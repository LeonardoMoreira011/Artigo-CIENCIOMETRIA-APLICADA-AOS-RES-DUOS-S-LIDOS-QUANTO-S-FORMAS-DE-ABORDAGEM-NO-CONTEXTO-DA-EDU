# -*- coding: utf-8 -*-
# Gera manual/guia_visual.html (Guia visual do Cinabro). Uso: python3 ferramentas/guia/gerar_guia.py   (depois: node ferramentas/guia/guia_pdf.js)
import json, os, html
AQUI = os.path.dirname(os.path.abspath(__file__)); RAIZ = os.path.normpath(os.path.join(AQUI, '..', '..'))
IMG = 'img_guia/'
PAL = json.load(open(os.path.join(RAIZ, 'manual', 'img_guia', 'paletas.json'), encoding='utf-8'))

# ---- ícones (traço, 24x24) ------------------------------------------------------------------------------------------------------
P = {
 'db': '<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 1.7 3.6 3 8 3s8-1.3 8-3V5"/><path d="M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>',
 'chart': '<path d="M3 3v18h18"/><path d="M7 15l4-5 3 3 5-7"/>',
 'palette': '<path d="M12 3a9 9 0 100 18c1.4 0 2-1 1.6-2.2-.4-1.3.3-2.3 1.6-2.3H17a4 4 0 004-4c0-5-4-9.5-9-9.5z"/><circle cx="7.5" cy="11" r="1"/><circle cx="10" cy="7" r="1"/><circle cx="15" cy="7" r="1"/>',
 'text': '<path d="M4 20l5.5-14 5.5 14M6 15h7M16 10h5M18.5 10v10"/>',
 'legend': '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 9h2M12 9h6M7 13h2M12 13h6M7 17h2M12 17h4"/>',
 'tools': '<path d="M14 6l4 4M4 20l9-9M13 4l7 7-3 3-7-7z"/>',
 'download': '<path d="M12 3v12M7 10l5 5 5-5M4 20h16"/>',
 'cube': '<path d="M12 2l9 5v10l-9 5-9-5V7z"/><path d="M12 12l9-5M12 12L3 7M12 12v10"/>',
 'rotate': '<path d="M20 12a8 8 0 11-2.6-5.9"/><path d="M20 4v5h-5"/>',
 'globe': '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18"/>',
 'layers': '<path d="M12 3l9 5-9 5-9-5z"/><path d="M3 13l9 5 9-5"/>',
 'dash': '<rect x="3" y="3" width="8" height="10" rx="1"/><rect x="13" y="3" width="8" height="6" rx="1"/><rect x="13" y="11" width="8" height="10" rx="1"/><rect x="3" y="15" width="8" height="6" rx="1"/>',
 'help': '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 114 2c-.8.6-1.5 1-1.5 2.2M12 17h.01"/>',
 'folder': '<path d="M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>',
 'sliders': '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
 'check': '<path d="M5 12.5l4.5 4.5L19 7"/>',
 'bulb': '<path d="M9 18h6M10 21h4M12 3a6 6 0 00-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0012 3z"/>',
 'warn': '<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 18h.01"/>',
 'mouse': '<path d="M5 3l14 7-6 2-2 6z"/>',
 'table': '<rect x="3" y="4" width="18" height="16" rx="1"/><path d="M3 10h18M3 15h18M9 4v16"/>',
 'star': '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
 'cpu': '<rect x="6" y="6" width="12" height="12" rx="1"/><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"/>',
 'pdf': '<path d="M6 3h8l4 4v14H6z"/><path d="M14 3v4h4M9 14h6M9 17h4"/>',
 'wrench': '<path d="M14.5 6.5a4 4 0 005 5L20 12l-8 8a2.1 2.1 0 01-3-3l8-8z"/>',
}
def ic(n, cls='', sz=None):
    s = ' style="width:%s;height:%s"' % (sz, sz) if sz else ''
    return '<svg class="ic %s" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"%s>%s</svg>' % (cls, s, P[n])

def fig(arq, leg='', cls='', estilo=''):
    return '<figure class="%s" style="%s"><img src="%s%s" alt="">%s</figure>' % (cls, estilo, IMG, arq, ('<figcaption>%s</figcaption>' % leg) if leg else '')
def nota(tipo, titulo, texto):
    ico = {'dica': 'bulb', 'atencao': 'warn', 'atalho': 'mouse', 'exemplo': 'star'}[tipo]
    return '<div class="nota %s">%s<div><b>%s</b> %s</div></div>' % (tipo, ic(ico), titulo, texto)
def passo(n, titulo, texto):
    return '<div class="passo"><span class="num">%s</span><div><b>%s</b><br>%s</div></div>' % (n, titulo, texto)
def badge(n, x, y): return '<span class="bd" style="left:%s%%;top:%s%%">%s</span>' % (x, y, n)

paginas = []
def pagina(secao, icone, titulo, corpo, cls=''):
    paginas.append((secao, icone, titulo, corpo, cls))

