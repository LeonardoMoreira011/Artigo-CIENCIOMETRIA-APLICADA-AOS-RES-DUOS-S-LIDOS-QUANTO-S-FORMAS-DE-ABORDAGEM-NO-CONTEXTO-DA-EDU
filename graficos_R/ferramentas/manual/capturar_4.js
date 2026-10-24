// Prints do manual, parte 4: barras de erro, testes estatísticos, anotações, exportar, abas, retomar.
const path = require('path'); const { novaPrevia, abrir, exemplo, painel, recorte, rolar, escolherY, campo, IMG } = require('./comum');
async function escolherMulti(page, id, termos) {
  for (const t of termos) { await page.click(`#${id}-selectized`); await page.fill(`#${id}-selectized`, t); await page.waitForTimeout(200); await page.click('.selectize-dropdown-content .option >> nth=0'); }
  await page.keyboard.press('Escape'); await page.waitForTimeout(300);
}
(async () => {
  let { browser, page, idle } = await abrir();
  // ---- barras de erro (média ± desvio padrão)
  await painel(page, 'dados');
  await exemplo(page, idle, 'media_e_desvio.csv');
  await page.selectOption('#tipo_grafico', 'pontos'); await idle();
  await rolar(page, null, 'Colunas de erro');
  await novaPrevia(page, idle, () => escolherMulti(page, 'colunas_erro', ['Desvio']));
  await painel(page, 'eixos'); await page.click('#bloco-numeros > summary'); await page.waitForTimeout(300);
  await campo(page, idle, 'x_titulo', 'Tempo (h)'); await campo(page, idle, 'y_titulo', 'Concentração (mg/L)');
  await painel(page, 'dados'); await rolar(page, null, 'Colunas de erro'); await recorte(page, '20_erro_painel');
  await page.screenshot({ path: IMG + '/21_erro_resultado.png' });
  // ---- testes estatísticos (replicatas em boxplot)
  await exemplo(page, idle, 'replicatas.csv');
  await page.selectOption('#tipo_grafico', 'boxplot'); await idle();
  await page.click('button:has-text("Tabelas e testes")'); await page.waitForTimeout(600);
  await page.evaluate(() => { const s = $('#estat_testes')[0].selectize; s.clear(); });
  await escolherMulti(page, 'estat_testes', ['Normalidade', 'ANOVA', 'Tukey', 'Kruskal', 'Pares']);
  await page.click('#estat_calcular'); await idle(); await page.waitForTimeout(800);
  await rolar(page, '#estat_testes', ''); await recorte(page, '22_testes_painel');
  await page.evaluate(() => { const g = document.querySelector('.gaveta'); const t = document.querySelector('.estat-tabelas'); if (t) g.scrollTop += t.getBoundingClientRect().top - g.getBoundingClientRect().top - 40; });
  await page.waitForTimeout(300); await recorte(page, '23_testes_tabelas');
  await page.screenshot({ path: IMG + '/24_boxplot.png' });
  // ---- anotar: texto, forma, figura
  await page.click('.faixa >> text=Texto'); await page.waitForTimeout(1200); await idle();
  await page.screenshot({ path: IMG + '/25_anotar_texto.png' });
  // ---- exportar
  await painel(page, 'exportar'); await recorte(page, '26_exportar');
  // ---- abas e cabeçalho
  await page.click('.aba-acao:has-text("Duplicar")'); await idle(); await page.waitForTimeout(500);
  await recorte(page, '27_cabecalho_abas', '.topo', { altura: 140, largura: 1440 });
  await page.screenshot({ path: IMG + '/27_abas.png', clip: { x: 0, y: 0, width: 1440, height: 130 } });
  await page.waitForTimeout(6500);                                       // salvamento automático
  await browser.close();
  // ---- retomar
  ({ browser, page, idle } = await abrir({ manterModal: true }));
  await page.waitForSelector('#retomar_sim', { timeout: 15000 }).catch(() => {});
  await page.screenshot({ path: IMG + '/28_retomar.png' });
  console.log('retomar visível?', !!(await page.$('#retomar_sim')));
  await browser.close();
})();
