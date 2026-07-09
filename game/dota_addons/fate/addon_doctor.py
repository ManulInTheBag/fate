# -*- coding: utf-8 -*-
"""
addon_doctor.py — статический валидатор аддона fate.

Проверяет:
  1. Битые ссылки на ассеты (particles/models/sounds/soundevents/materials)
     из скриптов, vsndevts и карт — файл должен существовать в game (compiled),
     в content (source) или в стоковом pak01.
  2. Опечатки с двойным расширением (.vsnd.vsnd, .vpcf.vpcf, ...).
  3. Сироты: скомпилированные ассеты в game без исходника в content
     (в Tools mode ломаются при попытке перекомпиляции).
  4. Битые ссылки на дочерние партикли внутри vpcf_c.
  5. Несовпадение регистра пути в ссылке и на диске (ломается в VPK/Linux).
  6. Партикли, используемые в коде (EffectName/CreateParticle), но нигде
     не запрекешенные ("particle"/"particle_folder" в KV, PrecacheResource в lua).
  7. Клиент-серверные проблемы модификаторов: геттеры статов/тултипов,
     обёрнутые в IsServer() (на клиенте вернут nil — значения бафа не видны),
     и self.X из kv/IsServer-блоков, читаемые в клиентских функциях.

Запуск:  python addon_doctor.py            (полная проверка, ~1-2 мин)
         python addon_doctor.py --fast     (без скана чилдов партиклей)
Отчёт:   addon_doctor_report.txt рядом со скриптом.
"""
import os, re, sys, struct, zlib, time
from collections import defaultdict

GAME = os.path.dirname(os.path.abspath(__file__))
CONTENT = GAME.replace(os.sep + 'game' + os.sep, os.sep + 'content' + os.sep)
VPK = os.path.join(os.path.dirname(os.path.dirname(GAME)), 'dota', 'pak01_dir.vpk')
FAST = '--fast' in sys.argv

SOUND_SRC_EXT = ('.mp3', '.wav', '.ogg', '.flac', '.aac', '.m4a')
REF_RE = re.compile(
    rb'(?:particles/[\w\-./ ]+?\.vpcf|models/[\w\-./ ]+?\.vmdl'
    rb'|sounds/[\w\-./ ]+?\.vsnd|soundevents/[\w\-./ ]+?\.vsndevts'
    rb'|materials/[\w\-./ ]+?\.vmat)', re.IGNORECASE)
DOUBLE_EXT_RE = re.compile(
    rb'[\w\-./ ]+?(\.vsnd\.vsnd|\.vpcf\.vpcf|\.vmdl\.vmdl|\.vmat\.vmat|\.vsndevts\.vsndevts)')

def norm(p):
    return p.replace('\\', '/').lower()

# ---------- stock vpk index ----------
def read_cstr(buf, off):
    end = buf.index(b'\x00', off)
    return buf[off:end].decode('utf-8', 'replace'), end + 1

def parse_vpk(path):
    data = open(path, 'rb').read()
    sig, ver = struct.unpack_from('<II', data, 0)
    off = 28 if ver == 2 else 12
    out = set()
    while True:
        ext, off = read_cstr(data, off)
        if not ext:
            break
        while True:
            folder, off = read_cstr(data, off)
            if not folder:
                break
            while True:
                name, off = read_cstr(data, off)
                if not name:
                    break
                _, preload = struct.unpack_from('<IH', data, off)
                off += 18 + preload
                out.add(f"{folder}/{name}.{ext}")
    return out

# ---------- disk index (для case-check и существования) ----------
def index_tree(root):
    idx = {}
    for r, _, files in os.walk(root):
        for f in files:
            rel = os.path.relpath(os.path.join(r, f), root).replace(os.sep, '/')
            idx[rel.lower()] = rel
    return idx

