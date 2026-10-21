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
#     (1 pt = 1/72 polegada). Tamanho da figura em cm.
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
  #   "auto" reconhece UTF-8, latin1 (Excel) e UTF-16 ("Texto Unicode" do Excel).
  #   OPÇÕES: "auto" | "UTF-8" | "latin1" | "UTF-16" | "UTF-16LE" | "UTF-16BE"
  #   EX.: cfg$dados$codificacao <- "latin1"

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
  #   OPÇÕES (todas aparecem, desenhadas, em mostrar_paletas()):
  #     Do Cinabro ........... "cinabro" (padrão) | "marca" (azul e verde; as 4 primeiras cores são as mais distintas)
  #     Acessíveis ........... "okabe_ito" | "tol_brilhante" | "tol_vibrante" | "tol_suave" | "tol_alto_contraste" |
  #                            "tol_medio_contraste" | "tol_claro" | "tol_escuro" | "tol_palido"
  #     Qualitativas (Brewer)  "brewer_Set1" | "brewer_Set2" | "brewer_Dark2" | "brewer_Paired" | "brewer_Accent" |
  #                            "brewer_Pastel1" | "brewer_Pastel2" | "brewer_Set3"
  #     Degradês (Brewer) .... "brewer_Blues" | "brewer_Greens" | "brewer_Oranges" | "brewer_Reds" | "brewer_Purples" |
  #                            "brewer_YlGnBu" | "brewer_YlOrRd"
  #     Divergentes (Brewer) . "brewer_RdYlGn" (vermelho-escuro -> verde) | "brewer_Spectral" | "brewer_RdYlBu" |
  #                            "brewer_RdBu" | "brewer_BrBG" | "brewer_PiYG" | "brewer_PRGn"
  #     Contínuas ............ "viridis" | "magma" | "plasma" | "cividis" | "inferno" | "turbo" | "mako" | "rocket"
  #                            (pacote viridisLite) | "cmo_thermal" | "cmo_haline" | "cmo_algae" | "cmo_matter" |
  #                            "cmo_deep" | "cmo_balance" | "cmo_delta" | "cmo_curl" | "crameri_batlow" | "crameri_roma" |
  #                            "crameri_bam" | "crameri_vik" | "crameri_lajolla" | "crameri_bilbao" | "crameri_oslo" |
  #                            "crameri_lapaz" | "crameri_hawaii" | "crameri_tokyo" | "crameri_berlin" |
  #                            "tol_por_do_sol" | "tol_iridescente" | "tol_BuRd" | "cinza"
  #     Outras do ColorBrewer  "brewer_<nome>" (precisa do pacote RColorBrewer)
  #     Sua própria .......... "personalizada" (cores em cfg$cores$personalizada)
  #   As cores vêm de trabalhos com licença livre; os créditos estão em NOTICE.md.
  #   EX.: cfg$cores$paleta <- "okabe_ito"
  paleta = "cinabro",

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

  # simbolos_ordem: quais símbolos usar, na ordem, quando incrementar_simbolo = TRUE (repete se faltar).
  #   NULL = a sequência padrão. Aceita nomes ou números: "circulo" | "quadrado" | "losango" | "triangulo" |
  #   "triangulo_invertido" | "circulo_vazio" | "quadrado_vazio" | "cruz" | "x" | "estrela" | "esfera"
  #   EX.: cfg$cores$simbolos_ordem <- c("quadrado", "circulo")   |   só quadrados: c("quadrado")
  simbolos_ordem = NULL,

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
  # (aceita também o nome: "circulo", "quadrado", "losango", "triangulo", "triangulo_invertido", "estrela", "esfera"...
  #  "esfera" = bolinha com volume (sombreado e brilho), com sombreado e brilho; use com preenchimento "serie".)

  # tamanho_simbolo_pt: tamanho do símbolo em pt.
  #   OPÇÕES: número > 0      EX.: cfg$serie_padrao$tamanho_simbolo_pt <- 8
  tamanho_simbolo_pt = 6,

  # esfera_luz: de onde vem a luz nas esferas, c(x, y) de -1 a 1 (x < 0 = esquerda; y < 0 = embaixo).
  #   EX.: cfg$serie_padrao$esfera_luz <- c(-0.4, 0.5)   (brilho em cima, à esquerda)
  esfera_luz = c(-0.35, -0.45),

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

  # ordenar_x: ordena os pontos de cada série por X antes de ligá-los. Com FALSE (padrão,
  #   como padrão) a linha segue a ORDEM DAS LINHAS DO CSV, o que permite curvas que
  #   voltam (laços, histerese, trajetórias). Use TRUE se o CSV está fora de ordem e você
  #   quer a linha sempre da esquerda para a direita.
  #   OPÇÕES: TRUE | FALSE
  #   EX.: cfg$linhas$ordenar_x <- TRUE
  ordenar_x = FALSE,

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

  # linha_guia_espessura_pt / linha_guia_recuo: espessura (pt) da linha guia e quanto ela
  #   para antes do rótulo (em fração do raio).
  #   OPÇÕES: números >= 0 (padrões 0.6 e 0.07)
  #   EX.: cfg$pizza$linha_guia_espessura_pt <- 1
  linha_guia_espessura_pt = 0.6,
  linha_guia_recuo = 0.07,

  # rotulos_raio_dentro / rotulos_raio_borda: posição dos rótulos, em fração do raio, quando
  #   rotulos_posicao = "dentro" (numa pizza cheia; na rosca fica no meio do anel) ou "borda".
  #   OPÇÕES: números > 0 (padrões 0.62 e 1.08)
  #   EX.: cfg$pizza$rotulos_raio_borda <- 1.15
  rotulos_raio_dentro = 0.62,
  rotulos_raio_borda = 1.08,

  # rotulos_afastar: afasta rótulos "fora"/"borda" que se sobreporiam (fatias pequenas
  #   vizinhas). Só move os que colidem; os demais ficam onde estão.
  #   OPÇÕES: TRUE | FALSE      EX.: cfg$pizza$rotulos_afastar <- FALSE
  rotulos_afastar = TRUE,

  # rotulos_margem: folga (fração do raio) entre os rótulos mais externos e a borda da figura.
  #   OPÇÕES: número >= 0 (padrão 0.15)      EX.: cfg$pizza$rotulos_margem <- 0.3
  rotulos_margem = 0.15,

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
  marcas_rug = FALSE,

  # rug_comprimento_pt / rug_espessura_pt: tamanho e espessura dos tracinhos de marcas_rug.
  #   OPÇÕES: números > 0 (padrões 5 e 0.6)      EX.: cfg$distribuicao$rug_comprimento_pt <- 8
  rug_comprimento_pt = 5,
  rug_espessura_pt = 0.6
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

  # semente: semente do sorteio do "jitter" (mesma figura toda vez). O sorteio do
  #   restante da sua sessão do R não é alterado.
  semente = 123,

  # enxame_resolucao: altura de cada "faixa" do enxame (pontos_disposicao = "enxame"), em
  #   fração da faixa dos dados. Pontos na mesma faixa são afastados para os lados.
  #   OPÇÕES: número > 0 (padrão 0.025; menor = pontos mais espalhados)
  #   EX.: cfg$boxplot$enxame_resolucao <- 0.04
  enxame_resolucao = 0.025,

  # pontos_borda_pt / outliers_borda_pt / media_borda_pt: espessura (pt) da borda dos
  #   símbolos dos dados, dos outliers e da média.
  #   OPÇÕES: número >= 0 (padrões 0.4 / 0.8 / 0.9)
  #   EX.: cfg$boxplot$outliers_borda_pt <- 1.2
  pontos_borda_pt = 0.4,
  outliers_borda_pt = 0.8,
  media_borda_pt = 0.9,

  # media_erro_ponto_fator: no estilo "ponto" de media_erro, o símbolo da média tem
  #   media_tamanho_pt multiplicado por este fator.
  #   OPÇÕES: número > 0 (padrão 1.4)      EX.: cfg$boxplot$media_erro_ponto_fator <- 2
  media_erro_ponto_fator = 1.4,

  # n_tamanho_pt: tamanho do texto "n = ..." de mostrar_n, em pt.
  #   OPÇÕES: NULL (80 % do tamanho base do texto) | número
  #   EX.: cfg$boxplot$n_tamanho_pt <- 7
  n_tamanho_pt = NULL
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
  #   Em eixo de datas, use texto: "2024-01-01", "01/01/2024" ou "01/01/2024 08:00".
  #   OPÇÕES: NULL | número | "data"
  #   EX.: cfg$eixo_x$inicio <- 0; cfg$eixo_x$fim <- 100
  #        cfg$eixo_x$inicio <- "01/03/2024"; cfg$eixo_x$fim <- "30/06/2024"
  inicio = NULL,
  fim = NULL,

  # tempo: a coluna X é uma data/hora? Colunas como 2024-03-15, 15/03/2024 ou
  #   15/03/2024 14:30 viram eixo de datas (posição proporcional ao tempo, ticks em
  #   dias, meses, anos...). "auto" detecta; FALSE trata o texto como categorias.
  #   Só vale para pontos, linha, linha_pontos, area e area_empilhada.
  #   OPÇÕES: "auto" | TRUE | FALSE
  #   EX.: cfg$eixo_x$tempo <- FALSE
  tempo = "auto",

  # formato_data: formato das datas do CSV quando o "auto" não acerta (o "auto" entende
  #   dia/mês/ano, ano-mês-dia e hora opcional). Códigos: %d dia, %m mês, %Y ano de
  #   4 dígitos, %H hora, %M minuto, %S segundo.
  #   OPÇÕES: NULL (auto) | "formato"
  #   EX.: cfg$eixo_x$formato_data <- "%m/%d/%Y"   # mês/dia/ano (estilo americano)
  formato_data = NULL,

  # formato_rotulo_data: como as datas aparecem nos ticks. NULL = automático conforme o
  #   passo entre os ticks (anos: 2024; meses: 03/2024; dias: 15/03; horas: 14:30). Só
  #   números, para não depender do idioma do Windows.
  #   OPÇÕES: NULL | "formato"
  #   EX.: cfg$eixo_x$formato_rotulo_data <- "%d/%m/%Y"   ou   "%H:%M"
  formato_rotulo_data = NULL,

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
  #   DÉCADAS (1 = a cada potência de 10). Em eixo de datas, use um passo em texto:
  #   número + unidade (sec/seg, min, hour/hora, day/dia, week/semana, month/mes, year/ano).
  #   OPÇÕES: número > 0 | "passo de tempo"
  #   EX.: cfg$eixo_x$incremento <- 20       cfg$eixo_x$incremento <- "1 mes"
  #        cfg$eixo_x$incremento <- "2 semanas"      cfg$eixo_x$incremento <- "6 horas"
  incremento = NULL,

  # quantidade: número de ticks maiores (modo "quantidade").
  quantidade = NULL,

  # primeiro_tick: posição do primeiro tick maior (modo "incremento").
  #   NULL = no início do eixo. Em eixo de datas aceita texto: "01/01/2024".
  primeiro_tick = NULL,

  # ticks_manuais: posições dos ticks (modo "manual"). Em eixo de datas, textos de data.
  #   EX.: cfg$eixo_x$ticks_manuais <- c(0, 25, 60, 100)
  #        cfg$eixo_x$ticks_manuais <- c("01/01/2024", "15/03/2024")
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
  #   espessura NULL = igual à da moldura (cfg$caixa$espessura_pt): mudar a moldura padroniza tudo.
  #   EX.: cfg$eixo_x$espessura_ticks_pt <- 0.75
  espessura_ticks_pt = NULL,
  cor_ticks = "black",

  # mostrar_linha / cor_linha / espessura_linha_pt: linha do eixo
  #   (com caixa fechada, a linha é a da caixa: veja cfg$caixa). espessura NULL = a da moldura.
  mostrar_linha = TRUE,
  cor_linha = "black",
  espessura_linha_pt = NULL,

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

  # distancia_rotulos_pt: distância entre números e eixo, em pt. Com a caixa de tamanho fixo (cfg$caixa) só os
  #   números se movem; o gráfico não muda de tamanho.
  distancia_rotulos_pt = 3,

  # mostrar_titulo / tamanho_titulo_pt / cor_titulo / negrito_titulo /
  # italico_titulo / distancia_titulo_pt: aparência do título do eixo.
  mostrar_titulo = TRUE,
  tamanho_titulo_pt = NULL,
  cor_titulo = "black",
  negrito_titulo = FALSE,
  italico_titulo = FALSE,
  distancia_titulo_pt = 4,

  # rotacao_titulo: ângulo do título do eixo, em graus. NULL = o padrão (X: 0; Y: 90, lendo de baixo para cima;
  #   Y da direita: -90). OPÇÕES: NULL | número      EX.: cfg$eixo_y$rotacao_titulo <- 0   (Y na horizontal)
  rotacao_titulo = NULL
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
  espessura_ticks_pt = NULL,     # NULL = igual à da moldura (cfg$caixa$espessura_pt)
  cor_ticks = "black",
  mostrar_linha = TRUE,
  cor_linha = "black",
  espessura_linha_pt = NULL,     # NULL = igual à da moldura
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
  distancia_titulo_pt = 4,
  # rotacao_titulo: graus. NULL = padrão (Y: 90, lendo de baixo para cima).  EX.: cfg$eixo_y$rotacao_titulo <- 0
  rotacao_titulo = NULL
)

