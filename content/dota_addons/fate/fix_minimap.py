#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Убирает сетку тёмных линий, которую minimap_create впекает в миникарту
из-за сбоя депт-стенсила (dota_create_minimap_ds.vtex).

Артефакт — однопиксельные тёмные линии на регулярной сетке (период 64 px
при размере 512, смещения 7 и 56). Содержимое под ними не потеряно у
соседних пикселей, поэтому линии просто интерполируются из соседей.

Запуск:
    python fix_minimap.py materials/overviews/7vs7_common.tga
    python fix_minimap.py            # починит все .tga в materials/overviews

Оригинал сохраняется рядом как <имя>.tga.bak (если .bak уже есть — не
перезаписывается, чтобы не затереть чистую версию).
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OVERVIEWS = os.path.join(HERE, "materials", "overviews")

# насколько пиксель должен быть темнее соседей через один, чтобы считаться линией
DARKER_THAN = 15
# доля длины стороны, которую линия должна покрывать
MIN_COVERAGE = 0.10


def load_tga(path):
    d = bytearray(open(path, "rb").read())
    idlen = d[0]
    w, h, bpp, desc = struct.unpack_from("<HHBB", d, 12)
    if d[2] != 2 or bpp != 24:
        raise ValueError("ожидался несжатый 24-битный TGA, а тут type=%d bpp=%d" % (d[2], bpp))
    return d, 18 + idlen, w, h


def lum(d, off, w, x, y):
    i = off + (y * w + x) * 3
    return 0.299 * d[i + 2] + 0.587 * d[i + 1] + 0.114 * d[i]


def line_scores(d, off, w, h, vertical):
    """Для каждой координаты — сколько пикселей темнее обоих соседей через один."""
    n = w if vertical else h
    other = h if vertical else w
    out = [0] * n
    for a in range(2, n - 2):
        c = 0
        for b in range(2, other - 2):
            x, y = (a, b) if vertical else (b, a)
            v = lum(d, off, w, x, y)
            if vertical:
                if lum(d, off, w, x - 2, y) - v > DARKER_THAN and lum(d, off, w, x + 2, y) - v > DARKER_THAN:
                    c += 1
            else:
                if lum(d, off, w, x, y - 2) - v > DARKER_THAN and lum(d, off, w, x, y + 2) - v > DARKER_THAN:
                    c += 1
        out[a] = c
    return out


def periodic_offsets(scores, size):
    """Находит период и смещения сетки: берём уверенные линии и смотрим,
    на каких (период, смещение) они сидят. Это отсекает контуры зданий,
    которые в периодику не попадают."""
    strong = [i for i, v in enumerate(scores) if v > size * MIN_COVERAGE]
    if len(strong) < 4:
        return None, []
    for period in (64, 128, 32, 256):
        groups = {}
        for i in strong:
            groups.setdefault(i % period, []).append(i)
        # смещение считаем настоящим, если на нём сидит минимум треть возможных позиций
        need = max(2, (size // period) // 3)
        offs = sorted(o for o, v in groups.items() if len(v) >= need)
        covered = sum(len(groups[o]) for o in offs)
        if offs and covered >= len(strong) * 0.6:
            return period, offs
    return None, []


def repair(path):
    d, off, w, h = load_tga(path)

    vs = line_scores(d, off, w, h, True)
    hs = line_scores(d, off, w, h, False)
    pv, ov = periodic_offsets(vs, h)
    ph, oh = periodic_offsets(hs, w)
    period = pv or ph
    if not period:
        print("  %s: регулярной сетки не найдено, файл не тронут" % os.path.basename(path))
        return False

    offs = sorted(set(ov) | set(oh))
    cols = [x for x in range(1, w - 1) if x % period in offs]
    rows = [y for y in range(1, h - 1) if y % period in offs]
    print("  период %d px, смещения %s -> %d столбцов, %d строк"
          % (period, offs, len(cols), len(rows)))

    bak = path + ".bak"
    if not os.path.exists(bak):
        open(bak, "wb").write(bytes(d))
        print("  оригинал сохранён: %s" % os.path.basename(bak))

    colset, rowset = set(cols), set(rows)

    def blend(x0, y0, x1, y1, xt, yt):
        ia = off + (y0 * w + x0) * 3
        ib = off + (y1 * w + x1) * 3
        it = off + (yt * w + xt) * 3
        for k in range(3):
            d[it + k] = (d[ia + k] + d[ib + k]) // 2

    for x in cols:
        lo = x - 1
        hi = x + 1
        while lo > 0 and lo in colset:
            lo -= 1
        while hi < w - 1 and hi in colset:
            hi += 1
        for y in range(h):
            blend(lo, y, hi, y, x, y)
    for y in rows:
        lo = y - 1
        hi = y + 1
        while lo > 0 and lo in rowset:
            lo -= 1
        while hi < h - 1 and hi in rowset:
            hi += 1
        for x in range(w):
            blend(x, lo, x, hi, x, y)

    open(path, "wb").write(bytes(d))
    print("  готово: %s" % os.path.basename(path))
    return True


def main():
    args = sys.argv[1:]
    if args:
        targets = [a if os.path.isabs(a) else os.path.join(HERE, a) for a in args]
    else:
        targets = [os.path.join(OVERVIEWS, f)
                   for f in sorted(os.listdir(OVERVIEWS)) if f.lower().endswith(".tga")]
    for t in targets:
        print(os.path.basename(t))
        try:
            repair(t)
        except Exception as e:
            print("  ошибка: %s" % e)


if __name__ == "__main__":
    main()
