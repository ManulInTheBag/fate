"""Clean up stored values at stats/export time (non-destructive).

- Heroes are a CLOSED set of 51, so we snap each stored hero to the nearest
  known hero (fixes OCR near-misses like "Vlad Ill" -> "Vlad III"); anything too
  far off (OCR garbage like "PS", "aie sory ws") becomes "Unknown".
- Players are an OPEN set, so we can't auto-snap, but we resolve names through
  the alias map (set via `!alias`) to merge alt accounts / OCR variants onto one
  canonical name.
"""

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
