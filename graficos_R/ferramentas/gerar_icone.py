#!/usr/bin/env python3
"""Gera o ícone do atalho (app_shiny/www/icone.ico e icone_512.png): o emblema sobre fundo CREME (não transparente).
uso: python3 ferramentas/gerar_icone.py      (precisa de Pillow)"""
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
CREME = (0xF5, 0xEB, 0xDD, 255)          # #F5EBDD, o fundo da interface
MARGEM = 0.07                            # respiro em volta do emblema

emb = Image.open(RAIZ / "identidade" / "emblema_1024.png").convert("RGBA")
def montar(lado):
    base = Image.new("RGBA", (lado, lado), CREME)
    miolo = round(lado * (1 - 2 * MARGEM))
    e = emb.resize((miolo, miolo), Image.LANCZOS)
    base.alpha_composite(e, ((lado - miolo) // 2, (lado - miolo) // 2))
    return base

www = RAIZ / "app_shiny" / "www"
montar(512).save(www / "icone_512.png")
tamanhos = [16, 24, 32, 48, 64, 128, 256]
montar(256).save(www / "icone.ico", format="ICO", sizes=[(t, t) for t in tamanhos])   # o Windows escolhe o tamanho certo
print("ok:", www / "icone.ico", www / "icone_512.png")
