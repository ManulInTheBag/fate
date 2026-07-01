import sys, cv2, numpy as np, ocr, easyocr_backend as eb
f = sys.argv[1]
img = ocr.load_bgr(open(f"data/debug/{f}.png","rb").read())
rows, cols = ocr.detect_rows(img)
pitch = float(np.median([b[0]-a[0] for a,b in zip(rows,rows[1:])]))
def rd(im):
    res = eb._reader(("en","ru")).readtext(im, detail=1, paragraph=False)
    res.sort(key=lambda r:(round(r[0][0][1],-1), r[0][0][0]))
    return " ".join(t for _,t,_ in res)
for i,(cy,*_) in enumerate(rows):
    reg = ocr._crop_frac(img, *cols["name"], cy-0.5*pitch, cy+0.5*pitch)
    up = cv2.resize(reg, None, fx=4, fy=4, interpolation=cv2.INTER_CUBIC)
    g = cv2.cvtColor(cv2.resize(reg,None,fx=4,fy=4,interpolation=cv2.INTER_CUBIC), cv2.COLOR_BGR2GRAY)
    _,th = cv2.threshold(g,0,255,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    print(f"{i+1:2} cubic={rd(up)!r:30} otsu={rd(cv2.cvtColor(th,cv2.COLOR_GRAY2BGR))!r}")
