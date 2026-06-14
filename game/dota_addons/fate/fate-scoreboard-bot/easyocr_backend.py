"""EasyOCR backend — a deep-learning OCR that's much more accurate than
Tesseract on stylized game fonts and CJK.

Readers are heavy, so they're created lazily and cached. We use:
  - ('en','ru')   Latin + Cyrillic  -> numbers, most player names, English heroes
  - ('ch_sim','en') Chinese + Latin -> Chinese heroes / Chinese player names

First use downloads the model files (~tens of MB) once.
"""

import re
import cv2
import easyocr

_CJK_RE = re.compile(r"[぀-ヿ㐀-䶿一-鿿]")
_KANA_RE = re.compile(r"[぀-ゟ゠-ヿ]")   # hiragana + katakana => Japanese
_readers = {}


def _reader(langs):
    if langs not in _readers:
        _readers[langs] = easyocr.Reader(list(langs), gpu=False, verbose=False)
    return _readers[langs]


def _read(langs, cell, allowlist=None):
    if cell is None or cell.size == 0:
        return []
    up = cv2.resize(cell, None, fx=3, fy=3, interpolation=cv2.INTER_CUBIC)
    kw = {"detail": 1, "paragraph": False}
    if allowlist:
        kw["allowlist"] = allowlist
    res = _reader(langs).readtext(up, **kw)
    res.sort(key=lambda r: r[0][0][0])   # left-to-right
    return res


def _join(res):
    return " ".join(t for (_b, t, _c) in res).strip()


def _cjk_ratio(s):
    chars = [c for c in s if not c.isspace()]
    if not chars:
        return 0.0
    return sum(1 for c in chars if _CJK_RE.match(c)) / len(chars)


def _clean_name(txt):
    return " ".join(txt.split()).strip().lstrip("|[] ").strip()


def warmup():
    """Load the readers up front (so the first scoreboard isn't slow)."""
    _reader(("en", "ru"))
    _reader(("ch_sim", "en"))
    _reader(("ja", "en"))


def ocr_int(cell):
    digits = "".join(c for (_b, t, _c) in _read(("en", "ru"), cell, allowlist="0123456789")
                     for c in t if c.isdigit())
    return int(digits) if digits else None


def detect_digit_boxes(region):
    """Detect every number in `region`, returning [(cx, cy, value)] as fractions
    of the region. Used to find the table rows directly from where the K/D/A
    numbers actually are (robust to resolution / team size)."""
    if region is None or region.size == 0:
        return []
    up = cv2.resize(region, None, fx=2.5, fy=2.5, interpolation=cv2.INTER_CUBIC)
    H, W = up.shape[:2]
    out = []
    for bb, text, _conf in _reader(("en", "ru")).readtext(
            up, allowlist="0123456789", detail=1, paragraph=False):
        t = "".join(c for c in text if c.isdigit())
        if not t:
            continue
        xs = [float(p[0]) for p in bb]; ys = [float(p[1]) for p in bb]
        out.append(((min(xs) + max(xs)) / 2 / W, (min(ys) + max(ys)) / 2 / H, int(t)))
    return out


def ocr_text(cell, lang=None, cjk=False):
    primary = _clean_name(_join(_read(("en", "ru"), cell)))
    if cjk:
        cn = _clean_name(_join(_read(("ch_sim", "en"), cell)))
        # Player names can be Japanese (lang is None); heroes can't (lang="eng").
        ja = _clean_name(_join(_read(("ja", "en"), cell))) if lang is None else ""
        # use the JA read only when it's genuinely Japanese (kana AND mostly CJK),
        # so a Latin/Cyrillic name isn't turned into a stray katakana char.
        if _KANA_RE.search(ja) and _cjk_ratio(ja) >= 0.6:
            return ja
        if _cjk_ratio(cn) >= 0.5:
            return cn
    return primary
