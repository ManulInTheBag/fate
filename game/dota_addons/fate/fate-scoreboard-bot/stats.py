"""Aggregate confirmed match data into the tables we export to Excel."""

from collections import defaultdict
from itertools import combinations

import db
import normalize


def _kda(k, d, a):
    return round((k + a) / max(d, 1), 2)


def compute(start_ts=None, end_ts=None, min_id=None, max_id=None):
    rows = db.all_confirmed_players(start_ts, end_ts, min_id, max_id)

    # Clean up stored values (non-destructive): snap heroes to the known set and
    # merge player alt-accounts / OCR variants via the alias map.
    alias_map = db.get_alias_map()
    for r in rows:
        r["player"] = normalize.snap_player(normalize.resolve_player(r["player"], alias_map))
        r["hero"] = normalize.clean_hero(r["hero"])

    # Merge names that differ only by case ("Cute Iute" vs "cute Iute") onto the
    # most common spelling.
    case_counts = defaultdict(lambda: defaultdict(int))
    for r in rows:
        case_counts[r["player"].lower()][r["player"]] += 1
    canon = {low: max(variants, key=variants.get) for low, variants in case_counts.items()}
    for r in rows:
        r["player"] = canon[r["player"].lower()]

    # A *player* name that matches a HERO name is the hero cell bleeding into the
    # player cell (e.g. "Bhan king Nobunaga"). Bucket these as Unknown — but only
    # for rare names (<=2 games), so a real player named after a servant survives.
    pcounts = defaultdict(int)
    for r in rows:
        pcounts[r["player"]] += 1
    for r in rows:
        p = r["player"]
        if pcounts[p] <= 2 and normalize.hero_match_score(p) >= normalize.PLAYER_AS_HERO:
            r["player"] = normalize.UNKNOWN_PLAYER

    # group rows by match
    by_match = defaultdict(list)
    for r in rows:
        by_match[r["match_id"]].append(r)

    player = defaultdict(lambda: dict(games=0, wins=0, k=0, d=0, a=0, gold=0, heroes=defaultdict(int)))
    hero = defaultdict(lambda: dict(games=0, wins=0, k=0, d=0, a=0))
    player_hero = defaultdict(lambda: dict(games=0, wins=0, k=0, d=0, a=0))
    teammates = defaultdict(lambda: dict(games=0, wins=0))

    matches_summary = []

    for mid, prows in by_match.items():
        # match-level row
        first = prows[0]
        matches_summary.append({
            "match_id": mid,
            "posted_at": first["posted_at"],
            "winner": first["winner"],
            "score_top": first["score_top"],
            "score_bottom": first["score_bottom"],
        })

        # per-team grouping for teammate pairs
        teams = defaultdict(list)
        for r in prows:
            k = r["kills"] or 0
            d = r["deaths"] or 0
            a = r["assists"] or 0
            g = r["gold"] or 0
            won = bool(r["won"])

            ps = player[r["player"]]
            ps["games"] += 1
            ps["wins"] += int(won)
            ps["k"] += k; ps["d"] += d; ps["a"] += a; ps["gold"] += g
            ps["heroes"][r["hero"]] += 1

            hs = hero[r["hero"]]
            hs["games"] += 1
            hs["wins"] += int(won)
            hs["k"] += k; hs["d"] += d; hs["a"] += a

            phs = player_hero[(r["player"], r["hero"])]
            phs["games"] += 1
            phs["wins"] += int(won)
            phs["k"] += k; phs["d"] += d; phs["a"] += a

            teams[r["team"]].append((r["player"], won))

        for team_players in teams.values():
            for (p1, w1), (p2, _w2) in combinations(team_players, 2):
                key = tuple(sorted((p1, p2)))
                teammates[key]["games"] += 1
                teammates[key]["wins"] += int(w1)

    # ---- materialize sorted tables ----
    player_table = []
    for name, s in player.items():
        games = s["games"]
        fav = max(s["heroes"].items(), key=lambda kv: kv[1])[0] if s["heroes"] else ""
        player_table.append({
            "player": name, "games": games, "wins": s["wins"], "losses": games - s["wins"],
            "winrate": round(100 * s["wins"] / games, 1) if games else 0,
            "kills": s["k"], "deaths": s["d"], "assists": s["a"],
            "kda": _kda(s["k"], s["d"], s["a"]),
            "avg_k": round(s["k"] / games, 1) if games else 0,
            "avg_d": round(s["d"] / games, 1) if games else 0,
            "avg_a": round(s["a"] / games, 1) if games else 0,
            "avg_gold": round(s["gold"] / games) if games else 0,
            "heroes_played": len(s["heroes"]),
            "most_played_hero": fav,
        })
    player_table.sort(key=lambda x: (-x["winrate"], -x["games"]))

    hero_table = []
    for name, s in hero.items():
        games = s["games"]
        hero_table.append({
            "hero": name, "picks": games, "wins": s["wins"], "losses": games - s["wins"],
            "winrate": round(100 * s["wins"] / games, 1) if games else 0,
            "avg_k": round(s["k"] / games, 1) if games else 0,
            "avg_d": round(s["d"] / games, 1) if games else 0,
            "avg_a": round(s["a"] / games, 1) if games else 0,
            "kda": _kda(s["k"], s["d"], s["a"]),
        })
    hero_table.sort(key=lambda x: (-x["picks"], -x["winrate"]))

    player_hero_table = []
    for (p, h), s in player_hero.items():
        games = s["games"]
        player_hero_table.append({
            "player": p, "hero": h, "games": games, "wins": s["wins"],
            "winrate": round(100 * s["wins"] / games, 1) if games else 0,
            "kda": _kda(s["k"], s["d"], s["a"]),
        })
    player_hero_table.sort(key=lambda x: (x["player"], -x["games"]))

    teammate_table = []
    for (p1, p2), s in teammates.items():
        games = s["games"]
        teammate_table.append({
            "player_a": p1, "player_b": p2, "games_together": games,
            "wins_together": s["wins"],
            "winrate": round(100 * s["wins"] / games, 1) if games else 0,
        })
    teammate_table.sort(key=lambda x: (-x["games_together"], -x["winrate"]))

    matches_summary.sort(key=lambda x: x["posted_at"])

    return {
        "players": player_table,
        "heroes": hero_table,
        "player_hero": player_hero_table,
        "teammates": teammate_table,
        "matches": matches_summary,
        "raw": rows,
    }
