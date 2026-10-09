# -*- coding: utf-8 -*-
"""Метка комбо Билли — пулевые дырки на теле цели (modifier_billy_combo_mark).

Три состояния: billy_hole_1/2/3 — одна, две, три дырки. Каждая следующая текстура
содержит предыдущие дырки на тех же местах (у каждой дырки свой сид): при попадании
спрайт подменяется, и видно, как добавляется новая дырка.

Вид — пробоина в металле, как на референсе юзера (06.10.2026: ровные окружности
«слишком простые», нужны рваные неровные):
  лепестки — вывернутый наружу металл: рваный край с острыми зубцами разной длины,
             металлический градиент, свет сверху-слева, складки от дырки к зубцам,
             тонкая «шлифовка», тёмная кромка и блик по краю;
  нагар — тёмное выгорание вокруг дырки на лепестках;
  дырка — неровный чёрный провал, внутренняя стенка подсвечена с дальней стороны;
  тень лепестков на теле цели и лёгкая копоть вокруг — контраст на любой модели.
Рисуется в 4× и сжимается в премультиплицированном виде — гладкие края без каймы.

Ещё собирает партикли particles/billy/billy_combo_mark_1/2/3.vpcf из шаблона
billy_combo_mark.template (там вся настройка спрайта), отличаются только текстурой.

Запуск из этой папки: python build_billy_holes.py, затем
resourcecompiler -game <game/dota> -f -i content/dota_addons/fate/materials/billy/billy_hole_*.vtex
resourcecompiler -game <game/dota> -f -i content/dota_addons/fate/particles/billy/billy_combo_mark_?.vpcf
"""
import math, os, random
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
PART = os.path.join(HERE, '..', '..', 'particles', 'billy')
OUT = 512
SS = 4                      # суперсэмплинг
N = OUT * SS
C = N / 2

# центры дырок (пиксели итоговой 512-текстуры от центра) и радиус провала
HOLES = [(-74, -40), (82, -20), (4, 86)]
R_CORE = 24
LIGHT = math.atan2(-1, -1)  # свет сверху-слева (y вниз)
SAMPLES = 2048              # точность профиля края по углу

VTEX = open(os.path.join(HERE, '..', 'hijikata', 'duel.vtex'), encoding='utf-8', newline='').read()

YY, XX = np.mgrid[0:N, 0:N].astype(np.float32)
ANG = np.linspace(-math.pi, math.pi, SAMPLES, endpoint=False)


def over(dst, src):
    """dst, src — float32 RGBA 0..1 (не премульт.); src поверх dst."""
    a = src[..., 3:4]
    out_a = a + dst[..., 3:4] * (1 - a)
    rgb = (src[..., :3] * a + dst[..., :3] * dst[..., 3:4] * (1 - a)) / np.maximum(out_a, 1e-6)
    return np.concatenate([rgb, out_a], axis=-1)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def angdiff(a, b):
    return (a - b + math.pi) % (2 * math.pi) - math.pi


def smooth_noise(rnd, n, k):
    """Периодический шум по углу: случайные значения, сглаженные окном k."""
    v = np.array([rnd.uniform(-1, 1) for _ in range(n)], np.float32)
    ker = np.hanning(2 * k + 1)
    ker /= ker.sum()
    v = np.concatenate([v[-k:], v, v[:k]])
    return np.convolve(v, ker, mode='valid')


def lookup(profile, th):
    idx = ((th + math.pi) / (2 * math.pi) * SAMPLES).astype(np.int32) % SAMPLES
    return profile[idx]