# ============ 1. Capa (tratada à parte) ======================================================================================================
CAPA = '''<section class="capa">
  <div class="capa-esq">
    <div class="capa-sel">GUIA VISUAL</div>
    <h1>Cinabro</h1>
    <p class="capa-lema">Dos seus dados ao gráfico pronto, sem programar.</p>
    <p class="capa-txt">Um passeio ilustrado, passo a passo, para quem vai usar o Cinabro todos os dias: do primeiro clique ao dashboard, com gráficos 3D, paletas de cores, projetos e idiomas.</p>
    <ul class="capa-lista">
      <li>%s Gráficos 2D, 3D, mapas e radar</li><li>%s 32 paletas de cores para os gradientes</li><li>%s Português, English e Español</li><li>%s Dashboard em uma página, com PDF</li>
    </ul>
    <div class="capa-rodape">Versão 0.3.0 · Leonardo Moreira · licença MIT</div>
  </div>
  <div class="capa-dir">%s%s%s</div>
</section>''' % (ic('cube'), ic('palette'), ic('globe'), ic('dash'),
  fig('pal_viridis.png', '', 'cp cp1'), fig('m20_radar.png', '', 'cp cp2'), fig('pal_divergente.png', '', 'cp cp3'))

# ============ 2. Como usar / mapa da tela ====================================================================================================
pagina('Comece aqui', 'mouse', 'Conheça a tela em 1 minuto', '''
<div class="col2" style="grid-template-columns:1.75fr 1fr">
  <div class="mapa">%s%s%s%s%s%s%s%s</div>
  <div>
    <ol class="leg-mapa">
      <li><b>Abas</b> — vários gráficos no mesmo trabalho (+ Nova aba, Duplicar, Renomear).</li>
      <li><b>Barra do topo</b> — idioma, estilos prontos, <i>Salvar projeto</i>, <i>Abrir projeto</i>, <i>Restaurar tudo</i> e <i>Sair</i>.</li>
      <li><b>Trilho de blocos</b> — 7 ícones: Dados · Eixos · Cores · Texto · Legenda · Análises · Exportação.</li>
      <li><b>Gaveta de ajustes</b> — os campos do bloco escolhido. Tudo muda o gráfico na hora.</li>
      <li><b>Faixa de ações</b> — ajuste de curva, média ± DP, caixa de estatística, anotações, baixar PNG/PDF, Dashboard.</li>
      <li><b>Barra de giro 3D</b> — só aparece nos gráficos 3D: arraste, gire e escolha vistas.</li>
      <li><b>Prévia</b> — o gráfico. Clique no título para editar; arraste a legenda e as caixas.</li>
    </ol>
    %s
  </div>
</div>''' % (fig('tela_3d.png', '', 'tela'), badge(1, 7, 8.2), badge(2, 78, 2.5), badge(3, 2.1, 36), badge(4, 17, 55), badge(5, 62, 15), badge(6, 47, 23.6), badge(7, 70, 64),
    nota('dica', 'Menos é mais.', 'Você só precisa de 3 passos para o primeiro gráfico: <b>dados → tipo de gráfico → ajustes</b>. O resto é refinamento, no seu tempo.')))

# ============ 3. Abrir o programa ============================================================================================================
pagina('Comece aqui', 'cpu', 'Instalar e abrir (Windows)', '''
<div class="passos4">%s%s%s%s</div>
<div class="col2" style="margin-top:6mm">
  <div class="cartao"><h3>%s Na primeira vez</h3><p>O Cinabro baixa sozinho os pacotes de que precisa. <b>Precisa de internet</b> e leva alguns minutos; as próximas aberturas conferem tudo em menos de 1 segundo.</p>
  <p>Em rede de empresa, se aparecer o aviso de internet, informe o proxy (a mensagem na tela mostra o comando).</p></div>
  <div class="cartao"><h3>%s Atalho na área de trabalho</h3><p>Na 1ª abertura o Cinabro cria o atalho sozinho. Se mudar a pasta de lugar, ele refaz o atalho.</p>
  <p>Para fechar: botão <b>Sair</b> no topo (fecha o programa de verdade, não só a aba do navegador).</p></div>
</div>
%s''' % (passo(1, 'Descompacte', 'Extraia o <b>Cinabro.zip</b> numa pasta sua (não rode de dentro do ZIP).'),
         passo(2, 'Abra', 'Dê dois cliques em <b>abrir_app.bat</b>. Uma janela preta aparece: é o Cinabro trabalhando.'),
         passo(3, 'Espere o navegador', 'O programa abre sozinho no navegador, em <i>localhost</i>. Seus dados <b>não saem</b> do computador.'),
         passo(4, 'Trabalhe', 'Escolha um exemplo ou o seu CSV. Para encerrar, clique em <b>Sair</b>.'),
         ic('download'), ic('star'),
         nota('atencao', 'Nunca feche a janela preta antes de terminar', 'ela é o motor do programa. Se fechar sem querer, abra o <i>abrir_app.bat</i> de novo e use o aviso <b>Retomar de onde você parou</b>: o Cinabro guarda o último gráfico sozinho.')))

