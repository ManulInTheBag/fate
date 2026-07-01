"""Image -> raw scoreboard cells, using OpenCV preprocessing + Tesseract.

Strategy: the layout is fixed, so we never ask Tesseract to understand the
table. We (1) auto-detect the 12 player rows from the bright digits in the
kills/deaths/assists strip, then (2) crop each known column cell and OCR it on
its own with the right settings (digit whitelist for numbers, text for names).
"""

import os
import re
import cv2
import numpy as np
import pytesseract

import config

# Hiragana/Katakana + CJK Ext-A + CJK Unified Ideographs.
_CJK_RE = re.compile(r"[぀-ヿ㐀-䶿一-鿿]")

if config.TESSERACT_CMD:
    pytesseract.pytesseract.tesseract_cmd = config.TESSERACT_CMD


# ---------- low-level helpers ----------

def load_bgr(image_bytes: bytes) -> np.ndarray:
    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Could not decode image bytes.")
    return img


def _crop_frac(img, x0, x1, y0, y1):
    h, w = img.shape[:2]
    return img[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)]


def _prep(cell, scale=3, invert=True):
    """Grayscale, upscale, Otsu-threshold to black-on-white for Tesseract."""
    if cell.size == 0:
        return cell
    gray = cv2.cvtColor(cell, cv2.COLOR_BGR2GRAY)
    gray = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    _, th = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    # Text is light on dark -> Otsu makes text white. Tesseract wants dark text
    # on light, so invert.
    if invert:
        th = cv2.bitwise_not(th)
    th = cv2.copyMakeBorder(th, 12, 12, 12, 12, cv2.BORDER_CONSTANT, value=255)
    return th


def _clean_name(txt):
    txt = " ".join(txt.split()).strip()
    # The left table border sometimes reads as a leading "|"/"[" before the name.
    return txt.lstrip("|[] ").strip()


def _cjk_ratio(s):
    chars = [c for c in s if not c.isspace()]
    if not chars:
        return 0.0
    return sum(1 for c in chars if _CJK_RE.match(c)) / len(chars)


# ---------- engine dispatch ----------

def _use_easyocr():
    return config.OCR_ENGINE == "easyocr"


def ocr_int(cell):
    if _use_easyocr():
        import easyocr_backend
        return easyocr_backend.ocr_int(cell)
    # Tesseract: small 1-2 digit cells are flaky on a single PSM, so try a few.
    th = _prep(cell, scale=4)
    for psm in (7, 8, 6, 10):
        txt = pytesseract.image_to_string(
            th, config=f"--psm {psm} -c tessedit_char_whitelist=0123456789"
        )
        digits = "".join(c for c in txt if c.isdigit())
        if digits:
            return int(digits)
    return None


def ocr_text(cell, lang=None, cjk=False):
    """OCR a text cell. For names (cjk=True) a second CJK pass is used only when
    the result is MOSTLY CJK, so a stray hallucinated CJK char can't hijack a
    Latin name (e.g. "Skill Diff")."""
    if _use_easyocr():
        import easyocr_backend
        return easyocr_backend.ocr_text(cell, lang=lang, cjk=cjk)
    th = _prep(cell)
    primary = _clean_name(
        pytesseract.image_to_string(th, lang=lang or config.OCR_LANG, config="--psm 7")
    )
    if cjk and config.OCR_LANG_CJK:
        alt = _clean_name(
            pytesseract.image_to_string(th, lang=config.OCR_LANG_CJK, config="--psm 7")
        )
        if _cjk_ratio(alt) >= 0.5:
            return alt
    return primary


# ---------- row layout ----------

def _name_bright(img, name_col, cy, half=0.011):
    cell = _crop_frac(img, *name_col, cy - half, cy + half)
    if cell.size == 0:
        return 0.0
    gray = cv2.cvtColor(cell, cv2.COLOR_BGR2GRAY)
    return float((gray > 180).mean())


def _name_line_bands(img, name_col, cy, pitch):
    """Find the player line and hero line within a row by their brightness bands,
    so we split on the REAL gap between them rather than a fixed point. Returns a
    list of (y0, y1) fractions, top to bottom. Player = upper line, hero = lower."""
    ry0, ry1 = cy - 0.52 * pitch, cy + 0.52 * pitch
    region = _crop_frac(img, *name_col, ry0, ry1)
    if region.size == 0:
        return []
    gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY)
    rh = gray.shape[0]
    prof = (gray > 110).mean(axis=1).astype(np.float32)   # text = bright; bg dark
    k = max(1, int(0.06 * rh))
    if k > 1:
        prof = np.convolve(prof, np.ones(k) / k, mode="same")
    bands, start = [], None
    for i, on in enumerate(prof > 0.035):
        if on and start is None:
            start = i
        elif not on and start is not None:
            bands.append((start, i)); start = None
    if start is not None:
        bands.append((start, len(prof)))
    # keep real text lines (drop thin noise), as image fractions
    out = []
    for a, b in bands:
        if (b - a) >= 0.20 * rh:
            out.append((ry0 + (ry1 - ry0) * a / rh, ry0 + (ry1 - ry0) * b / rh))
    return out