def main():
    t0 = time.time()
    print("addon_doctor: индексация...")
    stock = parse_vpk(VPK) if os.path.isfile(VPK) else set()
    game_idx = index_tree(GAME)
    content_idx = index_tree(CONTENT) if os.path.isdir(CONTENT) else {}

    def exists_anywhere(ref):
        """ref в форме source (particles/x.vpcf). Возвращает 'game'/'content'/'stock'/None."""
        r = norm(ref)
        if r + '_c' in game_idx or r in game_idx:
            return 'game'
        if r.startswith('sounds/') and r.endswith('.vsnd'):
            stem = r[:-len('.vsnd')]
            if any(stem + e in content_idx for e in SOUND_SRC_EXT):
                return 'content'
        elif r in content_idx:
            return 'content'
        if r + '_c' in stock or r in stock:
            return 'stock'
        return None

    def case_mismatch(ref):
        r = norm(ref)
        for idx in (game_idx, content_idx):
            for key in (r + '_c', r):
                actual = idx.get(key)
                if actual is not None:
                    want = ref.replace('\\', '/')
                    if actual[:len(want)] != want and actual.lower()[:len(want)] == want.lower():
                        return actual
        return None

    errors, warns = [], []
    dbl = []

    # ---------- 1+2: ссылки из текстовых источников ----------
    text_roots = [os.path.join(GAME, 'scripts'),
                  os.path.join(GAME, 'panorama'),
                  os.path.join(GAME, 'resource'),
                  os.path.join(CONTENT, 'soundevents')]
    checked = set()
    for root in text_roots:
        if not os.path.isdir(root):
            continue
        for r, _, files in os.walk(root):
            for f in files:
                if not f.lower().endswith(('.lua', '.txt', '.kv', '.vsndevts', '.xml', '.js', '.css', '.res')):
                    continue
                ap = os.path.join(r, f)
                try:
                    data = open(ap, 'rb').read()
                except OSError:
                    continue
                relf = os.path.relpath(ap, GAME).replace(os.sep, '/')
                for m in DOUBLE_EXT_RE.finditer(data):
                    line = data[:m.start()].count(b'\n') + 1
                    dbl.append(f"{relf}:{line}  {m.group().decode('ascii','ignore')}")
                for m in REF_RE.finditer(data):
                    ref = m.group().decode('ascii', 'ignore')
                    key = (norm(ref), relf)
                    if key in checked:
                        continue
                    checked.add(key)
                    where = exists_anywhere(ref)
                    if where is None:
                        line = data[:m.start()].count(b'\n') + 1
                        errors.append(f"{relf}:{line}  MISSING  {ref}")
                    else:
                        mm = case_mismatch(ref)
                        if mm:
                            warns.append(f"{relf}  CASE  ссылка '{ref}' vs файл '{mm}'")

    # ---------- 1b: ссылки из карт (vpk) ----------
    maps_dir = os.path.join(GAME, 'maps')
    if os.path.isdir(maps_dir):
        for f in os.listdir(maps_dir):
            if not f.lower().endswith('.vpk'):
                continue
            data = open(os.path.join(maps_dir, f), 'rb').read()
            seen = set()
            for m in REF_RE.finditer(data):
                ref = norm(m.group().decode('ascii', 'ignore'))
                if ref in seen:
                    continue
                seen.add(ref)
                if exists_anywhere(ref) is None:
                    errors.append(f"maps/{f}  MISSING  {ref}")

    # ---------- 3: сироты (compiled без исходника) ----------
    orphan_by_kind = defaultdict(list)
    for rel_l, rel in game_idx.items():
        if rel_l.endswith('.vsnd_c'):
            stem = rel_l[:-len('.vsnd_c')]
            if not any(stem + e in content_idx for e in SOUND_SRC_EXT):
                orphan_by_kind['sounds'].append(rel)
        elif rel_l.endswith('.vpcf_c'):
            if rel_l[:-2] not in content_idx:
                orphan_by_kind['particles'].append(rel)
        elif rel_l.endswith('.vmdl_c'):
            if rel_l[:-2] not in content_idx:
                orphan_by_kind['models'].append(rel)
        elif rel_l.endswith('.vmat_c'):
            if rel_l[:-2] not in content_idx:
                orphan_by_kind['materials'].append(rel)

    # ---------- 4: чилды партиклей ----------
    broken_children = []
    if not FAST:
        pdir = os.path.join(GAME, 'particles')
        n = 0
        for r, _, files in os.walk(pdir):
            for f in files:
                if not f.lower().endswith('.vpcf_c'):
                    continue
                ap = os.path.join(r, f)
                own = norm(os.path.relpath(ap, GAME))[:-2]
                try:
                    data = open(ap, 'rb').read()
                except OSError:
                    continue
                n += 1
                for m in REF_RE.finditer(data):
                    ref = m.group().decode('ascii', 'ignore')
                    rl = norm(ref)
                    if not rl.endswith('.vpcf') or rl == own:
                        continue
                    if exists_anywhere(ref) is None:
                        broken_children.append(
                            f"{own}  ->  {rl}")
        broken_children = sorted(set(broken_children))

    # ---------- 5: precache-покрытие партиклей ----------
    prec_exact, prec_folders = set(), set()
    used_fx = defaultdict(list)   # particle -> [file:line, ...]
    KV_PART = re.compile(r'"particle"\s+"([^"]+\.vpcf)"', re.I)
    KV_PFOLD = re.compile(r'"particle_folder"\s+"([^"]+)"', re.I)
    KV_FX = re.compile(r'"EffectName"\s+"([^"]+\.vpcf)"', re.I)
    LUA_PREC = re.compile(r'PrecacheResource\(\s*["\'](particle|particle_folder)["\']\s*,\s*["\']([^"\']+)["\']', re.I)
    LUA_FX = re.compile(r'(?:EffectName\s*=\s*|CreateParticle\w*\(\s*)["\']([^"\']+\.vpcf)["\']', re.I)
    scripts_root = os.path.join(GAME, 'scripts')
    for r, _, files in os.walk(scripts_root):
        for f in files:
            low = f.lower()
            if not low.endswith(('.lua', '.txt', '.kv')):
                continue
            ap = os.path.join(r, f)
            try:
                text = open(ap, 'r', encoding='utf-8', errors='ignore').read()
            except OSError:
                continue
            relf = os.path.relpath(ap, GAME).replace(os.sep, '/')
            for m in KV_PART.finditer(text):
                prec_exact.add(norm(m.group(1)))
            for m in KV_PFOLD.finditer(text):
                prec_folders.add(norm(m.group(1)).rstrip('/'))
            for m in LUA_PREC.finditer(text):
                kind, path = m.group(1).lower(), norm(m.group(2))
                (prec_folders.add(path.rstrip('/')) if kind == 'particle_folder'
                 else prec_exact.add(path))
            for rx in (KV_FX, LUA_FX):
                for m in rx.finditer(text):
                    p = norm(m.group(1))
                    line = text[:m.start()].count('\n') + 1
                    if len(used_fx[p]) < 3:
                        used_fx[p].append(f"{relf}:{line}")

    not_precached = []
    for p, locs in sorted(used_fx.items()):
        if p in prec_exact:
            continue
        if any(p.startswith(fol + '/') for fol in prec_folders):
            continue
        not_precached.append(f"{p}\n        исп.: {'; '.join(locs)}")

    # ---------- 6: клиент-серверные проблемы модификаторов ----------
    FUNC_RE = re.compile(r'^function\s+([\w_]+):([\w_]+)\s*\(([^)]*)\)', re.M)
    CLIENT_FUNC = re.compile(r'^(GetModifier\w*|OnTooltip\w*|GetModifierExtraHealthBonus)$')
    cs_issues = []
    for r, _, files in os.walk(os.path.join(scripts_root, 'vscripts')):
        for f in files:
            if not f.lower().endswith('.lua'):
                continue
            ap = os.path.join(r, f)
            try:
                text = open(ap, 'r', encoding='utf-8', errors='ignore').read()
            except OSError:
                continue
            relf = os.path.relpath(ap, GAME).replace(os.sep, '/')
            marks = list(FUNC_RE.finditer(text))
            funcs = defaultdict(dict)  # class -> {fname: body}
            for i, m in enumerate(marks):
                cls, fname = m.group(1), m.group(2)
                end = marks[i+1].start() if i + 1 < len(marks) else len(text)
                funcs[cls][fname] = text[m.end():end]
            for cls, fd in funcs.items():
                if 'modifier' not in cls.lower():
                    continue
                # server-only переменные из OnCreated/OnRefresh
                server_vars, safe_vars = set(), set()
                for fname, body in fd.items():
                    assigns = re.finditer(r'self\.([A-Za-z_]\w*)\s*=\s*([^\n]+)', body)
                    in_created = fname in ('OnCreated', 'OnRefresh')
                    guarded = 'IsServer()' in body
                    for a in assigns:
                        var, rhs = a.group(1), a.group(2)
                        if in_created and (guarded or re.search(r'\bkv\.', rhs)):
                            server_vars.add(var)
                        elif not guarded:
                            safe_vars.add(var)
                server_only = server_vars - safe_vars
                for fname, body in fd.items():
                    if not CLIENT_FUNC.match(fname):
                        continue
                    # (А) весь геттер под IsServer()
                    code = re.sub(r'--[^\n]*', '', body)
                    first = next((l.strip() for l in code.splitlines() if l.strip()), '')
                    if first.startswith('if IsServer()') and 'else' not in code:
                        cs_issues.append(
                            f"{relf}  {cls}:{fname}()  ГЕТТЕР ПОД IsServer() — на клиенте вернёт nil")
                        continue
                    # (Б) читает server-only self.X
                    for var in server_only:
                        if re.search(r'self\.' + re.escape(var) + r'\b', body):
                            cs_issues.append(
                                f"{relf}  {cls}:{fname}()  читает self.{var} (задаётся только на сервере)")
                            break

    # ---------- отчёт ----------
    rpt_path = os.path.join(GAME, 'addon_doctor_report.txt')
    with open(rpt_path, 'w', encoding='utf-8') as rpt:
        def sect(title, items, limit=None):
            rpt.write(f"\n=== {title} ({len(items)}) ===\n")
            for it in (items if limit is None else items[:limit]):
                rpt.write(it + '\n')
            if limit is not None and len(items) > limit:
                rpt.write(f"... и ещё {len(items)-limit}\n")
            print(f"{title}: {len(items)}")

        sect("ОШИБКИ: битые ссылки (файл не найден нигде)", sorted(set(errors)))
        sect("ОШИБКИ: двойные расширения", dbl)
        sect("ОШИБКИ: битые чилды партиклей" + (" [пропущено --fast]" if FAST else ""),
             broken_children, limit=200)
        sect("ПРЕДУПРЕЖДЕНИЯ: регистр путей", sorted(set(warns)))
        sect("ПРЕДУПРЕЖДЕНИЯ: партикли без precache", not_precached)
        sect("ПРЕДУПРЕЖДЕНИЯ: клиент-сервер (значения бафов не видны на клиенте)",
             sorted(set(cs_issues)))
        rpt.write("\n=== СИРОТЫ: compiled без исходника в content ===\n")
        for kind, lst in sorted(orphan_by_kind.items()):
            by_folder = defaultdict(int)
            for rel in lst:
                parts = norm(rel).split('/')
                by_folder['/'.join(parts[:2])] += 1
            rpt.write(f"\n[{kind}] всего {len(lst)}:\n")
            for fol, cnt in sorted(by_folder.items(), key=lambda x: -x[1])[:25]:
                rpt.write(f"  {cnt:5d}  {fol}\n")
            print(f"сироты {kind}: {len(lst)}")
    print(f"\nотчёт: {rpt_path}")
    print(f"время: {time.time()-t0:.0f} c")

if __name__ == '__main__':
    main()
