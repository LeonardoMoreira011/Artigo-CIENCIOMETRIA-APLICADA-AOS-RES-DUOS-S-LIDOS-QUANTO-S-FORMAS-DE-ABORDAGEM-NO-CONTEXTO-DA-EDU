# =============================================================================
#  01_config.R  —  TODOS OS PARÂMETROS EDITÁVEIS DO GRÁFICO
# =============================================================================
#  Como usar:
#   - Edite os valores aqui OU mude no console/script com atribuição direta:
#       cfg$eixo_x$inicio <- 0
#   - Cada parâmetro tem: descrição, "OPÇÕES:" (valores aceitos) e "EX.:".
#   - No console:  ajuda()            -> lista os blocos
#                  ajuda("eixo_x")    -> mostra todos os parâmetros do bloco
#                  galeria()          -> PDF visual com símbolos, linhas, paletas
#   - Unidades: espessuras, tamanhos de texto, símbolos e ticks em PONTOS (pt),
#     como no Origin (1 pt = 1/72 polegada). Tamanho da figura em cm.
#   - Números: ponto decimal SEMPRE (1.5). Nunca vírgula.
#   - NULL significa "automático".
# =============================================================================

cfg <- list()

# -----------------------------------------------------------------------------
# DADOS — leitura do CSV
# -----------------------------------------------------------------------------
cfg$dados <- list(
  # separador: caractere que separa as colunas do CSV.
  #   OPÇÕES: "auto" | "," | ";" | "\t" (tabulação) | "|"
  #   EX.: cfg$dados$separador <- ";"
  separador = "auto",

  # decimal_virgula: o arquivo usa vírgula como decimal (CSV de Excel em português)?
  #   O resultado é SEMPRE convertido para ponto decimal (1,5 -> 1.5).
  #   OPÇÕES: "auto" (detecta) | TRUE | FALSE
  #   EX.: cfg$dados$decimal_virgula <- TRUE
  decimal_virgula = "auto",

  # codificacao: codificação de texto do arquivo (afeta acentos dos cabeçalhos).
  #   OPÇÕES: "auto" | "UTF-8" | "latin1"
  #   EX.: cfg$dados$codificacao <- "latin1"
  codificacao = "auto",

  # cabecalho: a primeira linha (após pular_linhas) contém os nomes das colunas?
  #   OPÇÕES: TRUE | FALSE (colunas viram V1, V2, ...)
  cabecalho = TRUE,

  # pular_linhas: quantas linhas ignorar no topo do arquivo (comentários, unidades).
  #   OPÇÕES: número inteiro >= 0
  #   EX.: cfg$dados$pular_linhas <- 2
  pular_linhas = 0,

  # valores_ausentes: textos tratados como "sem dado" (NA).
  #   OPÇÕES: vetor de textos
  #   EX.: cfg$dados$valores_ausentes <- c("", "NA", "-", "n.d.")
  valores_ausentes = c("", "NA", "NaN", "-", "--", "#N/D", "#N/A", "#DIV/0!"),

  # relatorio: imprime no console o relatório de leitura (colunas, tipos, NAs, avisos).
  #   OPÇÕES: TRUE | FALSE
  relatorio = TRUE
)

# -----------------------------------------------------------------------------
# GRAFICO — tipo e colunas usadas
# -----------------------------------------------------------------------------
cfg$grafico <- list(
  # tipo: tipo de gráfico.
  #   OPÇÕES: "pontos" | "linha" | "linha_pontos" | "area" | "area_empilhada" |
  #           "barras" | "pizza" | "histograma" | "densidade" | "ecdf" | "boxplot"
  #   EX.: cfg$grafico$tipo <- "boxplot"
  tipo = "linha_pontos",

  # coluna_x: coluna do eixo X (nome entre aspas ou número da coluna).
  #   Em "barras" e "pizza" é a coluna das CATEGORIAS. Ignorada em histograma,
  #   densidade, ecdf e boxplot.
  #   OPÇÕES: número | "nome da coluna"
  #   EX.: cfg$grafico$coluna_x <- "Tempo (s)"
  coluna_x = 1,

  # colunas_y: colunas plotadas (cada uma vira uma série / caixa / fatia).
  #   NULL = todas as colunas numéricas, exceto a coluna_x.
  #   Em "pizza" usa só a primeira.
  #   OPÇÕES: NULL | vetor de nomes ou números
  #   EX.: cfg$grafico$colunas_y <- c("Amostra A", "Amostra C")
  colunas_y = NULL,

  # coluna_grupo: (formato "longo") coluna categórica que separa os dados em grupos.
  #   Usada em boxplot, histograma, densidade e ecdf: os valores de colunas_y[1]
  #   são divididos pelos grupos desta coluna.
  #   OPÇÕES: NULL | "nome da coluna"
  #   EX.: cfg$grafico$coluna_grupo <- "Tratamento"
  coluna_grupo = NULL,

  # ordem_itens: ordem das séries/categorias/caixas (nomes). NULL = ordem do arquivo.
  #   OPÇÕES: NULL | vetor de nomes
  #   EX.: cfg$grafico$ordem_itens <- c("Controle", "Dose 1", "Dose 2")
  ordem_itens = NULL
)