def _split_at_gap(img, name_col, y0, y1):
    """The player (upper) and hero (lower) lines sometimes merge into one band
    (close together on Chinese boards). Split at the darkest row between them —
    the real gap — rather than the geometric middle, which mangles both lines."""
    region = _crop_frac(img, *name_col, y0, y1)
    if region.size == 0:
        return (y0 + y1) / 2
    gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY)
    rh = gray.shape[0]
    prof = (gray > 110).mean(axis=1).astype(np.float32)
    lo, hi = int(0.30 * rh), int(0.75 * rh)
    if hi - lo < 2:
        return (y0 + y1) / 2
    gi = lo + int(np.argmin(prof[lo:hi]))
    return y0 + (y1 - y0) * gi / rh


def _easyocr():
    import easyocr_backend
    return easyocr_backend


def _score_lines(lines, parser_mod, backend):
    """Annotate each detected name line with its best hero-match score, a player
    reading, and all candidate texts (for roster snapping)."""
    scored = []
    for ln in lines:
        cands = ln["cands"]
        hero_txt, hero_s = "", 0
        for t, _c in cands.values():           # best hero match across readers
            _h, s = parser_mod.match_hero(t)
            if s > hero_s:
                hero_txt, hero_s = t, s
        scored.append({"y": ln["y"], "hero_txt": hero_txt, "hero_s": hero_s,
                       "player": backend.pick_player(cands),
                       "ptexts": [t for t, _c in cands.values() if t]})
    return scored


def _assign_name(scored):
    """Decide which line is the hero and which is the player. Default: player on
    top, hero on the bottom line — but a line that *confidently* matches a known
    hero takes the hero slot (Chinese boards where the hero, with its "24级" level
    prefix, overruns the player line). Returns (player_line, hero_line) dicts,
    either of which may be None."""
    if not scored:
        return None, None
    scored.sort(key=lambda s: s["y"])
    if len(scored) == 1:
        ln = scored[0]
        return (None, ln) if ln["hero_s"] >= config.FUZZY_THRESHOLD else (ln, None)
    hero_line = scored[-1]                    # default: bottom line is the hero
    best = max(scored, key=lambda s: s["hero_s"])
    if best["hero_s"] >= config.FUZZY_THRESHOLD and best["hero_s"] > hero_line["hero_s"]:
        hero_line = best                     # a confident hero elsewhere wins
    others = [s for s in scored if s is not hero_line]
    return (others[0] if others else None), hero_line


def _read_name(img, cols, cy, pitch, parser_mod, backend):
    """Read one row's names. EasyOCR detects the name region's physical lines;
    we assign hero/player by the closed hero list. Returns
    (player_raw, hero_raw, player_cands) — player_cands are all reading variants,
    used later to snap to the roster."""
    if backend is None:
        p, h = _read_name_bands(img, cols, cy, pitch)
        return p, h, [p]
    region = _crop_frac(img, *cols["name"], cy - 0.5 * pitch, cy + 0.5 * pitch)
    scored = _score_lines(backend.read_name_lines(region), parser_mod, backend)
    player_line, hero_line = _assign_name(scored)
    player_raw = player_line["player"] if player_line else ""
    player_cands = player_line["ptexts"] if player_line else []
    hero_raw = (hero_line["hero_txt"] or hero_line["player"]) if hero_line else ""
    return player_raw, hero_raw, player_cands


def _read_name_bands(img, cols, cy, pitch):
    """Brightness-band split (Tesseract fallback path)."""
    bands = _name_line_bands(img, cols["name"], cy, pitch)
    pad = 0.04 * pitch
    if len(bands) >= 2:
        (py0, py1) = bands[0]; (hy0, hy1) = (bands[1][0], bands[-1][1])
    elif len(bands) == 1:
        b0, b1 = bands[0]; bm = _split_at_gap(img, cols["name"], b0, b1)
        py0, py1, hy0, hy1 = b0, bm, bm, b1
    else:
        hh = min(pitch * 0.46, 0.016)
        py0, py1, hy0, hy1 = cy - hh, cy, cy, cy + hh
    player = ocr_text(_crop_frac(img, *cols["name"], py0 - pad, py1 + pad), cjk=True)
    hero = ocr_text(_crop_frac(img, *cols["name"], hy0 - pad, hy1 + pad),
                    lang="eng", cjk=True)
    return player, hero


