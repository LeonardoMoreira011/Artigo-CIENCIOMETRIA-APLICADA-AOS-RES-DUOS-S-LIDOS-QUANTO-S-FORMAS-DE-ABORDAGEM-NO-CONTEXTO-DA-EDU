# Demo Cinabro — ativos de personal care (dados fictícios)

| Pasta / arquivo | O que é |
|---|---|
| `ROTEIRO_APRESENTACAO.md` | Roteiro de ≈ 12 min, ato a ato, com o que clicar no app |
| `dados/` | 9 planilhas CSV fictícias (uma por gráfico) |
| `projetos/` | 9 arquivos `.cinabro`: no app, **Abrir projeto** carrega dados + configuração |
| `imagens/` | Um PNG (200 dpi) por gráfico |
| `dashboard_pt.html` | Dashboard final (abre em qualquer navegador) |
| `dashboard_pt_editavel.html` | O mesmo, no editor |
| `dashboard_pt.pdf` | PDF de 2 páginas A4 |
| `dados_ficticios.R` · `gerar_demo.R` | Scripts que recriam tudo (precisam da pasta `graficos_R` ao lado) |

Para refazer: `Rscript dados_ficticios.R` e depois `Rscript gerar_demo.R`.
