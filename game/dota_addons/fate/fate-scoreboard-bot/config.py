"""Configuration + OCR crop calibration.

All crop coordinates are FRACTIONS of the image width/height (0.0-1.0) so they
work regardless of the screenshot resolution, as long as the scoreboard panel
sits in the same place. They are calibrated for the standard 16:9 end-of-round
scoreboard. If your crops are off, run:

    python calibrate.py path\to\a_scoreboard.png

which saves an overlay image showing exactly where each column/row is read,
then tweak the numbers below until the boxes line up.
"""

import os
from dotenv import load_dotenv

load_dotenv()

# ---- Discord / runtime ----
DISCORD_TOKEN = os.getenv("DISCORD_TOKEN", "")


def _id_set(name):
    return {int(x) for x in os.getenv(name, "").replace(" ", "").split(",") if x}


# Channel(s) the bot SILENTLY reads scoreboards from. It never posts or reacts
# here. Comma-separated IDs allowed (e.g. several servers' scoreboard channels).
WATCH_CHANNEL_IDS = _id_set("WATCH_CHANNEL_IDS") or _id_set("WATCH_CHANNEL_ID")

# The bot's OWN channel (in your private server): every parsed scoreboard is
# posted here for review, all stats/exports are sent here, and all commands are
# accepted here. The bot only ever "talks" in this channel.
CONTROL_CHANNEL_ID = int(os.getenv("CONTROL_CHANNEL_ID", "0") or "0")

# If True, scoreboards are saved to stats automatically (the review post in the
# control channel is informational, still correctable). If False, a match only
# counts after you react ✅ on its review post.
AUTO_CONFIRM = os.getenv("AUTO_CONFIRM", "false").strip().lower() in ("1", "true", "yes")

ADMIN_USER_IDS = _id_set("ADMIN_USER_IDS")
TESSERACT_CMD = os.getenv("TESSERACT_CMD", "").strip()

# Player names mix scripts, and Tesseract can't read Latin+Cyrillic+CJK reliably
# in a single pass (CJK gets mangled). So names use TWO passes: a Latin/Cyrillic
# pass (OCR_LANG) and a CJK pass (OCR_LANG_CJK). The CJK result is used only when
# it actually contains CJK characters. Set OCR_LANG_CJK empty to disable the CJK
# pass. Digits never use either.
OCR_LANG = os.getenv("OCR_LANG", "eng").strip() or "eng"
OCR_LANG_CJK = os.getenv("OCR_LANG_CJK", "").strip()

# Which OCR engine to use: "easyocr" (deep-learning, far more accurate, needs the
# easyocr package) or "tesseract" (lighter fallback). EasyOCR ignores OCR_LANG*.
OCR_ENGINE = os.getenv("OCR_ENGINE", "easyocr").strip().lower()

# Run EasyOCR on the GPU (CUDA) when possible — much faster than CPU. "auto"
# (default) uses the GPU whenever a CUDA build of torch can see one, and silently
# falls back to CPU otherwise; "1"/"true" forces it; "0"/"false" disables it.
# Needs a CUDA build of torch (the default "+cpu" wheel never sees the GPU).
OCR_GPU = os.getenv("OCR_GPU", "auto").strip().lower()

# When the hero NAME text can't be read, fall back to matching the hero PORTRAIT
# icon against a learned library (hero_vision / data/hero_portraits.npz, built by
# build_portraits.py). "1"/"true" (default) on; "0"/"false" off. The match is
# accepted only above HERO_VISION_GATE (cosine similarity), else the hero stays
# Unknown for manual review.
HERO_VISION = os.getenv("HERO_VISION", "true").strip().lower() in ("1", "true", "yes", "on")
HERO_VISION_GATE = float(os.getenv("HERO_VISION_GATE", "0.60"))

DB_PATH = os.path.join(os.path.dirname(__file__), "data", "scoreboards.db")
EXPORT_PATH = os.path.join(os.path.dirname(__file__), "data", "fate_stats.xlsx")
DEBUG_DIR = os.path.join(os.path.dirname(__file__), "data", "debug")

# Players per team. These scoreboards are 6v6.
PLAYERS_PER_TEAM = 6

# Fuzzy-match acceptance threshold (0-100). Below this we keep the raw OCR text
# and flag the cell for manual correction.
FUZZY_THRESHOLD = 78

# ---- Crop columns (fractions of width) ----
# Dota's scoreboard scales uniformly on 16:9, so these column fractions are the
# same at 1600x900 / 1920x1080 / 2560x1440. ROWS are found adaptively from image
# content (see ocr.detect_rows), so only the columns are calibrated here.
COLUMNS = {
    "name":    (0.500, 0.600),   # player (upper line) + hero (lower line)
    "score":   (0.606, 0.640),   # big team-score number
    "kills":   (0.645, 0.669),
    "deaths":  (0.670, 0.696),
    "assists": (0.697, 0.722),
    "gold":    (0.858, 0.893),
}

# Vertical window (fraction of height) the table can occupy, and the largest
# team size to expect.
ROW_SCAN = (0.13, 0.63)
MAX_TEAM = 8
