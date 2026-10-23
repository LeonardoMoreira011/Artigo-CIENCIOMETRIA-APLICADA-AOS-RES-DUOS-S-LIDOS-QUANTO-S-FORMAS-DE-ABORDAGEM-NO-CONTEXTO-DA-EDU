// Teste no navegador (Playwright). Rode com o app aberto: node caixas_moveis.js <pasta para as imagens>
// Precisa de: npm i playwright   e   npx playwright install chromium.   CINABRO_URL muda o endereço (padrão http://127.0.0.1:8421/).
const { chromium } = require('playwright');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
const DADOS = process.env.CINABRO_DADOS || require('path').resolve(__dirname, '..', '..', 'dados');
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await (await browser.newContext({ viewport: { width: 1500, height: 950 } })).newPage();
  page.on('pageerror', e => console.log('PAGEERROR', e.message));
  const idle = async () => { await page.waitForTimeout(500); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 90000 }); await page.waitForTimeout(500); };
  const val = id => page.$eval('#' + id, e => e.value);
  const box = id => page.$eval('.caixa-movel[data-id="' + id + '"]', e => { const r = e.getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height }; });
  await page.goto(URL); await page.waitForTimeout(2500);
  await page.selectOption('#exemplo', 'ensaio_temperatura.csv'); await page.waitForFunction(() => document.querySelector('#previa img')); await idle();
  // 1) ajuste linear pela faixa: tem que nascer uma caixa de estatística separada
  await page.click('summary:has-text("Ajuste de curva")'); await page.click('.faixa-lista >> text=Linear (reta)'); await idle(); await page.waitForTimeout(1200); await idle();
  console.log('ajuste aj1_ativo:', await page.$eval('#aj1_ativo', e => e.checked), '| caixa cx1_ativo:', await page.$eval('#cx1_ativo', e => e.checked), '| itens da caixa:', await page.$eval('#cx1_itens', e => JSON.stringify($(e).val())), '| ajustes:', await val('cx1_ajustes'));
  console.log('molduras:', await page.$$eval('.caixa-movel', els => els.map(e => e.dataset.id)));
  await page.screenshot({ path: SP + '/cx_1_ajuste.png' });
  // 2) figura
  await page.click('.faixa-btn:has-text("Figura")'); await page.waitForTimeout(600);
  await page.setInputFiles('#im1_arquivo', SP + '/logo_teste.png'); await page.waitForTimeout(1500); await idle(); await page.waitForTimeout(800);
  console.log('molduras:', await page.$$eval('.caixa-movel', els => els.map(e => e.dataset.id)));
  // 3) arrastar a figura
  let b = await box('im1'); const x0 = await val('im1_x'), y0 = await val('im1_y');
  await page.mouse.move(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.down(); await page.mouse.move(b.x + b.w / 2 - 120, b.y + b.h / 2 - 90, { steps: 8 }); await page.mouse.up();
  await idle(); await page.waitForTimeout(800); await idle();
  console.log('figura x,y antes', x0, y0, '-> depois', await val('im1_x'), await val('im1_y'));
  // 4) redimensionar a figura
  b = await box('im1'); const l0 = await val('im1_largura');
  await page.mouse.move(b.x + b.w / 2, b.y + b.h / 2); const hx = b.x + b.w, hy = b.y + b.h;
  await page.mouse.move(hx, hy); await page.mouse.down(); await page.mouse.move(hx + 70, hy + 40, { steps: 8 }); await page.mouse.up();
  await idle(); await page.waitForTimeout(800); await idle();
  console.log('figura largura antes', l0 || '(vazio)', '-> depois', await val('im1_largura'));
  // 5) mover e esticar a caixa de estatística
  b = await box('cx1'); const cx0 = await val('cx1_x'), cy0 = await val('cx1_y');
  await page.mouse.move(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.down(); await page.mouse.move(b.x + b.w / 2 + 60, b.y + b.h / 2 + 140, { steps: 8 }); await page.mouse.up();
  await idle(); await page.waitForTimeout(800); await idle();
  console.log('caixa x,y antes', cx0, cy0, '-> depois', await val('cx1_x'), await val('cx1_y'));
  b = await box('cx1'); const t0 = await val('cx1_tamanho_pt');
  await page.mouse.move(b.x + 5, b.y + 5); await page.mouse.move(b.x + b.w, b.y + b.h); await page.mouse.down(); await page.mouse.move(b.x + b.w + 50, b.y + b.h + 30, { steps: 8 }); await page.mouse.up();
  await idle(); await page.waitForTimeout(800); await idle();
  console.log('caixa tamanho_pt antes', t0 || '(vazio)', '-> depois', await val('cx1_tamanho_pt'));
  // 6) clique = edição rápida
  b = await box('cx1'); await page.mouse.click(b.x + b.w / 2, b.y + b.h / 2); await page.waitForTimeout(500);
  console.log('popover aberto:', await page.$('#popover-edicao') !== null, '| campos no popover:', await page.$$eval('#popover-edicao .campo', els => els.length));
  await page.screenshot({ path: SP + '/cx_2_final.png' });
  await browser.close();
})();