class Hole:
    def __init__(self, idx, cx, cy):
        rnd = self.rnd = random.Random(4242 + idx * 977)
        self.cx, self.cy = C + cx * SS, C + cy * SS
        rc = R_CORE * SS * rnd.uniform(0.9, 1.05)
        self.rc = rc

        # край провала — неровный круг
        core = (1 + 0.05 * np.sin(3 * ANG + rnd.uniform(0, 6)) + 0.035 * np.sin(5 * ANG + rnd.uniform(0, 6))
                + 0.05 * smooth_noise(rnd, SAMPLES, 18) + 0.025 * smooth_noise(rnd, SAMPLES, 4))
        self.core = rc * core

        # край лепестков: рваная база + острые зубцы разной длины
        edge = rc * (2.05 + 0.16 * smooth_noise(rnd, SAMPLES, 40) + 0.06 * smooth_noise(rnd, SAMPLES, 8)
                     + 0.03 * smooth_noise(rnd, SAMPLES, 2))
        self.spikes = []
        n = rnd.randint(7, 10)
        base = rnd.uniform(-math.pi, math.pi)
        for i in range(n):
            phi = base + 2 * math.pi * i / n + rnd.uniform(-0.25, 0.25)
            length = rc * rnd.uniform(0.45, 1.5) * (1.35 if rnd.random() < 0.3 else 1)
            width = rnd.uniform(0.12, 0.26)
            lean = rnd.uniform(-0.4, 0.4)          # зубец чуть загнут в сторону
            t = angdiff(ANG, phi) / width
            t = np.where(t > 0, t * (1 + lean), t * (1 - lean))
            edge = edge + length * np.clip(1 - np.abs(t), 0, 1) ** 1.6
            self.spikes.append((phi, width))
        # мелкие зазубрины по всему краю
        for _ in range(rnd.randint(14, 22)):
            phi = rnd.uniform(-math.pi, math.pi)
            w = rnd.uniform(0.02, 0.05)
            edge = edge + rc * rnd.uniform(0.06, 0.18) * np.clip(1 - np.abs(angdiff(ANG, phi)) / w, 0, 1)
        self.edge = edge.astype(np.float32)

        # складки металла: гребень от провала к каждому зубцу + несколько случайных
        fold = np.zeros(SAMPLES, np.float32)
        folds = [p for p, _ in self.spikes] + [rnd.uniform(-math.pi, math.pi) for _ in range(rnd.randint(4, 7))]
        for phi in folds:
            dd = angdiff(ANG, phi)
            fold += np.sign(dd) * np.exp(-np.abs(dd) / rnd.uniform(0.05, 0.12)) * rnd.uniform(0.6, 1.0)
        self.fold = fold
        self.brush = smooth_noise(rnd, SAMPLES, 1)           # «шлифовка» — мелкие радиальные полосы
        self.soot_noise = smooth_noise(rnd, SAMPLES, 30)

    def polar(self):
        dx, dy = XX - self.cx, YY - self.cy
        return np.sqrt(dx * dx + dy * dy), np.arctan2(dy, dx)

    def petal_alpha(self, d, th, grow=0.0):
        R = lookup(self.edge, th) + grow
        return 1 - smooth(R - 1.2 * SS, R, d)

    def shadow_and_soot(self):
        """Тень лепестков на теле (сдвиг вниз-вправо, размыта) + лёгкая копоть вокруг."""
        d, th = self.polar()
        lay = np.zeros((N, N, 4), np.float32)
        R = lookup(self.edge, th)
        soot = 0.38 * (1 - smooth(R * 0.9, R * (1.35 + 0.15 * lookup(self.soot_noise, th)), d))
        dx, dy = XX - self.cx - 3 * SS, YY - self.cy - 3 * SS
        d2, th2 = np.sqrt(dx * dx + dy * dy), np.arctan2(dy, dx)
        shadow = 0.55 * self.petal_alpha(d2, th2, 2 * SS)
        a = 1 - (1 - soot) * (1 - shadow)
        lay[..., 0], lay[..., 1], lay[..., 2] = 0.05, 0.04, 0.035
        lay[..., 3] = a
        img = Image.fromarray((np.clip(lay, 0, 1) * 255).astype(np.uint8), 'RGBA').filter(ImageFilter.GaussianBlur(2.5 * SS))
        return np.asarray(img, dtype=np.float32) / 255

    def metal(self):
        d, th = self.polar()
        R = lookup(self.edge, th)
        rcore = lookup(self.core, th)
        u = np.clip((d - rcore) / np.maximum(R - rcore, 1), 0, 1)     # 0 — у провала, 1 — у края
        lit = np.cos(th - LIGHT)

        # металл: тёмный загиб в провал, светлое плечо, к краю чуть темнее
        v = 0.30 + 0.48 * smooth(0.0, 0.32, u) - 0.16 * smooth(0.55, 1.0, u)
        # лепесток вывернут наружу: сторона к свету светлее, особенно у плеча
        v += 0.32 * lit * (1 - 0.5 * u)
        # складки и шлифовка
        v += 0.19 * lookup(self.fold, th) * (0.4 + 0.6 * smooth(0.1, 0.5, u)) * np.clip(1 - u * 0.5, 0, 1)
        v += 0.05 * lookup(self.brush, th)
        # нагар у провала
        v *= 1 - 0.75 * np.exp(-(d - rcore) / (0.38 * self.rc))
        # кромка: тёмная линия по краю + блик внутри неё на свету
        edge_dist = R - d
        v *= 1 - 0.65 * np.exp(-(edge_dist / (1.3 * SS)) ** 2)
        v += 0.35 * np.exp(-((edge_dist - 3.2 * SS) / (1.2 * SS)) ** 2) * np.clip(lit, 0, 1) ** 2
        v = np.clip(v, 0, 1)
        rgb = np.stack([v * 0.94, v * 0.96, v * 1.0], axis=-1)       # холодный металл
        a = self.petal_alpha(d, th)

        # провал: чёрный, дальняя (к свету обращённая) стенка подсвечена
        q = np.clip(d / rcore, 0, 1)
        wall = smooth(0.5, 1.0, q) * np.clip(-lit, 0, 1) ** 1.3
        cv = 0.01 + 0.17 * wall
        core_rgb = np.stack([cv * 1.04, cv * 0.98, cv * 0.95], axis=-1)
        inside = 1 - smooth(rcore - 1.2 * SS, rcore, d)
        rgb = rgb * (1 - inside[..., None]) + core_rgb * inside[..., None]
        return np.concatenate([rgb, a[..., None]], axis=-1)