# ============ 4. Passo 1 - dados ============================================================================================================
pagina('Passo a passo', 'db', 'Passo 1 · Traga os seus dados', '''
<div class="col2">
  <div>
    <p class="lead">Um arquivo <b>CSV</b> (salvo pelo Excel) é tudo de que você precisa. A <b>1ª coluna</b> costuma ser o eixo X; as outras, as séries (eixo Y).</p>
    <div class="tabela-demo"><table><tr><th>Tempo (min)</th><th>Amostra A</th><th>Amostra B</th></tr><tr><td>0</td><td>22,1</td><td>19,6</td></tr><tr><td>5</td><td>36,2</td><td>29,8</td></tr><tr><td>10</td><td>49,7</td><td>38,7</td></tr></table><span class="seta">→</span>%s</div>
    <ol class="lista-passos">
      <li>Clique em <b>Escolher arquivo...</b> (bloco <i>Dados</i>) ou use <b>...ou use um exemplo</b>.</li>
      <li>Confira a tabela que aparece: o Cinabro mostra as primeiras linhas e quantas colunas leu.</li>
      <li>Se precisar, troque a <b>Coluna do eixo X</b> e marque quais <b>Colunas Y</b> entram.</li>
    </ol>
  </div>
  <div>
    %s
    %s
  </div>
</div>''' % (fig('g01_linha_pontos.png', '', 'mini'), fig('tela_2d.png', 'Exemplo carregado: tabela, tipo de gráfico e colunas à esquerda; o gráfico à direita.', ''),
    nota('dica', 'Excel em português?', 'Pode salvar do jeito que o Excel salva (separador <b>;</b> e vírgula decimal, acentos em UTF-8). O Cinabro reconhece sozinho; não precisa trocar nada.')))

# ============ 5. Passo 2 - tipo de gráfico (galeria) ========================================================================================
def card(img, nome, quando): return '<div class="gal">%s<b>%s</b><span>%s</span></div>' % (fig(img), nome, quando)
pagina('Passo a passo', 'chart', 'Passo 2 · Escolha o tipo de gráfico', '<div class="galeria">' + ''.join([
  card('g01_linha_pontos.png', 'Linha e pontos', 'Uma grandeza que muda (tempo, dose, temperatura).'),
  card('g06_barras.png', 'Barras', 'Comparar categorias, com barras de erro.'),
  card('g07_pizza.png', 'Pizza / rosca', 'Partes de um todo (poucas categorias).'),
  card('g08_histograma.png', 'Histograma · densidade', 'Como os valores se distribuem.'),
  card('g09_boxplot.png', 'Boxplot', 'Comparar grupos e ver valores atípicos.'),
  card('g16_mapa_calor.png', 'Mapa de calor', 'Muitas amostras × muitas variáveis.'),
  card('g14_pca.png', 'PCA · CA · CCA', 'Resumir muitas variáveis em 2 eixos.'),
  card('m16_superficie_matriz.png', 'Superfície 3D · mapa de cor', 'Uma grandeza Z que depende de X e Y.'),
  card('m17_barras_3d.png', 'Barras 3D · dispersão 3D', 'Valores numa grade, ou pontos no espaço.'),
  card('m19_linhas_3d.png', 'Linhas 3D (cascata)', 'Espectros, perfis ao longo do tempo.'),
  card('m20_radar.png', 'Radar', 'Perfil de várias notas, de cada item.'),
  card('g18_mapa_brasil.png', 'Mapas (mundo · Brasil)', 'Valor por país ou estado.')]) + '</div>' + nota('dica', 'Em dúvida?', 'Escolha o tipo e olhe a prévia: dá para trocar quantas vezes quiser, sem perder os dados. A ajuda embaixo de cada campo explica o que ele faz.'), 'galeria-pg')

# ============ 6. Passo 3 - ajustes ===========================================================================================================
pagina('Passo a passo', 'sliders', 'Passo 3 · Ajuste do jeito que você quer', '''
<div class="blocos7">
  <div class="b7"><span class="ci">%s</span><b>Dados</b>Arquivo, tipo, colunas.</div>
  <div class="b7"><span class="ci">%s</span><b>Eixos</b>Início, fim, intervalo, escala, grade, quebra, Y2.</div>
  <div class="b7"><span class="ci">%s</span><b>Cores</b>Paleta, linhas, símbolos, série por série.</div>
  <div class="b7"><span class="ci">%s</span><b>Texto</b>Fonte, tamanhos, títulos.</div>
  <div class="b7"><span class="ci">%s</span><b>Legenda</b>Posição, fundo, borda.</div>
  <div class="b7"><span class="ci">%s</span><b>Análises</b>Curvas, estatística, anotações.</div>
  <div class="b7"><span class="ci">%s</span><b>Exportação</b>Formato, tamanho, qualidade.</div>
</div>
<div class="col2" style="margin-top:5mm">
  <div>%s</div>
  <div>
    <h3>%s Edite direto no gráfico</h3>
    <ul class="tick">
      <li><b>Clique no título</b> (ou nos títulos dos eixos): abre uma caixa com o texto, o negrito e o tamanho.</li>
      <li><b>Arraste a legenda</b> e puxe a alça da direita para mudar a largura.</li>
      <li><b>Caixas de texto, formas e figuras</b>: arraste e estique; as setas do teclado movem de 2 em 2 (com Shift, de 10 em 10).</li>
      <li><b>Trave um bloco</b> (<i>Congelar</i>) para manter o mesmo estilo em todas as abas.</li>
    </ul>
    %s
  </div>
</div>''' % (ic('db'), ic('chart'), ic('palette'), ic('text'), ic('legend'), ic('tools'), ic('download'), fig('31_caixas_moveis.png', 'Caixas e figuras se movem com o mouse.', ''),
    ic('mouse'), nota('atalho', 'Atalho:', 'em qualquer campo, o botão <b>Restaurar tudo</b> (topo) devolve o padrão. Nada é gravado nos seus dados.')))

