# -*- coding: utf-8 -*-
"""Generate empty-model stubs for stock wearable vmdl_c of fate's override base heroes.

Usage: python gen_stubs.py [--write]   (default = dry run)
"""
import os, re, struct, sys, shutil, zlib
from collections import defaultdict

ADDON = r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota_addons\fate"
VPK = r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\pak01_dir.vpk"
STUB_SRC = os.path.join(ADDON, r"models\heroes\centaur\armor_sleek_1\armor_sleek_1.vmdl_c")

# stock dir names (models/heroes/X and models/items/X) per fate override base hero
HERO_DIRS = {
    'heroes': [
        'abaddon','axe','beastmaster','blood_seeker','bounty_hunter','centaur','chen','clinkz',
        'crystal_maiden','crystal_maiden_persona','dark_willow','doom','drow','ember_spirit',
        'enchantress','faceless_void','gyro','huskar','juggernaut','legion_commander','lina',
        'magnataur','mirana','mirana_persona','monkey_king','siren','nevermore','shadow_fiend',
        'nightstalker','ogre_magi','omniknight','phantom_assassin','phantom_assassin_persona',
        'phantom_lancer','phoenix','puck','queenofpain','razor','rikimaru','shadowshaman',
        'wraith_king','skywrath_mage','sniper','spectre','spirit_breaker','sven','lanaya',
        'terrorblade','tidehunter','tiny','tiny_01','tiny_02','tiny_03','tiny_04',
        'treant_protector','troll_warlord','ursa','vengeful','venomancer','windrunner',
    ],
    'items': [
        'abaddon','axe','beastmaster','blood_seeker','bounty_hunter','centaur','chen','clinkz',
        'crystal_maiden','dark_willow','doom','drow','ember_spirit','enchantress','faceless_void',
        'gyrocopter','huskar','juggernaut','legion_commander','lina','magnataur','mirana',
        'mirana_persona','monkey_king','siren','nevermore','shadow_fiend','nightstalker',
        'ogre_magi','omniknight','phantom_assassin','phantom_lancer','phoenix','puck',
        'queenofpain','razor','rikimaru','shadowshaman','skeleton_king','wraith_king',
        'skywrath_mage','sniper','spectre','spirit_breaker','sven','lanaya','templar_assassin',
        'terrorblade','tidehunter','tiny','tiny_01','tiny_02','tiny_03','tiny_04','treant',
        'troll_warlord','ursa','vengeful','vengefulspirit','venomancer','windrunner',
    ],
}

def read_cstr(buf, off):
    end = buf.index(b'\x00', off)
    return buf[off:end].decode('utf-8', 'replace'), end + 1

def parse_vpk(path):
    data = open(path, 'rb').read()
    sig, ver = struct.unpack_from('<II', data, 0)
    off = 28 if ver == 2 else 12
    out = set()
    while True:
        ext, off = read_cstr(data, off)
        if not ext:
            break
        while True:
            folder, off = read_cstr(data, off)
            if not folder:
                break
            while True:
                name, off = read_cstr(data, off)
                if not name:
                    break
                _, preload = struct.unpack_from('<IH', data, off)
                off += 18 + preload
                out.add(f"{folder}/{name}.{ext}")
    return out

def main():
    write = '--write' in sys.argv
    stock = parse_vpk(VPK)

    # protected: stock model paths the addon references on purpose (attach props etc.)
    refs = set()
    pat = re.compile(r'models/(?:heroes|items)/[A-Za-z0-9_/\.]+?\.vmdl', re.I)
    for r, _, files in os.walk(os.path.join(ADDON, 'scripts')):
        for f in files:
            if f.lower().endswith(('.lua', '.kv', '.txt')):
                try:
                    txt = open(os.path.join(r, f), encoding='utf-8', errors='replace').read()
                except OSError:
                    continue
                for m in pat.findall(txt):
                    refs.add(m.lower())
    print(f"protected script-referenced models: {len(refs)}")

    # also protect models embedded in the addon's own compiled particles
    bpat = re.compile(rb'models/(?:heroes|items)/[a-z0-9_/\.]+?\.vmdl', re.I)
    nref = 0
    for r, _, files in os.walk(os.path.join(ADDON, 'particles')):
        for f in files:
            if f.lower().endswith('.vpcf_c'):
                blob = open(os.path.join(r, f), 'rb').read()
                for m in bpat.findall(blob):
                    s = m.decode().lower()
                    if s not in refs:
                        refs.add(s)
                        nref += 1
    print(f"protected addon-particle-referenced models: +{nref}")

    # existing addon files (lowercased)
    existing = set()
    for r, _, files in os.walk(os.path.join(ADDON, 'models')):
        for f in files:
            rel = os.path.relpath(os.path.join(r, f), ADDON).replace(os.sep, '/').lower()
            existing.add(rel)

    wanted_prefixes = tuple(
        f"models/{kind}/{d}/" for kind, dirs in HERO_DIRS.items() for d in dirs
    )

    todo, skipped_ref, skipped_exist = [], [], 0
    for p in stock:
        pl = p.lower()
        if not pl.endswith('.vmdl_c') or not pl.startswith(wanted_prefixes):
            continue
        if pl in existing:
            skipped_exist += 1
            continue
        if pl[:-2] in refs:  # .vmdl_c -> .vmdl
            skipped_ref.append(pl)
            continue
        todo.append(pl)

    stub = open(STUB_SRC, 'rb').read()
    print(f"stub source: {len(stub)} bytes, crc {zlib.crc32(stub):08x}")
    print(f"already stubbed/present: {skipped_exist}")
    print(f"PROTECTED (skipped, used by scripts): {len(skipped_ref)}")
    for s in sorted(skipped_ref):
        print("   KEEP", s)
    per = defaultdict(int)
    for t in todo:
        per['/'.join(t.split('/')[1:3])] += 1
    print(f"TO CREATE: {len(todo)} stubs, {len(todo)*len(stub)/1e6:.1f} MB")
    for k in sorted(per):
        print(f"   {k}: {per[k]}")

    if write:
        for t in todo:
            dst = os.path.join(ADDON, t.replace('/', os.sep))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, 'wb') as fh:
                fh.write(stub)
        print("WRITTEN.")
    else:
        print("(dry run — pass --write to create)")

if __name__ == '__main__':
    main()
