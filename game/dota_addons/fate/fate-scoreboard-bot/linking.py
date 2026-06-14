"""Suggest player-name merges from the stored data.

Players are an open set, so we can't snap them to a fixed list like heroes. But
OCR variants of the same person (e.g. "Moskes" vs "MoskesAcabe", "tragic
igrushia otchim:" vs "tragic igrushka otchima") show up as near-duplicate names
where one is common and the other rare. We pair each rare name with the most
similar MORE-FREQUENT name — "linking based on how close they look and how often
they appear" — and propose linking the rare one onto the frequent one.

This only proposes; the user applies via `!links apply` or `!alias`, so two
genuinely different people are never merged silently.

Note: cross-script variants (a Latin name OCR'd as Cyrillic, or two slightly
different CJK spellings) score low on fuzzy matching and won't be suggested —
those still need a manual `!alias`.
"""

from collections import Counter, defaultdict
from itertools import combinations

from rapidfuzz import fuzz

import db
import normalize

MIN_SCORE = 87  # similarity needed to propose a merge

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


def suggest(min_score=MIN_SCORE):
    """Return [{alias, alias_count, main, main_count, score}], rare->frequent.
    Uses transliteration-aware similarity and skips name pairs that ever played
    together."""
    counts = _resolved_counts()
    cooc = _cooccurring()
    names = sorted(counts, key=lambda n: (-counts[n], n))  # frequent first
    linked = set()
    out = []
    for i, anchor in enumerate(names):
        if anchor in linked:
            continue
        for other in names[i + 1:]:        # only same-or-rarer names
            if other in linked or tuple(sorted((anchor, other))) in cooc:
                continue
            score = _similarity(anchor, other)
            if score >= min_score:
                out.append({"alias": other, "alias_count": counts[other],
                            "main": anchor, "main_count": counts[anchor],
                            "score": int(score)})
                linked.add(other)
    return out
