# =============================================================================
#  graficos_R_completo.R  —  TEMPLATE DE GRÁFICOS CIENTÍFICOS EM R (ARQUIVO ÚNICO)
# =============================================================================
#  Alternativa ao Origin: pontos, linhas, áreas, barras, pizza, histograma, densidade,
#  ECDF e boxplot, com controle fino de eixos, ticks, moldura, cores, gradientes,
#  legenda, painéis empilhados, quebra de eixo, eixo de datas e exportação
#  (PNG, TIFF, JPEG, PDF, SVG, EMF). Tudo em um único arquivo.
#
#  COMO USAR (3 passos)
#   1) Só na primeira vez:   instalar_pacotes()      (depois de rodar este arquivo, ver passo 2;
#                            se faltar pacote, o script para e avisa; rode instalar_pacotes() e
#                            depois este arquivo de novo)
#   2) Abra este arquivo no RStudio e clique em  Source  (ou Ctrl+Shift+S).
#   3) Teste:    demonstracao()          # gráfico de exemplo com dados fictícios
#                demonstracao("datas")   # outras: "linha", "barras", "pizza", "boxplot", "datas"
#      Seus dados:   role até a PARTE 3 (PAINEL DE AJUSTES): preencha ARQUIVO_CSV, mude o que quiser
#                    (escala, ticks, grade, quebra, cores, fonte...) e dê Source de novo.
#                    Alternativa: dados <- ler_csv("C:/pasta/dados.csv"); g <- plotar(dados, cfg); salvar(g, cfg)
#
#  AJUDA:  ajuda()  |  ajuda("eixo_x")  |  ajuda("tipos")  |  galeria()
#  (ajuda() lê a PARTE 1 deste arquivo: use Source, ou deixe o arquivo na pasta de trabalho
#   com o nome graficos_R_completo.R)
#
#  Se os acentos aparecerem estranhos: File > Reopen with Encoding > UTF-8.
#  Estrutura:  PARTE 0 instalador | PARTE 1 configuração (cfg) | PARTE 2 motor | PARTE 3 painel de ajustes
#  Requisitos: R >= 4.2, ggplot2 >= 3.5, scales, patchwork, ragg >= 1.5.
# =============================================================================

# #############################################################################
#  PARTE 0 — INSTALADOR DE PACOTES
# #############################################################################

# Instala/atualiza os pacotes necessários. Rode UMA vez:  instalar_pacotes()
#  (sem permissão de administrador, instala na sua pasta pessoal; com proxy, defina antes
#   Sys.setenv(https_proxy = "http://usuario:senha@proxy.empresa.com:8080"))
instalar_pacotes <- function() {
  #  Instala/atualiza os pacotes usados pelo template. No notebook corporativo,
  #  se não houver permissão de administrador, os pacotes vão para a sua pasta
  #  pessoal de bibliotecas (criada automaticamente).
  #
  #  Se a rede da empresa usar proxy e o download falhar, descomente e ajuste:
  #  Sys.setenv(https_proxy = "http://usuario:senha@proxy.empresa.com:8080")
  #  Sys.setenv(http_proxy  = "http://usuario:senha@proxy.empresa.com:8080")
  # =============================================================================

  options(repos = c(CRAN = "https://cloud.r-project.org"))

  # Versões mínimas testadas
  minimos <- c(
    ggplot2   = "3.5.0",   # gradientes, ticks menores, legenda "inside"  (testado 3.5.2 e 4.0.3)
    scales    = "1.3.0",   # transformações de eixo (testado 1.4.0)
    patchwork = "1.2.0",   # painéis empilhados (testado 1.3.2)
    ragg      = "1.5.0"    # PNG/TIFF/JPEG de qualidade; < 1.5 tem bug no gradiente radial
  )
  opcionais <- c(
    svglite      = "2.1.0",  # SVG editável (Inkscape/Illustrator)
    devEMF       = "4.0",    # EMF para colar no Word/PowerPoint
    viridisLite  = "0.4.0",  # paletas viridis/magma/plasma/cividis
    RColorBrewer = "1.1-3",  # paletas brewer_*
    systemfonts  = "1.0.0"   # checagem das fontes instaladas
  )

  # Pasta de instalação: a padrão, ou a pessoal se a padrão não for gravável
  lib <- .libPaths()[1]
  if (file.access(lib, 2) != 0) {
    lib <- Sys.getenv("R_LIBS_USER")
    dir.create(lib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(lib, .libPaths()))
    message("Sem permissão na pasta padrão; instalando em: ", lib)
  }

  precisa <- function(p, v) {
    !requireNamespace(p, quietly = TRUE) || utils::packageVersion(p) < v
  }
  instalar <- function(lista, obrigatorio) {
    for (p in names(lista)) {
      if (precisa(p, lista[[p]])) {
        message(">> Instalando/atualizando ", p, " (>= ", lista[[p]], ")")
        tryCatch(utils::install.packages(p, lib = lib, dependencies = c("Depends", "Imports", "LinkingTo"),
                                         type = if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")),
                 error = function(e) message("   Falhou: ", conditionMessage(e)))
      }
    }
  }
  instalar(minimos, TRUE)
  instalar(opcionais, FALSE)

  cat("\n================ RESULTADO ================\n")
  ok <- TRUE
  for (p in names(c(minimos, opcionais))) {
    v <- c(minimos, opcionais)[[p]]
    tem <- requireNamespace(p, quietly = TRUE)
    ver <- if (tem) as.character(utils::packageVersion(p)) else "-"
    st <- if (!tem) "FALTA" else if (utils::packageVersion(p) < v) "ANTIGO" else "ok"
    obrig <- p %in% names(minimos)
    if (obrig && st != "ok") ok <- FALSE
    cat(sprintf("  %-13s %-9s %-7s %s\n", p, ver, st, if (obrig) "(obrigatório)" else "(opcional)"))
  }
  cat(sprintf("  R             %-9s %s\n", as.character(getRversion()),
              if (getRversion() >= "4.2.0") "ok" else "ANTIGO: gradientes exigem R >= 4.2"))
  if (ok) {
    cat("\nTudo pronto. Reinicie a sessão (Ctrl+Shift+F10) e rode este script de novo (Source).\n")
  } else {
    cat("\nAlgum pacote obrigatório falhou. Causas comuns no notebook corporativo:\n",
        " 1) proxy: rode Sys.setenv(https_proxy = 'http://usuario:senha@proxy:8080') e tente de novo;\n",
        " 2) bloqueio do CRAN: peça à TI liberação de https://cloud.r-project.org;\n",
        " 3) RStudio aberto com pacotes carregados: reinicie a sessão (Ctrl+Shift+F10) e rode de novo.\n")
  }

  cat("\nDICA RStudio: Tools > Global Options > General > Graphics > Backend = \"AGG\"\n",
      "  (deixa a aba Plots com as mesmas fontes e gradientes do arquivo final).\n", sep = "")
}

# #############################################################################
#  PARTE 1 — CONFIGURAÇÃO (cfg): TODOS OS PARÂMETROS EDITÁVEIS
# #############################################################################
# @@INICIO_CONFIG@@
# =============================================================================
#  PARÂMETROS EDITÁVEIS DO GRÁFICO (o cfg)
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
  #  "esfera" = bolinha com volume (sombreado e brilho), no estilo do Origin; use com preenchimento "serie".)

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
  #   como no Origin) a linha segue a ORDEM DAS LINHAS DO CSV, o que permite curvas que
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

  # fator_divisao: divide os números do eixo secundário (ex.: 1000 mostra 100 em vez de 100000).
  #   NULL = usa o mesmo do eixo_y (como era antes). Avise a unidade no título.
  #   OPÇÕES: NULL | número      EX.: cfg$eixo_y2$fator_divisao <- 1000
  fator_divisao = NULL,

  # distancia_titulo_pt / distancia_rotulos_pt: espaço (pt) entre o título e os números do eixo secundário, e entre
  #   os números e o eixo. NULL = o mesmo do eixo_y.      EX.: cfg$eixo_y2$distancia_titulo_pt <- 10
  distancia_titulo_pt = NULL,
  distancia_rotulos_pt = NULL,

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

  # painel_largura_cm / painel_altura_cm: tamanho FIXO da caixa do gráfico (a área dentro dos eixos), em cm,
  #   igual em todos os gráficos (como o layer do Origin). Números, títulos e legenda ficam fora dela e a
  #   página é ajustada para caber tudo (veja exportacao$ajustar_pagina). NULL = a caixa ocupa o que sobra da página.
  #   EX.: cfg$caixa$painel_largura_cm <- 9; cfg$caixa$painel_altura_cm <- 6.5
  painel_largura_cm = NULL,
  painel_altura_cm = NULL,

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

  # ancora: qual ponto da legenda fica em (dentro_x, dentro_y).
  #   OPÇÕES: "auto" (= mesmo canto da posição) | c(x, y) entre 0 e 1
  ancora = "auto",

  # titulo: título da legenda. NULL = sem título.
  titulo = NULL,

  # n_colunas: número de colunas de itens.  OPÇÕES: NULL | inteiro
  n_colunas = NULL,

  # inverter_ordem: inverte a ordem dos itens.  OPÇÕES: TRUE | FALSE
  inverter_ordem = FALSE,

  # alinhar: com a legenda FORA do gráfico ("direita"/"esquerda"/"topo"/"base"), onde ela fica ao longo do lado.
  #   Em direita/esquerda: "topo" | "centro" | "base".  Em topo/base: "esquerda" | "centro" | "direita".
  #   OPÇÕES: NULL (centro) | os textos acima      EX.: cfg$legenda$alinhar <- "topo"
  alinhar = NULL,

  # direcao: itens um embaixo do outro ou lado a lado.  OPÇÕES: NULL (automático) | "vertical" | "horizontal"
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

  # tamanho_chave_pt: tamanho do quadradinho/linha de cada item.
  tamanho_chave_pt = 14,

  # espacamento_pt: espaço vertical entre os itens.
  espacamento_pt = 2,

  # escala: aumenta (> 1) ou diminui (< 1) a legenda inteira: texto, quadradinhos, espaços e folgas.
  #   OPÇÕES: número > 0      EX.: cfg$legenda$escala <- 0.8
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

  # estilo: como as duas partes aparecem.
  #   "separado" (padrão): dois gráficos, cada um com a sua moldura, com um espaço entre eles.
  #   "continuo": estilo Origin: as partes coladas dentro de UMA moldura só, com duas barras "//"
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
  #   OPÇÕES: números > 0 (padrões 5 e 4)      EX.: cfg$quebra$marca_largura_pt <- 8
  marca_largura_pt = 5,
  marca_altura_pt = 4
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

  # ajustar_pagina: com caixa$painel_largura_cm/painel_altura_cm, a página do arquivo se ajusta ao conteúdo (caixa
  #   do tamanho pedido + números, títulos e legenda), sem cortar nada; largura/altura acima não são usadas.
  #   FALSE = página sempre de largura x altura (a caixa fica centralizada; avisa se não couber).
  #   OPÇÕES: TRUE | FALSE
  ajustar_pagina = TRUE,

  # carimbo_data: acrescenta data e hora ao nome do arquivo.  OPÇÕES: TRUE | FALSE
  carimbo_data = FALSE,

  # sobrescrever: se FALSE e o arquivo existir, cria nome_2, nome_3, ...
  sobrescrever = TRUE
)
# @@FIM_CONFIG@@
.CFG_PADRAO <- cfg   # guarda o padrão: resetar_cfg() e a checagem de nomes usam esta cópia

# #############################################################################
#  PARTE 2 — MOTOR (não precisa editar)
# #############################################################################

# Caminho deste arquivo (quando rodado com Source) e pasta do projeto.
.achar_arquivo_script <- function() {
  for (i in rev(seq_len(sys.nframe()))) {
    quadro <- tryCatch(sys.frame(i), error = function(e) NULL)
    if (!is.null(quadro) && exists("ofile", envir = quadro, inherits = FALSE)) {
      of <- get("ofile", envir = quadro, inherits = FALSE)
      if (is.character(of) && length(of) == 1 && file.exists(of) && grepl("@@INICIO_CONFIG@@", paste(readLines(of, n = 400, warn = FALSE, encoding = "UTF-8"), collapse = "\n"), fixed = TRUE))
        return(normalizePath(of, winslash = "/"))
    }
  }
  if (file.exists("graficos_R_completo.R")) return(normalizePath("graficos_R_completo.R", winslash = "/"))
  NULL
}
.ARQUIVO_SCRIPT <- .achar_arquivo_script()
.motor_pasta <- if (!is.null(.ARQUIVO_SCRIPT)) dirname(.ARQUIVO_SCRIPT) else getwd()

# Linhas da PARTE 1 deste arquivo (ajuda() mostra os comentários de cada parâmetro).
.config_linhas <- function() {
  if (is.null(.ARQUIVO_SCRIPT) || !file.exists(.ARQUIVO_SCRIPT))
    stop("ajuda() precisa ler este arquivo. Rode-o com Source (ou deixe-o na pasta de trabalho ",
         "com o nome graficos_R_completo.R).", call. = FALSE)
  L <- readLines(.ARQUIVO_SCRIPT, encoding = "UTF-8", warn = FALSE)
  i <- grep("^# @@INICIO_CONFIG@@", L); f <- grep("^# @@FIM_CONFIG@@", L)
  L[(i[1] + 1):(f[1] - 1)]
}

# Estilos prontos (equivalem aos arquivos da pasta estilos/ do projeto).
.ESTILOS_EMBUTIDOS <- list(
  apresentacao = # Estilo "apresentacao" — slides 16:9, fontes grandes, cores vivas.
  # Carregue com: cfg <- carregar_estilo("apresentacao", cfg)
  list(
    texto = list(fonte = "sans", tamanho_base_pt = 16),
    cores = list(paleta = "tableau", incrementar_simbolo = FALSE),
    serie_padrao = list(simbolo = 21, tamanho_simbolo_pt = 9, espessura_borda_pt = 1.2,
                        linha_espessura_pt = 3, preenchimento_simbolo = "serie"),
    caixa = list(fechada = FALSE, ticks_espelhados = FALSE, margens_cm = c(0.5, 0.8, 0.5, 0.5)),
    eixo_x = list(direcao_maiores = "fora", direcao_menores = "nenhum", n_menores = 0,
                  comprimento_maiores_pt = 6, espessura_ticks_pt = 1.5, espessura_linha_pt = 1.5,
                  cor_rotulos = "grey25", cor_linha = "grey25", cor_ticks = "grey25"),
    eixo_y = list(direcao_maiores = "fora", direcao_menores = "nenhum", n_menores = 0,
                  comprimento_maiores_pt = 6, espessura_ticks_pt = 1.5, espessura_linha_pt = 1.5,
                  cor_rotulos = "grey25", cor_linha = "grey25", cor_ticks = "grey25"),
    grade = list(maior_y = TRUE, cor_maior = "grey88", espessura_maior_pt = 0.8),
    barras = list(contorno_cor = NA, largura = 0.75),
    legenda = list(posicao = "topo", tamanho_chave_pt = 18),
    exportacao = list(largura = 24, altura = 13.5, unidade = "cm", dpi = 200, formatos = c("png"))
  ),
  padrao_cientifico = # Estilo "padrao_cientifico" — moldura completa, ticks maiores e menores para
  # dentro nos 4 lados, linhas de 1.5 pt (visual clássico de software científico).
  # Carregue com: cfg <- carregar_estilo("padrao_cientifico", cfg)
  list(
    texto = list(fonte = "Arial", tamanho_base_pt = 12),
    cores = list(paleta = "classico", incrementar_simbolo = TRUE),
    serie_padrao = list(tamanho_simbolo_pt = 7, espessura_borda_pt = 1, linha_espessura_pt = 1.5),
    caixa = list(fechada = TRUE, espessura_pt = 1.5, ticks_espelhados = TRUE, rotulos_espelhados = FALSE),
    eixo_x = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 6,
                  comprimento_menores_pt = 3.5, espessura_ticks_pt = 1.5, n_menores = 1,
                  distancia_rotulos_pt = 5),
    eixo_y = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 6,
                  comprimento_menores_pt = 3.5, espessura_ticks_pt = 1.5, n_menores = 1,
                  distancia_rotulos_pt = 5),
    legenda = list(posicao = "dentro", moldura = FALSE, fundo = "transparente"),
    exportacao = list(largura = 12, altura = 9, unidade = "cm", dpi = 600)
  ),
  publicacao_classico = # Estilo "publicacao_classico" — artigo científico, 1 coluna (8.5 cm), P&B.
  # Carregue com: cfg <- carregar_estilo("publicacao_classico", cfg)
  # Edite à vontade: só o que estiver aqui é alterado no cfg.
  list(
    texto = list(fonte = "Arial", tamanho_base_pt = 9),
    cores = list(paleta = "cinza", incrementar_simbolo = TRUE, incrementar_tipo_linha = TRUE),
    serie_padrao = list(tamanho_simbolo_pt = 5, espessura_borda_pt = 0.7, linha_espessura_pt = 1,
                        preenchimento_simbolo = "branco"),
    caixa = list(fechada = TRUE, espessura_pt = 0.8, ticks_espelhados = TRUE, rotulos_espelhados = FALSE,
                 margens_cm = c(0.2, 0.3, 0.2, 0.2)),
    eixo_x = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 4,
                  comprimento_menores_pt = 2, espessura_ticks_pt = 0.8, n_menores = 1),
    eixo_y = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 4,
                  comprimento_menores_pt = 2, espessura_ticks_pt = 0.8, n_menores = 1),
    grade = list(maior_x = FALSE, maior_y = FALSE, menor_x = FALSE, menor_y = FALSE),
    legenda = list(posicao = "dentro", moldura = FALSE, fundo = "transparente", tamanho_chave_pt = 12),
    exportacao = list(largura = 8.5, altura = 6.5, unidade = "cm", dpi = 600, formatos = c("pdf", "tiff"))
  )
)

# -----------------------------------------------------------------------------
#  01_base.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/01_base.R — opções, checagem de pacotes, utilitários e conversões de unidade
# =============================================================================
# (parte do motor carregado por 02_motor.R; não precisa editar)

options(OutDec = ".", scipen = 6)

local({
  falta <- c("ggplot2", "scales", "patchwork")[
    !vapply(c("ggplot2", "scales", "patchwork"), requireNamespace, logical(1), quietly = TRUE)]
  if (length(falta))
    stop("Pacotes ausentes: ", paste(falta, collapse = ", "),
         ". Rode primeiro: instalar_pacotes()", call. = FALSE)
  if (utils::packageVersion("ggplot2") < "3.5.0")
    stop("ggplot2 ", utils::packageVersion("ggplot2"), " é antigo. É preciso >= 3.5.0. ",
         "Rode instalar_pacotes() para atualizar.", call. = FALSE)
  if (utils::packageVersion("scales") < "1.3.0")
    stop("scales ", utils::packageVersion("scales"), " é antigo. É preciso >= 1.3.0.", call. = FALSE)
  if (utils::packageVersion("patchwork") < "1.2.0")
    stop("patchwork ", utils::packageVersion("patchwork"), " é antigo. É preciso >= 1.2.0.", call. = FALSE)
})

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
})

`%||%` <- function(a, b) if (is.null(a)) b else a
# TRUE se o pacote p está instalado (pacotes opcionais ficam desativados sem erro).
.tem <- function(p) requireNamespace(p, quietly = TRUE)
.R42 <- getRversion() >= "4.2.0"
.GG4 <- utils::packageVersion("ggplot2") >= "4.0.0"

# Cópia de referência do cfg (para detectar nomes digitados errado)
.cfg_ref <- .CFG_PADRAO   # cópia do cfg padrão (PARTE 1), antes de qualquer edição sua

# ---- Conversões de unidade (tudo do usuário em pt) --------------------------
# ggplot: linewidth em "mm" de ggplot; texto/símbolo em mm; stroke próprio.
.lw <- function(pt) pt * 96 / 72 / ggplot2::.pt          # espessura de linha
# Tamanho de texto/símbolo: pt do usuário -> unidade interna do ggplot2.
.tx <- function(pt) pt / ggplot2::.pt                    # texto e símbolos
# Espessura da borda de símbolo: pt do usuário -> unidade 'stroke' do ggplot2.
.st <- function(pt) pt * 96 / 72 * 2 / ggplot2::.stroke  # borda de símbolo

# Pasta/arquivo relativo (ex.: "estilos", "dados/x.csv"): se não existe a partir da pasta de trabalho
# mas existe dentro da pasta do projeto, usa o do projeto (funciona mesmo com setwd() em outro lugar).
.eh_absoluto <- function(p) grepl("^([A-Za-z]:|/|\\\\|~)", p)
# Entra: caminho de pasta. Sai: o mesmo caminho, ou a pasta de mesmo nome dentro do projeto se só ela existir.
.pasta_proj <- function(p) {
  if (.eh_absoluto(p) || dir.exists(p)) return(p)
  alt <- file.path(.motor_pasta, p)
  if (dir.exists(alt)) alt else p
}
# Entra: caminho de arquivo. Sai: o mesmo caminho, ou o arquivo dentro do projeto se só ele existir.
.arquivo_proj <- function(a) {
  if (.eh_absoluto(a) || file.exists(a)) return(a)
  alt <- file.path(.motor_pasta, a)
  if (file.exists(alt)) alt else a
}

# Emite um aviso (warning) em português, sem mostrar a chamada interna.
.aviso <- function(...) warning(paste0(...), call. = FALSE, immediate. = TRUE)
.erro  <- function(...) stop(paste0(...), call. = FALSE)

# -----------------------------------------------------------------------------
#  02_cores_texto.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/02_cores_texto.R — cores, paletas, gradientes, sobrescrito/subscrito, mescla de listas
# =============================================================================

# ---- Cores ------------------------------------------------------------------
# Valida e normaliza uma cor (nome, #RRGGBB, c(R,G,B) ou "transparente"). Erro em português se inválida.
.cor <- function(x, onde = "cor") {
  if (is.null(x)) return(NULL)
  if (length(x) == 3 && is.numeric(x)) return(grDevices::rgb(x[1], x[2], x[3], maxColorValue = 255))
  if (length(x) == 1 && is.na(x)) return(NA_character_)
  if (identical(x, "transparente")) return("transparent")
  ok <- tryCatch({ grDevices::col2rgb(x); TRUE }, error = function(e) FALSE)
  if (!ok) .erro("Cor inválida em ", onde, ": '", x, "'. Use nome (\"red\"), \"#RRGGBB\" ou c(R,G,B).")
  x
}
# Aplica opacidade a uma cor (a = 1 não altera; NA e NULL passam direto).
.alfa <- function(cor, a) {
  if (is.null(cor) || (length(cor) == 1 && is.na(cor))) return(cor)
  if (is.null(a) || a >= 1) return(cor)
  scales::alpha(cor, a)
}
# Cor intermediária entre c1 e c2.
.cor_media <- function(c1, c2) grDevices::colorRampPalette(c(c1, c2))(3)[2]
# Brilho percebido (0 a 1) de uma cor; decide texto branco ou preto sobre ela.
.luminancia <- function(cor) {
  v <- grDevices::col2rgb(cor) / 255
  sum(c(0.299, 0.587, 0.114) * v)
}

.PALETAS <- list(
  classico  = c("#000000", "#D62728", "#1F4E9E", "#2CA02C", "#8E44AD", "#FF7F0E",
                "#17BECF", "#8C564B", "#E377C2", "#7F7F7F"),
  okabe_ito = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9",
                "#000000", "#F0E442"),
  tableau   = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F", "#EDC948",
                "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC")
)

# Entra: nome da paleta e n. Sai: vetor com n cores (interpola se a paleta for menor que n).
.paleta <- function(nome, n, cfg_cores = NULL) {
  n <- max(n, 1)
  base <- if (nome %in% names(.PALETAS)) {
    .PALETAS[[nome]]
  } else if (nome %in% c("viridis", "magma", "plasma", "cividis", "inferno")) {
    if (!.tem("viridisLite")) .erro("Paleta '", nome, "' precisa do pacote viridisLite.")
    fun <- getExportedValue("viridisLite", nome)
    return(fun(n, end = if (nome == "viridis" || nome == "cividis") 0.92 else 0.88))
  } else if (nome == "cinza") {
    return(grDevices::grey.colors(n, start = 0, end = 0.75))
  } else if (startsWith(nome, "brewer_")) {
    if (!.tem("RColorBrewer")) .erro("Paletas brewer_ precisam do pacote RColorBrewer.")
    pal <- sub("^brewer_", "", nome)
    info <- RColorBrewer::brewer.pal.info
    if (!pal %in% rownames(info))
      .erro("Paleta ColorBrewer '", pal, "' não existe. Opções: ",
            paste(rownames(info), collapse = ", "))
    RColorBrewer::brewer.pal(info[pal, "maxcolors"], pal)
  } else if (nome == "personalizada") {
    vapply(cfg_cores$personalizada, .cor, character(1), onde = "cores$personalizada")
  } else {
    .erro("Paleta '", nome, "' desconhecida. Opções: classico, okabe_ito, tableau, viridis, ",
          "magma, plasma, cividis, cinza, brewer_<nome>, personalizada. Veja mostrar_paletas().")
  }
  if (n <= length(base)) base[seq_len(n)] else grDevices::colorRampPalette(base)(n)
}

# Gradiente de 2 cores (padrão grid). grupo = TRUE: relativo ao conjunto inteiro.
.gradiente <- function(c1, c2, direcao, grupo = FALSE) {
  cores <- c(c1, c2)
  if (grepl("invertido", direcao)) cores <- rev(cores)
  dir <- sub("_invertido", "", direcao)
  args <- list(colours = cores)
  if (.R42) args$group <- grupo
  if (dir == "radial") {
    args$colours <- rev(args$colours)   # centro = cor2 (clara), borda = cor da série
    args <- c(args, list(cx1 = 0.5, cy1 = 0.5, r1 = 0, cx2 = 0.5, cy2 = 0.5, r2 = 0.5))
    return(do.call(grid::radialGradient, args))
  }
  xy <- switch(dir,
               vertical   = c(0.5, 0, 0.5, 1),
               horizontal = c(0, 0.5, 1, 0.5),
               diagonal   = c(0, 0, 1, 1),
               .erro("gradiente_direcao '", direcao, "' inválida."))
  args <- c(args, list(x1 = xy[1], y1 = xy[2], x2 = xy[3], y2 = xy[4]))
  do.call(grid::linearGradient, args)
}

# ---- Texto com sobrescrito ^{ } e subscrito _{ } -----------------------------
# TRUE se o texto tem sobrescrito ^{ } ou subscrito _{ }.
.tem_formatacao <- function(s) is.character(s) && length(s) == 1 && grepl("[\\^_]\\{", s)

# Converte "Área (m^{2})" em string plotmath: "Área (m"*""^"2"*")"
.plotmath <- function(s) {
  if (!.tem_formatacao(s)) return(deparse(s))
  partes <- character(0)
  resto <- s
  while (nchar(resto) > 0) {
    m <- regexpr("[\\^_]\\{[^}]*\\}", resto)
    if (m == -1) { partes <- c(partes, deparse(resto)); break }
    if (m > 1) partes <- c(partes, deparse(substr(resto, 1, m - 1)))
    tok <- regmatches(resto, m)
    conteudo <- substr(tok, 3, nchar(tok) - 1)
    partes <- c(partes, if (substr(tok, 1, 1) == "^")
      paste0('""^', deparse(conteudo)) else paste0('""[', deparse(conteudo), "]"))
    resto <- substr(resto, m + attr(m, "match.length"), nchar(resto))
  }
  paste(partes, collapse = "*")
}
# Texto simples ou expressão plotmath (se tiver ^{ } ou _{ }), pronto para títulos e rótulos.
# negrito = TRUE: o plotmath ignora a face "bold" do tema, então a expressão é envolvida em bold().
.texto <- function(s, negrito = FALSE) {
  if (is.null(s)) return(NULL)
  if (!.tem_formatacao(s)) return(s)
  expr <- parse(text = .plotmath(s))[[1]]
  if (isTRUE(negrito)) call("bold", expr) else expr
}
# Rótulos de legenda: vetor de textos ou expressões, conforme tenham ^{ } / _{ }.
.rotulos_legenda <- function(x) {
  if (any(vapply(x, .tem_formatacao, logical(1))))
    parse(text = vapply(x, .plotmath, character(1)))
  else x
}

# ---- Mescla de listas (para painéis e estilos) -------------------------------
# Entra: lista base e lista novo. Sai: base com os valores de novo por cima (recursivo; séries por nome).
.mesclar <- function(base, novo) {
  if (!is.list(novo) || is.null(names(novo))) return(novo)
  for (nm in names(novo)) {
    if (is.list(base[[nm]]) && !is.null(names(base[[nm]])) && is.list(novo[[nm]]) &&
        !is.null(names(novo[[nm]])) && !nm %in% c("series")) {
      base[[nm]] <- .mesclar(base[[nm]], novo[[nm]])
    } else if (nm == "series" && is.list(novo[[nm]])) {
      for (s in names(novo[[nm]]))
        base$series[[s]] <- utils::modifyList(base$series[[s]] %||% list(), novo[[nm]][[s]])
    } else {
      base[nm] <- list(novo[[nm]])
    }
  }
  base
}

# -----------------------------------------------------------------------------
#  03_leitura.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/03_leitura.R — leitura de CSV e referência a colunas
# =============================================================================

# =============================================================================
#  LEITURA DE CSV
# =============================================================================
# Conta quantas vezes o separador aparece numa linha, ignorando o que está entre aspas.
.contar_fora_aspas <- function(linha, sep) {
  sem <- gsub('"[^"]*"', "", linha)
  lengths(regmatches(sem, gregexpr(sep, sem, fixed = TRUE)))
}

# Entra: linhas do CSV. Sai: o separador mais provável (; tab , |).
.detectar_separador <- function(linhas) {
  amostra <- utils::head(linhas[nzchar(trimws(linhas))], 30)
  for (sep in c(";", "\t", ",", "|")) {
    n <- vapply(amostra, .contar_fora_aspas, integer(1), sep = sep, USE.NAMES = FALSE)
    if (all(n > 0) && length(unique(n)) == 1) return(sep)
  }
  for (sep in c(";", "\t", ",", "|")) {
    n <- vapply(amostra, .contar_fora_aspas, integer(1), sep = sep, USE.NAMES = FALSE)
    if (mean(n > 0) > 0.8) return(sep)
  }
  ","
}

# Detecta UTF-16 pelo BOM (FF FE / FE FF) ou por bytes nulos alternados (texto ASCII em UTF-16).
# Entra: bytes do arquivo e cfg$dados$codificacao. Sai: "UTF-16LE", "UTF-16BE" ou NULL.
.detectar_utf16 <- function(bytes, cod = "auto") {
  cod <- toupper(cod)
  if (cod %in% c("UTF-16LE", "UTF-16BE")) return(cod)
  if (!cod %in% c("AUTO", "UTF-16") || length(bytes) < 2) return(NULL)
  b <- as.integer(bytes)
  if (b[1] == 255L && b[2] == 254L) return("UTF-16LE")
  if (b[1] == 254L && b[2] == 255L) return("UTF-16BE")
  a <- b[seq_len(min(length(b), 4000))]
  nulos_impar <- mean(a[c(TRUE, FALSE)] == 0L)   # bytes nº 1, 3, 5...
  nulos_par   <- mean(a[c(FALSE, TRUE)] == 0L)   # bytes nº 2, 4, 6...
  if (nulos_par > 0.3 && nulos_impar < 0.05) return("UTF-16LE")
  if (nulos_impar > 0.3 && nulos_par < 0.05) return("UTF-16BE")
  if (cod == "UTF-16") "UTF-16LE" else NULL
}

# Converte os bytes de um arquivo UTF-16 em texto UTF-8 (descarta o BOM).
.decodificar_utf16 <- function(bytes, cod16, arquivo) {
  b <- as.integer(bytes)
  if (length(b) >= 2 && ((b[1] == 255L && b[2] == 254L) || (b[1] == 254L && b[2] == 255L))) bytes <- bytes[-(1:2)]
  if (length(bytes) %% 2 == 1) bytes <- bytes[-length(bytes)]
  txt <- iconv(list(bytes), from = cod16, to = "UTF-8")
  if (length(txt) != 1 || is.na(txt))
    .erro("Não consegui decodificar '", arquivo, "' como ", cod16,
          ". Salve como CSV UTF-8 ou defina cfg$dados$codificacao.")
  txt
}

# Lê as linhas (já separadas) como tabela de TEXTO sem embaralhar linhas com mais ou menos
# campos que o cabeçalho (read.table com fill = TRUE empurraria os campos extras para uma
# linha nova). Devolve list(tab, n_cab = nº de campos do cabeçalho, curtas = linhas de dados
# com campos faltando).
.ler_tabela <- function(linhas, sep, cabecalho, arquivo) {
  erro_leitura <- function(e) .erro("Não consegui ler '", arquivo, "' com separador '",
                                    if (sep == "\t") "\\t" else sep, "': ", conditionMessage(e),
                                    "\n  Tente definir cfg$dados$separador manualmente.")
  con <- textConnection(linhas); on.exit(close(con))
  nc <- tryCatch(utils::count.fields(con, sep = sep, quote = "\"", comment.char = "",
                                     blank.lines.skip = FALSE),
                 error = function(e) rep(NA_integer_, length(linhas)))
  nmax <- suppressWarnings(max(nc, na.rm = TRUE))
  ler <- function(...) tryCatch(
    utils::read.table(text = linhas, sep = sep, colClasses = "character", check.names = FALSE,
                      quote = "\"", na.strings = character(0), strip.white = TRUE,
                      comment.char = "", fill = TRUE, blank.lines.skip = TRUE,
                      encoding = "UTF-8", ...),
    error = erro_leitura)
  if (!is.finite(nmax)) {  # contagem impossível (aspas abertas): leitura comum do R
    tab <- ler(header = cabecalho)
    return(list(tab = tab, n_cab = ncol(tab), curtas = integer(0)))
  }
  tab <- ler(header = FALSE, col.names = paste0("V", seq_len(nmax)))
  if (cabecalho) {
    nomes <- as.character(unlist(tab[1, ], use.names = FALSE))
    nomes[is.na(nomes)] <- ""
    tab <- tab[-1, , drop = FALSE]
    names(tab) <- nomes
    rownames(tab) <- NULL
    n_cab <- if (is.na(nc[1])) nmax else nc[1]
    curtas <- which(nc[-1] < n_cab)
  } else {
    n_cab <- nmax
    curtas <- which(nc < nmax)
  }
  list(tab = tab, n_cab = n_cab, curtas = curtas)
}

