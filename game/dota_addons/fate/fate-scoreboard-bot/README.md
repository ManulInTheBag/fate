# Fate Scoreboard Bot

A Discord bot that reads end-of-round **Fate** scoreboard screenshots with OCR
and turns them into a multi-sheet **Excel** report: player stats, hero stats,
hero picks per player, win/loss, KDA, and teammate stats — for any time range or
range of games you ask for.

It uses **two kinds of channel**, kept strictly separate:

```
  YOUR GROUP'S SERVER                 YOUR PRIVATE SERVER
  ┌────────────────────┐              ┌─────────────────────────────┐
  │ #scoreboards       │              │ #bot-control                │
  │ (people post pics) │   silent     │  • each parse posted here   │
  │                    │ ───────────► │    for review (✅ / ❌ / fix)│
  │ bot NEVER posts    │   OCR +      │  • %export today / 7d /     │
  │ or reacts here     │   fuzzy      │    games 10-25 → .xlsx      │
  └────────────────────┘              │  • %matches                 │
                                      └─────────────────────────────┘
                                                   │
                                              SQLite store
```

The **scoreboards channel stays completely clean** — the bot only reads it. All
of the bot's output and every command live in your own private **control
channel**, even if it's on a different server.

## Why there's a review step

Tesseract can't perfectly read stylized game fonts, Cyrillic, or Japanese names
(in practice ~1 wrong cell per board). The bot does the heavy lifting
(fixed-column crops + fuzzy-matching to your known hero/player lists) and posts
the parse to your control channel so you can fix the rare miss with a one-line
reply. Set `AUTO_CONFIRM=true` to skip the ✅ step and save everything
automatically (still correctable afterward).

---

## 1. Install

### a) Python deps
```powershell
cd "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota_addons\fate\fate-scoreboard-bot"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

> **Python 3.14 note:** if `pip install` fails on `opencv-python` / `numpy`
> (no wheels yet for 3.14), install Python **3.12** and create the venv with it:
> `py -3.12 -m venv .venv`. Everything else is the same.

### b) Tesseract OCR (one-time, system install)
Download the Windows installer (UB Mannheim build):
<https://github.com/UB-Mannheim/tesseract/wiki> → run it → keep the default
path `C:\Program Files\Tesseract-OCR`.

**Optional but recommended** for player names: during install, tick the
**Russian** and **Japanese** language data (or add them later). Then set
`OCR_LANG=eng+rus+jpn` in your `.env`.

### c) Configure
```powershell
copy .env.example .env
notepad .env
```
Fill in `DISCORD_TOKEN`, `WATCH_CHANNEL_IDS`, `CONTROL_CHANNEL_ID`, and the
Tesseract path.

---

## 2. Create the Discord bot
1. <https://discord.com/developers/applications> → **New Application**.
2. **Bot** tab → **Add Bot** → copy the **Token** into `.env` (`DISCORD_TOKEN`).
3. Under **Privileged Gateway Intents**, enable **MESSAGE CONTENT INTENT**.
4. **OAuth2 → URL Generator**: scope `bot`; permissions *Read Messages*,
   *Send Messages*, *Attach Files*, *Add Reactions*, *Read Message History*.
   Open the generated URL and invite the bot to **both** servers — your group's
   server (to read scoreboards) and your private server (to post stats).
5. Enable **Developer Mode** (Settings → Advanced). Then right-click:
   - your **scoreboards** channel → Copy Channel ID → `WATCH_CHANNEL_IDS`
     (comma-separate if you have several);
   - your private **control** channel → Copy Channel ID → `CONTROL_CHANNEL_ID`.

The bot never posts or reacts in the watched channel — it only reads it.

---

## 3. Calibrate the crops (do this once)

Save one of your scoreboards as a PNG and run:
```powershell
python calibrate.py path\to\scoreboard.png
```
It prints what it read and writes `data\debug\<name>_overlay.png` with colored
boxes over each column/row. If the boxes are off, tweak `COLUMNS` and `ROWS` in
`config.py` and re-run until they line up. (Defaults are calibrated for the
standard 1920×1080 scoreboard.)

---

## 4. Run
```powershell
python bot.py
```
**In your group's scoreboards channel:** people just post screenshots — the bot
reads them silently.

**In your private control channel**, the bot posts each parse for review:
- **React ✅** to save it (or set `AUTO_CONFIRM=true` to skip this), **❌** to discard.
- **Reply to correct** any cell:
  ```
  row5 player="cute lute" hero="Arturia Pendragon" k=13 d=16 a=37 gold=1077
  score 12-11
  winner top
  ```
  Fields: `k/d/a` (kills/deaths/assists), `gold`, `player`, `hero`. Quote values
  with spaces.

**Commands (control channel):**
| Command | Result |
|---------|--------|
| `%export` | Excel for **all** saved matches |
| `%export today` / `yesterday` / `week` / `month` | by time |
| `%export 7d` / `24h` / `90m` | last N days / hours / minutes |
| `%export last 5` | last 5 saved matches |
| `%export from 2026-06-01 to 2026-06-10` | inclusive date range |
| `%export games 10-25` / `game 14` | by game number (range) |
| `%matches` | list recent matches + their game numbers |
| `%help` | quick reference |

Use `%matches` to see game numbers, then `%export games N-M` for a specific
session.

---

## Excel sheets
| Sheet | Contents |
|-------|----------|
| Overview | counts + generation time |
| Player Stats | games, W/L, win %, K/D/A totals & averages, KDA, avg gold, most-played hero |
| Hero Stats | picks, win %, average K/D/A, KDA |
| Player-Hero | each player's record on each hero (hero choosing) |
| Teammates | every duo's games together + win rate |
| Matches | one row per match (date, winner, score) |
| Raw Match Players | every player-row of every match |

## The hero list is generated from the game files
`heroes.py` is **auto-generated** — don't hand-edit it. It's built by reading the
addon's own files:
- `scripts/npc/heroes/*.kv` → each Fate hero's `override_hero` (base Dota hero)
- `resource/addon_english.txt` → that base hero's scoreboard display name

So the names exactly match what shows in-game (e.g. `Oda Nobunaga` and
`Demon king Nobunaga` are correctly kept separate). When you add or rename a hero
in the mod, regenerate:
```powershell
python gen_heroes.py
```
It prints the full roster and rewrites `heroes.py`. It only includes heroes
actually `#base`-included in `npc_heroes_custom.txt`, so unused `.kv` files are
ignored.

## Player roster
- `roster.py` — seed player names (Discord/Steam personas can't come from the
  game files). The bot also **learns** new names whenever you confirm a match.

## Files
| File | Role |
|------|------|
| `bot.py` | Discord bot: silent watch + control channel commands |
| `periods.py` | parse `today` / `7d` / `games 10-25` into export filters |
| `ocr.py` | image → raw cells (OpenCV + Tesseract) |
| `parser.py` | fuzzy-match + team/winner assignment |
| `corrections.py` | apply your reply-corrections |
| `db.py` | SQLite storage (source of truth) |
| `stats.py` | aggregate confirmed matches |
| `excel_export.py` | build the .xlsx |
| `calibrate.py` | offline test / crop tuning |
| `gen_heroes.py` | regenerate `heroes.py` from the game files |
| `config.py` | settings + crop calibration |
