#!/usr/bin/env python3
"""Reduz os PNG do manual (manual/img) para uma paleta de 256 cores, sem diferença visível (PSNR acima de 40 dB), e assim o Manual_Cinabro.pdf encolhe
de ~5,7 MB para ~3 MB. Rode depois de refazer os prints e antes de gerar_pdf.js.  uso (na pasta graficos_R):  python3 ferramentas/manual/otimizar_imagens.py"""
import glob, io, math, os
import numpy as np
from PIL import Image

antes = depois = trocadas = 0
for f in sorted(glob.glob(os.path.join("manual", "img", "*.png"))):
    b0 = os.path.getsize(f); rgb = Image.open(f).convert("RGB")
    q = rgb.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    buf = io.BytesIO(); q.save(buf, "PNG", optimize=True)
    mse = ((np.asarray(rgb, dtype=float) - np.asarray(q.convert("RGB"), dtype=float)) ** 2).mean()
    psnr = 99 if mse == 0 else 10 * math.log10(255 ** 2 / mse)
    antes += b0
    if buf.tell() < 0.75 * b0 and psnr >= 40:
        open(f, "wb").write(buf.getvalue()); depois += buf.tell(); trocadas += 1
    else:
        depois += b0
print("manual/img: %.2f MB -> %.2f MB (%d imagens reduzidas)" % (antes / 1e6, depois / 1e6, trocadas))