#' Lê um CSV e devolve um data.frame com números em ponto decimal.
ler_csv <- function(arquivo, opcoes = NULL) {
  op <- opcoes %||% (if (exists("cfg", envir = globalenv())) get("cfg", envir = globalenv())$dados) %||%
    .cfg_ref$dados
  arquivo <- .arquivo_proj(arquivo)
  if (!file.exists(arquivo))
    .erro("Arquivo não encontrado: '", arquivo, "'.\n  Pasta atual: ", getwd(),
          "\n  Dica: use o caminho completo do arquivo (ex.: 'C:/pasta/dados.csv') ou confira a pasta de trabalho com getwd().")
  tam <- file.info(arquivo)$size
  if (is.na(tam) || tam == 0) .erro("O arquivo '", arquivo, "' está vazio.")
  bytes <- readBin(arquivo, "raw", tam)
  cod <- op$codificacao %||% "auto"
  utf16 <- .detectar_utf16(bytes, cod)
  if (!is.null(utf16)) {
    txt <- .decodificar_utf16(bytes, utf16, arquivo)
    cod <- utf16
  } else {
    if (length(bytes) >= 3 && all(bytes[1:3] == as.raw(c(0xEF, 0xBB, 0xBF)))) bytes <- bytes[-(1:3)]
    bytes <- bytes[bytes != as.raw(0)]
    txt <- rawToChar(bytes)
    if (cod == "auto") cod <- if (validUTF8(txt)) "UTF-8" else "latin1"
    if (toupper(cod) != "UTF-8") {
      conv <- iconv(txt, if (cod == "latin1") "CP1252" else cod, "UTF-8")
      if (is.na(conv)) conv <- iconv(txt, "latin1", "UTF-8")
      txt <- conv
    }
  }
  Encoding(txt) <- "UTF-8"

  linhas <- strsplit(txt, "\r\n|\n|\r")[[1]]
  numeros <- seq_along(linhas)          # nº da linha no arquivo, para as mensagens
  pular <- op$pular_linhas %||% 0
  if (pular > 0) {
    fora <- seq_len(min(pular, length(linhas)))
    linhas <- linhas[-fora]; numeros <- numeros[-fora]
  }
  sep <- op$separador %||% "auto"
  if (length(linhas) && grepl('^"?sep=.', linhas[1])) {
    if (sep == "auto") sep <- substr(sub('^"?sep=', "", linhas[1]), 1, 1)
    linhas <- linhas[-1]; numeros <- numeros[-1]
  }
  cheias <- nzchar(trimws(linhas))
  linhas <- linhas[cheias]; numeros <- numeros[cheias]
  if (!length(linhas)) .erro("Nenhuma linha com dados em '", arquivo, "'.")
  if (sep == "auto") sep <- .detectar_separador(linhas)

  cabecalho <- isTRUE(op$cabecalho %||% TRUE)
  lida <- .ler_tabela(linhas, sep, cabecalho, arquivo)
  tab <- lida$tab
  estrutura <- character(0)
  nomes <- trimws(names(tab))
  nomes[!nzchar(nomes)] <- paste0("V", which(!nzchar(nomes)))
  names(tab) <- make.unique(nomes, sep = "_")
  # campos a mais que o cabeçalho (com conteúdo) ou a menos: avisa em vez de embaralhar
  desloc <- as.integer(cabecalho)
  linhas_arq <- function(i) paste(utils::head(numeros[i + desloc], 3), collapse = ", ")
  for (j in seq_len(max(0, ncol(tab) - lida$n_cab)) + lida$n_cab) {
    cheio <- which(nzchar(trimws(tab[[j]])))
    if (length(cheio))
      estrutura <- c(estrutura, sprintf(
        paste("%d linha(s) tem(têm) mais campos que o cabeçalho (linha %s do arquivo): os campos extras",
              "foram para a coluna '%s'. Confira o separador e as aspas."),
        length(cheio), linhas_arq(cheio), names(tab)[j]))
  }
  if (length(lida$curtas))
    estrutura <- c(estrutura, sprintf(
      "%d linha(s) tem(têm) menos campos que o cabeçalho (linha %s do arquivo): completada(s) com vazio (NA).",
      length(lida$curtas), linhas_arq(lida$curtas)))
  for (a in estrutura) .aviso("Leitura de '", basename(arquivo), "': ", a)
  # remove colunas totalmente vazias no fim (separador sobrando)
  vazias <- vapply(tab, function(v) all(!nzchar(trimws(v))), logical(1))
  if (any(vazias)) tab <- tab[, !vazias, drop = FALSE]

  na_txt <- op$valores_ausentes %||% c("", "NA")
  limpas <- lapply(tab, function(v) { v <- trimws(v); v[v %in% na_txt] <- NA; v })

  # Decide se a vírgula é decimal
  padrao_virg  <- "^[-+]?([0-9]{1,3}(\\.[0-9]{3})+|[0-9]*),[0-9]+([eE][-+]?[0-9]+)?$"
  padrao_ponto <- "^[-+]?[0-9]*\\.[0-9]+([eE][-+]?[0-9]+)?$"
  todos <- unlist(limpas, use.names = FALSE)
  todos <- todos[!is.na(todos)]
  dv <- op$decimal_virgula %||% "auto"
  if (identical(dv, "auto")) {
    dv <- sep != "," && sum(grepl(padrao_virg, todos)) > sum(grepl(padrao_ponto, todos))
  }

  avisos <- character(0)   # conversões numéricas: aparecem no relatório de leitura
  conv <- lapply(names(limpas), function(nm) {
    v <- limpas[[nm]]
    v2 <- v
    if (isTRUE(dv)) {
      milhar <- !is.na(v2) & grepl("^[-+]?[0-9]{1,3}(\\.[0-9]{3})+(,[0-9]+)?$", v2)
      v2[milhar] <- gsub(".", "", v2[milhar], fixed = TRUE)
      v2 <- sub(",", ".", v2, fixed = TRUE)
    }
    num <- suppressWarnings(as.numeric(v2))
    ok <- sum(!is.na(num)); tot <- sum(!is.na(v))
    if (tot > 0 && ok == tot) return(num)
    if (tot > 0 && ok / tot >= 0.5) {
      ruins <- which(!is.na(v) & is.na(num))
      avisos <<- c(avisos, sprintf(
        "Coluna '%s': %d valor(es) não numérico(s) virou(aram) NA. Ex.: linha %s = '%s'",
        nm, length(ruins), linhas_arq(ruins),
        paste(utils::head(v[ruins], 3), collapse = "', '")))
      return(num)
    }
    v
  })
  dados <- as.data.frame(stats::setNames(conv, names(limpas)), check.names = FALSE,
                         stringsAsFactors = FALSE)

  attr(dados, "arquivo") <- arquivo
  if (isTRUE(op$relatorio %||% TRUE)) {
    cat("\n=== Leitura de", basename(arquivo), "===\n")
    cat(sprintf("Codificação: %s | Separador: '%s' | Decimal no arquivo: %s -> convertido para ponto\n",
                cod, if (sep == "\t") "\\t" else sep, if (isTRUE(dv)) "vírgula" else "ponto"))
    cat(sprintf("%d linhas x %d colunas\n", nrow(dados), ncol(dados)))
    for (i in seq_along(dados)) {
      v <- dados[[i]]
      cat(sprintf("  [%d] %-28s %-9s NAs: %-4d %s\n", i, paste0("'", names(dados)[i], "'"),
                  if (is.numeric(v)) "numérica" else if (!is.null(.detectar_tempo(v))) "data" else "texto",
                  sum(is.na(v)),
                  if (is.numeric(v) && any(!is.na(v)))
                    sprintf("(%s a %s)", format(min(v, na.rm = TRUE)), format(max(v, na.rm = TRUE)))
                  else if (!is.numeric(v)) sprintf("ex.: %s", paste(utils::head(unique(v[!is.na(v)]), 3),
                                                                    collapse = ", "))
                  else ""))
    }
    if (length(avisos)) for (a in avisos) cat("  AVISO:", a, "\n")
    cat("\n")
  }
  if (length(c(estrutura, avisos))) attr(dados, "avisos") <- c(estrutura, avisos)
  dados
}

#' Lista as colunas de um data.frame lido
colunas <- function(dados) {
  data.frame(n = seq_along(dados), coluna = names(dados),
             tipo = vapply(dados, function(v)
               if (is.numeric(v)) "numérica" else if (!is.null(.detectar_tempo(v))) "data" else "texto", ""),
             row.names = NULL)
}

# Entra: dados e referência (nome ou número). Sai: nome da coluna; erro com sugestão se não existir.
.coluna <- function(dados, ref, onde) {
  if (is.null(ref)) return(NULL)
  if (is.numeric(ref)) {
    if (ref < 1 || ref > ncol(dados))
      .erro(onde, ": coluna número ", ref, " não existe (o arquivo tem ", ncol(dados), " colunas).")
    return(names(dados)[ref])
  }
  if (!ref %in% names(dados)) {
    sug <- names(dados)[utils::adist(ref, names(dados), ignore.case = TRUE) <= max(2, nchar(ref) %/% 4)]
    .erro(onde, ": coluna '", ref, "' não encontrada.",
          if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "",
          "\n  Colunas disponíveis: ", paste0("'", names(dados), "'", collapse = ", "))
  }
  ref
}

# -----------------------------------------------------------------------------
#  04_validacao.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/04_validacao.R — validação do cfg (nomes, opções, limites)
# =============================================================================

# =============================================================================
#  VALIDAÇÃO DO cfg
# =============================================================================
# TRUE se v é uma data (Date, POSIXct ou texto reconhecível como data); NULL conta como FALSE
.valor_tempo <- function(v) {
  !is.null(v) && length(v) == 1 &&
    (inherits(v, c("Date", "POSIXt")) || (is.character(v) && !is.null(.detectar_tempo(v))))
}

.OPCOES <- list(
  "grafico$tipo" = c("pontos", "linha", "linha_pontos", "area", "area_empilhada", "barras",
                     "pizza", "histograma", "densidade", "ecdf", "boxplot"),
  "cores$preenchimento" = c("solido", "gradiente"),
  "cores$gradiente_direcao" = c("vertical", "vertical_invertido", "horizontal",
                                "horizontal_invertido", "diagonal", "radial"),
  "linhas$ligacao" = c("reta", "spline", "degrau_hv", "degrau_vh", "degrau_meio"),
  "linhas$preencher_area" = c("nenhum", "ate_zero", "ate_base", "proxima_serie"),
  "linhas$linhas_queda" = c("nenhuma", "vertical", "horizontal", "ambas"),
  "linhas$erro_lado" = c("ambos", "superior", "inferior"),
  "linhas$rotulos_dados" = c("nenhum", "y", "x", "xy", "serie"),
  "barras$arranjo" = c("agrupado", "empilhado", "empilhado_100"),
  "barras$orientacao" = c("vertical", "horizontal"),
  "barras$rotulos_posicao" = c("fora", "dentro", "centro"),
  "pizza$sentido" = c("horario", "anti_horario"),
  "pizza$rotulos_posicao" = c("fora", "dentro", "borda"),
  "distribuicao$medida" = c("contagem", "frequencia", "percentual", "densidade"),
  "boxplot$variacao" = c("box", "box_pontos", "meio_box", "violino", "violino_box", "media_erro"),
  "boxplot$orientacao" = c("vertical", "horizontal"),
  "boxplot$bigode" = c("tukey", "percentis", "min_max", "desvio_padrao", "erro_padrao", "ic95"),
  "boxplot$bigode_lado" = c("ambos", "superior", "inferior"),
  "boxplot$pontos_disposicao" = c("jitter", "coluna", "enxame"),
  "boxplot$media_erro_tipo" = c("desvio_padrao", "erro_padrao", "ic95"),
  "boxplot$media_erro_estilo" = c("barra", "ponto"),
  "eixo_y2$modo" = c("independente", "transformado"),
  "legenda$posicao" = c("dentro", "direita", "esquerda", "topo", "base"),
  "legenda$alinhar" = c("topo", "centro", "base", "esquerda", "direita"),
  "legenda$direcao" = c("vertical", "horizontal"),
  "legenda$tipo_moldura" = c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash"),
  "titulos$alinhamento" = c("esquerda", "centro", "direita"),
  "quebra$estilo" = c("separado", "continuo"),
  "paineis$direcao" = c("vertical", "horizontal"),
  "paineis$rotulos_eixo_comum" = c("ultimo", "todos"),
  "paineis$formato_letra" = c("(a)", "a)", "a", "(A)", "A", "(i)"),
  "exportacao$unidade" = c("cm", "mm", "in")
)
.OPCOES_EIXO <- list(
  escala = c("linear", "log10", "ln", "log2", "reciproco", "raiz"),
  ticks_modo = c("auto", "incremento", "quantidade", "min_max", "manual"),
  direcao_maiores = c("dentro", "fora", "ambos", "nenhum"),
  direcao_menores = c("dentro", "fora", "ambos", "nenhum"),
  notacao = c("normal", "milhar", "cientifica", "cientifica_E", "potencia10", "percentual")
)

# Completa o cfg com os padrões da PARTE 1 para tudo o que faltar nos blocos. Assim continuam
# funcionando scripts que SUBSTITUEM um bloco inteiro (cfg$quebra <- list(...)) e estilos salvos
# antes de um parâmetro existir. Não mexe em cfg$series e cfg$referencias (livres).
.completar_cfg <- function(cfg) {
  ref <- .cfg_ref
  if (is.null(ref)) return(cfg)
  for (bl in setdiff(names(ref), c("series", "referencias"))) {
    if (!is.list(ref[[bl]]) || is.null(names(ref[[bl]]))) next
    if (is.null(cfg[[bl]])) { cfg[[bl]] <- ref[[bl]]; next }
    if (!is.list(cfg[[bl]])) next
    for (nm in setdiff(names(ref[[bl]]), names(cfg[[bl]])))
      if (!is.null(ref[[bl]][[nm]])) cfg[[bl]][[nm]] <- ref[[bl]][[nm]]
  }
  cfg
}

# Erro em português (com sugestão) se 'valor' não está na lista de opções válidas.
.checar_opcao <- function(valor, opcoes, onde) {
  if (is.null(valor)) return(invisible())
  if (!is.character(valor) || length(valor) != 1 || !valor %in% opcoes) {
    sug <- opcoes[utils::adist(as.character(valor)[1], opcoes, ignore.case = TRUE) <= 3]
    .erro("cfg$", onde, " = '", paste(valor, collapse = ","), "' não é válido.",
          if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "",
          "\n  OPÇÕES: ", paste0('"', opcoes, '"', collapse = " | "))
  }
}

# Avisa blocos e parâmetros do cfg que não existem (digitados errado), comparando com a PARTE 1.
.checar_nomes <- function(cfg) {
  ref <- .cfg_ref
  if (is.null(ref)) return(invisible())
  livres <- c("series", "referencias", "interno")
  for (bl in names(cfg)) {
    if (bl %in% c(".interno")) next
    if (!bl %in% names(ref)) {
      sug <- names(ref)[utils::adist(bl, names(ref)) <= 3]
      .aviso("Bloco cfg$", bl, " não existe e será ignorado.",
             if (length(sug)) paste0(" Você quis dizer cfg$", sug[1], "?") else "")
      next
    }
    if (bl %in% livres || !is.list(cfg[[bl]]) || is.null(names(cfg[[bl]]))) next
    desconhecidos <- setdiff(names(cfg[[bl]]), c(names(ref[[bl]]), ".ocultar_extremo"))
    for (p in desconhecidos) {
      sug <- names(ref[[bl]])[utils::adist(p, names(ref[[bl]])) <= 3]
      .aviso("Parâmetro cfg$", bl, "$", p, " não existe e será ignorado.",
             if (length(sug)) paste0(" Você quis dizer cfg$", bl, "$", sug[1], "?") else "")
    }
  }
}

# Chaves aceitas em cada item de cfg$referencias e de cfg$anotacoes$textos/setas/faixas
.CHAVES_ITENS <- list(
  referencias = c("eixo", "valor", "cor", "espessura_pt", "tipo", "rotulo", "rotulo_tamanho_pt"),
  textos = c("x", "y", "texto", "tamanho_pt", "cor", "negrito", "alinhamento"),
  setas = c("x", "y", "x_fim", "y_fim", "cor", "espessura_pt", "tamanho_ponta_pt"),
  faixas = c("eixo", "de", "ate", "cor", "opacidade"))

# Avisa chave digitada errado dentro dos itens (ex.: tamanho_ptt), que antes era ignorada em silêncio.
.checar_itens <- function(cfg) {
  um <- function(lista, tipo, onde) for (i in seq_along(lista)) {
    ruins <- setdiff(names(lista[[i]]), .CHAVES_ITENS[[tipo]])
    for (r in ruins) {
      sug <- .CHAVES_ITENS[[tipo]][utils::adist(r, .CHAVES_ITENS[[tipo]]) <= 3]
      .aviso(onde, "[[", i, "]]$", r, " não existe e será ignorado.",
             if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "")
    }
  }
  um(cfg$referencias, "referencias", "cfg$referencias")
  for (t in c("textos", "setas", "faixas")) um(cfg$anotacoes[[t]], t, paste0("cfg$anotacoes$", t))
}

# Confere opções, limites e combinações do cfg; para no primeiro erro, com mensagem em português.
.validar <- function(cfg, checar_nomes = TRUE) {
  if (checar_nomes) { .checar_nomes(cfg); .checar_itens(cfg) }
  for (k in names(.OPCOES)) {
    p <- strsplit(k, "$", fixed = TRUE)[[1]]
    .checar_opcao(cfg[[p[1]]][[p[2]]], .OPCOES[[k]], k)
  }
  for (ax in c("eixo_x", "eixo_y")) {
    e <- cfg[[ax]]
    for (k in names(.OPCOES_EIXO)) .checar_opcao(e[[k]], .OPCOES_EIXO[[k]], paste0(ax, "$", k))
    if (!is.null(e$tempo) && !(identical(e$tempo, "auto") || is.logical(e$tempo)))
      .erro("cfg$", ax, "$tempo deve ser \"auto\", TRUE ou FALSE.")
    datas <- .valor_tempo(e$inicio) && .valor_tempo(e$fim)   # inicio/fim como datas: .calc_eixo confere a ordem
    if (!is.null(e$inicio) && !is.null(e$fim) && !datas) {
      if (!is.numeric(e$inicio) || !is.numeric(e$fim))
        .erro("cfg$", ax, "$inicio e $fim devem ser números (use ponto decimal: 2.5).")
      if (e$inicio >= e$fim)
        .erro("cfg$", ax, "$inicio (", e$inicio, ") deve ser menor que cfg$", ax, "$fim (", e$fim,
              "). Para inverter o eixo use cfg$", ax, "$inverter <- TRUE.")
    }
    if (identical(e$ticks_modo, "incremento") && is.null(e$incremento))
      .erro("cfg$", ax, "$ticks_modo = \"incremento\" exige cfg$", ax, "$incremento (ex.: 10).")
    if (!is.null(e$incremento) && is.null(.passo_tempo(e$incremento)) &&
        (!is.numeric(e$incremento) || e$incremento <= 0))
      .erro("cfg$", ax, "$incremento deve ser um número > 0 (ou, em eixo de datas, um passo como \"1 mes\").")
    if (identical(e$ticks_modo, "quantidade") && is.null(e$quantidade))
      .erro("cfg$", ax, "$ticks_modo = \"quantidade\" exige cfg$", ax, "$quantidade (ex.: 5).")
    if (identical(e$ticks_modo, "manual") && is.null(e$ticks_manuais))
      .erro("cfg$", ax, "$ticks_modo = \"manual\" exige cfg$", ax, "$ticks_manuais (ex.: c(0, 5, 10)).")
    if (!is.null(e$rotulos_manuais) && length(e$rotulos_manuais) != length(e$ticks_manuais))
      .erro("cfg$", ax, "$rotulos_manuais tem ", length(e$rotulos_manuais),
            " textos mas ticks_manuais tem ", length(e$ticks_manuais), " posições.")
  }
  if (isTRUE(cfg$eixo_y2$ativo)) {
    for (k in c("ticks_modo", "notacao")) .checar_opcao(cfg$eixo_y2[[k]], .OPCOES_EIXO[[k]], paste0("eixo_y2$", k))
  }
  if (cfg$legenda$posicao == "dentro") {
    if (any(c(cfg$legenda$dentro_x, cfg$legenda$dentro_y) < 0 | c(cfg$legenda$dentro_x, cfg$legenda$dentro_y) > 1))
      .erro("cfg$legenda$dentro_x e dentro_y devem estar entre 0 e 1.")
  }
  lg <- cfg$legenda
  for (k in c("fundo_opacidade", "sombra_opacidade"))
    if (!is.null(lg[[k]]) && (!is.numeric(lg[[k]]) || length(lg[[k]]) != 1 || lg[[k]] < 0 || lg[[k]] > 1))
      .erro("cfg$legenda$", k, " deve ser um número entre 0 e 1.")
  for (k in c("painel_largura_cm", "painel_altura_cm"))
    if (!is.null(cfg$caixa[[k]]) && (!is.numeric(cfg$caixa[[k]]) || length(cfg$caixa[[k]]) != 1 || cfg$caixa[[k]] <= 0))
      .erro("cfg$caixa$", k, " deve ser um número maior que 0 (cm).")
  if (!is.null(lg$escala) && (!is.numeric(lg$escala) || length(lg$escala) != 1 || lg$escala <= 0))
    .erro("cfg$legenda$escala deve ser um número maior que 0 (ex.: 0.8).")
  if (!is.null(lg$distancia_pt) && (!is.numeric(lg$distancia_pt) || !length(lg$distancia_pt) %in% 1:2 || any(lg$distancia_pt < 0)))
    .erro("cfg$legenda$distancia_pt deve ser um número >= 0 ou c(horizontal, vertical), em pt.")
  if (!is.null(lg$alinhar)) {
    lado <- if (lg$posicao %in% c("direita", "esquerda")) c("topo", "centro", "base") else c("esquerda", "centro", "direita")
    if (lg$posicao != "dentro" && !lg$alinhar %in% lado)
      .erro("cfg$legenda$alinhar = \"", lg$alinhar, "\" não serve para a legenda em \"", lg$posicao,
            "\". OPÇÕES: ", paste0('"', lado, '"', collapse = " | "))
  }
  if (!is.null(lg$sombra_deslocamento_pt) && (!is.numeric(lg$sombra_deslocamento_pt) ||
                                              !length(lg$sombra_deslocamento_pt) %in% 1:2))
    .erro("cfg$legenda$sombra_deslocamento_pt deve ser um número ou c(direita, baixo), em pt.")
  if (!is.null(cfg$pizza$raio_furo) && (cfg$pizza$raio_furo < 0 || cfg$pizza$raio_furo > 0.9))
    .erro("cfg$pizza$raio_furo deve estar entre 0 e 0.9.")
  if (!identical(cfg$legenda$mostrar, "auto") && !is.logical(cfg$legenda$mostrar))
    .erro("cfg$legenda$mostrar deve ser \"auto\", TRUE ou FALSE.")
  invisible(TRUE)
}

# -----------------------------------------------------------------------------
#  05_series.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/05_series.R — estilo das séries e escalas de legenda
# =============================================================================

# =============================================================================
#  ESTILO DAS SÉRIES
# =============================================================================
.CHAVES_SERIE <- c("cor", "cor2", "simbolo", "tamanho_simbolo_pt", "espessura_borda_pt",
                   "preenchimento_simbolo", "linha_espessura_pt", "linha_tipo", "opacidade",
                   "opacidade_preenchimento", "nome_legenda", "mostrar_na_legenda", "eixo",
                   "coluna_erro", "coluna_erro_inferior", "coluna_erro_superior", "coluna_erro_x")
.SIMBOLOS_INC <- c(21, 22, 24, 23, 25, 1, 0, 2, 5, 6, 3, 4, 8)
.LINHAS_INC <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")

# Entra: cfg e nomes dos itens (séries/categorias).
# Sai: lista com o estilo completo de cada item (cor, símbolo, linha, gradiente).
.estilos <- function(cfg, itens, grupo_gradiente = FALSE, inverter_grad = FALSE) {
  n <- length(itens)
  cores <- .paleta(cfg$cores$paleta, n, cfg$cores)
  if (!isTRUE(cfg$.interno$em_painel)) for (s in setdiff(names(cfg$series), itens))
    .aviso("cfg$series[[\"", s, "\"]] não corresponde a nenhuma série/categoria deste gráfico. ",
           "Disponíveis: ", paste0("'", itens, "'", collapse = ", "))
  out <- lapply(seq_len(n), function(i) {
    it <- itens[i]
    s <- cfg$series[[it]] %||% list()
    ruins <- setdiff(names(s), .CHAVES_SERIE)
    for (r in ruins) {
      sug <- .CHAVES_SERIE[utils::adist(r, .CHAVES_SERIE) <= 3]
      .aviso("cfg$series[[\"", it, "\"]]$", r, " não existe.",
             if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "")
    }
    p <- cfg$serie_padrao
    cor <- .cor(s$cor %||% cores[i], paste0("series '", it, "'"))
    cor2 <- .cor(s$cor2 %||% cfg$cores$gradiente_cor2, paste0("series '", it, "' cor2"))
    ordem <- cfg$cores$simbolos_ordem %||% .SIMBOLOS_INC
    simb <- .simbolo_codigo(s$simbolo %||% (if (isTRUE(cfg$cores$incrementar_simbolo))
      ordem[(i - 1) %% length(ordem) + 1] else p$simbolo), paste0("símbolo de '", it, "'"))
    lt <- s$linha_tipo %||% (if (isTRUE(cfg$cores$incrementar_tipo_linha))
      .LINHAS_INC[(i - 1) %% length(.LINHAS_INC) + 1] else p$linha_tipo)
    ps <- s$preenchimento_simbolo %||% p$preenchimento_simbolo
    fill_simb <- switch(ps, serie = cor, branco = "white", vazio = NA_character_,
                        .cor(ps, paste0("preenchimento_simbolo de '", it, "'")))
    op <- s$opacidade %||% p$opacidade
    opf <- s$opacidade_preenchimento %||% p$opacidade_preenchimento
    preench <- if (identical(cfg$cores$preenchimento, "gradiente")) {
      dir <- cfg$cores$gradiente_direcao
      if (inverter_grad) dir <- switch(sub("_invertido", "", dir),
                                       vertical = sub("vertical", "horizontal", dir),
                                       horizontal = sub("horizontal", "vertical", dir), dir)
      .gradiente(.alfa(cor, opf), .alfa(cor2, opf), dir, grupo_gradiente)
    } else .alfa(cor, opf)
    list(item = it,
         rotulo = s$nome_legenda %||% it,
         legenda = s$mostrar_na_legenda %||% TRUE,
         cor = cor, cor2 = cor2,
         cor_solida = .alfa(cor, opf),
         preench = preench,
         simbolo = simb,
         tam = s$tamanho_simbolo_pt %||% p$tamanho_simbolo_pt,
         borda = s$espessura_borda_pt %||% p$espessura_borda_pt,
         fill_simb = fill_simb,
         lw = s$linha_espessura_pt %||% p$linha_espessura_pt,
         lt = lt, op = op, opf = opf,
         eixo = s$eixo %||% "y1",
         erro = s$coluna_erro, erro_inf = s$coluna_erro_inferior,
         erro_sup = s$coluna_erro_superior, erro_x = s$coluna_erro_x)
  })
  stats::setNames(out, itens)
}

# Escalas manuais "fundidas" numa só legenda
.escalas_legenda <- function(est, aes_usadas, cfg) {
  itens <- names(est)
  quebras <- itens[vapply(est, function(e) isTRUE(e$legenda), logical(1))]
  if (isTRUE(cfg$legenda$inverter_ordem)) quebras <- rev(quebras)
  rotulos <- .rotulos_legenda(vapply(est[quebras], function(e) as.character(e$rotulo), ""))
  nome <- if (is.null(cfg$legenda$titulo)) NULL else .texto(cfg$legenda$titulo)
  guia <- guide_legend(ncol = cfg$legenda$n_colunas, byrow = TRUE)
  valores <- list(
    colour    = function() stats::setNames(vapply(est, function(e) e$cor, ""), itens),
    fill      = function() stats::setNames(lapply(est, function(e) e$preench), itens),
    fill_simb = function() stats::setNames(vapply(est, function(e) e$fill_simb, ""), itens),
    shape     = function() stats::setNames(vapply(est, function(e) e$simbolo, 0), itens),
    size      = function() stats::setNames(vapply(est, function(e) .tx(e$tam), 0), itens),
    stroke    = function() stats::setNames(vapply(est, function(e) .st(e$borda), 0), itens),
    linetype  = function() stats::setNames(vapply(est, function(e) as.character(e$lt), ""), itens),
    linewidth = function() stats::setNames(vapply(est, function(e) .lw(e$lw), 0), itens),
    alpha     = function() stats::setNames(vapply(est, function(e) e$op, 0), itens)
  )
  radial <- identical(cfg$cores$preenchimento, "gradiente") && grepl("radial", cfg$cores$gradiente_direcao)
  lapply(aes_usadas, function(a) {
    v <- valores[[a]]()
    if (a == "fill" && radial && length(quebras))
      guia <- guide_legend(ncol = cfg$legenda$n_colunas, byrow = TRUE,
                           override.aes = list(fill = unname(vapply(est[quebras], function(e) e$cor_solida, ""))))
    estetica <- if (a == "fill_simb") "fill" else a
    if (estetica == "fill" && !is.list(v)) v <- as.list(v)
    if (length(quebras) == 0)
      return(scale_discrete_manual(aesthetics = estetica, values = v, guide = "none"))
    scale_discrete_manual(aesthetics = estetica, values = v, breaks = quebras,
                          labels = rotulos, name = nome, guide = guia, drop = FALSE,
                          na.value = NA)
  })
}

# -----------------------------------------------------------------------------
#  06_eixos.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/06_eixos.R — limites, ticks maiores/menores e rótulos dos eixos
# =============================================================================

# =============================================================================
#  EIXOS: limites, ticks maiores/menores, rótulos
# =============================================================================
# Base do logaritmo da escala (10, e ou 2); NA se a escala não é logarítmica.
.base_log <- function(escala) switch(escala, log10 = 10, ln = exp(1), log2 = 2, NA)

# Transformação de escala do scales (linear, log, 1/x, raiz), com inversão opcional.
.transformacao <- function(escala, inverter) {
  t <- switch(escala,
              linear = scales::transform_identity(),
              log10 = scales::transform_log10(),
              ln = scales::transform_log(),
              log2 = scales::transform_log(2),
              reciproco = scales::transform_reciprocal(),
              raiz = scales::transform_sqrt())
  if (isTRUE(inverter)) t <- scales::transform_compose(t, scales::transform_reverse())
  t
}

# Limites automáticos de um eixo numérico a partir da faixa dos dados (décadas inteiras em log).
.limites_auto <- function(faixa, escala) {
  faixa <- faixa[is.finite(faixa)]
  if (!length(faixa)) return(c(0, 1))
  r <- range(faixa)
  b <- .base_log(escala)
  if (!is.na(b)) {
    r <- r[r > 0]
    if (!length(r)) .erro("Escala logarítmica precisa de valores > 0.")
    r <- range(r)
    lo <- b^floor(log(r[1], b) + 1e-9); hi <- b^ceiling(log(r[2], b) - 1e-9)
    if (lo == hi) { lo <- lo / b; hi <- hi * b }
    return(c(lo, hi))
  }
  if (diff(r) == 0) r <- r + c(-1, 1) * max(abs(r[1]) * 0.1, 1)
  p <- pretty(r, n = 5)
  lim <- range(p)
  if (escala %in% c("raiz") && lim[1] < 0) lim[1] <- 0
  lim
}

# Formata números com ponto decimal, sem zeros sobrando; casas fixas se informado.
.fmt_num <- function(v, casas = NULL, milhar = FALSE) {
  if (!length(v)) return(character(0))
  if (!is.null(casas)) {
    s <- formatC(v, format = "f", digits = casas, big.mark = if (milhar) "," else "",
                 decimal.mark = ".")
  } else {
    fin <- v[is.finite(v)]
    dig <- 0
    if (length(fin)) {
      for (d in 0:10) if (all(abs(round(fin, d) - fin) < 1e-9 * pmax(1, abs(fin)))) { dig <- d; break } else dig <- d
    }
    s <- formatC(v, format = "f", digits = dig, big.mark = if (milhar) "," else "",
                 decimal.mark = ".")
  }
  s[s %in% c("-0", sub("^", "-", formatC(0, format = "f", digits = casas %||% 0)))] <-
    formatC(0, format = "f", digits = casas %||% 0)
  s
}

# Entra: config do eixo. Sai: função que formata os rótulos (notação, casas, prefixo, sufixo, fator).
.formatador <- function(e) {
  casas <- e$casas_decimais
  fator <- e$fator_divisao %||% 1
  pre <- e$prefixo %||% ""; suf <- e$sufixo %||% ""
  notacao <- e$notacao %||% "normal"
  function(x) {
    if (!length(x)) return(character(0))
    na <- is.na(x)
    v <- x / fator
    out <- switch(notacao,
      normal = .fmt_num(v, casas),
      milhar = .fmt_num(v, casas, milhar = TRUE),
      percentual = paste0(.fmt_num(v * 100, casas), "%"),
      cientifica_E = {
        s <- formatC(v, format = "E", digits = casas %||% 1)
        s <- sub("E\\+?(-?)0*([0-9])", "E\\1\\2", s)
        s[v == 0] <- "0"
        if (is.null(casas)) s <- sub("\\.?0+E", "E", s)
        s
      },
      cientifica = , potencia10 = {
        ex <- ifelse(v == 0, 0, floor(log10(abs(v)) + 1e-9))
        m <- v / 10^ex
        expr <- vapply(seq_along(v), function(i) {
          if (is.na(v[i])) return('""')
          if (v[i] == 0) return('"0"')
          mi <- if (is.null(casas)) .fmt_num(round(m[i], 3)) else .fmt_num(m[i], casas)
          if (notacao == "potencia10" && abs(m[i] - round(m[i])) < 1e-9 && round(m[i]) %in% c(1, -1))
            return(paste0(if (m[i] < 0) "-" else "", "10^", ex[i]))
          paste0('"', mi, '"%*%10^', ex[i])
        }, "")
        if (nzchar(pre) || nzchar(suf))
          expr <- paste0(deparse(pre), "*", expr, "*", deparse(suf))
        out <- parse(text = expr)
        return(out)
      }
    )
    out <- paste0(pre, out, suf)
    out[na] <- ""
    out
  }
}

# Calcula a escala de um eixo. Entra: config do eixo (e), valores dos dados (faixa), rótulos das
# categorias (eixo categórico), limites impostos pelos painéis (forcar) e a informação de
# tempo (list(classe, formato) de .detectar_tempo(), para eixo de datas/horas).
# Sai: list(limites, maiores, menores, rotulos, trans, mult, cfg, escala, categorias, tempo).
.calc_eixo <- function(e, faixa, categorias = NULL, forcar = NULL, tempo = NULL) {
  escala <- if (!is.null(categorias)) "linear" else e$escala %||% "linear"
  if (!is.null(tempo) && !identical(escala, "linear"))
    .erro("Eixo de datas/horas exige escala linear (cfg$eixo_x$escala = \"linear\").")
  b <- .base_log(escala)
  if ((!is.na(b) || escala == "reciproco") && is.null(forcar)) {
    ruins <- sum(is.finite(faixa) & faixa <= 0)
    if (ruins && !is.na(b)) .aviso("Escala ", escala, ": ", ruins,
                                   " valor(es) <= 0 não podem ser desenhados e serão omitidos.")
    if (escala == "reciproco" && any(faixa == 0, na.rm = TRUE))
      .aviso("Escala recíproca: valores iguais a 0 (1/0 = infinito) serão omitidos.")
  }
  auto <- if (!is.null(categorias)) c(0.5, length(categorias) + 0.5)
          else if (!is.null(tempo)) .limites_tempo(faixa, tempo$classe)
          else .limites_auto(faixa, escala)
  if (!is.null(forcar)) auto <- forcar
  ini_usuario <- if (!is.null(tempo)) .tempo_num(e$inicio, tempo, "cfg$eixo_x$inicio") else e$inicio
  fim_usuario <- if (!is.null(tempo)) .tempo_num(e$fim, tempo, "cfg$eixo_x$fim") else e$fim
  lo <- ini_usuario %||% auto[1]; hi <- fim_usuario %||% auto[2]
  if (lo >= hi) {
    if (!is.null(tempo) && !is.null(ini_usuario) && !is.null(fim_usuario))
      .erro("cfg$eixo_x$inicio deve ser anterior a cfg$eixo_x$fim.")
    folga <- if (!is.null(tempo)) (if (tempo$classe == "Date") 1 else 3600) else NULL
    if (is.null(ini_usuario)) lo <- hi - (folga %||% (abs(hi) * 0.1 + 1))
    else hi <- lo + (folga %||% (abs(lo) * 0.1 + 1))
  }
  if (!is.na(b) && lo <= 0)
    .erro("Escala logarítmica: o início do eixo deve ser > 0 (atual: ", lo, ").")
  if (escala == "reciproco" && lo <= 0 && hi >= 0)
    .erro("Escala recíproca não pode incluir o zero (", lo, " a ", hi, ").")
  if (escala == "raiz" && lo < 0) .erro("Escala raiz: o início do eixo deve ser >= 0.")
  lim <- c(lo, hi)
  tol <- 1e-9 * max(abs(lim))
  # em escala log a tolerância é relativa (senão 1e-9 "gruda" em 1e-10 num eixo de 10 décadas)
  perto <- function(v, alvo) if (!is.na(b)) abs(v / alvo - 1) <= 1e-9 else abs(v - alvo) <= tol
  dentro <- function(v) if (!is.na(b)) v >= lo * (1 - 1e-9) & v <= hi * (1 + 1e-9) else v >= lo - tol & v <= hi + tol

  modo <- e$ticks_modo %||% "auto"
  if (!is.null(tempo) && modo %in% c("auto", "incremento", "manual")) {
    maiores <- .maiores_tempo(e, lo, hi, tempo, modo)
  } else if (!is.null(categorias) && modo == "auto") {
    maiores <- seq_along(categorias)
  } else if (modo == "auto") {
    maiores <- if (!is.na(b)) {
      ex <- seq(ceiling(log(lo, b) - 1e-9), floor(log(hi, b) + 1e-9))
      if (length(ex) > 8) ex <- ex[ex %% ceiling(length(ex) / 6) == 0]
      if (length(ex) < 2) scales::breaks_log(5, base = b)(lim) else b^ex
    } else if (escala == "reciproco") {
      dec <- 10^(floor(log10(min(abs(lim)))):ceiling(log10(max(abs(lim)))))
      cand <- sort(unique(c(lo, hi, sign(hi) * as.vector(outer(c(1, 1.5, 2, 2.5, 3, 4, 5, 6, 8), dec)))))
      cand <- cand[cand >= lo & cand <= hi & cand != 0]
      alvo <- 1 / seq(1 / hi, 1 / lo, length.out = 6)
      unique(vapply(alvo, function(a) cand[which.min(abs(1 / cand - 1 / a))], 0))
    } else pretty(lim, n = 5)
  } else if (modo == "incremento") {
    if (!is.na(b)) {
      ex0 <- if (!is.null(e$primeiro_tick)) log(e$primeiro_tick, b) else ceiling(log(lo, b) - 1e-9)
      maiores <- b^seq(ex0, log(hi, b) + 1e-9, by = e$incremento)
    } else {
      ini <- e$primeiro_tick %||% lo
      n <- floor((hi - ini) / e$incremento + 1e-9)
      if (n > 1000) .erro("incremento muito pequeno: geraria ", n, " ticks.")
      if (n > 40 && is.null(tempo)) {            # intervalo pequeno demais para a faixa: os números se sobreporiam
        passo <- .passo_bonito((hi - ini) / 8)
        .aviso("O intervalo ", e$incremento, " gera ", n + 1, " traços entre ", signif(ini, 6), " e ", signif(hi, 6),
               " (os números ficariam um sobre o outro); usando ", passo, " neste eixo. ",
               "Com quebra de eixo, defina o intervalo de cada parte (quebra_y_intervalo_* / quebra_y2_intervalo_*).")
        e$incremento <- passo
        n <- floor((hi - ini) / passo + 1e-9)
      }
      maiores <- round(ini + (0:max(n, 0)) * e$incremento, 12)
    }
  } else if (modo == "quantidade") {
    maiores <- if (!is.na(b)) exp(seq(log(lo), log(hi), length.out = e$quantidade))
               else seq(lo, hi, length.out = e$quantidade)
  } else if (modo == "min_max") {
    maiores <- lim
  } else {
    maiores <- e$ticks_manuais
  }
  .ajustar <- function(v) {
    v <- signif(v, 12)
    v[perto(v, lo)] <- lo; v[perto(v, hi)] <- hi
    v
  }
  maiores <- .ajustar(maiores)
  if (modo != "manual") maiores <- maiores[dentro(maiores)]

  # ticks menores
  nm <- if (!is.null(categorias)) 0 else e$n_menores %||% 0
  menores <- NULL
  mm <- sort(unique(maiores))
  if (nm > 0 && length(mm) >= 2) {
    entre <- function(a, z) a + (seq_len(nm)) * (z - a) / (nm + 1)
    menores <- unlist(lapply(seq_len(length(mm) - 1), function(i) entre(mm[i], mm[i + 1])))
    if (!is.na(b) || escala == "reciproco") {
      r1 <- mm[2] / mm[1]; r2 <- mm[length(mm)] / mm[length(mm) - 1]
      ext <- c(entre(mm[1] / r1, mm[1]), entre(mm[length(mm)], mm[length(mm)] * r2))
    } else {
      d1 <- mm[2] - mm[1]; d2 <- mm[length(mm)] - mm[length(mm) - 1]
      ext <- c(unlist(lapply(1:20, function(k) entre(mm[1] - k * d1, mm[1] - (k - 1) * d1))),
               unlist(lapply(1:20, function(k) entre(mm[length(mm)] + (k - 1) * d2, mm[length(mm)] + k * d2))))
    }
    menores <- .ajustar(c(menores, ext))
    menores <- menores[dentro(menores)]
  }

  rotulos <- if (!is.null(e$rotulos_manuais)) as.character(e$rotulos_manuais)
             else if (!is.null(categorias) && modo == "auto") categorias
             else if (!is.null(tempo)) .formatador_tempo(e, tempo$classe, lim, maiores)
             else .formatador(e)
  # painéis colados: esconde o número que encosta no painel vizinho
  ocultar <- e$.ocultar_extremo
  if (!is.null(ocultar)) {
    alvo <- if (identical(ocultar, "max")) hi else lo
    if (is.function(rotulos)) {
      f0 <- rotulos
      rotulos <- function(x) {
        r <- f0(x); sel <- !is.na(x) & perto(x, alvo)
        if (is.expression(r)) { r <- as.list(r); r[sel] <- list(""); return(as.expression(r)) }
        r[sel] <- ""; r
      }
    } else if (is.character(rotulos) && is.null(categorias) && length(rotulos) == length(maiores)) {
      rotulos[perto(maiores, alvo)] <- ""      # rótulos manuais: esconde o do extremo
    }
  }
  list(limites = lim, maiores = maiores, menores = menores %||% numeric(0),
       rotulos = rotulos, trans = .transformacao(escala, e$inverter),
       mult = (e$margem_percentual %||% 0) / 100, cfg = e, escala = escala,
       categorias = categorias, tempo = tempo)
}

