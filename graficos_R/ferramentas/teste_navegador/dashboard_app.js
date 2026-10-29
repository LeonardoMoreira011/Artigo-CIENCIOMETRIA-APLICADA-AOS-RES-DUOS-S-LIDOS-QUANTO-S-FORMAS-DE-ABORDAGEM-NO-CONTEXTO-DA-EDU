// Teste no navegador (Playwright). Rode com o app aberto: node dashboard_app.js <pasta para as imagens>
// O PDF precisa do Edge/Chrome do computador; neste teste, aponte CINABRO_NAVEGADOR para o executável (antes de abrir o app) se ele não for achado.
// Percurso completo do Dashboard: 3 abas (linhas, barras, mapa-múndi) -> botão Dashboard -> escolha das abas -> editor em tela cheia ->
// arrastar um bloco -> PDF pelo servidor -> voltar ao Cinabro -> voltar ao último dashboard (o que foi arrumado continua).
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const URL = process.env.CINABRO_URL || 'http://127.0.0.1:8421/';
const SP = process.argv[2] || require('os').tmpdir();
let falhas = 0;
const ok = (nome, cond, extra) => { console.log((cond ? 'OK   ' : 'FALHA') + ' ' + nome + (extra !== undefined ? '  [' + extra + ']' : '')); if (!cond) falhas++; };
(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const ctx = await browser.newContext({ viewport: { width: 1500, height: 950 }, acceptDownloads: true });
  const page = await ctx.newPage();
  page.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  const idle = async () => { await page.waitForTimeout(500); await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 120000 }); await page.waitForTimeout(800); };
  const exemplo = async n => { await page.selectOption('#exemplo', n); await page.waitForFunction(() => document.querySelector('#previa img')); await idle(); };
  await page.goto(URL); await page.waitForTimeout(2500); await page.waitForSelector('#retomar_nao', { timeout: 8000 }).then(() => page.click('#retomar_nao')).catch(() => {}); await page.waitForTimeout(800);

  // sem dados: o botão avisa
  await page.click('#abrir_dashboard'); await page.waitForTimeout(800);
  ok('sem dados, o botão Dashboard avisa em vez de abrir', (await page.$$('#dash_montar')).length === 0 && /Carregue os dados/.test(await page.textContent('#shiny-notification-panel')));

  await exemplo('ensaio_temperatura.csv');
  await page.click('.aba-acao:has-text("+ Nova aba")'); await idle(); await page.waitForTimeout(2200);
  await exemplo('resistencia_materiais.csv'); await page.selectOption('#tipo_grafico', 'barras'); await idle(); await page.waitForTimeout(1500); await idle();
  await page.click('.aba-acao:has-text("+ Nova aba")'); await idle(); await page.waitForTimeout(2200);
  await exemplo('mapa_mundo_vendas.csv'); await page.selectOption('#tipo_grafico', 'mapa_mundo'); await idle(); await page.waitForTimeout(1500); await idle();
  await page.click('.aba-acao:has-text("+ Nova aba")'); await idle(); await page.waitForTimeout(2200);     // 4ª aba, sem dados: tem de ficar de fora
  ok('4 abas', (await page.$$('.aba')).length === 4);

  await page.click('#abrir_dashboard'); await page.waitForSelector('#dash_montar', { timeout: 10000 }); await page.waitForTimeout(400);
  ok('a janela oferece as abas COM dados (3) e avisa das sem dados', (await page.$$('#dash_abas input[type=checkbox]')).length === 3 && /Sem dados/.test(await page.textContent('.modal-body')));
  ok('padrões: A4 paisagem, gráficos vetoriais, destaques ligados', (await page.$eval('#dash_formato', e => e.value)) === 'a4h' && (await page.$eval('#dash_qualidade', e => e.value)) === 'vetorial' && (await page.$eval('#dash_destaques', e => e.checked)));
  await page.screenshot({ path: path.join(SP, 'dashapp_1_janela.png') });
  await page.click('#dash_montar');
  await page.waitForSelector('#dash-overlay iframe', { timeout: 120000 });
  const frame = page.frameLocator('#dash-frame'); await frame.locator('.folha').first().waitFor({ timeout: 30000 }); await page.waitForTimeout(1500);
  const f = page.frames().find(x => x.url().includes('/painel/dash_'));
  ok('o editor abre em tela cheia, dentro do Cinabro', !!f && (await page.$eval('#dash-overlay', e => getComputedStyle(e).display)) === 'block');
  const bl = await f.evaluate(() => window.__dash.estado.paginas[0].blocos.map(b => b.tipo));
  ok('1ª página: 3 gráficos, números-chave e destaques', bl.filter(t => t === 'grafico').length === 3 && bl.includes('kpi') && bl.includes('destaques'), bl.join());
  ok('gráficos em SVG vetorial', (await f.$$('.bk.grafico svg')).length === 3);
  const fr = await f.evaluate(() => (window.__dash.estado.paginas[0].blocos.find(b => b.tipo === 'destaques').itens || []).join(' | '));
  ok('os destaques saem dos números (Aço/Titânio; Estados Unidos)', /subiu/.test(fr) && /maior valor/.test(fr), fr.slice(0, 120));
  await page.screenshot({ path: path.join(SP, 'dashapp_2_editor.png') });

  // arrastar um bloco dentro do editor
  const g = await f.evaluate(() => window.__dash.estado.paginas[0].blocos.filter(b => b.tipo === 'grafico')[0].id);
  const r = await f.$eval('.bk[data-id="' + g + '"]', e => { const r = e.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; });
  const ant = await f.evaluate(id => window.__dash.estado.paginas[0].blocos.find(b => b.id === id).x, g);
  await page.mouse.move(r.x, r.y); await page.mouse.down(); await page.mouse.move(r.x + 70, r.y + 10, { steps: 8 }); await page.mouse.up(); await page.waitForTimeout(300);
  const dep = await f.evaluate(id => window.__dash.estado.paginas[0].blocos.find(b => b.id === id).x, g);
  ok('arrastar no editor (dentro do iframe) move o bloco', Math.abs(dep - ant) > 0.01, (dep - ant).toFixed(3));

  // PDF gerado pelo servidor (Edge/Chrome em modo invisível)
  const [dl] = await Promise.all([page.waitForEvent('download', { timeout: 120000 }), f.click('#bt-pdf')]);
  const arq = path.join(SP, 'dashapp.pdf'); await dl.saveAs(arq);
  const pdf = fs.readFileSync(arq), txt = pdf.toString('latin1');
  const paginas = (txt.match(/\/Type\s*\/Page[^s]/g) || []).length;
  ok('o PDF baixa pronto (arquivo PDF válido, nome do título)', txt.startsWith('%PDF') && pdf.length > 5000 && /\.pdf$/.test(dl.suggestedFilename()), dl.suggestedFilename() + ' ' + Math.round(pdf.length / 1024) + ' KB');
  ok('o PDF tem uma página A4 paisagem por folha', paginas === 1, paginas + ' página(s)');
  let fontes = ''; try { fontes = require('child_process').execSync('pdffonts "' + arq + '"').toString(); } catch (e) { fontes = null; }
  ok('o PDF usa a fonte Barlow (a mesma dos gráficos) e não uma fonte de reserva', fontes === null || (/Barlow/.test(fontes) && !/Inter|Liberation|DejaVu/.test(fontes)), fontes === null ? 'pdffonts ausente: não conferido' : fontes.split('\n').slice(2, 4).join(' / ').replace(/\s+/g, ' '));
  let texto = ''; try { texto = require('child_process').execSync('pdftotext "' + arq + '" -').toString(); } catch (e) { texto = null; }
  ok('o texto do PDF é de verdade (selecionável): título e destaques', texto === null || (/Painel de acompanhamento/.test(texto) && /Amostra A/.test(texto)));
  // voltar ao Cinabro e depois ao dashboard: o que foi arrumado continua
  await f.click('#bt-voltar'); await page.waitForTimeout(400);
  ok('"Voltar ao Cinabro" esconde o editor', (await page.$eval('#dash-overlay', e => getComputedStyle(e).display)) === 'none');
  await page.click('#abrir_dashboard'); await page.waitForSelector('#dash_reabrir', { timeout: 10000 }); await page.click('#dash_reabrir'); await page.waitForTimeout(800);
  const dep2 = await f.evaluate(id => window.__dash.estado.paginas[0].blocos.find(b => b.id === id).x, g);
  ok('"Voltar ao último" traz o editor de volta com a disposição que você deixou', (await page.$eval('#dash-overlay', e => getComputedStyle(e).display)) === 'block' && Math.abs(dep2 - dep) < 1e-9);
  await browser.close();
  console.log(falhas ? '\n' + falhas + ' FALHA(S)' : '\nTudo certo.'); process.exit(falhas ? 1 : 0);
})();
