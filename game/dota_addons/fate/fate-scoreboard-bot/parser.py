"""Turn raw OCR cells into a clean, structured match.

- Snap hero/player names to known rosters with rapidfuzz.
- Assign teams (top/bottom) and the winner (higher score; the winning team is
  also the highlighted block on top, used as a tiebreaker).
- Flag any field we're not confident about so the bot can ask you to confirm.
"""

import re

from rapidfuzz import process, fuzz

import config
import heroes as heroes_mod

# The hero cell reads as e.g. "Cu Chulainn 24-ro yp." (Latin/Cyrillic level after)
# or "23级村正" / "24级 卫宫" (Chinese level "NN级" BEFORE the name).
_LEVEL_CN = re.compile(r"^\s*\d+\s*级\s*")   # leading Chinese level
_LEVEL_RE = re.compile(r"\s*\d+.*$")          # trailing level (no hero has a digit)


def _strip_level(raw):
    return _LEVEL_RE.sub("", _LEVEL_CN.sub("", raw or "")).strip(" -–—.,")


def _match(raw, candidates, aliases=None):
    if not raw:
        return raw, 0
    key = raw.strip().lower()
    if aliases and key in aliases:
        return aliases[key], 100
    # fuzz.ratio is case-insensitive (processor) and length-aware, so "IL" matches
    # "IvL" while a short "Mo" does NOT capture "Moskes" (no substring bonus).
    best = process.extractOne(raw, candidates, scorer=fuzz.ratio, processor=str.lower)
    if best and best[1] >= config.FUZZY_THRESHOLD:
        return best[0], int(best[1])
    return raw, int(best[1]) if best else 0


_CN = getattr(heroes_mod, "CHINESE", {})
_HERO_CANDIDATES = heroes_mod.HEROES + list(_CN.keys())


def match_hero(raw):
    cleaned = _strip_level(raw)
    if not cleaned:
        return cleaned, 0
    if cleaned in _CN:                       # exact Chinese name
        return _CN[cleaned], 100
    key = cleaned.lower()
    if heroes_mod.ALIASES and key in heroes_mod.ALIASES:
        return heroes_mod.ALIASES[key], 100
    # fuzz.ratio is length-aware, so a short "IL" won't capture "Gilgamesh".
    best = process.extractOne(cleaned, _HERO_CANDIDATES, scorer=fuzz.ratio,
                              processor=str.lower)
    if best and best[1] >= config.FUZZY_THRESHOLD:
        return _CN.get(best[0], best[0]), int(best[1])   # map Chinese -> English
    return cleaned, int(best[1]) if best else 0


def match_player(raw, roster):
    return _match(raw, roster)


def best_player(cands, primary, roster):
    """Pick the player reading that best matches a known roster name across all
    OCR candidate variants (plain + OTSU + Chinese). This lets a regular like
    "шешня" be recovered when one variant reads it correctly even if the default
    read ("пепня") doesn't. Falls back to the primary read when nothing matches."""
    best_m, best_s = None, 0
    for c in cands:
        if not c:
            continue
        m, s = _match(c, roster)
        if s > best_s:
            best_m, best_s = m, s
    if best_m is not None and best_s >= config.FUZZY_THRESHOLD:
        return best_m, best_s
    return _match(primary, roster)