# posição (0-1 no painel) de valores num eixo calculado
.npc <- function(v, ax) {
  tl <- sort(ax$trans$transform(ax$limites))
  r <- tl + c(-1, 1) * diff(tl) * ax$mult
  (ax$trans$transform(v) - r[1]) / diff(r)
}

# Passo "redondo" (1, 2, 2.5, 5 x 10^k) mais próximo de 'alvo'.
.passo_bonito <- function(alvo) {
  if (!is.finite(alvo) || alvo <= 0) return(1)
  k <- 10^floor(log10(alvo)); m <- alvo / k
  k * c(1, 2, 2.5, 5, 10)[which.min(abs(c(1, 2, 2.5, 5, 10) - m))]
}

# -----------------------------------------------------------------------------
#  06_eixos_tempo.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/06_eixos_tempo.R — eixo de datas e horas (colunas como 15/03/2024 14:30)
# =============================================================================
#  O eixo continua numérico por dentro: dias desde 1970 (só data) ou segundos
#  desde 1970 em UTC (data e hora). Os ticks e os rótulos é que são calculados
#  como datas. Tudo isto é chamado por .calc_eixo() e .construir_xy().
# =============================================================================

# Formatos de data reconhecidos sozinhos (dia antes do mês, como no Excel em português).
# Para outro formato (ex.: mês/dia/ano) use cfg$eixo_x$formato_data <- "%m/%d/%Y".
.FMT_DATAS <- list(
  list(re = "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}",      f = "%Y-%m-%d"),
  list(re = "[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}",      f = "%d/%m/%Y"),
  list(re = "[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}",      f = "%d-%m-%Y"),
  list(re = "[0-9]{1,2}\\.[0-9]{1,2}\\.[0-9]{4}",  f = "%d.%m.%Y"),
  list(re = "[0-9]{4}/[0-9]{1,2}/[0-9]{1,2}",      f = "%Y/%m/%d"))

# Passos de tick automáticos: nome no formato do seq() e duração aproximada (s).
.PASSOS_TEMPO <- c("1 sec" = 1, "5 sec" = 5, "15 sec" = 15, "30 sec" = 30,
                   "1 min" = 60, "5 min" = 300, "15 min" = 900, "30 min" = 1800,
                   "1 hour" = 3600, "3 hour" = 10800, "6 hour" = 21600, "12 hour" = 43200,
                   "1 day" = 86400, "2 day" = 172800, "1 week" = 604800, "2 week" = 1209600,
                   "1 month" = 2629800, "3 month" = 7889400, "6 month" = 15778800,
                   "1 year" = 31557600, "2 year" = 63115200, "5 year" = 157788000,
                   "10 year" = 315576000, "20 year" = 631152000, "50 year" = 1577880000,
                   "100 year" = 3155760000)

# Unidades aceitas em cfg$eixo_x$incremento (português ou inglês) -> unidade do seq()
.UNIDADES_TEMPO <- c(sec = "sec", secs = "sec", s = "sec", seg = "sec", segundo = "sec", segundos = "sec",
                     min = "min", mins = "min", minuto = "min", minutos = "min",
                     hour = "hour", hours = "hour", h = "hour", hora = "hour", horas = "hour",
                     day = "day", days = "day", d = "day", dia = "day", dias = "day",
                     week = "week", weeks = "week", semana = "week", semanas = "week",
                     month = "month", months = "month", mes = "month", "mês" = "month", meses = "month",
                     year = "year", years = "year", ano = "year", anos = "year")
.SEG_UNIDADE <- c(sec = 1, min = 60, hour = 3600, day = 86400, week = 604800,
                  month = 2629800, year = 31557600)

# Reconhece uma coluna de datas/horas. Entra: vetor (texto, Date ou POSIXct) e, opcional, um
# formato strptime. Sai: NULL (não é data) ou list(classe = "Date"|"POSIXct", num, formato).
# num = posições no eixo (dias para Date, segundos para POSIXct); NA onde o texto é vazio.
.detectar_tempo <- function(v, formato = NULL) {
  if (inherits(v, "Date")) return(list(classe = "Date", num = as.numeric(v), formato = NA_character_))
  if (inherits(v, "POSIXct")) return(list(classe = "POSIXct", num = as.numeric(v), formato = NA_character_))
  if (!is.character(v)) return(NULL)
  vazio <- is.na(v) | !nzchar(trimws(v))
  x <- sub("T", " ", trimws(v[!vazio]), fixed = TRUE)
  if (!length(x)) return(NULL)
  devolver <- function(seg, classe, fmt) {
    num <- rep(NA_real_, length(v))
    num[!vazio] <- if (classe == "Date") seg / 86400 else seg
    list(classe = classe, num = num, formato = fmt)
  }
  if (!is.null(formato) && !is.na(formato) && !identical(formato, "auto")) {
    p <- as.numeric(as.POSIXct(strptime(x, formato, tz = "UTC")))
    if (anyNA(p)) return(NULL)
    return(devolver(p, if (grepl("%[HMSIpTR]", formato)) "POSIXct" else "Date", formato))
  }
  for (fm in .FMT_DATAS) {
    if (!all(grepl(paste0("^", fm$re, "( [0-9]{1,2}:[0-9]{2}(:[0-9]{2})?)?$"), x))) next
    com_seg <- grepl(":[0-9]{2}:[0-9]{2}$", x)
    com_hm <- !com_seg & grepl(":", x, fixed = TRUE)
    so_data <- !com_seg & !com_hm
    seg <- rep(NA_real_, length(x))
    ler <- function(sel, f) as.numeric(as.POSIXct(strptime(x[sel], f, tz = "UTC")))
    if (any(com_seg)) seg[com_seg] <- ler(com_seg, paste(fm$f, "%H:%M:%S"))
    if (any(com_hm))  seg[com_hm]  <- ler(com_hm, paste(fm$f, "%H:%M"))
    if (any(so_data)) seg[so_data] <- ler(so_data, fm$f)
    if (anyNA(seg)) next                         # data impossível (ex.: 31/02): tenta o próximo formato
    return(devolver(seg, if (any(com_seg | com_hm)) "POSIXct" else "Date", fm$f))
  }
  NULL
}

# Interpreta "1 month", "2 semanas", "6 horas"... Sai: NULL ou list(n, un, by, seg).
.passo_tempo <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) return(NULL)
  m <- regmatches(tolower(x), regexec("^\\s*([0-9]+)\\s*([^0-9[:space:]]+)\\s*$", tolower(x)))[[1]]
  if (length(m) != 3) return(NULL)
  un <- unname(.UNIDADES_TEMPO[m[3]])
  n <- as.integer(m[2])
  if (is.na(un) || is.na(n) || n < 1) return(NULL)
  list(n = n, un = un, by = paste(n, un), seg = n * unname(.SEG_UNIDADE[un]))
}

# Posição no eixo -> objeto Date ou POSIXct (UTC)
.eixo_para_tempo <- function(v, classe) {
  if (classe == "Date") as.Date(v, origin = "1970-01-01")
  else as.POSIXct(v, origin = "1970-01-01", tz = "UTC")
}

# Converte um limite/tick dado pelo usuário (texto, Date, POSIXct ou número) para a posição
# no eixo. Número é aceito como já está na unidade do eixo (dias ou segundos).
.tempo_num <- function(v, tempo, onde) {
  if (is.null(v)) return(NULL)
  if (is.numeric(v)) return(as.numeric(v))
  d <- .detectar_tempo(v, tempo$formato)
  if (is.null(d) && is.character(v)) d <- .detectar_tempo(v)
  if (is.null(d) || anyNA(d$num))
    .erro(onde, ": não entendi a data '", paste(v, collapse = "', '"),
          "'. Use \"2024-03-15\", \"15/03/2024\" ou \"15/03/2024 14:30\".")
  if (d$classe == tempo$classe) d$num
  else if (tempo$classe == "POSIXct") d$num * 86400   # data -> segundos
  else d$num / 86400                                  # data/hora -> dias
}

# Primeiro tick <= lo alinhado ao passo (início do mês, da semana, do ano, da hora...)
.alinhar_tempo <- function(lo, passo, classe) {
  por_dia <- if (classe == "Date") 1 else 86400
  if (passo$un %in% c("month", "year")) {
    d <- .eixo_para_tempo(lo, classe)
    y <- as.integer(format(d, "%Y")); m <- as.integer(format(d, "%m"))
    ini <- if (passo$un == "month") as.Date(sprintf("%04d-%02d-01", y, ((m - 1L) %/% passo$n) * passo$n + 1L))
           else as.Date(sprintf("%04d-01-01", (y %/% passo$n) * passo$n))
    return(as.numeric(ini) * por_dia)
  }
  u <- passo$seg / (if (classe == "Date") 86400 else 1)    # duração do passo na unidade do eixo
  if (passo$un == "week") return(floor((lo - 4 * por_dia) / u) * u + 4 * por_dia)   # semanas começam na segunda
  floor(lo / u) * u
}

# Sequência de ticks entre ini e fim (posições no eixo) a cada 'passo'
.sequencia_tempo <- function(ini, fim, passo, classe) {
  if (classe == "Date" && passo$un %in% c("sec", "min", "hour"))
    .erro("O eixo tem só datas (sem hora): use passos de dia, semana, mês ou ano em vez de '", passo$by, "'.")
  if (ini > fim) return(numeric(0))
  if ((fim - ini) * (if (classe == "Date") 86400 else 1) / passo$seg > 2000)
    .erro("O passo '", passo$by, "' geraria mais de 2000 ticks no eixo. Use um passo maior.")
  s <- seq(.eixo_para_tempo(ini, classe), .eixo_para_tempo(fim, classe), by = passo$by)
  as.numeric(s)
}

# Ticks automáticos "redondos" (cerca de 'alvo' deles). cobrir = TRUE estende até passar de hi.
.quebras_tempo <- function(lo, hi, classe, alvo = 6, cobrir = FALSE) {
  por_dia <- if (classe == "Date") 1 else 86400
  cand <- .PASSOS_TEMPO
  if (classe == "Date") cand <- cand[cand >= 86400]
  n_ticks <- pmax((hi - lo) / por_dia * 86400 / cand, 1e-9)
  passo <- .passo_tempo(names(cand)[which.min(abs(log(n_ticks / alvo)))])
  ini <- .alinhar_tempo(lo, passo, classe)
  tk <- .sequencia_tempo(ini, hi + passo$seg * 1.1 / (86400 / por_dia), passo, classe)
  if (!cobrir) return(tk[tk <= hi])
  i <- which(tk >= hi)[1]
  if (is.na(i)) tk else tk[seq_len(i)]
}

# Limites automáticos do eixo de tempo: arredonda os dados para fora até um tick redondo
.limites_tempo <- function(faixa, classe) {
  r <- range(faixa[is.finite(faixa)])
  if (diff(r) == 0) r <- r + c(-1, 1) * (if (classe == "Date") 1 else 3600)
  range(.quebras_tempo(r[1], r[2], classe, cobrir = TRUE))
}

# Ticks maiores em eixo de tempo nos modos "auto", "incremento" e "manual".
.maiores_tempo <- function(e, lo, hi, tempo, modo) {
  if (modo == "manual") return(.tempo_num(e$ticks_manuais, tempo, "cfg$eixo_x$ticks_manuais"))
  if (modo == "auto") return(.quebras_tempo(lo, hi, tempo$classe))
  passo <- .passo_tempo(e$incremento)
  ini <- .tempo_num(e$primeiro_tick, tempo, "cfg$eixo_x$primeiro_tick") %||% lo
  if (!is.null(passo)) return(.sequencia_tempo(ini, hi, passo, tempo$classe))
  if (!is.numeric(e$incremento))
    .erro("cfg$eixo_x$incremento = '", e$incremento, "' não é um passo de tempo válido. ",
          "Exemplos: \"1 day\", \"2 semanas\", \"1 mes\", \"6 horas\", \"30 min\".")
  ini + (0:floor((hi - ini) / e$incremento + 1e-9)) * e$incremento
}

# Formatador dos rótulos de um eixo de tempo. O formato automático depende do passo entre os ticks
# (anos -> "2024"; meses -> "03/2024"; dias -> "15/03"; horas -> "14:30"): só números, para não
# depender do idioma do computador. cfg$eixo_x$formato_rotulo_data troca o formato.
# Entra: config do eixo, classe, limites e os ticks maiores (posições no eixo).
.formatador_tempo <- function(e, classe, lim, maiores = NULL) {
  por_dia <- if (classe == "Date") 1 else 86400
  dias <- (lim[2] - lim[1]) / por_dia
  passo <- if (length(maiores) >= 2) stats::median(diff(sort(maiores))) / por_dia * 86400 else dias * 86400 / 5
  fmt <- e$formato_rotulo_data %||% if (passo >= 300 * 86400) "%Y"
    else if (passo >= 25 * 86400) "%m/%Y"
    else if (passo >= 0.9 * 86400) (if (dias > 300) "%d/%m/%y" else "%d/%m")
    else if (passo >= 60) (if (dias >= 1) "%d/%m %H:%M" else "%H:%M")
    else "%H:%M:%S"
  pre <- e$prefixo %||% ""; suf <- e$sufixo %||% ""
  function(x) {
    out <- format(.eixo_para_tempo(x, classe), fmt)
    out <- paste0(pre, out, suf)
    out[is.na(x)] <- ""
    out
  }
}

# -----------------------------------------------------------------------------
#  07_tema.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/07_tema.R — tema (caixa, ticks, rótulos, grade, legenda) e fontes
# =============================================================================

# =============================================================================
#  TEMA (aparência: caixa, ticks, rótulos, grade, legenda)
# =============================================================================
# Comprimento do tick com sinal: negativo = para dentro, 0 = nenhum.
.comp_tick <- function(direcao, comp) {
  switch(direcao %||% "dentro", dentro = -comp, fora = comp, ambos = comp, nenhum = 0)
}

# Elemento de tema para os números de um eixo (tamanho, cor, rotação, distância).
.elem_rotulo <- function(e, cfg, lado, cor_forcada = NULL) {
  if (!isTRUE(e$mostrar_rotulos %||% TRUE)) return(element_blank())
  d <- e$distancia_rotulos_pt %||% 3
  m <- switch(lado, bottom = margin(t = d), top = margin(b = d),
              left = margin(r = d), right = margin(l = d))
  ang <- e$rotacao_rotulos %||% 0
  just <- if (ang == 0) list(h = NULL, v = NULL) else switch(lado,
    bottom = list(h = 1, v = if (ang == 90) 0.5 else 1),
    top = list(h = 0, v = if (ang == 90) 0.5 else 0),
    left = list(h = 1, v = 0.5), right = list(h = 0, v = 0.5))
  element_text(size = e$tamanho_rotulos_pt %||% cfg$texto$tamanho_base_pt,
               colour = cor_forcada %||% e$cor_rotulos %||% cfg$texto$cor,
               face = if (isTRUE(e$negrito_rotulos)) "bold" else "plain",
               angle = ang, hjust = just$h, vjust = just$v, margin = m)
}

# Elemento de tema para o título de um eixo (tamanho, cor, estilo, distância).
.elem_titulo <- function(e, cfg, lado, cor_forcada = NULL) {
  if (!isTRUE(e$mostrar_titulo %||% TRUE)) return(element_blank())
  d <- e$distancia_titulo_pt %||% 4
  m <- switch(lado, bottom = margin(t = d), top = margin(b = d),
              left = margin(r = d), right = margin(l = d))
  face <- if (isTRUE(e$negrito_titulo) && isTRUE(e$italico_titulo)) "bold.italic"
          else if (isTRUE(e$negrito_titulo)) "bold" else if (isTRUE(e$italico_titulo)) "italic" else "plain"
  element_text(size = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt,
               colour = cor_forcada %||% e$cor_titulo %||% cfg$texto$cor, face = face,
               angle = switch(lado, left = 90, right = -90, 0), margin = m)
}

# Entra: cfg, config do eixo horizontal e do vertical (como aparecem na tela) e os lados com eixo.
# Sai: tema ggplot2 completo.
.tema <- function(cfg, eh, ev, lados, sem_eixos = FALSE, cor_y2 = NULL) {
  # eh = config do eixo HORIZONTAL na tela; ev = do VERTICAL
  # lados = lista(hor = c("bottom", "top"?), ver = c("left", "right"?)), lado_principal
  tx <- cfg$texto; cx <- cfg$caixa; gr <- cfg$grade; lg <- cfg$legenda
  fonte <- .fonte(tx$fonte)
  fundo <- function(v) if (identical(v, "transparente")) NA else .cor(v)
  t <- theme_grey(base_size = tx$tamanho_base_pt, base_family = fonte) +
    theme(text = element_text(colour = tx$cor, family = fonte),
          plot.background = element_rect(fill = fundo(cx$fundo_pagina), colour = NA),
          panel.background = element_rect(fill = fundo(cx$fundo_painel), colour = NA),
          plot.margin = margin(cx$margens_cm[1], cx$margens_cm[2], cx$margens_cm[3],
                               cx$margens_cm[4], unit = "cm"),
          aspect.ratio = cx$proporcao,
          strip.background = element_blank())
  # grade (respeita o que está na horizontal/vertical da TELA)
  gl <- function(on, cor, esp, tipo, opac = 1) {
    if (!isTRUE(on)) return(element_blank())
    element_line(colour = .alfa(.cor(cor, "grade"), opac), linewidth = .lw(esp), linetype = tipo)
  }
  t <- t + theme(
    panel.grid.major.x = gl(lados$grade_x_maior, gr$cor_maior, gr$espessura_maior_pt, gr$tipo_maior,
                            gr$opacidade_maior),
    panel.grid.major.y = gl(lados$grade_y_maior, gr$cor_maior, gr$espessura_maior_pt, gr$tipo_maior,
                            gr$opacidade_maior),
    panel.grid.minor.x = gl(lados$grade_x_menor, gr$cor_menor, gr$espessura_menor_pt, gr$tipo_menor,
                            gr$opacidade_menor),
    panel.grid.minor.y = gl(lados$grade_y_menor, gr$cor_menor, gr$espessura_menor_pt, gr$tipo_menor,
                            gr$opacidade_menor))
  if (sem_eixos) {
    t <- t + theme(axis.text = element_blank(), axis.title = element_blank(),
                   axis.ticks = element_blank(), axis.line = element_blank(),
                   panel.grid = element_blank(), panel.border = element_blank())
  } else {
    # caixa / linhas de eixo
    if (isTRUE(cx$fechada)) {
      t <- t + theme(panel.border = element_rect(fill = NA, colour = .cor(cx$cor), linewidth = .lw(cx$espessura_pt)),
                     axis.line = element_blank())
    } else {
      # linha de cada eixo (só se mostrar_linha e, nos lados opostos, só se o lado existe)
      linha <- function(e, ativo, cor = NULL, ponta = NULL) {
        if (!(isTRUE(e$mostrar_linha) && ativo)) return(element_blank())
        element_line(colour = cor %||% e$cor_linha, linewidth = .lw(e$espessura_linha_pt), lineend = ponta)
      }
      t <- t + theme(panel.border = element_blank(),
        axis.line.x.bottom = linha(eh, TRUE, ponta = "square"),
        axis.line.y.left   = linha(ev, TRUE, ponta = "square"),
        axis.line.y.right  = linha(ev, "right" %in% lados$ver, cor = cor_y2),
        axis.line.x.top    = linha(eh, "top" %in% lados$hor))
    }
    # ticks
    tk <- function(e, cor = NULL) element_line(colour = cor %||% e$cor_ticks, linewidth = .lw(e$espessura_ticks_pt))
    for (lado in c("bottom", "top", "left", "right")) {
      e <- if (lado %in% c("bottom", "top")) eh else ev
      xy <- if (lado %in% c("bottom", "top")) "x" else "y"
      cor_l <- if (lado == lados$lado_y2) cor_y2 else NULL
      el <- list()
      el[[paste0("axis.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.ticks.length.", xy, ".", lado)]] <- unit(.comp_tick(e$direcao_maiores, e$comprimento_maiores_pt),
                                                                "pt")
      el[[paste0("axis.minor.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.minor.ticks.length.", xy, ".",
                 lado)]] <- unit(.comp_tick(e$direcao_menores, e$comprimento_menores_pt), "pt")
      el[[paste0("axis.text.", xy, ".", lado)]] <- .elem_rotulo(e, cfg, lado, cor_l)
      el[[paste0("axis.title.", xy, ".", lado)]] <- .elem_titulo(e, cfg, lado, cor_l)
      t <- t + do.call(theme, el)
    }
  }
  # legenda
  t <- t + .tema_legenda(cfg, fonte)
  # títulos
  ti <- cfg$titulos
  hj <- switch(ti$alinhamento, esquerda = 0, centro = 0.5, direita = 1)
  t + theme(plot.title = element_text(hjust = hj, size = ti$tamanho_titulo_pt %||% (tx$tamanho_base_pt * 1.2),
                                      face = if (isTRUE(ti$negrito_titulo)) "bold" else "plain"),
            plot.subtitle = element_text(hjust = hj, size = ti$tamanho_subtitulo_pt %||% tx$tamanho_base_pt),
            plot.title.position = "panel")
}

# Parte do tema que controla posição, moldura, fundo, textos e espaçamento da legenda.
.tema_legenda <- function(cfg, fonte) {
  lg <- cfg$legenda; tx <- cfg$texto
  pos <- switch(lg$posicao, dentro = "inside", direita = "right", esquerda = "left",
                topo = "top", base = "bottom")
  sombra <- isTRUE(lg$sombra)
  fundo <- if (identical(lg$fundo, "transparente")) { if (sombra) "white" else NA } else .cor(lg$fundo)
  if (!is.na(fundo) && (lg$fundo_opacidade %||% 1) < 1) fundo <- .alfa(fundo, lg$fundo_opacidade)
  caixa <- element_rect(fill = fundo, colour = if (isTRUE(lg$moldura)) .cor(lg$cor_moldura) else NA,
                        linewidth = .lw(lg$espessura_moldura_pt))
  if (!identical(lg$tipo_moldura %||% "solid", "solid")) caixa <- element_rect(fill = fundo, colour = caixa$colour,
                                                                               linewidth = caixa$linewidth,
                                                                               linetype = lg$tipo_moldura)
  if (sombra) {
    d <- rep_len(lg$sombra_deslocamento_pt, 2)
    attr(caixa, "sombra") <- list(cor = .alfa(.cor(lg$sombra_cor), lg$sombra_opacidade), dx = d[1], dy = d[2])
    class(caixa) <- c("element_sombra", class(caixa))
  }
  esc <- lg$escala %||% 1                      # aumenta/diminui tudo na legenda: texto, quadradinhos, espaços e folgas
  t <- theme(
    legend.position = pos,
    legend.background = caixa,
    legend.key = element_rect(fill = NA, colour = NA),
    legend.key.size = unit(lg$tamanho_chave_pt * esc, "pt"),
    legend.key.spacing.y = unit(lg$espacamento_pt * esc, "pt"),
    legend.text = element_text(size = (lg$tamanho_texto_pt %||% tx$tamanho_base_pt) * esc),
    legend.title = if (is.null(lg$titulo)) element_blank() else
      element_text(size = (lg$tamanho_titulo_pt %||% tx$tamanho_base_pt) * esc),
    legend.margin = do.call(margin, as.list(lg$margem_interna_pt * esc)))
  if (pos == "inside") {
    anc <- if (identical(lg$ancora, "auto")) c(lg$dentro_x, lg$dentro_y) else lg$ancora
    t <- t + theme(legend.position.inside = c(lg$dentro_x, lg$dentro_y),
                   legend.justification.inside = anc)
    if (!is.null(lg$distancia_pt)) {            # distância da legenda até a borda da caixa, em pt (para dentro)
      d <- rep_len(lg$distancia_pt, 2)
      t <- t + theme(legend.box.margin = margin(t = if (anc[2] > 0.5) d[2] else 0, r = if (anc[1] > 0.5) d[1] else 0,
                                                b = if (anc[2] < 0.5) d[2] else 0, l = if (anc[1] < 0.5) d[1] else 0))
    }
  }
  if (pos %in% c("top", "bottom")) t <- t + theme(legend.direction = "horizontal")
  if (!is.null(lg$direcao)) t <- t + theme(legend.direction = lg$direcao)
  if (!is.null(lg$alinhar) && pos != "inside") {
    j <- c(esquerda = 0, base = 0, centro = 0.5, topo = 1, direita = 1)[[lg$alinhar]]
    t <- t + theme(legend.justification = if (pos %in% c("top", "bottom")) c(j, 0.5) else c(0.5, j))
  }
  t
}

# Retângulo da legenda com sombra projetada: o element_rect comum, precedido de um retângulo deslocado.
# (Método S3 próprio, registrado no ggplot2 — funciona igual no 3.5 e no 4.0.)
.element_grob_sombra <- function(element, ...) {
  base <- NextMethod()
  sh <- attr(element, "sombra")
  sombra <- grid::rectGrob(x = unit(0.5, "npc") + unit(sh$dx, "pt"), y = unit(0.5, "npc") - unit(sh$dy, "pt"),
                           width = unit(1, "npc"), height = unit(1, "npc"), gp = gpar(fill = sh$cor, col = NA))
  grid::gTree(children = grid::gList(sombra, base))
}
registerS3method("element_grob", "element_sombra", .element_grob_sombra, envir = asNamespace("ggplot2"))

.fontes_cache <- new.env()
# Nome de fonte utilizável: o pedido se existir no sistema; senão 'sans', com aviso.
.fonte <- function(f) {
  if (is.null(f) || f %in% c("sans", "serif", "mono", "")) return(f %||% "sans")
  if (!is.null(.fontes_cache[[f]])) return(.fontes_cache[[f]])
  ok <- TRUE
  if (.tem("systemfonts")) {
    fams <- unique(.familias_fontes())
    ok <- tolower(f) %in% tolower(fams)
  }
  res <- if (ok) f else {
    .aviso("Fonte '", f, "' não encontrada no sistema; usando 'sans'. Veja listar_fontes().")
    "sans"
  }
  .fontes_cache[[f]] <- res
  res
}

# Bordas do painel para annotation_custom(). O ggplot2 4.0 lê esses limites em unidades de DADOS e os
# transforma pela escala: em log/raiz/recíproca -Inf viraria NaN (e um aviso), então usa as bordas reais.
# O ggplot2 3.5 NÃO transforma (já espera espaço transformado), e lá c(-Inf, Inf) serve para qualquer escala.
.borda_painel <- function(ax) {
  if (!.GG4 || is.null(ax) || identical(ax$escala, "linear") || !is.null(ax$categorias)) return(c(-Inf, Inf))
  r <- sort(ax$trans$transform(ax$limites))
  r <- r + c(-1, 1) * diff(r) * ax$mult
  sort(ax$trans$inverse(r))
}

# Ticks menores do eixo Y2: o sec_axis() do ggplot2 não os desenha na escala própria do Y2, então
# são traços no lado direito nas posições dos menores calculados para o Y2.
# Entra: y2 (list(ax, para1, cor)), eixo Y1 calculado e a config do eixo vertical.
.ticks_y2_menores <- function(y2, ax_y, ev, ax_x = NULL) {
  menores <- y2$ax$menores
  dir <- ev$direcao_menores %||% "dentro"
  if (!length(menores) || identical(dir, "nenhum") || is.null(y2$para1)) return(NULL)
  p <- .npc(y2$para1(menores), ax_y)
  p <- p[p >= -1e-6 & p <= 1 + 1e-6]
  if (!length(p)) return(NULL)
  L <- unit(ev$comprimento_menores_pt, "pt")
  gp <- gpar(col = .cor(y2$cor), lwd = .lw(ev$espessura_ticks_pt) * ggplot2::.pt, lineend = "butt")
  x0 <- unit(1, "npc"); y <- unit(p, "npc")
  filhos <- switch(dir,
    dentro = list(segmentsGrob(x0, y, x0 - L, y, gp = gp)),
    fora   = list(segmentsGrob(x0, y, x0 + L, y, gp = gp)),
    ambos  = list(segmentsGrob(x0, y, x0 - L, y, gp = gp), segmentsGrob(x0, y, x0 + L, y, gp = gp)))
  bx <- .borda_painel(ax_x); by <- .borda_painel(ax_y)
  annotation_custom(gTree(children = do.call(gList, filhos)), xmin = bx[1], xmax = bx[2], ymin = by[1], ymax = by[2])
}

# Ticks "ambos" (cruzando o eixo): parte interna desenhada como anotação
.ticks_internos <- function(axh, axv, lados, ax_x = NULL, ax_y = NULL) {
  segs <- list()
  add <- function(ax, lado) {
    e <- ax$cfg
    for (tipo in c("maiores", "menores")) {
      dir <- if (tipo == "maiores") e$direcao_maiores else e$direcao_menores
      if (!identical(dir, "ambos")) next
      v <- if (tipo == "maiores") ax$maiores else ax$menores
      if (!length(v)) next
      p <- .npc(v, ax); p <- p[p >= -1e-6 & p <= 1 + 1e-6]
      L <- unit(if (tipo == "maiores") e$comprimento_maiores_pt else e$comprimento_menores_pt, "pt")
      gp <- gpar(col = e$cor_ticks, lwd = .lw(e$espessura_ticks_pt) * ggplot2::.pt, lineend = "butt")
      g <- switch(lado,
        bottom = segmentsGrob(unit(p, "npc"), unit(0, "npc"), unit(p, "npc"), L, gp = gp),
        top    = segmentsGrob(unit(p, "npc"), unit(1, "npc"), unit(p, "npc"), unit(1, "npc") - L, gp = gp),
        left   = segmentsGrob(unit(0, "npc"), unit(p, "npc"), L, unit(p, "npc"), gp = gp),
        right  = segmentsGrob(unit(1, "npc"), unit(p, "npc"), unit(1, "npc") - L, unit(p, "npc"), gp = gp))
      segs[[length(segs) + 1]] <<- g
    }
  }
  for (l in lados$hor) add(axh, l)
  for (l in lados$ver) if (!(l == lados$lado_y2)) add(axv, l)
  if (!length(segs)) return(NULL)
  bx <- .borda_painel(ax_x); by <- .borda_painel(ax_y)   # eixos de DADOS (antes de qualquer coord_flip)
  annotation_custom(do.call(gTree, list(children = do.call(gList, segs))),
                    xmin = bx[1], xmax = bx[2], ymin = by[1], ymax = by[2])
}

# -----------------------------------------------------------------------------
#  08_tipos_comum.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/08_tipos_comum.R — auxiliares comuns aos construtores de gráfico
# =============================================================================

# =============================================================================
#  CONSTRUÇÃO POR TIPO — cada função devolve list(camadas, info)
# =============================================================================
# Entra: dados e colunas Y. Sai: data.frame longo (x, y, serie, mapa, barras de erro) de todas as séries.
.serie_longa <- function(dados, xcol, ycols, est, mapa_col = NULL) {
  do.call(rbind, lapply(ycols, function(yc) {
    e <- est[[yc]]
    d <- data.frame(x = dados[[xcol]], y = dados[[yc]], serie = yc, stringsAsFactors = FALSE)
    d$mapa <- if (is.null(mapa_col)) NA_real_ else dados[[mapa_col]]
    erro_col <- function(ref, nome) {
      if (is.null(ref)) return(rep(NA_real_, nrow(dados)))
      cc <- .coluna(dados, ref, paste0("cfg$series[[\"", yc, "\"]]$", nome))
      if (!is.numeric(dados[[cc]])) .erro("Coluna de erro '", cc, "' não é numérica.")
      dados[[cc]]
    }
    d$e_inf <- erro_col(e$erro_inf %||% e$erro, "coluna_erro")
    d$e_sup <- erro_col(e$erro_sup %||% e$erro, "coluna_erro")
    d$e_x <- erro_col(e$erro_x, "coluna_erro_x")
    d
  }))
}

