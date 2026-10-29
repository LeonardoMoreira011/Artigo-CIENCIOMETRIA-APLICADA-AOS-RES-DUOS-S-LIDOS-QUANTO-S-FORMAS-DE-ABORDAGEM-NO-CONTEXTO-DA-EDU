// Teste no navegador (Playwright). Rode com o app aberto: node caixas_moveis.js <pasta para as imagens>
// Precisa de: npm i playwright   e   npx playwright install chromium.   CINABRO_URL muda o endereço (padrão http://127.0.0.1:8421/).
// Confere as caixas móveis: moldura sempre visível, mover, esticar por canto e por lado, Shift (proporção), setas, "sombra" ao arrastar,
// caixa em unidades dos eixos e clique para editar.
const { chromium } = require('playwright');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
let falhas = 0;
const ok = (nome, cond, extra) => { console.log((cond ? 'OK   ' : 'FALHA') + ' ' + nome + (extra !== undefined ? '  [' + extra + ']' : '')); if (!cond) falhas++; };
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await (await browser.newContext({ viewport: { width: 1500, height: 950 } })).newPage();
  page.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  const idle = async () => { await page.waitForTimeout(500); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 90000 }); await page.waitForTimeout(500); };
  const assenta = async () => { await idle(); await page.waitForTimeout(900); await idle(); };
  const val = async id => parseFloat(await page.$eval('#' + id, e => e.value));
  const box = id => page.$eval('.caixa-movel[data-id="' + id + '"]', e => { const r = e.getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height }; });
  const alca = (id, h) => page.$eval('.caixa-movel[data-id="' + id + '"] .cm-alca[data-h="' + h + '"]', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  const arrastar = async (de, para, passos = 8, shift = false) => {
    await page.mouse.move(de.x, de.y); if (shift) await page.keyboard.down('Shift'); await page.mouse.down();
    await page.mouse.move(para.x, para.y, { steps: passos }); await page.mouse.up(); if (shift) await page.keyboard.up('Shift');
  };
  await page.goto(URL); await page.waitForTimeout(2500);
  if (await page.$('#retomar_nao')) { await page.click('#retomar_nao'); await page.waitForTimeout(600); }       // aviso de "retomar o último gráfico"
  await page.selectOption('#exemplo', 'ensaio_temperatura.csv'); await page.waitForFunction(() => document.querySelector('#previa img')); await idle();
  // 1) ajuste linear: nasce a caixa de estatística, com moldura visível mesmo sem o mouse em cima
  await page.click('summary:has-text("Ajuste de curva")'); await page.click('.faixa-lista >> text=Linear (reta)'); await assenta();
  ok('caixa de estatística nasce com moldura', (await page.$$eval('.caixa-movel', els => els.map(e => e.dataset.id))).includes('cx1'));
  await page.mouse.move(5, 5);
  ok('moldura visível sem passar o mouse', await page.$eval('.caixa-movel[data-id="cx1"]', e => getComputedStyle(e).borderTopColor !== 'rgba(0, 0, 0, 0)' && parseFloat(getComputedStyle(e).borderTopWidth) > 0));
  // 1b) caixa de estatística: mover e esticar o canto (muda a letra)
  let b = await box('cx1'); const cx0 = await val('cx1_x'), cy0 = await val('cx1_y');
  await arrastar({ x: b.x + b.w / 2, y: b.y + b.h / 2 }, { x: b.x + b.w / 2 - 250, y: b.y + b.h / 2 + 200 }); await assenta();
  ok('estatística: arrastar muda x e y', (await val('cx1_x')) !== cx0 && (await val('cx1_y')) !== cy0, cx0 + ',' + cy0 + ' -> ' + (await val('cx1_x')) + ',' + (await val('cx1_y')));
  b = await box('cx1'); const t0 = parseFloat(await page.$eval('#cx1_tamanho_pt', e => e.value) || '0');
  await arrastar(await alca('cx1', 'nw'), { x: b.x - 40, y: b.y - 30 }); await assenta();
  ok('estatística: puxar o canto muda o tamanho da letra', (await val('cx1_tamanho_pt')) > (t0 || 0), (t0 || '(vazio)') + ' -> ' + (await val('cx1_tamanho_pt')));
  // 6) clique = edição rápida
  b = await box('cx1'); await page.mouse.click(b.x + b.w / 2, b.y + b.h / 2); await page.waitForTimeout(500);
  ok('clique abre a edição rápida', (await page.$('#popover-edicao')) !== null && (await page.$$eval('#popover-edicao .campo', els => els.length)) > 0);
  await page.keyboard.press('Escape'); await page.waitForTimeout(300);
  // 2) figura (fração): mover, esticar pelo canto (proporção) e ver a "sombra" durante o gesto
  await page.click('.faixa-btn:has-text("Figura")'); await page.waitForTimeout(600);
  await page.setInputFiles('#im1_arquivo', SP + '/logo_teste.png'); await page.waitForTimeout(1500); await assenta();
  b = await box('im1'); const x0 = await val('im1_x'), y0 = await val('im1_y');
  await page.mouse.move(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.down(); await page.mouse.move(b.x + b.w / 2 - 120, b.y + b.h / 2 - 90, { steps: 6 });
  ok('sombra aparece durante o arrasto', await page.$eval('.caixa-movel[data-id="im1"] .cm-fant', e => getComputedStyle(e).display === 'block' && getComputedStyle(e).backgroundImage.indexOf('url') === 0));
  await page.screenshot({ path: SP + '/cx_0_arrastando.png' });
  await page.mouse.up(); await assenta();
  ok('figura: x e y mudaram ao arrastar', (await val('im1_x')) < x0 && (await val('im1_y')) > y0, x0 + ',' + y0 + ' -> ' + (await val('im1_x')) + ',' + (await val('im1_y')));
  b = await box('im1'); const l0 = parseFloat(await page.$eval('#im1_largura', e => e.value) || '0');
  await arrastar(await alca('im1', 'se'), { x: b.x + b.w + 70, y: b.y + b.h + 5 }); await assenta();
  const l1 = await val('im1_largura'); ok('figura: puxar o canto muda a largura', l1 > (l0 || 0.2), (l0 || '(vazio)') + ' -> ' + l1);
  ok('figura: o canto mantém a proporção (altura vazia)', await page.$eval('#im1_altura', e => e.value === ''));
  // 3) retângulo em unidades dos eixos: mover, esticar por lado
  await page.click('summary:has-text("Forma")'); await page.click('.faixa-lista >> text=Retângulo'); await assenta();
  await page.selectOption('#fm1_unidade', 'dados'); await page.waitForTimeout(300);
  for (const [k, v] of [['x', 30], ['y', 40], ['largura', 15], ['altura', 20]]) { await page.fill('#fm1_' + k, String(v)); await page.dispatchEvent('#fm1_' + k, 'change'); }
  await assenta();
  ok('retângulo em unidades dos eixos ganha moldura', (await page.$$eval('.caixa-movel', els => els.map(e => e.dataset.id))).includes('fm1'));
  b = await box('fm1'); const rx = await val('fm1_x'), ry = await val('fm1_y'), rl = await val('fm1_largura'), ra = await val('fm1_altura');
  await arrastar({ x: b.x + b.w / 2, y: b.y + b.h / 2 }, { x: b.x + b.w / 2 + 100, y: b.y + b.h / 2 - 60 }); await assenta();
  const rx1 = await val('fm1_x'), ry1 = await val('fm1_y');
  ok('dados: arrastar muda x e y na unidade dos eixos', rx1 > rx && ry1 > ry && rx1 < 60.5 && ry1 < 100.5, rx + ',' + ry + ' -> ' + rx1 + ',' + ry1);
  ok('dados: arrastar não mexe na largura e na altura', (await val('fm1_largura')) === rl && (await val('fm1_altura')) === ra);
  b = await box('fm1');
  await arrastar(await alca('fm1', 'e'), { x: b.x + b.w + 60, y: b.y + b.h / 2 + 30 }); await assenta();
  const rl1 = await val('fm1_largura'), ra1 = await val('fm1_altura');
  ok('dados: puxar o lado direito muda só a largura', rl1 > rl && ra1 === ra, rl + ' -> ' + rl1 + ' | altura ' + ra + ' -> ' + ra1);
  b = await box('fm1');
  await arrastar(await alca('fm1', 'n'), { x: b.x + b.w / 2, y: b.y - 40 }); await assenta();
  ok('dados: puxar o lado de cima muda só a altura', (await val('fm1_altura')) > ra1 && (await val('fm1_largura')) === rl1, ra1 + ' -> ' + (await val('fm1_altura')));
  // 4) setas: ajuste fino do retângulo selecionado
  b = await box('fm1'); await page.mouse.click(b.x + b.w / 2, b.y + b.h / 2); await page.waitForTimeout(300);
  await page.keyboard.press('Escape'); await page.waitForTimeout(200);
  const ax = await val('fm1_x');
  for (let i = 0; i < 4; i++) await page.keyboard.press('ArrowRight');
  await page.keyboard.press('Shift+ArrowDown'); await page.waitForTimeout(900); await assenta();
  ok('setas movem a caixa selecionada', (await val('fm1_x')) > ax, ax + ' -> ' + (await val('fm1_x')));
  await page.screenshot({ path: SP + '/cx_2_final.png' });
  // 7) texto, polígono e figura empilhados no centro (o pior caso): cada um tem que ser alcançável, mover e esticar (cantos e lados)
  const pg2 = await (await browser.newContext({ viewport: { width: 1500, height: 950 } })).newPage();
  pg2.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  const page2 = pg2;
  const idle2 = async () => { await page2.waitForTimeout(500); await page2.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 90000 }); await page2.waitForTimeout(500); };
  const assenta2 = async () => { await idle2(); await page2.waitForTimeout(900); await idle2(); };
  await page2.goto(URL); await page2.waitForTimeout(2500); if (await page2.$('#retomar_nao')) { await page2.click('#retomar_nao'); await page2.waitForTimeout(600); }
  await page2.selectOption('#exemplo', 'ensaio_temperatura.csv'); await page2.waitForFunction(() => document.querySelector('#previa img')); await idle2();
  await page2.click('.faixa-btn:has-text("Texto")'); await assenta2();
  await page2.click('summary:has-text("Forma")'); await page2.click('.faixa-lista >> text=Polígono livre'); await assenta2();
  await page2.click('.faixa-btn:has-text("Figura")'); await page2.waitForTimeout(600);
  await page2.setInputFiles('#im1_arquivo', SP + '/logo_teste.png'); await page2.waitForTimeout(1500); await assenta2();
  const v2 = async id => (await page2.$eval('#' + id, e => e.value));
  const b2 = id => page2.$eval('.caixa-movel[data-id="' + id + '"]', e => { const r = e.getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height }; });
  const a2 = async (id, h) => { const q = await b2(id); await page2.mouse.move(q.x + q.w / 2, q.y + q.h / 2); await page2.waitForTimeout(150); return a2b(id, h); };       // as alças só aparecem com o mouse em cima
  const a2b = (id, h) => page2.$eval('.caixa-movel[data-id="' + id + '"] .cm-alca[data-h="' + h + '"]', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  const dono = async id => { const b = await b2(id); return page2.evaluate(([x, y]) => { const e = document.elementFromPoint(x, y); return (e.closest('.caixa-movel') || { dataset: {} }).dataset.id; }, [b.x + b.w / 2, b.y + b.h / 2]); };
  const arr2 = async (de, para) => { await page2.mouse.move(de.x, de.y); await page2.mouse.down(); await page2.mouse.move(para.x, para.y, { steps: 8 }); await page2.mouse.up(); await assenta2(); };
  ok('texto (menor) fica por cima do polígono e da figura maiores', (await dono('fm1')) === 'fm1', await dono('fm1'));
  ok('polígono é alcançável por uma parte livre (o centro está coberto pelos menores)', await page2.evaluate(() => { const e = document.querySelector('.caixa-movel[data-id="fm2"]'); const r = e.getBoundingClientRect(); const x = r.left + 8, y = r.bottom - 8; const t = document.elementFromPoint(x, y); return t && t.closest('.caixa-movel') && t.closest('.caixa-movel').dataset.id === 'fm2'; }));
  // texto: mover e esticar pelo canto (letra) e por um lado (largura e altura próprias)
  let t = await b2('fm1'); const tx0 = parseFloat(await v2('fm1_x'));
  await arr2({ x: t.x + t.w / 2, y: t.y + t.h / 2 }, { x: t.x + t.w / 2 - 200, y: t.y + t.h / 2 - 150 });
  ok('texto: arrastar muda a posição', parseFloat(await v2('fm1_x')) < tx0, tx0 + ' -> ' + (await v2('fm1_x')));
  t = await b2('fm1'); await arr2(await a2('fm1', 'se'), { x: t.x + t.w + 40, y: t.y + t.h + 20 });
  ok('texto: puxar o canto muda o tamanho da letra', (await v2('fm1_tamanho_pt')) !== '', 'tamanho_pt=' + (await v2('fm1_tamanho_pt')));
  t = await b2('fm1'); await arr2(await a2('fm1', 'e'), { x: t.x + t.w + 60, y: t.y + t.h / 2 });
  ok('texto: puxar o lado dá largura e altura próprias', (await v2('fm1_largura')) !== '' && (await v2('fm1_altura')) !== '', 'larg=' + (await v2('fm1_largura')) + ' alt=' + (await v2('fm1_altura')));
  // figura: canto (proporção) e lado (largura e altura livres)
  let f = await b2('im1'); await arr2(await a2('im1', 'se'), { x: f.x + f.w + 40, y: f.y + f.h + 40 });
  ok('figura: o canto muda só a largura (proporção mantida)', (await v2('im1_largura')) !== '' && (await v2('im1_altura')) === '', 'larg=' + (await v2('im1_largura')));
  f = await b2('im1'); await arr2(await a2('im1', 's'), { x: f.x + f.w / 2, y: f.y + f.h + 50 });
  ok('figura: puxar o lado de baixo dá altura própria', (await v2('im1_altura')) !== '', 'alt=' + (await v2('im1_altura')));
  // polígono: mover e esticar por um lado
  let pgn = await b2('fm2'); const vv0 = await v2('fm2_vertices');
  await arr2({ x: pgn.x + 10, y: pgn.y + pgn.h - 10 }, { x: pgn.x - 60, y: pgn.y + pgn.h - 60 });
  const vv1 = await v2('fm2_vertices'); ok('polígono: arrastar muda os vértices', vv1 !== vv0, vv0 + ' -> ' + vv1);
  pgn = await b2('fm2'); await arr2(await a2('fm2', 'w'), { x: pgn.x - 50, y: pgn.y + pgn.h / 2 });
  ok('polígono: puxar o lado esquerdo estica os vértices', (await v2('fm2_vertices')) !== vv1, vv1 + ' -> ' + (await v2('fm2_vertices')));
  await page2.screenshot({ path: SP + '/cx_3_empilhados.png' });
  await browser.close();
  console.log(falhas ? ('==== ' + falhas + ' FALHOU ====') : '==== tudo certo ====');
  process.exit(falhas ? 1 : 0);
})();
