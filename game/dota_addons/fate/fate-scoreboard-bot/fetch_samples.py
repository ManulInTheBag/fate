"""Download scoreboard screenshots from the watched Discord channel(s) to a local
folder, for OCR testing / validation. Read-only: it never posts, reacts, or
touches the stats DB — it just saves the image attachments to disk.

Usage (from the bot folder, with the venv python):
    python fetch_samples.py                 # last 200 messages
    python fetch_samples.py 1000            # last 1000 messages
    python fetch_samples.py all             # entire channel history
    python fetch_samples.py after 2026-05-01
    python fetch_samples.py 500 --out tests/shots   # custom output folder

Files are saved as  <YYYY-MM-DD>_<msgid>_<original-name>  so they're unique,
chronological, and traceable back to the source message. Re-running skips files
already on disk, so it's an incremental sync.
"""

import os
import sys
import asyncio
from datetime import datetime, timezone

import discord

import config

IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".bmp")
DEFAULT_OUT = os.path.join(os.path.dirname(__file__), "data", "samples")


def _parse_args(argv):
    """Return (limit, after_dt, out_dir). Mirrors %backfill's argument style."""
    out = DEFAULT_OUT
    if "--out" in argv:
        i = argv.index("--out")
        out = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    arg = " ".join(argv).strip().lower()

    limit, after_dt = 200, None
    if arg in ("all", "everything"):
        limit = None
    elif arg.startswith("after"):
        date = arg.replace("after", "").strip()
        after_dt = datetime.strptime(date, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        limit = None
    elif arg.isdigit():
        limit = int(arg)
    elif arg:
        raise SystemExit("Usage: python fetch_samples.py [N | all | after YYYY-MM-DD] [--out DIR]")
    return limit, after_dt, out


async def _run(limit, after_dt, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    intents = discord.Intents.default()
    intents.message_content = True
    client = discord.Client(intents=intents)

    @client.event
    async def on_ready():
        print(f"Logged in as {client.user}")
        total_saved = total_skipped = 0
        try:
            for cid in sorted(config.WATCH_CHANNEL_IDS):
                ch = client.get_channel(cid) or await client.fetch_channel(cid)
                if ch is None:
                    print(f"[warn] channel {cid} not found / not accessible")
                    continue
                print(f"Scanning #{ch} …")
                msgs = [m async for m in ch.history(limit=limit, after=after_dt)]
                msgs.sort(key=lambda m: m.created_at)
                images = [(m, att) for m in msgs if not m.author.bot
                          for att in m.attachments
                          if att.filename.lower().endswith(IMAGE_EXT)]
                print(f"  {len(images)} image(s) found")
                for m, att in images:
                    stamp = m.created_at.strftime("%Y-%m-%d")
                    safe = att.filename.replace(os.sep, "_").replace("/", "_")
                    name = f"{stamp}_{m.id}_{safe}"
                    path = os.path.join(out_dir, name)
                    if os.path.exists(path):
                        total_skipped += 1
                        continue
                    try:
                        await att.save(path)
                        total_saved += 1
                        if total_saved % 25 == 0:
                            print(f"  …{total_saved} downloaded")
                    except Exception as e:
                        print(f"  [err] {name}: {e}")
            print(f"\nDone. Saved {total_saved} new, skipped {total_skipped} "
                  f"already-present → {out_dir}")
        finally:
            await client.close()

    await client.start(config.DISCORD_TOKEN)


def main():
    if not config.DISCORD_TOKEN:
        raise SystemExit("Set DISCORD_TOKEN in your .env first.")
    if not config.WATCH_CHANNEL_IDS:
        raise SystemExit("No WATCH_CHANNEL_IDS set in your .env.")
    limit, after_dt, out_dir = _parse_args(sys.argv[1:])
    asyncio.run(_run(limit, after_dt, out_dir))


if __name__ == "__main__":
    main()
