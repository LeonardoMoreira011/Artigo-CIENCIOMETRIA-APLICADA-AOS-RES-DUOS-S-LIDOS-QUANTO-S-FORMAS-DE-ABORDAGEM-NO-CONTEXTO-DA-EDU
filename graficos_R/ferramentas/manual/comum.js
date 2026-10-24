// Funções comuns dos roteiros que tiram os prints do manual. Precisa do app aberto (CINABRO_URL, padrão http://127.0.0.1:8421/),
// do Playwright (npm i playwright) e do Chromium. Variável CHROMIUM = caminho do chromium (opcional).
const path = require('path');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const IMG = process.env.MANUAL_IMG || path.resolve(__dirname, '..', '..', 'manual', 'img');
const DADOS = path.resolve(__dirname, '..', '..', 'dados');
let chromium; try { chromium = require('playwright').chromium; } catch (e) { chromium = require('/opt/node-tools/node_modules/playwright').chromium; }

async function abrir(opts = {}) {
  const browser = await chromium.launch({ executablePath: process.env.CHROMIUM || (require('fs').existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined), args: ['--no-sandbox'] });
  const ctx = await browser.newContext({ viewport: { width: opts.largura || 1440, height: opts.altura || 900 }, deviceScaleFactor: opts.escala || 1, acceptDownloads: true });
  const page = await ctx.newPage();
  page.on('pageerror', e => console.log('PAGEERROR', e.message));
  const idle = async () => { await page.waitForTimeout(500);
    await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy') && !document.querySelector('#shiny-notification-panel .progress'), null, { timeout: 120000 });
    await page.waitForTimeout(700); };
  await page.goto(URL); await page.waitForTimeout(2500);
  if (!opts.manterModal && await page.$('#retomar_nao')) { await page.click('#retomar_nao'); await page.waitForTimeout(700); }       // ofereceu retomar o trabalho anterior
  if (!opts.manterModal && await page.$('#shiny-modal-wrapper .modal')) { await page.keyboard.press('Escape'); await page.waitForTimeout(700); }
  return { browser, ctx, page, idle };
}
async function exemplo(page, idle, nome) {
  await page.selectOption('#exemplo', nome); await page.waitForFunction(() => document.querySelector('#previa img')); await idle(); await page.waitForTimeout(600);
}
async function painel(page, id) {                               // abre um painel do trilho (sem fechar se já estiver aberto)
  const aberto = await page.$eval('.painel.ativo', e => e.id).catch(() => '');
  if (aberto !== 'painel-' + id) { await page.click(`.trilho-btn[data-painel="${id}"]`); await page.waitForTimeout(450); }
}
async function rects(page, seletores) {
  const out = {}; const vp = page.viewportSize();
  for (const [k, sel] of Object.entries(seletores)) {
    const r = await page.$eval(sel, e => { const b = e.getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: b.height }; }).catch(() => null);
    if (r) out[k] = { x: r.x / vp.width, y: r.y / vp.height, w: r.w / vp.width, h: r.h / vp.height };
  }
  return out;
}
async function recorte(page, nome, seletor = '.gaveta', opcoes = {}) {   // print só de uma região (padrão: o painel lateral)
  const r = await page.$eval(seletor, e => { const b = e.getBoundingClientRect(); return { x: b.x, y: b.y, width: b.width, height: b.height }; });
  const y0 = Math.max(0, r.y + (opcoes.dy || 0)), h = Math.min(opcoes.altura || r.height, page.viewportSize().height - y0);
  await page.screenshot({ path: IMG + '/' + nome + '.png', clip: { x: r.x, y: y0, width: opcoes.largura || r.width, height: h } });
}
async function rolar(page, seletor, texto) {                    // rola o painel lateral até um rótulo/campo
  await page.evaluate(([sel, tx]) => { const g = document.querySelector('.gaveta'); const el = sel ? document.querySelector(sel) : [...document.querySelectorAll('.gaveta label, .gaveta summary, .gaveta h3, .gaveta h2')].find(e => e.innerText.includes(tx));
    if (el) { const gr = g.getBoundingClientRect(), er = el.getBoundingClientRect(); g.scrollTop += er.top - gr.top - 70; } }, [seletor, texto]);
  await page.waitForTimeout(250);
}
async function escolherY(page, idle, nomes) {                    // escolhe as colunas Y (selectize)
  await page.click('#colunas_y-selectized');
  for (const n of nomes) { await page.fill('#colunas_y-selectized', n); await page.waitForTimeout(150); await page.click(".selectize-dropdown-content .option >> nth=0"); }
  await page.keyboard.press('Escape'); await idle();
}
async function campo(page, idle, id, valor) { await page.fill('#' + id, String(valor)); await page.keyboard.press('Tab'); await idle(); }
async function novaPrevia(page, idle, acao) {                    // faz a ação e espera a prévia ser redesenhada
  const antes = await page.$eval('#previa img', e => e.src).catch(() => '');
  await acao();
  await page.waitForFunction(a => { const i = document.querySelector('#previa img'); return i && i.src !== a; }, antes, { timeout: 60000 }).catch(() => {});
  await idle(); await page.waitForTimeout(500);
}
module.exports = { novaPrevia, recorte, rolar, escolherY, campo, abrir, exemplo, painel, rects, IMG, DADOS, URL };