# Guarda o gerador de números aleatórios da sessão e devolve a função que o restaura
# (os gráficos com sorteio, como o jitter do boxplot, não podem mexer na semente do usuário).
.guardar_rng <- function() {
  existia <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  antigo <- if (existia) get(".Random.seed", envir = globalenv(), inherits = FALSE)
  function() {
    if (existia) assign(".Random.seed", antigo, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
      rm(".Random.seed", envir = globalenv())
  }
}

# Nomes das colunas Y a plotar (cfg$grafico$colunas_y ou todas as numéricas, sem as de erro/mapa de cor).
.colunas_y <- function(dados, cfg, excluir = NULL, so_numericas = TRUE) {
  g <- cfg$grafico
  ys <- if (is.null(g$colunas_y)) {
    setdiff(names(dados)[vapply(dados, is.numeric, logical(1))], excluir)
  } else vapply(g$colunas_y, function(r) .coluna(dados, r, "cfg$grafico$colunas_y"), "")
  # tira colunas usadas como erro ou como mapa de cor (referidas por nome OU por número)
  nome_da_coluna <- function(r) if (is.numeric(r) && r >= 1 && r <= ncol(dados)) names(dados)[r] else as.character(r)
  refs <- unlist(lapply(cfg$series, function(s) list(s$coluna_erro, s$coluna_erro_inferior,
                                                     s$coluna_erro_superior, s$coluna_erro_x)),
                 recursive = FALSE)     # lista plana: mantém número como número e texto como texto
  usadas_erro <- vapply(Filter(Negate(is.null), refs), nome_da_coluna, "")
  if (is.null(g$colunas_y)) ys <- setdiff(ys, usadas_erro)
  if (!is.null(cfg$cores$mapear_coluna) && is.null(g$colunas_y))
    ys <- setdiff(ys, nome_da_coluna(cfg$cores$mapear_coluna))
  if (!length(ys)) .erro("Nenhuma coluna Y numérica encontrada. Defina cfg$grafico$colunas_y.")
  if (so_numericas) for (y in ys) if (!is.numeric(dados[[y]]))
    .erro("A coluna '", y, "' não é numérica (veja o relatório de leitura). ",
          "Se o arquivo usa vírgula decimal, defina cfg$dados$decimal_virgula <- TRUE.")
  if (!is.null(g$ordem_itens)) ys <- c(intersect(g$ordem_itens, ys), setdiff(ys, g$ordem_itens))
  ys
}

# -----------------------------------------------------------------------------
#  09_tipo_xy.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/09_tipo_xy.R — pontos, linhas e áreas
# =============================================================================

# ---- Pontos / linhas / áreas --------------------------------------------------
# Config do eixo Y2: a do eixo Y com o que o eixo_y2 define por cima (limites, ticks, formato). O divisor
# dos números (fator_divisao) é o do eixo_y2 se existir; senão herda o do eixo_y, como sempre foi.
.eixo_y2_efetivo <- function(cfg) {
  e2 <- utils::modifyList(cfg$eixo_y, cfg$eixo_y2[intersect(names(cfg$eixo_y2), names(cfg$eixo_y))])
  e2$fator_divisao <- cfg$eixo_y2$fator_divisao %||% cfg$eixo_y$fator_divisao
  e2$escala <- "linear"; e2$inverter <- FALSE
  e2
}
# Avisa quantos pontos saem do gráfico por não existirem na escala do eixo (<= 0 em log, 0 em 1/x).
.avisar_omitidos <- function(n, eixo, escala) {
  if (n > 0)
    .aviso("Eixo ", eixo, " em escala ", escala, ": ", n, " ponto(s) com valor ",
           if (identical(escala, "reciproco")) "igual a 0" else "<= 0",
           " não existe(m) nessa escala e foi(ram) omitido(s) do gráfico.")
}

# Decide se a coluna X de texto é um eixo de datas (cfg$eixo_x$tempo = "auto", TRUE ou FALSE).
# Sai: NULL (eixo categórico) ou o resultado de .detectar_tempo().
.tempo_do_eixo <- function(v, e) {
  modo <- e$tempo %||% "auto"
  if (identical(modo, FALSE)) return(NULL)
  d <- .detectar_tempo(v, e$formato_data)
  if (is.null(d) && isTRUE(modo))
    .erro("cfg$eixo_x$tempo = TRUE, mas a coluna X não é reconhecida como data. ",
          "Defina cfg$eixo_x$formato_data (ex.: \"%d/%m/%Y %H:%M\").")
  d
}

# Pontos, linhas e áreas. Entra: dados e cfg. Sai: list(camadas, info) com os eixos já calculados.
.construir_xy <- function(dados, cfg) {
  tipo <- cfg$grafico$tipo; L <- cfg$linhas
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  cats <- NULL; tempo <- NULL
  if (!is.numeric(dados[[xcol]])) {
    d_tempo <- .tempo_do_eixo(dados[[xcol]], cfg$eixo_x)
    if (!is.null(d_tempo)) {                     # coluna de datas/horas: eixo temporal
      dados[[xcol]] <- d_tempo$num
      tempo <- d_tempo[c("classe", "formato")]
    } else {                                     # texto: eixo categórico
      cats <- unique(as.character(dados[[xcol]][!is.na(dados[[xcol]])]))
      dados[[xcol]] <- match(as.character(dados[[xcol]]), cats)
    }
  }
  est <- .estilos(cfg, ycols)
  mc <- if (!is.null(cfg$cores$mapear_coluna)) .coluna(dados, cfg$cores$mapear_coluna,
                                                       "cfg$cores$mapear_coluna") else NULL
  if (!is.null(mc) && !is.numeric(dados[[mc]])) .erro("cfg$cores$mapear_coluna: a coluna '", mc,
                                                      "' precisa ser numérica.")
  d <- .serie_longa(dados, xcol, ycols, est, mc)
  invalido <- function(v, esc) if (!is.na(.base_log(esc %||% "linear"))) !is.na(v) & v <= 0
                               else if (identical(esc, "reciproco")) !is.na(v) & v == 0 else rep(FALSE, length(v))
  if (is.null(cats)) {
    inv_x <- invalido(d$x, cfg$eixo_x$escala)
    .avisar_omitidos(sum(inv_x), "X", cfg$eixo_x$escala)
    d$x[inv_x] <- NA
  }
  inv_y <- invalido(d$y, cfg$eixo_y$escala)
  .avisar_omitidos(sum(inv_y), "Y", cfg$eixo_y$escala)
  d$y[inv_y] <- NA
  d <- d[!is.na(d$x), ]
  d$serie <- factor(d$serie, levels = ycols)
  if (isTRUE(L$ordenar_x)) d <- d[order(d$serie, d$x), ]

  usa_y2 <- isTRUE(cfg$eixo_y2$ativo) && identical(cfg$eixo_y2$modo, "independente")
  ser_y2 <- if (usa_y2) ycols[vapply(est, function(e) identical(e$eixo, "y2"), logical(1))] else character(0)
  # quebra de eixo sem ligar através: cada série só mostra os valores desta parte (Y1 e Y2 têm faixas próprias)
  rec <- cfg$.interno$recortar_y; rec2 <- cfg$.interno$recortar_y2 %||% rec
  if (!is.null(rec)) {
    r <- if (length(ser_y2)) { e2 <- d$serie %in% ser_y2; list(lo = ifelse(e2, rec2[1], rec[1]),
                                                               hi = ifelse(e2, rec2[2], rec[2])) }
         else list(lo = rec[1], hi = rec[2])
    d <- d[is.na(d$y) | (d$y >= r$lo & d$y <= r$hi), ]
  }
  if (usa_y2 && !length(ser_y2))
    .erro("eixo_y2 ativo no modo \"independente\", mas nenhuma série tem eixo = \"y2\".\n",
          "  Ex.: cfg$series[[\"", ycols[length(ycols)], "\"]] <- list(eixo = \"y2\")")

  com_pontos <- tipo %in% c("pontos", "linha_pontos")
  com_linha <- tipo %in% c("linha", "linha_pontos", "area", "area_empilhada")
  preench <- L$preencher_area
  if (tipo == "area" && preench == "nenhum") preench <- "ate_zero"

  # empilhamento
  if (tipo == "area_empilhada") {
    if (usa_y2) .erro("area_empilhada não combina com eixo_y2.")
    larga <- stats::reshape(d[, c("x", "y", "serie")], idvar = "x", timevar = "serie", direction = "wide")
    larga <- larga[order(larga$x), ]
    acum <- 0
    pilha <- list()
    for (s in ycols) {
      v <- larga[[paste0("y.", s)]]; v[is.na(v)] <- 0
      pilha[[s]] <- data.frame(x = larga$x, ymin = acum, y = acum + v, serie = s)
      acum <- acum + v
    }
    d <- do.call(rbind, pilha); d$serie <- factor(d$serie, levels = ycols)
    d$e_inf <- d$e_sup <- d$e_x <- NA_real_
  }

  # faixa de dados para Y1 e Y2
  d1 <- d[!d$serie %in% ser_y2, ]
  faixa_y <- c(d1$y, d1$y - d1$e_inf, d1$y + d1$e_sup, if (tipo == "area_empilhada") 0,
               if (preench == "ate_zero") 0)
  faixa_x <- c(d$x, d$x - d$e_x, d$x + d$e_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  ax_x <- .calc_eixo(cfg$eixo_x, faixa_x, categorias = cats, forcar = cfg$.interno$forcar_x, tempo = tempo)

  y2 <- NULL
  if (usa_y2) {
    if (ax_y$escala != "linear") .erro("eixo_y2 \"independente\" exige eixo_y linear.")
    d2 <- d[d$serie %in% ser_y2, ]
    e2 <- .eixo_y2_efetivo(cfg)
    ax2 <- .calc_eixo(e2, c(d2$y, d2$y - d2$e_inf, d2$y + d2$e_sup))
    l1 <- ax_y$limites; l2 <- ax2$limites
    para1 <- function(v) l1[1] + (v - l2[1]) * diff(l1) / diff(l2)
    para2 <- function(v) l2[1] + (v - l1[1]) * diff(l2) / diff(l1)
    sel <- d$serie %in% ser_y2
    d$y[sel] <- para1(d$y[sel])
    d$e_inf[sel] <- d$e_inf[sel] * diff(l1) / diff(l2)
    d$e_sup[sel] <- d$e_sup[sel] * diff(l1) / diff(l2)
    y2 <- list(ax = ax2, para2 = para2, para1 = para1,
               titulo = cfg$eixo_y2$titulo %||% paste(ser_y2, collapse = ", "),
               cor = if (identical(cfg$eixo_y2$cor_eixo, "serie")) est[[ser_y2[1]]]$cor else cfg$eixo_y2$cor_eixo)
  }

  cam <- list()
  mapa <- !is.null(cfg$cores$mapear_coluna) && com_pontos
  # áreas
  if (preench != "nenhum" || tipo == "area_empilhada") {
    base_y <- 0
    if (preench == "ate_base") base_y <- ax_y$limites[if (isTRUE(cfg$eixo_y$inverter)) 2 else 1]
    for (i in seq_along(ycols)) {
      s <- ycols[i]; ds <- d[d$serie == s, ]; ds <- ds[order(ds$x), ]
      if (!nrow(ds)) next
      if (tipo == "area_empilhada") {
        rib <- data.frame(x = ds$x, ymin = ds$ymin, ymax = ds$y)
      } else if (preench == "proxima_serie") {
        if (i == length(ycols)) next
        prox <- d[d$serie == ycols[i + 1], ]
        yb <- stats::approx(prox$x, prox$y, xout = ds$x, rule = 2)$y
        rib <- data.frame(x = ds$x, ymin = pmin(ds$y, yb), ymax = pmax(ds$y, yb))
      } else rib <- data.frame(x = ds$x, ymin = base_y, ymax = ds$y)
      e <- est[[s]]
      a_area <- if (tipo == "area_empilhada") e$opf else L$opacidade_area
      fill <- if (identical(cfg$cores$preenchimento, "gradiente"))
        .gradiente(.alfa(e$cor, a_area), .alfa(e$cor2, a_area), cfg$cores$gradiente_direcao, FALSE)
        else .alfa(e$cor, a_area)
      cam[[length(cam) + 1]] <- geom_ribbon(data = rib, aes(x = x, ymin = ymin, ymax = ymax),
                                            fill = fill, colour = NA, inherit.aes = FALSE)
    }
  }
  # linhas de queda
  if (L$linhas_queda != "nenhuma") {
    bx <- if (isTRUE(cfg$eixo_x$inverter)) ax_x$limites[2] else ax_x$limites[1]
    by <- if (isTRUE(cfg$eixo_y$inverter)) ax_y$limites[2] else ax_y$limites[1]
    if (L$linhas_queda %in% c("vertical", "ambas"))
      cam[[length(cam) + 1]] <- geom_segment(data = d, aes(x = x, xend = x, y = y, yend = by, colour = serie),
        linetype = L$linhas_queda_tipo, linewidth = .lw(L$linhas_queda_espessura_pt), show.legend = FALSE)
    if (L$linhas_queda %in% c("horizontal", "ambas"))
      cam[[length(cam) + 1]] <- geom_segment(data = d, aes(x = x, xend = bx, y = y, yend = y, colour = serie),
        linetype = L$linhas_queda_tipo, linewidth = .lw(L$linhas_queda_espessura_pt), show.legend = FALSE)
  }
  # barras de erro
  de <- d[!is.na(d$e_inf) | !is.na(d$e_sup), ]
  if (nrow(de)) {
    larg <- if (ax_x$escala == "linear") L$erro_chapeu_percentual / 100 * diff(ax_x$limites) else 0
    de$ymin <- if (L$erro_lado == "superior") de$y else de$y - de$e_inf
    de$ymax <- if (L$erro_lado == "inferior") de$y else de$y + de$e_sup
    cam[[length(cam) + 1]] <- geom_errorbar(data = de, aes(x = x, ymin = ymin, ymax = ymax, colour = serie),
      width = larg, linewidth = .lw(L$erro_espessura_pt), show.legend = FALSE, inherit.aes = FALSE)
  }
  dx <- d[!is.na(d$e_x), ]
  if (nrow(dx)) {
    alt <- if (ax_y$escala == "linear") L$erro_chapeu_percentual / 100 * diff(ax_y$limites) else 0
    cam[[length(cam) + 1]] <- geom_errorbar(data = dx, aes(y = y, xmin = x - e_x, xmax = x + e_x, colour = serie),
      width = alt, orientation = "y", linewidth = .lw(L$erro_espessura_pt), show.legend = FALSE, inherit.aes = FALSE)
  }
  aes_leg <- character(0)
  # linhas
  if (com_linha) {
    if (mapa) {
      for (s in ycols) cam[[length(cam) + 1]] <- .camada_linha(d[d$serie == s, ], L$ligacao, mapeado = FALSE,
                                                               e = est[[s]])
    } else {
      cam[[length(cam) + 1]] <- .camada_linha(d, L$ligacao, mapeado = TRUE)
      aes_leg <- c(aes_leg, "colour", "linetype", "linewidth", "alpha")
    }
  }
  # pontos
  if (com_pontos) {
    if (mapa) {
      cam[[length(cam) + 1]] <- geom_point(data = d, aes(x = x, y = y, colour = mapa, fill = mapa,
                                                         shape = serie, size = serie, stroke = serie),
                                                  na.rm = TRUE)   # células vazias: sem aviso em inglês
      aes_leg <- unique(c(aes_leg, "shape", "size", "stroke"))
    } else {
      esf <- ycols[vapply(est[ycols], function(e) isTRUE(e$simbolo == .COD_ESFERA), NA)]   # séries "esfera"
      if (length(setdiff(ycols, esf)))
      cam[[length(cam) + 1]] <- geom_point(data = d[!d$serie %in% esf, ],
                                           aes(x = x, y = y, colour = serie, fill = serie,
                                                         shape = serie, size = serie, stroke = serie, alpha = serie),
        show.legend = TRUE, na.rm = TRUE, key_glyph = .draw_key_ponto_ou_nada)   # na.rm: células vazias sem aviso
      if (length(esf))
        cam[[length(cam) + 1]] <- geom_esfera(data = d[d$serie %in% esf, ], luz = cfg$serie_padrao$esfera_luz,
          mapping = aes(x = x, y = y, colour = serie, shape = serie, size = serie, stroke = serie), show.legend = TRUE)
      aes_leg <- unique(c(aes_leg, "colour", "shape", "size", "stroke",
                          if (length(setdiff(ycols, esf))) c("fill_simb",
                                                             "alpha")))   # só esferas: sem escalas de fill/alpha
    }
  }
  # rótulos de dados
  if (L$rotulos_dados != "nenhum") {
    dd <- d
    if (usa_y2) { sel <- dd$serie %in% ser_y2; dd$yv <- dd$y; dd$yv[sel] <- y2$para2(dd$y[sel]) } else dd$yv <- dd$y
    xv <- if (!is.null(cats)) cats[dd$x]
          else if (!is.null(tempo)) .formatador_tempo(cfg$eixo_x, tempo$classe, ax_x$limites, ax_x$maiores)(dd$x)
          else .fmt_num(dd$x, L$rotulos_casas)
    dd$rot <- switch(L$rotulos_dados,
                     y = .fmt_num(dd$yv, L$rotulos_casas), x = xv,
                     xy = paste0("(", xv, ", ", .fmt_num(dd$yv, L$rotulos_casas), ")"),
                     serie = as.character(dd$serie))
    k <- L$rotulos_deslocamento_pt / L$rotulos_tamanho_pt
    cam[[length(cam) + 1]] <- geom_text(data = dd, aes(x = x, y = y, label = rot, colour = serie),
      size = .tx(L$rotulos_tamanho_pt), vjust = if (k >= 0) -k else 1 - k, show.legend = FALSE,
      family = .fonte(cfg$texto$fonte))
  }
  usa_cor <- com_linha || nrow(de) || L$linhas_queda != "nenhuma" || L$rotulos_dados != "nenhum"
  if (!"colour" %in% aes_leg && !mapa && usa_cor) aes_leg <- c(aes_leg, "colour")
  escalas <- .escalas_legenda(est, aes_leg, cfg)
  if (mapa) escalas <- c(escalas, .escala_mapa(cfg, dados))
  if (!com_pontos && !com_linha) escalas <- c(escalas, list(guides(fill = "none")))

  titulo_y <- cfg$eixo_y$titulo %||% (if (length(setdiff(ycols, ser_y2)) == 1) setdiff(ycols, ser_y2) else "Y")
  list(camadas = c(cam, escalas),
       info = list(ax_x = ax_x, ax_y = ax_y, y2 = y2, flip = FALSE,
                   titulo_x = cfg$eixo_x$titulo %||% xcol, titulo_y = titulo_y,
                   legenda_auto = TRUE, faixa_x = faixa_x, faixa_y = faixa_y))
}

# Camada de linha (reta, spline ou degrau) de uma série ou de todas, com estilo mapeado ou fixo.
.camada_linha <- function(d, ligacao, mapeado, e = NULL) {
  d <- d[!is.na(d$y), ]
  if (ligacao == "spline") {
    niveis <- levels(d$serie)
    partes <- lapply(split(d, d$serie, drop = TRUE), function(s) {
      nm <- as.character(s$serie[1])
      s <- stats::aggregate(y ~ x, data = s, FUN = mean)
      if (nrow(s) < 3) return(data.frame(x = s$x, y = s$y, serie = nm))
      sp <- stats::spline(s$x, s$y, n = max(200, 10 * nrow(s)), method = "fmm")
      data.frame(x = sp$x, y = sp$y, serie = nm)
    })
    d <- do.call(rbind, partes)
    d$serie <- factor(d$serie, levels = niveis)
  }
  geo <- switch(ligacao, reta = geom_path, spline = geom_path,
                degrau_hv = function(...) geom_step(..., direction = "hv"),
                degrau_vh = function(...) geom_step(..., direction = "vh"),
                degrau_meio = function(...) geom_step(..., direction = "mid"))
  if (mapeado) {
    geo(data = d, aes(x = x, y = y, colour = serie, linetype = serie, linewidth = serie,
                      alpha = serie, group = serie), lineend = "round", linejoin = "round",
        show.legend = TRUE)   # TRUE: a legenda mostra a série mesmo sem dados nesta camada (quebra de eixo)
  } else {
    geo(data = d, aes(x = x, y = y), colour = .alfa(e$cor, e$op), linetype = e$lt,
        linewidth = .lw(e$lw), lineend = "round", linejoin = "round")
  }
}

# Escala e barra de cores para o mapa de cor por coluna numérica (2 ou 3 cores).
.escala_mapa <- function(cfg, dados) {
  c0 <- cfg$cores
  tit <- c0$mapa_titulo %||% c0$mapear_coluna
  guia <- guide_colourbar(title = if (identical(tit, "")) NULL else .texto(tit))
  cores <- vapply(c0$mapa_cores, .cor, "", onde = "cores$mapa_cores")
  if (length(cores) >= 3) {
    mc <- dados[[c0$mapear_coluna]]
    meio <- c0$mapa_ponto_medio %||% mean(range(mc, na.rm = TRUE))
    sc <- scale_colour_gradient2(low = cores[1], mid = cores[2], high = cores[3], midpoint = meio,
                                 limits = c0$mapa_limites, aesthetics = c("colour", "fill"),
                                 guide = guia, labels = .formatador(list()))
  } else {
    sc <- scale_colour_gradient(low = cores[1], high = cores[2], limits = c0$mapa_limites,
                                aesthetics = c("colour", "fill"), guide = guia,
                                labels = .formatador(list()))
  }
  list(sc)
}

# -----------------------------------------------------------------------------
#  10_tipo_barras.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/10_tipo_barras.R — barras
# =============================================================================

# ---- Barras ---------------------------------------------------------------------
# Barras agrupadas, empilhadas ou 100 %. Entra: dados e cfg. Sai: list(camadas, info).
.construir_barras <- function(dados, cfg) {
  B <- cfg$barras
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  flip <- B$orientacao == "horizontal"
  est <- .estilos(cfg, ycols, inverter_grad = flip)
  numerico <- is.numeric(dados[[xcol]])
  dados <- dados[!is.na(dados[[xcol]]), , drop = FALSE]
  if (numerico) {
    xs <- dados[[xcol]]; cats <- NULL
    passo <- if (length(unique(xs)) > 1) min(diff(sort(unique(xs)))) else 1
  } else {
    cats <- unique(as.character(dados[[xcol]]))
    ordem <- cfg$grafico$ordem_itens
    if (!is.null(ordem) && !any(ordem %in% ycols)) {   # (se citar colunas, a ordem é das séries)
      if (all(ordem %in% cats)) cats <- c(ordem, setdiff(cats, ordem))
      else .aviso("cfg$grafico$ordem_itens: não existe(m) a(s) categoria(s) ",
                  paste0("'", setdiff(ordem, cats), "'", collapse = ", "), ". A ordem foi ignorada. Categorias: ",
                  paste0("'", cats, "'", collapse = ", "))
    }
    xs <- match(as.character(dados[[xcol]]), cats); passo <- 1
  }
  n <- length(ycols); W <- B$largura * passo
  base <- B$linha_base %||% 0
  erro_de <- function(yc) {
    e <- est[[yc]]
    col <- function(ref) if (is.null(ref)) rep(0, nrow(dados)) else {
      v <- dados[[.coluna(dados, ref, paste0("cfg$series[[\"", yc, "\"]] coluna de erro"))]]; v[is.na(v)] <- 0; v }
    tem <- !is.null(e$erro) || !is.null(e$erro_inf) || !is.null(e$erro_sup)
    list(tem = tem, inf = col(e$erro_inf %||% e$erro), sup = col(e$erro_sup %||% e$erro))
  }
  ret <- list()
  if (B$arranjo == "agrupado") {
    sob <- B$sobreposicao %||% 0
    w <- W / (1 + (n - 1) * (1 - sob))
    for (i in seq_len(n)) {
      v <- dados[[ycols[i]]]
      x0 <- xs - W / 2 + (i - 1) * w * (1 - sob)
      er <- erro_de(ycols[i])
      ret[[i]] <- data.frame(xmin = x0, xmax = x0 + w, ymin = base, ymax = v, serie = ycols[i],
                             xc = x0 + w / 2, topo = v, valor = v, tem_erro = er$tem,
                             e_inf = er$inf, e_sup = er$sup, row.names = NULL)
    }
  } else {
    m <- sapply(ycols, function(y) { v <- dados[[y]]; v[is.na(v)] <- 0; v })
    if (is.null(dim(m))) m <- matrix(m, nrow = 1, dimnames = list(NULL, ycols))
    if (B$arranjo == "empilhado_100") {
      tot <- rowSums(abs(m)); tot[tot == 0] <- 1
      m <- m / tot * 100
      base <- 0
    }
    pos <- rep(base, nrow(m)); neg <- rep(base, nrow(m))
    for (i in seq_len(n)) {
      v <- m[, i]
      y0 <- ifelse(v >= 0, pos, neg); y1 <- y0 + v
      pos <- ifelse(v >= 0, y1, pos); neg <- ifelse(v < 0, y1, neg)
      er <- erro_de(ycols[i])
      ret[[i]] <- data.frame(xmin = xs - W / 2, xmax = xs + W / 2, ymin = y0, ymax = y1,
                             serie = ycols[i], xc = xs, topo = y1, valor = v, tem_erro = er$tem,
                             e_inf = er$inf, e_sup = er$sup, row.names = NULL)
    }
  }
  r <- do.call(rbind, ret); r <- r[!is.na(r$ymax), ]
  r$serie <- factor(r$serie, levels = ycols)

  contorno_serie <- identical(B$contorno_cor, "serie")
  cam <- list(if (contorno_serie)
    geom_rect(data = r, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = serie, colour = serie),
              linewidth = .lw(B$contorno_espessura_pt), linetype = B$contorno_tipo)
  else
    geom_rect(data = r, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = serie),
              colour = if (is.na(B$contorno_cor)) NA else .cor(B$contorno_cor),
              linewidth = .lw(B$contorno_espessura_pt), linetype = B$contorno_tipo))
  # erros (linha a linha, já alinhados com cada barra)
  faixa_err <- numeric(0)
  erros <- r[r$tem_erro & B$arranjo != "empilhado_100", ]
  if (nrow(erros)) {
    erros$ymin <- erros$topo - erros$e_inf; erros$ymax <- erros$topo + erros$e_sup
    cam[[length(cam) + 1]] <- geom_errorbar(data = erros, aes(x = xc, ymin = ymin, ymax = ymax),
      width = (erros$xmax[1] - erros$xmin[1]) * B$erro_chapeu, linewidth = .lw(B$erro_espessura_pt),
      colour = cfg$texto$cor, inherit.aes = FALSE)
    faixa_err <- c(erros$ymin, erros$ymax)
  }
  # rótulos
  if (isTRUE(B$rotulos_valor)) {
    rr <- r
    rr$rot <- if (B$arranjo == "empilhado_100") paste0(.fmt_num(rr$valor, B$rotulos_casas),
                                                       "%") else .fmt_num(rr$valor, B$rotulos_casas)
    pos <- B$rotulos_posicao
    rr$yl <- if (pos == "centro") (rr$ymin + rr$ymax) / 2 else rr$ymax
    neg <- rr$ymax < rr$ymin
    j <- switch(pos, fora = ifelse(neg, 1.3, -0.3), dentro = ifelse(neg, -0.3, 1.3), centro = 0.5)
    cam[[length(cam) + 1]] <- if (flip)
      geom_text(data = rr, aes(x = xc, y = yl, label = rot), hjust = j, size = .tx(B$rotulos_tamanho_pt),
                colour = .cor(B$rotulos_cor), family = .fonte(cfg$texto$fonte))
    else geom_text(data = rr, aes(x = xc, y = yl, label = rot), vjust = j, size = .tx(B$rotulos_tamanho_pt),
                   colour = .cor(B$rotulos_cor), family = .fonte(cfg$texto$fonte))
  }
  aes_leg <- c("fill", if (contorno_serie) "colour")
  faixa_y <- c(r$ymin, r$ymax, base, faixa_err)
  if (isTRUE(B$rotulos_valor) && B$rotulos_posicao == "fora")
    faixa_y <- c(faixa_y, max(faixa_y) + 0.08 * diff(range(faixa_y)))
  ax_x <- .calc_eixo(cfg$eixo_x, c(r$xmin, r$xmax), categorias = cats, forcar = cfg$.interno$forcar_x)
  if (numerico && is.null(cfg$eixo_x$inicio) && is.null(cfg$.interno$forcar_x)) {
    folga_x <- (1 - B$largura) * passo / 2
    ax_x <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(inicio = min(r$xmin) - folga_x, fim = max(r$xmax) + folga_x)),
                       c(r$xmin, r$xmax))
  }
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  tit_y <- cfg$eixo_y$titulo %||%
    (if (B$arranjo == "empilhado_100") "Percentual (%)" else if (n == 1) ycols else "Valor")
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = flip, titulo_x = cfg$eixo_x$titulo %||% xcol,
                   titulo_y = tit_y, legenda_auto = TRUE, faixa_x = c(r$xmin, r$xmax), faixa_y = faixa_y))
}

# -----------------------------------------------------------------------------
#  11_tipo_pizza.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/11_tipo_pizza.R — pizza e rosca
# =============================================================================

# ---- Pizza ----------------------------------------------------------------------
# Afasta verticalmente os rótulos de um mesmo lado que se sobreporiam; os que não colidem não
# se movem. Entra: tabela de rótulos (x, y, rot, hj, gx0, gy0, gx1, gy1), cfg e o limite
# aproximado do gráfico (para converter a altura do texto em unidades do raio).
# Sai: a mesma tabela com y, hj e fim da linha guia ajustados.
.afastar_rotulos_pizza <- function(rd, cfg, lim) {
  P <- cfg$pizza; ex <- cfg$exportacao; m <- cfg$caixa$margens_cm
  cm_por_unidade <- switch(ex$unidade, cm = 1, mm = 0.1, `in` = 2.54)
  lado_cm <- max(min(ex$largura * cm_por_unidade - m[2] - m[4], ex$altura * cm_por_unidade - m[1] - m[3]), 1)
  linhas <- lengths(strsplit(rd$rot, "\n", fixed = TRUE))
  alt <- linhas * P$rotulos_tamanho_pt * 1.2 / 72 * 2.54 * (2 * lim / lado_cm)  # altura de cada rótulo
  y0 <- rd$y; y <- y0
  for (lado in list(rd$x >= 0, rd$x < 0)) {
    idx <- which(lado)
    if (length(idx) < 2) next
    idx <- idx[order(y[idx], decreasing = TRUE)]
    for (volta in 1:200) {
      mexeu <- FALSE
      for (k in seq_len(length(idx) - 1)) {
        a <- idx[k]; b <- idx[k + 1]
        falta <- (alt[a] + alt[b]) / 2 - (y[a] - y[b])
        if (falta > 1e-9) { y[a] <- y[a] + falta / 2; y[b] <- y[b] - falta / 2; mexeu <- TRUE }
      }
      if (!mexeu) break
    }
  }
  mov <- abs(y - y0) > 1e-9
  if (!any(mov)) return(rd)
  rd$y <- y
  rd$hj[mov & rd$hj == 0.5] <- ifelse(rd$x[mov & rd$hj == 0.5] >= 0, 0, 1)   # texto para fora, longe do centro
  dx <- rd$x[mov] - rd$gx0[mov]; dy <- rd$y[mov] - rd$gy0[mov]
  n <- sqrt(dx^2 + dy^2)
  rd$gx1[mov] <- rd$x[mov] - P$linha_guia_recuo * dx / n
  rd$gy1[mov] <- rd$y[mov] - P$linha_guia_recuo * dy / n
  rd
}

# Pizza e rosca. Entra: dados e cfg. Sai: list(camadas, info) (info$pizza = TRUE).
.construir_pizza <- function(dados, cfg) {
  P <- cfg$pizza
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycol <- .colunas_y(dados, cfg, excluir = xcol)[1]
  cat_ <- as.character(dados[[xcol]]); val <- dados[[ycol]]
  ok <- !is.na(cat_) & !is.na(val)
  if (any(val[ok] < 0)) .aviso("Pizza: valores negativos em '", ycol, "' foram ignorados.")
  ok <- ok & val > 0
  cat_ <- cat_[ok]; val <- val[ok]
  if (anyDuplicated(cat_)) { ag <- tapply(val, factor(cat_, levels = unique(cat_)),
                                          sum); cat_ <- names(ag); val <- as.numeric(ag) }
  if (!is.null(cfg$grafico$ordem_itens)) {
    o <- c(intersect(cfg$grafico$ordem_itens, cat_), setdiff(cat_, cfg$grafico$ordem_itens))
    val <- val[match(o, cat_)]; cat_ <- o
  }
  pct <- val / sum(val) * 100
  if ((P$agrupar_abaixo %||% 0) > 0 && any(pct < P$agrupar_abaixo)) {
    peq <- pct < P$agrupar_abaixo
    cat_ <- c(cat_[!peq], P$nome_agrupado); val <- c(val[!peq], sum(val[peq]))
    pct <- val / sum(val) * 100
  }
  inexistentes <- setdiff(P$explodir, cat_)
  if (length(inexistentes))
    .aviso("cfg$pizza$explodir: não existe(m) a(s) categoria(s) ", paste0("'", inexistentes, "'", collapse = ", "),
           ". Categorias: ", paste0("'", cat_, "'", collapse = ", "))
  est <- .estilos(cfg, cat_, grupo_gradiente = TRUE)
  dir <- if (P$sentido == "horario") 1 else -1
  fr <- cumsum(c(0, val)) / sum(val)
  a0 <- P$angulo_inicial + dir * fr[-length(fr)] * P$angulo_total
  a1 <- P$angulo_inicial + dir * fr[-1] * P$angulo_total
  r0 <- P$raio_furo
  polys <- list(); rot <- list()
  for (i in seq_along(cat_)) {
    am <- (a0[i] + a1[i]) / 2 * pi / 180
    desl <- if (cat_[i] %in% P$explodir) P$deslocamento_explosao / 100 else 0
    cx <- desl * sin(am); cy <- desl * cos(am)
    ang <- seq(a0[i], a1[i], length.out = max(3, ceiling(abs(a1[i] - a0[i])) + 1)) * pi / 180
    px <- c(sin(ang), if (r0 > 0) r0 * sin(rev(ang)) else 0)
    py <- c(cos(ang), if (r0 > 0) r0 * cos(rev(ang)) else 0)
    polys[[i]] <- data.frame(x = px + cx, y = py + cy, serie = cat_[i])
    partes <- c(categoria = cat_[i], valor = .fmt_num(val[i], P$rotulos_casas),
                percentual = paste0(.fmt_num(pct[i], P$rotulos_casas), "%"))
    texto <- paste(partes[intersect(P$rotulos, names(partes))], collapse = P$rotulos_separador)
    rr <- switch(P$rotulos_posicao, dentro = if (r0 > 0) (1 + r0) / 2 else P$rotulos_raio_dentro,
                 borda = P$rotulos_raio_borda, fora = P$rotulos_distancia)
    lado <- sin(am)
    hj <- if (P$rotulos_posicao == "dentro") 0.5 else if (abs(lado) < 0.15) 0.5 else if (lado > 0) 0 else 1
    corr <- if (identical(P$rotulos_cor, "auto")) {
      if (P$rotulos_posicao == "dentro") (if (.luminancia(est[[i]]$cor) < 0.5) "white" else "black") else cfg$texto$cor
    } else .cor(P$rotulos_cor)
    if (nzchar(texto) && pct[i] >= (P$ocultar_rotulo_abaixo %||% 0))
      rot[[length(rot) + 1]] <- data.frame(x = cx + rr * sin(am), y = cy + rr * cos(am), rot = texto,
        hj = hj, cor = corr, gx0 = cx + 1.0 * sin(am), gy0 = cy + 1.0 * cos(am),
        gx1 = cx + (rr - P$linha_guia_recuo) * sin(am), gy1 = cy + (rr - P$linha_guia_recuo) * cos(am))
  }
  pl <- do.call(rbind, polys); pl$serie <- factor(pl$serie, levels = cat_)
  cam <- list(geom_polygon(data = pl, aes(x = x, y = y, group = serie, fill = serie),
                           colour = if (is.na(P$contorno_cor)) NA else .cor(P$contorno_cor),
                           linewidth = .lw(P$contorno_espessura_pt)))
  lim <- 1 + max(c(0, P$deslocamento_explosao / 100 * (length(P$explodir) > 0)))
  if (length(rot)) {
    rd <- do.call(rbind, rot)
    if (P$rotulos_posicao != "dentro" && isTRUE(P$rotulos_afastar) && nrow(rd) > 1)
      rd <- .afastar_rotulos_pizza(rd, cfg, max(lim, max(abs(c(rd$x, rd$y))) + P$rotulos_margem))
    if (P$rotulos_posicao == "fora" && isTRUE(P$linha_guia))
      cam[[length(cam) + 1]] <- geom_segment(data = rd, aes(x = gx0, y = gy0, xend = gx1, yend = gy1),
                                             colour = cfg$texto$cor, linewidth = .lw(P$linha_guia_espessura_pt))
    cam[[length(cam) + 1]] <- geom_text(data = rd, aes(x = x, y = y, label = rot), hjust = rd$hj,
      colour = rd$cor, size = .tx(P$rotulos_tamanho_pt), lineheight = 0.95, family = .fonte(cfg$texto$fonte))
    if (P$rotulos_posicao != "dentro") lim <- max(lim, max(abs(c(rd$x, rd$y))) + P$rotulos_margem)
  }
  leg <- !("categoria" %in% P$rotulos)
  list(camadas = c(cam, .escalas_legenda(est, "fill", cfg)),
       info = list(pizza = TRUE, lim = lim, legenda_auto = leg))
}

# -----------------------------------------------------------------------------
#  12_tipo_distribuicao.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/12_tipo_distribuicao.R — histograma, densidade e ECDF
# =============================================================================

# ---- Distribuições ----------------------------------------------------------------
# Entra: dados e cfg. Sai: lista de amostras (uma por série ou grupo) para distribuições e boxplot.
.amostras <- function(dados, cfg) {
  gcol <- cfg$grafico$coluna_grupo
  if (!is.null(gcol)) {
    gcol <- .coluna(dados, gcol, "cfg$grafico$coluna_grupo")
    vcol <- .colunas_y(dados, cfg, excluir = gcol)[1]
    g <- as.character(dados[[gcol]])
    itens <- unique(g[!is.na(g)])
    if (!is.null(cfg$grafico$ordem_itens)) itens <- c(intersect(cfg$grafico$ordem_itens, itens),
                                                      setdiff(itens, cfg$grafico$ordem_itens))
    am <- lapply(itens, function(i) { v <- dados[[vcol]][g %in% i]; v[!is.na(v)] })
    return(list(am = stats::setNames(am, itens), nome_valor = vcol, nome_grupo = gcol))
  }
  ycols <- .colunas_y(dados, cfg, excluir = NULL)
  am <- lapply(ycols, function(y) { v <- dados[[y]]; v[!is.na(v)] })
  list(am = stats::setNames(am, ycols), nome_valor = if (length(ycols) == 1) ycols else "Valor", nome_grupo = NULL)
}