# -----------------------------------------------------------------------------
# EIXO_Y2 — eixo Y secundário (à direita)
# -----------------------------------------------------------------------------
#  Para usar: cfg$eixo_y2$ativo <- TRUE e, no modo "independente", diga quais
#  séries vão para ele:  cfg$series[["Pressão"]] <- list(eixo = "y2")
#  A aparência (ticks, números, título, linha) segue o eixo_y, salvo o que for preenchido aqui.
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

  # fator_divisao: divide os números do eixo secundário (ex.: 1000 mostra 100 em vez de 100000).
  #   NULL = usa o mesmo do eixo_y (como era antes). Avise a unidade no título.
  #   OPÇÕES: NULL | número      EX.: cfg$eixo_y2$fator_divisao <- 1000
  fator_divisao = NULL,

  # distancia_titulo_pt / distancia_rotulos_pt: espaço (pt) entre o título e os números do eixo secundário, e entre
  #   os números e o eixo. NULL = o mesmo do eixo_y.      EX.: cfg$eixo_y2$distancia_titulo_pt <- 10
  distancia_titulo_pt = NULL,
  distancia_rotulos_pt = NULL,
  # rotacao_titulo: ângulo do título do eixo direito, em graus. NULL = o do eixo_y (padrão: -90).
  rotacao_titulo = NULL,

  # cor_eixo: pinta números, título e ticks do eixo secundário.
  #   OPÇÕES: NULL (preto) | "serie" (cor da 1ª série do y2) | qualquer cor
  cor_eixo = "serie",

  # ---- Aparência: as MESMAS opções do eixo_y. NULL = igual ao eixo_y (o que vale é o do eixo_y); preencha só o que
  #      quiser diferente no eixo da direita. (Início, fim, ticks, formato e distâncias estão acima.)
  #   primeiro_tick: de onde começam os ticks do Y2.              margem_percentual: folga nas pontas do Y2 (%).
  #   direcao_maiores / direcao_menores: "dentro" | "fora" | "ambos" | "nenhum".
  #   comprimento_maiores_pt / comprimento_menores_pt / espessura_ticks_pt / cor_ticks: ticks.
  #   mostrar_linha / espessura_linha_pt / cor_linha: a linha do eixo (aparece com a moldura aberta).
  #   mostrar_rotulos / tamanho_rotulos_pt / cor_rotulos / negrito_rotulos / rotacao_rotulos: os números.
  #   mostrar_titulo / tamanho_titulo_pt / cor_titulo / negrito_titulo / italico_titulo: o título.
  #   EX.: cfg$eixo_y2$direcao_maiores <- "fora"; cfg$eixo_y2$tamanho_rotulos_pt <- 9
  primeiro_tick = NULL,
  margem_percentual = NULL,
  direcao_maiores = NULL,
  direcao_menores = NULL,
  comprimento_maiores_pt = NULL,
  comprimento_menores_pt = NULL,
  espessura_ticks_pt = NULL,
  cor_ticks = NULL,
  mostrar_linha = NULL,
  espessura_linha_pt = NULL,
  cor_linha = NULL,
  mostrar_rotulos = NULL,
  tamanho_rotulos_pt = NULL,
  cor_rotulos = NULL,
  negrito_rotulos = NULL,
  rotacao_rotulos = NULL,
  mostrar_titulo = NULL,
  tamanho_titulo_pt = NULL,
  cor_titulo = NULL,
  negrito_titulo = NULL,
  italico_titulo = NULL
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

  # painel_fixo: a caixa do gráfico (a área dentro dos eixos) tem SEMPRE o mesmo tamanho, como uma área de plotagem de tamanho fixo:
  #   mexer em números, títulos, distâncias ou legenda move esses textos, não o gráfico, e a página do arquivo se
  #   ajusta para caber tudo (veja exportacao$ajustar_pagina). Vale para linha, pontos, barras, boxplot, histograma...
  #   (não para pizza nem painéis empilhados). FALSE = a caixa ocupa o que sobra da página (largura x altura).
  #   OPÇÕES: TRUE | FALSE
  painel_fixo = TRUE,

  # painel_largura_cm / painel_altura_cm: tamanho da caixa, em cm. NULL = o tamanho padrão (painel_padrao_cm).
  #   EX.: cfg$caixa$painel_largura_cm <- 9; cfg$caixa$painel_altura_cm <- 6.5
  painel_largura_cm = NULL,
  painel_altura_cm = NULL,
  # painel_padrao_cm: tamanho padrão c(largura, altura) da caixa, quando as duas acima estão vazias.
  painel_padrao_cm = c(10, 7.5),

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

  # cor_maior / espessura_maior_pt / tipo_maior / opacidade_maior: estilo da grade maior (as
  #   linhas que saem dos ticks MAIORES). opacidade: 1 = cor cheia, 0 = invisível.
  #   OPÇÕES cor: nome ("grey60") ou "#RRGGBB" | tipo: "solid" | "dashed" | "dotted" | "dotdash" |
  #           "longdash" | "twodash" | opacidade: número de 0 a 1
  #   EX.: cfg$grade$tipo_maior <- "dashed"; cfg$grade$cor_maior <- "#1F4E9E"
  #        cfg$grade$opacidade_maior <- 0.4
  cor_maior = "grey80",
  espessura_maior_pt = 0.5,
  tipo_maior = "solid",
  opacidade_maior = 1,

  # cor_menor / espessura_menor_pt / tipo_menor / opacidade_menor: estilo da grade menor
  #   (ticks menores). Mesmas OPÇÕES da grade maior.
  #   EX.: cfg$grade$opacidade_menor <- 0.3
  cor_menor = "grey92",
  espessura_menor_pt = 0.4,
  tipo_menor = "dashed",
  opacidade_menor = 1
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

  # x_dados / y_dados: posição da legenda por COORDENADAS DOS EIXOS (valores do eixo X e do eixo Y esquerdo, ex.:
  #   x_dados = 2016, y_dados = 600000). O canto superior esquerdo da legenda fica nesse ponto. Vale no lugar de
  #   dentro_x / dentro_y; um dos dois pode ficar vazio. Não serve para eixos de categorias.
  #   OPÇÕES: NULL | número (ou data, em eixo de datas)      EX.: cfg$legenda$x_dados <- 2016; cfg$legenda$y_dados <- 600000
  x_dados = NULL,
  y_dados = NULL,

  # ancora: qual ponto da legenda fica em (dentro_x, dentro_y).
  #   OPÇÕES: "auto" (= mesmo canto da posição) | c(x, y) entre 0 e 1
  ancora = "auto",

  # titulo: título da legenda. NULL = sem título.
  titulo = NULL,

  # n_colunas / n_linhas: em quantas colunas ou linhas os itens se organizam.  OPÇÕES: NULL | inteiro
  #   EX.: 4 itens em duas colunas: n_colunas <- 2.   Todos lado a lado em duas linhas: direcao "horizontal" e n_linhas <- 2.
  n_colunas = NULL,
  n_linhas = NULL,

  # inverter_ordem: inverte a ordem dos itens.  OPÇÕES: TRUE | FALSE
  inverter_ordem = FALSE,

  # alinhar: com a legenda FORA do gráfico ("direita"/"esquerda"/"topo"/"base"), onde ela fica ao longo do lado.
  #   Em direita/esquerda: "topo" | "centro" | "base".  Em topo/base: "esquerda" | "centro" | "direita".
  #   OPÇÕES: NULL (centro) | os textos acima      EX.: cfg$legenda$alinhar <- "topo"
  alinhar = NULL,

  # direcao: itens um embaixo do outro ("vertical") ou lado a lado, numa linha só ("horizontal").
  #   OPÇÕES: NULL (automático) | "vertical" | "horizontal"
  direcao = NULL,

  # moldura / cor_moldura / espessura_moldura_pt / tipo_moldura: borda da caixa da legenda.
  #   tipo_moldura OPÇÕES: "solid" | "dashed" | "dotted" | "dotdash" | "longdash" | "twodash"
  moldura = FALSE,
  cor_moldura = "black",
  espessura_moldura_pt = 0.5,
  tipo_moldura = "solid",

  # fundo: OPÇÕES: cor | "transparente".   fundo_opacidade: 0 (invisível) a 1 (sólido) da cor de fundo.
  #   EX.: cfg$legenda$fundo <- "white"; cfg$legenda$fundo_opacidade <- 0.8
  fundo = "transparente",
  fundo_opacidade = 1,

  # sombra: sombra projetada atrás da caixa da legenda (precisa de um fundo: com "transparente" o fundo vira branco).
  #   sombra_cor: cor.  sombra_opacidade: 0 a 1.  sombra_deslocamento_pt: c(para a direita, para baixo) em pt
  #   (um número só vale para os dois).
  #   OPÇÕES: TRUE | FALSE      EX.: cfg$legenda$sombra <- TRUE; cfg$legenda$sombra_deslocamento_pt <- c(3, 3)
  sombra = FALSE,
  sombra_cor = "black",
  sombra_opacidade = 0.35,
  sombra_deslocamento_pt = c(3, 3),

  # tamanho_texto_pt / tamanho_titulo_pt: NULL = tamanho base.
  tamanho_texto_pt = NULL,
  tamanho_titulo_pt = NULL,

  # negrito_texto / negrito_titulo: nomes das séries e título da legenda em negrito (ou cfg$texto$negrito_tudo).
  #   OPÇÕES: TRUE | FALSE
  negrito_texto = FALSE,
  negrito_titulo = FALSE,

  # tamanho_chave_pt: tamanho do quadradinho/linha de cada item.
  tamanho_chave_pt = 14,

  # espacamento_pt: espaço vertical entre os itens.
  espacamento_pt = 2,

  # escala: aumenta (> 1) ou diminui (< 1) a legenda inteira: texto, quadradinhos, símbolos, linhas, espaços e folgas.
  #   OPÇÕES: número > 0      EX.: cfg$legenda$escala <- 0.8
  # largura_pt: largura MANUAL da caixa da legenda, em pt (como esticar uma caixa solta): o conteúdo é escalado até a
  #   caixa ter essa largura, e os símbolos e linhas acompanham. NULL = a largura que o conteúdo pedir.
  #   OPÇÕES: NULL | número > 0      EX.: cfg$legenda$largura_pt <- 110
  largura_pt = NULL,
  # espaco_chave_texto_pt: espaço entre o símbolo e o nome. Menor = legenda mais compacta. NULL = padrão do ggplot2.
  #   OPÇÕES: NULL | número >= 0      EX.: cfg$legenda$espaco_chave_texto_pt <- 2
  espaco_chave_texto_pt = NULL,
  # largura_chave_pt: largura do espaço reservado ao símbolo. NULL = igual a tamanho_chave_pt.
  #   OPÇÕES: NULL | número > 0      EX.: cfg$legenda$largura_chave_pt <- 12
  largura_chave_pt = NULL,
  escala = 1,

  # distancia_pt: com a legenda "dentro", distância (pt) entre ela e a borda da caixa, para dentro:
  #   um número (vale para os dois lados) ou c(horizontal, vertical). NULL = pela posição dentro_x/dentro_y.
  #   EX.: cfg$legenda$distancia_pt <- c(8, 6)    (use com ancora/canto: a legenda encosta no canto mais próximo)
  distancia_pt = NULL,

  # ajustar_caixa: TRUE = se a legenda "dentro" for maior que a caixa do gráfico, ela é reduzida até caber
  #   (nunca aumenta). FALSE = tamanho exatamente como pedido, mesmo que passe da caixa.
  #   OPÇÕES: TRUE | FALSE
  ajustar_caixa = TRUE,

  # margem_interna_pt: folga entre o texto da legenda e a sua moldura: c(cima, direita,
  #   baixo, esquerda), em pt.
  #   OPÇÕES: vetor de 4 números >= 0      EX.: cfg$legenda$margem_interna_pt <- c(6, 8, 6, 8)
  margem_interna_pt = c(4, 6, 4, 6)
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
  # fonte: família tipográfica. Padrão: "Barlow", a fonte oficial (os arquivos vêm na pasta fontes/Barlow/ e
  #   são carregados sozinhos; também "Barlow Condensed" e "Barlow Semi Condensed"). "sans" = Arial no Windows /
  #   Helvetica no Mac. Veja as disponíveis com listar_fontes().
  #   OPÇÕES: "Barlow" | "Barlow Condensed" | "Barlow Semi Condensed" | "sans" | "serif" | "mono" | "Arial" | ...
  fonte = "Barlow",

  # tamanho_base_pt: tamanho padrão de todos os textos.
  tamanho_base_pt = 11,

  # cor: cor padrão dos textos.
  cor = "black",

  # negrito_tudo: TODOS os nomes e números em negrito (títulos, eixos, legenda, rótulos de dados...).
  #   Cada texto também tem o seu negrito (eixo$negrito_titulo, eixo$negrito_rotulos, legenda$negrito_texto...).
  #   OPÇÕES: TRUE | FALSE      EX.: cfg$texto$negrito_tudo <- TRUE
  negrito_tudo = FALSE
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
# AJUSTES — curvas de ajuste (linear, exponencial, potência, logarítmico, polinomial, loess, fórmula livre)
# -----------------------------------------------------------------------------
#  Lista de ajustes. Cada item (todas as chaves são opcionais, menos 'tipo' quando não for linear):
#    serie        nome da série (coluna Y) ou "todas" (uma curva para cada série; padrão)
#    tipo         "linear" | "exponencial" (y = a·exp(b·x)) | "potencia" (y = a·x^b) | "logaritmico" (y = a + b·ln x) |
#                 "polinomial" (com 'grau') | "loess" (suavizado, com 'suavizacao') | "formula" (com 'formula')
#    formula      só para tipo "formula": use x e nomes de parâmetros livres. EX.: "a*exp(-b*x) + c"  ou  "a/(1 + exp(-k*(x - x0)))"
#                 Permitido: + - * / ^ ( ) e exp, log, log10, log2, sqrt, sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, abs, pi
#    inicio       chutes iniciais dos parâmetros da fórmula. EX.: c(a = 5, b = 0.1, c = 0)   (vazio = o programa tenta vários)
#    grau         só para "polinomial" (1 a 8; padrão 2)
#    intercepto_zero  só para "linear": força a reta a passar pela origem
#    cor          cor da curva (vazio = a cor da série)       tipo_linha  "solid" | "dashed" | "dotted" | "dotdash" | "longdash" | "twodash"
#    espessura_pt grossura da curva (padrão 1.2)              opacidade   0 a 1
#    de, ate      trecho do eixo X em que a curva é desenhada (vazio = a faixa dos dados); estender = TRUE vai até as bordas do eixo
#    banda        TRUE desenha a faixa do intervalo de confiança da curva; banda_nivel (0.95) e banda_opacidade (0.18)
#    nome         nome do ajuste nas caixas de estatística     casas  casas decimais da equação (vazio = 4 algarismos significativos)
#  EX.: cfg$ajustes <- list(list(serie = "Y1", tipo = "linear", cor = "red", tipo_linha = "dashed"),
#                           list(serie = "Y2", tipo = "formula", formula = "a*exp(-b*x) + c"))
cfg$ajustes <- list()