def render(holes):
    canvas = np.zeros((N, N, 4), np.float32)
    for h in holes:
        canvas = over(canvas, h.shadow_and_soot())
        canvas = over(canvas, h.metal())
    # сжатие в премультиплицированном виде — без каймы на краях
    pm = np.concatenate([canvas[..., :3] * canvas[..., 3:4], canvas[..., 3:4]], axis=-1)
    small = Image.fromarray((np.clip(pm, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGBA').resize((OUT, OUT), Image.LANCZOS)
    s = np.asarray(small, dtype=np.float32) / 255
    rgb = s[..., :3] / np.maximum(s[..., 3:4], 1e-4)
    out = np.concatenate([np.clip(rgb, 0, 1), s[..., 3:4]], axis=-1)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), 'RGBA')


base = open(os.path.join(HERE, 'billy_combo_mark.template'), encoding='utf-8').read()
assert 'materials/billy/billy_hole_0.vtex' in base
holes = [Hole(i, x, y) for i, (x, y) in enumerate(HOLES)]
for n in range(1, len(HOLES) + 1):
    name = 'billy_hole_%d' % n
    render(holes[:n]).save(os.path.join(HERE, name + '.png'))
    with open(os.path.join(HERE, name + '.vtex'), 'w', encoding='utf-8', newline='') as f:
        f.write(VTEX.replace('materials/hijikata/duel.png', 'materials/billy/%s.png' % name))
    with open(os.path.join(PART, 'billy_combo_mark_%d.vpcf' % n), 'w', encoding='utf-8', newline='\n') as f:
        f.write(base.replace('billy_hole_0.vtex', name + '.vtex'))
    print('saved', name)
