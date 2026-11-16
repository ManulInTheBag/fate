"""Дым Natural Perception (W Билли): копия стокового riki_smokebomb, перекрашенная
из фиолетового в пыльно-серый.

Дерево декомпилируется из pak01 через Source2Viewer-CLI (как billy_crosshair),
ссылки riki_smokebomb* переименовываются в billy_smoke*, а каждый цвет
([r, g, b] и [r, g, b, a]) переводится в серый той же яркости с тёплым
«пыльным» оттенком. Править DUST/LIGHT здесь, затем:
    python build_billy_smoke.py
    resourcecompiler -i "<полный путь>/particles/billy/billy_smoke*.vpcf"
(без -game: с ним падает на gameinfo.gi).
"""
import os
import re
import subprocess
import sys
import tempfile

S2V = r"C:\Users\glebu\Tools\s2v\Source2Viewer-CLI.exe"
VPK = r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\pak01_dir.vpk"
SRC_DIR = "particles/units/heroes/hero_riki"
SRC_NAME = "riki_smokebomb"
DST_NAME = "billy_smoke"
OUT = os.path.dirname(os.path.abspath(__file__))

DUST = (1.06, 1.0, 0.88)   # множители яркости по каналам: тёплая пыль, а не стерильный серый
LIGHT = 0.55               # отсвет (deferred light, вспышка) приглушить: серый свет на земле не нужен

COLOR_RE = re.compile(r"(m_\w*Colou?r\w*\s*=\s*)\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(\s*,\s*\d+)?\s*\]")


def recolor(text, name):
    light = name.endswith("_e")   # вспышка + deferred light в центре
    def sub(m):
        r, g, b = int(m.group(2)), int(m.group(3)), int(m.group(4))
        lum = 0.299 * r + 0.587 * g + 0.114 * b
        if light:
            lum *= LIGHT
        rgb = [max(0, min(255, round(lum * k))) for k in DUST]
        return "%s[ %d, %d, %d%s ]" % (m.group(1), rgb[0], rgb[1], rgb[2], m.group(5) or "")
    return COLOR_RE.sub(sub, text)


def main():
    tmp = tempfile.mkdtemp(prefix="billy_smoke_")
    subprocess.run([S2V, "-i", VPK, "--vpk_filepath", SRC_DIR + "/" + SRC_NAME, "-d", "-o", tmp],
                   check=True, stdout=subprocess.DEVNULL)
    src = os.path.join(tmp, *SRC_DIR.split("/"))
    files = sorted(f for f in os.listdir(src) if f.startswith(SRC_NAME) and f.endswith(".vpcf"))
    if not files:
        sys.exit("s2v ничего не выгрузил")
    for f in files:
        with open(os.path.join(src, f), encoding="utf-8") as fh:
            text = fh.read()
        text = text.replace(SRC_DIR + "/" + SRC_NAME, "particles/billy/" + DST_NAME)
        name = DST_NAME + f[len(SRC_NAME):-5]
        text = recolor(text, name)
        with open(os.path.join(OUT, name + ".vpcf"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
        print("wrote", name + ".vpcf")


if __name__ == "__main__":
    main()