# Histograma, densidade e ECDF. Entra: dados e cfg. Sai: list(camadas, info).
.construir_distribuicao <- function(dados, cfg) {
  D <- cfg$distribuicao; tipo <- cfg$grafico$tipo
  A <- .amostras(dados, cfg); am <- A$am; itens <- names(am)
  vazio <- vapply(am, length, 0) < 2
  if (any(vazio)) .erro("Distribuição: a(s) série(s) ", paste(itens[vazio], collapse = ", "),
                        " tem(têm) menos de 2 valores.")
  est <- .estilos(cfg, itens)
  multi <- length(itens) > 1
  todos <- unlist(am)
  cam <- list(); faixa_y <- 0; aes_leg <- character(0); tit_y <- NULL
  escalar <- function(dens, n, w) switch(D$medida, contagem = dens * n * w, frequencia = dens * w,
                                         percentual = dens * w * 100, densidade = dens)
  if (tipo == "histograma") {
    if (!is.null(D$largura_classe)) {
      w <- D$largura_classe
      ini <- D$inicio_classe %||% (floor(min(todos) / w) * w)
      quebras <- seq(ini, max(todos) + w, by = w)
      quebras <- quebras[seq_len(max(2, which(quebras > max(todos))[1]))]
    } else if (!is.null(D$n_classes)) {
      ini <- D$inicio_classe %||% min(todos)
      quebras <- seq(ini, max(todos), length.out = D$n_classes + 1)
    } else {
      quebras <- graphics::hist(todos, plot = FALSE)$breaks
      if (!is.null(D$inicio_classe)) { w <- diff(quebras)[1]; quebras <- seq(D$inicio_classe, max(todos) + w, by = w) }
    }
    if (min(todos) < min(quebras)) .erro("distribuicao$inicio_classe (", min(quebras), ") é maior que o menor dado (",
                                         min(todos), ").")
    ret <- do.call(rbind, lapply(itens, function(i) {
      h <- graphics::hist(am[[i]], breaks = quebras, plot = FALSE, right = FALSE, include.lowest = TRUE)
      n <- length(am[[i]]); w <- diff(quebras)
      y <- switch(D$medida, contagem = h$counts, frequencia = h$counts / n,
                  percentual = h$counts / n * 100, densidade = h$counts / (n * w))
      data.frame(xmin = quebras[-length(quebras)], xmax = quebras[-1], ymin = 0, ymax = y, serie = i)
    }))
    ret$serie <- factor(ret$serie, levels = itens)
    if (multi && all(vapply(est, function(e) e$opf >= 1, TRUE))) {
      cfg2 <- cfg; cfg2$serie_padrao$opacidade_preenchimento <- D$opacidade_multiplas %||% 0.55
      est <- .estilos(cfg2, itens)
    }
    cam[[1]] <- geom_rect(data = ret, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = serie),
                          colour = if (is.na(D$contorno_cor)) NA else .cor(D$contorno_cor),
                          linewidth = .lw(D$contorno_espessura_pt))
    aes_leg <- "fill"; faixa_y <- c(0, ret$ymax); faixa_x <- range(quebras)
    tit_y <- switch(D$medida, contagem = "Contagem", frequencia = "Frequência relativa",
                    percentual = "Frequência (%)", densidade = "Densidade")
    curvas <- list()
    for (i in itens) {
      x <- am[[i]]; n <- length(x); w <- diff(quebras)[1]
      grade <- seq(min(quebras), max(quebras), length.out = 300)
      if (isTRUE(D$curva_densidade)) {
        dd <- stats::density(x, adjust = D$ajuste_banda, from = min(grade), to = max(grade), n = 300)
        curvas[[length(curvas) + 1]] <- data.frame(x = dd$x, y = escalar(dd$y, n, w), serie = i, tipo = "dens")
      }
      if (isTRUE(D$curva_normal)) {
        curvas[[length(curvas) + 1]] <- data.frame(x = grade,
                                                   y = escalar(stats::dnorm(grade, mean(x), stats::sd(x)), n, w),
                                                   serie = i, tipo = "normal")
      }
    }
    if (length(curvas)) {
      cv <- do.call(rbind, curvas); cv$serie <- factor(cv$serie, levels = itens)
      cam[[length(cam) + 1]] <- geom_line(
        data = cv, aes(x = x, y = y, colour = serie, group = interaction(serie, tipo), linetype = tipo),
        linewidth = .lw(D$espessura_curva_pt), show.legend = FALSE)
      cam[[length(cam) + 1]] <- scale_linetype_manual(values = c(dens = "solid", normal = "dashed"), guide = "none")
      aes_leg <- c(aes_leg, "colour"); faixa_y <- c(faixa_y, cv$y)
    }
  } else if (tipo == "densidade") {
    dd <- do.call(rbind, lapply(itens, function(i) {
      d <- stats::density(am[[i]], adjust = D$ajuste_banda)
      data.frame(x = d$x, y = d$y, serie = i)
    }))
    dd$serie <- factor(dd$serie, levels = itens)
    if (isTRUE(D$preencher_densidade)) {
      for (i in itens) {
        e <- est[[i]]; s <- dd[dd$serie == i, ]
        fill <- if (identical(cfg$cores$preenchimento, "gradiente"))
          .gradiente(.alfa(e$cor, D$opacidade_area), .alfa(e$cor2, D$opacidade_area), cfg$cores$gradiente_direcao)
          else .alfa(e$cor, D$opacidade_area)
        cam[[length(cam) + 1]] <- geom_ribbon(data = s, aes(x = x, ymin = 0, ymax = y), fill = fill, colour = NA)
      }
    }
    cam[[length(cam) + 1]] <- geom_line(data = dd, aes(x = x, y = y, colour = serie, linetype = serie,
                                                       linewidth = serie, alpha = serie))
    aes_leg <- c("colour", "linetype", "linewidth", "alpha")
    faixa_y <- c(0, dd$y); faixa_x <- range(dd$x); tit_y <- "Densidade"
  } else {
    ec <- do.call(rbind, lapply(itens, function(i) {
      x <- sort(am[[i]]); n <- length(x)
      data.frame(x = c(x[1], x), y = c(0, seq_len(n) / n), serie = i)
    }))
    ec$serie <- factor(ec$serie, levels = itens)
    cam[[1]] <- geom_step(data = ec, aes(x = x, y = y, colour = serie, linetype = serie, linewidth = serie,
                                         alpha = serie),
                          direction = "hv")
    aes_leg <- c("colour", "linetype", "linewidth", "alpha")
    faixa_y <- c(0, 1); faixa_x <- range(ec$x); tit_y <- "Probabilidade acumulada"
  }
  if (isTRUE(D$marcas_rug)) {
    escura <- vapply(itens, function(i) grDevices::colorRampPalette(c(est[[i]]$cor, "black"))(3)[2], "")
    rg <- data.frame(x = todos, cor = rep(escura, vapply(am, length, 0)))
    cam[[length(cam) + 1]] <- geom_rug(data = rg, aes(x = x), colour = rg$cor, sides = "b",
                                       length = unit(D$rug_comprimento_pt, "pt"), linewidth = .lw(D$rug_espessura_pt),
                                       inherit.aes = FALSE)
  }
  ax_x <- .calc_eixo(cfg$eixo_x, faixa_x, forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = FALSE,
                   titulo_x = cfg$eixo_x$titulo %||% A$nome_valor, titulo_y = cfg$eixo_y$titulo %||% tit_y,
                   legenda_auto = TRUE, faixa_x = faixa_x, faixa_y = faixa_y))
}

# -----------------------------------------------------------------------------
#  13_tipo_boxplot.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/13_tipo_boxplot.R — boxplot, violino e média ± erro
# =============================================================================

# ---- Boxplot e variações ------------------------------------------------------------
# Posições X dos pontos em "enxame" (sem sobreposição). Entra: valores y, centro e largura da
# faixa, faixa de dados e a altura relativa de cada faixa (cfg$boxplot$enxame_resolucao).
.enxame <- function(y, centro, largura, faixa_y, tam_rel = 0.025) {
  n <- length(y); if (!n) return(numeric(0))
  h <- max(diff(faixa_y) * tam_rel, 1e-12)
  bin <- floor((y - min(y)) / h)
  off <- numeric(n)
  for (b in unique(bin)) {
    idx <- which(bin == b); k <- length(idx)
    passo <- min(largura / max(k, 1), largura / 6)
    pos <- c(0, as.vector(rbind(seq_len(k), -seq_len(k))))[seq_len(k)]
    off[idx[order(y[idx])]] <- pos * passo
  }
  off <- pmax(pmin(off, largura / 2), -largura / 2)
  centro + off
}

# Boxplot, violino e média ± erro. Entra: dados e cfg. Sai: list(camadas, info).
.construir_boxplot <- function(dados, cfg) {
  X <- cfg$boxplot; var <- X$variacao
  A <- .amostras(dados, cfg); am <- A$am; itens <- names(am)
  if (any(vapply(am, length, 0) == 0)) .erro("Boxplot: série(s) sem dados: ",
                                             paste(itens[vapply(am, length, 0) == 0], collapse = ", "))
  flip <- identical(X$orientacao, "horizontal")
  est <- .estilos(cfg, itens, inverter_grad = flip)
  k <- length(itens); w <- X$largura
  contorno <- function(i) if (identical(X$contorno_cor, "serie")) est[[i]]$cor else .cor(X$contorno_cor)
  polys <- list(); segs <- list(); pts_media <- list(); pts_out <- list(); pts_dados <- list(); txt_n <- list()
  faixa <- range(unlist(am))
  restaurar_rng <- .guardar_rng(); on.exit(restaurar_rng(), add = TRUE)
  set.seed(X$semente %||% 123)
  erro_media <- function(x, tipo) {
    n <- length(x); s <- stats::sd(x); if (is.na(s)) s <- 0
    switch(tipo, desvio_padrao = s, erro_padrao = s / sqrt(n),
           ic95 = if (n > 1) stats::qt(0.975, n - 1) * s / sqrt(n) else 0)
  }
  for (j in seq_len(k)) {
    it <- itens[j]; x <- am[[it]]; p <- j; cc <- contorno(it)
    q <- stats::quantile(x, c(X$caixa_percentis[1], 50, X$caixa_percentis[2]) / 100, names = FALSE, type = 7)
    md <- mean(x)
    wl <- switch(X$bigode,
      tukey = { iqr <- q[3] - q[1]; c(min(x[x >= q[1] - X$bigode_coef * iqr]),
                                      max(x[x <= q[3] + X$bigode_coef * iqr])) },
      percentis = stats::quantile(x, X$bigode_percentis / 100, names = FALSE, type = 7),
      min_max = range(x),
      desvio_padrao = , erro_padrao = , ic95 = md + c(-1, 1) * erro_media(x, X$bigode))
    out <- if (X$bigode %in% c("tukey", "percentis")) x[x < wl[1] | x > wl[2]] else numeric(0)
    if (var == "media_erro") {
      er <- erro_media(x, X$media_erro_tipo)
      if (X$media_erro_estilo == "barra")
        polys[[length(polys) + 1]] <- data.frame(x = p + c(-w, w, w, -w) / 2, y = c(0, 0, md, md), item = it)
      segs[[length(segs) + 1]] <- data.frame(x = p, xend = p, y = md - er, yend = md + er, cor = cc,
                                             lw = X$contorno_espessura_pt)
      segs[[length(segs) + 1]] <- data.frame(x = p - w * X$bigode_chapeu / 2, xend = p + w * X$bigode_chapeu / 2,
                                             y = c(md - er,
                                                   md + er), yend = c(md - er,
                                                                      md + er), cor = cc, lw = X$contorno_espessura_pt)
      if (X$media_erro_estilo == "ponto")
        pts_media[[length(pts_media) + 1]] <- data.frame(x = p, y = md, fill = est[[it]]$cor,
                                                         tam = X$media_tamanho_pt * X$media_erro_ponto_fator, item = it)
      faixa <- range(c(faixa, 0, md + er, md - er))
      if (isTRUE(X$mostrar_n))
        txt_n[[length(txt_n) + 1]] <- data.frame(x = p, y = md + er, rot = paste0("n = ", length(x)))
      next
    }
    # caixa (ou violino)
    xb0 <- p - w / 2; xb1 <- p + w / 2
    if (var == "meio_box") { xb0 <- p; xb1 <- p + w / 2 }
    if (var == "violino_box") { xb0 <- p - w * 0.12; xb1 <- p + w * 0.12 }
    if (var %in% c("violino", "violino_box")) {
      if (length(x) < 2) {
        .aviso("Violino: o grupo '", it, "' tem ", length(x), " valor; são precisos pelo menos 2 para ",
               "estimar a densidade. O violino desse grupo não foi desenhado.")
      } else {
        dd <- stats::density(x, adjust = X$violino_ajuste_banda, cut = if (isTRUE(X$violino_cortar)) 0 else 3)
        lv <- dd$y / max(dd$y) * X$violino_largura / 2
        polys[[length(polys) + 1]] <- data.frame(x = c(p - lv, rev(p + lv)), y = c(dd$x, rev(dd$x)), item = it)
        faixa <- range(c(faixa, dd$x))
      }
    }
    if (var != "violino") {
      if (isTRUE(X$entalhe)) {
        nt <- 1.58 * (q[3] - q[1]) / sqrt(length(x)); ind <- (xb1 - xb0) * 0.25
        bx <- data.frame(x = c(xb0, xb0, xb0 + ind, xb0, xb0, xb1, xb1, xb1 - ind, xb1, xb1),
                         y = c(q[1], q[2] - nt, q[2], q[2] + nt, q[3], q[3], q[2] + nt, q[2], q[2] - nt, q[1]))
        mx <- c(xb0 + ind, xb1 - ind)
      } else {
        bx <- data.frame(x = c(xb0, xb1, xb1, xb0), y = c(q[1], q[1], q[3], q[3])); mx <- c(xb0, xb1)
      }
      bx$item <- if (var == "violino_box") paste0(".branco.", it) else it
      polys[[length(polys) + 1]] <- bx
      xm <- (xb0 + xb1) / 2; cap <- (xb1 - xb0) * X$bigode_chapeu / 2
      if (X$bigode_lado %in% c("ambos", "inferior"))
        segs[[length(segs) + 1]] <- data.frame(x = c(xm, xm - cap), xend = c(xm, xm + cap), y = c(q[1], wl[1]),
                                               yend = c(wl[1], wl[1]), cor = cc, lw = X$contorno_espessura_pt)
      if (X$bigode_lado %in% c("ambos", "superior"))
        segs[[length(segs) + 1]] <- data.frame(x = c(xm, xm - cap), xend = c(xm, xm + cap), y = c(q[3], wl[2]),
                                               yend = c(wl[2], wl[2]), cor = cc, lw = X$contorno_espessura_pt)
      if (isTRUE(X$mediana))
        segs[[length(segs) + 1]] <- data.frame(x = mx[1], xend = mx[2], y = q[2], yend = q[2], cor = cc,
                                               lw = X$mediana_espessura_pt)
      if (isTRUE(X$outliers) && length(out))
        pts_out[[length(pts_out) + 1]] <- data.frame(x = xm, y = out, cor = cc)
      faixa <- range(c(faixa, wl))
    }
    if (isTRUE(X$media))
      pts_media[[length(pts_media) + 1]] <- data.frame(
        x = if (var == "meio_box") (xb0 + xb1) / 2 else p, y = md,
        fill = .cor(X$media_preenchimento), tam = X$media_tamanho_pt, item = it)
    if (var %in% c("box_pontos", "meio_box")) {
      centro <- if (var == "meio_box") p - w / 4 else p
      larg <- if (var == "meio_box") min(X$pontos_largura, w / 2 * 0.9) else X$pontos_largura
      xs <- switch(X$pontos_disposicao, coluna = rep(centro, length(x)),
                   jitter = centro + stats::runif(length(x), -larg / 2, larg / 2),
                   enxame = .enxame(x, centro, larg, range(unlist(am)), X$enxame_resolucao))
      pts_dados[[length(pts_dados) + 1]] <- data.frame(x = xs, y = x, fill = .alfa(est[[it]]$cor, X$pontos_opacidade))
    }
    if (isTRUE(X$mostrar_n)) txt_n[[length(txt_n) + 1]] <- data.frame(x = p, y = max(wl[2], q[3], max(x)),
                                                                      rot = paste0("n = ", length(x)))
  }
  cam <- list()
  if (length(polys)) {
    pl <- do.call(rbind, polys)
    brancos <- grepl("^\\.branco\\.", pl$item)
    if (any(!brancos)) {
      pp <- pl[!brancos, ]; pp$item <- factor(pp$item, levels = itens)
      cam[[length(cam) + 1]] <- geom_polygon(data = pp, aes(x = x, y = y, group = item, fill = item),
        colour = if (identical(X$contorno_cor, "serie")) NA else .cor(X$contorno_cor),
        linewidth = .lw(X$contorno_espessura_pt))
      if (identical(X$contorno_cor, "serie"))
        for (it in levels(droplevels(pp$item)))
          cam[[length(cam) + 1]] <- geom_polygon(data = pp[pp$item == it, ], aes(x = x, y = y, group = item),
            fill = NA, colour = est[[it]]$cor, linewidth = .lw(X$contorno_espessura_pt), show.legend = FALSE)
    }
    if (any(brancos)) {
      pb <- pl[brancos, ]
      cam[[length(cam) + 1]] <- geom_polygon(data = pb, aes(x = x, y = y, group = item), fill = "white",
        colour = .cor(if (identical(X$contorno_cor,
                                    "serie")) "black" else X$contorno_cor), linewidth = .lw(X$contorno_espessura_pt))
    }
  }
  if (length(pts_dados)) {
    pd <- do.call(rbind, pts_dados)
    cam[[length(cam) + 1]] <- geom_point(data = pd, aes(x = x, y = y), shape = X$pontos_simbolo, fill = pd$fill,
      colour = if (X$pontos_simbolo >= 21) scales::alpha("black", 0.8) else pd$fill,
      size = .tx(X$pontos_tamanho_pt), stroke = .st(X$pontos_borda_pt))
  }
  if (length(segs)) {
    sg <- do.call(rbind, segs)
    cam[[length(cam) + 1]] <- geom_segment(data = sg, aes(x = x, xend = xend, y = y, yend = yend),
      colour = sg$cor, linewidth = .lw(sg$lw), lineend = "butt")
  }
  if (length(pts_out)) {
    po <- do.call(rbind, pts_out)
    cam[[length(cam) + 1]] <- geom_point(data = po, aes(x = x, y = y), shape = X$outliers_simbolo,
      colour = po$cor, size = .tx(X$outliers_tamanho_pt), stroke = .st(X$outliers_borda_pt))
  }
  if (length(pts_media)) {
    pm <- do.call(rbind, pts_media)
    cor_media <- .cor(if (identical(X$contorno_cor, "serie")) "black" else X$contorno_cor)
    cam[[length(cam) + 1]] <- geom_point(data = pm, aes(x = x, y = y), shape = X$media_simbolo, fill = pm$fill,
      colour = cor_media, size = .tx(pm$tam), stroke = .st(X$media_borda_pt))
  }
  if (length(txt_n)) {
    tn <- do.call(rbind, txt_n); faixa <- range(c(faixa, tn$y + 0.06 * diff(faixa)))
    tam_n <- X$n_tamanho_pt %||% cfg$texto$tamanho_base_pt * 0.8
    cam[[length(cam) + 1]] <- if (flip) geom_text(data = tn, aes(x = x, y = y, label = rot), hjust = -0.2,
                                                   size = .tx(tam_n), family = .fonte(cfg$texto$fonte))
      else geom_text(data = tn, aes(x = x, y = y, label = rot), vjust = -0.6,
                     size = .tx(tam_n), family = .fonte(cfg$texto$fonte))
  }
  ax_x <- .calc_eixo(cfg$eixo_x, c(0.5, k + 0.5), categorias = itens, forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa, forcar = cfg$.interno$forcar_y)
  aes_leg <- if (length(polys) && any(!grepl("^\\.branco\\.", do.call(rbind, polys)$item))) "fill" else character(0)
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = flip, titulo_x = cfg$eixo_x$titulo %||% (A$nome_grupo %||% ""),
                   titulo_y = cfg$eixo_y$titulo %||% A$nome_valor, legenda_auto = FALSE,
                   faixa_x = c(0.5, k + 0.5), faixa_y = faixa))
}

# -----------------------------------------------------------------------------
#  14_montagem.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/14_montagem.R — montagem final de um gráfico (eixos + tema + anotações)
# =============================================================================

# =============================================================================
#  MONTAGEM FINAL (eixos + tema + anotações)
# =============================================================================
# Escala contínua X ou Y a partir de um eixo calculado (limites, ticks, rótulos, margem).
.escala_continua <- function(ax, xy, sec, posicao = NULL) {
  f <- if (xy == "x") scale_x_continuous else scale_y_continuous
  args <- list(limits = ax$limites, breaks = ax$maiores, minor_breaks = ax$menores,
               labels = ax$rotulos, transform = ax$trans, expand = expansion(mult = ax$mult),
               oob = scales::oob_keep)
  if (!is.null(sec)) args$sec.axis <- sec
  if (!is.null(posicao)) args$position <- posicao
  do.call(f, args)
}