# -----------------------------------------------------------------------------
# CORES — paletas, gradiente de 2 cores e mapa de cor
# -----------------------------------------------------------------------------
cfg$cores <- list(
  # paleta: cores atribuídas automaticamente às séries, em sequência
  #   (como o "incremento" de cor). Veja todas com mostrar_paletas().
  #   OPÇÕES: "classico" | "okabe_ito" (segura p/ daltônicos) | "viridis" |
  #           "magma" | "plasma" | "cividis" | "cinza" | "tableau" |
  #           "brewer_Set1" | "brewer_Dark2" | "brewer_Paired" | (qualquer
  #           "brewer_<nome>" do ColorBrewer) | "personalizada"
  #   EX.: cfg$cores$paleta <- "okabe_ito"
  paleta = "classico",

  # personalizada: suas cores, usadas quando paleta = "personalizada".
  #   OPÇÕES: vetor de cores (nome, "#RRGGBB", "#RRGGBBAA" ou rgb(…))
  #   EX.: cfg$cores$personalizada <- c("#003F5C", "#BC5090", "#FFA600")
  personalizada = c("#003F5C", "#BC5090", "#FFA600", "#58508D", "#FF6361"),

  # preenchimento: tipo de preenchimento de barras, áreas, caixas, violinos,
  #   fatias e histogramas.
  #   OPÇÕES: "solido" | "gradiente" (2 cores: cor da série -> gradiente_cor2)
  #   EX.: cfg$cores$preenchimento <- "gradiente"
  preenchimento = "solido",

  # gradiente_cor2: segunda cor do gradiente (a primeira é a cor da série).
  #   Pode ser definida por série em cfg$series[["nome"]]$cor2.
  #   OPÇÕES: qualquer cor
  #   EX.: cfg$cores$gradiente_cor2 <- "white"
  gradiente_cor2 = "white",

  # gradiente_direcao: direção da transição de cor dentro de cada elemento.
  #   "vertical" = cor da série embaixo -> cor2 em cima;
  #   "horizontal" = esquerda -> direita; "diagonal" = canto inferior esq. ->
  #   superior dir.; "radial" = centro em cor2 (clara) -> borda na cor da série.
  #   Em barras/caixas HORIZONTAIS, "vertical" segue o comprimento da barra
  #   (da base para a ponta). Em pizza, o gradiente cobre a pizza inteira.
  #   OPÇÕES: "vertical" | "vertical_invertido" | "horizontal" |
  #           "horizontal_invertido" | "diagonal" | "radial"
  #   EX.: cfg$cores$gradiente_direcao <- "horizontal"
  gradiente_direcao = "vertical",

  # incrementar_simbolo: cada série recebe um símbolo diferente automaticamente.
  #   OPÇÕES: TRUE | FALSE (todas usam o símbolo de serie_padrao$simbolo)
  incrementar_simbolo = TRUE,

  # incrementar_tipo_linha: cada série recebe um tipo de linha diferente.
  #   OPÇÕES: TRUE | FALSE (todas sólidas, salvo definição por série)
  incrementar_tipo_linha = FALSE,

  # mapear_coluna: colore os PONTOS pelo valor de uma coluna numérica
  #   (mapa de cor com barra de cores). Só para tipos com pontos.
  #   OPÇÕES: NULL | "nome da coluna"
  #   EX.: cfg$cores$mapear_coluna <- "Temperatura"
  mapear_coluna = NULL,

  # mapa_cores: cores do mapa (2 = gradiente simples; 3 = baixo, meio, alto).
  #   OPÇÕES: vetor com 2 ou 3 cores
  #   EX.: cfg$cores$mapa_cores <- c("blue", "white", "red")
  mapa_cores = c("#2166AC", "#B2182B"),

  # mapa_ponto_medio: valor do meio quando mapa_cores tem 3 cores. NULL = média.
  #   OPÇÕES: NULL | número
  mapa_ponto_medio = NULL,

  # mapa_limites: limites da escala de cor. NULL = mín e máx dos dados.
  #   OPÇÕES: NULL | c(min, max)
  mapa_limites = NULL,

  # mapa_titulo: título da barra de cores. NULL = nome da coluna; "" = sem título.
  mapa_titulo = NULL
)

# -----------------------------------------------------------------------------
# SERIE_PADRAO — estilo aplicado a todas as séries (sobrescrito por cfg$series)
# -----------------------------------------------------------------------------
cfg$serie_padrao <- list(
  # simbolo: forma do símbolo quando incrementar_simbolo = FALSE.
  #   0-14 = só contorno; 15-20 = sólidos; 21-25 = contorno + preenchimento.
  #   21 círculo, 22 quadrado, 23 losango, 24 triângulo, 25 triângulo invertido.
  #   OPÇÕES: número de 0 a 25 (veja galeria())
  #   EX.: cfg$serie_padrao$simbolo <- 22
  simbolo = 21,

  # tamanho_simbolo_pt: tamanho do símbolo em pt.
  #   OPÇÕES: número > 0      EX.: cfg$serie_padrao$tamanho_simbolo_pt <- 8
  tamanho_simbolo_pt = 6,

  # espessura_borda_pt: espessura do contorno do símbolo em pt.
  #   OPÇÕES: número >= 0
  espessura_borda_pt = 0.8,

  # preenchimento_simbolo: preenchimento dos símbolos 21-25.
  #   OPÇÕES: "serie" (mesma cor da série) | "branco" | "vazio" | qualquer cor
  #   EX.: cfg$serie_padrao$preenchimento_simbolo <- "branco"
  preenchimento_simbolo = "serie",

  # linha_espessura_pt: espessura da linha da série em pt.
  #   OPÇÕES: número > 0      EX.: cfg$serie_padrao$linha_espessura_pt <- 2
  linha_espessura_pt = 1.5,

  # linha_tipo: tipo de traço (quando incrementar_tipo_linha = FALSE).
  #   OPÇÕES: "solid" | "dashed" | "dotted" | "dotdash" | "longdash" |
  #           "twodash" | código hexadecimal, ex.: "44" (4 traço, 4 espaço),
  #           "1343"
  #   EX.: cfg$serie_padrao$linha_tipo <- "dashed"
  linha_tipo = "solid",

  # opacidade: opacidade de linhas e símbolos (1 = opaco, 0 = invisível).
  #   OPÇÕES: número de 0 a 1
  opacidade = 1,

  # opacidade_preenchimento: opacidade de barras, áreas, caixas, fatias.
  #   OPÇÕES: número de 0 a 1      EX.: cfg$serie_padrao$opacidade_preenchimento <- 0.7
  opacidade_preenchimento = 1
)

