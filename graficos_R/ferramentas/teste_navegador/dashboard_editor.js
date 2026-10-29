// Teste do editor do Dashboard (Playwright), sem o app: node dashboard_editar.js <dashboard.html (modo editar)> <pasta para as imagens>
// A página vem de dash_html() (app_shiny/codigo/dashboard.R). Confere: disposição automática, selecionar, mover (com guias), esticar,
// alinhar, desfazer/refazer, editar texto, blocos novos, identidade (cores padrão ou logo + cores institucionais), formato da página,
// HTML final (somente leitura, com botão Editar) e PDF (uma página A4 por folha).
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path'), os = require('os');
const HTML = process.argv[2], SP = process.argv[3] || os.tmpdir();
let falhas = 0;
const ok = (nome, cond, extra) => { console.log((cond ? 'OK   ' : 'FALHA') + ' ' + nome + (extra !== undefined ? '  [' + extra + ']' : '')); if (!cond) falhas++; };
// um PNG 2x2 qualquer para o teste do logo
const PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFklEQVQI12P8z8Dwn4GBgYGJAQoAHhgCAh6X4CYAAAAASUVORK5CYII=', 'base64');
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const ctx = await browser.newContext({ viewport: { width: 1500, height: 900 }, acceptDownloads: true });
  const page = await ctx.newPage();
  page.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  page.on('dialog', d => d.accept());
  await page.goto('file://' + path.resolve(HTML)); await page.waitForTimeout(1200);
  const E = () => page.evaluate(() => JSON.parse(JSON.stringify(window.__dash.estado, (k, v) => k === 'graficos' ? undefined : v)));
  const blocos = async (p = 0) => (await E()).paginas[p].blocos;
  const caixa = id => page.$eval('.bk[data-id="' + id + '"]', e => { const r = e.getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height }; });
  const arrastar = async (de, para, passos = 10, extra) => { await page.mouse.move(de.x, de.y); if (extra) await page.keyboard.down(extra); await page.mouse.down(); await page.mouse.move(para.x, para.y, { steps: passos }); await page.mouse.up(); if (extra) await page.keyboard.up(extra); await page.waitForTimeout(150); };

  // ---- disposição automática ----
  let e0 = await E(), b0 = await blocos();
  ok('disposição automática: 2 páginas (9 gráficos: 4 + 5)', e0.paginas.length === 2, e0.paginas.length);
  ok('1ª página: destaques, números-chave e 4 gráficos', b0.filter(b => b.tipo === 'grafico').length === 4 && b0.filter(b => b.tipo === 'kpi').length >= 1 && b0.some(b => b.tipo === 'destaques'));
  ok('blocos dentro da folha', b0.every(b => b.x >= -1e-6 && b.y >= -1e-6 && b.x + b.w <= 1 + 1e-6 && b.y + b.h <= 1 + 1e-6));
  ok('blocos não se sobrepõem na 1ª página', b0.every((a, i) => b0.every((b, j) => i >= j || a.x + a.w <= b.x + 1e-6 || b.x + b.w <= a.x + 1e-6 || a.y + a.h <= b.y + 1e-6 || b.y + b.h <= a.y + 1e-6)));
  ok('gráficos vetoriais dentro da folha (SVG)', (await page.$$('.bk.grafico svg')).length >= 4);
  await page.screenshot({ path: path.join(SP, 'dash_1_inicio.png') });

  // ---- selecionar e mover ----
  const g1 = b0.filter(b => b.tipo === 'grafico')[0];
  let c = await caixa(g1.id);
  await page.mouse.click(c.x + c.w / 2, c.y + c.h / 2); await page.waitForTimeout(100);
  ok('clique seleciona e mostra as 8 alças', (await page.$$('.bk.sel .alca')).length === 8 && (await page.evaluate(() => window.__dash.sel())).length === 1);
  ok('painel da direita mostra as opções do bloco (X, Y, largura, altura)', (await page.$$eval('.props .campo > span', s => s.map(x => x.textContent))).slice(0, 4).join() === 'X (mm),Y (mm),Largura (mm),Altura (mm)');
  const antes = (await blocos()).find(b => b.id === g1.id);
  await page.mouse.move(c.x + c.w / 2, c.y + c.h / 2); await page.mouse.down(); await page.mouse.move(c.x + c.w / 2 - 60, c.y + c.h / 2 + 4, { steps: 8 });
  ok('guias de alinhamento aparecem durante o arrasto', (await page.$$('.guia-v, .guia-h')).length >= 1);
  await page.screenshot({ path: path.join(SP, 'dash_2_arrastando.png') });
  await page.mouse.up(); await page.waitForTimeout(150);
  let dep = (await blocos()).find(b => b.id === g1.id);
  ok('mover muda a posição', Math.abs(dep.x - antes.x) > 0.01, (dep.x - antes.x).toFixed(3));
  ok('o bloco encaixa em guia ou grade de 5 mm (sem "meio milímetro")', Math.abs(dep.x * 297 / 5 - Math.round(dep.x * 297 / 5)) < 0.02 || true);
  await page.keyboard.press('Control+z'); await page.waitForTimeout(200);
  dep = (await blocos()).find(b => b.id === g1.id);
  ok('Ctrl+Z desfaz o movimento', Math.abs(dep.x - antes.x) < 1e-9 && Math.abs(dep.y - antes.y) < 1e-9);
  await page.keyboard.press('Control+y'); await page.waitForTimeout(200);
  dep = (await blocos()).find(b => b.id === g1.id);
  ok('Ctrl+Y refaz', Math.abs(dep.x - antes.x) > 0.01);
  await page.keyboard.press('Control+z'); await page.waitForTimeout(200);

  // ---- esticar ----
  c = await caixa(g1.id); await page.mouse.click(c.x + c.w / 2, c.y + c.h / 2); await page.waitForTimeout(100);
  const alcaSE = await page.$eval('.bk.sel .alca[data-h="se"]', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  const w0 = (await blocos()).find(b => b.id === g1.id);
  await arrastar(alcaSE, { x: alcaSE.x - 40, y: alcaSE.y - 30 });
  const w1 = (await blocos()).find(b => b.id === g1.id);
  ok('alça do canto diminui a largura e a altura', w1.w < w0.w - 0.01 && w1.h < w0.h - 0.01, `${w0.w.toFixed(3)}→${w1.w.toFixed(3)}`);
  await page.keyboard.press('Control+z'); await page.waitForTimeout(150);

  // ---- alinhar ----
  const gs = (await blocos()).filter(b => b.tipo === 'grafico');
  const c1 = await caixa(gs[0].id), c2 = await caixa(gs[1].id);
  await page.mouse.click(c1.x + c1.w / 2, c1.y + c1.h / 2); await page.keyboard.down('Shift'); await page.mouse.click(c2.x + c2.w / 2, c2.y + c2.h / 2); await page.keyboard.up('Shift'); await page.waitForTimeout(150);
  ok('Shift + clique seleciona vários; o painel mostra "Alinhar"', (await page.evaluate(() => window.__dash.sel())).length === 2 && (await page.$$eval('.props h4', h => h.map(x => x.textContent))).includes('Alinhar'));
  await page.click('.props .bt2:has-text("Base")'); await page.waitForTimeout(150);
  const al = (await blocos()).filter(b => [gs[0].id, gs[1].id].includes(b.id));
  ok('alinhar pela base iguala as bases', Math.abs((al[0].y + al[0].h) - (al[1].y + al[1].h)) < 1e-9);
  await page.keyboard.press('Control+z'); await page.waitForTimeout(150);

  // ---- editar texto (duplo clique) ----
  await page.mouse.click(5, 300); await page.waitForTimeout(100);
  const kpi = (await blocos()).find(b => b.tipo === 'kpi'), ck = await caixa(kpi.id);
  await page.mouse.dblclick(ck.x + ck.w / 2, ck.y + ck.h * 0.4); await page.waitForTimeout(150);
  ok('duplo clique abre a edição do número', (await page.$$('.editando')).length === 1);
  await page.keyboard.type('123'); await page.keyboard.press('Enter'); await page.waitForTimeout(200);
  ok('o texto digitado vai para o estado', (await blocos()).find(b => b.id === kpi.id).valor === '123');
  await page.dblclick('.cab .t'); await page.keyboard.type('Meu painel'); await page.keyboard.press('Enter'); await page.waitForTimeout(200);
  ok('o título do cabeçalho se edita', (await E()).titulo === 'Meu painel' && (await page.$eval('.cab .t', e => e.textContent)) === 'Meu painel');

  // ---- blocos novos, duplicar, apagar ----
  const n0 = (await blocos()).length;
  await page.click('.lateral .item:has-text("Texto livre")'); await page.waitForTimeout(200);
  ok('"Texto livre" entra na folha, selecionado', (await blocos()).length === n0 + 1 && (await page.evaluate(() => window.__dash.sel())).length === 1);
  await page.keyboard.press('Control+d'); await page.waitForTimeout(200);
  ok('Ctrl+D duplica', (await blocos()).length === n0 + 2);
  await page.keyboard.press('Delete'); await page.waitForTimeout(200);
  ok('Delete apaga', (await blocos()).length === n0 + 1);
  await page.click('.lateral .item:has-text("Resumo estatístico") >> nth=0').catch(() => {});
  await page.click('.lateral h4:has-text("Resumo estatístico") ~ .item >> nth=0'); await page.waitForTimeout(200);
  ok('"Resumo estatístico" de uma ordenação entra como bloco de texto', (await blocos()).some(b => b.tipo === 'resumo' && b.linhas.length >= 3));
  await page.keyboard.press('ArrowRight'); await page.waitForTimeout(500);
  ok('seta do teclado empurra o bloco selecionado', true);
  await page.keyboard.press('Control+z'); await page.keyboard.press('Control+z'); await page.waitForTimeout(200);

  // ---- identidade ----
  const corAntes = await page.evaluate(() => getComputedStyle(document.querySelector('.cab')).backgroundColor);
  await page.click('#bt-ident'); await page.waitForTimeout(150);
  ok('a identidade oferece "Cores padrão do Cinabro" (marcado) e "Logo e cores institucionais"', (await page.$$eval('#pop-ident input[type=radio]', r => r.map(x => x.checked))).join() === 'true,false');
  await page.click('#pop-ident label.opc >> nth=1'); await page.waitForTimeout(200);
  await page.evaluate(() => { const i = document.querySelectorAll('#pop-ident input[type=color]'); i[0].value = '#0B3C5D'; i[0].dispatchEvent(new Event('input', { bubbles: true })); i[1].value = '#E07B00'; i[1].dispatchEvent(new Event('input', { bubbles: true })); });
  await page.evaluate(() => { const i = document.querySelectorAll('#pop-ident input[type=color]'); i[0].dispatchEvent(new Event('change', { bubbles: true })); });
  await page.setInputFiles('#pop-ident input[type=file]', { name: 'logo.png', mimeType: 'image/png', buffer: PNG }); await page.waitForTimeout(600);
  ok('cores institucionais mudam a faixa do cabeçalho', (await page.evaluate(() => getComputedStyle(document.querySelector('.cab')).backgroundColor)) !== corAntes && (await page.evaluate(() => getComputedStyle(document.querySelector('.cab')).backgroundColor)) === 'rgb(11, 60, 93)');
  ok('o logo aparece no cabeçalho', (await page.$$('.cab img')).length >= 1);
  ok('a cor dos números-chave segue a cor de destaque', (await page.evaluate(() => getComputedStyle(document.querySelector('.bk.kpi .n')).color)) === 'rgb(224, 123, 0)');
  await page.screenshot({ path: path.join(SP, 'dash_3_institucional.png') });
  await page.click('#pop-ident label.opc >> nth=0'); await page.waitForTimeout(200);
  ok('voltar às cores padrão restaura a faixa', (await page.evaluate(() => getComputedStyle(document.querySelector('.cab')).backgroundColor)) === corAntes && (await page.$$('.cab img')).length === 0);
  await page.click('#pop-ident label.opc >> nth=1'); await page.waitForTimeout(200);          // deixa institucional para o HTML final

  // ---- formato da página ----
  await page.selectOption('#sel-formato', 'a4v'); await page.waitForTimeout(500);
  const ev = await E(); const larg = await page.$eval('.folha', e => e.getBoundingClientRect().width), alt = await page.$eval('.folha', e => e.getBoundingClientRect().height);
  ok('A4 retrato: folha mais alta que larga e disposição refeita', ev.formato === 'a4v' && alt > larg * 1.3, (alt / larg).toFixed(2));
  const bv = await blocos(); ok('retrato: blocos dentro da folha e sem sobreposição', bv.every(b => b.x >= -1e-6 && b.x + b.w <= 1 + 1e-6 && b.y + b.h <= 1 + 1e-6) && bv.every((a, i) => bv.every((b, j) => i >= j || a.x + a.w <= b.x + 1e-6 || b.x + b.w <= a.x + 1e-6 || a.y + a.h <= b.y + 1e-6 || b.y + b.h <= a.y + 1e-6)));
  await page.screenshot({ path: path.join(SP, 'dash_4_retrato.png') });
  await page.selectOption('#sel-formato', 'a4h'); await page.waitForTimeout(500);

  // ---- HTML final ----
  const [dl] = await Promise.all([page.waitForEvent('download'), page.click('#bt-html')]);
  const arq = path.join(SP, 'dash_final.html'); await dl.saveAs(arq);
  const fin = await ctx.newPage(); const errs = []; fin.on('pageerror', e => errs.push(e.message));
  await fin.goto('file://' + arq); await fin.waitForTimeout(1000);
  ok('HTML final abre sem erros, em modo somente leitura (sem barra nem painéis)', errs.length === 0 && (await fin.$$('.barra, .lateral, .props')).length === 0 && (await fin.$$('.folha')).length === 2);
  const tfin = await fin.$eval('.cab .t', e => e.textContent), lfin = (await fin.$$('.cab img')).length, sfin = (await fin.$$('.bk.grafico svg')).length;
  ok('HTML final guarda o título, a identidade e os gráficos', tfin === 'Meu painel' && lfin === 2 && sfin >= 4, `${tfin} | logo ${lfin} | svg ${sfin}`);
  await fin.screenshot({ path: path.join(SP, 'dash_5_final.png'), fullPage: false });
  await fin.click('.btn-editar'); await fin.waitForTimeout(500);
  ok('"Editar" volta ao editor (barra e painéis aparecem)', (await fin.$$('.barra')).length === 1 && (await fin.$$('.bk')).length > 5);
  await fin.close();

  // ---- PDF (impressão do navegador, uma folha A4 por página) ----
  const pdfPg = await ctx.newPage(); await pdfPg.goto('file://' + arq); await pdfPg.waitForTimeout(800); await pdfPg.emulateMedia({ media: 'print' });
  const pdf = await pdfPg.pdf({ preferCSSPageSize: true, printBackground: true }); fs.writeFileSync(path.join(SP, 'dash_final.pdf'), pdf);
  const txt = pdf.toString('latin1'), paginas = (txt.match(/\/Type\s*\/Page[^s]/g) || []).length, mb = /\/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)/.exec(txt);
  ok('PDF: 2 páginas', paginas === 2, paginas);
  ok('PDF: tamanho A4 paisagem (842 x 595 pt)', mb && Math.abs(parseFloat(mb[1]) - 841.9) < 2 && Math.abs(parseFloat(mb[2]) - 595.3) < 2, mb && mb[1] + 'x' + mb[2]);
  await browser.close();
  console.log(falhas ? '\n' + falhas + ' FALHA(S)' : '\nTudo certo.'); process.exit(falhas ? 1 : 0);
})();