# ============ 7. 3D: planilha -> superficie ==================================================================================================
pagina('Gráficos 3D e mapas', 'cube', 'Do Excel ao 3D: a planilha em matriz X, Y, Z', '''
<div class="col2">
  <div>
    <p class="lead">Para o <b>eixo Z</b> (a altura ou a cor), organize a planilha como uma <b>matriz</b>: a 1ª coluna traz os valores de Y, o cabeçalho das outras colunas traz os valores de X, e as células são o Z.</p>
    <div class="tabela-demo grande"><table><tr><th>pH \\ Temperatura</th><th>20</th><th>30</th><th>40</th><th>50</th></tr><tr><td><b>4</b></td><td>6,3</td><td>7,7</td><td>11,7</td><td>13,3</td></tr><tr><td><b>5</b></td><td>8,4</td><td>13,1</td><td>24,3</td><td>33,0</td></tr><tr><td><b>6</b></td><td>10,3</td><td>22,9</td><td>46,1</td><td>67,2</td></tr><tr><td><b>7</b></td><td>12,0</td><td>30,7</td><td>60,4</td><td>88,1</td></tr></table></div>
    <div class="trio">
      <div><b>X</b> = cabeçalho das colunas (temperatura)</div><div><b>Y</b> = 1ª coluna (pH)</div><div><b>Z</b> = células (rendimento)</div>
    </div>
    <h3>Três jeitos de usar</h3>
    <ul class="tick"><li><b>Superfície 3D</b>: o Z vira altura <i>e</i> cor.</li><li><b>Mapa de cor</b>: visto de cima, só cores (gradiente contínuo).</li><li><b>Barras 3D / Dispersão 3D</b>: uma barra ou ponto por célula.</li></ul>
  </div>
  <div>
    %s
    %s
  </div>
</div>''' % ('<div class="duas-img">' + fig('m16_superficie_matriz.png', 'Superfície 3D', '') + fig('d3_mapa_cor.png', 'O mesmo dado como mapa de cor', '') + '</div>',
    nota('dica', 'Tabela longa também vale.', 'Se os seus dados vêm como três colunas (X, Y, Z), escolha <b>Formato da tabela: Longo</b>. Pontos que formam uma grade viram superfície; os demais, dispersão 3D.')))

# ============ 8. girar o 3D ==================================================================================================================
pagina('Gráficos 3D e mapas', 'rotate', 'Gire o gráfico 3D como se estivesse na mão', '''
%s
<div class="trilha">
  <div class="tr1"><span class="n">1</span><b>Arraste</b><br>Clique no gráfico e arraste em qualquer direção: a rotação é circular. Solte e a imagem completa volta nítida.</div>
  <div class="tr1"><span class="n">2</span><b>⟲ Girar</b><br>Giro contínuo, ótimo para apresentar. Clique de novo para parar (o ângulo fica gravado).</div>
  <div class="tr1"><span class="n">3</span><b>Vistas prontas</b><br><i>Frente</i>, <i>Lado</i>, <i>Topo</i> e <i>Padrão</i> levam direto ao ângulo mais útil.</div>
  <div class="tr1"><span class="n">4</span><b>Perspectiva · Grade</b><br>Dois botões ligam/desligam a perspectiva e a grade das paredes. A leitura mostra o ângulo atual.</div>
</div>
%s
<div class="col2" style="margin-top:3mm">
  <div class="cartao"><h3>%s Quando soltar, o ângulo é guardado</h3><p>Os campos <b>Giro da vista</b> e <b>Altura do olhar</b> acompanham o que você fez. Dá para digitar o valor exato para repetir a mesma vista em outro gráfico.</p></div>
  <div class="cartao"><h3>%s Também editável</h3><p><b>Profundidade</b> do eixo Y, <b>perspectiva</b>, <b>altura</b> do eixo Z, caixa (paredes/piso), <b>grade</b> e sua grossura, arestas, traços e o estilo de cada eixo.</p></div>
</div>''' % (fig('barra_giro.png', 'A barra de giro (aparece sozinha nos gráficos 3D).', 'barra'), fig('rotacao_6_angulos.png', 'A mesma superfície em seis ângulos de uma volta completa — os números dos eixos nunca se sobrepõem.', 'larga'), ic('rotate'), ic('sliders')))

