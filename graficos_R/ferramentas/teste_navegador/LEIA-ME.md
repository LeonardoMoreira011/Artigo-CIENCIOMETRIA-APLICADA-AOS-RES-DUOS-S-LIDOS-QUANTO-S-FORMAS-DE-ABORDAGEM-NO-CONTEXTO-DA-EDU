# Testes no navegador (o que os testes em R não enxergam)

Os testes `06_testes.R` e `app_shiny/testes_app.R` só rodam R: **não pegam erro no JavaScript do app** (um erro de JS em `www/app.js` já deixou o trilho e as caixas móveis sem resposta e passou despercebido).
Estes três roteiros abrem o app de verdade num Chromium controlado e conferem o que aparece e o que acontece ao clicar.

1. Abra o app (por exemplo `abrir_app.bat`, ou `shiny::runApp("app_shiny", port = 8421)`).
2. Uma vez: `npm i playwright` e `npx playwright install chromium`.
3. `node caixas_moveis.js <pasta>` — faz um ajuste pela faixa (nasce a caixa de estatística), anexa uma figura, arrasta e estica as molduras, clica para editar.
   `node paineis_cartoes_abas.js <pasta>` — 7 painéis, seções recolhidas, selo "ligado", cartões sob demanda, troca de aba, salvar e carregar configuração.
   `node grande_sair.js <pasta>` — CSV de 50 mil linhas (gere `grande.csv` na pasta), prévia reduzida, valor absurdo num campo e botão Sair.
`caixas_moveis.js` precisa de um `logo_teste.png` (qualquer PNG) na pasta; `grande_sair.js`, de um `grande.csv`. Eles imprimem o que mediram; um erro de página aparece como `PAGEERROR`.
