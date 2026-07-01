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

import config

_CJK_RE = re.compile(r"[぀-ヿ㐀-䶿一-鿿]")
_KANA_RE = re.compile(r"[぀-ゟ゠-ヿ]")   # hiragana + katakana => Japanese
_CYR_RE = re.compile(r"[А-Яа-яЁё]")     # Cyrillic
_readers = {}
_gpu = None   # resolved once, lazily


def _use_gpu():
    """Decide whether EasyOCR should use the GPU, honoring config.OCR_GPU. Auto
    mode (and forced mode) require a CUDA build of torch that can actually see a
    device; we never claim the GPU when torch can't, so the bot still runs on the
    default '+cpu' wheel."""
    global _gpu
    if _gpu is not None:
        return _gpu
    setting = config.OCR_GPU
    if setting in ("0", "false", "no", "off"):
        _gpu = False
        return _gpu
    try:
        import torch
        _gpu = bool(torch.cuda.is_available())
    except Exception:
        _gpu = False
    return _gpu


def _reader(langs):
    if langs not in _readers:
        _readers[langs] = easyocr.Reader(list(langs), gpu=_use_gpu(), verbose=False)
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


def _read_text(langs, cell, allowlist=None):
    """Return (cleaned_text, mean_confidence)."""
    res = _read(langs, cell, allowlist)
    text = _clean_name(_join(res))
    conf = (sum(c for (_b, _t, c) in res) / len(res)) if res else 0.0
    return text, conf


def _boxes(langs, up):
    """readtext -> [(yc_frac, x0, text, conf)] on an already-upscaled image."""
    H = up.shape[0]
    out = []
    for bb, t, c in _reader(langs).readtext(up, detail=1, paragraph=False):
        ys = [p[1] for p in bb]; xs = [p[0] for p in bb]
        out.append(((min(ys) + max(ys)) / 2 / H, min(xs), t, c))
    return out


