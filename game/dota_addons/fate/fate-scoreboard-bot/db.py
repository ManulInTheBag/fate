"""SQLite storage. This is the source of truth; Excel is generated from it.

Matches are saved as PENDING when OCR'd, and flipped to CONFIRMED once a human
approves them in Discord. Only confirmed matches count toward statistics.
"""

import os
import json
import sqlite3
import time

import config

SCHEMA = """
CREATE TABLE IF NOT EXISTS matches (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id        INTEGER UNIQUE,
    source_message_id INTEGER,
    channel_id        INTEGER,
    posted_at         INTEGER,
    image_url         TEXT,
    score_top         INTEGER,
    score_bottom      INTEGER,
    winner            TEXT,
    confirmed         INTEGER DEFAULT 0,
    raw_json          TEXT
);
CREATE TABLE IF NOT EXISTS match_players (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id  INTEGER REFERENCES matches(id) ON DELETE CASCADE,
    slot      INTEGER,
    team      TEXT,
    won       INTEGER,
    player    TEXT,
    hero      TEXT,
    kills     INTEGER,
    deaths    INTEGER,
    assists   INTEGER,
    gold      INTEGER
);
CREATE TABLE IF NOT EXISTS roster (
    name TEXT PRIMARY KEY
);
CREATE TABLE IF NOT EXISTS player_aliases (
    alias_lower TEXT PRIMARY KEY,
    alias       TEXT,
    canonical   TEXT NOT NULL
);
"""


def _conn():
    os.makedirs(os.path.dirname(config.DB_PATH), exist_ok=True)
    c = sqlite3.connect(config.DB_PATH)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA foreign_keys = ON")
    return c


def init_db():
    with _conn() as c:
        c.executescript(SCHEMA)
        # migrate older DBs that predate source_message_id
        cols = {r["name"] for r in c.execute("PRAGMA table_info(matches)")}
        if "source_message_id" not in cols:
            c.execute("ALTER TABLE matches ADD COLUMN source_message_id INTEGER")


# ---- roster ----

def get_roster():
    """Roster from roster.py plus any names learned at runtime."""
    import roster as roster_mod
    names = set(roster_mod.PLAYERS)
    with _conn() as c:
        for r in c.execute("SELECT name FROM roster"):
            names.add(r["name"])
    return sorted(names)


# ---- player aliases (link alt accounts / OCR variants -> one canonical name) ----

def add_alias(alias, canonical):
    alias = alias.strip()
    canonical = canonical.strip()
    with _conn() as c:
        c.execute("INSERT OR REPLACE INTO player_aliases(alias_lower, alias, canonical) "
                  "VALUES (?,?,?)", (alias.lower(), alias, canonical))


def remove_alias(alias):
    with _conn() as c:
        cur = c.execute("DELETE FROM player_aliases WHERE alias_lower=?",
                        (alias.strip().lower(),))
        return cur.rowcount


def get_alias_map():
    """{alias_lower: canonical} for resolving names during stats."""
    with _conn() as c:
        return {r["alias_lower"]: r["canonical"]
                for r in c.execute("SELECT alias_lower, canonical FROM player_aliases")}


def list_aliases():
    with _conn() as c:
        return [(r["alias"], r["canonical"]) for r in c.execute(
            "SELECT alias, canonical FROM player_aliases ORDER BY canonical, alias")]


def _is_junk_name(name):
    """A learned name we should NOT keep in the roster: too short, or a near-dupe
    of a clean seed (e.g. "Cute Iute" vs seed "cute lute")."""
    import roster as roster_mod
    from rapidfuzz import process, fuzz
    name = name.strip()
    if len(name) <= 2:
        return True
    if name in roster_mod.PLAYERS:
        return False
    b = process.extractOne(name, roster_mod.PLAYERS, scorer=fuzz.WRatio, processor=str.lower)
    return bool(b and b[1] >= 85)


def remember_player(name, conn=None):
    if not name or _is_junk_name(name):
        return
    if conn is not None:
        conn.execute("INSERT OR IGNORE INTO roster(name) VALUES (?)", (name.strip(),))
        return
    with _conn() as c:
        c.execute("INSERT OR IGNORE INTO roster(name) VALUES (?)", (name.strip(),))


def clean_roster():
    """Remove junk learned names (short / near-dupes of seeds) that pollute
    matching. Returns how many were removed."""
    with _conn() as c:
        learned = [r["name"] for r in c.execute("SELECT name FROM roster")]
        removed = [n for n in learned if _is_junk_name(n)]
        for n in removed:
            c.execute("DELETE FROM roster WHERE name=?", (n,))
        return len(removed)


# ---- matches ----

def save_pending(message_id, channel_id, image_url, match,
                 source_message_id=None, posted_at=None):
    with _conn() as c:
        cur = c.execute(
            """INSERT OR REPLACE INTO matches
               (message_id, source_message_id, channel_id, posted_at, image_url,
                score_top, score_bottom, winner, confirmed, raw_json)
               VALUES (?,?,?,?,?,?,?,?,0,?)""",
            (message_id, source_message_id, channel_id,
             int(posted_at if posted_at is not None else time.time()), image_url,
             match["score_top"], match["score_bottom"], match["winner"],
             json.dumps(match)),
        )
        return cur.lastrowid


