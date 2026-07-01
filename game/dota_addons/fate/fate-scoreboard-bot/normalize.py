"""Clean up stored values at stats/export time (non-destructive).

- Heroes are a CLOSED set of 51, so we snap each stored hero to the nearest
  known hero (fixes OCR near-misses like "Vlad Ill" -> "Vlad III"); anything too
  far off (OCR garbage like "PS", "aie sory ws") becomes "Unknown".
- Players are an OPEN set, so we can't auto-snap, but we resolve names through
  the alias map (set via `%alias`) to merge alt accounts / OCR variants onto one
  canonical name.
- Some player cells are the HERO cell bleeding in (e.g. "Demon king Nobunaga
  24-го") or pure OCR mush with bracket junk ("GOLDEN DUCK! [CEI"). `debleed_player`
  strips the servant name + the in-game day counter + bracket junk and tries to
  recover the real regular from the roster, falling back to Unknown.
"""

import re

from rapidfuzz import process, fuzz

import heroes as heroes_mod
import roster as roster_mod

_HERO_SET = set(heroes_mod.HEROES)
_SEEDS = list(roster_mod.PLAYERS)        # clean canonical player names
UNKNOWN_HERO = "Unknown"


def snap_player(name):
    """Snap a player name to a known clean roster name if it's clearly the same
    (case-insensitive, similar length) — fixes OCR variants like "Cute Iute" ->
    "cute lute"."""
    if not name or name in _SEEDS:
        return name
    best = process.extractOne(name, _SEEDS, scorer=fuzz.ratio, processor=str.lower)
    if best and best[1] >= 80:           # same spirit as the live match threshold
        return best[0]
    return name

# Snapping a stored hero to the closest known one is more lenient than the live
# match threshold: "Vlad Ill" scores ~75 vs "Vlad III" while OCR garbage stays
# at/below ~60, so 72 cleanly separates them.
_HERO_SNAP = 72
_CN = getattr(heroes_mod, "CHINESE", {})
_HERO_CANDIDATES = heroes_mod.HEROES + list(_CN.keys())


def clean_hero(name):
    if not name:
        return UNKNOWN_HERO
    if name in _HERO_SET:
        return name
    if name in _CN:                          # exact Chinese (Fate) name
        return _CN[name]
    key = name.strip().lower()
    if heroes_mod.ALIASES and key in heroes_mod.ALIASES:
        return heroes_mod.ALIASES[key]
    best = process.extractOne(name, _HERO_CANDIDATES, scorer=fuzz.ratio,
                              processor=str.lower)
    if best and best[1] >= _HERO_SNAP:
        return _CN.get(best[0], best[0])     # map Chinese -> English
    return UNKNOWN_HERO


UNKNOWN_PLAYER = "Unknown"
# A player name this close to a hero name is almost certainly the hero cell
# bleeding into the player cell (e.g. "Bhan king Nobunaga" = Demon king Nobunaga).
# (fuzz.ratio scale: real players score <50, hero-bleed >=78.)
PLAYER_AS_HERO = 78


def hero_match_score(name):
    if not name:
        return 0
    if name in _HERO_SET:
        return 100
    best = process.extractOne(name, heroes_mod.HEROES, scorer=fuzz.ratio,
                              processor=str.lower)
    return int(best[1]) if best else 0


def resolve_player(name, alias_map):
    """Follow alias links to the end, so chains resolve fully
    (e.g. МозКез -> MeskesAcabe -> MoskesAcabe). Cycle-safe."""
    if not name:
        return name
    cur = name
    seen = set()
    for _ in range(20):
        key = cur.strip().lower()
        if key in seen:
            break
        seen.add(key)
        nxt = alias_map.get(key)
        if nxt is None or nxt == cur:
            break
        cur = nxt
    return cur


# ---- hero-cell bleed recovery -------------------------------------------------
# The in-game scoreboard shows a day counter next to the servant ("... 24-го").
# When the player cell is missed, OCR grabs "<servant> <day>" into the name.
_DAY_RE = re.compile(r"\s*\d{1,3}\s*[-–—]\s*[A-Za-zА-Яа-яЁё]{1,3}\b\.*")
# Within a bleed cell we strip ALL punctuation (it only runs on names already
# flagged as bleed, so real punctuated nicks like "M.H.R" are never reached).
_JUNK_RE = re.compile(r"[^\w\s]", re.UNICODE)

_HERO_NAMES = [h.lower() for h in heroes_mod.HEROES]
# Individual servant-name words long enough to be a reliable signal, plus the
# Nobunaga title pieces OCR mangles a lot ("Hobunaga", "mobunaga", "bunaga").
_HERO_WORDS = set()
for _h in _HERO_NAMES:
    for _w in re.split(r"[^a-zа-яё0-9]+", _h):
        if len(_w) >= 4:
            _HERO_WORDS.add(_w)
_HERO_WORDS |= {"nobunaga", "bunaga", "obunaga", "claudius", "demon", "king"}
_HERO_WORDS = list(_HERO_WORDS)


def _contains_hero(s):
    """Does this (longish) string contain a servant name? Uses partial_ratio so a
    servant embedded in surrounding garbage still trips it."""
    s = s.strip().lower()
    if len(s) < 7:
        return False
    best = process.extractOne(s, _HERO_NAMES, scorer=fuzz.partial_ratio)
    return bool(best and best[1] >= 88)


def _strip_hero_words(s):
    """Drop word-tokens that look like a servant name word, keep the rest."""
    out = []
    for tok in re.split(r"(\s+)", s):
        t = tok.strip().lower()
        if len(t) >= 4:
            b = process.extractOne(t, _HERO_WORDS, scorer=fuzz.ratio)
            if b and b[1] >= 80:
                continue
        out.append(tok)
    return "".join(out)


def debleed_player(name, roster_names=None):
    """Recover a real player from a cell with hero/servant text or OCR junk bled in.

    Only acts when there's a bleed signal — an in-game day counter ("24-го"),
    bracket junk, or an embedded servant name — so ordinary (if mangled) nicks are
    left untouched. Returns a roster name when the leftover clearly matches a
    regular, UNKNOWN_PLAYER when it was bleed but nothing readable remains, or
    None when it doesn't look like bleed (caller keeps the name as-is)."""
    if not name:
        return None
    if roster_names is None:                     # clean file roster, never the
        roster_names = _SEEDS                     # auto-learned (garbage-prone) DB one
    has_day = bool(_DAY_RE.search(name))
    has_bracket = bool(re.search(r"[\[\]]", name))
    stripped = _DAY_RE.sub(" ", name)
    has_hero = _contains_hero(stripped)
    if not (has_day or has_bracket or has_hero):
        return None
    cleaned = _JUNK_RE.sub(" ", _strip_hero_words(stripped))
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .,-")
    if len(cleaned) >= 3 and roster_names:
        # Recover only to roster names long enough to match safely — short ones
        # like "Мо"/"Sky" inflate the fuzzy score and grab unrelated garbage.
        targets = [r for r in roster_names if len(r) >= 4]
        best = process.extractOne(cleaned, targets, scorer=fuzz.WRatio,
                                  processor=str.lower)
        if best and best[1] >= 86:
            return best[0]
    # Force Unknown only on a STRONG bleed signal (servant name / day counter).
    # A lone bracket can be junk inside an otherwise-real nick ("БОЛЬШАЯ ШИШКА]"),
    # so without a recovery we leave it for the caller to keep.
    if has_day or has_hero:
        return UNKNOWN_PLAYER
    return None
