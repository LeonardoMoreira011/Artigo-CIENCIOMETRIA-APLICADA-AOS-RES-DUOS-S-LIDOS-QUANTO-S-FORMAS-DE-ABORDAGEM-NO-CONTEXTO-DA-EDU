// Prints do manual, parte 2: dados, eixos, séries, texto, legenda.
const { abrir, exemplo, painel, rects, recorte, rolar, escolherY, campo, IMG } = require('./comum');
(async () => {
  const { browser, page, idle } = await abrir();
  await painel(page, 'dados');
  await recorte(page, '04_dados_inicio');                              // "Seus dados": enviar CSV ou usar exemplo
  await exemplo(page, idle, 'ensaio_temperatura.csv');
  await rolar(page, null, 'Seus dados'); await recorte(page, '05_dados_carregados');
  await rolar(page, null, 'Tipo de gráfico'); await recorte(page, '06_tipo_colunas');
  await escolherY(page, idle, ['Amostra A', 'Amostra B', 'Amostra C']);
  await rolar(page, null, 'Tipo de gráfico'); await recorte(page, '07_colunas_y');
  // títulos dos eixos
  await painel(page, 'eixos');
  await page.click('#bloco-numeros > summary'); await page.waitForTimeout(400);
  await rolar(page, '#bloco-numeros > summary', '');
  await recorte(page, '08_eixos_titulos');
  await campo(page, idle, 'x_titulo', 'Tempo (min)'); await campo(page, idle, 'y_titulo', 'Temperatura (°C)');
  await page.screenshot({ path: IMG + '/09_primeiro_grafico.png' });
  // intervalos
  await painel(page, 'eixos'); await page.click('#bloco-numeros > summary'); await page.waitForTimeout(300);
  await rolar(page, '#bloco-intervalos > summary', ''); await recorte(page, '10_eixos_intervalos');
  // escala e grade
  await page.click('#bloco-escala > summary'); await page.waitForTimeout(300); await rolar(page, '#bloco-escala > summary', ''); await recorte(page, '11_eixos_escala');
  await page.click('#bloco-grade > summary'); await page.waitForTimeout(300); await rolar(page, '#bloco-grade > summary', ''); await recorte(page, '12_eixos_grade');
  // séries
  await painel(page, 'series'); await recorte(page, '13_series');
  // texto e legenda
  await painel(page, 'texto'); await recorte(page, '14_texto');
  await painel(page, 'legenda'); await recorte(page, '15_legenda');
  console.log('ok'); await browser.close();
})();