# -----------------------------------------------------------------------------
# SERIES — estilo individual por série/categoria/caixa (opcional)
# -----------------------------------------------------------------------------
#  Cada item tem o NOME da série (nome da coluna; em pizza, a categoria; em
#  boxplot por grupo, o grupo). Só escreva o que quiser mudar.
#  Parâmetros aceitos por série:
#    cor, cor2 (2ª cor do gradiente), simbolo, tamanho_simbolo_pt,
#    espessura_borda_pt, preenchimento_simbolo, linha_espessura_pt, linha_tipo,
#    opacidade, opacidade_preenchimento,
#    nome_legenda      (texto exibido na legenda),
#    mostrar_na_legenda (TRUE/FALSE — apaga só esta entrada),
#    eixo              ("y1" ou "y2" — eixo Y secundário),
#    coluna_erro       (coluna com erro simétrico ±),
#    coluna_erro_inferior / coluna_erro_superior (erros assimétricos),
#    coluna_erro_x     (erro horizontal ±)
#  EX.:
#    cfg$series[["Amostra A"]] <- list(cor = "#D62728", simbolo = 22,
#                                      nome_legenda = "Amostra A (25 °C)",
#                                      coluna_erro = "Desvio A")
#    cfg$series[["Amostra B"]] <- list(mostrar_na_legenda = FALSE)
cfg$series <- list()

# -----------------------------------------------------------------------------
# LINHAS — opções dos tipos pontos / linha / linha_pontos / area
# -----------------------------------------------------------------------------
cfg$linhas <- list(
  # ligacao: como os pontos são ligados.
  #   OPÇÕES: "reta" | "spline" (curva suave) | "degrau_hv" (horizontal depois
  #           vertical) | "degrau_vh" | "degrau_meio"
  #   EX.: cfg$linhas$ligacao <- "spline"
  ligacao = "reta",

  # preencher_area: preenchimento sob a curva (tipos linha / linha_pontos /
  #   pontos). O tipo "area" usa "ate_zero" se aqui estiver "nenhum".
  #   OPÇÕES: "nenhum" | "ate_zero" | "ate_base" (até o início do eixo Y) |
  #           "proxima_serie" (entre cada série e a seguinte)
  #   EX.: cfg$linhas$preencher_area <- "ate_base"
  preencher_area = "nenhum",

  # opacidade_area: opacidade do preenchimento sob a curva.
  #   OPÇÕES: número de 0 a 1
  opacidade_area = 0.35,

  # linhas_queda: linhas ligando cada ponto ao eixo (drop lines).
  #   OPÇÕES: "nenhuma" | "vertical" | "horizontal" | "ambas"
  linhas_queda = "nenhuma",

  # linhas_queda_tipo / linhas_queda_espessura_pt: estilo das linhas de queda.
  linhas_queda_tipo = "dotted",
  linhas_queda_espessura_pt = 0.75,

  # erro_lado: quais lados das barras de erro desenhar.
  #   OPÇÕES: "ambos" | "superior" | "inferior"
  erro_lado = "ambos",

  # erro_espessura_pt: espessura das barras de erro em pt.
  erro_espessura_pt = 1,

  # erro_chapeu_percentual: largura do "chapéu" da barra de erro, em % da
  #   largura do eixo X. 0 = sem chapéu.
  #   OPÇÕES: número >= 0      EX.: cfg$linhas$erro_chapeu_percentual <- 1.5
  erro_chapeu_percentual = 2,

  # rotulos_dados: escreve o valor ao lado de cada ponto.
  #   OPÇÕES: "nenhum" | "y" | "x" | "xy" | "serie"
  #   EX.: cfg$linhas$rotulos_dados <- "y"
  rotulos_dados = "nenhum",

  # rotulos_casas: casas decimais dos rótulos de dados.
  rotulos_casas = 2,

  # rotulos_tamanho_pt: tamanho do texto dos rótulos de dados.
  rotulos_tamanho_pt = 8,

  # rotulos_deslocamento_pt: distância vertical do rótulo ao ponto (+ acima, - abaixo).
  rotulos_deslocamento_pt = 7
)

# -----------------------------------------------------------------------------
# BARRAS — opções do tipo "barras" (colunas)
# -----------------------------------------------------------------------------
cfg$barras <- list(
  # arranjo: como várias séries são combinadas.
  #   OPÇÕES: "agrupado" | "empilhado" | "empilhado_100" (percentual)
  #   EX.: cfg$barras$arranjo <- "empilhado"
  arranjo = "agrupado",

  # orientacao: OPÇÕES: "vertical" (colunas) | "horizontal" (barras deitadas).
  #   Em "horizontal", eixo_x continua sendo o eixo das CATEGORIAS (fica na
  #   vertical) e eixo_y o dos VALORES (fica na horizontal).
  orientacao = "vertical",

  # largura: fração do espaço de cada categoria ocupada pelas barras
  #   (espaço entre grupos = 1 - largura).
  #   OPÇÕES: número de 0.05 a 1      EX.: cfg$barras$largura <- 0.6
  largura = 0.8,

  # sobreposicao: sobreposição entre barras vizinhas do mesmo grupo
  #   (só "agrupado"). 0 = lado a lado; 0.5 = metade sobreposta; negativo = espaço.
  #   OPÇÕES: número de -0.5 a 0.9
  sobreposicao = 0,

  # contorno_cor / contorno_espessura_pt / contorno_tipo: borda das barras.
  #   OPÇÕES cor: cor | "serie" | NA (sem contorno)
  contorno_cor = "black",
  contorno_espessura_pt = 0.75,
  contorno_tipo = "solid",

  # linha_base: valor de onde as barras partem.
  #   OPÇÕES: número      EX.: cfg$barras$linha_base <- 100
  linha_base = 0,

  # rotulos_valor: escrever o valor em cada barra.
  #   OPÇÕES: TRUE | FALSE
  rotulos_valor = FALSE,

  # rotulos_posicao: OPÇÕES: "fora" (acima da barra) | "dentro" (no topo, por
  #   dentro) | "centro"
  rotulos_posicao = "fora",

  # rotulos_casas / rotulos_tamanho_pt / rotulos_cor: formato dos rótulos.
  rotulos_casas = 1,
  rotulos_tamanho_pt = 8,
  rotulos_cor = "black",

  # erro_espessura_pt / erro_chapeu: barras de erro (definidas por série com
  #   coluna_erro). erro_chapeu = fração da largura da barra.
  erro_espessura_pt = 0.75,
  erro_chapeu = 0.4
)

