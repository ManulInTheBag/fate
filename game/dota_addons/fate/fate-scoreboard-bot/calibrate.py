r"""Calibration / offline test tool.

Usage:
    python calibrate.py path\to\scoreboard.png

It runs the full OCR pipeline on a local image (no Discord needed), prints the
parsed table to the console, and writes an overlay PNG into data\debug\ showing
exactly which boxes were read. If the boxes don't line up with the columns/rows,
adjust COLUMNS / ROWS in config.py and re-run.
"""

import os
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

import config
import ocr
import parser as score_parser
import db


def main():
    if len(sys.argv) < 2:
        print("Usage: python calibrate.py <image_path>")
        raise SystemExit(1)
    path = sys.argv[1]
    if not os.path.exists(path):
        raise SystemExit(f"No such file: {path}")

    with open(path, "rb") as f:
        data = f.read()

    name = os.path.splitext(os.path.basename(path))[0] + "_overlay.png"
    extracted = ocr.extract(data, debug_name=name)
    print(f"\nDetected rows: {extracted['n_rows']}  "
          f"(team size {extracted.get('split')} per side)")
    print(f"Scores: top={extracted['score_top']} bottom={extracted['score_bottom']}\n")

    print("Raw OCR per row:")
    for i, r in enumerate(extracted["rows"], 1):
        print(f" {i:>2}. player={r['player_raw']!r:24} hero={r['hero_raw']!r:24} "
              f"K={r['kills']} D={r['deaths']} A={r['assists']} gold={r['gold']}")

    db.init_db()
    match = score_parser.build_match(extracted, db.get_roster())
    print("\nAfter fuzzy-matching:\n")
    print(score_parser.format_table(match))

    overlay = os.path.join(config.DEBUG_DIR, name)
    print(f"\nOverlay image written to: {overlay}")
    print("Open it and check the colored boxes sit on the right columns/rows.")


if __name__ == "__main__":
    main()
