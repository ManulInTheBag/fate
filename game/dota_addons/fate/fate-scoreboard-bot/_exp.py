import sys, cv2, numpy as np, ocr, easyocr_backend as eb
img = ocr.load_bgr(open("data/debug/wrong3.png","rb").read())
rows, cols = ocr.detect_rows(img)
pitch = float(np.median([b[0]-a[0] for a,b in zip(rows,rows[1:])]))
cy = rows[1][0]   # row 2 = шешня
# player line is upper half of the name region
reg = ocr._crop_frac(img, *cols["name"], cy-0.5*pitch, cy+0.05*pitch)
cv2.imwrite("data/debug/exp_player.png", cv2.resize(reg, None, fx=6, fy=6, interpolation=cv2.INTER_NEAREST))
print("region", reg.shape)

def show(tag, im, langs=("en","ru"), **kw):
    res = eb._reader(langs).readtext(im, detail=1, paragraph=False, **kw)
    res.sort(key=lambda r: r[0][0][0])
    txt = " ".join(t for _,t,_ in res)
    cf = np.mean([c for *_,c in res]) if res else 0
    print(f"{tag:28} {txt!r:20} c={cf:.2f}")

gray = cv2.cvtColor(reg, cv2.COLOR_BGR2GRAY)
for fx in (3,5,8):
    up = cv2.resize(reg, None, fx=fx, fy=fx, interpolation=cv2.INTER_CUBIC)
    show(f"cubic x{fx}", up)
up = cv2.resize(reg, None, fx=6, fy=6, interpolation=cv2.INTER_LANCZOS4)
show("lanczos x6", up)
# sharpen
up = cv2.resize(reg, None, fx=6, fy=6, interpolation=cv2.INTER_CUBIC)
sh = cv2.filter2D(up, -1, np.array([[0,-1,0],[-1,5,-1],[0,-1,0]]))
show("cubic x6 + sharpen", sh)
# grayscale upscale + threshold
g6 = cv2.resize(gray, None, fx=6, fy=6, interpolation=cv2.INTER_CUBIC)
show("gray x6", cv2.cvtColor(g6, cv2.COLOR_GRAY2BGR))
_,th = cv2.threshold(g6,0,255,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
show("otsu x6", cv2.cvtColor(th, cv2.COLOR_GRAY2BGR))
# ru only
show("ru-only x6", cv2.resize(reg,None,fx=6,fy=6,interpolation=cv2.INTER_CUBIC), langs=("ru",))
# easyocr params
show("x6 params", cv2.resize(reg,None,fx=6,fy=6,interpolation=cv2.INTER_CUBIC),
     contrast_ths=0.05, adjust_contrast=0.7, text_threshold=0.5)