# -----------------------------------------------------------------------------
# MARCAS_ESTATISTICAS — traços de média / mediana e faixas de desvio padrão, erro padrão, IC 95% ou mín–máx
# -----------------------------------------------------------------------------
#  Lista de marcas. Cada item (opcionais):
#    serie          série (ou "todas")                 eixo   "y" (linhas horizontais; padrão) | "x" (linhas verticais)
#    centro         "media" (padrão) | "mediana" | "nenhum"
#    faixa          "dp" (padrão) | "ep" | "ic95" | "minmax" | "nenhuma"      multiplo  quantos DP/EP (padrão 1; 2 = ±2 DP)
#    cor            cor dos traços (vazio = a cor da série)    opacidade  0 a 1
#    centro_espessura_pt (1.2)  centro_tipo ("solid")  faixa_espessura_pt (0.8)  faixa_tipo ("dotted")
#    preencher      TRUE pinta a área entre os dois traços da faixa (preencher_opacidade 0.15)
#    rotulo         TRUE escreve o valor ao lado de cada traço (rotulo_tamanho_pt 8)     casas  casas decimais do rótulo
#    modo           "linhas" (padrão) | "barras_por_x": barras de erro (média ± faixa) para cada valor de X com replicatas;
#                   com ponto_media = TRUE desenha também a média; chapeu_percentual = largura da tampa (1.5)
#  EX.: cfg$marcas_estatisticas <- list(list(serie = "Y1", faixa = "dp", preencher = TRUE, faixa_tipo = "dashed"))
cfg$marcas_estatisticas <- list()