# ============ 9. Atlas de paletas ============================================================================================================
def grad(c):
    if not c: return 'transparent'
    return 'linear-gradient(90deg,%s)' % ','.join('%s %d%%' % (x, round(i * 100 / max(len(c) - 1, 1))) for i, x in enumerate(c))
def atlas(grupos):
    out = ''
    for g in grupos:
        itens = [p for p in PAL if p['grupo'] == g]
        out += '<div class="atl-g"><h4>%s</h4>' % html.escape(g) + ''.join('<div class="atl-i"><i style="background:%s"></i><span>%s</span></div>' % (grad(p['cores']), html.escape(p['rotulo'].split(' (')[0] if p['nome'] != 'cinabro' else 'Cinabro (séries)')) for p in itens) + '</div>'
    return out
pagina('Cores e paletas', 'palette', 'As 32 paletas do Cinabro', '''
<p class="lead">Todas funcionam nos gradientes do <b>eixo Z</b> (3D, mapa de cor, mapa de calor, mapas geográficos) <b>e</b> como cor automática das séries. Cada uma aparece com a sua amostra de cor.</p>
<div class="atlas">%s</div>
%s''' % (atlas(['Do Cinabro', 'Degradês', 'Divergentes', 'Contínuas (viridis)', 'Científicas']),
   nota('dica', 'Como escolher?', '<b>Degradês</b> para valores que só crescem (dose, temperatura). <b>Divergentes</b> quando há um centro que importa (zero, média): o centro claro cai em zero sozinho quando os dados passam por zero. <b>Cividis</b> é a mais segura para daltonismo. <b>Viridis, Magma e Turbo</b> dão contraste forte em superfícies.')))

# ============ 10. escolher e editar o gradiente ==============================================================================================
pagina('Cores e paletas', 'palette', 'Escolha e afine o gradiente', '''
<div class="col2">
  <div>
    %s
    <ol class="lista-passos" style="margin-top:3mm">
      <li>No bloco <b>Dados</b>, achei <b>Cores do gradiente (eixo Z)</b>.</li>
      <li>Clique e <b>digite para procurar</b> (ex.: <i>viri</i> → Viridis). Cada opção traz a sua amostra.</li>
      <li>Não gostou da direção? Marque <b>Inverter o gradiente</b>.</li>
    </ol>
  </div>
  <div>
    <div class="tres-img">%s%s%s</div>
    <table class="tab-edit">
      <tr><td><b>Faixas de cor</b></td><td>Gradiente liso (vazio) ou em degraus (ex.: 7 faixas).</td></tr>
      <tr><td><b>Escala começa/termina em</b></td><td>Fixa os limites para comparar gráficos entre si.</td></tr>
      <tr><td><b>Valor do centro</b></td><td>Nas divergentes: o ponto neutro (ex.: 0).</td></tr>
      <tr><td><b>As suas cores</b></td><td>Escreva <i>white, gold, red</i> (ou #RRGGBB): vale mais que a paleta.</td></tr>
      <tr><td><b>Barra de cores</b></td><td>Título, intervalo, casas decimais, posição, altura e largura.</td></tr>
    </table>
  </div>
</div>''' % (fig('paleta_aberta.png', 'O seletor: grupos, nomes e amostras.', ''), fig('pal_inverter.png', 'Invertido', 'mini3'), fig('pal_faixas.png', 'Em 7 faixas', 'mini3'), fig('pal_divergente_cinabro.png', 'Divergente', 'mini3')))

# ============ 11. Radar e mapa de calor ======================================================================================================
pagina('Gráficos 3D e mapas', 'chart', 'Radar, mapa de calor e mapas', '''
<div class="col3">
  <div class="cartao">%s<h3>Radar</h3><p>1ª coluna = nome de cada item; as outras colunas numéricas (3 ou mais) são os eixos. Ótimo para comparar <b>protótipos, materiais, notas</b>.</p>
  <p class="peq">Edite: anéis, escala, grade (círculo/polígono), opacidade, pontos, legenda.</p></div>
  <div class="cartao">%s<h3>Mapa de calor</h3><p>Linhas × colunas coloridas pelo valor. Escreva os números nas células, <b>normalize</b> por linha (nota z) e <b>reordene por semelhança</b>.</p>
  <p class="peq">Divergentes + nota z: o centro cai em zero sozinho.</p></div>
  <div class="cartao">%s<h3>Mapas</h3><p>Valor por <b>país</b> (nome em inglês) ou por <b>estado</b> (sigla). Projeção, recorte e nomes escritos nos locais.</p>
  <p class="peq">Cores: as mesmas 32 paletas.</p></div>
</div>
%s''' % (fig('m20_radar.png'), fig('pal_divergente.png'), fig('g18_mapa_brasil.png'),
   nota('exemplo', 'Exemplos prontos.', 'No bloco <i>Dados</i>, o menu <b>...ou use um exemplo</b> traz planilhas modelo para cada tipo (radar, superfície, cascata, mapas...). A pasta <b>modelos_csv</b> tem os mesmos arquivos para você copiar a estrutura.')))

