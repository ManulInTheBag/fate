"""Discord bot.

Two roles, kept strictly separate:

  WATCH channels  (your group's server): the bot reads scoreboard screenshots
                  SILENTLY. It never posts or reacts there.
  CONTROL channel (your own private server): the bot posts every parsed
                  scoreboard here for review, sends all stats/exports here, and
                  accepts commands here.

Commands (control channel only):
  %export [period]   period = today | yesterday | week | month | 7d | 24h |
                              last 5 | from 2026-06-01 to 2026-06-10 | games 10-25
  %matches           list recent saved matches with their game numbers
  %help

Review a posted scoreboard: react ✅ to save (skip if AUTO_CONFIRM), ❌ to delete,
or reply to it to fix cells, e.g.  row6 k=5   ·   score 12-11

Run:  python bot.py
"""

import asyncio
import traceback

import discord

import config
import db
import ocr
import parser as score_parser
import corrections
import excel_export
import periods

import sys
from datetime import datetime

# Print player names / status with any script (CJK, Cyrillic) without crashing
# the Windows console window the bot runs in.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


def log(msg):
    """Print a timestamped line to the bot's console window."""
    print(f"[{datetime.now():%H:%M:%S}] {msg}", flush=True)


intents = discord.Intents.default()
intents.message_content = True
intents.reactions = True
client = discord.Client(intents=intents)

CONFIRM, REJECT = "✅", "❌"
IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".bmp")


def _is_admin(user_id):
    return not config.ADMIN_USER_IDS or user_id in config.ADMIN_USER_IDS


def _control_channel():
    return client.get_channel(config.CONTROL_CHANNEL_ID)


def _table_message(match, header):
    return f"{header}\n```\n{score_parser.format_table(match)}\n```"


# ---------- silent ingestion from watch channels ----------

async def _ingest(message, attachment, quiet=False):
    """Process one scoreboard image. Returns 'saved', 'skipped', 'ignored', or
    'failed'. `quiet` suppresses the per-image control-channel posts (backfill)."""
    who = f"{attachment.filename} from {message.author.display_name}"
    control = _control_channel()
    if control is None:
        log(f"[warn] control channel {config.CONTROL_CHANNEL_ID} not found")
        return "failed"

    if db.source_exists(message.id):
        log(f"· skip (already saved): {who}")
        return "skipped"

    try:
        data = await attachment.read()
        # OCR is blocking (spawns Tesseract); run it off the event loop so the
        # Discord heartbeat keeps flowing during long backfills.
        extracted = await asyncio.to_thread(ocr.extract, data, f"{message.id}.png")
    except Exception:
        traceback.print_exc()
        log(f"✗ OCR error: {who}")
        return "failed"

    match = score_parser.build_match(extracted, db.get_roster())
    if not match["valid"]:
        log(f"✗ ignored (not a scoreboard — {match['reason']}): {who}")
        return "ignored"
    when = message.created_at  # original post time (UTC), keeps history accurate
    src = (f"📥 Scoreboard from **{message.author.display_name}** in "
           f"**#{message.channel}** · {when:%Y-%m-%d %H:%M} · [source]({message.jump_url})")
    action = ("Saved automatically — reply to fix cells, ❌ to remove."
              if config.AUTO_CONFIRM else
              "React ✅ to save, ❌ to discard, or reply to fix cells "
              "(e.g. `row6 k=5`).")
    sent = await control.send(_table_message(match, f"{src}\n{action}"))

    db.save_pending(sent.id, control.id, attachment.url, match,
                    source_message_id=message.id, posted_at=when.timestamp())
    if config.AUTO_CONFIRM:
        db.confirm(sent.id)
    try:
        await sent.add_reaction(CONFIRM)
        await sent.add_reaction(REJECT)
    except discord.HTTPException:
        pass
    st, sb = extracted["score_top"], extracted["score_bottom"]
    log(f"✓ saved: {extracted['n_rows']} players, score {st}-{sb} | {who}")
    return "saved"