def source_exists(source_message_id):
    """Has a scoreboard from this original message already been ingested?
    Used to dedupe backfill / re-posts."""
    if source_message_id is None:
        return False
    with _conn() as c:
        return c.execute(
            "SELECT 1 FROM matches WHERE source_message_id=? LIMIT 1",
            (source_message_id,),
        ).fetchone() is not None


def get_pending_by_message(message_id):
    with _conn() as c:
        row = c.execute(
            "SELECT * FROM matches WHERE message_id=?", (message_id,)
        ).fetchone()
        if not row:
            return None
        d = dict(row)
        d["match"] = json.loads(d["raw_json"])
        return d


def update_pending(message_id, match):
    with _conn() as c:
        c.execute(
            """UPDATE matches SET score_top=?, score_bottom=?, winner=?, raw_json=?
               WHERE message_id=?""",
            (match["score_top"], match["score_bottom"], match["winner"],
             json.dumps(match), message_id),
        )


def confirm(message_id):
    """Promote a pending match to confirmed and materialize its player rows."""
    rec = get_pending_by_message(message_id)
    if not rec:
        return False
    match = rec["match"]
    with _conn() as c:
        c.execute("UPDATE matches SET confirmed=1 WHERE id=?", (rec["id"],))
        c.execute("DELETE FROM match_players WHERE match_id=?", (rec["id"],))
        for p in match["players"]:
            c.execute(
                """INSERT INTO match_players
                   (match_id, slot, team, won, player, hero, kills, deaths, assists, gold)
                   VALUES (?,?,?,?,?,?,?,?,?,?)""",
                (rec["id"], p["slot"], p["team"], int(p["won"]),
                 p["player"], p["hero"], p["kills"], p["deaths"], p["assists"], p["gold"]),
            )
            remember_player(p["player"], conn=c)
    return True


def delete_match(message_id):
    with _conn() as c:
        c.execute("DELETE FROM matches WHERE message_id=?", (message_id,))


def _range_clause(start_ts=None, end_ts=None, min_id=None, max_id=None):
    where, args = [], []
    if start_ts is not None:
        where.append("posted_at >= ?"); args.append(int(start_ts))
    if end_ts is not None:
        where.append("posted_at <= ?"); args.append(int(end_ts))
    if min_id is not None:
        where.append("id >= ?"); args.append(int(min_id))
    if max_id is not None:
        where.append("id <= ?"); args.append(int(max_id))
    return (" AND ".join(where) or "1"), args


def count_matches(start_ts=None, end_ts=None, min_id=None, max_id=None):
    clause, args = _range_clause(start_ts, end_ts, min_id, max_id)
    with _conn() as c:
        return c.execute(f"SELECT COUNT(*) FROM matches WHERE {clause}", args).fetchone()[0]


def delete_matches(start_ts=None, end_ts=None, min_id=None, max_id=None):
    """Delete matches in the given range (cascades to their player rows).
    Returns the number of matches deleted."""
    clause, args = _range_clause(start_ts, end_ts, min_id, max_id)
    with _conn() as c:
        cur = c.execute(f"DELETE FROM matches WHERE {clause}", args)
        return cur.rowcount


def delete_match_ids(ids):
    """Delete specific matches by id (cascades to player rows)."""
    ids = list(ids)
    if not ids:
        return 0
    with _conn() as c:
        qmarks = ",".join("?" * len(ids))
        cur = c.execute(f"DELETE FROM matches WHERE id IN ({qmarks})", ids)
        return cur.rowcount


def all_confirmed_players(start_ts=None, end_ts=None, min_id=None, max_id=None):
    """Flat list of confirmed (match, player) rows for stats, optionally filtered
    by posted-at time range and/or match-id (game) range."""
    where = ["m.confirmed = 1"]
    args = []
    if start_ts is not None:
        where.append("m.posted_at >= ?"); args.append(int(start_ts))
    if end_ts is not None:
        where.append("m.posted_at <= ?"); args.append(int(end_ts))
    if min_id is not None:
        where.append("m.id >= ?"); args.append(int(min_id))
    if max_id is not None:
        where.append("m.id <= ?"); args.append(int(max_id))
    sql = f"""SELECT m.id AS match_id, m.posted_at, m.winner,
                     m.score_top, m.score_bottom,
                     p.slot, p.team, p.won, p.player, p.hero,
                     p.kills, p.deaths, p.assists, p.gold
              FROM matches m JOIN match_players p ON p.match_id = m.id
              WHERE {' AND '.join(where)}
              ORDER BY m.posted_at, p.slot"""
    with _conn() as c:
        return [dict(r) for r in c.execute(sql, args)]


def recent_confirmed_matches(limit=20):
    """Most recent confirmed matches (id, date, winner, score) for `!matches`."""
    with _conn() as c:
        return [dict(r) for r in c.execute(
            """SELECT id, posted_at, winner, score_top, score_bottom
               FROM matches WHERE confirmed=1
               ORDER BY posted_at DESC LIMIT ?""", (limit,))]