# -----------------------------------------------------------------------------
# CAIXAS_ESTATISTICAS — caixas livres (como a legenda) com números: média, DP, EP, soma, R², equação, valor de p, ANOVA...
# -----------------------------------------------------------------------------
#  Lista de caixas. Cada item (opcionais):
#    series   séries incluídas (vazio = todas)     titulo  título da caixa
#    itens    o que escrever, em ordem. Descritiva: "n" "media" "mediana" "dp" "ep" "soma" "minimo" "maximo" "amplitude" "variancia" "cv" "q1" "q3" "ic95"
#             Ajuste: "equacao" "r2" "r2_aj" "rmse" "aic" "bic" "p_modelo" "parametros" "p_parametros" "shapiro_residuos"
#             Testes (entre as séries): "pearson" "spearman" "kendall" (X × Y) "shapiro" (normalidade) "ttest" "wilcoxon" "var_test" (duas séries)
#             "anova" "kruskal" "tukey" "bartlett" "fligner" (duas ou mais séries)
#    ajustes  quais ajustes entram (números da lista cfg$ajustes; vazio = todos)    casas  casas decimais
#    x, y     posição em fração da caixa do gráfico (0 a 1; padrão 0.03, 0.97)       ancora  "sup_esq" (padrão) | "sup_centro" | "sup_dir" | "centro_esq" | "centro" | "centro_dir" | "inf_esq" | "inf_centro" | "inf_dir"
#    tamanho_pt, cor_texto, negrito, alinhamento ("esquerda" | "centro" | "direita"), colorir_serie (TRUE: nome na cor da série)
#    fundo (cor), opacidade_fundo, borda_cor, borda_pt, borda_tipo, cantos ("arredondado" padrão | "reto"), raio_pt, margem_pt
#    sombra (TRUE/FALSE), sombra_cor, sombra_opacidade, sombra_dx_pt, sombra_dy_pt
#  EX.: cfg$caixas_estatisticas <- list(list(itens = c("media", "dp", "n", "equacao", "r2"), x = 0.05, y = 0.95, sombra = TRUE))
cfg$caixas_estatisticas <- list()