def _assign_kda(boxes, cols):
    """boxes: [(cx, value)] for one row. Assign each to the nearest of the
    kills/deaths/assists columns."""
    cc = {key: (cols[key][0] + cols[key][1]) / 2 for key in ("kills", "deaths", "assists")}
    vals = {"kills": None, "deaths": None, "assists": None}
    for cx, val in sorted(boxes):
        key = min(cc, key=lambda k: abs(cc[k] - cx))
        if vals[key] is None:
            vals[key] = val
    return vals["kills"], vals["deaths"], vals["assists"]


def _calibrate_columns(boxes):
    """Locate the table's real column positions from the digit grid, so we work
    on ANY crop/resolution — not just full screenshots. The K/D/A columns are the
    three densest small-number (0-99) columns; from them we derive a scale+offset
    that maps the reference layout (config.COLUMNS) onto this image. For a full
    screenshot the transform is ~identity. Returns (cols_dict, (kc, ac)) or
    (None, None) if the grid can't be read."""
    kc_ref = sum(config.COLUMNS["kills"]) / 2
    dc_ref = sum(config.COLUMNS["deaths"]) / 2
    ac_ref = sum(config.COLUMNS["assists"]) / 2

    xs = sorted(cx for (cx, _cy, v) in boxes if v is not None and v <= 99)
    if len(xs) < 9:
        return None, None
    clusters, cur = [], [xs[0]]
    for x in xs[1:]:
        if x - cur[-1] <= 0.015:              # same column
            cur.append(x)
        else:
            clusters.append(cur); cur = [x]
    clusters.append(cur)
    clusters = [c for c in clusters if len(c) >= 3]   # a column = many rows
    if len(clusters) < 3:
        return None, None
    clusters.sort(key=len, reverse=True)
    kc, dc, ac = sorted(sum(c) / len(c) for c in clusters[:3])   # K/D/A left->right

    denom = ac_ref - kc_ref
    if denom <= 0:
        return None, None
    s = (ac - kc) / denom                     # scale ref -> image
    o = kc - s * kc_ref                        # offset
    if not (0.2 < s < 5.0):                    # implausible -> bail
        return None, None
    if abs((s * dc_ref + o) - dc) > 0.02:      # middle anchor must agree
        return None, None

    def rm(name):
        a, b = config.COLUMNS[name]
        return (min(max(s * a + o, 0.0), 1.0), min(max(s * b + o, 0.0), 1.0))
    # When the transform is essentially identity (a normal full screenshot) keep
    # the exact reference columns — anchor-detection noise could otherwise nudge a
    # borderline hero cell and flip a good read into a misread. Only remap when
    # the layout genuinely differs (a cropped/zoomed table).
    nm, cfg = rm("name"), config.COLUMNS["name"]
    if abs(nm[0] - cfg[0]) < 0.02 and abs(nm[1] - cfg[1]) < 0.02:
        cols = {name: tuple(config.COLUMNS[name]) for name in config.COLUMNS}
    else:
        cols = {name: rm(name) for name in config.COLUMNS}
    return cols, (kc, ac)


def _rows_from_boxes(img, boxes, cols, kspan):
    """Cluster digit boxes (image fractions) lying in the K/D/A span into player
    rows -> [(cy, k, d, a)]."""
    kx0, kx1 = kspan
    m = 0.012
    kda = [b for b in boxes if b[2] is not None and b[2] <= 99
           and kx0 - m <= b[0] <= kx1 + m]
    if len(kda) < 6:
        return []
    kda.sort(key=lambda b: b[1])             # by vertical position
    groups, cur = [], [kda[0]]
    for b in kda[1:]:
        if b[1] - cur[0][1] < 0.012:          # same row (K/D/A share a height)
            cur.append(b)
        else:
            groups.append(cur); cur = [b]
    groups.append(cur)

    rows = []
    for grp in groups:
        cy = sum(b[1] for b in grp) / len(grp)
        k, d, a = _assign_kda([(b[0], b[2]) for b in grp], cols)
        # a real player row has K/D/A numbers AND a player name beside them; a
        # stray digit cluster (UI / header) has no name, so drop it.
        if sum(v is not None for v in (k, d, a)) >= 2 and \
                _name_bright(img, cols["name"], cy) > 0.008:
            rows.append((cy, k, d, a))
    rows.sort(key=lambda r: r[0])
    return rows


