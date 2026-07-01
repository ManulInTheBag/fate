import time, numpy as np, ocr, easyocr_backend as eb
eb.warmup()
img = ocr.load_bgr(open("data/debug/wrong1.png","rb").read())
t=time.time(); rows,cols=ocr.detect_rows(img); print(f"detect_rows: {time.time()-t:.1f}s ({len(rows)} rows)")
pitch=float(np.median([b[0]-a[0] for a,b in zip(rows,rows[1:])]))
import parser as pm
backend=eb
t=time.time()
for cy,*_ in rows:
    ocr._read_name(img, cols, cy, pitch, pm, backend)
print(f"name loop ({len(rows)} rows): {time.time()-t:.1f}s  => {(time.time()-t)/len(rows):.2f}s/row")
# single region: how many ms per readtext
reg=ocr._crop_frac(img,*cols["name"],rows[3][0]-0.5*pitch,rows[3][0]+0.5*pitch)
up=__import__("cv2").resize(reg,None,fx=3,fy=3)
for langs in [("en","ru"),("ch_sim","en")]:
    t=time.time(); eb._reader(langs).readtext(up,detail=1,paragraph=False); print(f"  one readtext {langs}: {(time.time()-t)*1000:.0f}ms")
