// Teste no navegador (Playwright). Rode com o app aberto: node novos_graficos.js <pasta para as imagens>
// Mapa de calor, PCA, CA, CCA, mapa-múndi e mapa do Brasil: escolhe o tipo, marca variáveis/ambientais/grupo e confere que o gráfico sai sem erro.
const { chromium } = require('playwright');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
let falhas = 0;
const ok = (nome, cond, extra) => { console.log((cond ? 'OK   ' : 'FALHA') + ' ' + nome + (extra !== undefined ? '  [' + extra + ']' : '')); if (!cond) falhas++; };
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await (await browser.newContext({ viewport: { width: 1500, height: 950 } })).newPage();
  page.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  const idle = async () => { await page.waitForTimeout(500); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 90000 }); await page.waitForTimeout(800); };
  const assenta = async () => { await page.waitForTimeout(1500); await idle(); await page.waitForTimeout(1000); await idle(); };
  const erros = () => page.$$eval('[class*=erro]', e => e.map(x => x.textContent.trim().slice(0, 160)).filter(Boolean));
  const visivel = id => page.$eval('#' + id, e => !!(e.offsetWidth || e.offsetHeight));
  const escolher = async (id, termos) => { for (const t of termos) { await page.click(`#${id}-selectized`); await page.fill(`#${id}-selectized`, t); await page.waitForTimeout(250); await page.keyboard.press('Enter'); await page.waitForTimeout(150); } await page.keyboard.press('Escape'); await page.waitForTimeout(300); };
  const exemplo = async n => { await page.selectOption('#exemplo', n); await page.waitForFunction(() => document.querySelector('#previa img')); await idle(); };
  await page.goto(URL); await page.waitForTimeout(2500); await page.waitForSelector('#retomar_nao', { timeout: 8000 }).then(() => page.click('#retomar_nao')).catch(() => {}); await page.waitForTimeout(800);
  const foto = async n => page.screenshot({ path: SP + '/nv_' + n + '.png' });
  // PCA / CA / CCA
  await exemplo('ordenacao_amostras_variaveis_ambientais.csv');
  await page.selectOption('#tipo_grafico', 'cca'); await assenta();
  ok('CCA sem ambientais avisa em português', (await erros()).join(' ').includes('Variáveis ambientais'));
  ok('campos de ordenação aparecem só no PCA/CA/CCA', await visivel('multi_transformacao') && !(await visivel('calor_esquema')) && !(await visivel('mapa_nivel')));
  await page.selectOption('#coluna_grupo', 'Local'); await idle();
  await escolher('multi_variaveis', ['Aquila', 'Boreus', 'Caelum', 'Draco', 'Eridanus', 'Fornax', 'Grus', 'Hydra']);
  await escolher('multi_ambientais', ['pH', 'Temperatura', 'Salinidade']); await assenta();
  await page.selectOption('#multi_elipses', 'dados'); await assenta();
  ok('CCA com variáveis, ambientais e grupo monta sem erro', (await erros()).length === 0, (await erros()).join(' | '));
  await foto('cca');
  // resumo estatístico: aparece por padrão, arrasta, e pode ser desligado
  ok('o resumo estatístico aparece sozinho (caixa arrastável)', (await page.$$('.caixa-movel[data-id="multi_resumo"]')).length === 1);
  const rb = await page.$eval('.caixa-movel[data-id="multi_resumo"]', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  await page.mouse.move(rb.x, rb.y); await page.mouse.down(); await page.mouse.move(rb.x + 40, rb.y + 30, { steps: 6 }); await page.mouse.up(); await assenta();
  const rx = await page.$eval('#multi_resumo_x', e => e.value); ok('arrastar o resumo grava a posição nos campos', rx !== '' && !isNaN(parseFloat(rx)), rx);
  await page.uncheck('#multi_resumo_ativo'); await assenta();
  ok('desmarcar "Resumo estatístico no gráfico" tira a caixa', (await page.$$('.caixa-movel[data-id="multi_resumo"]')).length === 0);
  await page.check('#multi_resumo_ativo'); await page.evaluate(() => ['multi_resumo_x', 'multi_resumo_y'].forEach(id => $('#' + id).val('').trigger('input').trigger('change'))); await assenta();
  ok('ligar de novo traz a caixa de volta', (await page.$$('.caixa-movel[data-id="multi_resumo"]')).length === 1);
  // nomes arrastáveis: arrastar grava "Nome=x,y" no campo; duplo clique devolve à posição automática
  const nomes = await page.$$eval('.caixa-movel.rotulo', els => els.map(e => e.dataset.id + ':' + e.querySelector('.cm-rot').textContent));
  ok('os nomes das variáveis e ambientais ganham moldura para arrastar', nomes.length >= 8, nomes.length + ' nomes');
  const alvo = '.caixa-movel.rotulo >> nth=0'; const bx = await page.$eval('.caixa-movel.rotulo', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  await page.mouse.move(bx.x, bx.y); await page.mouse.down(); await page.mouse.move(bx.x - 60, bx.y + 50, { steps: 8 }); await page.mouse.up(); await assenta();
  const pos = await page.$eval('#multi_rotulos_posicoes', e => e.value);
  ok('arrastar um nome grava a posição no campo', /=-?[0-9.]+,-?[0-9.]+/.test(pos), pos); await foto('cca_nome_movido');
  const b2 = await page.$eval('.caixa-movel.rotulo.ativa, .caixa-movel.rotulo', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  await page.$$eval('.caixa-movel.rotulo', els => els.forEach(e => e.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }))));
  await assenta(); ok('duplo clique devolve os nomes à posição automática', (await page.$eval('#multi_rotulos_posicoes', e => e.value)) === '');
  await page.selectOption('#tipo_grafico', 'pca'); await assenta(); ok('PCA monta sem erro', (await erros()).length === 0, (await erros()).join(' | ')); await foto('pca');
  await page.selectOption('#tipo_grafico', 'ca'); await assenta(); ok('CA monta sem erro', (await erros()).length === 0, (await erros()).join(' | '));
  // mapa de calor
  await exemplo('mapa_de_calor.csv'); await page.selectOption('#tipo_grafico', 'mapa_calor'); await assenta();
  ok('mapa de calor monta sem erro e mostra os campos do gradiente', (await erros()).length === 0 && await visivel('calor_esquema') && !(await visivel('multi_transformacao')), (await erros()).join(' | '));
  await page.check('#calor_valores'); await page.selectOption('#calor_agrupar', 'ambos'); await page.selectOption('#calor_esquema', 'divergente'); await assenta();
  ok('mapa de calor com valores, agrupamento e escala divergente monta sem erro', (await erros()).length === 0, (await erros()).join(' | ')); await foto('calor');
  // mapas
  await exemplo('mapa_mundo_vendas.csv'); await page.selectOption('#tipo_grafico', 'mapa_mundo'); await assenta();
  ok('mapa-múndi monta sem erro', (await erros()).length === 0 && await visivel('mapa_projecao'), (await erros()).join(' | '));
  await page.selectOption('#mapa_nivel', 'regiao'); await page.selectOption('#mapa_rotulos', 'nome_valor'); await assenta();
  ok('mapa-múndi por região comercial com rótulos monta sem erro', (await erros()).length === 0, (await erros()).join(' | ')); await foto('mundo');
  await exemplo('mapa_brasil_estados.csv'); await page.selectOption('#tipo_grafico', 'mapa_brasil'); await page.selectOption('#mapa_nivel', 'pais'); await assenta();
  ok('mapa do Brasil monta sem erro (sem o campo de projeção)', (await erros()).length === 0 && !(await visivel('mapa_projecao')), (await erros()).join(' | ')); await foto('brasil');
  await browser.close();
  console.log(falhas ? ('==== ' + falhas + ' FALHOU ====') : '==== tudo certo ====');
  process.exit(falhas ? 1 : 0);
})();