# ============ 12. Análises ===================================================================================================================
pagina('Análises e anotações', 'tools', 'Curvas, estatística e anotações', '''
<div class="col2">
  <div>
    <h3>%s Ajuste de curva</h3>
    <p>Na faixa de ações, <b>Ajuste de curva</b>: linear, exponencial, potência, logarítmico, polinomial, loess ou <b>a sua fórmula</b> (ex.: <i>a*x/(b+x)</i>). A equação e o R² aparecem numa <b>caixa de estatística</b> que você move e edita.</p>
    %s
  </div>
  <div>
    <h3>%s Média ± DP, testes e tabelas</h3>
    <p>Traços de média e desvio, barras de erro por coluna, ANOVA, Tukey, Kruskal-Wallis e outras comparações em <b>Tabelas e testes</b>, com tabela pronta para copiar.</p>
    %s
    <h3>%s Anotar</h3>
    <p><b>Texto</b>, <b>Forma</b> (retângulo, elipse, seta, polígono...) e <b>Figura</b> (PNG/JPEG, ex.: logo). Tudo arrastável, com cor, borda e sombra.</p>
  </div>
</div>''' % (ic('chart'), fig('18_ajuste_resultado.png', 'Curva ajustada, com equação e R².', ''), ic('table'), fig('g11_media_desvio.png', 'Média e desvio padrão.', ''), ic('text')))

# ============ 13. Abas / projetos ============================================================================================================
pagina('Seu trabalho', 'folder', 'Abas e projetos: não perca nada', '''
<div class="col3">
  <div class="cartao">%s<h3>Abas</h3><p>Cada aba é um gráfico completo (dados + ajustes). <b>+ Nova aba</b>, <b>Duplicar</b> (copia dados e configuração) e <b>Renomear</b>.</p></div>
  <div class="cartao">%s<h3>Salvar / Abrir projeto</h3><p>Um arquivo <b>.cinabro</b> guarda os <b>dados e a configuração</b> juntos: mande para um colega e ele abre igualzinho, ou volte a ele daqui a um mês.</p></div>
  <div class="cartao">%s<h3>Retomar de onde parou</h3><p>O Cinabro guarda sozinho o último gráfico. Ao abrir de novo ele pergunta se você quer <b>Retomar</b>.</p></div>
</div>
<div class="col2" style="margin-top:5mm">
  <div>%s</div>
  <div>
    <h3>%s Modelo e código</h3>
    <p>No fim da página, <b>Modelo, configuração e código</b> mostra o script R equivalente ao gráfico: para repetir em lote, auditar ou aprender.</p>
    %s
  </div>
</div>''' % (ic('layers'), ic('folder'), ic('rotate'), fig('27_cabecalho_abas.png', 'As abas no alto da tela.', ''), ic('wrench'),
   nota('dica', 'Boa prática.', 'Salve um <b>.cinabro</b> por gráfico importante. Para refazer um relatório com dados novos, abra o projeto e carregue o CSV atualizado.')))

# ============ 14. Dashboard ==================================================================================================================
pagina('Seu trabalho', 'dash', 'Dashboard: tudo numa página', '''
<div class="col2">
  <div>%s</div>
  <div>
    <ol class="lista-passos">
      <li>Deixe cada gráfico numa <b>aba</b>.</li>
      <li>Clique em <b>Dashboard</b> (faixa de ações) e marque as abas que entram.</li>
      <li>O <b>editor em tela cheia</b> abre: arraste e estique os blocos, edite os textos dos <b>destaques</b> e dos <b>números-chave</b>, troque a <b>identidade</b> (cores e logo da empresa).</li>
      <li>Baixe em <b>PDF</b> (A4, vetorial) ou <b>HTML</b> (abre em qualquer navegador).</li>
    </ol>
    %s
    %s
  </div>
</div>''' % (fig('dash_exemplo.png', 'Exemplo: dashboard de uma história de ativos de personal care (dados fictícios).', ''),
   nota('dica', 'Já vem com análise.', 'O Cinabro escreve frases e números-chave a partir dos seus dados (variação, máximo, correlações...). Você reescreve o que quiser.'),
   nota('atencao', 'PDF pelo app:', 'usa o Edge ou o Chrome do computador. Se o seu não for encontrado, abra o HTML e imprima em PDF pelo navegador.')))

