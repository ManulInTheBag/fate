"""Барабан револьвера над хелсбаром Билли (billy_hud.js / billy_hud.css).

Панорама рисует border-radius на 32 px без сглаживания (юзер 09.10.2026: «супер
лоу-качество»), поэтому все круги — картинки, нарисованные с суперсэмплингом и
отданные с мипами (Box): на экране они только уменьшаются.

Файлы (экранный размер — в CSS, текстура = 4× или больше, все POT):
  drum_steel / drum_orange / drum_red  128² → 32 px — тело барабана: обод, выемки
      между гнёздами, ось в центре под числом. Цвет: D выкл. / D вкл. (оранжевый, юзер 09.10.2026) /
      пуль нет. Гнёзда сверху кладутся отдельными картинками и крутятся с телом.
  chamber_loaded / chamber_loaded_dim / chamber_empty / chamber_empty_red  64² → 16 px —
      гнездо (круг 8 px в центре, вокруг место под ореол у красного).
  drum_glow_orange / drum_glow_red  256² → 48 px — ореол вокруг барабана (не крутится,
      «дышит» прозрачностью из CSS).

Геометрия гнёзд дублируется в billy_hud.js: CHAMBER_RADIUS (10.5 px от центра),
шаг 360/6, первое гнездо сверху.

Запуск: python build_billy_drum.py, затем resourcecompiler по каждому *_png.vtex
(память panorama-icon-compile: RGBA8888, srgb/srgb, мипы Box для POT).
"""
import math
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SS = 4                                   # суперсэмплинг поверх размера текстуры

DRUM_PX = 32                             # экранный размер тела
CHAMBERS = 6
CHAMBER_RADIUS = 10.5                    # экранные px от центра до центра гнезда
CHAMBER_R = 4.0                          # экранный радиус гнезда
CHAMBER_BOX = 16                         # экранный размер картинки гнезда
GLOW_BOX = 48

DRUM_TEX, CHAMBER_TEX, GLOW_TEX = 128, 64, 256

# цвета тела: центр, край, обод, светлый край обода
DRUMS = {
    "steel":  ((92, 95, 102), (26, 27, 31), (138, 140, 146), (205, 208, 214)),
    "orange": ((156, 80, 20), (46, 20, 5), (255, 150, 48), (255, 222, 150)),
    "red":    ((96, 18, 14), (30, 5, 5), (214, 50, 36), (255, 140, 110)),
}


def grid(n):
    """Координаты пикселей в долях: (x, y) от −1 до 1 по канве n×n."""
    c = (np.arange(n) + 0.5) / n * 2 - 1
    return np.meshgrid(c, c)


