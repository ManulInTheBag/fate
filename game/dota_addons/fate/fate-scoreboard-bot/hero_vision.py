"""Identify a hero from its scoreboard PORTRAIT when the text OCR can't.

Every Fate hero overrides a base Dota hero, so each row shows that base hero's
fixed icon to the left of the name. Those icons are pixel-identical across boards
(only the resolution and the team-colour frame differ), which makes them a very
reliable visual key when the hero *name* text is unreadable.

We don't need the Dota game files: the library is SELF-BOOTSTRAPPING. `build`
(see build_portraits.py) scans boards where the text OCR confidently read the
hero, crops that hero's portrait, and stores it under the known name. At runtime
`match` compares an unknown row's portrait against every stored vector and
returns the nearest hero — but only when the similarity clears a gate, so a
genuinely-new/garbled icon stays Unknown rather than being mislabelled.

Representation: the portrait is cropped (relative to the name column so it tracks
cropped/zoomed boards), resized to a fixed square, the team-colour frame is
trimmed off, and the pixels are mean-subtracted + L2-normalised into a vector.
Similarity is the cosine (dot product) of two such vectors.
"""

import os
import cv2
import numpy as np

LIB_PATH = os.path.join(os.path.dirname(__file__), "data", "hero_portraits.npz")

# Portrait x-range, expressed in units of the NAME column's own WIDTH measured
# left from its left edge. Tying it to the column width (not a fixed image
# fraction) makes it scale correctly on cropped/zoomed boards, where the columns
# are recalibrated to a different scale than a full screenshot. Calibrated from
# real 16:9 boards: name col (0.500,0.600) -> portrait (0.479,0.512).
PORTRAIT_W0, PORTRAIT_W1 = -0.21, 0.12
_SIZE = 64          # normalise every portrait to this square
_BORDER = 7         # px trimmed off each side after resize (the team-colour frame)
# Default cosine-similarity gate to accept a portrait match. Tuned on real boards:
# >=0.60 keeps ~94% of rows at ~99% accuracy in leave-one-board-out CV.
DEFAULT_GATE = 0.60

_lib = None         # cached (vecs: (N,D) float32, labels: list[str])


def portrait_box(name_col):
    """(x0, x1) fractions of width for the portrait, left of the name column.
    Scaled by the name column's width so it tracks cropped/zoomed boards."""
    x0c = name_col[0]
    w = name_col[1] - name_col[0]
    return x0c + PORTRAIT_W0 * w, x0c + PORTRAIT_W1 * w


def vector(img, name_col, cy, pitch):
    """Crop the portrait for the row centred at `cy` and return its normalised
    feature vector, or None if the crop is empty."""
    h, w = img.shape[:2]
    x0, x1 = portrait_box(name_col)
    half = 0.45 * pitch
    cell = img[int((cy - half) * h):int((cy + half) * h),
               int(x0 * w):int(x1 * w)]
    return _vec(cell)


def _vec(cell):
    if cell is None or cell.size == 0:
        return None
    c = cv2.resize(cell, (_SIZE, _SIZE), interpolation=cv2.INTER_AREA)
    c = c[_BORDER:_SIZE - _BORDER, _BORDER:_SIZE - _BORDER]   # drop the frame
    # Slight blur before vectorising: the same hero's icon is cropped 1-2px
    # differently from board to board (resolution / calibration jitter), and a
    # raw-pixel cosine collapses under that. Blurring makes the descriptor
    # tolerant of small shifts — lifts leave-one-board-out accuracy ~98%->99.8%.
    c = cv2.GaussianBlur(c, (0, 0), 1.6)
    v = c.astype(np.float32).reshape(-1)
    v -= v.mean()                      # ignore overall brightness
    n = np.linalg.norm(v)
    return (v / n) if n > 1e-6 else None


def _load():
    global _lib
    if _lib is not None:
        return _lib
    if not os.path.exists(LIB_PATH):
        _lib = (np.zeros((0, 0), np.float32), [])
        return _lib
    z = np.load(LIB_PATH, allow_pickle=True)
    _lib = (z["vecs"].astype(np.float32), [str(x) for x in z["labels"]])
    return _lib


def available():
    """True if a non-empty portrait library is present."""
    vecs, labels = _load()
    return len(labels) > 0


def match(vec, gate=DEFAULT_GATE):
    """Nearest hero for a portrait vector. Returns (hero, similarity) when the
    best match clears `gate`, else (None, best_similarity)."""
    if vec is None:
        return None, 0.0
    vecs, labels = _load()
    if not labels or vecs.shape[1] != vec.shape[0]:
        return None, 0.0
    sims = vecs @ vec
    i = int(np.argmax(sims))
    s = float(sims[i])
    return (labels[i], s) if s >= gate else (None, s)


def save_library(vectors, labels):
    """Persist (list of vectors, parallel list of hero names) and refresh cache."""
    global _lib
    vecs = np.asarray(vectors, dtype=np.float32)
    np.savez_compressed(LIB_PATH, vecs=vecs, labels=np.array(labels, dtype=object))
    _lib = None
