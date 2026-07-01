"""Suggest player-name merges from the stored data.

Players are an open set, so we can't snap them to a fixed list like heroes. But
OCR variants of the same person (e.g. "Moskes" vs "MoskesAcabe", "tragic
igrushia otchim:" vs "tragic igrushka otchima") show up as near-duplicate names
where one is common and the other rare. We pair each rare name with the most
similar MORE-FREQUENT name — "linking based on how close they look and how often
they appear" — and propose linking the rare one onto the frequent one.

This only proposes; the user applies via `%links apply` or `%alias`, so two
genuinely different people are never merged silently.

Note: cross-script variants (a Latin name OCR'd as Cyrillic, or two slightly
different CJK spellings) score low on fuzzy matching and won't be suggested —
those still need a manual `%alias`.
"""

from collections import Counter, defaultdict
from itertools import combinations

from rapidfuzz import fuzz, process

import db
import normalize
import roster as roster_mod

MIN_SCORE = 87    # similarity to propose merging two ordinary names (high tier)
ROSTER_SCORE = 85  # similarity to snap a stray name onto a known roster regular
LOW_SCORE = 72    # looser bar, used ONLY between two garbled non-roster names —
                  # surfaces OCR-mangled regulars (the "... +" / "Т_mk" / "бтач"
                  # families). Tuned so families merge without joining two distinct
                  # regulars; the few 1-game false pairs are caught on review.

# Visual Cyrillic->Latin map: OCR often renders a Latin glyph as its Cyrillic
# look-alike, so comparing transliterated forms catches those variants.
_CYR = {
    'А': 'A', 'В': 'B', 'Е': 'E', 'Ё': 'E', 'К': 'K', 'М': 'M', 'Н': 'H', 'О': 'O',
    'Р': 'P', 'С': 'C', 'Т': 'T', 'У': 'Y', 'Х': 'X', 'З': '3', 'І': 'I', 'Ј': 'J',
    'а': 'a', 'в': 'B', 'е': 'e', 'к': 'k', 'м': 'm', 'н': 'H', 'о': 'o', 'р': 'p',
    'с': 'c', 'т': 't', 'у': 'y', 'х': 'x', 'з': '3', 'и': 'u', 'л': 'n', 'п': 'n',
    'г': 'r', 'б': '6', 'й': 'u', 'ф': 'o', 'ш': 'w', 'э': 'e', 'я': '9',
}


def _translit(s):
    return "".join(_CYR.get(ch, ch) for ch in s)


def _similarity(a, b):
    return max(fuzz.WRatio(a, b), fuzz.WRatio(_translit(a), _translit(b)))


def _resolved_counts():
    rows = db.all_confirmed_players()
    amap = db.get_alias_map()
    return Counter(normalize.resolve_player(r["player"], amap) for r in rows)


def _cooccurring():
    """Pairs of names that appeared in the SAME match — they cannot be the same
    person, so we never propose merging them."""
    rows = db.all_confirmed_players()
    amap = db.get_alias_map()
    by_match = defaultdict(set)
    for r in rows:
        by_match[r["match_id"]].add(normalize.resolve_player(r["player"], amap))
    pairs = set()
    for names in by_match.values():
        for a, b in combinations(sorted(names), 2):
            pairs.add((a, b))
    return pairs


def _roster_match(name, roster_set):
    """Best roster regular this name resembles (transliteration-aware), or None."""
    if not roster_set or name in roster_set:
        return None
    cand = list(roster_set)
    b1 = process.extractOne(name, cand, scorer=fuzz.WRatio, processor=str.lower)
    tn = _translit(name)
    b2 = process.extractOne(tn, [(_translit(c)) for c in cand], scorer=fuzz.WRatio)
    score = max(b1[1] if b1 else 0, b2[1] if b2 else 0)
    if score >= ROSTER_SCORE and b1:
        return b1[0], int(score)
    return None


def suggest(min_score=MIN_SCORE):
    """Return link suggestions, each {alias, alias_count, main, main_count, score,
    tier}. rare -> frequent / roster. Transliteration-aware; never pairs names
    that ever played together (they can't be one person).

    tier="high":
      - roster-anchored: a stray name that closely matches a known regular, OR
      - a near-duplicate of a more-frequent name (>= MIN_SCORE).
      Safe to bulk-apply.
    tier="low":
      - two garbled non-roster names (>= LOW_SCORE) that look alike — recovers
        OCR-mangled regulars. Review before applying.
    """
    counts = _resolved_counts()
    cooc = _cooccurring()
    # Anchor on the CLEAN file roster, not db.get_roster() — the latter includes
    # ~600 auto-learned garbage nicks that would swallow the off-roster tier.
    roster_set = set(roster_mod.PLAYERS)
    # 1–2 char names fuzz into anything ("z" scores 90 vs "Ezik"/"Matz" because
    # it's a substring) — exclude them from BOTH sides of every suggestion.
    names = [n for n in sorted(counts, key=lambda n: (-counts[n], n))
             if len(n.strip()) >= 3]
    linked = set()
    out = []

    def together(a, b):
        return tuple(sorted((a, b))) in cooc

    # 1) high tier — snap stray names onto known roster regulars
    for n in names:
        if n in linked or n in roster_set:
            continue
        m = _roster_match(n, roster_set)
        if m and len(m[0].strip()) >= 3 and not together(n, m[0]):
            out.append({"alias": n, "alias_count": counts[n], "main": m[0],
                        "main_count": counts.get(m[0], 0), "score": m[1],
                        "tier": "high"})
            linked.add(n)

    # 2) high tier — near-duplicate of a more-frequent name
    for i, anchor in enumerate(names):
        if anchor in linked:
            continue
        for other in names[i + 1:]:
            if other in linked or together(anchor, other):
                continue
            if _similarity(anchor, other) >= min_score:
                out.append({"alias": other, "alias_count": counts[other],
                            "main": anchor, "main_count": counts[anchor],
                            "score": int(_similarity(anchor, other)), "tier": "high"})
                linked.add(other)

    # 3) low tier — garbled-vs-garbled (both off-roster), looser bar
    off = [n for n in names if n not in roster_set
           and not _roster_match(n, roster_set)]
    for i, anchor in enumerate(off):
        if anchor in linked:
            continue
        members = [anchor]            # everyone merged onto this anchor so far
        for other in off[i + 1:]:
            if other in linked:
                continue
            if any(together(other, m) for m in members):  # can't be the same person
                continue
            if _similarity(anchor, other) >= LOW_SCORE:
                out.append({"alias": other, "alias_count": counts[other],
                            "main": anchor, "main_count": counts[anchor],
                            "score": int(_similarity(anchor, other)), "tier": "low"})
                linked.add(other)
                members.append(other)
    return out
