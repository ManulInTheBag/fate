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


def detect_rows(img):
    """Find rows directly from the detected NUMBER positions (EasyOCR). Each
    player row is a cluster of K/D/A digit boxes at one height. Returns a list of
    (cy, kills, deaths, assists). Robust to resolution, team size, and ignores
    the header (which has no digits)."""
    import easyocr_backend
    cols = config.COLUMNS
    y0f, y1f = config.ROW_SCAN
    sx0, sx1 = cols["kills"][0], cols["assists"][1]
    region = _crop_frac(img, sx0, sx1, y0f, y1f)
    raw = easyocr_backend.detect_digit_boxes(region)
    boxes = [(sx0 + (sx1 - sx0) * cx, y0f + (y1f - y0f) * cy, val) for (cx, cy, val) in raw]
    if len(boxes) < 6:
        return []

    boxes.sort(key=lambda b: b[1])           # by vertical position
    groups, cur = [], [boxes[0]]
    for b in boxes[1:]:
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


# ---------- full extraction ----------

def extract(image_bytes: bytes, debug_name=None):
    img = load_bgr(image_bytes)
    cols = config.COLUMNS
    rows = detect_rows(img)
    found = len(rows) >= 6

    if len(rows) >= 2:
        pitch = float(np.median([b[0] - a[0] for a, b in zip(rows, rows[1:])]))
    else:
        pitch = 0.030
    hh = min(pitch * 0.46, 0.016)
    split = round(len(rows) / 2)

    results = []
    for i, (cy, k, d, a) in enumerate(rows):
        y0, y1 = cy - hh, cy + hh
        name_cell = _crop_frac(img, *cols["name"], y0, y1)
        player_cell = _crop_frac(img, *cols["name"], y0, cy)
        hero_cell = _crop_frac(img, *cols["name"], cy, y1)
        results.append({
            "team": "top" if i < split else "bottom",
            "player_raw": ocr_text(player_cell, cjk=True) or ocr_text(name_cell, cjk=True),
            "hero_raw": ocr_text(hero_cell, lang="eng", cjk=True),
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