# -----------------------------------------------------------------------------
# PIZZA — opções do tipo "pizza" (e rosca)
# -----------------------------------------------------------------------------
cfg$pizza <- list(
  # angulo_inicial: onde começa a 1ª fatia, em graus (0 = 12 h; 90 = 3 h).
  #   OPÇÕES: número      EX.: cfg$pizza$angulo_inicial <- 90
  angulo_inicial = 0,

  # sentido: OPÇÕES: "horario" | "anti_horario"
  sentido = "horario",

  # angulo_total: abertura total da pizza em graus (360 = completa; 180 = meia).
  #   OPÇÕES: número de 1 a 360
  angulo_total = 360,

  # raio_furo: furo central (rosca), como fração do raio. 0 = pizza cheia.
  #   OPÇÕES: número de 0 a 0.9      EX.: cfg$pizza$raio_furo <- 0.5
  raio_furo = 0,

  # explodir: categorias destacadas (puxadas para fora).
  #   OPÇÕES: NULL | vetor de nomes de categorias
  #   EX.: cfg$pizza$explodir <- c("Ferro")
  explodir = NULL,

  # deslocamento_explosao: distância das fatias destacadas, em % do raio.
  deslocamento_explosao = 10,

  # rotulos: o que escrever em cada fatia (pode combinar).
  #   OPÇÕES: vetor com "categoria", "valor", "percentual"  |  character(0) = nada
  #   EX.: cfg$pizza$rotulos <- c("percentual")
  rotulos = c("categoria", "percentual"),

  # rotulos_separador: separador entre as partes do rótulo.
  #   OPÇÕES: "\n" (quebra de linha) | " " | " - " | etc.
  rotulos_separador = "\n",

  # rotulos_posicao: OPÇÕES: "fora" | "dentro" | "borda"
  rotulos_posicao = "fora",

  # rotulos_distancia: distância do rótulo ao centro, em fração do raio
  #   (usada em "fora"; ~1.25 fica logo fora da pizza).
  rotulos_distancia = 1.25,

  # linha_guia: liga rótulos "fora" à fatia.  OPÇÕES: TRUE | FALSE
  linha_guia = TRUE,

  # rotulos_casas: casas decimais de valor e percentual.
  rotulos_casas = 1,

  # rotulos_tamanho_pt / rotulos_cor: OPÇÕES cor: cor | "auto" (preto/branco
  #   conforme o fundo, para rótulos "dentro").
  rotulos_tamanho_pt = 9,
  rotulos_cor = "auto",

  # ocultar_rotulo_abaixo: não escreve rótulo em fatias menores que este %.
  ocultar_rotulo_abaixo = 0,

  # agrupar_abaixo: junta fatias menores que este % em uma só.
  #   OPÇÕES: número (0 = não agrupa)      EX.: cfg$pizza$agrupar_abaixo <- 3
  agrupar_abaixo = 0,
  nome_agrupado = "Outros",

  # contorno_cor / contorno_espessura_pt: borda das fatias.
  contorno_cor = "white",
  contorno_espessura_pt = 1
)

# -----------------------------------------------------------------------------
# DISTRIBUICAO — histograma, densidade e ecdf
# -----------------------------------------------------------------------------
cfg$distribuicao <- list(
  # largura_classe: largura de cada barra do histograma. NULL = automático.
  #   OPÇÕES: NULL | número > 0      EX.: cfg$distribuicao$largura_classe <- 0.5
  largura_classe = NULL,

  # n_classes: número de classes (usado se largura_classe = NULL).
  #   NULL = regra de Sturges.
  n_classes = NULL,

  # inicio_classe: início da primeira classe. NULL = automático.
  inicio_classe = NULL,

  # medida: o que o eixo Y do histograma mostra.
  #   OPÇÕES: "contagem" | "frequencia" (0-1) | "percentual" | "densidade"
  medida = "contagem",

  # curva_densidade: sobrepõe curva de densidade (kernel) ao histograma.
  curva_densidade = FALSE,

  # curva_normal: sobrepõe a curva normal com a média e desvio dos dados.
  curva_normal = FALSE,

  # ajuste_banda: suavização da densidade (1 = padrão; <1 mais detalhada).
  ajuste_banda = 1,

  # espessura_curva_pt: espessura das curvas de densidade / normal / ecdf.
  espessura_curva_pt = 1.5,

  # preencher_densidade: preenche sob a curva no tipo "densidade".
  preencher_densidade = TRUE,
  opacidade_area = 0.35,

  # contorno_cor / contorno_espessura_pt: borda das barras do histograma.
  contorno_cor = "black",
  contorno_espessura_pt = 0.5,

  # opacidade_multiplas: opacidade das barras quando há várias séries
  #   sobrepostas no mesmo histograma (se serie_padrao$opacidade_preenchimento = 1).
  opacidade_multiplas = 0.55,

  # marcas_rug: tracinhos com cada dado junto ao eixo X.
  marcas_rug = FALSE
)