async def _ingest_silent(message, attachment):
    """Backfill path: OCR + save + confirm directly, no per-game review message
    (avoids flooding the channel when importing a big history). Keyed by the
    original message so it's deduped and re-runnable."""
    who = f"{attachment.filename} ({message.created_at:%Y-%m-%d})"
    if db.source_exists(message.id):
        log(f"· skip (already saved): {who}")
        return "skipped"
    try:
        data = await attachment.read()
        extracted = await asyncio.to_thread(ocr.extract, data)
    except Exception:
        traceback.print_exc()
        log(f"✗ OCR error: {who}")
        return "failed"
    match = score_parser.build_match(extracted, db.get_roster())
    if not match["valid"]:
        log(f"✗ ignored (not a scoreboard — {match['reason']}): {who}")
        return "ignored"
    when = message.created_at
    db.save_pending(message.id, message.channel.id, attachment.url, match,
                    source_message_id=message.id, posted_at=when.timestamp())
    db.confirm(message.id)
    st, sb = extracted["score_top"], extracted["score_bottom"]
    log(f"✓ saved: {extracted['n_rows']} players, score {st}-{sb} | {who}")
    return "saved"


# ---------- control-channel commands ----------

async def _cmd_backfill(channel, arg):
    """Import scoreboards posted before the bot existed.

    %backfill            last 200 messages, auto-imported
    %backfill 1000       last 1000 messages
    %backfill all        entire history
    %backfill after 2026-05-01   everything since a date
    add  review          at the end to post each for ✅ instead of auto-import
    """
    import re
    from datetime import datetime, timezone

    if not config.WATCH_CHANNEL_IDS:
        await channel.send("⚠️ No watch channels configured.")
        return

    arg = arg.strip().lower()
    review = arg.endswith("review")
    if review:
        arg = arg[: -len("review")].strip()

    limit, after_dt, scope = 200, None, "the last 200 messages"
    if arg in ("all", "everything"):
        limit, scope = None, "all history"
    elif arg.startswith("after"):
        m = re.search(r"(\d{4}-\d{2}-\d{2})", arg)
        if not m:
            await channel.send("Use: `%backfill after 2026-05-01`")
            return
        after_dt = datetime.strptime(m.group(1), "%Y-%m-%d").replace(tzinfo=timezone.utc)
        limit, scope = None, f"messages since {m.group(1)}"
    elif arg:
        if not arg.isdigit():
            await channel.send("Use: `%backfill [N | all | after YYYY-MM-DD] [review]`")
            return
        limit = int(arg)
        scope = f"the last {limit} messages"

    mode = "posting each for review" if review else "auto-importing"
    await channel.send(f"⏳ Backfill started — scanning {scope} in "
                       f"{len(config.WATCH_CHANNEL_IDS)} channel(s), {mode}. "
                       f"Watch the bot window for progress. This can take a while…")
    log(f"===== BACKFILL START ({scope}) =====")

    saved = skipped = failed = ignored = done = 0
    for cid in config.WATCH_CHANNEL_IDS:
        ch = client.get_channel(cid)
        if ch is None:
            continue
        msgs = [m async for m in ch.history(limit=limit, after=after_dt)]
        msgs.sort(key=lambda m: m.created_at)  # oldest first → chronological game #s
        images = [(m, att) for m in msgs if not m.author.bot
                  for att in m.attachments if att.filename.lower().endswith(IMAGE_EXT)]
        log(f"#{ch}: {len(images)} image(s) to check")
        for i, (m, att) in enumerate(images, 1):
            res = await (_ingest(m, att, quiet=True) if review
                         else _ingest_silent(m, att))
            saved += res == "saved"
            skipped += res == "skipped"
            failed += res == "failed"
            ignored += res == "ignored"
            done += 1
            if done % 10 == 0:
                log(f"   progress {i}/{len(images)} — "
                    f"saved {saved}, skip {skipped}, trash {ignored}, err {failed}")

    log(f"===== BACKFILL DONE: saved {saved}, skipped {skipped}, "
        f"trash {ignored}, errors {failed} =====")
    await channel.send(
        f"✅ Backfill done. Imported **{saved}**, skipped **{skipped}** "
        f"(already saved), ignored **{ignored}** (not scoreboards), "
        f"couldn't read **{failed}**.\n"
        + ("Review the posted scoreboards above." if review else
           "Run `%export` to see the data. Spot-check the Excel for OCR errors.")
    )

