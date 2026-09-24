"""Поставить / снять отрисовку зон попадания в аддоне.

  python zone_debug.py on  <host.lua> <filter> [--skip a,b] [--min 150] [--time 3]
  python zone_debug.py off
  python zone_debug.py status

<host.lua> — путь относительно scripts/vscripts, КУДА дописать подключение.
Брать общий модуль Слуги (abilities/barghest/barghest_shared.lua): он грузится
раньше способностей и в нём определены хелперы, которые оборачивают адаптеры.
Нет общего модуля — любой файл способности Слуги.

⚠️ НЕ addon_game_mode.lua: он падает на последней строке (6144), и дописанное
после неё никогда не выполнится.

Что делает `on`: копирует zone_debug.lua в vscripts/zz_zone_debug.lua и
дописывает в конец host одну строку с маркером ZT_DEBUG (только в tools-режиме).
`off` убирает строку из ЛЮБОГО файла vscripts, где найдёт маркер, и удаляет
zz_zone_debug.lua. Файл host правится байтами: CRLF/LF и кодировка не трогаются.
После on/off — `script_reload` в VConsole.
"""
import argparse
import shutil
import sys
from pathlib import Path

ADDON = Path(r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota_addons\fate")
VS = ADDON / "scripts" / "vscripts"
DST = VS / "zz_zone_debug.lua"
SRC = Path(__file__).with_name("zone_debug.lua")
MARK = b"-- ZT_DEBUG"

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def lua_str_list(items):
    return "{" + ", ".join('"%s"' % s for s in items) + "}"


def hosts():
    return [p for p in VS.rglob("*.lua") if MARK in p.read_bytes()]


def off():
    n = 0
    for p in hosts():
        b = p.read_bytes()
        out = b"".join(l for l in b.splitlines(keepends=True) if MARK not in l)
        p.write_bytes(out)
        print("убрано из", p.relative_to(VS))
        n += 1
    if DST.exists():
        DST.unlink()
        print("удалён", DST.name)
    if not n:
        print("строк подключения не найдено")


def on(a):
    host = VS / a.host
    if not host.exists():
        sys.exit(f"нет файла {host}")
    if hosts():
        off()
    shutil.copyfile(SRC, DST)
    b = host.read_bytes()
    eol = b"\r\n" if b"\r\n" in b else b"\n"
    skip = [s for s in (a.skip or "").split(",") if s]
    line = (f"if IsInToolsMode and IsInToolsMode() then ZT_FILTER = \"{a.filter}\"; "
            f"ZT_SKIP = {lua_str_list(skip)}; ZT_MIN = {a.min}; ZT_TIME = {a.time}; "
            f"require('zz_zone_debug') end ").encode() + MARK
    if not b.endswith(b"\n"):
        b += eol
    host.write_bytes(b + line + eol)
    print("подключено в", host.relative_to(VS))
    print("теперь script_reload в VConsole; проверка: console_log.py tail --grep ZT")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    o = sub.add_parser("on")
    o.add_argument("host"); o.add_argument("filter")
    o.add_argument("--skip"); o.add_argument("--min", type=int, default=150)
    o.add_argument("--time", type=float, default=3.0)
    sub.add_parser("off"); sub.add_parser("status")
    a = ap.parse_args()
    if a.cmd == "on":
        on(a)
    elif a.cmd == "off":
        off()
    else:
        hs = hosts()
        print("включено в: " + ", ".join(str(h.relative_to(VS)) for h in hs) if hs else "выключено")
        print("zz_zone_debug.lua:", "есть" if DST.exists() else "нет")


if __name__ == "__main__":
    main()
