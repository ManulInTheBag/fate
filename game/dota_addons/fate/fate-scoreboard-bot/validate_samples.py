"""Run the OCR pipeline over a folder of saved scoreboard screenshots and report
how each one parsed. Use it to spot-check accuracy and measure speed (e.g. after
the GPU switch) against real boards downloaded with fetch_samples.py.

Usage (from the bot folder, with the venv python):
    python validate_samples.py                 # over data/samples
    python validate_samples.py tests/shots      # a different folder
    python validate_samples.py --debug          # also write box overlays to data/debug

For each image it prints: valid?, rows found, team scores, and parse time. At the
end it summarizes how many parsed as valid scoreboards and the timing. It does
NOT touch the stats DB — purely read-only OCR.
"""

import os
import sys
import time

import config
import ocr
import parser as score_parser

DEFAULT_DIR = os.path.join(os.path.dirname(__file__), "data", "samples")
IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".bmp")


def main():
    args = sys.argv[1:]
    debug = "--debug" in args
    args = [a for a in args if a != "--debug"]
    folder = args[0] if args else DEFAULT_DIR

    if not os.path.isdir(folder):
        raise SystemExit(f"Folder not found: {folder}")
    files = sorted(f for f in os.listdir(folder)
                   if f.lower().endswith(IMAGE_EXT))
    if not files:
        raise SystemExit(f"No images in {folder}")

    print(f"OCR engine: {config.OCR_ENGINE}", end="")
    if config.OCR_ENGINE == "easyocr":
        try:
            import easyocr_backend
            print(f"  ·  GPU: {easyocr_backend._use_gpu()}", end="")
            print("  (warming up readers…)")
            t = time.time()
            easyocr_backend.warmup()
            print(f"  readers loaded in {time.time() - t:.1f}s")
        except Exception as e:
            print(f"  (warmup failed: {e})")
    else:
        print()

    print(f"\nValidating {len(files)} image(s) in {folder}\n")
    print(f"{'#':>3}  {'valid':<5}  {'rows':>4}  {'score':>9}  {'sec':>5}  file")
    print("-" * 78)

    valid_n = 0
    times = []
    for i, fn in enumerate(files, 1):
        path = os.path.join(folder, fn)
        with open(path, "rb") as f:
            data = f.read()
        t = time.time()
        try:
            ext = ocr.extract(data, debug_name=(fn + ".png") if debug else None)
            dt = time.time() - t
            times.append(dt)
            match = score_parser.build_match(ext, [])
            ok = "yes" if match["valid"] else "NO"
            valid_n += match["valid"]
            score = f"{ext['score_top']}-{ext['score_bottom']}"
            reason = "" if match["valid"] else f"  ({match['reason']})"
            print(f"{i:>3}  {ok:<5}  {ext['n_rows']:>4}  {score:>9}  "
                  f"{dt:>5.2f}  {fn}{reason}")
        except Exception as e:
            dt = time.time() - t
            print(f"{i:>3}  {'ERR':<5}  {'-':>4}  {'-':>9}  {dt:>5.2f}  {fn}  ({e})")

    print("-" * 78)
    n = len(files)
    avg = sum(times) / len(times) if times else 0.0
    print(f"\nValid scoreboards: {valid_n}/{n} ({100 * valid_n / n:.0f}%)")
    if times:
        print(f"Time per image: avg {avg:.2f}s  ·  min {min(times):.2f}s  ·  "
              f"max {max(times):.2f}s  ·  total {sum(times):.1f}s")


if __name__ == "__main__":
    main()