# Camadas de anotação: faixas (antes do gráfico) e referências, setas, textos e letra (depois).
.camadas_extra <- function(cfg, info) {
  cam <- list(); fonte <- .fonte(cfg$texto$fonte)
  an <- cfg$anotacoes
  antes <- list()
  for (fx in an$faixas) {
    cor <- .cor(fx$cor %||% "grey60"); op <- fx$opacidade %||% 0.25
    antes[[length(antes) + 1]] <- if ((fx$eixo %||% "x") == "x")
      annotate("rect", xmin = fx$de, xmax = fx$ate, ymin = -Inf, ymax = Inf, fill = cor, alpha = op)
      else annotate("rect", ymin = fx$de, ymax = fx$ate, xmin = -Inf, xmax = Inf, fill = cor, alpha = op)
  }
  for (r in cfg$referencias) {
    if (is.null(r$valor)) .erro("cfg$referencias: cada linha precisa de 'valor'.")
    cor <- .cor(r$cor %||% "grey40"); esp <- .lw(r$espessura_pt %||% 0.75); tp <- r$tipo %||% "dashed"
    if ((r$eixo %||% "y") == "y") {
      cam[[length(cam) + 1]] <- geom_hline(yintercept = r$valor, colour = cor, linewidth = esp, linetype = tp)
      if (!is.null(r$rotulo)) cam[[length(cam) + 1]] <- annotate("text", x = Inf, y = r$valor, label = r$rotulo,
        hjust = 1.05, vjust = -0.4, colour = cor, size = .tx(r$rotulo_tamanho_pt %||% 8), family = fonte)
    } else {
      cam[[length(cam) + 1]] <- geom_vline(xintercept = r$valor, colour = cor, linewidth = esp, linetype = tp)
      if (!is.null(r$rotulo)) cam[[length(cam) + 1]] <- annotate("text", x = r$valor, y = Inf, label = r$rotulo,
        hjust = 1.05, vjust = -0.4, angle = 90, colour = cor, size = .tx(r$rotulo_tamanho_pt %||% 8), family = fonte)
    }
  }
  for (s in an$setas) {
    cam[[length(cam) + 1]] <- annotate("segment", x = s$x, y = s$y, xend = s$x_fim, yend = s$y_fim,
      colour = .cor(s$cor %||% cfg$texto$cor), linewidth = .lw(s$espessura_pt %||% 0.8),
      arrow = arrow(length = unit(s$tamanho_ponta_pt %||% 6, "pt"), type = "closed"))
  }
  for (t in an$textos) {
    pm <- .tem_formatacao(t$texto)
    cam[[length(cam) + 1]] <- annotate("text", x = t$x, y = t$y,
      label = if (pm) (if (isTRUE(t$negrito)) paste0("bold(", .plotmath(t$texto),
                                                     ")") else .plotmath(t$texto)) else t$texto,
      parse = pm,
      hjust = switch(t$alinhamento %||% "centro", esquerda = 0, centro = 0.5, direita = 1),
      colour = .cor(t$cor %||% cfg$texto$cor), size = .tx(t$tamanho_pt %||% cfg$texto$tamanho_base_pt),
      fontface = if (isTRUE(t$negrito)) "bold" else "plain", family = fonte)
  }
  if (!is.null(an$letra)) {
    cam[[length(cam) + 1]] <- annotation_custom(textGrob(an$letra, x = an$letra_posicao[1], y = an$letra_posicao[2],
      hjust = 0, vjust = 1, gp = gpar(fontsize = an$letra_tamanho_pt %||% cfg$texto$tamanho_base_pt,
                                      fontface = if (isTRUE(an$letra_negrito)) "bold" else "plain",
                                      fontfamily = fonte, col = cfg$texto$cor)),
      xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
  }
  list(antes = antes, depois = cam)
}

# Monta UM gráfico. Entra: dados e cfg. Sai: objeto ggplot (com attr "info" = eixos calculados) ou,
# com so_info = TRUE, só a lista 'info' (faixas de dados e eixos), sem montar nada: é o que a
# passada prévia dos painéis precisa.
.plotar_um <- function(dados, cfg, so_info = FALSE) {
  tipo <- cfg$grafico$tipo
  res <- switch(tipo,
    pontos = , linha = , linha_pontos = , area = , area_empilhada = .construir_xy(dados, cfg),
    barras = .construir_barras(dados, cfg),
    pizza = .construir_pizza(dados, cfg),
    histograma = , densidade = , ecdf = .construir_distribuicao(dados, cfg),
    boxplot = .construir_boxplot(dados, cfg))
  info <- res$info
  if (isTRUE(so_info)) return(info)
  extra <- .camadas_extra(cfg, info)
  g <- ggplot() + extra$antes + res$camadas + extra$depois
  mostrar_leg <- if (identical(cfg$legenda$mostrar, "auto")) info$legenda_auto else isTRUE(cfg$legenda$mostrar)

  if (isTRUE(info$pizza)) {
    g <- g + coord_fixed(xlim = c(-info$lim, info$lim), ylim = c(-info$lim, info$lim), expand = FALSE, clip = "off") +
      .tema(cfg, cfg$eixo_x, cfg$eixo_y, list(hor = "bottom", ver = "left", lado_y2 = ""), sem_eixos = TRUE) +
      labs(title = .texto(cfg$titulos$titulo, cfg$titulos$negrito_titulo), subtitle = .texto(cfg$titulos$subtitulo))
    if (!mostrar_leg) g <- g + theme(legend.position = "none")
    attr(g, "info") <- info
    return(g)
  }

  if (is.null(info$y2) && isTRUE(cfg$eixo_y2$ativo) && identical(cfg$eixo_y2$modo, "transformado")) {
    if (isTRUE(info$flip)) .erro("eixo_y2 \"transformado\" não é suportado em barras/caixas horizontais.")
    if (info$ax_y$escala != "linear") .erro("eixo_y2 \"transformado\" exige eixo_y linear.")
    fa <- cfg$eixo_y2$fator %||% 1; de <- cfg$eixo_y2$deslocamento %||% 0
    if (fa == 0) .erro("cfg$eixo_y2$fator não pode ser 0.")
    e2 <- .eixo_y2_efetivo(cfg)
    l2 <- sort(fa * info$ax_y$limites + de)
    e2$inicio <- e2$inicio %||% l2[1]; e2$fim <- e2$fim %||% l2[2]
    if (e2$inicio != l2[1] || e2$fim != l2[2]) {
      .aviso("eixo_y2 \"transformado\": os limites seguem o eixo_y (", l2[1], " a ", l2[2],
             "); inicio/fim do y2 ignorados.")
      e2$inicio <- l2[1]; e2$fim <- l2[2]
    }
    ax2 <- .calc_eixo(e2, l2)
    cor2 <- if (is.null(cfg$eixo_y2$cor_eixo) || identical(cfg$eixo_y2$cor_eixo,
                                                           "serie")) NULL else cfg$eixo_y2$cor_eixo
    info$y2 <- list(ax = ax2, para2 = function(v) fa * v + de, para1 = function(v) (v - de) / fa,
                    titulo = cfg$eixo_y2$titulo %||% "",
                    cor = cor2 %||% cfg$texto$cor)
  }
  cx <- cfg$caixa; it <- cfg$.interno %||% list()
  espelhar <- isTRUE(cx$fechada) && isTRUE(cx$ticks_espelhados)
  sec_dup <- function(ax) {
    if (!espelhar) return(NULL)
    dup_axis(name = NULL, labels = if (isTRUE(cx$rotulos_espelhados)) derive() else NULL)
  }
  y_dir <- isTRUE(it$y_direita) && is.null(info$y2)
  x_topo <- isTRUE(it$x_topo)
  # secundários
  sec_x <- sec_dup(info$ax_x)
  sec_y <- if (!is.null(info$y2)) {
    a2 <- info$y2$ax
    sec_axis(transform = info$y2$para2, name = .texto(info$y2$titulo, cfg$eixo_y$negrito_titulo), breaks = a2$maiores,
             labels = a2$rotulos)
  } else sec_dup(info$ax_y)
  g <- g + .escala_continua(info$ax_x, "x", sec_x, if (x_topo) "top") +
    .escala_continua(info$ax_y, "y", sec_y, if (y_dir) "right")
  gm <- list(x = guide_axis(minor.ticks = length(info$ax_x$menores) > 0),
             y = guide_axis(minor.ticks = length(info$ax_y$menores) > 0))
  if (!is.null(sec_x)) gm$x.sec <- guide_axis(minor.ticks = length(info$ax_x$menores) > 0)
  if (!is.null(sec_y)) gm$y.sec <- guide_axis(minor.ticks = is.null(info$y2) && length(info$ax_y$menores) > 0)
  g <- g + do.call(guides, gm)
  g <- g + labs(x = .texto(info$titulo_x, cfg$eixo_x$negrito_titulo),
                y = .texto(info$titulo_y, cfg$eixo_y$negrito_titulo),
                title = .texto(cfg$titulos$titulo, cfg$titulos$negrito_titulo),
                subtitle = .texto(cfg$titulos$subtitulo))
  g <- g + if (isTRUE(info$flip)) coord_flip(clip = if (isTRUE(cx$recortar)) "on" else "off")
           else coord_cartesian(clip = if (isTRUE(cx$recortar)) "on" else "off")

  # eixos na TELA (com barras/box horizontais, x e y trocam de lugar)
  eh <- if (isTRUE(info$flip)) cfg$eixo_y else cfg$eixo_x
  ev <- if (isTRUE(info$flip)) cfg$eixo_x else cfg$eixo_y
  axh <- if (isTRUE(info$flip)) info$ax_y else info$ax_x
  axv <- if (isTRUE(info$flip)) info$ax_x else info$ax_y
  tem_sec_v <- !is.null(sec_y); tem_sec_h <- !is.null(sec_x)
  if (isTRUE(info$flip)) { tmp <- tem_sec_v; tem_sec_v <- tem_sec_h; tem_sec_h <- tmp }
  lados <- list(hor = c("bottom", if (tem_sec_h) "top"), ver = c("left", if (tem_sec_v) "right"),
                lado_y2 = if (!is.null(info$y2)) "right" else "",
                grade_x_maior = if (isTRUE(info$flip)) cfg$grade$maior_y else cfg$grade$maior_x,
                grade_y_maior = if (isTRUE(info$flip)) cfg$grade$maior_x else cfg$grade$maior_y,
                grade_x_menor = if (isTRUE(info$flip)) cfg$grade$menor_y else cfg$grade$menor_x,
                grade_y_menor = if (isTRUE(info$flip)) cfg$grade$menor_x else cfg$grade$menor_y)
  ev_y2 <- ev
  g <- g + .tema(cfg, eh, ev, lados, cor_y2 = if (!is.null(info$y2)) .cor(info$y2$cor) else NULL)
  if (!is.null(info$y2)) {
    # estilo de rótulos do y2: casas/notação próprias já nos rótulos; mostra sempre
    d2 <- Filter(Negate(is.null), cfg$eixo_y2[c("distancia_titulo_pt", "distancia_rotulos_pt")])   # distâncias do Y2
    g <- g + theme(axis.text.y.right = .elem_rotulo(utils::modifyList(ev, c(list(mostrar_rotulos = TRUE), d2)), cfg,
                                                    "right",
                                                    .cor(info$y2$cor)),
                   axis.title.y.right = .elem_titulo(utils::modifyList(ev, c(list(mostrar_titulo = !isTRUE(cfg$.interno$sem_titulo_y2)), d2)), cfg, "right",
                                                     .cor(info$y2$cor)))
  }
  if (y_dir && espelhar) {
    g <- g + theme(axis.text.y.left = element_blank(), axis.title.y.left = element_blank(),
                   axis.text.y.right = .elem_rotulo(ev, cfg,
                                                    "right"), axis.title.y.right = .elem_titulo(ev, cfg, "right"))
  }
  ti <- .ticks_internos(axh, axv, lados, info$ax_x, info$ax_y)
  if (!is.null(ti)) g <- g + ti
  if (!is.null(info$y2)) {
    tm <- .ticks_y2_menores(info$y2, info$ax_y, ev, info$ax_x)
    if (!is.null(tm)) g <- g + tm
  }
  if (!mostrar_leg) g <- g + theme(legend.position = "none")
  else g <- .ajustar_legenda(g, cfg)
  attr(g, "info") <- info
  g
}

# -----------------------------------------------------------------------------
#  15_entrada_paineis.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/15_entrada_paineis.R — plotar() (ponto de entrada), painéis e quebra de eixo
# =============================================================================

# =============================================================================
#  PLOTAR (ponto de entrada) — simples, painéis ou quebra de eixo
# =============================================================================
# Ponto de entrada: monta o gráfico, os painéis ou a quebra de eixo conforme o cfg.
# Entra: dados (de ler_csv) e cfg. Sai: ggplot ou patchwork, com attr "cfg" e "dados".
plotar <- function(dados, cfg = get("cfg", envir = globalenv())) {
  if (missing(dados) || !is.data.frame(dados)) .erro("plotar(dados, cfg): 'dados' deve ser o resultado de ler_csv().")
  .checar_nomes(cfg); .checar_itens(cfg)   # avisa nomes digitados errado ANTES de completar com os padrões
  cfg <- .completar_cfg(cfg)
  .validar(cfg, checar_nomes = FALSE)
  g <- if (isTRUE(cfg$paineis$ativo)) .plotar_paineis(dados, cfg)
       else if (isTRUE(cfg$quebra$ativo)) .plotar_quebra(dados, cfg)
       else .plotar_um(dados, cfg)
  attr(g, "dados") <- dados
  attr(g, "cfg") <- cfg
  g
}

# Letra do painel (a), (A), (i)... conforme o formato escolhido.
.formatar_letra <- function(i, formato) {
  l <- letters[i]; L <- LETTERS[i]
  rom <- tolower(as.character(utils::as.roman(i)))
  switch(formato, "(a)" = paste0("(", l, ")"), "a)" = paste0(l, ")"), "a" = l,
         "(A)" = paste0("(", L, ")"), "A" = L, "(i)" = paste0("(", rom, ")"))
}

# Título único (vertical ou horizontal) ao lado de um conjunto de painéis.
.rotulo_lateral <- function(texto, cfg, vertical = TRUE, direita = FALSE, cor = NULL) {
  e <- if (vertical) cfg$eixo_y else cfg$eixo_x
  face <- if (isTRUE(e$negrito_titulo)) "bold" else "plain"
  patchwork::wrap_elements(full = textGrob(.texto(texto, isTRUE(e$negrito_titulo)),
    rot = if (vertical) (if (direita) -90 else 90) else 0,
    gp = gpar(fontsize = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt, fontface = face,
              fontfamily = .fonte(cfg$texto$fonte), col = cor %||% e$cor_titulo %||% cfg$texto$cor)))
}

# Painéis com eixo comum: calcula os limites comuns e monta cada painel. Entra: dados e cfg. Sai: patchwork.
.plotar_paineis <- function(dados, cfg) {
  P <- cfg$paineis; n <- length(P$lista)
  if (n < 1) .erro("cfg$paineis$ativo = TRUE, mas cfg$paineis$lista está vazia. Veja o exemplo na PARTE 1 deste script.")
  vertical <- P$direcao == "vertical"
  comum <- if (vertical) "eixo_x" else "eixo_y"
  cfgs <- lapply(seq_len(n), function(i) {
    p <- P$lista[[i]]
    if (!is.null(p[[comum]]) && length(setdiff(names(p[[comum]]), c("mostrar_rotulos", "mostrar_titulo"))))
      .aviso("Painel ", i, ": ajustes em ", comum, " são ignorados — o ", comum, " é comum a todos os painéis.")
    ajustes <- p[[comum]][intersect(names(p[[comum]]), c("mostrar_rotulos", "mostrar_titulo"))]
    p[[comum]] <- if (length(ajustes)) ajustes else NULL   # só estes dois valem por painel
    ci <- .mesclar(cfg, p)
    ci$paineis$ativo <- FALSE; ci$quebra$ativo <- FALSE
    ci$.interno <- list(em_painel = TRUE)
    .validar(ci)
    ci
  })
  # 1ª passada: só as faixas de dados de cada painel (sem montar o gráfico e sem repetir os avisos,
  # que saem na 2ª passada), para calcular o eixo comum
  previas <- lapply(cfgs, function(ci) suppressWarnings(.plotar_um(dados, ci, so_info = TRUE)))
  faixas <- lapply(previas, function(inf) {
    if (isTRUE(inf$pizza)) .erro("Pizza não pode ser usada em painéis com eixo comum.")
    if (vertical) inf$faixa_x else inf$faixa_y
  })
  tempos <- Filter(Negate(is.null), lapply(previas, function(inf) inf$ax_x$tempo))
  tempo_comum <- if (vertical && length(tempos)) tempos[[1]] else NULL
  tipos <- vapply(cfgs, function(ci) ci$grafico$tipo, "")
  categorias <- lapply(names(dados), function(n) if (!is.numeric(dados[[n]])) unique(as.character(dados[[n]])))
  conhecidos <- c(names(dados), unlist(categorias))
  for (s in setdiff(unique(unlist(lapply(cfgs, function(ci) names(ci$series)))), conhecidos))
    .aviso("cfg$series[[\"", s, "\"]] não corresponde a nenhuma coluna/categoria dos dados.")
  forcar <- if (vertical && all(tipos %in% c("barras", "boxplot"))) NULL
            else .calc_eixo(cfg[[comum]], unlist(faixas), tempo = tempo_comum)$limites
  plots <- vector("list", n)
  for (i in seq_len(n)) {
    ci <- cfgs[[i]]
    ci$.interno <- list(em_painel = TRUE)
    if (vertical) ci$.interno$forcar_x <- forcar else ci$.interno$forcar_y <- forcar
    ultimo <- if (vertical) i == n else i == 1
    if (P$rotulos_eixo_comum == "ultimo" && !ultimo) {
      ci[[comum]]$mostrar_rotulos <- FALSE; ci[[comum]]$mostrar_titulo <- FALSE
    }
    if (isTRUE(P$alternar_lado) && i %% 2 == 0) {
      if (vertical) ci$.interno$y_direita <- TRUE else ci$.interno$x_topo <- TRUE
    }
    outro <- if (vertical) "eixo_y" else "eixo_x"
    if (isTRUE(P$ocultar_rotulo_encostado) && P$espaco_pt < 10) {
      if (vertical && i > 1) ci[[outro]]$.ocultar_extremo <- if (isTRUE(ci[[outro]]$inverter)) "min" else "max"
      if (!vertical && i < n) ci[[outro]]$.ocultar_extremo <- if (isTRUE(ci[[outro]]$inverter)) "min" else "max"
    }
    if (!is.null(P$titulo_unico)) ci[[outro]]$mostrar_titulo <- FALSE
    if (isTRUE(P$letras)) ci$anotacoes$letra <- ci$anotacoes$letra %||% .formatar_letra(i, P$formato_letra)
    m <- cfg$caixa$margens_cm; esp <- P$espaco_pt / 2 / 72 * 2.54
    if (vertical) {
      ci$caixa$margens_cm <- c(if (i == 1) m[1] else esp, m[2], if (i == n) m[3] else esp, m[4])
    } else {
      ci$caixa$margens_cm <- c(m[1], if (i == n) m[2] else esp, m[3], if (i == 1) m[4] else esp)
    }
    if (i > 1) { ci$titulos$titulo <- NULL; ci$titulos$subtitulo <- NULL }   # título só no 1º painel
    plots[[i]] <- .plotar_um(dados, ci)
  }
  tam <- P$tamanhos %||% rep(1, n)
  if (length(tam) != n) .erro("cfg$paineis$tamanhos deve ter ", n, " valores (um por painel).")
  pw <- if (vertical) patchwork::wrap_plots(plots, ncol = 1, heights = tam)
        else patchwork::wrap_plots(plots, nrow = 1, widths = tam)
  if (isTRUE(P$legenda_unica)) {
    pos <- switch(cfg$legenda$posicao, dentro = "right", direita = "right", esquerda = "left", topo = "top",
                  base = "bottom")
    pw <- pw + patchwork::plot_layout(guides = "collect") & theme(legend.position = pos)
  }
  if (!is.null(P$titulo_unico)) {
    lab <- .rotulo_lateral(P$titulo_unico, cfg, vertical)
    pw <- if (vertical) patchwork::wrap_plots(lab, pw, nrow = 1, widths = grid::unit(c(1.6, 1), c("lines", "null")))
          else patchwork::wrap_plots(pw, lab, ncol = 1, heights = grid::unit(c(1, 1.6), c("null", "lines")))
  }
  pw
}

# Sugere cfg$quebra$de e cfg$quebra$ate: o MAIOR VAZIO entre os valores Y dos seus dados (quando um
# grupo de valores está muito longe do outro). Entra: dados e cfg. Sai (invisível): list(de, ate).
# Imprime as linhas prontas para colar. Só olha o maior vazio; para outro, escolha de/ate à mão.
sugerir_quebra <- function(dados, cfg = get("cfg", envir = globalenv())) {
  cfg <- .completar_cfg(cfg)
  ys <- .colunas_y(dados, cfg, excluir = .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x"))
  v <- sort(unique(unlist(lapply(ys, function(y) dados[[y]]))))
  v <- v[is.finite(v)]
  if (length(v) < 2) .erro("Preciso de pelo menos 2 valores Y diferentes para procurar um vazio.")
  vazios <- diff(v); i <- which.max(vazios)
  folga <- vazios[i] * 0.05                              # 5 % de folga de cada lado do vazio
  de <- v[i] + folga; ate <- v[i + 1] - folga
  passo <- 10^(floor(log10(vazios[i])) - 1)              # arredonda para um número "redondo" dentro do vazio
  de2 <- ceiling(de / passo) * passo; ate2 <- floor(ate / passo) * passo
  if (de2 < ate2) { de <- de2; ate <- ate2 }
  cat(sprintf("Maior vazio entre os dados: de %s a %s (largura %s).\n",
              format(v[i], big.mark = ""), format(v[i + 1], big.mark = ""), format(vazios[i], big.mark = "")))
  cat("Cole estas linhas para quebrar o eixo Y nesse trecho:\n")
  cat(sprintf("  cfg$quebra$ativo <- TRUE; cfg$quebra$de <- %s; cfg$quebra$ate <- %s\n",
              format(de, scientific = FALSE), format(ate, scientific = FALSE)))
  invisible(list(de = de, ate = ate))
}

# Eixo Y com trecho omitido: monta as duas partes e as junta. Entra: dados e cfg. Sai: patchwork.
.plotar_quebra <- function(dados, cfg) {
  Q <- cfg$quebra
  if (is.null(Q$de) || is.null(Q$ate) || Q$de >= Q$ate) .erro("cfg$quebra: defina de < ate (ex.: de = 20, ate = 80).")
  if (cfg$grafico$tipo == "pizza") .erro("Quebra de eixo não se aplica a pizza.")
  base <- cfg; base$quebra$ativo <- FALSE
  inf <- .plotar_um(dados, base, so_info = TRUE)
  lim <- inf$ax_y$limites
  if (Q$de <= lim[1] || Q$ate >= lim[2]) .erro("cfg$quebra: o trecho omitido (", Q$de, " a ", Q$ate,
                                               ") precisa estar dentro do eixo Y (", lim[1], " a ", lim[2], ").")
  inferior <- base; superior <- base
  inferior$eixo_y$inicio <- lim[1]; inferior$eixo_y$fim <- Q$de
  superior$eixo_y$inicio <- Q$ate; superior$eixo_y$fim <- lim[2]
  # eixo Y da direita: tem o seu próprio trecho omitido (y2_de/y2_ate); sem eles, acompanha o do Y1
  y2 <- inf$y2
  if (!is.null(y2)) {
    lim2 <- y2$ax$limites
    de2 <- Q$y2_de %||% y2$para2(Q$de); ate2 <- Q$y2_ate %||% y2$para2(Q$ate)
    if (is.null(Q$y2_de) && is.null(Q$y2_ate)) {     # divisa derivada do Y1: arredonda para números "redondos" (sem 0.373714286)
      passo <- .passo_bonito(diff(lim2) / 25)
      d3 <- ceiling(de2 / passo - 1e-9) * passo; a3 <- floor(ate2 / passo + 1e-9) * passo
      if (d3 < a3 && d3 > lim2[1] && a3 < lim2[2]) { de2 <- d3; ate2 <- a3 }
    }
    if (de2 >= ate2) .erro("cfg$quebra: no eixo Y da direita defina y2_de < y2_ate (ex.: y2_de = 2000, y2_ate = 6000).")
    if (de2 <= lim2[1] || ate2 >= lim2[2]) .erro("cfg$quebra: o trecho omitido do eixo Y da direita (", de2, " a ",
                                                 ate2,
                                                 ") precisa estar dentro do eixo (", lim2[1], " a ", lim2[2], ").")
    inferior$eixo_y2$inicio <- lim2[1]; inferior$eixo_y2$fim <- de2
    superior$eixo_y2$inicio <- ate2; superior$eixo_y2$fim <- lim2[2]
  } else if (!is.null(Q$y2_de) || !is.null(Q$y2_ate))
    .aviso("cfg$quebra$y2_de/y2_ate ignorados: não há eixo Y da direita com séries próprias (eixo_y2).")
  continuo <- identical(Q$estilo, "continuo")       # TRUE: uma moldura só, partes coladas (estilo Origin)
  m <- cfg$caixa$margens_cm; esp <- if (continuo) 0 else Q$espaco_pt / 2 / 72 * 2.54
  # a parte de cima fica sem números/título do X; a de baixo sem legenda, títulos e letra
  sem_ligar <- isFALSE(Q$ligar_atraves) && cfg$grafico$tipo %in% c("pontos", "linha", "linha_pontos")
  ajustar_parte <- function(ck, parte, faixa) {
    ck$.interno <- list(forcar_x = inf$ax_x$limites)      # as duas partes compartilham o mesmo eixo X
    if (sem_ligar) {
      ck$.interno$recortar_y <- faixa
      if (!is.null(y2)) ck$.interno$recortar_y2 <- c(ck$eixo_y2$inicio, ck$eixo_y2$fim)
    }
    ck$eixo_y$mostrar_titulo <- FALSE
    ck$.interno$fracao_altura <- if (parte == "superior") Q$proporcao_superior else 1 - Q$proporcao_superior
    if (!is.null(y2)) ck$.interno$sem_titulo_y2 <- TRUE   # o título do Y2 vai uma vez só, ao lado das duas partes
    # intervalo entre os ticks de cada parte (NULL = automático)
    inc <- Q[[paste0("incremento_", parte)]]; inc2 <- Q[[paste0("y2_incremento_", parte)]]
    if (!is.null(inc)) { ck$eixo_y$ticks_modo <- "incremento"; ck$eixo_y$incremento <- inc }
    if (!is.null(inc2) && !is.null(y2)) { ck$eixo_y2$ticks_modo <- "incremento"; ck$eixo_y2$incremento <- inc2 }
    ck$caixa$proporcao <- NULL                         # as alturas das partes seguem proporcao_superior
    if (isTRUE(cfg$exportacao$fundo_transparente)) { ck$caixa$fundo_pagina <- "transparente"; ck$caixa$fundo_painel <- "transparente" }
    if (continuo && parte == "inferior") ck$eixo_y$.ocultar_extremo <- "max"   # o número da divisa aparece só uma vez
    if (parte == "superior") {
      ck$caixa$margens_cm <- c(m[1], 0, esp, 0)
      ck$eixo_x$mostrar_rotulos <- FALSE; ck$eixo_x$mostrar_titulo <- FALSE
    } else {
      ck$caixa$margens_cm <- c(esp, 0, m[3], 0)
      ck$legenda$mostrar <- FALSE; ck$titulos$titulo <- NULL; ck$titulos$subtitulo <- NULL
      ck$anotacoes$letra <- NULL
    }
    ck
  }
  gs <- .plotar_um(dados, ajustar_parte(superior, "superior", c(Q$ate, lim[2])))
  gi <- .plotar_um(dados, ajustar_parte(inferior, "inferior", c(lim[1], Q$de)))
  pr <- Q$proporcao_superior
  if (!continuo && isTRUE(Q$marcas)) {
    marca <- function(y) {
      gp <- gpar(col = cfg$caixa$cor, lwd = .lw(cfg$caixa$espessura_pt) * ggplot2::.pt)
      dx <- unit(Q$marca_largura_pt, "pt"); dy <- unit(Q$marca_altura_pt, "pt")
      gTree(children = gList(
        segmentsGrob(unit(0, "npc") - dx, unit(y, "npc") - dy, unit(0, "npc") + dx, unit(y, "npc") + dy, gp = gp),
        segmentsGrob(unit(1, "npc") - dx, unit(y, "npc") - dy, unit(1, "npc") + dx, unit(y, "npc") + dy, gp = gp)))
    }
    gs <- gs + annotation_custom(marca(0), -Inf, Inf, -Inf, Inf)
    gi <- gi + annotation_custom(marca(1), -Inf, Inf, -Inf, Inf)
  }
  pw <- .quebra_montar(gs, gi, cfg, Q, pr, continuo, inf$titulo_y, y2)
  attr(pw, "partes") <- list(gs, gi)
  attr(pw, "quebra_gtable") <- TRUE   # o salvar() refaz a figura se o fundo for transparente
  pw
}

# -----------------------------------------------------------------------------
#  15_quebra_continua.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/15_quebra_continua.R — quebra de eixo CONTÍNUA (estilo Origin): uma moldura só
# =============================================================================
#  As duas partes ficam coladas dentro de UMA moldura. Nas bordas esquerda e direita, no ponto da
#  quebra, a linha é interrompida e aparecem duas barras "//". É montada com o gtable (que já vem
#  com o ggplot2), pois o patchwork não sabe desenhar uma moldura que atravessa dois gráficos.
# =============================================================================

# Entra: as duas partes (ggplot), cfg, cfg$quebra, a proporção da parte de cima (0 a 1), o estilo (continuo: TRUE) e os
#   títulos laterais (título do Y e info do Y2).
# Sai: um elemento do patchwork com as duas partes empilhadas (gtable). No estilo contínuo ficam coladas, com uma moldura
#   só; no separado cada uma tem a sua moldura. Os títulos dos eixos Y ficam ao lado, à distância pedida dos números.
#   O gtable também vai no atributo "gt" (usado para fixar o tamanho do gráfico).
.quebra_montar <- function(gs, gi, cfg, Q, pr, continuo, tit_y1 = NULL, y2 = NULL) {
  if (!requireNamespace("gtable",
                        quietly = TRUE)) .erro("A quebra de eixo precisa do pacote gtable (vem com o ggplot2).")
  zero <- unit(0, "pt")
  if (is.null(grDevices::dev.list())) {           # ggplotGrob() precisa de um dispositivo: usa um nulo, sem arquivo
    grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  }
  if (continuo) {
    # a moldura e as linhas dos eixos são desenhadas por cima (um traço só); aqui somem as de cada parte
    sem_linhas <- theme(panel.border = element_blank(), axis.line.x.bottom = element_blank(),
                        axis.line.x.top = element_blank(), axis.line.y.left = element_blank(),
                        axis.line.y.right = element_blank())
    gs <- gs + sem_linhas + theme(axis.ticks.x.bottom = element_blank(), axis.ticks.length.x.bottom = zero,
                                  axis.minor.ticks.x.bottom = element_blank(), axis.minor.ticks.length.x.bottom = zero)
    gi <- gi + sem_linhas + theme(axis.ticks.x.top = element_blank(), axis.ticks.length.x.top = zero,
                                  axis.minor.ticks.x.top = element_blank(), axis.minor.ticks.length.x.top = zero,
                                  axis.text.x.top = element_blank(), axis.title.x.top = element_blank())
  }
  ts <- ggplot2::ggplotGrob(gs); ti <- ggplot2::ggplotGrob(gi)
  # legenda à direita/esquerda existe só na parte de cima: dá à de baixo as mesmas colunas, vazias
  falta <- ncol(ts) - ncol(ti)
  if (falta > 0) {
    ti <- if (identical(cfg$legenda$posicao, "esquerda"))
      gtable::gtable_add_cols(ti, ts$widths[seq_len(falta)], pos = 0)
    else gtable::gtable_add_cols(ti, ts$widths[(ncol(ti) + 1):ncol(ts)], pos = -1)
  }
  if (ncol(ts) != ncol(ti)) .erro("Quebra de eixo: as duas partes ficaram com colunas diferentes. ",
                                  "Tente cfg$legenda$posicao <- \"dentro\".")
  gt <- rbind(ts, ti, size = "max")
  pan <- gt$layout[gt$layout$name == "panel", ]
  pan <- pan[order(pan$t), ]
  gt$heights[pan$t[1]] <- unit(pr, "null"); gt$heights[pan$t[2]] <- unit(1 - pr, "null")
  if (continuo) {
    moldura <- .moldura_quebra(cfg, Q, pr)
    gt <- gtable::gtable_add_grob(gt, moldura, t = pan$t[1], b = pan$b[2], l = pan$l[1], r = pan$r[1],
                                  clip = "off", z = Inf, name = "moldura-quebra")
  }
  # títulos dos eixos Y ao lado das duas partes (centrados nas duas), com a distância pedida dos números
  titulo_lateral <- function(gt, texto, e, lado, cor) {
    d <- e$distancia_titulo_pt %||% 4
    gp <- gpar(fontsize = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt,
               fontface = if (isTRUE(e$negrito_titulo)) "bold" else "plain",
               fontfamily = .fonte(cfg$texto$fonte), col = cor %||% e$cor_titulo %||% cfg$texto$cor)
    rot <- if (lado == "esq") 90 else -90
    lab <- .texto(texto, isTRUE(e$negrito_titulo))
    largura <- grid::grobWidth(textGrob(lab, rot = rot, gp = gp)) + unit(d, "pt")
    desl <- unit(if (lado == "esq") -d / 2 else d / 2, "pt")
    tg <- textGrob(lab, rot = rot, x = unit(0.5, "npc") + desl, gp = gp)
    pos <- if (lado == "esq") 0 else -1
    gt <- gtable::gtable_add_cols(gt, largura, pos = pos)
    gtable::gtable_add_grob(gt, tg, t = pan$t[1], b = pan$b[2], l = if (lado == "esq") 1 else ncol(gt),
                            r = if (lado == "esq") 1 else ncol(gt), clip = "off", name = paste0("titulo-y-", lado))
  }
  if (isTRUE(cfg$eixo_y$mostrar_titulo) && !is.null(tit_y1) && !identical(tit_y1, ""))
    gt <- titulo_lateral(gt, tit_y1, cfg$eixo_y, "esq", NULL)
  if (!is.null(y2) && isTRUE(cfg$eixo_y$mostrar_titulo) && !identical(y2$titulo, ""))
    gt <- titulo_lateral(gt, y2$titulo, utils::modifyList(cfg$eixo_y, cfg$eixo_y2[c("distancia_titulo_pt")[
      !is.null(cfg$eixo_y2$distancia_titulo_pt)]]), "dir", .cor(y2$cor))
  m <- cfg$caixa$margens_cm                          # margem externa esquerda/direita (as partes ficam sem ela)
  gt <- gtable::gtable_add_cols(gt, unit(m[4], "cm"), pos = 0)
  gt <- gtable::gtable_add_cols(gt, unit(m[2], "cm"), pos = -1)
  w <- patchwork::wrap_elements(full = gt)
  attr(w, "gt") <- gt
  w
}

# Moldura contínua com as barras "//" no ponto da quebra (coordenadas relativas às duas partes juntas).
# Com marcas = FALSE a moldura fica sem interrupção. Moldura aberta: só eixo esquerdo e inferior.
.moldura_quebra <- function(cfg, Q, pr) {
  cx <- cfg$caixa; fechada <- isTRUE(cx$fechada)
  ev <- cfg$eixo_y; eh <- cfg$eixo_x
  cor <- if (fechada) .cor(cx$cor) else .cor(ev$cor_linha)
  esp <- if (fechada) cx$espessura_pt else ev$espessura_linha_pt
  gp <- gpar(col = cor, lwd = .lw(esp) * ggplot2::.pt, lineend = "square")
  esquerda <- fechada || isTRUE(ev$mostrar_linha)
  direita <- fechada
  base <- fechada || isTRUE(eh$mostrar_linha)
  yj <- unit(1 - pr, "npc")                      # a quebra fica na divisa entre as duas partes
  dx <- unit(Q$marca_largura_pt, "pt"); dy <- unit(Q$marca_altura_pt, "pt"); g <- unit(Q$marca_altura_pt * 0.75, "pt")
  yu <- yj + g; yl <- yj - g                     # centro das duas barras (a linha some entre elas)
  seg <- function(x1, y1, x2, y2) segmentsGrob(x1, y1, x2, y2, gp = gp)
  borda <- function(x) {
    x <- unit(x, "npc")
    if (!isTRUE(Q$marcas)) return(list(seg(x, unit(0, "npc"), x, unit(1, "npc"))))
    list(seg(x, unit(1, "npc"), x, yu), seg(x, yl, x, unit(0, "npc")),
         seg(x - dx, yu - dy, x + dx, yu + dy), seg(x - dx, yl - dy, x + dx, yl + dy))
  }
  filhos <- c(if (esquerda) borda(0), if (direita) borda(1),
              if (fechada) list(seg(unit(0, "npc"), unit(1, "npc"), unit(1, "npc"), unit(1, "npc"))),
              if (base) list(seg(unit(0, "npc"), unit(0, "npc"), unit(1, "npc"), unit(0, "npc"))))
  gTree(children = do.call(gList, filhos))
}

# -----------------------------------------------------------------------------
#  16_exportacao.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/16_exportacao.R — exportação (salvar), prévia (visualizar) e lote
# =============================================================================

# =============================================================================
#  EXPORTAÇÃO E PRÉVIA
# =============================================================================
# TRUE se o cfg (ou algum painel) usa preenchimento em gradiente.
.usa_gradiente <- function(cfg) {
  identical(cfg$cores$preenchimento, "gradiente") ||
    (isTRUE(cfg$paineis$ativo) && any(vapply(cfg$paineis$lista,
                                             function(p) identical(p$cores$preenchimento, "gradiente"), TRUE)))
}

# TRUE se o ragg pode ser usado (e, se o gradiente é radial, se a versão corrige o bug do ragg < 1.5).
.ragg_ok <- function(cfg = NULL) {
  if (!.tem("ragg")) return(FALSE)
  # ragg < 1.5 desenha errado gradiente radial (claro -> escuro): usa Cairo nesse caso
  if (!is.null(cfg) && identical(cfg$cores$preenchimento, "gradiente") &&
      grepl("radial", cfg$cores$gradiente_direcao) && utils::packageVersion("ragg") < "1.5.0") return(FALSE)
  TRUE
}

# Abre o dispositivo gráfico do formato pedido (png, tiff, jpeg, pdf, svg, emf), com os fallbacks do R base.
.abrir_dispositivo <- function(formato, arq, larg_in, alt_in, dpi, fundo, usar_ragg = .tem("ragg")) {
  fundo_jpeg <- if (identical(fundo, "transparent")) "white" else fundo   # JPEG não tem transparência
  switch(formato,
    png = if (usar_ragg) ragg::agg_png(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                       background = fundo)
          else grDevices::png(arq, width = larg_in, height = alt_in, units = "in", res = dpi, bg = fundo,
                              type = if (capabilities("cairo")) "cairo" else "windows"),
    tiff = if (usar_ragg) ragg::agg_tiff(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                            background = fundo, compression = "lzw")
           else grDevices::tiff(arq, width = larg_in, height = alt_in, units = "in", res = dpi, bg = fundo,
                                compression = "lzw", type = if (capabilities("cairo")) "cairo" else "windows"),
    jpeg = if (usar_ragg) ragg::agg_jpeg(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                         background = fundo_jpeg, quality = 95)
           else grDevices::jpeg(arq, width = larg_in, height = alt_in, units = "in", res = dpi, quality = 95,
                                bg = fundo_jpeg),
    pdf = if (capabilities("cairo")) grDevices::cairo_pdf(arq, width = larg_in, height = alt_in, bg = fundo)
          else grDevices::pdf(arq, width = larg_in, height = alt_in, bg = fundo, useDingbats = FALSE),
    svg = if (.tem("svglite")) svglite::svglite(arq, width = larg_in, height = alt_in, bg = fundo)
          else grDevices::svg(arq, width = larg_in, height = alt_in, bg = fundo),
    emf = if (.tem("devEMF")) devEMF::emf(arq, width = larg_in, height = alt_in, bg = fundo, emfPlus = TRUE)
          else .erro("Formato emf precisa do pacote devEMF (rode instalar_pacotes())."),
    .erro("Formato '", formato, "' desconhecido. OPÇÕES: png, tiff, jpeg, pdf, svg, emf"))
}

# Cópia do cfg com todos os preenchimentos em cor sólida (formatos sem gradiente).
.sem_gradiente <- function(cfg) {
  cfg$cores$preenchimento <- "solido"
  if (isTRUE(cfg$paineis$ativo))
    cfg$paineis$lista <- lapply(cfg$paineis$lista, function(p) {
      if (!is.null(p$cores)) p$cores$preenchimento <- "solido"
      p
    })
  cfg
}

# Tamanho de saída. Sem painel de tamanho fixo: o da página (cfg$exportacao). Com cfg$caixa$painel_largura_cm /
# painel_altura_cm: a caixa do gráfico fica EXATAMENTE nesse tamanho, e a página cresce (ou encolhe) para caber
# números, títulos e legenda sem cortar nada (exportacao$ajustar_pagina = TRUE) — o gráfico tem o mesmo tamanho
# em todos os arquivos. Entra: g e cfg. Sai: list(grob = NULL | gtable pronto para desenhar, larg, alt em polegadas).
.preparar_saida <- function(g, cfg) {
  pg <- .tamanho_pagina_in(cfg)
  cx <- cfg$caixa
  pw <- cx$painel_largura_cm; ph <- cx$painel_altura_cm
  if (is.null(pw) && is.null(ph)) return(list(grob = NULL, larg = pg[1], alt = pg[2]))
  if (is.null(ph) && !is.null(pw) && !is.null(cx$proporcao)) ph <- pw * cx$proporcao
  if (is.null(pw) && !is.null(ph) && !is.null(cx$proporcao)) pw <- ph / cx$proporcao
  gt <- attr(g, "gt")
  if (is.null(gt)) {
    if (inherits(g, "patchwork")) {
      .aviso("caixa$painel_largura_cm/painel_altura_cm não valem para painéis empilhados; tamanho da página usado.")
      return(list(grob = NULL, larg = pg[1], alt = pg[2]))
    }
    if (is.null(grDevices::dev.list())) { grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE) }
    gt <- ggplot2::ggplotGrob(g)
  }
  pan <- gt$layout[gt$layout$name == "panel", ]
  pan <- pan[order(pan$t, pan$l), ]
  cols <- sort(unique(unlist(Map(seq, pan$l, pan$r)))); linhas <- sort(unique(unlist(Map(seq, pan$t, pan$b))))
  if (!is.null(pw) && length(cols) == 1) gt$widths[cols] <- grid::unit(pw, "cm")
  if (!is.null(ph)) {
    if (length(linhas) == 1) gt$heights[linhas] <- grid::unit(ph, "cm")
    else if (length(linhas) == 2) {                      # quebra de eixo: a altura se divide entre as duas partes
      pr <- cfg$quebra$proporcao_superior %||% 0.5
      gt$heights[linhas] <- grid::unit(c(ph * pr, ph * (1 - pr)), "cm")
    }
  }
  gt$respect <- FALSE
  dev_ant <- grDevices::dev.cur()
  if (.tem("ragg")) ragg::agg_capture(width = 10, height = 10, units = "in", res = 72) else grDevices::pdf(NULL)
  dev_nosso <- grDevices::dev.cur()
  tam <- tryCatch({
    soma <- function(u, f) if (any(grid::unitType(u) == "null")) NA_real_ else f(sum(u), "in", valueOnly = TRUE)
    c(soma(gt$widths, grid::convertWidth), soma(gt$heights, grid::convertHeight))
  }, finally = if (dev_nosso %in% grDevices::dev.list()) grDevices::dev.off(dev_nosso))
  if (dev_ant %in% grDevices::dev.list()) grDevices::dev.set(dev_ant)
  if (isTRUE(cfg$exportacao$ajustar_pagina %||% TRUE)) {
    larg <- if (is.na(tam[1])) pg[1] else tam[1]; alt <- if (is.na(tam[2])) pg[2] else tam[2]
  } else {
    larg <- pg[1]; alt <- pg[2]
    if (!is.na(tam[1]) && tam[1] > larg * 1.005 || !is.na(tam[2]) && tam[2] > alt * 1.005)
      .aviso("O gráfico (caixa de tamanho fixo + números, títulos e legenda) tem ", round(tam[1] * 2.54, 1), " x ",
             round(tam[2] * 2.54, 1), " cm e não cabe na página de ", round(pg[1] * 2.54, 1), " x ",
             round(pg[2] * 2.54,
                   1), " cm: parte será cortada. Aumente a página ou use exportacao$ajustar_pagina <- TRUE.")
  }
  list(grob = gt, larg = larg, alt = alt)
}

# Desenha o gráfico no dispositivo aberto: o gtable de tamanho fixo (se houver) ou o objeto como está.
.desenhar <- function(prep, g) {
  if (is.null(prep$grob)) print(g) else { grid::grid.newpage(); grid::grid.draw(prep$grob) }
}

#' Exporta o gráfico nos formatos de cfg$exportacao
# Deixa transparentes o fundo da página e o do painel SEM refazer o gráfico, para não perder o que
# o usuário somou ao objeto (+ theme(), + labs(), + camadas). Serve para ggplot e para patchwork.
.fundo_transparente <- function(g) {
  t <- theme(plot.background = element_rect(fill = NA, colour = NA),
             panel.background = element_rect(fill = NA, colour = NA))
  if (inherits(g, "patchwork")) g & t else g + t
}

# Exporta o gráfico nos formatos de cfg$exportacao. Entra: g (de plotar), cfg e nome opcional. Sai: caminhos gravados.
salvar <- function(g, cfg = attr(g, "cfg") %||% get("cfg", envir = globalenv()), nome = NULL) {
  cfg <- .completar_cfg(cfg)
  ex <- cfg$exportacao
  fator <- switch(ex$unidade, cm = 1 / 2.54, mm = 1 / 25.4, `in` = 1)
  larg <- ex$largura * fator; alt <- ex$altura * fator
  ex$pasta <- .pasta_proj(ex$pasta)
  if (!dir.exists(ex$pasta)) dir.create(ex$pasta, recursive = TRUE)
  dados <- attr(g, "dados")
  base <- nome %||% ex$nome_arquivo %||% paste0(
    if (!is.null(attr(dados, "arquivo"))) tools::file_path_sans_ext(basename(attr(dados, "arquivo"))) else "grafico",
    "_", cfg$grafico$tipo)
  if (isTRUE(ex$carimbo_data)) base <- paste0(base, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  fundo <- if (isTRUE(ex$fundo_transparente)) "transparent" else "white"
  transparente <- isTRUE(ex$fundo_transparente)
  if (transparente) {
    # quebra contínua: as partes têm fundo próprio e só nascem transparentes ao montar o gráfico
    if (isTRUE(attr(g, "quebra_gtable")) && !is.null(dados)) g <- plotar(dados, cfg)
    g <- .fundo_transparente(g)
  }
  prep <- .preparar_saida(g, cfg)
  larg <- prep$larg; alt <- prep$alt
  saidas <- character(0)
  for (f in tolower(ex$formatos)) {
    ext <- switch(f, jpeg = "jpg", f)
    arq <- file.path(ex$pasta, paste0(base, ".", ext))
    if (!isTRUE(ex$sobrescrever)) {
      k <- 2
      while (file.exists(arq)) {
        arq <- file.path(ex$pasta, paste0(base, "_", k, ".", ext))
        k <- k + 1
      }
    }
    .abrir_dispositivo(f, arq, larg, alt, ex$dpi, fundo, usar_ragg = .ragg_ok(cfg))
    disp <- grDevices::dev.cur()
    tryCatch({
      gg <- g; prep_f <- prep
      if (.usa_gradiente(cfg)) {
        cap <- tryCatch(unlist(grDevices::dev.capabilities()$patterns), error = function(e) character(0))
        if (!"LinearGradient" %in% cap) {
          .aviso("O formato '", f, "' não suporta gradiente; usando cor sólida neste arquivo ",
                 "(o gráfico é refeito a partir do cfg: ajustes feitos depois com + theme() ou ",
                 "+ camadas não entram nele).")
          if (!is.null(dados)) {
            gg <- plotar(dados, .sem_gradiente(cfg))
            if (transparente) gg <- .fundo_transparente(gg)
            prep_f <- .preparar_saida(gg, cfg)
          }
        }
      }
      .desenhar(prep_f, gg)
    }, finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
    saidas <- c(saidas, arq)
  }
  message("Salvo: ", paste(normalizePath(saidas, winslash = "/", mustWork = FALSE), collapse = "\n       "))
  invisible(saidas)
}

#' Prévia fiel (mesmo tamanho e fontes do arquivo final) no Viewer do RStudio
visualizar <- function(g, cfg = attr(g, "cfg") %||% get("cfg", envir = globalenv()), dpi = 150) {
  cfg <- .completar_cfg(cfg)
  ex <- cfg$exportacao
  fator <- switch(ex$unidade, cm = 1 / 2.54, mm = 1 / 25.4, `in` = 1)
  arq <- tempfile("previa_", fileext = ".png")
  prep <- .preparar_saida(g, cfg)
  .abrir_dispositivo("png", arq, prep$larg, prep$alt, dpi, "white", usar_ragg = .ragg_ok(cfg))
  disp <- grDevices::dev.cur()
  tryCatch(.desenhar(prep, g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    html <- tempfile("previa_", fileext = ".html")
    writeLines(sprintf(paste0(
      '<html><body style="margin:0;background:#e5e5e5;display:flex;justify-content:center;',
      'align-items:flex-start;padding:12px"><img src="%s" style="max-width:100%%;',
      'box-shadow:0 1px 6px #888"></body></html>'), basename(arq)), html)
    file.copy(arq, file.path(dirname(html), basename(arq)), overwrite = TRUE)
    viewer(html)
  } else {
    .desenhar(prep, g)
  }
  invisible(arq)
}

#' Aplica o mesmo cfg a todos os CSVs de uma pasta
exportar_lote <- function(pasta = "dados", cfg = get("cfg", envir = globalenv()), padrao = "\\.csv$") {
  pasta <- .pasta_proj(pasta)
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE, ignore.case = TRUE)
  if (!length(arqs)) .erro("Nenhum CSV em '", pasta, "'.")
  res <- list()
  for (a in arqs) {
    message("\n>> ", basename(a))
    r <- tryCatch({
      d <- ler_csv(a, cfg$dados); g <- plotar(d, cfg)
      c2 <- cfg; c2$exportacao$nome_arquivo <- NULL
      salvar(g, c2)
    }, error = function(e) { message("   ERRO: ", conditionMessage(e)); NULL })
    res[[basename(a)]] <- r
  }
  invisible(res)
}

# -----------------------------------------------------------------------------
#  17_estilos.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/17_estilos.R — estilos salvos, reset do cfg e lista de fontes
# =============================================================================

# =============================================================================
#  ESTILOS (presets) E RESET
# =============================================================================
.BLOCOS_ESTILO <- c("cores", "serie_padrao", "linhas", "barras", "pizza", "distribuicao", "boxplot",
                    "eixo_x", "eixo_y", "eixo_y2", "caixa", "grade", "legenda", "titulos", "texto", "exportacao")

# Grava os blocos de aparência do cfg em estilos/<nome>.R (sem títulos nem limites dos dados).
salvar_estilo <- function(cfg, nome, pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  if (!dir.exists(pasta)) dir.create(pasta)
  est <- cfg[.BLOCOS_ESTILO]
  # não guarda o que é específico de um conjunto de dados
  for (ax in c("eixo_x", "eixo_y", "eixo_y2")) est[[ax]][c("titulo", "inicio", "fim", "ticks_manuais",
                                                           "rotulos_manuais")] <- NULL
  est$exportacao$nome_arquivo <- NULL
  arq <- file.path(pasta, paste0(nome, ".R"))
  con <- file(arq, "w", encoding = "UTF-8")
  writeLines(c(paste0("# Estilo '", nome, "' salvo em ", format(Sys.time(), "%d/%m/%Y %H:%M")),
               paste0("# Pode ser editado à mão. Carregue com: cfg <- carregar_estilo(\"", nome, "\", cfg)")), con)
  dput(est, con, control = c("keepNA", "keepInteger", "niceNames", "showAttributes"))
  close(con)
  message("Estilo salvo em ", arq)
  invisible(arq)
}

# Entra: nome do estilo e cfg. Sai: o cfg com o estilo aplicado por cima.
carregar_estilo <- function(nome, cfg = get("cfg", envir = globalenv()), pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  if (!file.exists(nome) && !file.exists(file.path(pasta, paste0(nome, ".R"))) && nome %in% names(.ESTILOS_EMBUTIDOS))
    return(.mesclar(cfg, .ESTILOS_EMBUTIDOS[[nome]]))      # estilo embutido neste script
  arq <- if (file.exists(nome)) nome else file.path(pasta, paste0(nome, ".R"))
  if (!file.exists(arq)) {
    disp <- listar_estilos(pasta)
    .erro("Estilo '", nome, "' não encontrado. Disponíveis: ", paste(disp, collapse = ", "))
  }
  est <- eval(parse(arq, encoding = "UTF-8"))
  .mesclar(cfg, est)
}

# Nomes dos estilos disponíveis: os 3 embutidos neste script e os arquivos da pasta de estilos.
listar_estilos <- function(pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  sort(unique(c(names(.ESTILOS_EMBUTIDOS), sub("\\.R$", "", list.files(pasta, pattern = "\\.R$")))))
}

# Volta o cfg do console ao padrão da PARTE 1 deste script.
resetar_cfg <- function() {
  assign("cfg", .CFG_PADRAO, envir = globalenv())
  message("cfg voltou ao padrão (PARTE 1 do script)")
  invisible(.CFG_PADRAO)
}

# Imprime os nomes de fonte instalados (pelo systemfonts) para usar em cfg$texto$fonte.
listar_fontes <- function() {
  if (!.tem("systemfonts")) {
    message("Instale 'systemfonts' (vem com ragg) para listar as fontes.")
    return(invisible())
  }
  f <- sort(unique(.familias_fontes()))
  print(f)
  invisible(f)
}

# Famílias que o R enxerga: as instaladas no sistema e as registradas por registrar_fonte().
.familias_fontes <- function() {
  c(systemfonts::system_fonts()$family, systemfonts::registry_fonts()$family)
}

# Usa uma fonte que está num arquivo .ttf/.otf, SEM instalá-la no Windows (vale só nesta sessão do R).
# Serve quando a fonte instalada não aparece em listar_fontes().
# Entra: nome (como vai em cfg$texto$fonte) e pasta (com os arquivos, ex.: "Barlow-Regular.ttf",
#   "Barlow-Bold.ttf", "Barlow-Italic.ttf", "Barlow-BoldItalic.ttf") ou arquivos (vetor com nomes
#   regular, bold, italic, bolditalic). Só o regular é obrigatório. Sai (invisível): o nome registrado.
registrar_fonte <- function(nome, pasta = NULL, arquivos = NULL) {
  if (!.tem("systemfonts")) .erro("registrar_fonte() precisa do pacote systemfonts (vem com ragg).")
  if (!is.character(nome) || length(nome) != 1 || !nzchar(nome)) .erro("registrar_fonte(nome): informe o nome da fonte, ex.: \"Barlow\".")
  if (is.null(arquivos)) {
    if (is.null(pasta) || !dir.exists(pasta)) .erro("registrar_fonte: a pasta '", pasta %||% "", "' não existe. ",
                                                    "Use o caminho da pasta com os .ttf, ex.: \"C:/Users/voce/Downloads/Barlow\".")
    todos <- list.files(pasta, pattern = "\\.(ttf|otf)$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
    base <- gsub("[ _]", "", nome)
    estilo <- sub("\\.(ttf|otf)$", "", basename(todos), ignore.case = TRUE)
    ok <- grepl(paste0("^", base, "-"), estilo, ignore.case = TRUE)   # "Barlow-Bold" sim; "BarlowCondensed-Bold" não
    estilo <- tolower(sub("^[^-]*-", "", estilo[ok])); todos <- todos[ok]
    achar <- function(e) { i <- which(estilo == e); if (length(i)) todos[i[1]] else NA_character_ }
    arquivos <- c(regular = achar("regular"), bold = achar("bold"), italic = achar("italic"),
                  bolditalic = achar("bolditalic"))
  }
  arquivos <- unlist(arquivos)
  if (is.null(names(arquivos))) names(arquivos) <- c("regular", "bold", "italic", "bolditalic")[seq_along(arquivos)]
  reg <- arquivos[["regular"]]
  if (is.null(reg) || is.na(reg) || !file.exists(reg))
    .erro("registrar_fonte: não achei o arquivo \"", nome, "-Regular.ttf\" em '", pasta %||% "", "'.\n",
          "  Arquivos .ttf/.otf encontrados lá: ",
          paste(utils::head(basename(list.files(pasta %||% ".", pattern = "\\.(ttf|otf)$", recursive = TRUE,
                                                ignore.case = TRUE)), 8),
                collapse = ", "),
          "\n  Use os arquivos estáticos (Barlow-Regular.ttf...), não o arquivo de fonte variável (com colchetes no nome).")
  pega <- function(k) { v <- arquivos[k]; if (length(v) && !is.na(v) && file.exists(v)) unname(v) else reg }
  bo <- pega("bold"); it <- pega("italic")
  bi <- { v <- arquivos["bolditalic"]; if (length(v) && !is.na(v) && file.exists(v)) unname(v) else bo }
  systemfonts::register_font(name = nome, plain = reg, bold = bo, italic = it, bolditalic = bi)
  .fontes_cache[[nome]] <- NULL                       # esquece um "não encontrada" anterior
  message("Fonte '", nome, "' registrada (", sum(!is.na(arquivos) & file.exists(arquivos)), " arquivo(s)). ",
          "Use cfg$texto$fonte <- \"", nome, "\".")
  invisible(nome)
}

# -----------------------------------------------------------------------------
#  18_painel.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/18_painel.R — PAINEL DE AJUSTES: variáveis simples (escala, ticks, grade, quebra, cores...)
# =============================================================================
#  O painel (arquivo painel_de_ajustes.R ou PARTE 3 do script único) define variáveis como
#  x_intervalo <- 1 ou grade_tipo <- "dashed". aplicar_painel() copia as que não são NULL para o
#  cfg. NULL = "não mexer" (vale o padrão do template).
# =============================================================================

# Variável do painel -> c(bloco do cfg, parâmetro). Valor copiado como está.
.PAINEL_MAPA <- list(
  # tipo e colunas
  tipo_grafico = c("grafico", "tipo"), coluna_x = c("grafico", "coluna_x"), colunas_y = c("grafico", "colunas_y"),
  # escala
  x_inicio = c("eixo_x", "inicio"), x_fim = c("eixo_x", "fim"), x_folga_pct = c("eixo_x", "margem_percentual"),
  x_escala = c("eixo_x", "escala"), x_inverter = c("eixo_x", "inverter"),
  y_inicio = c("eixo_y", "inicio"), y_fim = c("eixo_y", "fim"), y_folga_pct = c("eixo_y", "margem_percentual"),
  y_escala = c("eixo_y", "escala"), y_inverter = c("eixo_y", "inverter"),
  recortar_nos_limites = c("caixa", "recortar"),
  # ticks
  x_primeiro_tick = c("eixo_x", "primeiro_tick"), x_ticks_menores = c("eixo_x", "n_menores"),
  x_ticks_direcao = c("eixo_x", "direcao_maiores"), x_ticks_menores_direcao = c("eixo_x", "direcao_menores"),
  x_ticks_comprimento_pt = c("eixo_x", "comprimento_maiores_pt"),
  x_ticks_menores_comprimento_pt = c("eixo_x", "comprimento_menores_pt"),
  y_primeiro_tick = c("eixo_y", "primeiro_tick"), y_ticks_menores = c("eixo_y", "n_menores"),
  y_ticks_direcao = c("eixo_y", "direcao_maiores"), y_ticks_menores_direcao = c("eixo_y", "direcao_menores"),
  y_ticks_comprimento_pt = c("eixo_y", "comprimento_maiores_pt"),
  y_ticks_menores_comprimento_pt = c("eixo_y", "comprimento_menores_pt"),
  ticks_espelhados = c("caixa", "ticks_espelhados"),
  x_ticks_espessura_pt = c("eixo_x", "espessura_ticks_pt"), y_ticks_espessura_pt = c("eixo_y", "espessura_ticks_pt"),
  x_ticks_cor = c("eixo_x", "cor_ticks"), y_ticks_cor = c("eixo_y", "cor_ticks"),
  x_linha_espessura_pt = c("eixo_x", "espessura_linha_pt"), y_linha_espessura_pt = c("eixo_y", "espessura_linha_pt"),
  moldura_espessura_pt = c("caixa", "espessura_pt"), moldura_cor = c("caixa", "cor"),
  # números e títulos
  x_titulo = c("eixo_x", "titulo"), y_titulo = c("eixo_y", "titulo"), titulo_grafico = c("titulos", "titulo"),
  titulo_grafico_negrito = c("titulos", "negrito_titulo"),
  x_dividir_por = c("eixo_x", "fator_divisao"), y_dividir_por = c("eixo_y", "fator_divisao"),
  x_casas_decimais = c("eixo_x", "casas_decimais"), y_casas_decimais = c("eixo_y", "casas_decimais"),
  x_notacao = c("eixo_x", "notacao"), y_notacao = c("eixo_y", "notacao"),
  x_rotacao_numeros = c("eixo_x", "rotacao_rotulos"), y_rotacao_numeros = c("eixo_y", "rotacao_rotulos"),
  x_mostrar_numeros = c("eixo_x", "mostrar_rotulos"), y_mostrar_numeros = c("eixo_y", "mostrar_rotulos"),
  # grade
  grade_x = c("grade", "maior_x"), grade_y = c("grade", "maior_y"), grade_cor = c("grade", "cor_maior"),
  grade_tipo = c("grade", "tipo_maior"), grade_espessura_pt = c("grade", "espessura_maior_pt"),
  grade_opacidade = c("grade", "opacidade_maior"),
  grade_menor_x = c("grade", "menor_x"), grade_menor_y = c("grade", "menor_y"),
  grade_menor_cor = c("grade", "cor_menor"), grade_menor_tipo = c("grade", "tipo_menor"),
  grade_menor_espessura_pt = c("grade", "espessura_menor_pt"), grade_menor_opacidade = c("grade", "opacidade_menor"),
  # quebra
  quebra_estilo = c("quebra", "estilo"), quebra_de = c("quebra",
                                                       "de"), quebra_ate = c("quebra", "ate"), quebra_espaco_pt = c("quebra", "espaco_pt"),
  quebra_y2_de = c("quebra", "y2_de"), quebra_y2_ate = c("quebra", "y2_ate"),
  quebra_y_intervalo_inferior = c("quebra", "incremento_inferior"),
  quebra_y_intervalo_superior = c("quebra", "incremento_superior"),
  quebra_y2_intervalo_inferior = c("quebra", "y2_incremento_inferior"),
  quebra_y2_intervalo_superior = c("quebra", "y2_incremento_superior"),
  quebra_ligar_pontos = c("quebra", "ligar_atraves"), quebra_proporcao_superior = c("quebra", "proporcao_superior"),
  # cores, linhas e símbolos
  cores_paleta = c("cores", "paleta"), cores_gradiente_cor2 = c("cores", "gradiente_cor2"),
  linha_espessura_pt = c("serie_padrao",
                         "linha_espessura_pt"), simbolo_tamanho_pt = c("serie_padrao", "tamanho_simbolo_pt"),
  simbolo_borda_pt = c("serie_padrao", "espessura_borda_pt"),
  simbolo_forma = c("serie_padrao", "simbolo"), simbolo_variar = c("cores", "incrementar_simbolo"),
  simbolos_ordem = c("cores", "simbolos_ordem"), simbolo_preenchimento = c("serie_padrao", "preenchimento_simbolo"),
  esfera_luz = c("serie_padrao", "esfera_luz"),
  # texto
  fonte = c("texto", "fonte"), tamanho_texto_pt = c("texto", "tamanho_base_pt"), cor_texto = c("texto", "cor"),
  titulo_grafico_tamanho_pt = c("titulos", "tamanho_titulo_pt"),
  x_titulo_tamanho_pt = c("eixo_x", "tamanho_titulo_pt"), y_titulo_tamanho_pt = c("eixo_y", "tamanho_titulo_pt"),
  x_numeros_tamanho_pt = c("eixo_x", "tamanho_rotulos_pt"), y_numeros_tamanho_pt = c("eixo_y", "tamanho_rotulos_pt"),
  legenda_texto_tamanho_pt = c("legenda",
                               "tamanho_texto_pt"), legenda_titulo_tamanho_pt = c("legenda", "tamanho_titulo_pt"),
  # legenda e moldura
  legenda_mostrar = c("legenda", "mostrar"), legenda_posicao = c("legenda", "posicao"),
  legenda_x = c("legenda", "dentro_x"), legenda_y = c("legenda", "dentro_y"), legenda_titulo = c("legenda", "titulo"),
  legenda_escala = c("legenda", "escala"), legenda_distancia_pt = c("legenda", "distancia_pt"),
  legenda_ajustar_caixa = c("legenda", "ajustar_caixa"),
  painel_largura_cm = c("caixa", "painel_largura_cm"), painel_altura_cm = c("caixa", "painel_altura_cm"),
  ajustar_pagina = c("exportacao", "ajustar_pagina"),
  x_distancia_titulo_pt = c("eixo_x",
                            "distancia_titulo_pt"), y_distancia_titulo_pt = c("eixo_y", "distancia_titulo_pt"),
  x_distancia_numeros_pt = c("eixo_x",
                             "distancia_rotulos_pt"), y_distancia_numeros_pt = c("eixo_y", "distancia_rotulos_pt"),
  y2_distancia_titulo_pt = c("eixo_y2",
                             "distancia_titulo_pt"), y2_distancia_numeros_pt = c("eixo_y2", "distancia_rotulos_pt"),
  legenda_ancora = c("legenda", "ancora"), legenda_alinhar = c("legenda", "alinhar"),
  legenda_direcao = c("legenda", "direcao"), legenda_n_colunas = c("legenda", "n_colunas"),
  legenda_inverter_ordem = c("legenda", "inverter_ordem"), legenda_tamanho_chave_pt = c("legenda", "tamanho_chave_pt"),
  legenda_espacamento_pt = c("legenda",
                             "espacamento_pt"), legenda_margem_interna_pt = c("legenda", "margem_interna_pt"),
  legenda_fundo = c("legenda", "fundo"), legenda_fundo_opacidade = c("legenda", "fundo_opacidade"),
  legenda_borda = c("legenda", "moldura"), legenda_borda_cor = c("legenda", "cor_moldura"),
  legenda_borda_espessura_pt = c("legenda", "espessura_moldura_pt"), legenda_borda_tipo = c("legenda", "tipo_moldura"),
  legenda_sombra = c("legenda", "sombra"), legenda_sombra_cor = c("legenda", "sombra_cor"),
  legenda_sombra_opacidade = c("legenda", "sombra_opacidade"),
  legenda_sombra_deslocamento_pt = c("legenda", "sombra_deslocamento_pt"),
  caixa_fechada = c("caixa", "fechada"),
  # exportação
  largura_cm = c("exportacao", "largura"), altura_cm = c("exportacao", "altura"), dpi = c("exportacao", "dpi"),
  formatos = c("exportacao", "formatos"), nome_arquivo = c("exportacao", "nome_arquivo"),
  pasta_saida = c("exportacao", "pasta")
)

# Variáveis do painel que mexem no eixo Y da direita (Y2).
.Y2_VARIAVEIS <- c("y2_series", "y2_fator", "y2_deslocamento", "y2_titulo", "y2_inicio", "y2_fim", "y2_intervalo",
                   "y2_ticks_manuais", "y2_ticks_menores", "y2_cor", "y2_cor_eixo", "y2_dividir_por", "y2_casas_decimais",
                   "y2_notacao", "y2_prefixo", "y2_sufixo", "y2_igual_y1", "y2_legenda_sufixo")

# Entra: cfg, o ambiente onde estão as variáveis do painel (padrão: o console/global) e, opcional, os
# dados (para a quebra automática). Sai: o cfg com os ajustes do painel; imprime o que foi aplicado.
aplicar_painel <- function(cfg, painel = globalenv(), dados = NULL) {
  cfg <- .completar_cfg(cfg)
  pega <- function(nome) get0(nome, envir = painel, inherits = FALSE)
  aplicados <- character(0)
  marca <- function(nome) aplicados <<- c(aplicados, nome)

  for (nome in names(.PAINEL_MAPA)) {
    v <- pega(nome)
    if (is.null(v)) next
    alvo <- .PAINEL_MAPA[[nome]]
    if (nome == "recortar_nos_limites") v <- isTRUE(v)
    cfg[[alvo[1]]][[alvo[2]]] <- v
    marca(nome)
  }
  # intervalo entre ticks maiores / ticks em posições escolhidas
  for (ax in c("x", "y")) {
    e <- paste0("eixo_", ax)
    iv <- pega(paste0(ax, "_intervalo")); tm <- pega(paste0(ax, "_ticks_manuais"))
    if (!is.null(iv)) { cfg[[e]]$ticks_modo <- "incremento"; cfg[[e]]$incremento <- iv; marca(paste0(ax, "_intervalo")) }
    if (!is.null(tm)) { cfg[[e]]$ticks_modo <- "manual"; cfg[[e]]$ticks_manuais <- tm; marca(paste0(ax, "_ticks_manuais")) }
  }
  # fonte que está só num arquivo .ttf (sem instalar): registra antes de o gráfico usar o nome
  fp <- pega("fonte_pasta")
  if (!is.null(fp)) {
    nome_f <- pega("fonte")
    if (is.null(nome_f)) .erro("fonte_pasta precisa de 'fonte' (o nome), ex.: fonte <- \"Barlow\".")
    registrar_fonte(nome_f, pasta = fp); marca("fonte_pasta")
  }
  # legenda: canto pronto (posição + âncora) e ligação automática da borda / sombra quando só o detalhe é dado
  canto <- pega("legenda_canto")
  if (!is.null(canto)) {
    cantos <- list(sup_esq = c(0, 1), sup_centro = c(0.5, 1), sup_dir = c(1, 1), centro_esq = c(0, 0.5),
                   centro = c(0.5, 0.5),
                   centro_dir = c(1, 0.5), inf_esq = c(0, 0), inf_centro = c(0.5, 0), inf_dir = c(1, 0))
    if (length(canto) != 1 || !canto %in% names(cantos))
      .erro("legenda_canto = '", paste(canto, collapse = ","), "' não é válido. OPÇÕES: ",
            paste0('"', names(cantos), '"', collapse = " | "))
    a <- cantos[[canto]]; folga <- if (is.null(pega("legenda_distancia_pt"))) 0.03 else 0   # com distância em pt: encosta na borda
    cfg$legenda$posicao <- "dentro"               # legenda_x / legenda_y / legenda_ancora, se dados, valem mais
    if (is.null(pega("legenda_ancora"))) cfg$legenda$ancora <- a
    if (is.null(pega("legenda_x"))) cfg$legenda$dentro_x <- if (a[1] == 0) folga else if (a[1] == 1) 1 - folga else 0.5
    if (is.null(pega("legenda_y"))) cfg$legenda$dentro_y <- if (a[2] == 0) folga else if (a[2] == 1) 1 - folga else 0.5
    marca("legenda_canto")
  }
  if (is.null(pega("legenda_borda")) && any(!vapply(list(pega("legenda_borda_cor"), pega("legenda_borda_espessura_pt"),
                                                         pega("legenda_borda_tipo")), is.null, NA)))
    cfg$legenda$moldura <- TRUE
  if (is.null(pega("legenda_sombra")) && any(!vapply(list(pega("legenda_sombra_cor"), pega("legenda_sombra_opacidade"),
                                                          pega("legenda_sombra_deslocamento_pt")), is.null, NA)))
    cfg$legenda$sombra <- TRUE
  rd <- pega("rotulos_dados_tamanho_pt")   # texto escrito junto dos pontos/barras (rótulos de dados)
  if (!is.null(rd)) { cfg$linhas$rotulos_tamanho_pt <- rd; cfg$barras$rotulos_tamanho_pt <- rd; marca("rotulos_dados_tamanho_pt") }
  # eixo Y da direita (Y2): as séries listadas em y2_series passam para ele; o X continua o mesmo
  y2s <- pega("y2_series")
  y2f <- pega("y2_fator"); y2d <- pega("y2_deslocamento")
  y2_dadas <- Filter(function(n) !is.null(pega(n)), .Y2_VARIAVEIS)
  ja_ativo <- isTRUE(cfg$eixo_y2$ativo)            # Y2 ligado antes (cfg$eixo_y2$ativo <- TRUE ou aplicar_painel anterior)
  if (!is.null(y2s) || !is.null(y2f) || !is.null(y2d) || (ja_ativo && length(y2_dadas))) {
    cfg$eixo_y2$ativo <- TRUE
    if (!is.null(y2s)) {
      for (nm in y2s) cfg$series[[nm]] <- utils::modifyList(cfg$series[[nm]] %||% list(), list(eixo = "y2"))
      marca("y2_series")
    } else if (!is.null(y2f) || !is.null(y2d)) cfg$eixo_y2$modo <- "transformado"   # o mesmo dado em outra unidade
    # séries do Y2: as de y2_series ou, se o Y2 já estava ligado, as que já têm eixo = "y2" no cfg
    y2s <- y2s %||% names(Filter(function(x) identical(x$eixo, "y2"), cfg$series))
    if (!is.null(y2f)) { cfg$eixo_y2$fator <- y2f; marca("y2_fator") }
    if (!is.null(y2d)) { cfg$eixo_y2$deslocamento <- y2d; marca("y2_deslocamento") }
    for (nome in c("y2_titulo", "y2_inicio", "y2_fim", "y2_ticks_menores", "y2_casas_decimais", "y2_notacao",
                   "y2_prefixo", "y2_sufixo", "y2_dividir_por", "y2_cor_eixo", "y2_ticks_manuais")) {
      v <- pega(nome); if (is.null(v)) next
      alvo <- switch(nome, y2_titulo = "titulo", y2_inicio = "inicio", y2_fim = "fim", y2_ticks_menores = "n_menores",
                     y2_casas_decimais = "casas_decimais", y2_notacao = "notacao", y2_prefixo = "prefixo",
                     y2_sufixo = "sufixo", y2_dividir_por = "fator_divisao", y2_cor_eixo = "cor_eixo",
                     y2_ticks_manuais = "ticks_manuais")
      cfg$eixo_y2[[alvo]] <- v
      if (nome == "y2_ticks_manuais") cfg$eixo_y2$ticks_modo <- "manual"
      marca(nome)
    }
    iv2 <- pega("y2_intervalo")
    if (!is.null(iv2)) { cfg$eixo_y2$ticks_modo <- "incremento"; cfg$eixo_y2$incremento <- iv2; marca("y2_intervalo") }
    cor2 <- pega("y2_cor")    # uma cor para as séries do Y2 e para o eixo
    if (!is.null(cor2)) {
      for (nm in y2s) cfg$series[[nm]] <- utils::modifyList(cfg$series[[nm]] %||% list(), list(cor = cor2))
      cfg$eixo_y2$cor_eixo <- cor2; marca("y2_cor")
    }
    suf <- pega("y2_legenda_sufixo")    # legenda única: avisa em qual eixo cada série do Y2 está lendo
    if (!is.null(suf)) {
      for (nm in y2s) {
        s2 <- cfg$series[[nm]] %||% list()
        atual <- s2$nome_legenda %||% nm
        if (endsWith(atual, suf)) next                # aplicar_painel() de novo no mesmo cfg não soma outra vez
        cfg$series[[nm]] <- utils::modifyList(s2, list(nome_legenda = paste0(atual, suf)))
      }
      marca("y2_legenda_sufixo")
    }
    if (isTRUE(pega("y2_igual_y1"))) {   # números, título e ticks do Y2 no mesmo estilo do Y1 (cor e título)
      cfg$eixo_y2$cor_eixo <- cfg$eixo_y$cor_rotulos %||% cfg$texto$cor
      if (is.null(pega("y2_titulo")) && !is.null(cfg$eixo_y$titulo)) cfg$eixo_y2$titulo <- cfg$eixo_y$titulo
      marca("y2_igual_y1")
    }
  }
  else if (length(y2_dadas))
    .aviso("O painel tem ", paste(y2_dadas, collapse = ", "),
           " preenchido(s), mas o eixo direito (Y2) não está ativo — ",
           "ajuste ignorado. Preencha y2_series (ex.: y2_series <- \"Temperatura\") para ligar o Y2.")
  neg <- pega("eixos_titulo_negrito")
  if (!is.null(neg)) { cfg$eixo_x$negrito_titulo <- isTRUE(neg); cfg$eixo_y$negrito_titulo <- isTRUE(neg); marca("eixos_titulo_negrito") }
  # cores: gradiente, paleta personalizada (vence a paleta nomeada) e cor de séries específicas
  if (isTRUE(pega("cores_gradiente"))) { cfg$cores$preenchimento <- "gradiente"; marca("cores_gradiente") }
  pers <- pega("cores_personalizadas")
  if (!is.null(pers)) { cfg$cores$paleta <- "personalizada"; cfg$cores$personalizada <- pers; marca("cores_personalizadas") }
  por_serie <- pega("cores_por_serie")
  if (!is.null(por_serie)) {
    if (is.null(names(por_serie)) || any(!nzchar(names(por_serie))))
      .erro("cores_por_serie precisa de nomes: c(\"WORLD\" = \"#000000\", \"BRAZIL\" = \"#1F4E9E\").")
    for (nm in names(por_serie))
      cfg$series[[nm]] <- utils::modifyList(cfg$series[[nm]] %||% list(), list(cor = por_serie[[nm]]))
    marca("cores_por_serie")
  }
  # uma forma só para todas as séries: basta dar simbolo_forma (a troca automática de formas é desligada)
  if (!is.null(pega("simbolo_forma")) && is.null(pega("simbolo_variar")) && is.null(pega("simbolos_ordem")))
    cfg$cores$incrementar_simbolo <- FALSE
  if (!is.null(pega("simbolo_forma"))) .simbolo_codigo(pega("simbolo_forma"), "simbolo_forma")   # valida o nome
  # grossura da linha / tamanho do ponto / contorno do ponto de séries específicas (vencem o valor geral)
  for (nome in c("linha_espessura_por_serie", "simbolo_tamanho_por_serie", "simbolo_borda_por_serie",
                 "simbolo_forma_por_serie")) {
    v <- pega(nome)
    if (is.null(v)) next
    forma <- nome == "simbolo_forma_por_serie"          # este recebe o nome da forma (texto) ou o número
    if (is.null(names(v)) || any(!nzchar(names(v))) || (!forma && !is.numeric(v)))
      .erro(nome,
            if (forma) " precisa do nome da série e da forma: c(\"WORLD\" = \"esfera\", \"BRAZIL\" = \"quadrado\")."
                  else " precisa de números com o nome da série: c(\"WORLD\" = 1, \"BRAZIL\" = 3).")
    if (forma) for (k in seq_along(v)) .simbolo_codigo(v[[k]], paste0(nome, "[\"", names(v)[k], "\"]"))
    chave <- switch(nome, linha_espessura_por_serie = "linha_espessura_pt",
                    simbolo_tamanho_por_serie = "tamanho_simbolo_pt",
                    simbolo_borda_por_serie = "espessura_borda_pt", simbolo_forma_por_serie = "simbolo")
    for (nm in names(v)) {
      novo <- list(v[[nm]]); names(novo) <- chave
      cfg$series[[nm]] <- utils::modifyList(cfg$series[[nm]] %||% list(), novo)
    }
    marca(nome)
  }
  # quebra: ligada por quebra_ativar; sem de/ate, procura o maior vazio entre os dados
  qa <- pega("quebra_ativar")
  if (!is.null(qa)) {
    cfg$quebra$ativo <- isTRUE(qa); marca("quebra_ativar")
    if (isTRUE(qa) && (is.null(cfg$quebra$de) || is.null(cfg$quebra$ate)) && !is.null(dados)) {
      s <- sugerir_quebra(dados, cfg)
      cfg$quebra$de <- s$de; cfg$quebra$ate <- s$ate
    }
  }
  if (length(aplicados)) message("Painel de ajustes aplicado: ", paste(aplicados, collapse = ", "))
  else message("Painel de ajustes: nenhum ajuste ativo (tudo NULL = padrão do template).")
  cfg
}

# -----------------------------------------------------------------------------
#  19_marcadores.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/19_marcadores.R — formas dos símbolos (nomes) e o símbolo "esfera" (bolinha com profundidade)
# =============================================================================

# Formas pelo nome (o número do R, de 0 a 25, continua valendo). "esfera" é o símbolo com volume (veja abaixo).
.SIMBOLOS_NOME <- c(circulo = 21, quadrado = 22, losango = 23, triangulo = 24, triangulo_invertido = 25,
                    circulo_vazio = 1, quadrado_vazio = 0, triangulo_vazio = 2, losango_vazio = 5,
                    triangulo_invertido_vazio = 6, cruz = 3, x = 4, estrela = 8, esfera = 99)
.COD_ESFERA <- 99

# Entra: nome ("quadrado") ou número (22). Sai: o código numérico. Erro claro se não existir.
.simbolo_codigo <- function(x, onde = "simbolo") {
  if (is.numeric(x)) return(x)
  if (length(x) != 1 || !x %in% names(.SIMBOLOS_NOME))
    .erro(onde, " = '", paste(x, collapse = ","), "' não é um símbolo válido. OPÇÕES: um número de 0 a 25 ou ",
          paste0('"', names(.SIMBOLOS_NOME), '"', collapse = " | "))
  unname(.SIMBOLOS_NOME[x])
}

# Escurece (f < 0) ou clareia (f > 0) uma cor. f entre -1 e 1.
.tom <- function(cor, f) {
  m <- grDevices::col2rgb(cor) / 255
  m <- if (f >= 0) m + (1 - m) * f else m * (1 + f)
  grDevices::rgb(m[1, ], m[2, ], m[3, ])
}

# Desenha esferas: círculos concentrados na direção da luz, do tom escuro (borda) ao claro (miolo), e um brilho.
# x, y: posições (unit); r_pt: raio em pt (vetor); cores: vetor; luz: c(x, y) de -1 a 1 (direção do brilho).
.grob_esferas <- function(x, y, r_pt, cores, luz = c(-0.35, -0.45), passos = 18) {
  n <- length(x)
  cores <- rep_len(cores, n); r_pt <- rep_len(r_pt, n)
  norma <- sqrt(sum(luz^2)); luz <- if (norma > 0) luz / norma else c(-0.6, -0.8)   # só a direção importa
  unicas <- unique(cores)                                # uma rampa de tons por cor (não por ponto)
  rampas <- lapply(unicas, function(cr) grDevices::colorRampPalette(c(.tom(cr, -0.45), cr, .tom(cr, 0.55)))(21))
  idx <- match(cores, unicas)
  filhos <- list()
  for (k in seq_len(passos)) {
    t <- (k - 1) / (passos - 1)                         # 0 = borda ... 1 = miolo claro
    raio <- r_pt * (1 - 0.82 * t)
    desloc <- (r_pt - raio) * 0.85                       # o miolo se afasta do centro, rumo à luz
    j <- 1 + round(t^1.15 * 20)
    col_k <- vapply(idx, function(i) rampas[[i]][j], "")
    filhos[[k]] <- grid::circleGrob(x = x + grid::unit(luz[1] * desloc, "pt"),
                                    y = y + grid::unit(luz[2] * desloc, "pt"),
                                    r = grid::unit(raio, "pt"), gp = grid::gpar(fill = col_k, col = NA))
  }
  brilho <- c(0.36, 0.25, 0.14)                          # brilho: 3 círculos brancos pequenos e translúcidos
  for (j in seq_along(brilho)) {
    filhos[[length(filhos) + 1]] <- grid::circleGrob(
      x = x + grid::unit(luz[1] * r_pt * 0.5, "pt"), y = y + grid::unit(luz[2] * r_pt * 0.5, "pt"),
      r = grid::unit(r_pt * brilho[j], "pt"), gp = grid::gpar(fill = grDevices::rgb(1, 1, 1, c(0.18, 0.32, 0.6)[j]),
                                                              col = NA))
  }
  do.call(grid::grobTree, filhos)
}

# Raio (pt) de um símbolo do ggplot (círculo 21): o mesmo cálculo do R base.
.raio_simbolo_pt <- function(size, stroke) 0.375 * (size * ggplot2::.pt + stroke * ggplot2::.stroke / 2)

# Chave da legenda da esfera: só desenha se a série for esfera (shape = 99).
.draw_key_esfera <- function(data, params, size) {
  if (!isTRUE(all(data$shape == .COD_ESFERA))) return(grid::nullGrob())
  .grob_esferas(grid::unit(0.5, "npc"), grid::unit(0.5, "npc"), .raio_simbolo_pt(data$size, data$stroke %||% 0.5),
                data$colour, luz = params$luz %||% c(-0.35, -0.45))
}

# Chave comum de ponto que não desenha as séries que são esfera (senão o R desenharia o caractere 99).
.draw_key_ponto_ou_nada <- function(data, params, size) {
  if (isTRUE(all(data$shape == .COD_ESFERA))) return(grid::nullGrob())
  ggplot2::draw_key_point(data, params, size)
}

.GeomEsfera <- ggplot2::ggproto("GeomEsfera", ggplot2::Geom,
  required_aes = c("x", "y"),
  default_aes = ggplot2::aes(colour = "black", size = 2, stroke = 0.5, shape = 99, alpha = NA, fill = NA),
  draw_key = .draw_key_esfera,
  extra_params = c("na.rm", "luz"),
  draw_panel = function(data, panel_params, coord, luz = c(-0.35, -0.45), na.rm = FALSE) {
    if (!nrow(data)) return(grid::nullGrob())
    co <- coord$transform(data, panel_params)
    .grob_esferas(grid::unit(co$x, "npc"), grid::unit(co$y, "npc"), .raio_simbolo_pt(co$size, co$stroke),
                  co$colour, luz = luz)
  })

geom_esfera <- function(mapping = NULL, data = NULL, luz = c(-0.35, -0.45), show.legend = NA, na.rm = TRUE, ...) {
  ggplot2::layer(geom = .GeomEsfera, stat = "identity", position = "identity", data = data, mapping = mapping,
                 show.legend = show.legend, inherit.aes = FALSE, params = list(na.rm = na.rm, luz = luz, ...))
}

# -----------------------------------------------------------------------------
#  20_legenda_ajuste.R
# -----------------------------------------------------------------------------
# =============================================================================
#  R/20_legenda_ajuste.R — garante que a legenda "dentro" caiba na caixa do gráfico
# =============================================================================

# Tamanho da página em polegadas (o do cfg$exportacao) e o do painel (a caixa) em pt, se for fixo.
.tamanho_pagina_in <- function(cfg) {
  ex <- cfg$exportacao
  f <- switch(ex$unidade %||% "cm", cm = 1 / 2.54, mm = 1 / 25.4, `in` = 1)
  c(ex$largura * f, ex$altura * f)
}

# Mede o gráfico como será desenhado (mesmo dispositivo e fontes do arquivo final).
# Entra: g (ggplot), tamanho da página em polegadas. Sai: list(painel = c(larg, alt) em pt, legenda = c(larg, alt) em pt)
# ou NULL se não houver legenda "dentro" medível.
.medir_legenda <- function(g, tam_in) {
  dev_ant <- grDevices::dev.cur()
  if (.tem("ragg")) ragg::agg_capture(width = tam_in[1], height = tam_in[2], units = "in", res = 72)
  else grDevices::pdf(NULL, width = tam_in[1], height = tam_in[2])
  dev_nosso <- grDevices::dev.cur()
  on.exit({ if (dev_nosso %in% grDevices::dev.list()) grDevices::dev.off(dev_nosso)
            if (dev_ant %in% grDevices::dev.list()) grDevices::dev.set(dev_ant) }, add = TRUE)
  gt <- tryCatch(ggplot2::ggplotGrob(g), error = function(e) NULL)
  if (is.null(gt)) return(NULL)
  k <- which(gt$layout$name == "guide-box-inside")
  if (!length(k)) return(NULL)
  lg <- gt$grobs[[k[1]]]
  if (inherits(lg, "zeroGrob")) return(NULL)
  mede <- function(u, total) {                  # soma das partes absolutas; o que sobra é do painel
    nulas <- grid::unitType(u) == "null"
    abs_pt <- if (any(!nulas)) sum(grid::convertUnit(u[!nulas], "pt", valueOnly = TRUE)) else 0
    max(total * 72 - abs_pt, 1)
  }
  list(painel = c(mede(gt$widths, tam_in[1]), mede(gt$heights, tam_in[2])),
       legenda = c(grid::convertWidth(grid::grobWidth(lg), "pt", valueOnly = TRUE),
                   grid::convertHeight(grid::grobHeight(lg), "pt", valueOnly = TRUE)))
}

# Se a legenda "dentro" for maior que a caixa do gráfico, reduz (escala) até caber. Entra: g e cfg. Sai: g.
.ajustar_legenda <- function(g, cfg) {
  lg <- cfg$legenda
  if (!identical(lg$posicao, "dentro") || !isTRUE(lg$ajustar_caixa %||% TRUE)) return(g)
  esc0 <- lg$escala %||% 1; esc <- esc0
  fr <- cfg$.interno$fracao_altura %||% 1       # quebra de eixo: a legenda mora só na parte de cima
  fixo <- c(cfg$caixa$painel_largura_cm, cfg$caixa$painel_altura_cm)
  for (it in 1:3) {
    m <- tryCatch(.medir_legenda(g, .tamanho_pagina_in(cfg)), error = function(e) NULL)
    if (is.null(m)) break
    painel <- m$painel
    if (length(fixo) == 2) painel <- fixo * 72 / 2.54          # caixa de tamanho fixo: as medidas são exatas
    d <- if (is.null(lg$distancia_pt)) c(0, 0) else rep_len(lg$distancia_pt, 2)
    f <- min(1, (painel[1] * 0.97 - d[1]) / m$legenda[1], (painel[2] * fr * 0.95 - d[2]) / m$legenda[2])
    if (!is.finite(f) || f >= 0.995) break
    esc <- esc * max(f * 0.99, 0.2)
    c2 <- cfg; c2$legenda$escala <- esc
    g <- g + .tema_legenda(c2, .fonte(cfg$texto$fonte))
  }
  if (esc < esc0 * 0.995)
    message("Legenda reduzida para ", round(100 * esc / esc0), "% para caber dentro da caixa ",
            "(cfg$legenda$ajustar_caixa <- FALSE desliga; legenda$escala, ou menos séries/colunas, também ajudam).")
  g
}

# -----------------------------------------------------------------------------
#  04_catalogo.R — ajuda(), galeria(), mostrar_paletas()
# -----------------------------------------------------------------------------
# =============================================================================
#  04_catalogo.R — "LEGENDA DE POSSIBILIDADES"
# =============================================================================
#  ajuda()                 lista os blocos do cfg e para que servem
#  ajuda("eixo_x")         mostra TODOS os parâmetros do bloco, com OPÇÕES e EX.
#  ajuda("tipos")          resumo dos tipos de gráfico e o que cada um usa
#  mostrar_paletas()       desenha as paletas disponíveis
#  galeria()               gera saida/galeria_referencia.pdf (símbolos, linhas,
#                          paletas, ticks, gradientes e um exemplo de cada tipo)
#  O texto de ajuda é lido diretamente da PARTE 1 deste script: o que você vê aqui é
#  exatamente o que está documentado lá.
# =============================================================================

.APELIDOS <- c(x = "eixo_x", y = "eixo_y", y2 = "eixo_y2", eixo = "eixo_x", eixos = "eixo_x",
               pontos = "linhas", linha = "linhas", linha_pontos = "linhas", area = "linhas",
               erro = "linhas", erros = "linhas", histograma = "distribuicao", densidade = "distribuicao",
               ecdf = "distribuicao", violino = "boxplot", box = "boxplot", rosca = "pizza",
               cor = "cores", gradiente = "cores", paleta = "cores", serie = "series",
               simbolo = "serie_padrao", simbolos = "serie_padrao", moldura = "caixa", ticks = "eixo_x",
               fonte = "texto", painel = "paineis", empilhar = "paineis", exportar = "exportacao",
               salvar = "exportacao", grid = "grade", titulo = "titulos", referencia = "referencias",
               tempo = "eixo_x", data = "eixo_x", datas = "eixo_x", ordenar_x = "linhas")

ajuda <- function(bloco = NULL) {
  L <- .config_linhas()
  ini <- grep("^cfg\\$[a-z_0-9]+ <- ", L)
  nomes <- sub("^cfg\\$([a-z_0-9]+) <- .*", "\\1", L[ini])
  tracos <- grep("^# -{20,}", L)
  cab <- function(i) { t <- tracos[tracos < ini[i]]; if (length(t) >= 2) t[length(t) - 1] else ini[i] }
  if (is.null(bloco)) {
    cat("\nBLOCOS DO cfg (use ajuda(\"nome\") para ver os parâmetros):\n\n")
    for (i in seq_along(ini)) {
      t <- tracos[tracos < ini[i]]
      tit <- if (length(t)) sub("^#\\s*", "", L[t[length(t)] - 1]) else nomes[i]
      cat(sprintf("  %-14s %s\n", nomes[i], sub("^[A-Z_0-9]+\\s*[—-]\\s*", "", tit)))
    }
    cat("\nOutros:  ajuda(\"tipos\")   mostrar_paletas()   galeria()   listar_fontes()   listar_estilos()\n\n")
    return(invisible(nomes))
  }
  if (identical(bloco, "tipos")) {
    cat('
TIPOS DE GRÁFICO  (cfg$grafico$tipo)            colunas usadas / bloco de opções
  "pontos"          dispersão                    coluna_x + colunas_y    -> ajuda("linhas")
  "linha"           só linhas                    coluna_x + colunas_y    -> ajuda("linhas")
  "linha_pontos"    linha com símbolos           coluna_x + colunas_y    -> ajuda("linhas")
  "area"            linha com área preenchida    coluna_x + colunas_y    -> ajuda("linhas")
  "area_empilhada"  áreas somadas                coluna_x + colunas_y    -> ajuda("linhas")
  "barras"          colunas/barras               coluna_x (categorias) + colunas_y -> ajuda("barras")
  "pizza"           pizza / rosca                coluna_x (categorias) + 1 coluna_y -> ajuda("pizza")
  "histograma"      histograma (+curvas)         colunas_y ou coluna_grupo -> ajuda("distribuicao")
  "densidade"       curva de densidade           colunas_y ou coluna_grupo -> ajuda("distribuicao")
  "ecdf"            distribuição acumulada       colunas_y ou coluna_grupo -> ajuda("distribuicao")
  "boxplot"         box, violino, meio box, média±erro  colunas_y ou coluna_grupo -> ajuda("boxplot")

RECURSOS QUE VALEM PARA TODOS (exceto pizza): eixo_x, eixo_y, eixo_y2, caixa, grade,
  legenda, titulos, texto, referencias, anotacoes, quebra, paineis, exportacao.
')
    return(invisible())
  }
  b <- if (bloco %in% nomes) bloco else .APELIDOS[bloco]
  if (is.na(b) || !b %in% nomes) {
    sug <- nomes[utils::adist(bloco, nomes) <= 3]
    stop("Bloco '", bloco, "' não existe.", if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "",
         " Use ajuda() para ver a lista.", call. = FALSE)
  }
  i <- match(b, nomes)
  fim <- if (i < length(ini)) cab(i + 1) - 1 else length(L)
  trecho <- L[cab(i):fim]
  while (length(trecho) && !nzchar(trimws(trecho[length(trecho)]))) trecho <- trecho[-length(trecho)]
  cat("\n", paste(trecho, collapse = "\n"), "\n\n", sep = "")
  if (exists("cfg", envir = globalenv())) {
    atual <- get("cfg", envir = globalenv())[[b]]
    cat("# VALORES ATUAIS em cfg$", b, ":\n", sep = "")
    utils::str(atual, give.attr = FALSE, no.list = TRUE, comp.str = "  $ ")
  }
  invisible(trecho)
}

.grafico_paletas <- function(n = 8) {
  nomes <- c("classico", "okabe_ito", "tableau", "viridis", "magma", "plasma", "cividis", "cinza",
             "brewer_Set1", "brewer_Set2", "brewer_Dark2", "brewer_Paired", "brewer_Blues", "brewer_RdBu",
             "personalizada")
  cfg0 <- if (exists("cfg", envir = globalenv())) get("cfg", envir = globalenv())$cores else .cfg_ref$cores
  d <- do.call(rbind, lapply(nomes, function(p) {
    cores <- tryCatch(.paleta(p, n, cfg0), error = function(e) rep("grey90", n))
    data.frame(paleta = p, i = seq_len(n), cor = cores)
  }))
  d$paleta <- factor(d$paleta, levels = rev(nomes))
  g <- ggplot(d, aes(i, paleta)) + geom_tile(aes(fill = I(cor)), colour = "white", linewidth = 0.8) +
    geom_text(aes(label = i), size = 2.6, colour = "white") +
    scale_x_continuous(breaks = NULL, expand = c(0, 0)) +
    labs(x = NULL, y = NULL, title = "Paletas  (cfg$cores$paleta <- \"nome\")") +
    theme_minimal(11) + theme(panel.grid = element_blank(), axis.text.y = element_text(face = "bold"))
  g
}

mostrar_paletas <- function(n = 8) {
  g <- .grafico_paletas(n)
  print(g)
  invisible(g)
}

galeria <- function(arquivo = "saida/galeria_referencia.pdf") {
  if (!dir.exists(dirname(arquivo))) dir.create(dirname(arquivo), recursive = TRUE)
  cfg0 <- .cfg_ref
  pag <- list()
  # 1. símbolos
  s <- data.frame(s = 0:25, x = (0:25) %% 9, y = -((0:25) %/% 9))
  pag[[1]] <- ggplot(s, aes(x, y)) +
    geom_point(aes(shape = I(s)), size = 6, fill = "#4E79A7", colour = "black", stroke = 1) +
    geom_text(aes(label = s), vjust = 2.6, size = 3.5) +
    scale_y_continuous(expand = expansion(add = 0.7)) + scale_x_continuous(expand = expansion(add = 0.6)) +
    labs(title = "Símbolos  —  cfg$serie_padrao$simbolo  ou  cfg$series[[\"nome\"]]$simbolo",
         subtitle = paste("0–14: só contorno | 15–20: sólidos (cor da série) |",
                          "21–25: contorno + preenchimento (preenchimento_simbolo)")) +
    theme_void(12) + theme(plot.margin = margin(20, 20, 20, 20))
  # 2. tipos de linha
  lt <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash", "44", "13", "1343", "73", "2262")
  ld <- data.frame(t = factor(lt, levels = rev(lt)), x = 0, xend = 1)
  pag[[2]] <- ggplot(ld, aes(x = x, xend = xend, y = t, yend = t)) +
    geom_segment(aes(linetype = I(as.character(t))), linewidth = .lw(2)) +
    scale_x_continuous(limits = c(-0.05, 1.05)) +
    labs(title = "Tipos de linha  —  cfg$serie_padrao$linha_tipo",
         subtitle = "Códigos hexadecimais: pares (traço, espaço). Ex.: \"44\", \"1343\"", x = NULL, y = NULL) +
    theme_minimal(12) + theme(panel.grid = element_blank(), axis.text.x = element_blank(),
                              axis.text.y = element_text(face = "bold",
                                                         size = 12), plot.margin = margin(20, 20, 20, 20))
  # 3. paletas
  pag[[3]] <- .grafico_paletas() + theme(plot.margin = margin(20, 20, 20, 20))
  # dados sintéticos para exemplos
  set.seed(1)
  xy <- data.frame(X = 1:10, `Série 1` = cumsum(stats::runif(10, 0, 3)), `Série 2` = cumsum(stats::runif(10, 0, 2)),
                   check.names = FALSE)
  cat_ <- data.frame(Categoria = c("A", "B", "C", "D"), `Grupo 1` = c(5, 8, 3, 6), `Grupo 2` = c(4, 6, 5, 7),
                     check.names = FALSE)
  am <- data.frame(G1 = stats::rnorm(40, 10, 2), G2 = stats::rnorm(40, 13, 2.5), G3 = stats::rnorm(40, 12, 1.5))
  mini <- function(d, mod, tit) {
    c1 <- .mesclar(cfg0, mod); c1$texto$tamanho_base_pt <- 8; c1$legenda$tamanho_chave_pt <- 9
    c1$titulos$titulo <- tit; c1$titulos$tamanho_titulo_pt <- 9
    .plotar_um(d, c1)
  }
  # 4. ticks e gradientes
  tk <- lapply(c("dentro", "fora", "ambos", "nenhum"), function(dd)
    mini(xy, list(grafico = list(tipo = "linha"), legenda = list(mostrar = FALSE),
                  eixo_x = list(direcao_maiores = dd, direcao_menores = dd, n_menores = 1),
                  eixo_y = list(direcao_maiores = dd, direcao_menores = dd, n_menores = 1)),
         paste0("direcao_maiores = \"", dd, "\"")))
  gr <- lapply(c("vertical", "vertical_invertido", "horizontal", "horizontal_invertido", "diagonal", "radial"),
               function(dd)
    mini(cat_, list(grafico = list(tipo = "barras", colunas_y = "Grupo 1"), legenda = list(mostrar = FALSE),
                    cores = list(preenchimento = "gradiente", gradiente_direcao = dd, gradiente_cor2 = "white"),
                    series = list(`Grupo 1` = list(cor = "#1F4E9E"))),
         paste0("gradiente_direcao = \"", dd, "\"")))
  pag[[4]] <- patchwork::wrap_plots(c(tk, gr), ncol = 4) +
    patchwork::plot_annotation(title = "Direção dos ticks (eixo_x/eixo_y) e direção do gradiente (cores)")
  # 5. tipos
  tipos <- list(
    mini(xy, list(grafico = list(tipo = "pontos")), "tipo = \"pontos\""),
    mini(xy, list(grafico = list(tipo = "linha")), "\"linha\""),
    mini(xy, list(grafico = list(tipo = "linha_pontos")), "\"linha_pontos\""),
    mini(xy, list(grafico = list(tipo = "area"), legenda = list(mostrar = FALSE)), "\"area\""),
    mini(xy, list(grafico = list(tipo = "area_empilhada"), cores = list(paleta = "okabe_ito")), "\"area_empilhada\""),
    mini(xy, list(grafico = list(tipo = "linha"), linhas = list(ligacao = "degrau_hv")),
         "linhas$ligacao = \"degrau_hv\""),
    mini(cat_, list(grafico = list(tipo = "barras"), cores = list(paleta = "tableau")), "\"barras\" agrupado"),
    mini(cat_, list(grafico = list(tipo = "barras"), barras = list(arranjo = "empilhado"),
                    cores = list(paleta = "tableau")), "barras empilhado"),
    mini(cat_, list(grafico = list(tipo = "barras"), barras = list(orientacao = "horizontal"),
                    cores = list(paleta = "tableau")), "barras horizontal"),
    mini(cat_, list(grafico = list(tipo = "pizza", colunas_y = "Grupo 1"), cores = list(paleta = "tableau"),
                    pizza = list(explodir = "B", rotulos_tamanho_pt = 7)), "\"pizza\""),
    mini(cat_, list(grafico = list(tipo = "pizza", colunas_y = "Grupo 1"), cores = list(paleta = "tableau"),
                    pizza = list(raio_furo = 0.5, rotulos_tamanho_pt = 7)), "pizza raio_furo = 0.5"),
    mini(am, list(grafico = list(tipo = "histograma", colunas_y = "G1"), distribuicao = list(curva_normal = TRUE),
                  legenda = list(mostrar = FALSE)), "\"histograma\""),
    mini(am, list(grafico = list(tipo = "densidade"), cores = list(paleta = "viridis")), "\"densidade\""),
    mini(am, list(grafico = list(tipo = "ecdf"), cores = list(paleta = "okabe_ito")), "\"ecdf\""),
    mini(am, list(grafico = list(tipo = "boxplot"), cores = list(paleta = "tableau")), "boxplot \"box\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "box_pontos"),
                  cores = list(paleta = "tableau")), "\"box_pontos\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "meio_box"),
                  cores = list(paleta = "tableau")), "\"meio_box\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "violino_box"),
                  cores = list(paleta = "tableau")), "\"violino_box\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "violino"),
                  cores = list(paleta = "tableau")), "\"violino\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "media_erro"),
                  cores = list(paleta = "tableau")), "\"media_erro\"")
  )
  pag[[5]] <- patchwork::wrap_plots(lapply(tipos, function(g) patchwork::wrap_elements(full = g)), ncol = 4) +
    patchwork::plot_annotation(
      title = "Tipos e variações (cfg$grafico$tipo, cfg$boxplot$variacao, cfg$barras$arranjo ...)")
  dev <- if (capabilities("cairo")) grDevices::cairo_pdf else grDevices::pdf
  dev(arquivo, width = 11.7, height = 8.3, onefile = TRUE)
  for (p in pag) print(p)
  grDevices::dev.off()
  message("Galeria salva em ", arquivo)
  invisible(arquivo)
}