async def _cmd_help(channel):
    await channel.send(
        "**Fate scoreboard bot**\n"
        "I silently read scoreboards from the watched channel(s) and post each "
        "one here for review.\n\n"
        "**Review:** ✅ save · ❌ delete · reply to fix (e.g. `row6 k=5`, `score 12-11`)\n"
        "**`%export [period]`** — build an Excel report. Period examples:\n"
        "`%export` (all) · `%export today` · `%export week` · `%export 7d` · "
        "`%export last 5` · `%export from 2026-06-01 to 2026-06-10` · `%export games 10-25`\n"
        "**`%matches`** — list recent saved matches and their game numbers.\n"
        "**`%backfill [N|all|after YYYY-MM-DD] [review]`** — import old scoreboards "
        "already posted in the watched channel.\n"
        "**`%clear <what> [confirm]`** — delete matches (e.g. `%clear games 10-25`, "
        "`%clear all confirm`).\n"
        "**`%cleanup [confirm]`** — remove saved games that aren't Fate scoreboards "
        "(wrong format).\n"
        "**`%report N`** — import the latest games and export the last N (clean).\n"
        "**`%alias \"ReadName\" \"RealName\"`** — link a misread / alt name to the real "
        "player (`%alias` lists, `%unalias \"ReadName\"` removes).\n"
        "**`%links`** — numbered suggestions of likely-same players. Apply many at "
        "once: `%links apply` (all high-confidence), `%links apply 1 3 5-7`, or "
        "`%links name 4 \"Real Name\"`.\n"
        "**`%players`** — list everyone with game counts (to spot duplicates to `%alias`)."
    )


async def _cmd_matches(channel):
    rows = db.recent_confirmed_matches(15)
    if not rows:
        await channel.send("No saved matches yet.")
        return
    from datetime import datetime
    lines = ["Recent saved matches (newest first):", "", f"{'Game':>5}  {'Date':<16}  Result"]
    for m in rows:
        d = datetime.fromtimestamp(m["posted_at"]).strftime("%Y-%m-%d %H:%M")
        lines.append(f"{m['id']:>5}  {d:<16}  {m['winner'].upper()} "
                     f"{m['score_top']}-{m['score_bottom']}")
    await channel.send("```\n" + "\n".join(lines) + "\n```")


async def _cmd_export(channel, arg):
    recent_ids = [m["id"] for m in db.recent_confirmed_matches(1000)]
    try:
        filters, label = periods.parse(arg, recent_ids)
    except ValueError as e:
        await channel.send(f"⚠️ {e}")
        return
    try:
        path, n = await asyncio.to_thread(
            excel_export.export, None, filters, label)
    except Exception:
        traceback.print_exc()
        await channel.send("⚠️ Export failed — check the console.")
        return
    if n == 0:
        await channel.send(f"No saved matches for **{label}**.")
        return
    await channel.send(f"📊 **{label}** — {n} match(es).",
                       file=discord.File(path, filename="fate_stats.xlsx"))


async def _cmd_clear(channel, arg):
    """Delete saved matches. Two-step: shows the count first, deletes only when
    the command ends with `confirm`."""
    arg = arg.strip()
    confirm = arg.lower().endswith("confirm")
    if confirm:
        arg = arg[: -len("confirm")].strip()
    if not arg:
        await channel.send(
            "Usage: `%clear <what> confirm`\n"
            "`what` = `all` · `today` · `last 5` · `games 10-25` · `game 14` · "
            "`from 2026-06-01 to 2026-06-10`\n"
            "Without `confirm` I just show how many would be deleted.")
        return

    recent_ids = [m["id"] for m in db.recent_confirmed_matches(1000)]
    try:
        filters, label = periods.parse(arg, recent_ids)
    except ValueError as e:
        await channel.send(f"⚠️ {e}")
        return

    n = db.count_matches(**filters)
    if n == 0:
        await channel.send(f"Nothing to delete for **{label}**.")
        return
    if not confirm:
        await channel.send(
            f"⚠️ This will **permanently delete {n} match(es)** — **{label}**.\n"
            f"To confirm, run: `%clear {arg} confirm`")
        return
    deleted = db.delete_matches(**filters)
    await channel.send(f"🗑️ Deleted **{deleted}** match(es) — **{label}**.")