# -----------------------------------------------------------------------------
# FORMAS — caixas de texto, retângulos, elipses, triângulos, polígonos livres...
# -----------------------------------------------------------------------------
#  Lista de formas. Cada item:
#    tipo       "texto" | "retangulo" | "retangulo_arredondado" | "elipse" | "triangulo" | "losango" | "hexagono" | "estrela" | "poligono"
#    x, y       posição do centro (ou da âncora; padrão 0.5, 0.5). unidade = "fracao" (0 a 1 da caixa do gráfico; padrão) | "dados" (unidades dos eixos)
#    largura, altura   tamanho (na mesma unidade). Sem tamanho, a caixa de texto se ajusta ao texto.
#    vertices   só para "poligono": "0.2,0.2; 0.5,0.8; 0.8,0.3" (ou c(x1,y1,x2,y2,...)); na mesma unidade
#    texto      escreve dentro (aceita x^{2} e H_{2}O)     tamanho_pt, cor_texto, negrito, italico, alinhamento, angulo
#    fundo (cor ou vazio), opacidade_fundo, borda_cor, borda_pt, borda_tipo, raio_pt (cantos arredondados), margem_pt
#    sombra (TRUE), sombra_cor, sombra_opacidade, sombra_dx_pt, sombra_dy_pt
#    camada     "frente" (padrão) | "atras" (atrás dos dados)     ancora  como nas caixas de estatística (padrão "centro")
#  EX.: cfg$formas <- list(list(tipo = "texto", x = 0.5, y = 0.9, texto = "Zona crítica", fundo = "#FFF3CD", borda_cor = "orange"),
#                          list(tipo = "elipse", x = 30, y = 5, largura = 10, altura = 2, unidade = "dados", fundo = NA))
cfg$formas <- list()