# #############################################################################
#  PARTE 3 — COMO USAR
# #############################################################################

# Exemplos rápidos com dados fictícios (para testar a instalação e ver o resultado).
# Os arquivos vão para a pasta saida/demonstracao/ dentro da sua pasta de trabalho.
demonstracao <- function(tipo = c("linha", "barras", "pizza", "boxplot", "datas")) {
  tipo <- match.arg(tipo)
  cfg <- .CFG_PADRAO
  cfg$exportacao$pasta <- "saida/demonstracao"; cfg$exportacao$formatos <- c("png", "pdf")
  cfg$exportacao$dpi <- 200; cfg$exportacao$nome_arquivo <- paste0("demo_", tipo)
  dados <- switch(tipo,
    linha = {
      t <- seq(0, 60, by = 5)
      cfg$grafico$tipo <- "linha_pontos"; cfg$eixo_x$titulo <- "Tempo (min)"; cfg$eixo_y$titulo <- "Temperatura (°C)"
      cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 10
      cfg$caixa$fechada <- TRUE; cfg$caixa$ticks_espelhados <- TRUE; cfg$legenda$posicao <- "dentro"
      cfg$legenda$dentro_x <- 0.04; cfg$legenda$dentro_y <- 0.96
      data.frame(`Tempo (min)` = t, `Amostra A` = 20 + 0.9 * t - 0.004 * t^2,
                 `Amostra B` = 20 + 0.55 * t, `Amostra C` = 20 + 0.3 * t + 3 * sin(t / 8), check.names = FALSE)
    },
    barras = {
      cfg$grafico$tipo <- "barras"; cfg$eixo_y$titulo <- "Resistência (MPa)"; cfg$eixo_x$titulo <- ""
      cfg$eixo_y$inicio <- 0; cfg$barras$rotulos_valor <- TRUE; cfg$barras$rotulos_casas <- 0
      cfg$cores$preenchimento <- "gradiente"; cfg$legenda$posicao <- "dentro"
      data.frame(Material = c("Aço", "Alumínio", "Cobre", "Titânio", "Polímero"),
                 `Ensaio 1` = c(420, 270, 220, 880, 65), `Ensaio 2` = c(405, 262, 231, 861, 58), check.names = FALSE)
    },
    pizza = {
      cfg$grafico$tipo <- "pizza"; cfg$pizza$raio_furo <- 0.45; cfg$pizza$rotulos <- c("categoria", "percentual")
      cfg$pizza$rotulos_separador <- "\n"; cfg$titulos$titulo <- "Composição da liga (% massa)"
      data.frame(Elemento = c("Ferro", "Carbono", "Cromo", "Níquel", "Manganês", "Silício", "Vanádio"),
                 Massa = c(70, 12, 6, 5, 3, 2.2, 1.8))
    },
    boxplot = {
      set.seed(42)
      cfg$grafico$tipo <- "boxplot"; cfg$boxplot$variacao <- "box_pontos"; cfg$eixo_y$titulo <- "Resposta (u.a.)"
      data.frame(Controle = round(rnorm(20, 50, 5), 1), `Dose 1` = round(rnorm(20, 57, 6), 1),
                 `Dose 2` = round(rnorm(20, 65, 8), 1), check.names = FALSE)
    },
    datas = {
      cfg$grafico$tipo <- "linha_pontos"; cfg$eixo_x$titulo <- "Data da coleta"; cfg$eixo_y$titulo <- "Temperatura (°C)"
      cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- "2 semanas"; cfg$eixo_x$formato_rotulo_data <- "%d/%m"
      cfg$legenda$mostrar <- FALSE                 # só há uma série: dispensa a legenda
      d <- as.Date("2024-03-01") + seq(0, 77, by = 7)
      data.frame(`Data` = format(d, "%d/%m/%Y"), `Temperatura (°C)` = round(22 + 3 * sin(seq(0, 6, length.out = length(d))), 1),
                 check.names = FALSE)
    })
  g <- plotar(dados, cfg)
  visualizar(g, cfg)
  salvar(g, cfg)
  invisible(g)
}

