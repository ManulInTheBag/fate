# -*- coding: utf-8 -*-
"""Эффекты стойки комбо Билли (юзер 08.10.2026): «бушующая энергия» вокруг Билли вместо
свечения модели и кольцо-выброс на каждом выстреле очереди.

billy_combo_aura*  — копия дерева windranger_arcana_ambient (вихрь Windranger Arcana:
                     туман, спирали, дуги по земле, дым), перекрашенная из бирюзы в
                     электрический синий и ЗАМЕТНЕЕ (юзер): радиусы вихря ×AURA_SCALE,
                     пережог ×OVERBRIGHT. Выключены дети, которым нужны аттачи ног
                     Windranger (attach_ankle_*/attach_knee_* — у Билли их нет), бабочки и
                     листья (это про ветер Windranger, не про молнию). CP0 — Билли
                     (PATTACH_ABSORIGIN_FOLLOW), остальные CP система ставит себе сама.
billy_combo_ring_burst — копия wr_zinogre_powershot_channel_burst (кольца разряда Zinogre
                     перед стрелком), в той же синей гамме. CP1 — Билли, forward CP1 —
                     направление выстрела: кольца встают на 200 впереди, на высоте 120.

Дерево берётся из pak01 через Source2Viewer-CLI (как build_billy_smoke.py).
    python build_billy_combo_aura.py
    resourcecompiler -i "<полный путь>/particles/billy/billy_combo_aura*.vpcf"
    resourcecompiler -i "<полный путь>/particles/billy/billy_combo_ring*.vpcf"
(без -game: с ним падает на gameinfo.gi).
"""
import colorsys
import os
import re
import subprocess
import sys
import tempfile

S2V = r"C:\Users\glebu\Tools\s2v\Source2Viewer-CLI.exe"
VPK = r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\pak01_dir.vpk"
OUT = os.path.dirname(os.path.abspath(__file__))

HUE        = 214 / 360.0   # электрический синий (конус комбо — та же гамма)
SAT_MAX    = 0.8           # насыщенность не выше: чисто-синий аддитив почти не светится
VAL_MIN    = 0.9           # яркие цвета не темнее этого — синий тусклее бирюзы на глаз
AURA_SCALE = 1.35          # радиусы вихря
OVERBRIGHT = 1.6           # пережог спрайтов/лент вихря

TREES = [
    # (папка в vpk, префикс исходника, корень, новый префикс, выключить детей)
    ("particles/econ/items/windrunner/windranger_arcana", "windranger_arcana_ambient",
     "windranger_arcana_ambient", "billy_combo_aura",
     ("_butterfly_trail", "_leg_l_pnt", "_leg_r_pnt", "_leg_l", "_leg_r", "_ground_leaf")),
    ("particles/econ/items/windrunner/mh_windranger_zinogre/powershot", "wr_zinogre_powershot_channel",
     "wr_zinogre_powershot_channel_burst", "billy_combo_ring", ()),
]

COLOR_RE = re.compile(r"(m_\w*Colou?r\w*\s*=\s*)\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(\s*,\s*\d+)?\s*\]")


def recolor(text):
    def sub(m):
        r, g, b = (int(m.group(i)) / 255.0 for i in (2, 3, 4))
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        if s < 0.15 or v < 0.12:            # белое, серое, чёрное (дым, тень) — как есть
            return m.group(0)
        s = min(s, SAT_MAX)
        if v > 0.5:
            v = max(v, VAL_MIN)
        rgb = colorsys.hsv_to_rgb(HUE, s, v)
        return "%s[ %d, %d, %d%s ]" % (m.group(1), *(round(c * 255) for c in rgb), m.group(5) or "")
    return COLOR_RE.sub(sub, text)


def block_end(text, start):
    """Конец блока { ... }, открытого первой '{' после start."""
    i = text.index("{", start)
    depth = 0
    for j in range(i, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                return j
    raise ValueError("unbalanced")


def scale_param(text, key, k):
    """Умножить число параметра key (плоский float или PF-структура: литерал и диапазон random)."""
    out, pos, n = [], 0, 0
    for m in re.finditer(r"\b%s = " % key, text):
        if m.start() < pos:
            continue
        line_end = text.index("\n", m.end())
        flat = re.match(r"(-?\d+\.\d+)", text[m.end():line_end])
        if flat:
            out.append(text[pos:m.end()] + "%.4f" % (float(flat.group(1)) * k))
            pos = m.end() + len(flat.group(1))
        else:
            end = block_end(text, m.end())
            body = re.sub(r"(m_flLiteralValue|m_flRandomMin|m_flRandomMax) = (-?\d+\.\d+)",
                          lambda q: "%s = %.4f" % (q.group(1), float(q.group(2)) * k), text[m.end():end])
            out.append(text[pos:m.end()] + body)
            pos = end
        n += 1
    out.append(text[pos:])
    return "".join(out), n


def disable_children(text, prefix, suffixes):
    for suf in suffixes:
        ref = 'm_ChildRef = resource:"particles/billy/%s%s.vpcf"\n' % (prefix, suf)
        text = re.sub(r"(\t+)" + re.escape(ref), lambda m: m.group(0) + m.group(1) + "m_bDisableChild = true\n", text)
    return text


def reachable(files, root):
    seen, todo = set(), [root]
    while todo:
        n = todo.pop()
        if n in seen or n not in files:
            continue
        seen.add(n)
        for c in re.finditer(r'm_ChildRef = resource:"particles/billy/([a-z0-9_]+)\.vpcf"\n(\t+m_bDisableChild = true)?',
                             files[n]):
            if not c.group(2):
                todo.append(c.group(1))
    return seen


def build(src_dir, src_prefix, root, dst_prefix, off):
    tmp = tempfile.mkdtemp(prefix="billy_aura_")
    subprocess.run([S2V, "-i", VPK, "--vpk_filepath", src_dir + "/" + src_prefix, "-d", "-o", tmp],
                   check=True, stdout=subprocess.DEVNULL)
    folder = os.path.join(tmp, *src_dir.split("/"))
    files = {}
    for f in sorted(os.listdir(folder)):
        if not (f.startswith(src_prefix) and f.endswith(".vpcf")):
            continue
        with open(os.path.join(folder, f), encoding="utf-8") as fh:
            text = fh.read()
        text = text.replace(src_dir + "/" + src_prefix, "particles/billy/" + dst_prefix)
        files[dst_prefix + f[len(src_prefix):-5]] = text
    new_root = dst_prefix + root[len(src_prefix):]
    for n in files:
        files[n] = disable_children(files[n], dst_prefix, off)
    keep = reachable(files, new_root)
    assert new_root in keep, new_root
    for n in sorted(keep):
        text = recolor(files[n])
        if dst_prefix == "billy_combo_aura":
            for key in ("m_fRadiusMin", "m_fRadiusMax", "m_flInitialRadius"):
                text, _ = scale_param(text, key, AURA_SCALE)
            text, _ = scale_param(text, "m_flOverbrightFactor", OVERBRIGHT)
        with open(os.path.join(OUT, n + ".vpcf"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
        print("wrote", n + ".vpcf")
    return keep


def main():
    # старые копии — убрать, чтобы не путались с текущим деревом
    for t in TREES:
        for f in os.listdir(OUT):
            if f.startswith(t[3]) and f.endswith(".vpcf"):
                os.remove(os.path.join(OUT, f))
    for t in TREES:
        build(*t)


if __name__ == "__main__":
    sys.exit(main())
