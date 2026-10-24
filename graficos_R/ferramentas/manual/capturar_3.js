// Prints do manual, parte 3: CSV do Excel brasileiro, ajuste de curva e caixa de estatística.
const path = require('path'); const { novaPrevia, abrir, exemplo, painel, recorte, rolar, escolherY, campo, IMG, DADOS } = require('./comum');
(async () => {
  const { browser, page, idle } = await abrir();
  await painel(page, 'dados');
  await page.setInputFiles('#arquivo', path.join(DADOS, 'calibracao_excel_ptbr.csv')); await page.waitForFunction(() => document.querySelector('#previa img')); await idle();
  await rolar(page, null, 'Seus dados'); await recorte(page, '16_excel_ptbr');
  await page.selectOption('#tipo_grafico', 'pontos'); await idle();
  await painel(page, 'eixos'); await page.click('#bloco-numeros > summary'); await page.waitForTimeout(300);
  await campo(page, idle, 'x_titulo', 'Concentração (mg/L)'); await campo(page, idle, 'y_titulo', 'Absorbância');
  // menu "Ajuste de curva"
  await page.click('summary:has-text("Ajuste de curva")'); await page.waitForTimeout(400);
  await recorte(page, '17_menu_ajuste', '.faixa', { altura: 380, largura: 520 });
  await novaPrevia(page, idle, () => page.click('.faixa-lista >> text=Linear (reta)'));
  await page.screenshot({ path: IMG + '/18_ajuste_resultado.png' });
  await recorte(page, '19_ajuste_cartao');
  console.log('ok'); await browser.close();
})();