# -----------------------------------------------------------------------------
# BOXPLOT — box, violino, meio box, média ± erro
# -----------------------------------------------------------------------------
cfg$boxplot <- list(
  # variacao: OPÇÕES: "box" | "box_pontos" (dados sobrepostos) | "meio_box"
  #   (meia caixa + dados ao lado) | "violino" | "violino_box" | "media_erro"
  #   EX.: cfg$boxplot$variacao <- "violino_box"
  variacao = "box",

  # orientacao: OPÇÕES: "vertical" | "horizontal" (caixas deitadas; eixo_x
  #   continua sendo o das categorias e eixo_y o dos valores)
  orientacao = "vertical",

  # caixa_percentis: limites inferior e superior da caixa (percentis).
  #   OPÇÕES: c(inferior, superior)      EX.: c(10, 90)
  caixa_percentis = c(25, 75),

  # bigode: critério dos bigodes (whiskers).
  #   OPÇÕES: "tukey" (até 1.5×IQR, coef. editável) | "percentis" |
  #           "min_max" | "desvio_padrao" (média ± DP) | "erro_padrao" |
  #           "ic95" (intervalo de confiança 95% da média)
  bigode = "tukey",

  # bigode_coef: coeficiente do IQR no critério "tukey".
  bigode_coef = 1.5,

  # bigode_percentis: percentis dos bigodes no critério "percentis".
  #   OPÇÕES: c(inferior, superior)      EX.: c(5, 95)
  bigode_percentis = c(5, 95),

  # bigode_lado: OPÇÕES: "ambos" | "superior" | "inferior"
  bigode_lado = "ambos",

  # bigode_chapeu: largura do traço na ponta do bigode (fração da caixa). 0 = sem.
  bigode_chapeu = 0.5,

  # largura: largura da caixa (fração do espaço da categoria).
  largura = 0.5,

  # entalhe: caixa com entalhe (notch) na mediana.  OPÇÕES: TRUE | FALSE
  entalhe = FALSE,

  # mediana / mediana_espessura_pt: linha da mediana.
  mediana = TRUE,
  mediana_espessura_pt = 1.5,

  # media / media_simbolo / media_tamanho_pt / media_preenchimento: símbolo da média.
  media = TRUE,
  media_simbolo = 22,
  media_tamanho_pt = 5,
  media_preenchimento = "white",

  # outliers: mostra os pontos fora dos bigodes.  OPÇÕES: TRUE | FALSE
  outliers = TRUE,
  outliers_simbolo = 4,
  outliers_tamanho_pt = 5,

  # pontos_disposicao: como os dados aparecem em "box_pontos"/"meio_box".
  #   OPÇÕES: "jitter" (espalhados ao acaso) | "coluna" (em fila no centro) |
  #           "enxame" (espalhados sem sobreposição)
  pontos_disposicao = "enxame",
  pontos_largura = 0.3,
  pontos_tamanho_pt = 4,
  pontos_opacidade = 0.6,
  pontos_simbolo = 21,

  # contorno_cor / contorno_espessura_pt: borda das caixas e violinos.
  #   OPÇÕES cor: cor | "serie"
  contorno_cor = "black",
  contorno_espessura_pt = 1,

  # violino_largura / violino_ajuste_banda / violino_cortar: forma do violino.
  violino_largura = 0.8,
  violino_ajuste_banda = 1,
  violino_cortar = TRUE,

  # media_erro_tipo: erro mostrado em "media_erro".
  #   OPÇÕES: "desvio_padrao" | "erro_padrao" | "ic95"
  media_erro_tipo = "desvio_padrao",

  # media_erro_estilo: OPÇÕES: "barra" (coluna + erro) | "ponto" (símbolo + erro)
  media_erro_estilo = "barra",

  # mostrar_n: escreve o número de dados (n) acima de cada caixa.
  mostrar_n = FALSE,

  # semente: semente do sorteio do "jitter" (mesma figura toda vez).
  semente = 123
)

# -----------------------------------------------------------------------------
# EIXO_X — escala, ticks, rótulos, título e linha do eixo horizontal
# -----------------------------------------------------------------------------
cfg$eixo_x <- list(
  # titulo: título do eixo. NULL = nome da coluna; "" = sem título.
  #   Sobrescrito com ^{ }, subscrito com _{ }. Letras gregas: digite direto (σ, μ, Δ).
  #   OPÇÕES: NULL | "texto"
  #   EX.: cfg$eixo_x$titulo <- "Área (m^{2})"   ou   "CO_{2} (ppm)"
  titulo = NULL,

  # inicio / fim: limites do eixo ("From" / "To"). NULL = automático.
  #   OPÇÕES: NULL | número      EX.: cfg$eixo_x$inicio <- 0; cfg$eixo_x$fim <- 100
  inicio = NULL,
  fim = NULL,

  # margem_percentual: espaço extra além de inicio/fim, em % da faixa.
  #   OPÇÕES: número >= 0 (0 = eixo começa exatamente no limite)
  margem_percentual = 0,

  # escala: tipo de escala.
  #   OPÇÕES: "linear" | "log10" | "ln" | "log2" | "reciproco" (1/x) | "raiz"
  #   EX.: cfg$eixo_x$escala <- "log10"
  escala = "linear",

  # inverter: inverte o sentido do eixo (maior valor à esquerda).
  #   OPÇÕES: TRUE | FALSE
  inverter = FALSE,

  # ticks_modo: como os ticks MAIORES são posicionados.
  #   OPÇÕES: "auto" | "incremento" (usa incremento) | "quantidade" (usa
  #           quantidade) | "min_max" (só nos extremos) | "manual" (ticks_manuais)
  #   EX.: cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 20
  ticks_modo = "auto",

  # incremento: distância entre ticks maiores. Em escalas log, conta em
  #   DÉCADAS (1 = a cada potência de 10).
  incremento = NULL,

  # quantidade: número de ticks maiores (modo "quantidade").
  quantidade = NULL,

  # primeiro_tick: posição do primeiro tick maior (modo "incremento").
  #   NULL = no início do eixo.
  primeiro_tick = NULL,

  # ticks_manuais: posições dos ticks (modo "manual").
  #   EX.: cfg$eixo_x$ticks_manuais <- c(0, 25, 60, 100)
  ticks_manuais = NULL,

  # rotulos_manuais: textos no lugar dos números (mesmo tamanho de ticks_manuais).
  #   EX.: cfg$eixo_x$rotulos_manuais <- c("início", "Q1", "pico", "fim")
  rotulos_manuais = NULL,

  # n_menores: quantos ticks menores entre dois maiores. 0 = nenhum.
  #   Em log10 use 8 para marcar 2, 3, …, 9.
  #   OPÇÕES: inteiro >= 0      EX.: cfg$eixo_x$n_menores <- 4
  n_menores = 1,

  # direcao_maiores / direcao_menores: para onde os ticks apontam.
  #   OPÇÕES: "dentro" | "fora" | "ambos" (cruzando o eixo) | "nenhum"
  #   EX.: cfg$eixo_x$direcao_maiores <- "fora"
  direcao_maiores = "dentro",
  direcao_menores = "dentro",

  # comprimento_maiores_pt / comprimento_menores_pt: comprimento dos ticks em pt.
  comprimento_maiores_pt = 5,
  comprimento_menores_pt = 3,

  # espessura_ticks_pt / cor_ticks: espessura (pt) e cor dos ticks.
  espessura_ticks_pt = 1,
  cor_ticks = "black",

  # mostrar_linha / cor_linha / espessura_linha_pt: linha do eixo
  #   (com caixa fechada, a linha é a da caixa: veja cfg$caixa).
  mostrar_linha = TRUE,
  cor_linha = "black",
  espessura_linha_pt = 1,

  # mostrar_rotulos: mostra os números dos ticks.  OPÇÕES: TRUE | FALSE
  mostrar_rotulos = TRUE,

  # casas_decimais: casas decimais fixas nos rótulos. NULL = automático
  #   (sem zeros sobrando à direita).
  #   OPÇÕES: NULL | inteiro >= 0      EX.: cfg$eixo_x$casas_decimais <- 1
  casas_decimais = NULL,

  # notacao: formato dos números.
  #   OPÇÕES: "normal" (1500) | "milhar" (1,500 — vírgula só como separador de
  #           milhar) | "cientifica" (1.5×10³) | "cientifica_E" (1.5E3) |
  #           "potencia10" (10³, ideal para log10) | "percentual" (0.15 -> 15%)
  notacao = "normal",

  # fator_divisao: divide os rótulos por este número (ex.: 1000 para mostrar
  #   em milhares — lembre de indicar no título).
  fator_divisao = 1,

  # prefixo / sufixo: texto antes/depois de cada número (ex.: sufixo = " %").
  prefixo = "",
  sufixo = "",

  # tamanho_rotulos_pt / cor_rotulos / negrito_rotulos / rotacao_rotulos:
  #   aparência dos números. tamanho NULL = cfg$texto$tamanho_base_pt.
  #   rotacao em graus (ex.: 45, 90).
  tamanho_rotulos_pt = NULL,
  cor_rotulos = "black",
  negrito_rotulos = FALSE,
  rotacao_rotulos = 0,

  # distancia_rotulos_pt: distância entre números e eixo, em pt.
  distancia_rotulos_pt = 3,

  # mostrar_titulo / tamanho_titulo_pt / cor_titulo / negrito_titulo /
  # italico_titulo / distancia_titulo_pt: aparência do título do eixo.
  mostrar_titulo = TRUE,
  tamanho_titulo_pt = NULL,
  cor_titulo = "black",
  negrito_titulo = FALSE,
  italico_titulo = FALSE,
  distancia_titulo_pt = 4
)

