"""Чтение console.log Доты (игра запущена с -condebug).

  python console_log.py tail [-n 30] [--grep REGEX]
      последние строки (по умолчанию без шума «Failed loading resource»)
  python console_log.py wait REGEX [--timeout 120]
      ждать появления строки ПОСЛЕ момента запуска (код 0 — дождались, 1 — нет)
  python console_log.py reload
      когда была последняя перезагрузка VM и какие ошибки после неё
  python console_log.py errors [-n 20]
      Script Runtime Error / not found / rror по аддону после последней перезагрузки

Известный безвредный шум: `addon_game_mode.lua:6144 attempt to concatenate
local 'err'` — падает на каждой перезагрузке, давно.
"""
import argparse
import re
import sys
import time
from pathlib import Path

LOG = Path(r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\console.log")
NOISE = re.compile(r"Failed loading resource|GCClient|SteamNetSockets|Localization System")
KNOWN = re.compile(r"addon_game_mode\.lua:6144|Error running script named addon_game_mode")

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def lines():
    return LOG.read_text(encoding="utf-8", errors="replace").splitlines()


def after_last_reload(ls):
    idx = max((i for i, l in enumerate(ls) if "Initializing script VM" in l), default=0)
    return idx, ls[idx:]


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("tail"); t.add_argument("-n", type=int, default=30); t.add_argument("--grep")
    w = sub.add_parser("wait"); w.add_argument("regex"); w.add_argument("--timeout", type=float, default=120)
    sub.add_parser("reload")
    e = sub.add_parser("errors"); e.add_argument("-n", type=int, default=20)
    a = ap.parse_args()

    if a.cmd == "tail":
        ls = [l for l in lines() if not NOISE.search(l)]
        if a.grep:
            ls = [l for l in ls if re.search(a.grep, l)]
        print("\n".join(ls[-a.n:]))
    elif a.cmd == "wait":
        start = len(lines())
        rx = re.compile(a.regex)
        end = time.time() + a.timeout
        while time.time() < end:
            ls = lines()
            for l in ls[start:]:
                if rx.search(l):
                    print(l)
                    return 0
            time.sleep(1)
        print(f"не дождались /{a.regex}/ за {a.timeout:.0f} c")
        return 1
    elif a.cmd == "reload":
        ls = lines()
        idx, tail = after_last_reload(ls)
        print(ls[idx] if ls else "лог пуст")
        errs = [l for l in tail if re.search(r"Runtime Error|not found!|rror", l) and not KNOWN.search(l)
                and not NOISE.search(l)]
        print(f"ошибок после перезагрузки: {len(errs)}")
        print("\n".join(errs[-15:]))
    elif a.cmd == "errors":
        _, tail = after_last_reload(lines())
        errs = [l for l in tail if re.search(r"Runtime Error|not found!|stack traceback|\.lua:\d+", l)
                and not KNOWN.search(l) and "[ZT]" not in l]
        print("\n".join(errs[-a.n:]) or "ошибок нет")
    return 0


if __name__ == "__main__":
    sys.exit(main())