def column_boxes(region, langs, scale=3.0, otsu=False):
    """Detect text in `region` with one readtext pass and return its boxes as
    [(yc_frac, x0_frac, text, conf)] (fractions of the region). Used to read the
    WHOLE name column in a single detection per reader instead of re-cropping and
    re-detecting every row. `otsu` binarizes first, which sharpens thin stylized
    Cyrillic strokes (helps names like "шешня")."""
    if region is None or region.size == 0:
        return []
    up = cv2.resize(region, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    if otsu:
        g = cv2.cvtColor(up, cv2.COLOR_BGR2GRAY)
        _, b = cv2.threshold(g, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        up = cv2.cvtColor(b, cv2.COLOR_GRAY2BGR)
    H, W = up.shape[:2]
    out = []
    for bb, t, c in _reader(langs).readtext(up, detail=1, paragraph=False):
        ys = [p[1] for p in bb]; xs = [p[0] for p in bb]
        out.append(((min(ys) + max(ys)) / 2 / H, min(xs) / W, _clean_name(t), c))
    return out


def _otsu(up):
    g = cv2.cvtColor(up, cv2.COLOR_BGR2GRAY)
    _, b = cv2.threshold(g, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return cv2.cvtColor(b, cv2.COLOR_GRAY2BGR)


def read_name_lines(region):
    """Use EasyOCR's OWN text detection to split a name region into its physical
    lines (player on top, hero below) — far more reliable than brightness bands.

    The Latin/Cyrillic pass (en+ru) always runs; the others are added only when
    that read shows they're needed, so most rows cost just 1-2 detections:
      - "cn"   Chinese — when a line reads as junk (the cell is really CJK)
      - "enrub" OTSU-binarized en+ru — when a line has Cyrillic (binarizing
                sharpens thin stylized strokes, e.g. "шешня" vs "пепня")
      - "ja"   Japanese — only when a line is otherwise unreadable

    Returns lines top-to-bottom: {"y": y_center_frac, "cands": {tag: (text, conf)}}."""
    if region is None or region.size == 0:
        return []
    up = cv2.resize(region, None, fx=3, fy=3, interpolation=cv2.INTER_CUBIC)

    def group(items):
        items = sorted(items, key=lambda r: r[0])
        groups, cur = [], [items[0]]
        for it in items[1:]:
            if it[0] - cur[-1][0] <= 0.20:    # same physical line
                cur.append(it)
            else:
                groups.append(cur); cur = [it]
        groups.append(cur)
        return groups

    def line_cands(g):
        cands, bytag = {}, {}
        for _yc, x0, t, c, tag in g:
            bytag.setdefault(tag, []).append((x0, t, c))
        for tag, lst in bytag.items():
            lst.sort()
            cands[tag] = (_clean_name(" ".join(t for _, t, _ in lst)),
                          sum(c for _, _, c in lst) / len(lst))
        return cands

    def build(tagged):
        return [{"y": sum(x[0] for x in g) / len(g), "cands": line_cands(g)}
                for g in group(tagged)]

    tagged = [(*b, "enru") for b in _boxes(("en", "ru"), up)]
    if not tagged:
        return []
    enru_texts = [t for (_y, _x, t, _c, _tag) in tagged]
    if any(_alpha_ratio(t) < 0.5 for t in enru_texts if t):     # a CJK cell
        tagged += [(*b, "cn") for b in _boxes(("ch_sim", "en"), up)]
    if any(_CYR_RE.search(t or "") for t in enru_texts):        # stylized Cyrillic
        tagged += [(*b, "enrub") for b in _boxes(("en", "ru"), _otsu(up))]

    lines = build(tagged)
    # Last resort: a line nobody read confidently and that isn't CJK -> try JA.
    def unexplained(ln):
        cn = ln["cands"].get("cn", ("", 0))
        best = max((c for _t, c in ln["cands"].values()), default=0)
        return best < 0.40 and _cjk_ratio(cn[0]) < 0.5
    if any(unexplained(ln) for ln in lines):
        lines = build(tagged + [(*b, "ja") for b in _boxes(("ja", "en"), up)])
    return lines


def _cjk_ratio(s):
    chars = [c for c in s if not c.isspace()]
    if not chars:
        return 0.0
    return sum(1 for c in chars if _CJK_RE.match(c)) / len(chars)


def _alpha_ratio(s):
    """Fraction of non-space chars that are letters. A real name (Latin/Cyrillic)
    is ~1.0; OCR junk from reading CJK with the wrong model ("4з;") is low."""
    chars = [c for c in (s or "") if not c.isspace()]
    if not chars:
        return 0.0
    return sum(1 for c in chars if c.isalpha()) / len(chars)


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


def detect_digit_boxes(region, scale=None):
    """Detect every number in `region`, returning [(cx, cy, value)] as fractions
    of the region. Used to find the table rows directly from where the K/D/A
    numbers actually are (robust to resolution / team size). `scale` upscales the
    region before detection; if None it's chosen to keep the result around 1600px
    wide while capping height, so a narrow strip isn't blown up vertically."""
    if region is None or region.size == 0:
        return []
    h, w = region.shape[:2]
    if scale is None:
        scale = min(max(1.0, 1600.0 / w), 2000.0 / h)
        scale = max(scale, 1.0)
    up = cv2.resize(region, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC) \
        if scale > 1.0 else region
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


def pick_player(cands):
    """Choose a player-name reading from per-reader candidates {tag: (text, conf)}.
    Default to the Latin/Cyrillic read; only switch to a CJK read when it's
    clearly more confident, so a real Cyrillic name isn't replaced by a CJK
    hallucination."""
    best_t, best_c = cands.get("enru", ("", 0.0))
    cn = cands.get("cn")
    # Take the Chinese read when the cell is genuinely Chinese: either it's more
    # confident, OR the Latin/Cyrillic read came back as junk (low letter ratio),
    # which is what happens when the en/ru model is fed a CJK name ("夏霧" -> "4з;").
    if cn and _cjk_ratio(cn[0]) >= 0.5 and (cn[1] > best_c + 0.10 or _alpha_ratio(best_t) < 0.6):
        best_t, best_c = cn
    ja = cands.get("ja")
    if ja and ja[0] and _KANA_RE.search(ja[0]) and _cjk_ratio(ja[0]) >= 0.6 \
            and ja[1] > best_c + 0.10:
        best_t, best_c = ja
    return best_t


def ocr_text(cell, lang=None, cjk=False):
    # Latin/Cyrillic pass.
    en_t, en_c = _read_text(("en",), cell)
    if lang == "eng":
        # Heroes are English (or Chinese) — never Cyrillic, so don't use the ru
        # model (which turns Latin glyphs like "b" into Cyrillic look-alikes).
        best_t, best_c = en_t, en_c
    else:
        # Player names: en AND en+ru, keep the higher-confidence (slight en bias
        # so single Latin chars like "b" don't become Cyrillic "Ъ").
        ru_t, ru_c = _read_text(("en", "ru"), cell)
        best_t, best_c = (en_t, en_c) if en_c + 0.05 >= ru_c else (ru_t, ru_c)
    if cjk:
        cn_t, cn_c = _read_text(("ch_sim", "en"), cell)
        if _cjk_ratio(cn_t) >= 0.5:
            if lang == "eng":
                # Heroes are only Latin or Chinese: if the cell reads as Chinese,
                # that IS the hero (the en read is always garbage like "244 IJEE").
                best_t, best_c = cn_t, cn_c
            elif cn_c > best_c + 0.10:
                # Players may be Cyrillic: only take the Chinese read when it's
                # clearly more confident, so "шешня" isn't replaced by "川eワ".
                best_t, best_c = cn_t, cn_c
        if lang is None:
            ja_t, ja_c = _read_text(("ja", "en"), cell)
            if ja_t and _KANA_RE.search(ja_t) and _cjk_ratio(ja_t) >= 0.6 \
                    and ja_c > best_c + 0.10:
                best_t, best_c = ja_t, ja_c
    return best_t
