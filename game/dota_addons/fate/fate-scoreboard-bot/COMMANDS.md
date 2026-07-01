# Bot — Command Guide

## Turn the bot on / off
- **On:** double-click the **Fate Bot** shortcut (or `Start Bot.bat`). A window
  opens — the bot runs while it's open.
- **Off:** close the window.

The bot works only while the window is open and your PC is on. First start loads
the OCR models (the window shows `EasyOCR models ready`).

---

## How it works
1. Someone posts a **scoreboard screenshot** in the game channel.
2. The bot reads it silently and posts the parsed table in **your control channel**
   (it never writes in the game channel).
3. You review it there:
   - **✅** save to stats · **❌** discard · **reply** to fix a cell, then ✅

### Fixing cells (reply to the bot's message)
One change per line. Quote names with spaces.

| Type this | Effect |
|-----------|--------|
| `row6 k=5` | set kills on row 6 |
| `row6 k=5 d=13 a=32` | set K/D/A on row 6 |
| `row1 player="某個索引信使"` | fix a player name |
| `row3 hero="Oda Nobunaga"` | fix a hero |
| `score 12-6` | fix the score |
| `winner top` | which side won (`top`/`bottom`) |

Fields: `k` kills · `d` deaths · `a` assists · `player` · `hero`.

---

## Stats — `%export`
Builds an Excel file and posts it in the control channel.

| Command | Gives you |
|---------|-----------|
| `%export` | everything, all time |
| `%export today` / `yesterday` / `week` / `month` | by time |
| `%export 7d` / `24h` / `90m` | last N days / hours / minutes |
| `%export last 5` | the last 5 saved games |
| `%export from 2026-06-01 to 2026-06-10` | a date range |
| `%export games 10-25` / `game 14` | by game number |

**`%report N`** — quick: imports the latest games from the channel **and** exports
the last N in one step (e.g. `%report 10`).

---

## Viewing
| Command | Shows |
|---------|-------|
| `%matches` | recent games with their **game numbers** |
| `%players` | every player with how many games they have |
| `%help` | short reference in Discord |

---

## Linking the same player — `%alias` / `%links`
For alt accounts or names spelled differently by OCR — make them count as one.

| Command | Effect |
|---------|--------|
| `%alias "ReadName" "RealName"` | count the misread name as the real player |
| `%alias "ReadName" = "RealName"` | same thing, with `=` (also works) |
| `%alias` | list all links |
| `%unalias "ReadName"` | remove a link |
| `%links` | numbered suggestions of likely-same players |
| `%links apply` | apply all **high-confidence** suggestions |
| `%links apply all` | apply every suggestion (high + low) |
| `%links apply 1 3 5-7` | apply just those numbers (ranges ok) |
| `%links name 4 "Real Name"` | merge suggestion #4 (both names) onto a real player and learn the name |

Quote names that contain spaces. Example: `%alias "Ъ" "b"` or `%alias "cute Iute" "cute lute"`.

`%links` numbers every suggestion so you can apply several at once. It has two
tiers: **HIGH** (a stray name that closely matches a known regular, or a near-
duplicate of a more-frequent name — safe to bulk-apply) and **LOW** (heavily
garbled cross-script nicks grouped because they look alike and never played in the
same game — review, then `%links name N "Real"` to label the person). Known
regulars live in `roster.py`; suggestions aim at that list, so filling it in makes
linking sharper.

---

## Deleting data
**`%clear`** — delete games by range (two-step; needs `confirm`):

| Command | Effect |
|---------|--------|
| `%clear all` | preview (deletes nothing) |
| `%clear all confirm` | delete everything |
| `%clear game 14 confirm` · `%clear games 10-25 confirm` | by number |
| `%clear today confirm` · `%clear from … to … confirm` | by time |

**`%cleanup`** — remove games that aren't real Fate scoreboards (wrong format /
mis-read). `%cleanup` previews the count, `%cleanup confirm` deletes them.

---

## Importing old games — `%backfill`
Reads scoreboards posted **before the bot existed**. Safe to re-run (skips ones
already imported), keeps each game's original date.

| Command | Effect |
|---------|--------|
| `%backfill` | the last 200 messages |
| `%backfill all` | the entire channel history |
| `%backfill after 2026-05-01` | everything since a date |

Watch the bot window for live progress. EasyOCR is accurate but slow, so a big
backfill takes a while.

---

## What's automatic
- **Heroes** are snapped to the real 51-hero list; unreadable ones become `Unknown`.
- **Chinese scoreboards** are supported — Chinese hero names map to English.
- **Wrong formats** (the in-game Tab overlay, memes, chat screenshots) are skipped
  automatically; you'll see `✗ ignored` in the window.
- **Players** are merged through your `%alias` / `%links`.

## Typical flow
✅ each game as it's posted → occasionally `%players` to find duplicates →
`%alias` them → `%export today` (or `%report 10`) for the Excel.
