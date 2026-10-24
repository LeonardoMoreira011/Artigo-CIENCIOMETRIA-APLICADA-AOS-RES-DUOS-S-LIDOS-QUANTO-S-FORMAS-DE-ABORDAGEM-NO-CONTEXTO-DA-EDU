// Print do manual, parte 6: caixas móveis (moldura sempre visível, caixa selecionada com alças, sombra ao arrastar).
const path = require('path'); const { abrir, exemplo, IMG } = require('./comum');
const LOGO = path.resolve(__dirname, '..', '..', 'app_shiny', 'www', 'icone_512.png');
(async () => {
  const { browser, page, idle } = await abrir();
  const assenta = async () => { await idle(); await page.waitForTimeout(900); await idle(); };
  await exemplo(page, idle, 'ensaio_temperatura.csv');
  await page.click('summary:has-text("Ajuste de curva")'); await page.click('.faixa-lista >> text=Linear (reta)'); await assenta();
  await page.click('.faixa-btn:has-text("Figura")'); await page.waitForTimeout(600);
  await page.setInputFiles('#im1_arquivo', LOGO); await page.waitForTimeout(1500); await assenta();
  await page.fill('#im1_largura', '0.14'); await page.dispatchEvent('#im1_largura', 'change'); await assenta();
  // seleciona a figura (um clique abre a edição rápida; Esc fecha e a seleção fica) e arrasta um pouco, para mostrar a sombra
  let b = await page.$eval('.caixa-movel[data-id="im1"]', e => { const r = e.getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height }; });
  await page.mouse.click(b.x + b.w / 2, b.y + b.h / 2); await page.waitForTimeout(400); await page.keyboard.press('Escape'); await page.waitForTimeout(300);
  await page.mouse.move(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.down(); await page.mouse.move(b.x + b.w / 2 + 140, b.y + b.h / 2 + 60, { steps: 8 });
  const r = await page.$eval('.previa-quadro', e => { const q = e.getBoundingClientRect(); return { x: q.x, y: q.y, width: q.width, height: q.height }; });
  await page.screenshot({ path: IMG + '/31_caixas_moveis.png', clip: { x: r.x, y: r.y, width: r.width, height: Math.min(r.height, page.viewportSize().height - r.y) } });
  await page.mouse.up(); await browser.close();
})();
