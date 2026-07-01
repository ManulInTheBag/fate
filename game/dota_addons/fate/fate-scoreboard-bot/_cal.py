import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from rapidfuzz import process, fuzz
import roster
R = roster.PLAYERS

_FOLD = str.maketrans({"1":"i","l":"i","|":"i","!":"i","0":"o"})
def key_strip(s):   # punct/space strip + lower
    return "".join(c for c in s.lower() if c.isalnum())
def key_fold(s):    # + i/o confusable fold
    return "".join(c for c in s.lower().translate(_FOLD) if c.isalnum())

variants = ["MH R","CIte Iute","lantaclta","Ezic Agent","うみねこのな< -に","傑克森市場","XPlay","Snejik"]
for proc,name in [(str.lower,"lower"),(key_strip,"strip"),(key_fold,"fold")]:
    print(f"\n===== processor={name} =====")
    for v in variants:
        best = process.extractOne(v, R, scorer=fuzz.ratio, processor=proc)
        print(f"  {v!r:22} -> {best[0]!r:18} {best[1]:.0f}")

# collision check: does folding make any two DISTINCT roster names collide?
print("\n--- roster self-collisions under fold (score>=80, different names) ---")
for i,a in enumerate(R):
    for b in R[i+1:]:
        s = fuzz.ratio(key_fold(a), key_fold(b))
        if s >= 80:
            print(f"  {a!r} ~ {b!r}  {s:.0f}")
