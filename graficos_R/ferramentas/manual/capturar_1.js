// Prints do manual, parte 1: guia, tela inicial e visão geral (com as coordenadas para as setas numeradas).
const fs = require('fs'); const { abrir, exemplo, painel, rects, escolherY, campo, IMG } = require('./comum');
(async () => {
  let { browser, page, idle } = await abrir({ manterModal: true });
  await page.waitForTimeout(500);
  if (await page.$('#shiny-modal-wrapper .modal')) { await page.screenshot({ path: IMG + '/01_guia.png' }); await page.keyboard.press('Escape'); await page.waitForTimeout(700); }
  await page.screenshot({ path: IMG + '/02_inicial.png' });
  await exemplo(page, idle, 'ensaio_temperatura.csv');
  await escolherY(page, idle, ['Amostra A', 'Amostra B', 'Amostra C']);
  await painel(page, 'eixos'); await page.click('#bloco-numeros > summary'); await page.waitForTimeout(300);
  await campo(page, idle, 'x_titulo', 'Tempo (min)'); await campo(page, idle, 'y_titulo', 'Temperatura (°C)');
  await painel(page, 'dados'); await page.evaluate(() => { const g = document.querySelector('.gaveta'); if (g) g.scrollTop = 0; }); await page.waitForTimeout(400);
  await page.screenshot({ path: IMG + '/03_visao_geral.png' });
  const r = await rects(page, { cabecalho: '.topo', abas: '.abas-barra', trilho: '.trilho', gaveta: '.gaveta', faixa: '.faixa', grafico: '#previa', rodape: '.estudio .palco > :last-child',
    projeto: '#salvar_projeto', abrir: 'button[title^="Abre um arquivo .cinabro"]', estilos: '#estilo', restaurar: '#restaurar', sair: '#sair', ajuda: '#guia', baixar: '#botoes_baixar', maximizar: '#maximizar', atualizar: '#atualizar' });
  fs.writeFileSync(IMG + '/03_visao_geral.json', JSON.stringify(r, null, 1));
  console.log(Object.keys(r).join(', '));
  await browser.close();
})();