def detect_rows(img):
    """Find rows directly from the detected NUMBER positions (EasyOCR). Returns
    (rows, cols) where rows is a list of (cy, kills, deaths, assists) and cols is
    the column map for this image.

    Fast path: scan only the expected K/D/A strip with the reference columns —
    cheap, and right for any normal full screenshot. Slow path (crops / unusual
    layouts): scan the whole image and calibrate the columns from the digit grid.
    """
    import easyocr_backend
    cols = config.COLUMNS
    sx0, sx1 = cols["kills"][0], cols["assists"][1]
    y0f, y1f = config.ROW_SCAN
    strip = _crop_frac(img, sx0, sx1, y0f, y1f)
    raw = easyocr_backend.detect_digit_boxes(strip, scale=2.0)
    boxes = [(sx0 + (sx1 - sx0) * cx, y0f + (y1f - y0f) * cy, v) for (cx, cy, v) in raw]
    rows = _rows_from_boxes(img, boxes, cols, (cols["kills"][0], cols["assists"][1]))
    if len(rows) >= 6:
        return rows, cols

    # Fallback: full-image scan + column calibration (cropped/zoomed tables).
    boxes = easyocr_backend.detect_digit_boxes(img)
    cols, kspan = _calibrate_columns(boxes)
    if cols is None:
        return [], config.COLUMNS
    return _rows_from_boxes(img, boxes, cols, kspan), cols


# ---------- full extraction ----------

def extract(image_bytes: bytes, debug_name=None):
    img = load_bgr(image_bytes)
    rows, cols = detect_rows(img)
    found = len(rows) >= 6

    if len(rows) >= 2:
        pitch = float(np.median([b[0] - a[0] for a, b in zip(rows, rows[1:])]))
    else:
        pitch = 0.030
    hh = min(pitch * 0.46, 0.016)
    split = round(len(rows) / 2)

    import parser as parser_mod   # local parser.py (hero closed-set matcher)
    backend = _easyocr() if _use_easyocr() else None

    vision = None
    if config.HERO_VISION:
        import hero_vision
        if hero_vision.available():
            vision = hero_vision

    results = []
    for i, (cy, k, d, a) in enumerate(rows):
        player_raw, hero_raw, player_cands = _read_name(img, cols, cy, pitch, parser_mod, backend)
        # Portrait feature for the hero-by-icon fallback (used by parser when the
        # hero NAME text is unreadable). Kept on the row only until parsing; never
        # stored (it's a numpy vector).
        hero_vec = vision.vector(img, cols["name"], cy, pitch) if vision else None
        results.append({
            "team": "top" if i < split else "bottom",
            "player_raw": player_raw,
            "player_cands": player_cands,
            "hero_raw": hero_raw,
            "hero_vec": hero_vec,
            "kills": k, "deaths": d, "assists": a,
            "gold": None,
        })

    rows_y = [(cy - hh, cy + hh) for (cy, *_) in rows]
    sx0, sx1 = cols["score"]

    def _group_score(group):
        if not group:
            return None
        # the big score number is centered in the team block; read only the
        # central part so adjacent rows' digits don't bleed in.
        cy = (group[0][0] + group[-1][1]) / 2
        half = max((group[-1][1] - group[0][0]) * 0.3, 0.02)
        return ocr_int(_crop_frac(img, sx0, sx1, cy - half, cy + half))

    score_top = _group_score(rows_y[:split])
    score_bottom = _group_score(rows_y[split:])

    if debug_name:
        _save_debug(img, rows_y, cols, debug_name)

    # Decide whether this really is a scoreboard: the layout must have been
    # recognized AND most rows must contain actual K/D/A numbers. Random images
    # / chat screenshots / other UI screens fail one of these.
    n = len(results)
    with_nums = sum(1 for r in results
                    if any(r[k] is not None for k in ("kills", "deaths", "assists")))
    fill = (with_nums / n) if n else 0.0
    if not found:
        valid, reason = False, "layout not recognized"
    elif fill < 0.5:
        valid, reason = False, "no stats found"
    else:
        valid, reason = True, ""

    return {
        "rows": results,
        "split": split,
        "score_top": score_top,
        "score_bottom": score_bottom,
        "n_rows": len(results),
        "found": found,
        "valid": valid,
        "reason": reason,
    }


def _save_debug(img, rows_y, cols, name):
    os.makedirs(config.DEBUG_DIR, exist_ok=True)
    vis = img.copy()
    h, w = vis.shape[:2]

    def box(col, y0, y1, color):
        x0, x1 = col
        cv2.rectangle(vis, (int(x0 * w), int(y0 * h)), (int(x1 * w), int(y1 * h)), color, 2)

    for (y0, y1) in rows_y:
        for key, color in (
            ("name", (0, 255, 0)), ("score", (200, 200, 0)), ("kills", (255, 0, 0)),
            ("deaths", (0, 200, 255)), ("assists", (255, 0, 255)),
            ("gold", (0, 255, 255)),
        ):
            box(cols[key], y0, y1, color)
    path = os.path.join(config.DEBUG_DIR, name)
    cv2.imwrite(path, vis)
    return path