# -----------------------------------------------------------------------------
# EIXO_Y — mesmos parâmetros do eixo_x (veja ajuda("eixo_x") para detalhes)
# -----------------------------------------------------------------------------
cfg$eixo_y <- list(
  # titulo: NULL = nome da coluna (1 série) ou "Y" (várias); "" = sem título.
  #   EX.: cfg$eixo_y$titulo <- "Tensão (MPa)"
  titulo = NULL,
  # inicio / fim: limites. NULL = automático.  EX.: cfg$eixo_y$fim <- 50
  inicio = NULL,
  fim = NULL,
  # margem_percentual: espaço extra (%).
  margem_percentual = 0,
  # escala: "linear" | "log10" | "ln" | "log2" | "reciproco" | "raiz"
  escala = "linear",
  # inverter: TRUE | FALSE
  inverter = FALSE,
  # ticks_modo: "auto" | "incremento" | "quantidade" | "min_max" | "manual"
  ticks_modo = "auto",
  incremento = NULL,
  quantidade = NULL,
  primeiro_tick = NULL,
  ticks_manuais = NULL,
  rotulos_manuais = NULL,
  # n_menores: ticks menores entre maiores (0 = nenhum)
  n_menores = 1,
  # direcao_maiores / direcao_menores: "dentro" | "fora" | "ambos" | "nenhum"
  direcao_maiores = "dentro",
  direcao_menores = "dentro",
  comprimento_maiores_pt = 5,
  comprimento_menores_pt = 3,
  espessura_ticks_pt = 1,
  cor_ticks = "black",
  mostrar_linha = TRUE,
  cor_linha = "black",
  espessura_linha_pt = 1,
  mostrar_rotulos = TRUE,
  # casas_decimais: NULL | inteiro
  casas_decimais = NULL,
  # notacao: "normal" | "milhar" | "cientifica" | "cientifica_E" | "potencia10" | "percentual"
  notacao = "normal",
  fator_divisao = 1,
  prefixo = "",
  sufixo = "",
  tamanho_rotulos_pt = NULL,
  cor_rotulos = "black",
  negrito_rotulos = FALSE,
  rotacao_rotulos = 0,
  distancia_rotulos_pt = 3,
  mostrar_titulo = TRUE,
  tamanho_titulo_pt = NULL,
  cor_titulo = "black",
  negrito_titulo = FALSE,
  italico_titulo = FALSE,
  distancia_titulo_pt = 4
)

# -----------------------------------------------------------------------------
# EIXO_Y2 — eixo Y secundário (à direita)
# -----------------------------------------------------------------------------
#  Para usar: cfg$eixo_y2$ativo <- TRUE e, no modo "independente", diga quais
#  séries vão para ele:  cfg$series[["Pressão"]] <- list(eixo = "y2")
#  Estilo dos ticks (direção, comprimento, espessura) segue o eixo_y.
cfg$eixo_y2 <- list(
  # ativo: liga o eixo Y secundário.  OPÇÕES: TRUE | FALSE
  ativo = FALSE,

  # modo: "independente" = séries com eixo = "y2" têm escala própria;
  #       "transformado" = mesmo dado em outra unidade: y2 = fator*y + deslocamento
  #   OPÇÕES: "independente" | "transformado"
  modo = "independente",
  fator = 1,
  deslocamento = 0,

  # titulo: título do eixo. NULL = nome da série no y2.
  titulo = NULL,

  # inicio / fim: limites do eixo secundário. NULL = automático.
  inicio = NULL,
  fim = NULL,

  # ticks_modo / incremento / quantidade / ticks_manuais / n_menores: como no eixo_y.
  ticks_modo = "auto",
  incremento = NULL,
  quantidade = NULL,
  ticks_manuais = NULL,
  n_menores = 1,

  # casas_decimais / notacao / prefixo / sufixo: formato dos números.
  casas_decimais = NULL,
  notacao = "normal",
  prefixo = "",
  sufixo = "",

  # cor_eixo: pinta números, título e ticks do eixo secundário.
  #   OPÇÕES: NULL (preto) | "serie" (cor da 1ª série do y2) | qualquer cor
  cor_eixo = "serie"
)