async def _cmd_alias(channel, arg):
    """Link player names. `%alias <other> <main>` (or `%alias <other> = <main>`)
    merges <other> onto <main> in all stats. `%alias` lists them;
    `%alias remove <other>` unlinks. Quote names that contain spaces."""
    import shlex
    arg = arg.strip()
    if not arg:
        rows = db.list_aliases()
        if not rows:
            await channel.send("No aliases yet. Add one with "
                               "`%alias \"Read Name\" \"Real Name\"`.")
            return
        lines = ["**Linked names** (read → real):", "```"]
        lines += [f"{a}  →  {c}" for a, c in rows]
        lines.append("```")
        await channel.send("\n".join(lines))
        return

    low = arg.lower()
    if low.startswith(("remove ", "rm ", "delete ")):
        target = arg.split(None, 1)[1].strip().strip('"')
        n = db.remove_alias(target)
        await channel.send(f"✅ Unlinked **{target}**." if n else
                           f"No alias named **{target}**.")
        return

    # accept either  alt = main   or   "alt" "main"  (space-separated)
    alt = main = None
    if "=" in arg:
        left, right = arg.split("=", 1)
        alt, main = left.strip().strip('"').strip(), right.strip().strip('"').strip()
    else:
        try:
            parts = shlex.split(arg)
        except ValueError:
            parts = arg.split()
        if len(parts) == 2:
            alt, main = parts[0], parts[1]
    if not alt or not main:
        await channel.send('Use: `%alias "Read Name" "Real Name"`  (or with `=`)  ·  '
                           '`%alias` to list  ·  `%alias remove "Read Name"`')
        return
    db.add_alias(alt, main)
    await channel.send(f"🔗 Linked **{alt}** → **{main}**. It now counts as "
                       f"{main} in all stats.")


def _parse_indices(text, n):
    """Parse '1 3 5-7' (or commas) into a sorted set of valid 1..n indices."""
    picked = set()
    for tok in text.replace(",", " ").split():
        if "-" in tok[1:]:                       # a range like 5-7
            lo, _, hi = tok.partition("-")
            try:
                lo, hi = int(lo), int(hi)
            except ValueError:
                continue
            for i in range(min(lo, hi), max(lo, hi) + 1):
                if 1 <= i <= n:
                    picked.add(i)
        else:
            try:
                i = int(tok)
            except ValueError:
                continue
            if 1 <= i <= n:
                picked.add(i)
    return sorted(picked)


async def _cmd_links(channel, arg):
    """Suggest likely-same players; numbered so you can apply several at once.

      %links                list numbered suggestions
      %links apply          apply all HIGH-confidence ones
      %links apply all      apply every suggestion (high + low)
      %links apply 1 3 5-7  apply just those numbers
      %links name 4 "Real"  merge suggestion 4 (both names) onto a real player
    """
    import linking
    suggestions = await asyncio.to_thread(linking.suggest)
    if not suggestions:
        await channel.send("No likely duplicate players found. (Heavily garbled "
                           "cross-script nicks may still need a manual `%alias`.)")
        return

    low = arg.strip().lower()

    # ---- name N "Real": merge a whole suggested pair onto a real player ----
    if low.startswith("name"):
        rest = arg.strip()[4:].strip()
        parts = rest.split(None, 1)
        if len(parts) != 2 or not parts[0].isdigit():
            await channel.send('Use: `%links name <number> "Real Name"`')
            return
        idx = int(parts[0])
        if not (1 <= idx <= len(suggestions)):
            await channel.send(f"No suggestion #{idx} (have 1–{len(suggestions)}).")
            return
        real = parts[1].strip().strip('"').strip()
        s = suggestions[idx - 1]
        db.add_alias(s["alias"], real)
        db.add_alias(s["main"], real)
        db.remember_player(real)
        await channel.send(f"🔗 #{idx}: **{s['alias']}** and **{s['main']}** now count "
                           f"as **{real}**. (Add {real} to roster.py to make it stick.)")
        return

    # ---- apply [all | <numbers>] ----
    if low.startswith("apply"):
        sel = arg.strip()[5:].strip()
        if sel == "" :
            chosen = [s for s in suggestions if s["tier"] == "high"]
            label = f"{len(chosen)} high-confidence"
        elif sel.lower() == "all":
            chosen = suggestions
            label = f"all {len(chosen)}"
        else:
            idxs = _parse_indices(sel, len(suggestions))
            if not idxs:
                await channel.send("No valid numbers. e.g. `%links apply 1 3 5-7`")
                return
            chosen = [suggestions[i - 1] for i in idxs]
            label = f"{len(chosen)} selected (#{', #'.join(map(str, idxs))})"
        for s in chosen:
            db.add_alias(s["alias"], s["main"])
        await channel.send(f"🔗 Linked **{label}** name(s) to their main player. "
                           f"Re-export to see merged stats.")
        return

    # ---- list (numbered) ----
    high = [(i, s) for i, s in enumerate(suggestions, 1) if s["tier"] == "high"]
    lowt = [(i, s) for i, s in enumerate(suggestions, 1) if s["tier"] == "low"]
    lines = ["**Likely same players** — number, alias → main (similarity):", "```"]
    if high:
        lines.append("HIGH confidence (safe to apply all):")
        for i, s in high:
            lines.append(f'{i:>3}. {s["alias"]} ({s["alias_count"]}) → '
                         f'{s["main"]} ({s["main_count"]})  {s["score"]}%')
    if lowt:
        lines.append("")
        lines.append("LOW confidence — garbled nicks, review/name first:")
        for i, s in lowt:
            lines.append(f'{i:>3}. {s["alias"]} ({s["alias_count"]}) → '
                         f'{s["main"]} ({s["main_count"]})  {s["score"]}%')
    lines.append("```")
    lines.append("Apply: **`%links apply`** (all high) · `%links apply all` · "
                 "`%links apply 1 3 5-7`")
    lines.append('Name a real player: `%links name 4 \"Real Name\"` '
                 '(merges that pair and learns the name).')
    # Discord 2000-char cap: send in chunks if needed
    msg = "\n".join(lines)
    if len(msg) <= 1900:
        await channel.send(msg)
    else:
        await _send_chunked(channel, lines)


