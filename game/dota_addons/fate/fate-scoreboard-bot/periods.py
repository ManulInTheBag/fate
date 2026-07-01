"""Parse an export command's time/game-range argument into DB filters.

Accepted forms (case-insensitive), e.g. used as `%export <arg>`:

    (empty) / all                  -> everything
    today | yesterday
    week | month
    7d | 24h | 90m                 -> last N days / hours / minutes
    last 5                         -> last N matches (by recency)
    from 2026-06-01                -> that date 00:00 .. now
    from 2026-06-01 to 2026-06-10  -> inclusive date range
    games 10-25 | game 14          -> match-id (game) range
    matches 10-25

Returns (filters, label) where filters is a dict with any of:
start_ts, end_ts, min_id, max_id  (all epoch seconds / match ids).
"""

import re
from datetime import datetime, timedelta


def _day_start(d):
    return datetime(d.year, d.month, d.day)


def parse(arg, recent_match_ids=None):
    """recent_match_ids: optional list of confirmed match ids, newest first,
    used to resolve `last N`."""
    s = (arg or "").strip().lower()
    now = datetime.now()

    if s in ("", "all", "alltime", "all-time"):
        return {}, "All time"

    if s == "today":
        start = _day_start(now)
        return {"start_ts": start.timestamp()}, f"Today ({start:%Y-%m-%d})"

    if s == "yesterday":
        start = _day_start(now) - timedelta(days=1)
        end = _day_start(now)
        return ({"start_ts": start.timestamp(), "end_ts": end.timestamp()},
                f"Yesterday ({start:%Y-%m-%d})")

    if s == "week":
        s = "7d"
    if s == "month":
        s = "30d"

    m = re.fullmatch(r"(\d+)\s*([dhm])", s)
    if m:
        n = int(m.group(1))
        unit = {"d": "days", "h": "hours", "m": "minutes"}[m.group(2)]
        start = now - timedelta(**{unit: n})
        word = {"d": "day", "h": "hour", "m": "minute"}[m.group(2)]
        return {"start_ts": start.timestamp()}, f"Last {n} {word}{'s' if n != 1 else ''}"

    m = re.fullmatch(r"last\s+(\d+)", s)
    if m and recent_match_ids:
        n = int(m.group(1))
        ids = recent_match_ids[:n]
        if ids:
            return ({"min_id": min(ids), "max_id": max(ids)}, f"Last {len(ids)} matches")
        return {}, "Last matches (none yet)"

    m = re.fullmatch(r"(?:games?|matches?)\s+(\d+)(?:\s*-\s*(\d+))?", s)
    if m:
        a = int(m.group(1))
        b = int(m.group(2)) if m.group(2) else a
        lo, hi = min(a, b), max(a, b)
        return ({"min_id": lo, "max_id": hi},
                f"Game {lo}" if lo == hi else f"Games {lo}-{hi}")

    m = re.fullmatch(r"from\s+(\d{4}-\d{2}-\d{2})(?:\s+to\s+(\d{4}-\d{2}-\d{2}))?", s)
    if m:
        start = datetime.strptime(m.group(1), "%Y-%m-%d")
        f = {"start_ts": start.timestamp()}
        if m.group(2):
            end = datetime.strptime(m.group(2), "%Y-%m-%d") + timedelta(days=1)
            f["end_ts"] = end.timestamp()
            return f, f"{m.group(1)} to {m.group(2)}"
        return f, f"Since {m.group(1)}"

    raise ValueError(
        "Couldn't read that period. Try: `today`, `week`, `7d`, `last 5`, "
        "`from 2026-06-01 to 2026-06-10`, or `games 10-25`."
    )
