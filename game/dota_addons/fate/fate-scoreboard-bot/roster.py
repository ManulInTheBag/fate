"""Known player names — the "closed list" of your regular players.

Just like heroes.py is the closed list of 51 heroes, this is your list of player
names. Add every regular player's CORRECT name here (one per line, in quotes).
Then OCR variants snap to them automatically: "IL" -> "IvL", "Cute Iute" ->
"cute lute", etc. Mixed scripts are fine — Cyrillic, Japanese, Chinese all work.

After editing, restart the bot. Existing stats are fixed on the next `%export`
(snapping happens at export time); no need to re-import.

  HOW IT'S USED
  - match_player: fuzzy-matches each OCR'd name to this list (case-insensitive).
  - snap_player:  at export, snaps names to the closest entry here.
  - linking / de-bleed: link suggestions and hero-bleed recovery aim names at
    THIS list, so misreads collapse onto a real regular instead of a garbage row.
The bot also auto-learns names you type in corrections, but THIS list is the
canonical source — fill it with the real spellings.

This list was rebuilt from the 500-game export: every name you confirmed as a
correct read with >=2 games. Obvious in-data misspellings were folded onto the
canonical spelling (e.g. Shlraklln/shrakin -> Shirakiin, Mimm -> Mimin,
Naredo -> Nigredo). Add the real names of the still-garbled regulars as you
identify them (see the cluster report) so their variants snap here too.
"""

PLAYERS = [
    # --- core regulars (Latin) ---
    "Moskes",
    "D-HERO Bloo-D",
    "CIEL",
    "Prestige",
    "Nigredo",
    "Zlodemon",
    "Omen",
    "blackfish",
    "Tlen",
    "Kakaruma",
    "KEP4ILA",
    "benio",
    "Teterew",
    "Vivian",
    "tofurine",
    "Eyeoflie",
    "momo",
    "Nepman",
    "Vavelon",
    "Martin",
    "Sparkle",
    "Seva",
    "Golden duck",
    "NComnes",
    "Ezik",
    "Ryudo",
    "Loken",
    "moon",
    "Darkeyed",
    "Selrize",
    "DOGDOG",
    "Gura Sensei",
    "Dodzilla",
    "Renvor",
    "NoOneTalk2ME",
    "Condescending Prick",
    "cute lute",
    "IvL",
    "Shirakiin",
    "WindyCreatre",
    "Snejik",
    "Lyoha",
    "TpaBoPuDgE",
    "kyonko",
    "Huan",
    "rain",
    "Link",
    "Tomura",
    "Hapchu",
    "greedisgood",
    "M.H.R",
    "kuya",
    "Greedo",
    "Mimin",
    "Smorc",
    "Hvick",
    "The Forbldden One King",
    "SB niggir",
    "Sky",
    "XPlay",
    "BELL",
    "Zergling warior",
    "Happiness",
    "GoodGuyl'mHungry",
    "Shiakim",
    "saiya",
    "Rip laptop",
    "Bratan",
    "Suika Ibuki Enjoyer",
    "Aqua",
    "CaptGuardian",
    "You wIll give me an egg",
    "Hahaln",
    "pitz",
    "Adolfo",
    "SOU",
    "Jieng",
    "Mako",
    "sana",
    "Fannie",
    "Matz",
    "Mike",
    "Lmk",
    "Eolln Harenz",
    "TheAim",
    "Blanc Enjoyer",
    "Plneapple Buttnaked",
    "mafuno",
    "Kaiser",
    "Jopax",

    # --- Cyrillic regulars ---
    "ХВИК",
    "Мо",
    "МИНИСТР ОБОРОНЫ",
    "ВЫХУХОЛЬ",
    "С1С2СЗ",
    "Чекни шейдеры",
    "меня всё заебало ёпта",

    # --- CJK regulars ---
    "宫廷士液酒",
    "夏霖",
    "喜怒哀乐凭依",
    "锵锵锵锵锵锵锵",
    "干夏蕾咪",
    "供克森市埸",
    "碰巧",
    "疾风",

    # --- earlier seeds (kept; historical regulars) ---
    "Lantraciua",
    "MapoTofu",
    "шешня",

    # --- add the still-garbled regulars' REAL names below as you identify them ---
    # (e.g. the "-отлчй" cluster, the "... +" cluster, the "#Zf#Жi" cluster — see
    #  the cluster report; once named here + aliased, their variants snap in.)
]
