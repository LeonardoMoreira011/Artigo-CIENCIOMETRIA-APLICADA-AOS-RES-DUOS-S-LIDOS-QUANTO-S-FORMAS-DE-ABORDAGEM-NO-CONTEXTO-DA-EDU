// Prints do manual, parte 7: Dashboard (botão na faixa, janela de escolha, editor com um bloco selecionado e a folha pronta).
// Precisa do app aberto (CINABRO_URL), de Playwright e, para o PDF do dashboard, do Chromium em CINABRO_NAVEGADOR (ou Edge/Chrome do computador).
const path = require('path'); const { abrir, exemplo, IMG } = require('./comum');
(async () => {
  const { browser, ctx, page, idle } = await abrir({ largura: 1500, altura: 940 });
  const assenta = async () => { await idle(); await page.waitForTimeout(900); await idle(); };
  const escolher = async (id, termos) => { for (const t of termos) { await page.click(`#${id}-selectized`); await page.fill(`#${id}-selectized`, t); await page.waitForTimeout(250); await page.keyboard.press('Enter'); await page.waitForTimeout(150); } await page.keyboard.press('Escape'); await page.waitForTimeout(300); };
  const nomear = async n => { await page.click('.aba-acao:has-text("Renomear")'); await page.waitForSelector('#aba_nome_novo'); await page.fill('#aba_nome_novo', n); await page.click('#aba_nome_ok'); await idle(); };
  const nova = async () => { await page.click('.aba-acao:has-text("+ Nova aba")'); await idle(); await page.waitForTimeout(2200); };
  // aba 1: PCA
  await exemplo(page, idle, 'ordenacao_amostras_variaveis_ambientais.csv'); await page.selectOption('#tipo_grafico', 'pca'); await assenta();
  await page.selectOption('#coluna_grupo', 'Local'); await idle();
  await escolher('multi_variaveis', ['Aquila', 'Boreus', 'Caelum', 'Draco', 'Eridanus', 'Fornax', 'Grus', 'Hydra']); await escolher('multi_ambientais', ['pH', 'Temperatura', 'Salinidade']); await assenta();
  await page.selectOption('#multi_elipses', 'dados'); await assenta(); await nomear('PCA das espécies');
  await nova(); await exemplo(page, idle, 'mapa_mundo_vendas.csv'); await page.selectOption('#tipo_grafico', 'mapa_mundo'); await assenta(); await nomear('Vendas por país');
  await nova(); await exemplo(page, idle, 'resistencia_materiais.csv'); await page.selectOption('#tipo_grafico', 'barras'); await assenta(); await nomear('Resistência dos materiais');
  await nova(); await exemplo(page, idle, 'ensaio_temperatura.csv'); await assenta(); await nomear('Ensaio de temperatura');
  await page.screenshot({ path: IMG + '/32_dashboard_botao.png', clip: { x: 0, y: 150, width: 1500, height: 130 } });
  await page.click('#abrir_dashboard'); await page.waitForSelector('#dash_montar'); await page.waitForTimeout(700);
  await page.screenshot({ path: IMG + '/33_dashboard_janela.png', clip: await page.$eval('.modal-content', e => { const r = e.getBoundingClientRect(); return { x: r.x - 8, y: r.y - 8, width: r.width + 16, height: r.height + 16 }; }) });
  await page.click('#dash_montar'); await page.waitForSelector('#dash-overlay iframe', { timeout: 180000 });
  const f = page.frames().find(x => x.url().includes('/painel/dash_')); await f.waitForSelector('.folha', { timeout: 60000 }); await page.waitForTimeout(1800);
  // seleciona o gráfico do mapa e mostra a guia de alinhamento ao arrastar um pouco
  const id = await f.evaluate(() => window.__dash.estado.paginas[0].blocos.filter(b => b.tipo === 'grafico')[1].id);
  const r = await f.$eval('.bk[data-id="' + id + '"]', e => { const q = e.getBoundingClientRect(); return { x: q.left + q.width / 2, y: q.top + q.height / 2 }; });
  await page.mouse.click(r.x, r.y); await page.waitForTimeout(400);
  await page.screenshot({ path: IMG + '/34_dashboard_editor.png' });
  // a folha pronta (HTML final, só leitura)
  const [dl] = await Promise.all([page.waitForEvent('download'), f.click('#bt-html')]);
  const arq = path.join(require('os').tmpdir(), 'dash_manual.html'); await dl.saveAs(arq);
  const fin = await ctx.newPage(); await fin.setViewportSize({ width: 1300, height: 940 }); await fin.goto('file://' + arq); await fin.waitForTimeout(1500);
  await (await fin.$('.folha')).screenshot({ path: IMG + '/35_dashboard_folha.png' });
  await browser.close(); console.log('prints do Dashboard gerados em', IMG);
})();