def smooth(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return np.asarray(a, np.float32) + (np.asarray(b, np.float32) - np.asarray(a, np.float32)) * t[..., None]


def finish(rgb, alpha, size):
    """rgb 0..255, alpha 0..1 на суперсэмпл-канве → RGBA size×size (усреднение премультиплаем)."""
    a = np.clip(alpha, 0, 1)[..., None]
    pm = np.dstack([np.clip(rgb, 0, 255) * a, a * 255]).astype(np.float32)
    big = Image.fromarray(pm.astype(np.uint8), "RGBA")
    # premultiplied-усреднение: уменьшаем каналы как есть, потом делим на альфу
    small = np.asarray(big.resize((size, size), Image.BOX), np.float32)
    al = small[..., 3:4] / 255
    col = small[..., :3] / np.maximum(al, 1e-4)
    return Image.fromarray(np.dstack([np.clip(col, 0, 255), al * 255]).astype(np.uint8), "RGBA")


def over(dst_rgb, dst_a, src_rgb, src_a):
    """Альфа-композиция src поверх dst (rgb 0..255, a 0..1)."""
    out_a = src_a + dst_a * (1 - src_a)
    out_rgb = (src_rgb * src_a[..., None] + dst_rgb * (dst_a * (1 - src_a))[..., None]) / np.maximum(out_a, 1e-4)[..., None]
    return out_rgb, out_a


def build_drum(center, edge, rim, rim_hi):
    n = DRUM_TEX * SS
    x, y = grid(n)
    r = np.hypot(x, y)                  # 1 = край канвы = 16 экранных px
    px = 1.0 / (DRUM_PX / 2)            # один экранный px в долях радиуса
    aa = 1.5 / n * 2                    # ширина сглаживания края

    body_r = 1 - 0.5 * px
    alpha = 1 - smooth(body_r - aa, body_r, r)

    # тело: радиальный градиент, светлое пятно сверху-слева (объём)
    rgb = lerp(center, edge, smooth(0.0, 1.0, r))
    light = np.clip(1 - np.hypot(x + 0.35, y + 0.45) / 1.1, 0, 1) ** 2
    rgb = rgb + light[..., None] * 38

    # выемки между гнёздами: вытянутые по радиусу тёмные пазы у края
    ang = np.arctan2(y, x)
    for i in range(CHAMBERS):
        a = math.radians((i + 0.5) * 360 / CHAMBERS - 90)
        # координаты в системе паза: u — вдоль радиуса, v — поперёк
        u = x * math.cos(a) + y * math.sin(a)
        v = -x * math.sin(a) + y * math.cos(a)
        d = np.hypot(np.clip(u - 0.80, -0.16, 0.16) - (u - 0.80), v) / (1.9 * px)
        groove = 1 - smooth(0.75, 1.0, d)
        rgb = lerp(rgb, np.asarray(edge, np.float32) * 0.35, groove * 0.9)
        # светлая кромка паза со стороны света
        rgb = rgb + (smooth(0.7, 1.0, d) * (1 - smooth(1.0, 1.25, d)))[..., None] * 22

    # гнёзда-раззенковки: тёмное кольцо под картинку гнезда
    for i in range(CHAMBERS):
        a = math.radians(i * 360 / CHAMBERS - 90)
        cx, cy = CHAMBER_RADIUS * px * math.cos(a), CHAMBER_RADIUS * px * math.sin(a)
        d = np.hypot(x - cx, y - cy) / px
        ring = smooth(CHAMBER_R + 1.4, CHAMBER_R + 0.2, d)
        rgb = lerp(rgb, np.asarray(edge, np.float32) * 0.5, ring * 0.55)

    # ось: тёмный диск под числом
    hub = 1 - smooth(5.6 * px, 6.4 * px, r)
    rgb = lerp(rgb, np.asarray(edge, np.float32) * 0.45, hub * 0.85)

    # обод: кольцо 1.5 px, светлее сверху
    rim_w = 1.6 * px
    ring = smooth(body_r - rim_w - aa, body_r - rim_w, r) * (1 - smooth(body_r - aa, body_r, r))
    top = np.clip((-y + 1) / 2, 0, 1)
    rim_col = lerp(rim, rim_hi, top ** 1.5)
    rgb = rgb * (1 - ring[..., None]) + rim_col * ring[..., None]
    # внутренняя тень под ободом
    rgb = rgb * (1 - (smooth(body_r - rim_w - 2 * px, body_r - rim_w, r) * (1 - ring))[..., None] * 0.35)

    return finish(rgb, alpha, DRUM_TEX)


def build_chamber(kind):
    n = CHAMBER_TEX * SS
    x, y = grid(n)
    px = 1.0 / (CHAMBER_BOX / 2)
    r = np.hypot(x, y) / px             # экранные px от центра
    aa = 2.0 / n * 2 / px
    disc = 1 - smooth(CHAMBER_R - aa, CHAMBER_R, r)

    if kind.startswith("loaded"):
        # торец гильзы: латунь, блик сверху-слева, капсюль в центре, тёмный кант
        face = lerp((255, 232, 150), (176, 120, 40), smooth(0, CHAMBER_R, np.hypot(x / px + 1.2, y / px + 1.4)))
        rim = smooth(CHAMBER_R - 1.1, CHAMBER_R - 0.5, r)
        face = lerp(face, (96, 62, 18), rim * 0.9)
        primer = 1 - smooth(1.3, 1.7, r)
        primer_col = lerp((236, 214, 170), (150, 118, 72), smooth(0, 1.6, np.hypot(x / px + 0.4, y / px + 0.5)))
        face = lerp(face, primer_col, primer)
        ring = smooth(1.4, 1.7, r) * (1 - smooth(1.7, 2.1, r))
        face = lerp(face, (110, 74, 24), ring * 0.8)
        if kind == "loaded_dim":
            grey = face.mean(axis=-1, keepdims=True)
            face = (face * 0.45 + grey * 0.55) * 0.72
        return finish(face, disc, CHAMBER_TEX)

    if kind == "empty":
        # пустое гнездо: тёмная дыра, свет на нижней внутренней стенке
        hole = lerp((4, 4, 5), (34, 34, 38), smooth(1.5, CHAMBER_R, r))
        wall = np.clip(y / px / CHAMBER_R, 0, 1) * smooth(CHAMBER_R - 1.8, CHAMBER_R - 0.6, r)
        hole = hole + wall[..., None] * 40
        rim = smooth(CHAMBER_R - 0.8, CHAMBER_R - 0.3, r)
        hole = lerp(hole, (82, 82, 88), rim * 0.8)
        return finish(hole, disc, CHAMBER_TEX)

    # пустое при включённой D без пуль: раскалённое гнездо + мягкий ореол наружу
    hot = lerp((255, 168, 96), (120, 10, 6), smooth(0, CHAMBER_R, r))
    rim = smooth(CHAMBER_R - 0.8, CHAMBER_R - 0.3, r)
    hot = lerp(hot, (230, 60, 40), rim)
    glow_a = np.exp(-np.maximum(r - CHAMBER_R, 0) ** 2 / (2 * 1.0 ** 2)) * 0.45
    glow_a = glow_a * (1 - smooth(7.2, 8.0, r))
    rgb, a = over(np.zeros_like(hot) + np.asarray((255, 40, 20), np.float32), glow_a, hot, disc)
    return finish(rgb, a, CHAMBER_TEX)


def build_glow(color):
    n = GLOW_TEX * 2
    x, y = grid(n)
    px = 1.0 / (GLOW_BOX / 2)
    r = np.hypot(x, y) / px
    body = DRUM_PX / 2
    a = np.exp(-np.maximum(r - body + 1, 0) ** 2 / (2 * 2.6 ** 2))
    a = a * (1 - smooth(GLOW_BOX / 2 - 1.5, GLOW_BOX / 2, r))
    rgb = np.zeros((n, n, 3), np.float32) + np.asarray(color, np.float32)
    return finish(rgb, a * 0.9, GLOW_TEX)


def write_vtex(name):
    with open(os.path.join(HERE, name + "_png.vtex"), "w", encoding="utf-8", newline="\n") as f:
        f.write(
            '<!-- dmx encoding keyvalues2_noids 1 format vtex 1 -->\n'
            '"CDmeVtex"\n{\n'
            '\t"m_inputTextureArray" "element_array" [ "CDmeInputTexture" { "m_name" "string" "0" '
            '"m_fileName" "string" "panorama/images/custom_game/billy/' + name + '.png" '
            '"m_colorSpace" "string" "srgb" "m_typeString" "string" "2D" } ]\n'
            '\t"m_outputTypeString" "string" "2D"\n'
            '\t"m_outputFormat" "string" "RGBA8888"\n'
            # POT: мипы Box — картинки только уменьшаются (4× и больше)
            '\t"m_textureOutputChannelArray" "element_array" [ "CDmeTextureOutputChannel" { '
            '"m_inputTextureArray" "string_array" [ "0" ] "m_srcChannels" "string" "rgba" '
            '"m_dstChannels" "string" "rgba" "m_mipAlgorithm" "CDmeImageProcessor" { '
            '"m_algorithm" "string" "Box" "m_stringArg" "string" "" "m_vFloat4Arg" "vector4" "0 0 0 0" } '
            '"m_outputColorSpace" "string" "srgb" } ]\n'
            '}\n')


def save(img, name):
    img.save(os.path.join(HERE, name + ".png"))
    write_vtex(name)
    print("written", name, img.size)


def main():
    for key, cols in DRUMS.items():
        save(build_drum(*cols), "drum_" + key)
    for kind in ("loaded", "loaded_dim", "empty", "empty_red"):
        save(build_chamber(kind), "chamber_" + kind)
    save(build_glow((255, 146, 32)), "drum_glow_orange")
    save(build_glow((255, 48, 32)), "drum_glow_red")


if __name__ == "__main__":
    main()
