// Teste no navegador (Playwright): giro 3D. Rode com o app aberto: node orbita_3d.js <pasta para as imagens>
const { chromium } = require('playwright');
const path = require('path');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
let falhas = 0;
const ok = (n, c, x) => { console.log((c ? 'OK   ' : 'FALHA') + ' ' + n + (x !== undefined ? '  [' + x + ']' : '')); if (!c) falhas++; };
(async () => {
  const b = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await (await b.newContext({ viewport: { width: 1500, height: 950 } })).newPage();
  page.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  const idle = async () => { await page.waitForTimeout(500); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 120000 }); await page.waitForTimeout(600); };
  await page.goto(URL); await page.waitForSelector('#tipo_grafico', { timeout: 60000 }); await page.waitForTimeout(1500);
  await page.waitForSelector('#retomar_nao', { timeout: 3000 }).then(() => page.click('#retomar_nao')).catch(() => {});
  ok('a barra de giro está escondida num gráfico comum', !(await page.isVisible('#orbita-barra')));
  await page.selectOption('#exemplo', 'superficie_rendimento.csv'); await page.waitForFunction(() => document.querySelector('#previa img')); await idle();
  await page.selectOption('#tipo_grafico', 'superficie_3d'); await idle(); await page.waitForTimeout(1200);
  ok('na superfície 3D a barra de giro aparece', await page.isVisible('#orbita-barra'));
  const src0 = await page.$eval('#previa img', e => e.src);
  const box = await page.$eval('#previa img', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  await page.screenshot({ path: path.join(SP, 'orbita_0_padrao.png') });
  // arrastar
  await page.mouse.move(box.x, box.y); await page.mouse.down();
  for (let i = 1; i <= 12; i++) { await page.mouse.move(box.x + i * 14, box.y + i * 3); await page.waitForTimeout(120); }
  const durante = await page.$eval('#previa img', e => e.src);
  await page.screenshot({ path: path.join(SP, 'orbita_1_arrastando.png') });
  await page.mouse.up(); await idle(); await page.waitForTimeout(1500); await idle();
  ok('arrastar muda a prévia', durante !== src0 || (await page.$eval('#previa img', e => e.src)) !== src0);
  const az = parseFloat(await page.inputValue('#tri_azimute')), el = parseFloat(await page.inputValue('#tri_elevacao'));
  ok('ao soltar, o campo "Giro da vista" acompanha o arraste', Math.abs(az - 40) > 20, az + ' / ' + el);
  await page.screenshot({ path: path.join(SP, 'orbita_2_solto.png') });
  // vistas prontas
  for (const [nome, a, e] of [['Topo', 0, 90], ['Lado', 90, 12], ['Frente', 0, 12], ['Padrão', 40, 28]]) {
    await page.click('.orbita-vista:has-text("' + nome + '")'); await idle(); await page.waitForTimeout(1200); await idle();
    ok('vista ' + nome, Math.abs(parseFloat(await page.inputValue('#tri_azimute')) - a) < 0.6 && Math.abs(parseFloat(await page.inputValue('#tri_elevacao')) - e) < 0.6);
    await page.screenshot({ path: path.join(SP, 'orbita_vista_' + nome + '.png') });
  }
  // giro contínuo
  const antes = await page.$eval('#previa img', e => e.src);
  await page.click('#orbita-girar'); await page.waitForTimeout(4000);
  const meio = await page.$eval('#previa img', e => e.src);
  await page.screenshot({ path: path.join(SP, 'orbita_3_girando.png') });
  ok('o botão Girar fica ativo e a prévia muda sozinha', (await page.$eval('#orbita-girar', e => e.classList.contains('btn-verde'))) && meio !== antes);
  await page.click('#orbita-girar'); await idle(); await page.waitForTimeout(1500); await idle();
  ok('parar o giro devolve o botão ao normal e grava o ângulo', !(await page.$eval('#orbita-girar', e => e.classList.contains('btn-verde'))) && Math.abs(parseFloat(await page.inputValue('#tri_azimute')) - 40) > 1, await page.inputValue('#tri_azimute'));
  await page.selectOption('#tipo_grafico', 'linha_pontos'); await idle(); await page.waitForTimeout(800);
  ok('ao voltar a um gráfico comum a barra some', !(await page.isVisible('#orbita-barra')));
  await b.close();
  console.log(falhas ? '\n' + falhas + ' FALHA(S)' : '\nTudo certo.'); process.exit(falhas ? 1 : 0);
})();
