// Gera Guia_Visual_Cinabro.pdf a partir de manual/guia_visual.html (Chromium via Playwright). Uso: node ferramentas/guia/guia_pdf.js
const path = require('path'); const fs = require('fs');
let chromium; try { chromium = require('playwright').chromium; } catch (e) { chromium = require('/opt/node-tools/node_modules/playwright').chromium; }
(async () => {
  const raiz = path.resolve(__dirname, '..', '..');
  const b = await chromium.launch({ args: ['--no-sandbox'] }); const p = await b.newPage();
  await p.goto('file://' + path.join(raiz, 'manual', 'guia_visual.html')); await p.waitForSelector('body[data-pronto]'); await p.waitForTimeout(800); await p.evaluate(() => document.fonts.ready);
  await p.pdf({ path: path.join(raiz, 'Guia_Visual_Cinabro.pdf'), width: '297mm', height: '210mm', printBackground: true, preferCSSPageSize: true });
  await b.close(); console.log('PDF gerado: Guia_Visual_Cinabro.pdf');
})();
