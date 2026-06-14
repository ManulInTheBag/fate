"""Known player names — the "closed list" of your regular players.

Just like heroes.py is the closed list of 51 heroes, this is your list of player
names. Add every regular player's CORRECT name here (one per line, in quotes).
Then OCR variants snap to them automatically: "IL" -> "IvL", "Cute Iute" ->
"cute lute", etc. Mixed scripts are fine — Cyrillic, Japanese, Chinese all work.

After editing, restart the bot. Existing stats are fixed on the next `!export`
(snapping happens at export time); no need to re-import.

  HOW IT'S USED
  - match_player: fuzzy-matches each OCR'd name to this list (case-insensitive).
  - snap_player:  at export, snaps names to the closest entry here.
The bot also auto-learns names you type in corrections, but THIS list is the
canonical source — fill it with the real spellings.
"""

PLAYERS = [
    # --- originals ---
    "Zlodemon",
    "Renvor",
    "TpaBoPuDgE",
    "KEP4ILA",
    "M.H.R",
    "NComnes",
    "Omen",
    "Tlen",
    "Lantraciua",
    "Ezik",
    "cute lute",
    "MapoTofu",
    "IvL",
    "Seva",
    "Sparkle",
    "Teterew",
    "Чекни шейдеры",
    "Ryudo",
    "Kakaruma",
    "Jopax",
    "Prestige",
    "Adolfo",
    "Tomura"
    # --- add the rest of your regulars below (correct spelling) ---
]
