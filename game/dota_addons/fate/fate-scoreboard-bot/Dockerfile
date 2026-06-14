# Portable image for the Fate scoreboard bot.
# Works on any Docker host (Fly.io, a VM, etc.). The data/ folder (SQLite DB)
# should be a mounted volume so stats survive restarts/redeploys.
FROM python:3.12-slim

# Tesseract + the language packs the bot uses, plus OpenCV's runtime libs.
RUN apt-get update && apt-get install -y --no-install-recommends \
        tesseract-ocr \
        tesseract-ocr-rus \
        tesseract-ocr-jpn \
        tesseract-ocr-chi-sim \
        tesseract-ocr-chi-tra \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# On Linux tesseract is on PATH here; OCR languages default sensibly.
ENV TESSERACT_CMD=/usr/bin/tesseract \
    OCR_LANG=eng+rus \
    OCR_LANG_CJK=chi_sim+chi_tra+jpn

# Provide DISCORD_TOKEN / WATCH_CHANNEL_IDS / CONTROL_CHANNEL_ID at RUN time
# (env vars or secrets) — never bake the token into the image.
CMD ["python", "bot.py"]
