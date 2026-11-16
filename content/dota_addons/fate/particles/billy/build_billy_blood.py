"""Кровь от пуль Билли трёх размеров (юзер 06.10.2026: «на Q и W поменьше, на R среднее,
на комбе как сейчас — много»).

Большая (комбо) — стоковая pa_persona_crit_impact как есть. Малая (Q/W/E) и средняя (R) —
её уменьшенные копии: корень (кровавая клякса на земле, RenderProjected) с меньшим радиусом
и только частью детей — burst (брызги-спрайты) и mist (струйки), у средней ещё blood
(жидкие капли, RenderBlobs). Пятно bloodstain (радиус 350) и летящая струя travel — только
у комбо. Остальные дети и low-violence версия — стоковые (дерево persona не перекрыто
дампом в аддоне, см. память masked-stock-particles).

CP — как у PA crit: CP0 = attach_hitloc цели (follow), CP1 = позиция цели, forward CP1 =
направление ОТ стрелка: брызги летят по −X локальных осей CP1 (скорости [-450..-850, 0, …]),
клякса ложится позади по −X. Поэтому forward = (стрелок − цель): «от Билли к цели» давал
кровь в сторону Билли.

Запуск: python build_billy_blood.py, затем
    resourcecompiler -i "<полный путь>/particles/billy/billy_blood_*.vpcf"
(без -game: с ним падает на gameinfo.gi).
"""
import os
import re
import subprocess
import tempfile

S2V = r"C:\Users\glebu\Tools\s2v\Source2Viewer-CLI.exe"
VPK = r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\pak01_dir.vpk"
SRC = "particles/units/heroes/hero_phantom_assassin_persona"
ROOT = "pa_persona_crit_impact"
OUT = os.path.dirname(os.path.abspath(__file__))

# размер: клякса (множитель радиуса), burst/mist/blood: (число частиц | None, радиус, скорость)
LEVELS = {
    's': dict(decal=0.45, burst=(10, 0.55, 0.6), mist=(16, 0.55, 0.6), blood=None),
    'm': dict(decal=0.7,  burst=(20, 0.8, 0.8),  mist=(30, 0.8, 0.8),  blood=(None, 0.55, 0.7)),
}


def one(s, a, b):
    assert s.count(a) == 1, (a, s.count(a))
    return s.replace(a, b)


def num(x):
    return ('%.2f' % x).rstrip('0').rstrip('.') + ('' if '.' in ('%.2f' % x).rstrip('0').rstrip('.') else '.0')


def scale_vecs(s, k):
    def sub(m):
        return 'm_vLiteralValue = [ %s ]' % ', '.join(num(float(v) * k) for v in m.group(1).split(','))
    return re.sub(r'm_vLiteralValue = \[ ([-\d., ]+) \]', sub, s)


def scale(s, key, val, k):
    return one(s, '%s = %s\n' % (key, val), '%s = %s\n' % (key, num(float(val) * k)))


def decompile():
    tmp = tempfile.mkdtemp(prefix="billy_blood_")
    for name in (ROOT, ROOT + "_burst", ROOT + "_mist", ROOT + "_blood"):
        subprocess.run([S2V, "-i", VPK, "--vpk_filepath", "%s/%s.vpcf_c" % (SRC, name), "-d", "-o", tmp],
                       check=True, stdout=subprocess.DEVNULL)
    d = os.path.join(tmp, *SRC.split("/"))
    return {n: open(os.path.join(d, n + ".vpcf"), encoding="utf-8").read()
            for n in (ROOT, ROOT + "_burst", ROOT + "_mist", ROOT + "_blood")}


def put(name, text):
    with open(os.path.join(OUT, name + ".vpcf"), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", name)


def main():
    src = decompile()
    for lvl, cfg in LEVELS.items():
        kids = []

        cnt, rk, vk = cfg['burst']
        t = src[ROOT + "_burst"]
        t = one(t, 'm_flLiteralValue = 32.0\n', 'm_flLiteralValue = %s\n' % num(cnt))
        t = scale(t, '\t\t\t\tm_flRandomMin', '35.0', rk)
        t = scale(t, '\t\t\t\tm_flRandomMax', '50.0', rk)
        put('billy_blood_%s_burst' % lvl, scale_vecs(t, vk))
        kids.append('billy_blood_%s_burst' % lvl)

        cnt, rk, vk = cfg['mist']
        t = src[ROOT + "_mist"]
        t = one(t, 'm_flLiteralValue = 50.0\n', 'm_flLiteralValue = %s\n' % num(cnt))
        t = scale(t, '\t\t\t\tm_flLiteralValue', '250.0', vk)
        t = scale(t, '\t\t\t\tm_flLiteralValue', '500.0', vk)
        t = scale(t, '\t\t\t\tm_flRandomMin', '25.0', rk)
        t = scale(t, '\t\t\t\tm_flRandomMax', '30.0', rk)
        put('billy_blood_%s_mist' % lvl, scale_vecs(t, vk))
        kids.append('billy_blood_%s_mist' % lvl)

        if cfg['blood']:
            _, rk, vk = cfg['blood']
            t = src[ROOT + "_blood"]
            t = scale(t, '\t\t\t\tm_flRandomMin', '80.0', rk)
            t = re.sub(r'(m_flRandomMin = [\d.]+\n\t+m_flRandomMax = )([\d.]+)',
                       lambda m: m.group(1) + num(float(m.group(2)) * rk), t, count=1)
            t = scale(t, '\t\t\t\tm_flLiteralValue', '200.0', vk)
            t = scale(t, '\t\t\tm_fSpeedMax', '250.0', vk)
            put('billy_blood_%s_blood' % lvl, scale_vecs(t, vk))
            kids.append('billy_blood_%s_blood' % lvl)

        # корень: клякса меньше, дети — только свои копии
        t = src[ROOT]
        t = scale(t, '\t\t\t\tm_flRandomMin', '140.0', cfg['decal'])
        t = scale(t, '\t\t\t\tm_flRandomMax', '180.0', cfg['decal'])
        block = '\tm_Children = \n\t[\n' + ''.join(
            '\t\t{\n\t\t\tm_ChildRef = resource:"particles/billy/%s.vpcf"\n\t\t},\n' % k for k in kids) + '\t]\n'
        t, n = re.subn(r'\tm_Children = \n\t\[\n.*?\n\t\]\n', lambda m: block, t, flags=re.S)
        assert n == 1
        put('billy_blood_%s' % lvl, t)


if __name__ == "__main__":
    main()
