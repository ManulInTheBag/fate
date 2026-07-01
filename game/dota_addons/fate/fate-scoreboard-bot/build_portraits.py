"""Build the hero-portrait library used by hero_vision.match.

Scans a folder of scoreboard screenshots, and for every row whose hero the TEXT
OCR read confidently, stores that row's portrait vector under the known hero
name. The result (data/hero_portraits.npz) lets the bot recognise a hero from its
icon when the name text is unreadable.

Usage (from the bot folder, with the venv python):
    python build_portraits.py                 # learn from data/samples
    python build_portraits.py tests/shots      # a different folder
    python build_portraits.py --min-conf 85    # stricter text-confidence cutoff

Re-run whenever you've downloaded more boards (fetch_samples.py) to widen
coverage. It's additive in spirit but rebuilds from scratch each time, so it
always reflects the current image folder.
"""

import os
import sys

import cv2

import config
import ocr
import normalize
import hero_vision
import parser as score_parser

IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".bmp")
PER_HERO_CAP = 12          # keep at most this many sample portraits per hero


def main():
    args = sys.argv[1:]
    min_conf = config.FUZZY_THRESHOLD
    if "--min-conf" in args:
        i = args.index("--min-conf")
        min_conf = int(args[i + 1])
        args = args[:i] + args[i + 2:]
    folder = args[0] if args else os.path.join(os.path.dirname(__file__), "data", "samples")

    if not os.path.isdir(folder):
        raise SystemExit(f"Folder not found: {folder}")
    files = sorted(f for f in os.listdir(folder) if f.lower().endswith(IMAGE_EXT))
    if not files:
        raise SystemExit(f"No images in {folder}")

    import easyocr_backend
    easyocr_backend.warmup()

    by_hero = {}               # hero -> list of vectors
    boards = rows_seen = 0
    for fn in files:
        path = os.path.join(folder, fn)
        data = open(path, "rb").read()
        img = cv2.imread(path)
        if img is None:
            continue
        ext = ocr.extract(data)
        match = score_parser.build_match(ext, [])
        if not match["valid"]:
            continue
        rows, cols = ocr.detect_rows(img)
        if len(rows) != len(match["players"]):
            continue                    # row/player misalignment -> skip this board
        boards += 1
        pitch = (rows[-1][0] - rows[0][0]) / max(1, len(rows) - 1)
        for p, (cy, *_rest) in zip(match["players"], rows):
            hero = normalize.clean_hero(p["hero"])
            if hero == normalize.UNKNOWN_HERO or p["hero_conf"] < min_conf:
                continue
            vec = hero_vision.vector(img, cols["name"], cy, pitch)
            if vec is None:
                continue
            by_hero.setdefault(hero, []).append(vec)
            rows_seen += 1

    # Keep a spread of samples per hero (cap), then flatten to (vectors, labels).
    vectors, labels = [], []
    for hero, vecs in sorted(by_hero.items()):
        for v in vecs[:PER_HERO_CAP]:
            vectors.append(v)
            labels.append(hero)

    if not vectors:
        raise SystemExit("No confident portraits found — nothing to build.")
    hero_vision.save_library(vectors, labels)
    print(f"Scanned {len(files)} image(s), {boards} valid board(s), "
          f"{rows_seen} confident portrait(s).")
    print(f"Library: {len(vectors)} vectors across {len(by_hero)} heroes "
          f"-> {hero_vision.LIB_PATH}")
    missing = sorted(set(normalize._HERO_SET) - set(by_hero))
    if missing:
        print(f"\n{len(missing)} hero(es) not yet covered (need a board where the "
              f"name reads cleanly):")
        print("  " + ", ".join(missing))


if __name__ == "__main__":
    main()
