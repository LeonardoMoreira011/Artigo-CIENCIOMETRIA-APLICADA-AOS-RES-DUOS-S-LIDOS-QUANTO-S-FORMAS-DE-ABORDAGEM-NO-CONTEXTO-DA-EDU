// Gera manual/Manual_Cinabro.pdf a partir de manual/manual.html (Chromium via Playwright).
// uso: node ferramentas/manual/gerar_pdf.js        (depois de capturar os prints e a galeria)
const path = require('path'); const fs = require('fs');
let chromium; try { chromium = require('playwright').chromium; } catch (e) { chromium = require('/opt/node-tools/node_modules/playwright').chromium; }
(async () => {
  const raiz = path.resolve(__dirname, '..', '..', 'manual');
  const browser = await chromium.launch({ executablePath: process.env.CHROMIUM || (fs.existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined), args: ['--no-sandbox', '--allow-file-access-from-files'] });
  const page = await browser.newPage();
  await page.goto('file://' + path.join(raiz, 'manual.html')); await page.waitForTimeout(1500);
  await page.evaluate(() => document.fonts.ready);
  await page.pdf({ path: path.join(raiz, '..', 'Manual_Cinabro.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true,
    displayHeaderFooter: true, headerTemplate: '<span></span>',
    footerTemplate: '<div style="font-family: sans-serif; font-size: 8px; width: 100%; text-align: center; color: #6B6358;">Cinabro — manual de uso &nbsp;·&nbsp; página <span class="pageNumber"></span> de <span class="totalPages"></span></div>' });
  await browser.close(); console.log('PDF gerado:', path.join(raiz, '..', 'Manual_Cinabro.pdf'));
})();