# -----------------------------------------------------------------------------
# CAIXA — moldura do gráfico (caixa fechada), fundo e proporção
# -----------------------------------------------------------------------------
cfg$caixa <- list(
  # fechada: moldura nos 4 lados.  OPÇÕES: TRUE | FALSE (só eixos esquerdo e inferior)
  fechada = TRUE,

  # cor / espessura_pt: cor e espessura (pt) da moldura.
  cor = "black",
  espessura_pt = 1,

  # ticks_espelhados: repete os ticks no topo e à direita (mesma direção e
  #   intervalos dos eixos principais).  OPÇÕES: TRUE | FALSE
  ticks_espelhados = TRUE,

  # rotulos_espelhados: repete também os números no topo e à direita.
  rotulos_espelhados = FALSE,

  # fundo_painel / fundo_pagina: cores de fundo da área de plotagem e da figura.
  #   OPÇÕES: cor | "transparente"
  fundo_painel = "white",
  fundo_pagina = "white",

  # proporcao: altura/largura da área de plotagem. NULL = ocupa o espaço.
  #   OPÇÕES: NULL | número (1 = quadrado; 0.75 = 4:3)
  proporcao = NULL,

  # margens_cm: margens externas c(topo, direita, baixo, esquerda) em cm.
  margens_cm = c(0.3, 0.5, 0.3, 0.3),

  # recortar: esconde o que passar dos limites dos eixos.  OPÇÕES: TRUE | FALSE
  recortar = TRUE
)

# -----------------------------------------------------------------------------
# GRADE — linhas de grade
# -----------------------------------------------------------------------------
cfg$grade <- list(
  # maior_x / maior_y / menor_x / menor_y: liga cada conjunto de grade.
  #   OPÇÕES: TRUE | FALSE      EX.: cfg$grade$maior_y <- TRUE
  maior_x = FALSE,
  maior_y = FALSE,
  menor_x = FALSE,
  menor_y = FALSE,

  # cor_maior / espessura_maior_pt / tipo_maior: estilo da grade maior.
  cor_maior = "grey80",
  espessura_maior_pt = 0.5,
  tipo_maior = "solid",

  # cor_menor / espessura_menor_pt / tipo_menor: estilo da grade menor.
  cor_menor = "grey92",
  espessura_menor_pt = 0.4,
  tipo_menor = "dashed"
)

# -----------------------------------------------------------------------------
# LEGENDA
# -----------------------------------------------------------------------------
cfg$legenda <- list(
  # mostrar: exibe a legenda. "auto" = sim, exceto em boxplot (os nomes já
  #   estão no eixo).  OPÇÕES: "auto" | TRUE | FALSE (apaga a legenda)
  mostrar = "auto",

  # posicao: OPÇÕES: "dentro" | "direita" | "esquerda" | "topo" | "base"
  posicao = "dentro",

  # dentro_x / dentro_y: posição quando "dentro", em fração do painel
  #   (0,0 = canto inferior esquerdo; 1,1 = superior direito).
  #   EX.: cfg$legenda$dentro_x <- 0.95; cfg$legenda$dentro_y <- 0.95
  dentro_x = 0.04,
  dentro_y = 0.96,

  # ancora: qual ponto da legenda fica em (dentro_x, dentro_y).
  #   OPÇÕES: "auto" (= mesmo canto da posição) | c(x, y) entre 0 e 1
  ancora = "auto",

  # titulo: título da legenda. NULL = sem título.
  titulo = NULL,

  # n_colunas: número de colunas de itens.  OPÇÕES: NULL | inteiro
  n_colunas = NULL,

  # inverter_ordem: inverte a ordem dos itens.  OPÇÕES: TRUE | FALSE
  inverter_ordem = FALSE,

  # moldura / cor_moldura / espessura_moldura_pt: borda da caixa da legenda.
  moldura = FALSE,
  cor_moldura = "black",
  espessura_moldura_pt = 0.5,

  # fundo: OPÇÕES: cor | "transparente"
  fundo = "transparente",

  # tamanho_texto_pt / tamanho_titulo_pt: NULL = tamanho base.
  tamanho_texto_pt = NULL,
  tamanho_titulo_pt = NULL,

  # tamanho_chave_pt: tamanho do quadradinho/linha de cada item.
  tamanho_chave_pt = 14,

  # espacamento_pt: espaço vertical entre os itens.
  espacamento_pt = 2
)

# -----------------------------------------------------------------------------
# TITULOS — título e subtítulo do gráfico
# -----------------------------------------------------------------------------
cfg$titulos <- list(
  # titulo / subtitulo: NULL = nenhum.   EX.: cfg$titulos$titulo <- "Ensaio 1"
  titulo = NULL,
  subtitulo = NULL,
  # alinhamento: OPÇÕES: "esquerda" | "centro" | "direita"
  alinhamento = "centro",
  # tamanho_titulo_pt / negrito_titulo / tamanho_subtitulo_pt
  tamanho_titulo_pt = NULL,
  negrito_titulo = TRUE,
  tamanho_subtitulo_pt = NULL
)

# -----------------------------------------------------------------------------
# TEXTO — fonte global
# -----------------------------------------------------------------------------
cfg$texto <- list(
  # fonte: família tipográfica. "sans" = Arial no Windows / Helvetica no Mac.
  #   Veja as instaladas com listar_fontes().
  #   OPÇÕES: "sans" | "serif" | "mono" | "Arial" | "Times New Roman" | ...
  fonte = "sans",

  # tamanho_base_pt: tamanho padrão de todos os textos.
  tamanho_base_pt = 11,

  # cor: cor padrão dos textos.
  cor = "black"
)

# -----------------------------------------------------------------------------
# REFERENCIAS — linhas de referência horizontais/verticais
# -----------------------------------------------------------------------------
#  Lista de linhas. Cada linha: eixo ("x" vertical | "y" horizontal), valor,
#  e opcionalmente cor, espessura_pt, tipo, rotulo, rotulo_tamanho_pt.
#  EX.:
#   cfg$referencias <- list(
#     list(eixo = "y", valor = 0,  cor = "grey40", tipo = "dashed"),
#     list(eixo = "x", valor = 50, cor = "red", rotulo = "limite")
#   )
cfg$referencias <- list()

