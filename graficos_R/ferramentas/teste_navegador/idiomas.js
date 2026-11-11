// Teste no navegador (Playwright). Rode com o app aberto: node idiomas.js <pasta para as imagens>
// Percurso: português -> escolher English -> o trabalho continua (dados e gráfico) -> Español -> cookie guarda o idioma -> volta ao português.
// Também mede o tempo de abrir a tela em cada idioma (a 1ª vez de cada idioma traduz a tela; depois é imediato) e confere os gráficos 3D.
const { chromium } = require('playwright');
const path = require('path');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
let falhas = 0;
const ok = (nome, cond, extra) => { console.log((cond ? 'OK   ' : 'FALHA') + ' ' + nome + (extra !== undefined ? '  [' + extra + ']' : '')); if (!cond) falhas++; };
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const ctx = await browser.newContext({ viewport: { width: 1500, height: 950 } });
  const page = await ctx.newPage();
  page.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  const idle = async () => { await page.waitForTimeout(500); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 120000 }); await page.waitForTimeout(700); };
  const aberto = async (url) => { const t0 = Date.now(); await page.goto(url, { waitUntil: 'load' }); await page.waitForSelector('#idioma_sel', { timeout: 60000 }); const dt = Date.now() - t0; await page.waitForTimeout(1800); return dt; };
  const textoTela = async () => (await page.textContent('body')) || '';
  const fechaModal = async () => { await page.waitForSelector('#retomar_nao', { timeout: 4000 }).then(() => page.click('#retomar_nao')).catch(() => {}); await page.waitForTimeout(500); };

  // 1) português (a tela do português já está pronta ao abrir o programa)
  const t_pt = await aberto(URL); await fechaModal();
  ok('o seletor de idioma existe e tem 3 idiomas', (await page.$$eval('#idioma_sel option', o => o.map(x => x.value))).join() === 'pt,en,es');
  ok('a tela abre em português', /Seus dados/.test(await textoTela()), t_pt + ' ms');

  // 2) dados + gráfico
  await page.selectOption('#exemplo', 'ensaio_temperatura.csv'); await page.waitForFunction(() => document.querySelector('#previa img')); await idle();
  ok('com o exemplo carregado, a prévia aparece', !!(await page.$('#previa img')));

  // 3) trocar para English pelo seletor: a página recarrega e o trabalho continua
  const t0 = Date.now();
  await Promise.all([page.waitForNavigation({ timeout: 90000 }).catch(() => {}), page.selectOption('#idioma_sel', 'en')]);
  await page.waitForSelector('#idioma_sel', { timeout: 90000 }); await page.waitForFunction(() => document.querySelector('#previa img'), null, { timeout: 90000 }); await idle();
  const t_en = Date.now() - t0;
  const tx_en = await textoTela();
  ok('em English a tela está traduzida (Your data, Plot type...) e o gráfico continua lá', /Your data/.test(tx_en) && /Plot type/.test(tx_en) && !!(await page.$('#previa img')), '1ª vez: ' + t_en + ' ms');
  ok('em English não sobra título de bloco em português', !/Seus dados|Intervalos dos eixos|Tamanho e exportação/.test(tx_en));
  ok('a pergunta "Retomar de onde você parou?" não aparece (a troca retoma sozinha)', (await page.$$('#retomar_sim')).length === 0);
  ok('o tipo de gráfico trazido da sessão continua o mesmo', (await page.$eval('#tipo_grafico', e => e.value)) === 'linha_pontos');
  ok('os tipos de gráfico novos estão na lista, em inglês', (await page.$$eval('#tipo_grafico option', o => o.map(x => x.textContent))).some(x => /3D surface/.test(x)) && (await page.$$eval('#tipo_grafico option', o => o.map(x => x.textContent))).some(x => /Color map/.test(x)));
  await page.screenshot({ path: path.join(SP, 'idiomas_en.png') });

  // 4) Español, e depois English de novo (já traduzido: mais rápido)
  const t1 = Date.now();
  await Promise.all([page.waitForNavigation({ timeout: 90000 }).catch(() => {}), page.selectOption('#idioma_sel', 'es')]);
  await page.waitForSelector('#idioma_sel', { timeout: 90000 }); await page.waitForFunction(() => document.querySelector('#previa img'), null, { timeout: 90000 }); await idle();
  const t_es = Date.now() - t1, tx_es = await textoTela();
  ok('em Español a tela está traduzida e o gráfico continua', /Tus datos/.test(tx_es) && !/Seus dados/.test(tx_es) && !!(await page.$('#previa img')), '1ª vez: ' + t_es + ' ms');
  const t2 = Date.now();
  await Promise.all([page.waitForNavigation({ timeout: 90000 }).catch(() => {}), page.selectOption('#idioma_sel', 'en')]);
  await page.waitForSelector('#idioma_sel', { timeout: 90000 }); await page.waitForFunction(() => document.querySelector('#previa img'), null, { timeout: 90000 }); await idle();
  const t_en2 = Date.now() - t2;
  ok('voltar a um idioma já aberto é mais rápido (a tela fica guardada)', t_en2 < t_en + 500, t_en2 + ' ms contra ' + t_en + ' ms');

  // 5) o cookie guarda o idioma: uma página nova abre em inglês sem pedir nada
  const p2 = await ctx.newPage(); await p2.goto(URL); await p2.waitForSelector('#idioma_sel'); await p2.waitForTimeout(1200);
  ok('uma página nova abre no último idioma escolhido (cookie)', /Your data/.test((await p2.textContent('body')) || '') && (await p2.$eval('#idioma_sel', e => e.value)) === 'en'); await p2.close();

  // 6) um gráfico 3D em inglês: o título da barra e os nomes dos eixos vêm do idioma
  await page.selectOption('#exemplo', 'superficie_rendimento.csv'); await page.waitForFunction(() => document.querySelector('#previa img')); await idle();
  await page.selectOption('#tipo_grafico', 'superficie_3d'); await idle(); await page.waitForTimeout(1500); await idle();
  ok('a superfície 3D desenha em English (prévia presente, sem aviso de erro)', !!(await page.$('#previa img')) && !/Something needs adjusting/.test(await textoTela()));
  await page.screenshot({ path: path.join(SP, 'idiomas_3d_en.png') });

  // 7) volta ao português
  await Promise.all([page.waitForNavigation({ timeout: 90000 }).catch(() => {}), page.selectOption('#idioma_sel', 'pt')]);
  await page.waitForSelector('#idioma_sel', { timeout: 90000 }); await page.waitForFunction(() => document.querySelector('#previa img'), null, { timeout: 90000 }); await idle();
  ok('de volta ao português, sem restos do inglês e com o trabalho no lugar', /Seus dados/.test(await textoTela()) && !/Your data/.test(await textoTela()) && (await page.$eval('#tipo_grafico', e => e.value)) === 'superficie_3d');
  await browser.close();
  console.log(falhas ? '\n' + falhas + ' FALHA(S)' : '\nTudo certo.'); process.exit(falhas ? 1 : 0);
})();
