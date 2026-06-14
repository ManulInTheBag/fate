"""Apply human corrections (typed as a reply in Discord) to a parsed match.

Supported lines (one correction per line, case-insensitive keys):

    row3 player="KEP4ILA" hero="EMIYA" k=15 d=12 a=29 gold=4300
    score 12-11               (or:  score top=12 bottom=11)
    winner top                (or:  winner bottom)

Quote any value containing a space, e.g. player="cute lute".
Field aliases: k/kills, d/deaths, a/assists, g/gold.
"""

import shlex

FIELD_ALIASES = {
    "k": "kills", "kills": "kills",
    "d": "deaths", "deaths": "deaths",
    "a": "assists", "assists": "assists",
    "g": "gold", "gold": "gold",
    "player": "player", "p": "player",
    "hero": "hero", "h": "hero",
}
INT_FIELDS = {"kills", "deaths", "assists", "gold"}


def _reassign_wins(match):
    for p in match["players"]:
        p["won"] = p["team"] == match["winner"]


def apply(match, text):
    applied, errors = [], []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            toks = shlex.split(line)
        except ValueError as e:
            errors.append(f"`{line}` — {e}")
            continue
        if not toks:
            continue
        head = toks[0].lower()

        if head == "winner" and len(toks) >= 2:
            w = toks[1].lower()
            if w in ("top", "bottom"):
                match["winner"] = w
                _reassign_wins(match)
                applied.append(f"winner = {w}")
            else:
                errors.append(f"`{line}` — winner must be top/bottom")
            continue

        if head == "score":
            top = bottom = None
            rest = toks[1:]
            if len(rest) == 1 and "-" in rest[0]:
                a, _, b = rest[0].partition("-")
                top, bottom = a, b
            else:
                for t in rest:
                    if "=" in t:
                        key, _, val = t.partition("=")
                        if key.lower() == "top":
                            top = val
                        elif key.lower() == "bottom":
                            bottom = val
            try:
                if top is not None:
                    match["score_top"] = int(top)
                if bottom is not None:
                    match["score_bottom"] = int(bottom)
                # recompute winner from scores
                st, sb = match["score_top"], match["score_bottom"]
                if st is not None and sb is not None and st != sb:
                    match["winner"] = "top" if st > sb else "bottom"
                    _reassign_wins(match)
                applied.append(f"score = {match['score_top']}-{match['score_bottom']}")
            except (TypeError, ValueError):
                errors.append(f"`{line}` — scores must be numbers")
            continue

        if head.startswith("row"):
            try:
                idx = int(head[3:]) - 1
            except ValueError:
                errors.append(f"`{line}` — bad row number")
                continue
            if not (0 <= idx < len(match["players"])):
                errors.append(f"`{line}` — row out of range")
                continue
            p = match["players"][idx]
            changed = []
            for t in toks[1:]:
                if "=" not in t:
                    continue
                key, _, val = t.partition("=")
                field = FIELD_ALIASES.get(key.lower())
                if not field:
                    errors.append(f"`{line}` — unknown field '{key}'")
                    continue
                if field in INT_FIELDS:
                    try:
                        p[field] = int(val)
                    except ValueError:
                        errors.append(f"`{line}` — {field} must be a number")
                        continue
                else:
                    p[field] = val
                    # value is now human-verified
                    p[f"{field}_conf"] = 100
                if field in p.get("flags", []):
                    p["flags"].remove(field)
                changed.append(field)
            if changed:
                applied.append(f"row{idx+1}: {', '.join(changed)}")
            continue

        errors.append(f"`{line}` — unrecognized")
    return match, applied, errors
