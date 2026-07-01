import sys, cv2, numpy as np, ocr, easyocr_backend as eb
img = ocr.load_bgr(open(sys.argv[1],"rb").read())
rows, cols = ocr.detect_rows(img)
pitch = float(np.median([b[0]-a[0] for a,b in zip(rows,rows[1:])]))
i = int(sys.argv[2])
cy = rows[i][0]
h,w = img.shape[:2]
# full name region
ry0, ry1 = cy-0.52*pitch, cy+0.52*pitch
reg = ocr._crop_frac(img, *cols["name"], ry0, ry1)
cv2.imwrite("data/debug/dbg_region.png", cv2.resize(reg, None, fx=4, fy=4))
gray = cv2.cvtColor(reg, cv2.COLOR_BGR2GRAY)
prof110 = (gray>110).mean(axis=1)
prof180 = (gray>180).mean(axis=1)
print("rh", gray.shape[0], "name_col", cols["name"])
for j in range(gray.shape[0]):
    bar110 = "#"*int(prof110[j]*40); bar180="*"*int(prof180[j]*40)
    print(f"{j:2d} {prof110[j]:.2f} {prof180[j]:.2f} |{bar110:<40}|{bar180}")
print("bands:", ocr._name_line_bands(img, cols["name"], cy, pitch))
# EasyOCR boxes on the region (en+ru and ch_sim)
up = cv2.resize(reg, None, fx=3, fy=3, interpolation=cv2.INTER_CUBIC)
for langs in [("en","ru"),("ch_sim","en")]:
    print(f"--- readtext {langs} ---")
    for bb,t,c in eb._reader(langs).readtext(up, detail=1, paragraph=False):
        ys=[p[1] for p in bb]; print(f"  y={min(ys)/up.shape[0]:.2f}-{max(ys)/up.shape[0]:.2f} c={c:.2f} {t!r}")
