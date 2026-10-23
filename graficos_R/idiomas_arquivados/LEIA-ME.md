# Inglês e espanhol — arquivados (desligados)

O Cinabro é **só em português (BR)**. O que existia em inglês e espanhol ficou guardado aqui, atualizado até a última versão com os três idiomas
(incluindo os textos da curva externa, das caixas móveis e da paleta nova). **Para reativar, peça**: eu devolvo os arquivos aos lugares e religo o seletor.

| Arquivo aqui | Era usado em | O que fazia |
|---|---|---|
| `app/en.json`, `app/es.json` | `app_shiny/idiomas/` | dicionários da tela (≈ 970 textos cada) |
| `motor/02_traducoes_motor.R` | `R/` (e na lista `.MOTOR_ARQUIVOS` do `02_motor.R`) | mensagens do motor e títulos automáticos do gráfico |
| `README_EN.md`, `README_ES.md` | raiz do projeto | versões curtas do LEIAME |

## O que ficou no código, desligado (para reativar sem reescrever)
- `app_shiny/codigo/idiomas.R`: `tr()`, `trf()`, `tr_nomes()`, `traduzir_html()`, `carregar_dicionarios()` (a lista `IDIOMAS` está só com `"pt"`; a linha com os três está em comentário).
- `R/01_base.R`: `.traduzir_msg()`, `.rot()`; `.idioma()` devolve sempre `"pt"` (a versão que lia `options(cinabro.idioma)` está em comentário).
- `R/21_ajustes.R`: `.ROT_EST` ainda guarda os rótulos das estatísticas em pt, en e es.
- No servidor do app, `T()`, `TF()` e `UI()` continuam envolvendo os textos.

## Para reativar (resumo do que eu faço)
1. Devolver `app/*.json` para `app_shiny/idiomas/`, `motor/02_traducoes_motor.R` para `R/` (e para `.MOTOR_ARQUIVOS`), os READMEs para a raiz.
2. `IDIOMAS` com os três idiomas; `.idioma()` lendo a opção; o seletor de idioma no cabeçalho do `app.R` e o código dele no `app.js`; `idioma <- reactive(input$idioma_pagina %||% "pt")`.
3. Reativar os testes de idioma e rodar tudo.

Todo texto novo do app a partir de agora é escrito só em português, **sem** acrescentar linha nos `.json`; ao reativar, os textos novos precisam ser traduzidos de uma vez.