def build_match(extracted, roster):
    rows = extracted["rows"]
    n = len(rows)
    split = extracted.get("split", n // 2)

    score_top = extracted.get("score_top")
    score_bottom = extracted.get("score_bottom")

    # Winner: by score if known, else the top (highlighted) block wins.
    if score_top is not None and score_bottom is not None and score_top != score_bottom:
        winner = "top" if score_top > score_bottom else "bottom"
    else:
        winner = "top"

    players = []
    for i, row in enumerate(rows):
        team = row.get("team") or ("top" if i < split else "bottom")
        player_raw = row.get("player_raw", "")
        player_cands = row.get("player_cands") or ([player_raw] if player_raw else [])
        hero, h_conf = match_hero(row.get("hero_raw", ""))

        # Overlap case: a long hero name (e.g. "Demon king Nobunaga") overruns the
        # player-name line, so the hero lands in the PLAYER cell and the hero cell
        # reads empty. If so, take the hero from the player cell; the real player
        # name is overlapped/unreadable, so leave it blank to be corrected.
        if h_conf < config.FUZZY_THRESHOLD:
            alt_hero, alt_conf = match_hero(player_raw)
            if alt_conf >= config.FUZZY_THRESHOLD and alt_conf > h_conf:
                hero, h_conf = alt_hero, alt_conf
                player_raw, player_cands = "", []

        # Image fallback: the name text was unreadable, so identify the hero by its
        # PORTRAIT icon instead (hero_vision). Accepted only above the similarity
        # gate; marked so the reviewer knows it came from the picture, not text.
        hero_by_img = False
        if h_conf < config.FUZZY_THRESHOLD and config.HERO_VISION and row.get("hero_vec") is not None:
            import hero_vision
            vh, vs = hero_vision.match(row["hero_vec"], config.HERO_VISION_GATE)
            if vh:
                hero, hero_by_img, h_conf = vh, True, max(h_conf, int(vs * 100))

        player, p_conf = best_player(player_cands, player_raw, roster)

        flags = []
        if p_conf < config.FUZZY_THRESHOLD:
            flags.append("player")
        # An image-matched hero is resolved (just from the icon, not text), so it's
        # not a low-confidence cell — it carries its own "img" marker instead.
        if h_conf < config.FUZZY_THRESHOLD and not hero_by_img:
            flags.append("hero")
        for f in ("kills", "deaths", "assists", "gold"):
            if row.get(f) is None:
                flags.append(f)

        players.append({
            "slot": i,
            "team": team,
            "won": team == winner,
            "player": player,
            "player_conf": p_conf,
            "hero": hero,
            "hero_conf": h_conf,
            "hero_src": "image" if hero_by_img else "text",
            "kills": row.get("kills"),
            "deaths": row.get("deaths"),
            "assists": row.get("assists"),
            "gold": row.get("gold"),
            "flags": flags,
        })

    # Validity: the OCR layout must have been recognized (extracted["valid"]) AND
    # enough HERO names must match the real Fate roster. A non-scoreboard (chat,
    # meme, other game's stats, random noise) won't produce real hero names.
    heroes_ok = sum(1 for p in players
                    if p["hero_conf"] >= config.FUZZY_THRESHOLD or p.get("hero_src") == "image")
    need = max(2, round(0.25 * n)) if n else 1
    if not extracted.get("valid", True):
        valid, reason = False, extracted.get("reason", "not a scoreboard")
    elif heroes_ok < need:
        valid, reason = False, "no Fate heroes recognized"
    else:
        valid, reason = True, ""

    return {
        "score_top": score_top,
        "score_bottom": score_bottom,
        "winner": winner,
        "n_rows": n,
        "players": players,
        "valid": valid,
        "reason": reason,
        "heroes_ok": heroes_ok,
    }


def format_table(match):
    """Render the parsed match as a monospaced table for Discord, with '?' on
    low-confidence cells so issues are easy to spot."""
    lines = []
    st, sb = match["score_top"], match["score_bottom"]
    lines.append(f"Score: TOP {st if st is not None else '?'} - {sb if sb is not None else '?'} BOTTOM "
                 f"(winner: {match['winner'].upper()})")
    lines.append(f"{'#':>2} {'Player':<22} {'Hero':<20} {'K':>3} {'D':>3} {'A':>3}  W")
    lines.append("-" * 60)
    for p in match["players"]:
        def cell(v, key):
            s = "?" if v is None else str(v)
            return s + ("*" if key in p["flags"] else "")
        # A hero recognised from its portrait (not text) is tagged so you can
        # double-check it at a glance.
        hero_cell = cell(p["hero"], "hero")
        if p.get("hero_src") == "image":
            hero_cell += "~"
        lines.append(
            f"{p['slot']+1:>2} "
            f"{(cell(p['player'],'player'))[:22]:<22} "
            f"{hero_cell[:20]:<20} "
            f"{cell(p['kills'],'kills'):>3} {cell(p['deaths'],'deaths'):>3} "
            f"{cell(p['assists'],'assists'):>3}  "
            f"{'Y' if p['won'] else 'N'}"
        )
    lines.append("")
    lines.append("Cells marked * are low-confidence — fix before confirming. "
                 "Hero marked ~ was read from its portrait icon, not text.")
    return "\n".join(lines)