# -----------------------------------------------------------------------------
# IMAGENS — figuras anexadas (PNG ou JPEG) sobre o gráfico: logotipo, esquema, foto da amostra...
# -----------------------------------------------------------------------------
#  Lista de figuras (precisa dos pacotes png e jpeg; veja 00_instalar_pacotes.R). Cada item:
#    arquivo    caminho do PNG ou JPEG (PNG com fundo transparente funciona)
#    x, y       posição do ponto de ancoragem (padrão 0.5, 0.5). unidade = "fracao" (0 a 1 da caixa do gráfico; padrão) | "dados" (unidades dos eixos)
#    largura    largura da figura (padrão 0.2 da caixa); altura vazia = mantém a proporção da figura.
#               Em unidades dos dados, largura E altura são obrigatórias.
#    ancora     qual ponto da figura fica em (x, y): "centro" (padrão) | "sup_esq" | "sup_centro" | "sup_dir" | "centro_esq" | "centro_dir" | "inf_esq" | "inf_centro" | "inf_dir"
#    opacidade  0 a 1       angulo  giro em graus       camada  "frente" (padrão) | "atras" (atrás dos dados)
#    borda_cor, borda_pt, borda_tipo   contorno em volta da figura (basta preencher um deles)
#  EX.: cfg$imagens <- list(list(arquivo = "logo.png", x = 0.98, y = 0.98, ancora = "sup_dir", largura = 0.15))
cfg$imagens <- list()