# -----------------------------------------------------------------------------
# ANOTACOES — textos, setas, faixas destacadas e letra do painel
# -----------------------------------------------------------------------------
cfg$anotacoes <- list(
  # textos: lista de textos em coordenadas dos dados.
  #   Cada item: x, y, texto, e opcional tamanho_pt, cor, negrito, alinhamento
  #   ("esquerda" | "centro" | "direita").
  #   EX.: cfg$anotacoes$textos <- list(list(x = 20, y = 5, texto = "pico"))
  textos = list(),

  # setas: lista de setas. Cada item: x, y (início), x_fim, y_fim, e opcional
  #   cor, espessura_pt, tamanho_ponta_pt.
  setas = list(),

  # faixas: regiões sombreadas. Cada item: eixo ("x" | "y"), de, ate, e
  #   opcional cor, opacidade.
  #   EX.: cfg$anotacoes$faixas <- list(list(eixo = "x", de = 10, ate = 20))
  faixas = list(),

  # letra: letra do painel, ex.: "(a)". NULL = nenhuma.
  letra = NULL,
  # letra_posicao: c(x, y) em fração do painel.  EX.: c(0.03, 0.95)
  letra_posicao = c(0.03, 0.95),
  letra_tamanho_pt = NULL,
  letra_negrito = TRUE
)

# -----------------------------------------------------------------------------
# QUEBRA — quebra (interrupção) do eixo Y
# -----------------------------------------------------------------------------
cfg$quebra <- list(
  # ativo: liga a quebra do eixo Y.  OPÇÕES: TRUE | FALSE
  ativo = FALSE,
  # de / ate: trecho do eixo Y que será omitido.
  #   EX.: cfg$quebra$de <- 20; cfg$quebra$ate <- 80
  de = NULL,
  ate = NULL,
  # proporcao_superior: fração da altura para a parte de cima.
  proporcao_superior = 0.35,
  # espaco_pt: espaço entre as duas partes.
  espaco_pt = 4,
  # marcas: desenha os traços diagonais "//" da quebra.
  marcas = TRUE
)

# -----------------------------------------------------------------------------
# PAINEIS — gráficos empilhados com eixo X fixo (ou Y fixo)
# -----------------------------------------------------------------------------
#  Cada item de 'lista' é um painel e aceita QUALQUER bloco do cfg (grafico,
#  eixo_y, series, cores, legenda, referencias, anotacoes, ...), só com o que
#  muda. O eixo X (vertical) ou Y (horizontal) é o mesmo para todos.
#  EX.:
#   cfg$paineis$ativo <- TRUE
#   cfg$paineis$lista <- list(
#     list(grafico = list(colunas_y = "Sinal A", tipo = "linha"),
#          eixo_y  = list(titulo = "A (V)", inicio = -2, fim = 2)),
#     list(grafico = list(colunas_y = "Sinal B", tipo = "pontos"),
#          eixo_y  = list(titulo = "B (mA)")),
#     list(grafico = list(colunas_y = "Sinal C", tipo = "area"))
#   )
cfg$paineis <- list(
  # ativo: liga o modo painéis.  OPÇÕES: TRUE | FALSE
  ativo = FALSE,

  # direcao: "vertical" = empilhados (X comum) | "horizontal" = lado a lado (Y comum)
  direcao = "vertical",

  # lista: definição de cada painel (veja exemplo acima).
  lista = list(),

  # espaco_pt: espaço entre painéis. 0 = colados (moldura compartilhada).
  espaco_pt = 0,

  # rotulos_eixo_comum: OPÇÕES: "ultimo" (números/título do eixo comum só no
  #   painel de baixo/esquerda) | "todos"
  rotulos_eixo_comum = "ultimo",

  # alternar_lado: alterna os números do eixo NÃO comum entre esquerda/direita
  #   (ou baixo/topo).  OPÇÕES: TRUE | FALSE
  alternar_lado = FALSE,

  # titulo_unico: um só título para o eixo não comum (ex.: "Intensidade (u.a.)").
  #   NULL = um título por painel.
  titulo_unico = NULL,

  # tamanhos: altura (vertical) ou largura (horizontal) relativa de cada painel.
  #   NULL = iguais.      EX.: cfg$paineis$tamanhos <- c(2, 1, 1)
  tamanhos = NULL,

  # ocultar_rotulo_encostado: com painéis colados (espaco_pt < 10), esconde o
  #   número da borda que encostaria no painel vizinho (evita "200" sobre "-2").
  #   OPÇÕES: TRUE | FALSE
  ocultar_rotulo_encostado = TRUE,

  # legenda_unica: junta as legendas de todos os painéis em uma só (fora).
  #   OPÇÕES: TRUE | FALSE (cada painel com a sua, conforme cfg$legenda)
  legenda_unica = FALSE,

  # letras: escreve (a), (b), (c) ... em cada painel.  OPÇÕES: TRUE | FALSE
  letras = TRUE,
  # formato_letra: OPÇÕES: "(a)" | "a)" | "a" | "(A)" | "A" | "(i)"
  formato_letra = "(a)"
)

# -----------------------------------------------------------------------------
# EXPORTACAO — arquivos de saída
# -----------------------------------------------------------------------------
cfg$exportacao <- list(
  # pasta: onde salvar.
  pasta = "saida",

  # nome_arquivo: nome sem extensão. NULL = nome do CSV + tipo do gráfico.
  #   EX.: cfg$exportacao$nome_arquivo <- "figura_3"
  nome_arquivo = NULL,

  # formatos: um ou mais.
  #   OPÇÕES: "png" | "tiff" | "jpeg" | "pdf" | "svg" | "emf" (Word/PowerPoint)
  #   EX.: cfg$exportacao$formatos <- c("png", "pdf", "tiff")
  formatos = c("png", "pdf"),

  # largura / altura / unidade: tamanho final da figura.
  #   OPÇÕES unidade: "cm" | "mm" | "in"
  largura = 12,
  altura = 9,
  unidade = "cm",

  # dpi: resolução das imagens (png, tiff, jpeg). Revistas: 300-600; linhas: 1200.
  dpi = 600,

  # fundo_transparente: OPÇÕES: TRUE | FALSE
  fundo_transparente = FALSE,

  # carimbo_data: acrescenta data e hora ao nome do arquivo.  OPÇÕES: TRUE | FALSE
  carimbo_data = FALSE,

  # sobrescrever: se FALSE e o arquivo existir, cria nome_2, nome_3, ...
  sobrescrever = TRUE
)
