// Prints do manual, parte 5: exportação (seção completa) e "Modelo, configuração e código".
const { novaPrevia, abrir, exemplo, painel, recorte, rolar, IMG } = require('./comum');
(async () => {
  const { browser, page, idle } = await abrir();
  await exemplo(page, idle, 'ensaio_temperatura.csv');
  await painel(page, 'exportar');
  await page.click('#bloco-exportacao > summary'); await page.waitForTimeout(400);
  await rolar(page, '#bloco-exportacao > summary', ''); await recorte(page, '29_exportacao_secao');
  // bloco "Modelo, configuração e código" (abaixo do gráfico)
  const resumo = await page.$('summary:has-text("Modelo, configuração e código")');
  if (resumo) { await resumo.scrollIntoViewIfNeeded(); await resumo.click(); await page.waitForTimeout(700);
    await page.evaluate(() => { const m = document.querySelector('.palco'); const el = [...document.querySelectorAll('summary')].find(e => e.innerText.includes('Modelo, configuração')); if (el) el.scrollIntoView({ block: 'start' }); });
    await page.waitForTimeout(500); await page.screenshot({ path: IMG + '/30_modelo_codigo.png' }); }
  // estilos prontos
  await page.evaluate(() => window.scrollTo(0, 0));
  console.log('ok'); await browser.close();
})();
