// Teste no navegador (Playwright). Rode com o app aberto: node paineis_cartoes_abas.js <pasta para as imagens>
// Precisa de: npm i playwright   e   npx playwright install chromium.   CINABRO_URL muda o endereço (padrão http://127.0.0.1:8421/).
const { chromium } = require('playwright');
const fs = require('fs');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
const DADOS = process.env.CINABRO_DADOS || require('path').resolve(__dirname, '..', '..', 'dados');
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const ctx = await browser.newContext({ viewport: { width: 1500, height: 900 }, acceptDownloads: true });
  const page = await ctx.newPage();
  page.on('pageerror', e => console.log('PAGEERROR', e.message));
  const idle = async () => { await page.waitForTimeout(500); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 90000 }); await page.waitForTimeout(500); };
  await page.goto(URL); await page.waitForTimeout(2500);
  console.log('altura do cabeçalho (px):', await page.$eval('.topo', e => Math.round(e.getBoundingClientRect().height)), '| abas:', await page.$eval('.abas-barra', e => Math.round(e.getBoundingClientRect().height)));
  console.log('botões do trilho:', await page.$$eval('.trilho-btn', b => b.map(x => x.title)));
  await page.selectOption('#exemplo', 'ensaio_temperatura.csv'); await page.waitForFunction(() => document.querySelector('#previa img')); await idle();
  await page.screenshot({ path: SP + '/p2_1_dados.png' });
  await page.click('.trilho-btn[data-painel="eixos"]'); await page.waitForTimeout(500);
  console.log('seções do painel Eixos (aberta?):', await page.$$eval('#painel-eixos details.secao', s => s.map(x => x.dataset.bloco + ':' + (x.open ? 'aberta' : 'recolhida'))));
  await page.screenshot({ path: SP + '/p2_2_eixos.png' });
  await page.click('#bloco-quebra > summary'); await page.waitForTimeout(300); await page.check('#quebra_ativar'); await idle(); await page.waitForTimeout(500);
  console.log('quebra ligada -> selo "ligado":', await page.$eval('#bloco-quebra', e => e.classList.contains('ligado')));
  await page.uncheck('#quebra_ativar'); await idle();
  // cartão pela faixa, valor, aba nova e volta
  await page.click('summary:has-text("Ajuste de curva")'); await page.click('.faixa-lista >> text=Linear (reta)'); await idle(); await page.waitForTimeout(800);
  console.log('painel aberto depois do clique rápido:', await page.$eval('.painel.ativo', e => e.id), '| cartões criados:', await page.$$eval('.slot-cartoes .grupo', g => g.length));
  await page.selectOption('#aj1_tipo', 'polinomial'); await page.fill('#aj1_grau', '3'); await idle();
  await page.click('.aba-acao:has-text("+ Nova aba")'); await idle(); await page.waitForTimeout(2200);
  console.log('aba nova: aj1_ativo =', await page.$eval('#aj1_ativo', e => e.checked));
  await page.click('.aba >> nth=0'); await page.waitForFunction(() => document.querySelector('#previa img')); await page.waitForTimeout(3500); await idle();
  console.log('volta à aba 1: aj1_ativo =', await page.$eval('#aj1_ativo', e => e.checked), '| tipo =', await page.$eval('#aj1_tipo', e => e.value), '| grau =', await page.$eval('#aj1_grau', e => e.value));
  // salvar configuração, abrir página nova (outra sessão) e carregar
  await page.evaluate(() => { document.querySelector('details.mais-cartao').open = true; });
  const [dl] = await Promise.all([page.waitForEvent('download'), page.click('#salvar_cfg')]); const arq = SP + '/cfg_teste.json'; await dl.saveAs(arq);
  const j = JSON.parse(fs.readFileSync(arq, 'utf8')); console.log('JSON guarda aj1_tipo =', j.valores.aj1_tipo, '| aj1_ativo =', j.valores.aj1_ativo);
  const p2 = await ctx.newPage(); p2.on('pageerror', e => console.log('PAGEERROR2', e.message));
  await p2.goto(URL); await p2.waitForTimeout(2500);
  console.log('página nova: cartões antes:', await p2.$$eval('.slot-cartoes .grupo', g => g.length));
  await p2.evaluate(() => { document.querySelector('details.mais-cartao').open = true; });
  await p2.setInputFiles('#carregar_cfg', arq); await p2.waitForTimeout(3500);
  console.log('após carregar: cartões:', await p2.$$eval('.slot-cartoes .grupo', g => g.length), '| aj1_ativo =', await p2.$eval('#aj1_ativo', e => e.checked).catch(() => 'sem campo'), '| tipo =', await p2.$eval('#aj1_tipo', e => e.value).catch(() => '-'), '| grau =', await p2.$eval('#aj1_grau', e => e.value).catch(() => '-'));
  await page.bringToFront(); await page.click('.trilho-btn[data-painel="analise"]'); await page.waitForTimeout(500);
  await page.screenshot({ path: SP + '/p2_3_analise.png' });
  await browser.close();
})();
