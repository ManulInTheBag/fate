import cv2, numpy as np, ocr, easyocr_backend as eb
img = ocr.load_bgr(open("data/debug/new1.png","rb").read())
print("img", img.shape)
rows, cols = ocr.detect_rows(img)
pitch = float(np.median([b[0]-a[0] for a,b in zip(rows,rows[1:])]))
cy = rows[1][0]
reg = ocr._crop_frac(img, *cols["name"], cy-0.5*pitch, cy-0.02*pitch)  # player line
print("player region", reg.shape)
cv2.imwrite("data/debug/exp_new1.png", cv2.resize(reg,None,fx=8,fy=8,interpolation=cv2.INTER_NEAREST))
def rd(im, langs=("en","ru")):
    res = eb._reader(langs).readtext(im, detail=1, paragraph=False)
    res.sort(key=lambda r:r[0][0][0])
    return " ".join(t for _,t,_ in res), (np.mean([c for *_,c in res]) if res else 0)
g = cv2.cvtColor(reg, cv2.COLOR_BGR2GRAY)
variants = {}
for fx in (4,6,8,10):
    variants[f"cubic{fx}"] = cv2.resize(reg,None,fx=fx,fy=fx,interpolation=cv2.INTER_CUBIC)
gg = cv2.resize(g,None,fx=8,fy=8,interpolation=cv2.INTER_CUBIC)
_,otsu = cv2.threshold(gg,0,255,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
variants["otsu8"] = cv2.cvtColor(otsu,cv2.COLOR_GRAY2BGR)
variants["otsu8_dil"] = cv2.cvtColor(cv2.erode(otsu,np.ones((2,2),np.uint8)),cv2.COLOR_GRAY2BGR)
sh = cv2.filter2D(gg,-1,np.array([[0,-1,0],[-1,5,-1],[0,-1,0]]))
variants["gray8_sharp"] = cv2.cvtColor(sh,cv2.COLOR_GRAY2BGR)
ad = cv2.adaptiveThreshold(gg,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C,cv2.THRESH_BINARY,15,5)
variants["adapt8"] = cv2.cvtColor(ad,cv2.COLOR_GRAY2BGR)
for k,v in variants.items():
    t,c = rd(v); print(f"{k:14} {t!r:24} c={c:.2f}")
