"""Плакат «WANTED» в топ-баре (атрибут Билли Young Outlaw Leader).

Плакат ЗАМЕНЯЕТ портрет цели в ячейке топ-бара (юзер 08.10.2026: висящий снизу
занимал много места). Чуть выше портрета (юзер: «для эстетики») — 64×46: сверху
закрывает полоску цвета игрока (7 px), снизу на 3 px заходит рваным краем на
полосу с номером/золотом, их надписи не трогает.
Пергамент-рамка с обожжённым рваным краем, гвоздями в верхних углах, WANTED
сверху и DEAD OR ALIVE снизу; посередине прозрачное окно — туда панорама кладёт сепию портрета
(#WantedPortrait). Окно дублируется в multiteam_top_scoreboard.css.

Второй файл — wanted_holes.png: три пулевые пробоины размером с окно, кладутся
поверх портрета, когда голова получена (вместо штампа CLAIMED). Пробоина — та же,
что у метки комбо (materials/billy/billy_hole_1.png, build_billy_holes.py).

Картинки в 2× (SCALE). Запуск: python build_wanted_poster.py, затем resourcecompiler
по обоим *_png.vtex (память panorama-icon-compile: RGBA8888, srgb/srgb; NPOT — без мипов).
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
HOLE_SRC = os.path.join(HERE, "..", "..", "..", "..", "materials", "billy", "billy_hole_1.png")
SCALE = 2
# шире ячейки (64) на 2 px с каждой стороны: нахлёст закрывает щели от округления
# при дробном масштабе UI (1440p, 768p) — юзер видел край старого портрета
POSTER_W, POSTER_H = 68, 46            # ячейка: полоска цвета 7 + портрет 36 + 3
W, H = POSTER_W * SCALE, POSTER_H * SCALE

# окно портрета (экранные px) — то же в CSS (#WantedPortrait / #WantedHoles)
WIN = (6, 12, 56, 26)                  # x, y, w, h (= 4 px от края ячейки)

FONT = r"C:\Windows\Fonts\BOOKOSB.TTF"  # Bookman Old Style Bold
INK = (58, 34, 17)
SEED = 1873

# пробоины в окне: центр (доля ширины/высоты окна), диаметр в экранных px, поворот
HOLES = [(0.2, 0.42, 19, 0), (0.54, 0.62, 17, 70), (0.83, 0.36, 18, 150)]


def noise(shape, scale, rng):
    h, w = shape
    small = rng.random((max(2, h // scale), max(2, w // scale)))
    img = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    return np.asarray(img, dtype=np.float32) / 255.0


def torn_mask(rng):
    """Альфа листа: прямоугольник с мелко рваным краем."""
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    margin = 1.0 * SCALE
    pts = []

    def edge(x0, y0, x1, y1, n, normal):
        for i in range(n + 1):
            t = i / n
            off = rng.uniform(0.0, 1.0) * 1.3 * SCALE
            pts.append((x0 + (x1 - x0) * t + normal[0] * off, y0 + (y1 - y0) * t + normal[1] * off))
    edge(margin, margin, W - margin, margin, 30, (0, 1))
    edge(W - margin, margin, W - margin, H - margin, 12, (-1, 0))
    edge(W - margin, H - margin, margin, H - margin, 30, (0, -1))
    edge(margin, H - margin, margin, margin, 12, (1, 0))
    d.polygon(pts, fill=255)
    return np.asarray(m.filter(ImageFilter.GaussianBlur(0.5)), dtype=np.float32) / 255.0


def text_block(dst, text, box, size, tracking=0):
    """Надпись, вписанная в box (x0, y0, x1, y1): рисуем крупно и ужимаем."""
    x0, y0, x1, y1 = box
    font = ImageFont.truetype(FONT, size)
    widths = [font.getbbox(ch)[2] - font.getbbox(ch)[0] for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    asc, desc = font.getmetrics()
    tmp = Image.new("L", (int(total) + 8, asc + desc + 8), 0)
    td = ImageDraw.Draw(tmp)
    x = 4
    for ch, wch in zip(text, widths):
        bb = font.getbbox(ch)
        td.text((x - bb[0], 4), ch, font=font, fill=255)
        x += wch + tracking
    tmp = tmp.crop(tmp.getbbox())
    glyph = tmp.resize((int(x1 - x0), int(y1 - y0)), Image.LANCZOS)
    dst.paste(Image.new("L", glyph.size, 255), (int(x0), int(y0)), glyph)


def build_poster(rng):
    s = SCALE
    base = np.array([232, 211, 168], dtype=np.float32)
    n1 = noise((H, W), 10 * s, rng)
    n2 = noise((H, W), 3 * s, rng)
    fine = rng.random((H, W)).astype(np.float32)
    paper = base[None, None, :] * (0.86 + 0.10 * n1 + 0.04 * n2 + 0.03 * (fine - 0.5))[..., None]

    alpha = torn_mask(rng)
    # обожжённый край — узкий: рамка тонкая
    edge = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(2.2 * s)), dtype=np.float32) / 255.0
    k = np.clip((1.0 - edge) * 1.8, 0, 1)[..., None]
    paper = paper * (1 - k) + np.array([96, 58, 26], dtype=np.float32)[None, None, :] * k

    ink = Image.new("L", (W, H), 0)
    text_block(ink, "WANTED", (14 * s, 1.8 * s, 54 * s, 10.2 * s), 96, tracking=6)
    text_block(ink, "DEAD OR ALIVE", (11 * s, 39.4 * s, 57 * s, 43.6 * s), 64, tracking=8)
    ink_a = np.asarray(ink, dtype=np.float32) / 255.0
    ink_a *= np.clip(0.8 + 0.5 * noise((H, W), 2, rng), 0, 1)
    ink_col = np.array(INK, dtype=np.float32)
    paper = paper * (1 - ink_a[..., None] * 0.95) + ink_col[None, None, :] * (ink_a[..., None] * 0.95)

    # окно: тёмная рамка, проём прозрачный
    wx, wy, ww, wh = [v * s for v in WIN]
    fr = 1 * s
    yy, xx = np.mgrid[0:H, 0:W]
    in_frame = (xx >= wx - fr) & (xx < wx + ww + fr) & (yy >= wy - fr) & (yy < wy + wh + fr)
    in_hole = (xx >= wx) & (xx < wx + ww) & (yy >= wy) & (yy < wy + wh)
    paper[in_frame & ~in_hole] = ink_col * 0.9
    alpha = alpha.copy()
    alpha[in_hole] = 0.0

    img = Image.fromarray(np.dstack([np.clip(paper, 0, 255), alpha * 255]).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    for cx, cy in [(6 * s, 5 * s), (W - 6 * s, 5 * s)]:
        r = 2.0 * s
        d.ellipse((cx - r + 1, cy - r + 2, cx + r + 1, cy + r + 2), fill=(40, 24, 10, 150))
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(92, 88, 82, 255), outline=(36, 32, 28, 255), width=1)
        d.ellipse((cx - r * 0.55, cy - r * 0.6, cx - r * 0.05, cy - r * 0.1), fill=(190, 186, 176, 255))
    return img


def build_holes():
    """Три пробоины из текстуры метки комбо, на прозрачном поле размером с окно."""
    src = Image.open(HOLE_SRC).convert("RGBA")
    src = src.crop(src.getbbox())          # одна пробоина с лепестками
    ww, wh = WIN[2] * SCALE, WIN[3] * SCALE
    out = Image.new("RGBA", (ww, wh), (0, 0, 0, 0))
    for fx, fy, diam, rot in HOLES:
        size = int(diam * SCALE)
        # ресайз в премультиплицированном виде — без светлой каймы
        arr = np.asarray(src, dtype=np.float32) / 255.0
        pm = Image.fromarray((np.dstack([arr[..., :3] * arr[..., 3:4], arr[..., 3:4]]) * 255).astype(np.uint8), "RGBA")
        pm = pm.rotate(rot, resample=Image.BICUBIC, expand=True).resize((size, size), Image.LANCZOS)
        a = np.asarray(pm, dtype=np.float32) / 255.0
        rgb = a[..., :3] / np.maximum(a[..., 3:4], 1e-4)
        hole = Image.fromarray((np.dstack([np.clip(rgb, 0, 1), a[..., 3:4]]) * 255).astype(np.uint8), "RGBA")
        out.alpha_composite(hole, (int(fx * ww - size / 2), int(fy * wh - size / 2)))
    return out


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
            # NPOT: мипы нельзя — m_algorithm пустой
            '\t"m_textureOutputChannelArray" "element_array" [ "CDmeTextureOutputChannel" { '
            '"m_inputTextureArray" "string_array" [ "0" ] "m_srcChannels" "string" "rgba" '
            '"m_dstChannels" "string" "rgba" "m_mipAlgorithm" "CDmeImageProcessor" { '
            '"m_algorithm" "string" "" "m_stringArg" "string" "" "m_vFloat4Arg" "vector4" "0 0 0 0" } '
            '"m_outputColorSpace" "string" "srgb" } ]\n'
            '}\n')


def main():
    rng = np.random.default_rng(SEED)
    build_poster(rng).save(os.path.join(HERE, "wanted_poster.png"))
    write_vtex("wanted_poster")
    build_holes().save(os.path.join(HERE, "wanted_holes.png"))
    write_vtex("wanted_holes")
    print("written wanted_poster.png", (W, H), "wanted_holes.png", (WIN[2] * SCALE, WIN[3] * SCALE))


if __name__ == "__main__":
    main()