async def _send_chunked(channel, lines):
    buf, fence = [], "```"
    size = 0
    for ln in lines:
        if size + len(ln) > 1800:
            await channel.send("\n".join(buf))
            buf, size = [], 0
        buf.append(ln); size += len(ln) + 1
    if buf:
        await channel.send("\n".join(buf))


async def _cmd_cleanup(channel, arg):
    """Find/remove already-saved matches that aren't real Fate scoreboards
    (wrong format imported before validation) — detected by how few of their
    heroes match the real roster."""
    import normalize
    from collections import defaultdict

    rows = await asyncio.to_thread(db.all_confirmed_players)
    by_match = defaultdict(list)
    for r in rows:
        by_match[r["match_id"]].append(r)

    bad = []
    for mid, prows in by_match.items():
        recog = sum(1 for r in prows
                    if normalize.clean_hero(r["hero"]) != normalize.UNKNOWN_HERO)
        if prows and recog / len(prows) < 0.4:
            bad.append(mid)

    if not bad:
        await channel.send("✅ All saved matches look like real Fate scoreboards — "
                           "nothing to clean.")
        return
    if arg.strip().lower() == "confirm":
        n = db.delete_match_ids(bad)
        log(f"cleanup: deleted {n} non-Fate matches")
        await channel.send(f"🗑️ Deleted **{n}** match(es) that weren't Fate "
                           f"scoreboards. Re-run `%export` for clean stats.")
        return
    await channel.send(
        f"Found **{len(bad)}** saved match(es) that don't look like Fate "
        f"scoreboards (few/no recognized heroes — usually the in-game Tab "
        f"overlay or another format).\n"
        f"Run **`%cleanup confirm`** to delete them. (Maybe `%export` first as a "
        f"backup.)")


async def _cmd_players(channel):
    """List every distinct player (after aliases) with game counts, so duplicates
    are easy to eyeball and link by hand."""
    import stats
    data = await asyncio.to_thread(stats.compute)
    rows = sorted(data["players"], key=lambda p: p["player"].lower())
    if not rows:
        await channel.send("No players yet.")
        return
    lines, chunk = [], []
    for p in rows:
        chunk.append(f"{p['games']:>3}  {p['player']}")
    body = "Players (games · name) — link duplicates with `%alias \"Alt\" = \"Main\"`:\n```\n" \
           + "\n".join(chunk) + "\n```"
    # Discord 2000-char limit: split if needed
    if len(body) <= 1990:
        await channel.send(body)
    else:
        await channel.send("Players (games · name):")
        buf = "```\n"
        for line in chunk:
            if len(buf) + len(line) > 1900:
                await channel.send(buf + "```")
                buf = "```\n"
            buf += line + "\n"
        await channel.send(buf + "```")


async def _cmd_report(channel, arg):
    """Quick: import the last N games from the channel, then export just those."""
    n = arg.strip()
    if not n.isdigit():
        await channel.send("Usage: `%report 10` — backfill the latest games and "
                           "export the last 10 (clean).")
        return
    n = int(n)
    await _cmd_backfill(channel, str(max(n * 2, 30)))  # import latest, deduped
    await _cmd_export(channel, f"last {n}")


# ---------- correction replies ----------

