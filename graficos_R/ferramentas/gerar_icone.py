#!/usr/bin/env python3
"""Gera o ícone do atalho (app_shiny/www/icone.ico, icone_512.png e favicon.png): o emblema com PROFUNDIDADE sobre uma placa creme.
Linhas do contorno mais grossas, relevo (luz no alto à esquerda), sombra projetada do emblema e da placa.
uso: python3 ferramentas/gerar_icone.py      (precisa de Pillow e numpy)"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
L = 1024                                   # tamanho de trabalho
TINTA = (0x20, 0x24, 0x2B)                 # contorno do emblema
CREME_CLARO, CREME_ESCURO = (0xFC, 0xF6, 0xEA), (0xE9, 0xDA, 0xC2)
ESPESSURA = 9                              # px (em 1024) que o contorno engrossa
RAIO_PLACA = 0.20                          # canto arredondado da placa (fração do lado)

emb = Image.open(RAIZ / "identidade" / "emblema_1024.png").convert("RGBA").resize((L, L), Image.LANCZOS)

def mascara(a, limiar=128):                # array 0-255 -> imagem "L" binária
    return Image.fromarray(((a >= limiar) * 255).astype("uint8"), "L")

def deslocar(img, dx, dy):
    return ImageChops.offset(img, dx, dy)

def sombra(sil, desvio, raio, cor, op):
    """Sombra de uma silhueta ('L'): borrada, deslocada e colorida."""
    s = deslocar(sil, *desvio).filter(ImageFilter.GaussianBlur(raio))
    s = s.point(lambda v: int(v * op))
    cam = Image.new("RGBA", sil.size, cor + (0,)); cam.putalpha(s)
    return cam

# ---- emblema: contorno mais grosso + relevo ----------------------------------------------------------------------------------
a = np.array(emb).astype(float)
rgb, alfa = a[..., :3], a[..., 3]
lum = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
sat = rgb.max(axis=2) - rgb.min(axis=2)
tinta = (alfa > 40) & (lum < 95) & (sat < 45)                      # contorno: escuro e quase sem cor (o vermelho escuro tem cor)
cor = (alfa > 40) & ~tinta                                         # as áreas coloridas (vermelho, laranja, pontos)
m_tinta = mascara(tinta * 255)
grossa = m_tinta.filter(ImageFilter.MaxFilter(2 * ESPESSURA + 1))   # contorno engrossado
m_cor = mascara(cor * 255)
m_cor_fina = m_cor.filter(ImageFilter.MinFilter(3))                 # a cor não "come" o contorno novo
base = Image.new("RGBA", (L, L), (0, 0, 0, 0))
base.paste(Image.new("RGBA", (L, L), TINTA + (255,)), mask=grossa)
vivo = ImageEnhance.Color(emb.convert("RGB")).enhance(1.25).convert("RGBA"); vivo.putalpha(emb.getchannel("A"))     # cores mais vivas
base.paste(vivo, mask=m_cor_fina)                                   # cores por cima do contorno
# relevo: luz no alto à esquerda (borda clara) e sombra interna embaixo à direita
d = 7
luz = ImageChops.subtract(m_cor_fina, deslocar(m_cor_fina, d, d)).filter(ImageFilter.GaussianBlur(3))
esc = ImageChops.subtract(m_cor_fina, deslocar(m_cor_fina, -d, -d)).filter(ImageFilter.GaussianBlur(3))
base.alpha_composite(Image.composite(Image.new("RGBA", (L, L), (255, 255, 255, 110)), Image.new("RGBA", (L, L), (0, 0, 0, 0)), luz))
base.alpha_composite(Image.composite(Image.new("RGBA", (L, L), (0, 0, 0, 80)), Image.new("RGBA", (L, L), (0, 0, 0, 0)), esc))
silueta = Image.fromarray(np.array(base)[..., 3], "L")
silueta = silueta.point(lambda v: 255 if v > 20 else 0)

# ---- placa creme com gradiente, borda de luz e sombra --------------------------------------------------------------------------
def placa(lado):
    mg = int(lado * 0.045)
    caixa = (mg, mg, lado - mg, lado - mg - int(lado * 0.01))
    r = int((caixa[2] - caixa[0]) * RAIO_PLACA)
    forma = Image.new("L", (lado, lado), 0); ImageDraw.Draw(forma).rounded_rectangle(caixa, r, fill=255)
    yy, xx = np.mgrid[0:lado, 0:lado]
    cx, cy = lado * 0.42, lado * 0.36
    t = np.clip(np.hypot(xx - cx, yy - cy) / (lado * 0.80), 0, 1)[..., None]   # luz de cima à esquerda
    grad = (np.array(CREME_CLARO) * (1 - t) + np.array(CREME_ESCURO) * t).astype("uint8")
    fundo = Image.fromarray(np.dstack([grad, np.full((lado, lado), 255, "uint8")]), "RGBA")
    out = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    out.alpha_composite(sombra(forma, (0, int(lado * 0.022)), lado * 0.025, (60, 40, 20), 0.55))
    out.paste(fundo, mask=forma)
    # fio de luz na borda de cima e fio escuro na de baixo (relevo da placa)
    borda = ImageChops.subtract(forma, forma.filter(ImageFilter.MinFilter(5)))
    luz_b = ImageChops.multiply(borda, deslocar(ImageChops.invert(forma), 0, 3).filter(ImageFilter.GaussianBlur(1)).point(lambda v: 0)) if False else borda
    out.alpha_composite(Image.composite(Image.new("RGBA", (lado, lado), (255, 255, 255, 120)), Image.new("RGBA", (lado, lado), (0, 0, 0, 0)), luz_b))
    return out, caixa

def montar(lado):
    pl, caixa = placa(L)
    tam = caixa[2] - caixa[0]
    miolo = int(tam * 0.88)                                         # o emblema ocupa 88 % da placa
    e = base.resize((miolo, miolo), Image.LANCZOS); s = silueta.resize((miolo, miolo), Image.LANCZOS)
    x0 = caixa[0] + (tam - miolo) // 2; y0 = caixa[1] + (tam - miolo) // 2
    pos = (x0, y0)
    camada = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    sil_full = Image.new("L", (L, L), 0); sil_full.paste(s, pos)
    camada.alpha_composite(sombra(sil_full, (int(L * 0.018), int(L * 0.030)), L * 0.022, (30, 20, 15), 0.55))    # sombra longa e macia
    camada.alpha_composite(sombra(sil_full, (int(L * 0.005), int(L * 0.009)), L * 0.006, (20, 14, 10), 0.60))   # sombra de contato
    camada.alpha_composite(e, pos)
    final = pl.copy(); final.alpha_composite(camada)
    return final.resize((lado, lado), Image.LANCZOS)

www = RAIZ / "app_shiny" / "www"
montar(512).save(www / "icone_512.png")
montar(64).save(www / "favicon.png")
tamanhos = [16, 24, 32, 48, 64, 128, 256]
montar(256).save(www / "icone.ico", format="ICO", sizes=[(t, t) for t in tamanhos])   # o Windows escolhe o tamanho certo
print("ok:", www / "icone.ico", www / "icone_512.png", www / "favicon.png")
