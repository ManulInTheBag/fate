"""Auto-derive a crop profile for a scoreboard resolution using EasyOCR.

EasyOCR detects WHERE every number is; from the digit boxes we recover the
K/D/A/gold columns and the row positions precisely, then place name/score
relative to them. Run on a clean scoreboard:

    python calibrate_auto.py data\debug\1.png

It prints a PROFILES entry to paste into config.py.
"""
import sys, statistics
import cv2, easyocr

_reader = None
def reader():
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(['en'], gpu=False, verbose=False)
    return _reader


def boxes(img):
    h, w = img.shape[:2]
    out = []
    for bb, text, conf in reader().readtext(img):
        xs = [p[0] for p in bb]; ys = [p[1] for p in bb]
        out.append(dict(x0=min(xs)/w, x1=max(xs)/w, cx=(min(xs)+max(xs))/2/w,
                        y0=min(ys)/h, y1=max(ys)/h, cy=(min(ys)+max(ys))/2/h,
                        hgt=(max(ys)-min(ys))/h, text=text.strip()))
    return out


def cluster(items, key, tol):
    items = sorted(items, key=key)
    groups = []
    for it in items:
        if groups and key(it) - key(groups[-1][-1]) <= tol:
            groups[-1].append(it)
        else:
            groups.append([it])
    return groups


def main():
    img = cv2.imread(sys.argv[1])
    h, w = img.shape[:2]
    bx = boxes(img)
    # only the right-side table area, ignore tiny noise
    digits = [b for b in bx if b["text"].isdigit() and b["cx"] > 0.45 and 0.05 < b["cy"] < 0.65]

    # rows: cluster the y of digit boxes (use the most populated x-columns later,
    # but first get pitch from all). Cluster cy.
    ny = cluster(digits, lambda b: b["cy"], tol=0.012)
    rowys = [statistics.mean(b["cy"] for b in g) for g in ny if len(g) >= 3]
    rowys.sort()
    if len(rowys) < 4:
        print("Could not find rows — is this a clean scoreboard?"); return
    gaps = [b - a for a, b in zip(rowys, rowys[1:])]
    pitch = statistics.median(g for g in gaps if g < 1.5 * statistics.median(gaps))
    # team divider = a gap slightly bigger than pitch (not a whole missing row)
    divider = [g for g in gaps if 1.12 * pitch < g < 1.7 * pitch]
    team_gap = (statistics.median(divider) - pitch) if divider else 0.22 * pitch
    top_first = rowys[0]

    # columns: cluster digit cx into vertical columns, keep "full" ones
    nx = cluster(digits, lambda b: b["cx"], tol=0.012)
    cols = [(statistics.mean(b["cx"] for b in g),
             statistics.mean(b["x0"] for b in g),
             statistics.mean(b["x1"] for b in g), len(g),
             [b["text"] for b in g]) for g in nx]
    full = [c for c in cols if c[3] >= max(4, 0.4 * len(rowys))]
    full.sort()
    # drop a leading "level" column (all equal values, e.g. all '24')
    if full and len(set(full[0][4])) <= 2:
        full = full[1:]
    if len(full) < 4:
        print("Found columns:", [(round(c[0], 3), c[3]) for c in cols]); return
    kills, deaths, assists = full[0], full[1], full[2]
    gold = full[-1]

    def band(c, pad=0.004):
        return (round(float(c[1]) - pad, 3), round(float(c[2]) + pad, 3))

    # score: tall boxes left of kills (big font, 1-2 of them)
    score_bx = [b for b in bx if b["text"].isdigit() and b["cx"] < kills[0]
                and b["cx"] > 0.5 and b["hgt"] > 1.4 * statistics.median(b2["hgt"] for b2 in digits)]
    if score_bx:
        sc = (round(float(min(b["x0"] for b in score_bx)) - 0.004, 3),
              round(float(max(b["x1"] for b in score_bx)) + 0.004, 3))
    else:
        sc = (round(float(kills[1]) - 0.05, 3), round(float(kills[1]) - 0.02, 3))

    # name column: text (non-digit) boxes left of the score, aligned with rows
    names = [b for b in bx if not b["text"].isdigit() and b["cx"] < sc[0] and b["cx"] > 0.40
             and 0.05 < b["cy"] < 0.6 and len(b["text"]) >= 2]
    if names:
        nx0 = round(float(statistics.median([b["x0"] for b in names])) - 0.005, 3)
        nx1 = round(float(max(statistics.quantiles([b["x1"] for b in names], n=4)[2], sc[0] - 0.005)), 3)
    else:
        nx0, nx1 = round(sc[0] - 0.10, 3), round(sc[0] - 0.005, 3)

    print(f"\n    ({w}, {h}): {{")
    print(f'        "COLUMNS": {{')
    print(f'            "name":    ({nx0}, {nx1}),')
    print(f'            "score":   {sc},')
    print(f'            "kills":   {band(kills)},')
    print(f'            "deaths":  {band(deaths)},')
    print(f'            "assists": {band(assists)},')
    print(f'            "gold":    {band(gold)},')
    print(f'        }},')
    print(f'        "ROWS": {{"top_first_y": {round(top_first,4)}, "pitch": {round(pitch,4)}, '
          f'"team_gap": {round(max(team_gap,0.002),4)},')
    print(f'                 "row_height": {round(min(pitch*0.92,0.034),4)}, "max_team": 8}},')
    print(f"    }},")
    print(f"\n# detected {len(rowys)} rows, {n_team} per team, pitch {pitch:.4f}")


if __name__ == "__main__":
    main()