async def _try_correction(message):
    rec = db.get_pending_by_message(message.reference.message_id)
    if not rec:
        return False
    match, applied, errors = corrections.apply(rec["match"], message.content)
    db.update_pending(message.reference.message_id, match)
    if rec["confirmed"]:
        db.confirm(message.reference.message_id)  # re-materialize stats rows
    try:
        bot_msg = await message.channel.fetch_message(message.reference.message_id)
        head = bot_msg.content.split("\n```", 1)[0]
        await bot_msg.edit(content=_table_message(match, head + "  *(edited)*"))
    except discord.HTTPException:
        pass
    note = []
    if applied:
        note.append("✅ " + "; ".join(applied))
    if errors:
        note.append("⚠️ " + "; ".join(errors))
    await message.reply("\n".join(note) or "Nothing recognized to change.",
                        mention_author=False)
    return True


# ---------- events ----------

@client.event
async def on_ready():
    db.init_db()
    print(f"Logged in as {client.user}")
    print(f"  watching channels: {sorted(config.WATCH_CHANNEL_IDS) or '(none set)'}")
    print(f"  control channel:   {config.CONTROL_CHANNEL_ID or '(none set)'}")
    print(f"  auto-confirm:      {config.AUTO_CONFIRM}")
    print(f"  OCR engine:        {config.OCR_ENGINE}")
    if config.OCR_ENGINE == "easyocr":
        log("loading EasyOCR models (first run downloads them)…")
        try:
            import easyocr_backend
            await asyncio.to_thread(easyocr_backend.warmup)
            log("EasyOCR models ready.")
        except Exception:
            traceback.print_exc()
            log("⚠️ EasyOCR failed to load — set OCR_ENGINE=tesseract in .env to fall back.")


@client.event
async def on_message(message):
    if message.author.bot:
        return

    # --- control channel: commands + corrections ---
    if message.channel.id == config.CONTROL_CHANNEL_ID:
        if not _is_admin(message.author.id):
            return
        if message.reference and message.reference.message_id:
            if await _try_correction(message):
                return
        content = message.content.strip()
        low = content.lower()
        if low == "%help":
            await _cmd_help(message.channel)
        elif low == "%matches":
            await _cmd_matches(message.channel)
        elif low.startswith("%export"):
            await _cmd_export(message.channel, content[len("%export"):].strip())
        elif low.startswith("%backfill"):
            await _cmd_backfill(message.channel, content[len("%backfill"):].strip())
        elif low.startswith("%cleanup"):
            await _cmd_cleanup(message.channel, content[len("%cleanup"):].strip())
        elif low.startswith("%clear"):
            await _cmd_clear(message.channel, content[len("%clear"):].strip())
        elif low.startswith("%report"):
            await _cmd_report(message.channel, content[len("%report"):].strip())
        elif low.startswith("%links"):
            await _cmd_links(message.channel, content[len("%links"):].strip())
        elif low == "%players":
            await _cmd_players(message.channel)
        elif low == "%aliases":
            await _cmd_alias(message.channel, "")
        elif low.startswith("%unalias"):
            await _cmd_alias(message.channel, "remove " + content[len("%unalias"):].strip())
        elif low.startswith("%alias"):
            await _cmd_alias(message.channel, content[len("%alias"):].strip())
        return

    # --- watch channels: silent ingestion only ---
    if message.channel.id in config.WATCH_CHANNEL_IDS:
        for att in message.attachments:
            if att.filename.lower().endswith(IMAGE_EXT):
                await _ingest(message, att)
        return
    # everything else: ignore


@client.event
async def on_raw_reaction_add(payload):
    if payload.user_id == client.user.id:
        return
    if payload.channel_id != config.CONTROL_CHANNEL_ID:
        return
    if str(payload.emoji) not in (CONFIRM, REJECT):
        return
    if not _is_admin(payload.user_id):
        return
    rec = db.get_pending_by_message(payload.message_id)
    if not rec:
        return
    channel = client.get_channel(payload.channel_id)
    if str(payload.emoji) == CONFIRM:
        db.confirm(payload.message_id)
        if channel:
            await channel.send(f"💾 Saved match #{rec['id']}.")
    else:
        db.delete_match(payload.message_id)
        if channel:
            await channel.send("🗑️ Discarded that scoreboard.")


def main():
    if not config.DISCORD_TOKEN:
        raise SystemExit("Set DISCORD_TOKEN in your .env file first.")
    if not config.CONTROL_CHANNEL_ID:
        raise SystemExit("Set CONTROL_CHANNEL_ID in your .env (the bot's own channel).")
    if not config.WATCH_CHANNEL_IDS:
        print("[warn] No WATCH_CHANNEL_IDS set — the bot won't ingest anything.")
    db.init_db()
    client.run(config.DISCORD_TOKEN)


if __name__ == "__main__":
    main()
