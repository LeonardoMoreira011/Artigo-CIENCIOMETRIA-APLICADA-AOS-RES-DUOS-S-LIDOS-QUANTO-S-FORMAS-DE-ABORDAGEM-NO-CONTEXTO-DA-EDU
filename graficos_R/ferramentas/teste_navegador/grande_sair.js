// Teste no navegador (Playwright). Rode com o app aberto: node grande_sair.js <pasta para as imagens>
// Precisa de: npm i playwright   e   npx playwright install chromium.   CINABRO_URL muda o endereço (padrão http://127.0.0.1:8421/).
const { chromium } = require('playwright');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
const DADOS = process.env.CINABRO_DADOS || require('path').resolve(__dirname, '..', '..', 'dados');
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await (await browser.newContext({ viewport: { width: 1500, height: 950 } })).newPage();
  const idle = async () => { await page.waitForTimeout(400); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 120000 }); await page.waitForTimeout(400); };
  let t = Date.now(); await page.goto(URL); await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected()); console.log('abrir a página (ms):', Date.now() - t);
  t = Date.now(); await page.reload(); await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected()); console.log('recarregar a página (ms):', Date.now() - t);
  await page.waitForTimeout(1500);
  t = Date.now(); await page.setInputFiles('#arquivo', SP + '/grande.csv'); await page.waitForFunction(() => document.querySelector('#previa img'), null, { timeout: 120000 }); await idle(); console.log('CSV de 50 mil linhas -> primeiro gráfico (ms):', Date.now() - t);
  console.log('chip:', await page.$$eval('.chip-aviso', els => els.map(e => e.textContent.trim())));
  const src0 = await page.$eval('#previa img', e => e.src); t = Date.now();
  await page.evaluate(() => { const e = document.getElementById('titulo_grafico'); e.value = 'Teste'; $(e).trigger('input').trigger('change'); });
  await page.waitForFunction(s => document.querySelector('#previa img').src !== s, src0, { timeout: 120000 }); console.log('editar o título -> gráfico novo (ms):', Date.now() - t);
  // valor absurdo: 10 milhões de traços menores
  t = Date.now(); const src1 = await page.$eval('#previa img', e => e.src);
  await page.evaluate(() => { const e = document.getElementById('x_ticks_menores'); e.value = '10000000'; $(e).trigger('input').trigger('change'); });
  await page.waitForFunction(s => document.querySelector('#previa img').src !== s, src1, { timeout: 120000 }); await idle(); console.log('10 milhões de traços menores -> gráfico (ms):', Date.now() - t, '| avisos:', await page.$$eval('.aviso, .alert, .avisos li', els => els.map(e => e.textContent.trim().slice(0, 90))));
  await page.screenshot({ path: SP + '/f1_grande.png' });
  // Sair
  await page.click('#sair'); await page.waitForTimeout(2500); console.log('após Sair:', (await page.textContent('body')).trim().slice(0, 60));
  await browser.close();
})();