# -----------------------------------------------------------------------------
# QUEBRA — quebra (interrupção) do eixo Y
# -----------------------------------------------------------------------------
cfg$quebra <- list(
  # ativo: liga a quebra do eixo Y.  OPÇÕES: TRUE | FALSE
  ativo = FALSE,

  # estilo: como as duas partes aparecem.
  #   "separado" (padrão): dois gráficos, cada um com a sua moldura, com um espaço entre eles.
  #   "continuo": estilo contínuo: as partes coladas dentro de UMA moldura só, com duas barras "//"
  #               nas bordas esquerda e direita no ponto da quebra (espaco_pt não é usado).
  #   OPÇÕES: "separado" | "continuo"      EX.: cfg$quebra$estilo <- "continuo"
  estilo = "separado",

  # de / ate: trecho do eixo Y que será omitido.
  #   EX.: cfg$quebra$de <- 20; cfg$quebra$ate <- 80
  de = NULL,
  ate = NULL,
  # y2_de / y2_ate: trecho omitido do eixo Y da DIREITA (eixo_y2), com os valores desse eixo.
  #   NULL = acompanha o trecho do eixo Y da esquerda (mesma posição na figura).
  #   EX.: cfg$quebra$y2_de <- 2000; cfg$quebra$y2_ate <- 6000
  y2_de = NULL,
  y2_ate = NULL,
  # incremento_inferior / incremento_superior: intervalo entre os ticks maiores de CADA parte do eixo Y
  #   da esquerda (os ticks começam no início da parte: no "ate" para a de cima). NULL = automático.
  #   y2_incremento_*: o mesmo para o eixo Y da direita.
  #   EX.: cfg$quebra$incremento_inferior <- 20; cfg$quebra$incremento_superior <- 50
  incremento_inferior = NULL,
  incremento_superior = NULL,
  y2_incremento_inferior = NULL,
  y2_incremento_superior = NULL,
  # n_menores_inferior / n_menores_superior: ticks pequenos entre dois grandes em CADA parte do eixo Y da esquerda
  #   (0 = sem). y2_n_menores_*: o mesmo para o eixo da direita. NULL = o valor do eixo (eixo_y$n_menores / eixo_y2$n_menores).
  #   EX.: cfg$quebra$n_menores_inferior <- 4; cfg$quebra$n_menores_superior <- 1
  n_menores_inferior = NULL,
  n_menores_superior = NULL,
  y2_n_menores_inferior = NULL,
  y2_n_menores_superior = NULL,
  # proporcao_superior: fração da altura para a parte de cima.
  proporcao_superior = 0.35,
  # espaco_pt: espaço entre as duas partes. Aumente (ex.: 14) se os números das duas bordas da
  #   quebra se sobrepuserem.
  #   OPÇÕES: número >= 0      EX.: cfg$quebra$espaco_pt <- 14
  espaco_pt = 4,

  # ligar_atraves: a linha que liga um ponto de baixo a um de cima atravessa a quebra?
  #   TRUE (padrão): o traço aparece, cortado, nas duas partes. FALSE: não liga os pontos através
  #   da quebra (cada parte mostra só a sua linha). Vale para pontos, linha e linha_pontos.
  #   Use sugerir_quebra(dados) para descobrir de/ate a partir dos seus dados.
  #   OPÇÕES: TRUE | FALSE      EX.: cfg$quebra$ligar_atraves <- FALSE
  ligar_atraves = TRUE,
  # marcas: desenha os traços diagonais "//" da quebra.
  marcas = TRUE,

  # marca_largura_pt / marca_altura_pt: tamanho de cada traço diagonal da quebra, em pt
  #   (largura = quanto avança para os lados; altura = quanto sobe/desce).
  #   OPÇÕES: números > 0 (padrões 2.5 e 3: traço curto, que não encosta nos números do eixo)
  #   EX.: cfg$quebra$marca_largura_pt <- 4
  marca_largura_pt = 2.5,
  marca_altura_pt = 3
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

  # largura / altura / unidade: tamanho final da figura. ATENÇÃO: com a caixa de tamanho fixo (cfg$caixa$painel_fixo,
  #   o padrão) e ajustar_pagina = TRUE, a página se ajusta ao conteúdo e estes valores NÃO são usados. Para uma
  #   página de tamanho exato: cfg$caixa$painel_fixo <- FALSE (a caixa ocupa o que sobra) ou ajustar_pagina <- FALSE.
  #   OPÇÕES unidade: "cm" | "mm" | "in"
  largura = 12,
  altura = 9,
  unidade = "cm",

  # dpi: resolução das imagens (png, tiff, jpeg). Revistas: 300-600; linhas: 1200.
  dpi = 600,

  # fundo_transparente: OPÇÕES: TRUE | FALSE
  fundo_transparente = FALSE,

  # ajustar_pagina: com a caixa de tamanho fixo (cfg$caixa$painel_fixo), a página do arquivo se ajusta ao conteúdo
  #   (caixa do tamanho pedido + números, títulos e legenda), sem cortar nada; largura/altura acima não são usadas.
  #   FALSE = página sempre de largura x altura (a caixa fica centralizada; avisa se não couber).
  #   OPÇÕES: TRUE | FALSE
  ajustar_pagina = TRUE,

  # carimbo_data: acrescenta data e hora ao nome do arquivo.  OPÇÕES: TRUE | FALSE
  carimbo_data = FALSE,

  # sobrescrever: se FALSE e o arquivo existir, cria nome_2, nome_3, ...
  sobrescrever = TRUE
)