# ============ 15. Exportar ===================================================================================================================
pagina('Seu trabalho', 'download', 'Exporte para o Word, PowerPoint e revistas', '''
<div class="col2">
  <div>
    <table class="tab-edit">
      <tr><td><b>PNG</b></td><td>Imagem comum, para slides e e-mail.</td></tr>
      <tr><td><b>PDF · SVG · EMF</b></td><td>Vetoriais: não perdem qualidade ao ampliar. O <b>EMF</b> cola no Word/PowerPoint e continua editável.</td></tr>
      <tr><td><b>TIFF · JPEG</b></td><td>Para revistas e fotos.</td></tr>
    </table>
    <ul class="tick" style="margin-top:3mm"><li><b>Tamanho da página</b> em cm, mm ou polegadas (bloco <i>Exportação</i>). Com a <b>caixa fixa</b>, todos os gráficos saem do mesmo tamanho.</li><li><b>Resolução</b> em dpi: 300 para impressão, 150 para tela.</li><li>Botões <b>Baixar PNG</b> e <b>Baixar PDF</b> ficam ao lado do gráfico.</li><li>Estilos prontos (topo): <i>Publicação</i> (artigo) e <i>Apresentação</i> (slides).</li></ul>
  </div>
  <div>%s%s</div>
</div>''' % (fig('26_exportar.png', 'Bloco Exportação.', 'alto'), nota('dica', 'Para artigos:', 'escolha o estilo <b>Publicação</b>, tamanho de coluna da revista e baixe em PDF ou TIFF.')))

# ============ 16. Idiomas ====================================================================================================================
pagina('Seu trabalho', 'globe', 'Português, English e Español', '''
<div class="col2">
  <div>
    <p class="lead">O seletor de idioma, no topo, troca <b>toda a tela e o gráfico</b>: menus, ajudas, avisos, nomes dos eixos criados pelo programa e frases do dashboard.</p>
    <div class="idiomas"><span>Português (BR)</span><span>English</span><span>Español</span></div>
    <ul class="tick"><li>A troca <b>não perde o trabalho</b>: dados, ajustes e gráfico continuam onde estavam.</li><li>A 1ª vez de cada idioma leva alguns segundos; depois é imediato.</li><li>O último idioma fica lembrado no navegador.</li><li>O seu texto (títulos, nomes de séries) <b>não é traduzido</b>: o que você escreveu continua igual.</li></ul>
  </div>
  <div>%s%s</div>
</div>''' % (fig('topo_barra.png', 'Seletor de idioma, estilos prontos e projetos: tudo na barra do topo.', ''), nota('exemplo', 'Equipe global?', 'Abra o mesmo <b>.cinabro</b> em English ou Español para o colega de outro país: o gráfico é o mesmo, a tela fala a língua dele.')))

# ============ 17. FAQ ========================================================================================================================
pagina('Dúvidas', 'help', 'Dúvidas frequentes', '''
<div class="faq">
  <div class="q"><b>%s Meus dados saem do computador?</b><br>Não. O Cinabro roda local; os arquivos não são enviados a nenhum servidor. A internet só é usada na 1ª abertura, para baixar pacotes.</div>
  <div class="q"><b>%s Preciso saber programar?</b><br>Não. Tudo é feito na tela. O script R equivalente fica disponível se você quiser (e para auditoria).</div>
  <div class="q"><b>%s Posso usar o logo e as cores da minha empresa?</b><br>Sim: no editor do dashboard (identidade institucional), na paleta das séries e nos gradientes (<i>As suas cores</i>).</div>
  <div class="q"><b>%s Como repito o gráfico com dados novos?</b><br>Abra o <i>.cinabro</i> e carregue o CSV novo (ou troque os dados mantendo os ajustes com os blocos <i>Congelar</i>).</div>
  <div class="q"><b>%s Posso editar depois no PowerPoint/Illustrator?</b><br>Sim: exporte em <b>SVG</b> ou <b>EMF</b>; PDF vetorial também abre no Illustrator/Inkscape.</div>
  <div class="q"><b>%s Quantos pontos aguenta?</b><br>Dezenas de milhares: a prévia usa uma versão reduzida para ficar rápida; o arquivo final sai completo.</div>
  <div class="q"><b>%s Roda no Mac ou Linux?</b><br>O programa é em R, então sim, abrindo pelo R. O atalho e o <i>abrir_app.bat</i> são para Windows.</div>
  <div class="q"><b>%s De quem é e posso compartilhar?</b><br>Licença MIT: uso livre, mantendo o aviso de autoria (Leonardo Moreira). Veja NOTICE.md para as paletas e fontes.</div>
</div>''' % ((ic('check'),) * 8))

