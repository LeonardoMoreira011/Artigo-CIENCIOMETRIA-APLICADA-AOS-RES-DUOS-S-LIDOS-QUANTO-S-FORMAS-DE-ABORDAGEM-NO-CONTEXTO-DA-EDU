// Gera o PDF do dashboard a partir da página de impressão (precisa de: npm i playwright). Uso: node dashboard_para_pdf.js [pt|en|es]
const { chromium } = require('playwright'); const path = require('path');
const idm = process.argv[2] || 'pt';
(async () => {
  const b = await chromium.launch({ args: ['--no-sandbox'] }); const p = await b.newPage();
  await p.goto('file://' + path.resolve(__dirname, 'dashboard_' + idm + '_impressao.html')); await p.waitForTimeout(3000);
  await p.pdf({ path: path.resolve(__dirname, 'dashboard_' + idm + '.pdf'), preferCSSPageSize: true, printBackground: true });
  await b.close(); console.log('PDF gerado: dashboard_' + idm + '.pdf');
})();