# -----------------------------------------------------------------------------
#  PAINEL DE AJUSTES (arquivo painel_de_ajustes.R do projeto)
# -----------------------------------------------------------------------------
# =============================================================================
#  PAINEL DE AJUSTES DO GRÁFICO  (edite só este bloco)
# =============================================================================
#  Como usar: preencha ARQUIVO_CSV, mude o que quiser e clique em Source (Ctrl+Shift+S).
#  NULL = "não mexer" (vale o padrão do template). Para voltar ao padrão, escreva NULL.
#  Textos entre aspas; números sem aspas e com PONTO decimal; TRUE/FALSE em maiúsculas.
#  Categorias:  1 ARQUIVO E TIPO | 2 INTERVALOS | 3 ESCALA | 4 NÚMEROS E TÍTULOS | 5 GRADE |
#               6 QUEBRA DO EIXO Y | 7 EIXO Y DA DIREITA | 8 CORES E LINHAS | 9 FONTE | 10 MOLDURA |
#               11 LEGENDA (posição, fundo, borda, sombra) | 12 EXPORTAÇÃO
#  Quer um ajuste que não está aqui? Use o cfg direto (ajuda("eixo_x"), ajuda("grade")...).
# =============================================================================

# ---- 1. ARQUIVO E TIPO DE GRÁFICO -----------------------------------------------------------
ARQUIVO_CSV <- ""        # caminho do CSV. EX.: "C:/pasta/dados.csv". Vazio = só carrega o template.
tipo_grafico <- NULL     # "pontos" | "linha" | "linha_pontos" | "area" | "barras" | "pizza" | "boxplot"...
coluna_x     <- NULL     # coluna do eixo X: número ou "nome". EX.: 1  |  "Years"
colunas_y    <- NULL     # colunas Y. NULL = todas as outras numéricas. EX.: c(2, 3)  |  c("WORLD", "LATAM")

# ---- 2. INTERVALOS DOS EIXOS (início, fim, passo e grossura dos traços) -------------------------
#  Eixo X
x_inicio    <- NULL      # começo do eixo X.  EX.: 2015
x_fim       <- NULL      # fim do eixo X.     EX.: 2026
x_intervalo <- NULL      # distância entre os traços: 1 = de 1 em 1 | 2 = de 2 em 2 | 5 | "1 mes" (datas)
x_primeiro_tick <- NULL  # de onde começa a contar. EX.: 2016 (com x_intervalo 2: 2016, 2018, 2020...)
x_ticks_manuais <- NULL  # posições escolhidas à mão (ignora x_intervalo). EX.: c(2015, 2020, 2026)
x_ticks_menores <- NULL  # traços pequenos entre dois grandes. 0 = SEM traços pequenos. EX.: 0
x_ticks_espessura_pt <- NULL   # GROSSURA dos traços do eixo X, em pt. EX.: 1.5   (vale para grandes e pequenos)
x_ticks_comprimento_pt <- NULL # comprimento dos traços grandes, em pt. EX.: 6
x_ticks_menores_comprimento_pt <- NULL   # comprimento dos traços pequenos. EX.: 3
x_ticks_direcao <- NULL  # "dentro" | "fora" | "ambos" (cruzando o eixo) | "nenhum"
x_ticks_menores_direcao <- NULL
x_ticks_cor     <- NULL  # EX.: "black"
x_linha_espessura_pt <- NULL   # grossura da linha do eixo X (quando a moldura não é fechada). EX.: 1.5
#  Eixo Y
y_inicio    <- NULL      # EX.: 0
y_fim       <- NULL      # EX.: 700000
y_intervalo <- NULL      # EX.: 100000 (de 100000 em 100000)
y_primeiro_tick <- NULL
y_ticks_manuais <- NULL  # EX.: c(0, 1000, 5000, 10000)
y_ticks_menores <- NULL  # EX.: 0
y_ticks_espessura_pt <- NULL   # grossura dos traços do eixo Y. EX.: 1.5
y_ticks_comprimento_pt <- NULL
y_ticks_menores_comprimento_pt <- NULL
y_ticks_direcao <- NULL
y_ticks_menores_direcao <- NULL
y_ticks_cor     <- NULL
y_linha_espessura_pt <- NULL
#  Moldura (a caixa em volta do gráfico)
ticks_espelhados     <- NULL   # TRUE = repete os traços no topo e à direita (moldura fechada)
moldura_espessura_pt <- NULL   # grossura da moldura, em pt. EX.: 1.5
moldura_cor          <- NULL   # EX.: "black"
#  (a grossura das linhas da GRADE está no bloco 5)

# ---- 3. ESCALA (tipo, inversão e folga nas pontas) ------------------------------------------------
x_folga_pct <- NULL      # espaço extra nas pontas, em % do eixo. Evita o 1º/último ponto cortado. EX.: 4
x_escala    <- NULL      # "linear" | "log10" | "ln" | "log2" | "reciproco" | "raiz"
x_inverter  <- NULL      # TRUE = maior valor à esquerda
y_folga_pct <- NULL      # EX.: 3
y_escala    <- NULL      # EX.: "log10"
y_inverter  <- NULL
recortar_nos_limites <- NULL   # FALSE = pontos nas pontas aparecem INTEIROS (não são cortados pela moldura)

# ---- 4. NÚMEROS E TÍTULOS ---------------------------------------------------------------------
x_titulo         <- NULL   # EX.: "Anos"   (expoente: "Área (m^{2})"; índice: "CO_{2}")
y_titulo         <- NULL   # EX.: "Receita (US$ ×10^{3})"
titulo_grafico   <- NULL   # título no topo da figura. EX.: "Evolução 2015-2026"
titulo_grafico_negrito <- NULL   # TRUE | FALSE
eixos_titulo_negrito   <- NULL   # TRUE = títulos dos eixos X e Y em negrito
x_dividir_por    <- NULL   # divide os números do eixo. EX.: 1000 (100000 vira 100; avise no título)
y_dividir_por    <- NULL
x_casas_decimais <- NULL   # EX.: 0   (NULL = automático)
y_casas_decimais <- NULL
x_notacao        <- NULL   # "normal" | "milhar" | "cientifica" | "potencia10" | "percentual"
y_notacao        <- NULL
x_rotacao_numeros <- NULL  # graus. EX.: 45
y_rotacao_numeros <- NULL
x_mostrar_numeros <- NULL  # FALSE = esconde os números do eixo
y_mostrar_numeros <- NULL
#  Distâncias (pt): quanto afastar o título dos números e os números do eixo
x_distancia_titulo_pt  <- NULL   # título do X até os números. EX.: 6
y_distancia_titulo_pt  <- NULL   # título do Y até os números (com quebra de eixo vale também). EX.: 6
x_distancia_numeros_pt <- NULL   # números do X até o eixo. EX.: 3
y_distancia_numeros_pt <- NULL

# ---- 5. GRADE (linhas de fundo) ---------------------------------------------------------------
grade_x          <- NULL   # TRUE = linhas verticais nos ticks maiores do X
grade_y          <- NULL   # TRUE = linhas horizontais nos ticks maiores do Y
grade_cor        <- NULL   # EX.: "grey60" | "#1F4E9E"
grade_tipo       <- NULL   # "solid" | "dashed" (tracejada) | "dotted" (pontilhada) | "dotdash" | "longdash"
grade_espessura_pt <- NULL # EX.: 0.5
grade_opacidade  <- NULL   # 0 (invisível) a 1 (cor cheia). EX.: 0.4
grade_menor_x    <- NULL   # grade dos ticks MENORES (normalmente FALSE)
grade_menor_y    <- NULL
grade_menor_cor  <- NULL
grade_menor_tipo <- NULL
grade_menor_espessura_pt <- NULL
grade_menor_opacidade    <- NULL

# ---- 6. QUEBRA DO EIXO Y (intervalo grande entre os dados) -------------------------------------
quebra_ativar    <- NULL   # TRUE liga. Sem quebra_de/quebra_ate, o script ACHA o maior vazio entre os dados
quebra_estilo    <- NULL   # "separado" (dois gráficos com espaço) | "continuo" (uma moldura só, estilo Origin)
quebra_de        <- NULL   # início do trecho omitido. EX.: 5000
quebra_ate       <- NULL   # fim do trecho omitido.    EX.: 80000
quebra_espaco_pt <- NULL   # espaço entre as duas partes (aumente se os números se sobrepuserem). EX.: 14
quebra_y2_de     <- NULL   # trecho omitido do eixo DIREITO (valores do Y2). NULL = acompanha o do esquerdo. EX.: 2000
quebra_y2_ate    <- NULL   # EX.: 6000
quebra_y_intervalo_inferior <- NULL   # intervalo entre os traços da parte de baixo do eixo esquerdo. EX.: 20
quebra_y_intervalo_superior <- NULL   # ... e da parte de cima (começa no quebra_ate). EX.: 100
quebra_y2_intervalo_inferior <- NULL  # o mesmo para o eixo direito (baixo)
quebra_y2_intervalo_superior <- NULL  # ... (cima)
quebra_ligar_pontos      <- NULL   # FALSE = não liga os pontos através da quebra
quebra_proporcao_superior <- NULL  # altura da parte de cima, de 0 a 1. EX.: 0.5

# ---- 7. EIXO Y DA DIREITA (Y2): outras variáveis com escala, cor e intervalos próprios ---------------
#  O eixo X continua o mesmo. As colunas listadas em y2_series saem do eixo esquerdo e vão para o direito.
y2_series  <- NULL        # colunas no eixo direito. EX.: "Temperatura"  |  c("Temperatura", "Umidade")
y2_titulo  <- NULL        # título do eixo direito. EX.: "Temperatura (°C)"
y2_inicio  <- NULL        # começo do eixo direito. EX.: 0
y2_fim     <- NULL        # fim do eixo direito.    EX.: 40
y2_intervalo <- NULL      # distância entre os traços. EX.: 5 (de 5 em 5)
y2_ticks_manuais <- NULL  # posições à mão (ignora y2_intervalo). EX.: c(0, 10, 25, 40)
y2_ticks_menores <- NULL  # traços pequenos entre dois grandes. 0 = nenhum
y2_cor       <- NULL      # UMA cor para as séries do Y2 E para o eixo (números, título, traços). EX.: "#C00000"
y2_cor_eixo  <- NULL      # só a cor do eixo ("serie" = cor da 1ª série do Y2 | uma cor). Ignorado se y2_cor existir
y2_dividir_por <- NULL    # divide os números do eixo direito. EX.: 1000 (NULL = igual ao do eixo esquerdo)
                          #   Avise a unidade no título. EX.: y2_titulo <- "Pop. (×10^{3})"
y2_igual_y1   <- NULL     # TRUE = números, título e traços do Y2 iguais aos do Y1 (preto, mesmo título se y2_titulo
                          #   estiver vazio). A legenda das séries já é uma só para os dois eixos.
y2_legenda_sufixo <- NULL # texto somado ao nome das séries do Y2 na legenda única. EX.: " (eixo dir.)"
y2_casas_decimais <- NULL # EX.: 1
y2_notacao   <- NULL      # "normal" | "milhar" | "cientifica" | "potencia10" | "percentual"
y2_prefixo   <- NULL      # EX.: "US$ "
y2_sufixo    <- NULL      # EX.: " %"
y2_fator     <- NULL      # SEM séries novas: mostra o MESMO dado em outra unidade (y2 = fator × y + deslocamento).
y2_deslocamento <- NULL   #   EX. de °C para °F:  y2_fator <- 1.8;  y2_deslocamento <- 32
y2_distancia_titulo_pt  <- NULL   # título do Y2 até os números. EX.: 6
y2_distancia_numeros_pt <- NULL   # números do Y2 até o eixo. EX.: 3
#  As cores de cada série (esquerda ou direita) também podem vir de cores_por_serie (bloco 8).

# ---- 8. CORES, LINHAS E SÍMBOLOS ----------------------------------------------------------------
cores_paleta        <- NULL   # "classico" (padrão tipo Origin) | "okabe_ito" | "tableau" | "viridis" | "cinza" |
                              # "brewer_Set1"... (veja mostrar_paletas())
cores_personalizadas <- NULL  # suas cores, na ordem das colunas Y. EX.: c("#000000", "#D62728", "#1F4E9E")
cores_por_serie     <- NULL   # a cor de séries específicas (nome exato da coluna).
                              # EX.: c("WORLD" = "#000000", "LATAM" = "#C00000", "BRAZIL" = "#1F4E9E")
cores_gradiente     <- NULL   # TRUE = barras/áreas com degradê
cores_gradiente_cor2 <- NULL  # cor final do degradê. EX.: "white"
#  Grossuras SEPARADAS (todas em pt; valem para todas as séries):
linha_espessura_pt  <- NULL   # grossura das LINHAS. EX.: 2.5
simbolo_tamanho_pt  <- NULL   # tamanho dos PONTOS (símbolos). EX.: 8
simbolo_borda_pt    <- NULL   # grossura do CONTORNO dos pontos. EX.: 1.2
#  Só de algumas séries (nome exato da coluna; as demais seguem o valor geral acima):
linha_espessura_por_serie <- NULL   # EX.: c("WORLD" = 1, "BRAZIL" = 3.5)
simbolo_tamanho_por_serie <- NULL   # EX.: c("BRAZIL" = 10)
simbolo_borda_por_serie   <- NULL   # EX.: c("BRAZIL" = 1.5)
#  Só linhas, só pontos ou os dois: o "tipo" do bloco 1 ("linha" | "pontos" | "linha_pontos").
#  Formas dos pontos:
simbolo_forma  <- NULL   # UMA forma para todas as séries: "circulo" | "quadrado" | "losango" | "triangulo" |
                         #   "triangulo_invertido" | "estrela" | "cruz" | "x" | "circulo_vazio" | "quadrado_vazio" | "esfera"
                         #   (ou o número do R, 0 a 25). Preencher isto desliga a troca automática de formas.
simbolo_variar <- NULL   # TRUE = cada série com uma forma diferente | FALSE = todas iguais (simbolo_forma, padrão círculo)
simbolos_ordem <- NULL   # com variar: quais formas, em ordem. EX.: c("quadrado", "circulo", "triangulo")
simbolo_forma_por_serie <- NULL  # forma de séries específicas. EX.: c("WORLD" = "esfera", "BRAZIL" = "quadrado")
simbolo_preenchimento <- NULL    # "serie" (cheio) | "branco" | "vazio" | uma cor
esfera_luz     <- NULL   # de onde vem a luz na "esfera", c(x, y) de -1 a 1. EX.: c(-0.4, 0.5) (brilho em cima, à esquerda)

# ---- 9. FONTE -----------------------------------------------------------------------------------
fonte            <- NULL   # EX.: "Arial" | "Times New Roman" | "Calibri"  (nomes instalados: listar_fontes())
fonte_pasta      <- NULL   # pasta com os .ttf da fonte, para usá-la SEM instalar no Windows (quando listar_fontes() não a
                           #   mostra). EX.: "C:/Users/voce/Downloads/Barlow"  com  fonte <- "Barlow"
tamanho_texto_pt <- NULL   # tamanho BASE de todo o texto (os itens abaixo, se preenchidos, têm prioridade). EX.: 12
cor_texto        <- NULL   # EX.: "black"
#  Tamanhos separados, em pt (NULL = usa o tamanho base):
titulo_grafico_tamanho_pt <- NULL   # título no topo da figura. EX.: 16
x_titulo_tamanho_pt  <- NULL        # título do eixo X (ex.: "Years"). EX.: 14
y_titulo_tamanho_pt  <- NULL        # título do eixo Y (ex.: "Dolar"). EX.: 14
x_numeros_tamanho_pt <- NULL        # números do eixo X (os anos). EX.: 10
y_numeros_tamanho_pt <- NULL        # números do eixo Y. EX.: 10
legenda_texto_tamanho_pt  <- NULL   # nomes na legenda (WORLD, LATAM...). EX.: 10
legenda_titulo_tamanho_pt <- NULL   # título da legenda. EX.: 11
rotulos_dados_tamanho_pt  <- NULL   # texto escrito junto dos pontos/barras (rótulos de dados). EX.: 8

# ---- 10. MOLDURA DO GRÁFICO ---------------------------------------------------------------------------
caixa_fechada    <- NULL   # TRUE = moldura nos 4 lados | FALSE = só eixos esquerdo e inferior
painel_largura_cm <- NULL  # TAMANHO FIXO da caixa do gráfico (dentro dos eixos), em cm, igual em todos os gráficos.
painel_altura_cm  <- NULL  #   EX.: 9 e 6.5. Números, títulos e legenda ficam fora; a página se ajusta para caber tudo.

# ---- 11. LEGENDA: POSIÇÃO, FUNDO, BORDA E SOMBRA -------------------------------------------------------
legenda_mostrar  <- NULL   # FALSE = sem legenda
legenda_titulo   <- NULL   # título da legenda. EX.: "Região"
#  Posição
legenda_posicao  <- NULL   # "dentro" (sobre o gráfico) | "direita" | "esquerda" | "topo" | "base" (fora do gráfico)
legenda_canto    <- NULL   # atalho para "dentro": "sup_esq" | "sup_centro" | "sup_dir" | "centro_esq" | "centro" |
                           #   "centro_dir" | "inf_esq" | "inf_centro" | "inf_dir". EX.: "sup_dir"
legenda_x        <- NULL   # posição fina com "dentro", de 0 (esquerda) a 1 (direita). EX.: 0.04
legenda_y        <- NULL   # de 0 (embaixo) a 1 (em cima). EX.: 0.96
legenda_ancora   <- NULL   # qual ponto da caixa fica em (x, y): c(0, 1) = canto sup. esq. | c(1, 1) = sup. dir. ...
legenda_alinhar  <- NULL   # com a legenda FORA: onde ela fica ao longo do lado.
legenda_escala   <- NULL   # aumenta (> 1) ou diminui (< 1) a legenda toda. EX.: 0.8
legenda_distancia_pt <- NULL  # com "dentro": distância até a borda da caixa, em pt. EX.: 8  |  c(10, 6). Use com legenda_canto
legenda_ajustar_caixa <- NULL # TRUE (padrão) = se a legenda for maior que a caixa, é reduzida até caber | FALSE = como pedido
                           #   direita/esquerda: "topo" | "centro" | "base"; topo/base: "esquerda" | "centro" | "direita"
#  Disposição dos itens
legenda_direcao  <- NULL   # "vertical" (um embaixo do outro) | "horizontal" (lado a lado)
legenda_n_colunas <- NULL  # número de colunas. EX.: 2
legenda_inverter_ordem <- NULL  # TRUE = inverte a ordem dos itens
legenda_tamanho_chave_pt <- NULL   # tamanho do quadradinho/linha de cada item. EX.: 18
legenda_espacamento_pt   <- NULL   # espaço entre os itens. EX.: 4
legenda_margem_interna_pt <- NULL  # folga dentro da caixa: c(cima, direita, baixo, esquerda). EX.: c(6, 8, 6, 8)
#  Fundo
legenda_fundo    <- NULL   # cor de fundo da caixa. EX.: "white" | "#F2F2F2" | "transparente"
legenda_fundo_opacidade <- NULL    # 0 (invisível) a 1 (sólido). EX.: 0.8
#  Borda (basta preencher cor, espessura ou tipo para a borda aparecer)
legenda_borda    <- NULL   # TRUE = borda na caixa | FALSE = sem borda
legenda_borda_cor <- NULL  # EX.: "black"
legenda_borda_espessura_pt <- NULL  # EX.: 1
legenda_borda_tipo <- NULL # "solid" | "dashed" | "dotted" | "dotdash" | "longdash" | "twodash"
#  Sombra (basta preencher cor, opacidade ou deslocamento para a sombra aparecer)
legenda_sombra   <- NULL   # TRUE = sombra atrás da caixa (com fundo "transparente" a caixa fica branca)
legenda_sombra_cor <- NULL # EX.: "black" | "grey30"
legenda_sombra_opacidade <- NULL    # 0 a 1. EX.: 0.35
legenda_sombra_deslocamento_pt <- NULL  # c(para a direita, para baixo) em pt. EX.: c(3, 3)  |  c(5, 2)

# ---- 12. EXPORTAÇÃO ------------------------------------------------------------------------------------
largura_cm   <- NULL       # EX.: 14   (com painel_largura_cm preenchido a página se ajusta sozinha e estes valores não valem)
altura_cm    <- NULL       # EX.: 10
ajustar_pagina <- NULL     # com caixa de tamanho fixo: TRUE (padrão) = a página cresce/encolhe para caber tudo |
                           #   FALSE = página sempre largura_cm x altura_cm (a caixa fica centralizada)
dpi          <- NULL       # EX.: 600
formatos     <- NULL       # EX.: c("png", "pdf")   (também "tiff", "svg", "jpeg", "emf")
nome_arquivo <- NULL       # EX.: "minha_figura"
pasta_saida  <- NULL       # EX.: "C:/pasta/figuras"  (padrão: pasta saida/)

# =============================================================================
#  EXECUÇÃO (não precisa editar)
# =============================================================================
if (nzchar(ARQUIVO_CSV)) {
  dados <- ler_csv(ARQUIVO_CSV)
  cfg <- aplicar_painel(cfg, dados = dados)
  g <- plotar(dados, cfg)
  visualizar(g)
  salvar(g, cfg)
} else {
  cfg <- aplicar_painel(cfg)
  message("Preencha ARQUIVO_CSV no painel e rode de novo (Source) para gerar o gráfico.")
}

message("\nTemplate de gráficos carregado. Para um teste rápido rode:  demonstracao()   (ou ajuda())")

