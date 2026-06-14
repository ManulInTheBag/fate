# Hosting the bot 24/7

The bot needs Tesseract + language packs, OpenCV, and a database file that
persists. That fits an **always-on Linux VM**, not the typical "free app host"
(those sleep and wipe the disk).

## ⚠️ Run only ONE copy
Discord allows one connection per bot token. **Stop the bot on your PC before
running it on a host** (and vice-versa), or they'll fight and disconnect.

## Move your existing stats with you
Your matches/aliases live in `data/scoreboards.db`. Copy that file to the host so
you don't start from zero. (If you skip it, the bot just starts empty.)

---

## Option A — Oracle Cloud "Always Free" VM (genuinely free, forever)

Best free choice: a real VM that never expires. Sign up at
<https://www.oracle.com/cloud/free/>, create an **Ubuntu 22.04** instance
(the "Ampere/ARM, Always Free" shape is plenty), and allow SSH. Then:

```bash
# 1. install system deps
sudo apt update
sudo apt install -y python3-venv python3-pip git \
    tesseract-ocr tesseract-ocr-rus tesseract-ocr-jpn \
    tesseract-ocr-chi-sim tesseract-ocr-chi-tra \
    libgl1 libglib2.0-0

# 2. copy the project up (run this FROM YOUR PC, in PowerShell):
#    scp -r "C:\...\fate-scoreboard-bot" ubuntu@YOUR_SERVER_IP:~/
#    (exclude .venv; or just re-create the venv on the server as below)

# 3. on the server: set up the venv
cd ~/fate-scoreboard-bot
python3 -m venv .venv
./.venv/bin/pip install -r requirements.txt

# 4. create the .env (paste your values)
nano .env
```

`.env` on Linux (note the Linux Tesseract path):
```
DISCORD_TOKEN=your-token
WATCH_CHANNEL_IDS=1515375076961423473
CONTROL_CHANNEL_ID=951715915559473175
AUTO_CONFIRM=false
TESSERACT_CMD=/usr/bin/tesseract
OCR_LANG=eng+rus
OCR_LANG_CJK=chi_sim+chi_tra+jpn
```

Then copy your `data/scoreboards.db` into `~/fate-scoreboard-bot/data/`, and run
it as a service so it survives crashes and reboots:
```bash
sudo cp deploy/fate-bot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now fate-bot
journalctl -u fate-bot -f          # watch the logs; Ctrl-C to stop watching
```
Done — it now runs 24/7 with your PC off. Update later with
`git pull` (or re-scp) then `sudo systemctl restart fate-bot`.

---

## Option B — Docker host (e.g. Fly.io free allowance, or any VM with Docker)

A `Dockerfile` is included. On any machine with Docker:
```bash
docker build -t fate-bot .
docker run -d --name fate-bot --restart=always \
  -e DISCORD_TOKEN=your-token \
  -e WATCH_CHANNEL_IDS=1515375076961423473 \
  -e CONTROL_CHANNEL_ID=951715915559473175 \
  -v fate-data:/app/data \
  fate-bot
```
The `-v fate-data:/app/data` volume keeps the database across restarts. To seed
your existing stats, copy `scoreboards.db` into that volume before first run.

For **Fly.io** specifically: `fly launch` (uses the Dockerfile), add a volume
mounted at `/app/data`, and set secrets with
`fly secrets set DISCORD_TOKEN=... CONTROL_CHANNEL_ID=... WATCH_CHANNEL_IDS=...`.

---

## Option C — cheapest no-hassle (~$4/month)
If the Oracle setup feels fiddly, a tiny VPS (Hetzner ~€4, DigitalOcean $4) is
the least-effort reliable path — same steps as Option A. Not free, but trivial.

## Option D — your own hardware
An old laptop or a Raspberry Pi left on at home runs this fine (same Linux steps,
or just keep it running on Windows). Free if you already have the device.

---

## After it's hosted
Everything works the same — post scoreboards in the watched channel, run commands
in your control channel. To pull new code changes you make locally, copy them up
and restart the service/container.