# ============ 18. Solução de problemas =======================================================================================================
pagina('Dúvidas', 'wrench', 'Algo não saiu como esperado? Veja aqui', '''
<table class="sp">
  <tr><th>O que acontece</th><th>Por quê</th><th>O que fazer</th></tr>
  <tr><td>%s O programa não abre</td><td>Pasta dentro do ZIP, ou falta a internet na 1ª vez.</td><td>Extraia o ZIP; confira a internet (na empresa, informe o proxy como a mensagem mostra) e abra de novo.</td></tr>
  <tr><td>%s Aviso <b>Algo precisa de ajuste</b></td><td>Uma combinação de campos não faz sentido para o gráfico.</td><td>Leia a mensagem: ela diz o campo e o que mudar. A lista <i>O que você mudou</i> mostra o último ajuste feito.</td></tr>
  <tr><td>%s O 3D pede “números nos dois eixos”</td><td>A 1ª coluna ou o cabeçalho têm texto.</td><td>Use números em Y (1ª coluna) e X (cabeçalhos), ou o <b>mapa de calor</b> para nomes.</td></tr>
  <tr><td>%s Acentos aparecem estranhos</td><td>Codificação do CSV.</td><td>O Cinabro tenta UTF-8 e o Excel em português; se persistir, salve como <i>CSV UTF-8</i>.</td></tr>
  <tr><td>%s O eixo X virou data (ou não virou)</td><td>O formato da 1ª coluna.</td><td>Use datas como <i>01/03/2024</i>; para números simples, use ponto ou vírgula decimal.</td></tr>
  <tr><td>%s As cores parecem invertidas</td><td>O sentido da paleta (ex.: divergente RdBu: vermelho = menor).</td><td>Marque <b>Inverter o gradiente</b> ou escolha outra paleta.</td></tr>
  <tr><td>%s O PDF do dashboard não sai</td><td>Não achei o Edge/Chrome.</td><td>Abra o <b>HTML</b> do dashboard e use Imprimir → Salvar como PDF.</td></tr>
  <tr><td>%s A tela ficou lenta</td><td>Dados muito grandes ou muitas abas.</td><td>Use <b>Atualizar agora</b> (desligue <i>Atualizar sozinho</i>) enquanto ajusta; feche abas que não usa.</td></tr>
</table>''' % ((ic('warn', 'sm'),) * 8))

# ============ 19. Cola rápida ================================================================================================================
pagina('Dúvidas', 'star', 'Cola rápida', '''
<div class="col3">
  <div class="cartao"><h3>%s Mouse</h3><ul class="tick"><li>Clicar no título → editar texto</li><li>Arrastar a legenda / caixas</li><li>Arrastar o 3D → girar</li><li>Duplo clique no nome de um mapa → posição automática</li></ul></div>
  <div class="cartao"><h3>%s Teclado</h3><ul class="tick"><li>Setas: mover caixa 2 px</li><li>Shift + setas: 10 px</li><li>Esc: fecha janelas e buscas</li></ul></div>
  <div class="cartao"><h3>%s Botões do topo</h3><ul class="tick"><li><b>Salvar projeto</b> (.cinabro)</li><li><b>Abrir projeto</b></li><li><b>Restaurar tudo</b></li><li><b>Sair</b></li></ul></div>
</div>
<div class="col3" style="margin-top:5mm">
  <div class="cartao"><h3>%s 3D</h3><ul class="tick"><li>Arraste · ⟲ Girar · Frente/Lado/Topo/Padrão</li><li>Perspectiva · Grade</li><li>Profundidade, altura Z, caixa</li></ul></div>
  <div class="cartao"><h3>%s Cores</h3><ul class="tick"><li>32 paletas, com busca e amostra</li><li>Inverter · Faixas · Centro</li><li>As suas cores: <i>white, gold, red</i></li></ul></div>
  <div class="cartao"><h3>%s Entrega</h3><ul class="tick"><li>PNG · PDF · SVG · EMF · TIFF</li><li>Dashboard → PDF / HTML</li><li>Idioma: PT · EN · ES</li></ul></div>
</div>
<div class="fim">%s<div><b>Cinabro</b> · <i>A punctis ad curvam: ubi data colorem accipiunt.</i><br>Dos pontos à curva: onde os dados ganham cor.</div></div>''' % (ic('mouse'), ic('table'), ic('folder'), ic('cube'), ic('palette'), ic('download'), ic('chart', '', '14mm')))

# ====================== montagem ====================================================================================================================
JS = '''<script>
window.addEventListener('load', function () {
  document.querySelectorAll('.pg').forEach(function (s) {
    var c = s.querySelector('.corpo'), lim = s.getBoundingClientRect().top + s.clientHeight - 17 * 3.78, z = 1.5; c.style.zoom = z;
    while (z > 0.7 && c.getBoundingClientRect().bottom > lim) { z = Math.round((z - 0.025) * 1000) / 1000; c.style.zoom = z; }
  });
  document.body.setAttribute('data-pronto', '1');
});
</script>'''
CSS = open(os.path.join(AQUI, 'guia.css'), encoding='utf-8').read()
total = len(paginas) + 1
corpo = CAPA
secoes = []
for i, (sec, ico, tit, cor, cls) in enumerate(paginas, start=2):
    corpo += '''<section class="pg %s"><header><span class="sec">%s %s</span><span class="pnum">%d / %d</span></header>
<h2><span class="hi">%s</span>%s</h2><div class="corpo">%s</div><footer>Cinabro · Guia visual</footer></section>''' % (cls, '', sec, i, total, ic(ico), tit, cor)
open(os.path.join(RAIZ, 'manual', 'guia_visual.html'), 'w', encoding='utf-8').write(
    '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>Cinabro — Guia visual</title><style>%s</style></head><body>%s%s</body></html>' % (CSS, corpo, JS))
print('guia_visual.html:', total, 'páginas')
