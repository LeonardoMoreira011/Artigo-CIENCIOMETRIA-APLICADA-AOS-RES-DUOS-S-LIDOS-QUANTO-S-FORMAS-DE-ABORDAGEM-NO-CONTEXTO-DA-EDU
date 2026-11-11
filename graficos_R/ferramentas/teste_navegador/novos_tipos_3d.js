// Teste no navegador (Playwright). Rode com o app aberto: node novos_tipos_3d.js <pasta para as imagens>
// Radar, linhas 3D e mapa de cor: os campos certos aparecem em cada tipo, as faixas de cor e as linhas de nível desenham sem erro.
const { chromium } = require('playwright'); const path = require('path');
const SP = process.argv[2];
(async () => { const b = await chromium.launch({ args: ['--no-sandbox'] }); const p = await b.newPage({ viewport: { width: 1500, height: 950 } });
  let falhas = 0; const ok = (n, c) => { console.log((c ? 'OK   ' : 'FALHA') + ' ' + n); if (!c) falhas++; };
  p.on('pageerror', e => { console.log('PAGEERROR', e.message); falhas++; });
  const idle = async () => { await p.waitForTimeout(500); await p.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'), null, { timeout: 120000 }); await p.waitForTimeout(900); };
  await p.goto('' + (process.env.CINABRO_URL || 'http://127.0.0.1:8421/') + ''); await p.waitForTimeout(2000); await p.waitForSelector('#retomar_nao', { timeout: 3000 }).then(() => p.click('#retomar_nao')).catch(() => {});
  const exemplo = async n => { await p.selectOption('#exemplo', n); await p.waitForFunction(() => document.querySelector('#previa img')); await idle(); };
  const vis = async id => await p.$eval('#' + id, e => !!(e.offsetParent)).catch(() => false);
  await exemplo('radar_materiais.csv'); await p.selectOption('#tipo_grafico', 'radar'); await idle(); await p.waitForTimeout(1200); await idle();
  ok('radar: prévia presente e sem erro', !!(await p.$('#previa img')) && !/Algo precisa/.test(await p.textContent('body')));
  ok('radar: campos do radar visíveis e os do 3D escondidos', (await vis('radar_aneis')) && !(await vis('tri_azimute')) && !(await vis('calor_esquema')));
  await p.screenshot({ path: path.join(SP, 'novos_radar.png') });
  await p.fill('#radar_aneis', '4'); await p.selectOption('#radar_formato_grade', 'circulo'); await idle(); await p.waitForTimeout(1200); await idle();
  ok('radar: mudar anéis e grade atualiza sem erro', !/Algo precisa/.test(await p.textContent('body')));
  await exemplo('espectros_cascata.csv'); await p.selectOption('#tipo_grafico', 'linhas_3d'); await idle(); await p.waitForTimeout(1500); await idle();
  ok('linhas 3D: campos do 3D e de preenchimento visíveis', (await vis('tri_azimute')) && (await vis('tri_linhas_preencher')) && (await vis('calor_niveis_cor')) && !(await vis('radar_aneis')));
  await p.screenshot({ path: path.join(SP, 'novos_linhas3d.png') });
  await exemplo('superficie_rendimento.csv'); await p.selectOption('#tipo_grafico', 'mapa_cor'); await idle(); await p.waitForTimeout(1500); await idle();
  await p.fill('#calor_niveis_cor', '8'); await p.fill('#tri_niveis', '6'); await idle(); await p.waitForTimeout(1500); await idle();
  ok('mapa de cor: faixas de cor e linhas de nível sem erro', !/Algo precisa/.test(await p.textContent('body')) && !!(await p.$('#previa img')));
  await p.screenshot({ path: path.join(SP, 'novos_mapacor.png') });
  await b.close(); console.log(falhas ? falhas + ' FALHA(S)' : 'Tudo certo.'); process.exit(falhas ? 1 : 0); })();
