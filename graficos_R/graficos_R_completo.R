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
#  Estrutura:  PARTE 0 instalador | PARTE 1 configuração (cfg) | PARTE 2 motor | PARTE 2B fonte Barlow | PARTE 3 painel
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
    ragg      = "1.5.0",   # PNG/TIFF/JPEG de qualidade; < 1.5 tem bug no gradiente radial
    systemfonts = "1.0.0"  # fontes: Barlow oficial (fontes/Barlow) e todas as instaladas no computador
  )
  opcionais <- c(
    svglite      = "2.1.0",  # SVG editável (Inkscape/Illustrator)
    devEMF       = "4.0",    # EMF para colar no Word/PowerPoint
    viridisLite  = "0.4.0",  # paletas viridis/magma/plasma/cividis
    RColorBrewer = "1.1-3",  # paletas brewer_*
    shiny        = "1.7.0"   # aplicativo no navegador (app_shiny/, abrir_app.bat)
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
  #   OPÇÕES (todas aparecem em mostrar_paletas()):
  #     Estilo Origin ........ "classico" | "origin_basico" | "origin_vivo" | "origin_escuro" | "origin_pastel" |
  #                            "origin_suave" | "origin_pares" | "origin_doce"
  #     Marca ................ "marca"
  #     Acessíveis ........... "okabe_ito" | "tol_brilhante" | "tol_vibrante" | "tol_suave" | "tol_contraste"
  #     Revistas ............. "tableau" | "d3" | "npg" | "lancet" | "jco" | "nejm"
  #     Degradês de uma cor .. "seq_azul" | "seq_verde" | "seq_laranja" | "seq_vermelho" | "seq_roxo" |
  #                            "seq_azul_verde" | "seq_calor" | "seq_frio"
  #     Divergentes .......... "div_vermelho_azul" | "div_espectro" | "div_marrom_verde" | "arco_iris"
  #     Contínuas ............ "viridis" | "magma" | "plasma" | "cividis" | "inferno" | "turbo" | "cinza"
  #     ColorBrewer .......... "brewer_<nome>" (ex.: "brewer_Set1", "brewer_Spectral"; precisa do pacote RColorBrewer)
  #     Sua própria .......... "personalizada" (cores em cfg$cores$personalizada)
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

  # painel_fixo: a caixa do gráfico (a área dentro dos eixos) tem SEMPRE o mesmo tamanho, como o layer do Origin:
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

# Paletas prontas. Cada uma tem um nome curto (o que se escreve em cfg$cores$paleta) e um rótulo para a tela.
# "Estilo Origin": a sequência de cores básicas do Origin e conjuntos parecidos; as demais são paletas conhecidas
# de publicações científicas e de visualização (ColorBrewer, Paul Tol, ggsci, Tableau, D3).
.PALETAS <- list(
  # ---- estilo Origin
  classico  = c("#000000", "#D62728", "#1F4E9E", "#2CA02C", "#8E44AD", "#FF7F0E",
                "#17BECF", "#8C564B", "#E377C2", "#7F7F7F"),
  origin_basico = c("#000000", "#FF0000", "#0000FF", "#008000", "#FF00FF", "#008080", "#000080", "#800000",
                    "#800080", "#808000", "#FF8000", "#0080FF", "#8000FF", "#FF0080"),
  origin_vivo   = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFD700", "#A65628", "#F781BF", "#999999"),
  origin_escuro = c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666"),
  origin_pastel = c("#FBB4AE", "#B3CDE3", "#CCEBC5", "#DECBE4", "#FED9A6", "#FFFFCC", "#E5D8BD", "#FDDAEC", "#CCCCCC"),
  origin_suave  = c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854", "#FFD92F", "#E5C494", "#B3B3B3"),
  origin_pares  = c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", "#E31A1C", "#FDBF6F", "#FF7F00",
                    "#CAB2D6", "#6A3D9A", "#FFFF99", "#B15928"),
  origin_doce   = c("#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462", "#B3DE69", "#FCCDE5",
                    "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F"),
  # ---- marca
  marca     = c("#1B3A8C", "#0E9F4B", "#0B6E78", "#8CC63F", "#0F4C81", "#2FB5A0", "#5B7DB1", "#6BBF59"),
  # ---- acessíveis (daltonismo)
  okabe_ito = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9",
                "#000000", "#F0E442"),
  tol_brilhante = c("#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377", "#BBBBBB"),
  tol_vibrante  = c("#EE7733", "#0077BB", "#33BBEE", "#EE3377", "#CC3311", "#009988", "#BBBBBB"),
  tol_suave     = c("#CC6677", "#332288", "#DDCC77", "#117733", "#88CCEE", "#882255", "#44AA99", "#999933", "#AA4499"),
  tol_contraste = c("#004488", "#DDAA33", "#BB5566", "#000000"),
  # ---- publicações e software
  tableau   = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F", "#EDC948",
                "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC"),
  d3        = c("#1F77B4", "#FF7F0E", "#2CA02C", "#D62728", "#9467BD", "#8C564B", "#E377C2", "#7F7F7F", "#BCBD22", "#17BECF"),
  npg       = c("#E64B35", "#4DBBD5", "#00A087", "#3C5488", "#F39B7F", "#8491B4", "#91D1C2", "#DC0000", "#7E6148", "#B09C85"),
  lancet    = c("#00468B", "#ED0000", "#42B540", "#0099B4", "#925E9F", "#FDAF91", "#AD002A", "#ADB6B6", "#1B1919"),
  jco       = c("#0073C2", "#EFC000", "#868686", "#CD534C", "#7AA6DC", "#003C67", "#8F7700", "#3B3B3B", "#A73030", "#4A6990"),
  nejm      = c("#BC3C29", "#0072B5", "#E18727", "#20854E", "#7876B1", "#6F99AD", "#FFDC91", "#EE4C97"),
  # ---- degradês de uma cor (sequenciais): as séries percorrem do claro ao escuro
  seq_azul     = c("#C6DBEF", "#6BAED6", "#2171B5", "#08306B"),
  seq_verde    = c("#C7E9C0", "#74C476", "#238B45", "#00441B"),
  seq_laranja  = c("#FDD0A2", "#FD8D3C", "#D94801", "#7F2704"),
  seq_vermelho = c("#FCBBA1", "#FB6A4A", "#CB181D", "#67000D"),
  seq_roxo     = c("#DADAEB", "#9E9AC8", "#6A51A3", "#3F007D"),
  seq_azul_verde = c("#FFFFCC", "#A1DAB4", "#41B6C4", "#2C7FB8", "#253494"),
  seq_calor    = c("#FFFFB2", "#FECC5C", "#FD8D3C", "#F03B20", "#BD0026"),
  seq_frio     = c("#E0F7FA", "#80DEEA", "#26C6DA", "#00838F", "#004D40"),
  # ---- divergentes e arco-íris
  div_vermelho_azul = c("#B2182B", "#EF8A62", "#F7F7F7", "#67A9CF", "#2166AC"),
  div_espectro      = c("#D7191C", "#FDAE61", "#FFFFBF", "#ABDDA4", "#2B83BA"),
  div_marrom_verde  = c("#8C510A", "#D8B365", "#F5F5F5", "#5AB4AC", "#01665E"),
  arco_iris         = c("#9400D3", "#4B0082", "#0000FF", "#00AA00", "#FFD700", "#FF7F00", "#FF0000")
)
# As que percorrem um degradê (a n-ésima cor é interpolada ao longo da paleta inteira, não a n-ésima da lista).
.PALETAS_RAMPA <- c("seq_azul", "seq_verde", "seq_laranja", "seq_vermelho", "seq_roxo", "seq_azul_verde", "seq_calor",
                    "seq_frio", "div_vermelho_azul", "div_espectro", "div_marrom_verde", "arco_iris")

# Para a tela e para mostrar_paletas(): grupo -> c(nome = "rótulo").
.PALETAS_GRUPOS <- list(
  "Estilo Origin" = c("Clássica (preto, vermelho, azul...)" = "classico", "Origin: cores básicas" = "origin_basico",
                      "Origin: vivas" = "origin_vivo", "Origin: escuras" = "origin_escuro", "Origin: pastel" = "origin_pastel",
                      "Origin: suaves" = "origin_suave", "Origin: em pares" = "origin_pares", "Origin: doces" = "origin_doce"),
  "Marca" = c("Marca (azul e verde)" = "marca"),
  "Acessíveis (daltonismo)" = c("Okabe-Ito" = "okabe_ito", "Paul Tol: brilhante" = "tol_brilhante", "Paul Tol: vibrante" = "tol_vibrante",
                                "Paul Tol: suave" = "tol_suave", "Paul Tol: alto contraste" = "tol_contraste"),
  "Revistas e programas" = c("Tableau" = "tableau", "D3 (Category10)" = "d3", "Nature (NPG)" = "npg", "The Lancet" = "lancet",
                             "J. Clinical Oncology (JCO)" = "jco", "NEJM" = "nejm"),
  "Degradês de uma cor" = c("Azul" = "seq_azul", "Verde" = "seq_verde", "Laranja" = "seq_laranja", "Vermelho" = "seq_vermelho",
                            "Roxo" = "seq_roxo", "Amarelo → azul" = "seq_azul_verde", "Calor" = "seq_calor", "Frio" = "seq_frio"),
  "Divergentes e arco-íris" = c("Vermelho ↔ azul" = "div_vermelho_azul", "Espectro" = "div_espectro",
                                "Marrom ↔ verde" = "div_marrom_verde", "Arco-íris" = "arco_iris"),
  "Contínuas (viridis)" = c("Viridis" = "viridis", "Magma" = "magma", "Plasma" = "plasma", "Cividis" = "cividis",
                            "Inferno" = "inferno", "Turbo" = "turbo"),
  "Cinza" = c("Tons de cinza" = "cinza")
)

# Entra: nome da paleta e n. Sai: vetor com n cores (interpola se a paleta for menor que n).
.paleta <- function(nome, n, cfg_cores = NULL) {
  n <- max(n, 1)
  base <- if (nome %in% names(.PALETAS)) {
    b <- .PALETAS[[nome]]
    if (nome %in% .PALETAS_RAMPA) return(if (n == 1) b[length(b) - 1] else grDevices::colorRampPalette(b)(n))
    b
  } else if (nome %in% c("viridis", "magma", "plasma", "cividis", "inferno", "turbo")) {
    if (!.tem("viridisLite")) .erro("Paleta '", nome, "' precisa do pacote viridisLite.")
    fun <- getExportedValue("viridisLite", nome)
    return(fun(n, end = if (nome %in% c("viridis", "cividis")) 0.92 else 0.88))
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
    .erro("Paleta '", nome, "' desconhecida. Opções: ", paste(c(names(.PALETAS), "viridis", "magma", "plasma", "cividis", "inferno", "turbo", "cinza"), collapse = ", "),
          ", brewer_<nome>, personalizada. Veja mostrar_paletas().")
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
  for (k in c("largura_pt", "largura_chave_pt"))
    if (!is.null(lg[[k]]) && (!is.numeric(lg[[k]]) || length(lg[[k]]) != 1 || lg[[k]] <= 0))
      .erro("cfg$legenda$", k, " deve ser um número maior que 0 (pt).")
  if (!is.null(lg$espaco_chave_texto_pt) && (!is.numeric(lg$espaco_chave_texto_pt) || length(lg$espaco_chave_texto_pt) != 1 ||
                                             lg$espaco_chave_texto_pt < 0))
    .erro("cfg$legenda$espaco_chave_texto_pt deve ser um número >= 0 (pt).")
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

# Guia da legenda: como os itens se organizam. direcao "horizontal" = lado a lado (uma linha, ou n_linhas /
# n_colunas se dados); "vertical" = um embaixo do outro (uma coluna, ou n_colunas / n_linhas).
.guia_legenda <- function(cfg, n_itens, ...) {
  lg <- cfg$legenda
  nc <- lg$n_colunas; nl <- lg$n_linhas
  if (is.null(nc) && is.null(nl) && identical(lg$direcao, "horizontal")) nl <- 1
  if (!is.null(nc) && !is.null(nl) && n_itens > 0 && nc * nl < n_itens) nl <- ceiling(n_itens / nc)   # não cabem: aumenta as linhas
  guide_legend(ncol = nc, nrow = nl, byrow = TRUE, ...)
}

# Escalas manuais "fundidas" numa só legenda
.escalas_legenda <- function(est, aes_usadas, cfg) {
  itens <- names(est)
  quebras <- itens[vapply(est, function(e) isTRUE(e$legenda), logical(1))]
  if (isTRUE(cfg$legenda$inverter_ordem)) quebras <- rev(quebras)
  rotulos <- .rotulos_legenda(vapply(est[quebras], function(e) as.character(e$rotulo), ""))
  nome <- if (is.null(cfg$legenda$titulo)) NULL else .texto(cfg$legenda$titulo)
  guia <- .guia_legenda(cfg, length(quebras))
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
      guia <- .guia_legenda(cfg, length(quebras),
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
               face = if (.neg(cfg, e$negrito_rotulos)) "bold" else "plain",
               angle = ang, hjust = just$h, vjust = just$v, margin = m)
}

# Negrito ligado neste texto OU em "todos os nomes" (cfg$texto$negrito_tudo).
.neg <- function(cfg, valor = FALSE) isTRUE(valor) || isTRUE(cfg$texto$negrito_tudo)

# Ângulo padrão do título de cada lado do gráfico (esquerda sobe, direita desce, em cima/embaixo na horizontal).
.angulo_titulo <- function(e, lado) e$rotacao_titulo %||% switch(lado, left = 90, right = -90, 0)

# Elemento de tema para o título de um eixo (tamanho, cor, estilo, distância, rotação).
.elem_titulo <- function(e, cfg, lado, cor_forcada = NULL) {
  if (!isTRUE(e$mostrar_titulo %||% TRUE)) return(element_blank())
  d <- e$distancia_titulo_pt %||% 4
  m <- switch(lado, bottom = margin(t = d), top = margin(b = d),
              left = margin(r = d), right = margin(l = d))
  neg <- .neg(cfg, e$negrito_titulo)
  face <- if (neg && isTRUE(e$italico_titulo)) "bold.italic"
          else if (neg) "bold" else if (isTRUE(e$italico_titulo)) "italic" else "plain"
  centro <- if (!is.null(e$rotacao_titulo)) 0.5 else NULL                    # rotação escolhida: centraliza no seu espaço
  element_text(size = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt,
               colour = cor_forcada %||% e$cor_titulo %||% cfg$texto$cor, face = face,
               angle = .angulo_titulo(e, lado), hjust = centro, vjust = centro, margin = m)
}

# Entra: cfg, config do eixo horizontal e do vertical (como aparecem na tela) e os lados com eixo.
# Sai: tema ggplot2 completo.
# ev2 / cor_y2: aparência e cores (lista com ticks, rotulos, titulo, linha) do eixo da direita, quando ele é um Y2 próprio.
.tema <- function(cfg, eh, ev, lados, sem_eixos = FALSE, cor_y2 = NULL, ev2 = NULL) {
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
        element_line(colour = cor %||% e$cor_linha, linewidth = .lw(e$espessura_linha_pt %||% cx$espessura_pt),
                     lineend = ponta)
      }
      t <- t + theme(panel.border = element_blank(),
        axis.line.x.bottom = linha(eh, TRUE, ponta = "square"),
        axis.line.y.left   = linha(ev, TRUE, ponta = "square"),
        axis.line.y.right  = linha(ev2 %||% ev, "right" %in% lados$ver, cor = cor_y2$linha),
        axis.line.x.top    = linha(eh, "top" %in% lados$hor))
    }
    # ticks
    # espessura dos traços: a do eixo, ou (se vazia) a da moldura — mudar a grossura da caixa padroniza tudo
    tk <- function(e, cor = NULL) element_line(colour = cor %||% e$cor_ticks,
                                               linewidth = .lw(e$espessura_ticks_pt %||% cx$espessura_pt))
    for (lado in c("bottom", "top", "left", "right")) {
      e <- if (lado %in% c("bottom", "top")) eh else ev
      xy <- if (lado %in% c("bottom", "top")) "x" else "y"
      eh_y2 <- lado == lados$lado_y2
      if (eh_y2 && !is.null(ev2)) e <- ev2
      cor_l <- if (eh_y2) cor_y2$ticks else NULL
      el <- list()
      el[[paste0("axis.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.ticks.length.", xy, ".", lado)]] <- unit(.comp_tick(e$direcao_maiores, e$comprimento_maiores_pt),
                                                                "pt")
      el[[paste0("axis.minor.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.minor.ticks.length.", xy, ".",
                 lado)]] <- unit(.comp_tick(e$direcao_menores, e$comprimento_menores_pt), "pt")
      el[[paste0("axis.text.", xy, ".", lado)]] <- .elem_rotulo(e, cfg, lado, if (eh_y2) cor_y2$rotulos)
      el[[paste0("axis.title.", xy, ".", lado)]] <- .elem_titulo(e, cfg, lado, if (eh_y2) cor_y2$titulo)
      t <- t + do.call(theme, el)
    }
  }
  # legenda
  t <- t + .tema_legenda(cfg, fonte)
  # títulos
  ti <- cfg$titulos
  hj <- switch(ti$alinhamento, esquerda = 0, centro = 0.5, direita = 1)
  t + theme(plot.title = element_text(hjust = hj, size = ti$tamanho_titulo_pt %||% (tx$tamanho_base_pt * 1.2),
                                      face = if (.neg(cfg, ti$negrito_titulo)) "bold" else "plain"),
            plot.subtitle = element_text(hjust = hj, size = ti$tamanho_subtitulo_pt %||% tx$tamanho_base_pt,
                                         face = if (.neg(cfg)) "bold" else "plain"),
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
  if (!is.null(cfg$.interno$esc_leg)) cfg$.interno$esc_leg$v <- esc       # os símbolos/linhas das chaves seguem esta escala
  gap <- lg$espaco_chave_texto_pt             # espaço entre o símbolo e o texto (NULL = o padrão do ggplot2)
  t <- theme(
    legend.position = pos,
    legend.background = caixa,
    legend.key = element_rect(fill = NA, colour = NA),
    legend.key.size = unit(lg$tamanho_chave_pt * esc, "pt"),
    legend.key.spacing.y = unit(lg$espacamento_pt * esc, "pt"),
    legend.text = element_text(size = (lg$tamanho_texto_pt %||% tx$tamanho_base_pt) * esc,
                               face = if (.neg(cfg, lg$negrito_texto)) "bold" else "plain",
                               margin = if (!is.null(gap)) margin(l = gap * esc) else NULL),
    legend.title = if (is.null(lg$titulo)) element_blank() else
      element_text(size = (lg$tamanho_titulo_pt %||% tx$tamanho_base_pt) * esc,
                   face = if (.neg(cfg, lg$negrito_titulo)) "bold" else "plain"),
    legend.margin = do.call(margin, as.list(lg$margem_interna_pt * esc)))
  if (!is.null(lg$largura_chave_pt)) t <- t + theme(legend.key.width = unit(lg$largura_chave_pt * esc, "pt"))
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
    if (f %in% .FONTES_OFICIAIS) .registrar_fontes_oficiais()        # Barlow: vem junto com o template
    fams <- unique(.familias_fontes())
    ok <- tolower(f) %in% tolower(fams)
  }
  res <- if (ok) f else {
    .aviso("Fonte '", f, "' não encontrada", if (f %in% .FONTES_OFICIAIS) " (pasta fontes/Barlow ausente)" else " no sistema",
           "; usando 'sans'. Veja listar_fontes().")
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

# Ticks do eixo Y2 que o ggplot2 não desenha na escala própria do Y2: os menores (o sec_axis() não os traça) e a metade
# de dentro dos maiores quando a direção é "ambos". São traços no lado direito nas posições calculadas para o Y2.
# Entra: y2 (list(ax, para1, cor)), eixo Y1 calculado, a aparência do eixo vertical do Y2 (.estilo_y2) e a cor dos traços.
.ticks_y2_menores <- function(y2, ax_y, ev, ax_x = NULL, cor = NULL) {
  if (is.null(y2$para1)) return(NULL)
  filhos <- list()
  grupo <- function(valores, dir, comp, so_dentro) {
    if (!length(valores) || identical(dir, "nenhum") || (so_dentro && !identical(dir, "ambos"))) return()
    p <- .npc(y2$para1(valores), ax_y); p <- p[p >= -1e-6 & p <= 1 + 1e-6]
    if (!length(p)) return()
    L <- unit(comp, "pt"); x0 <- unit(1, "npc"); y <- unit(p, "npc")
    gp <- gpar(col = cor %||% .cor(y2$cor), lwd = .lw(ev$espessura_ticks_pt %||% 1) * ggplot2::.pt, lineend = "butt")
    if (so_dentro) filhos[[length(filhos) + 1]] <<- segmentsGrob(x0, y, x0 - L, y, gp = gp)
    else {
      if (dir %in% c("dentro", "ambos")) filhos[[length(filhos) + 1]] <<- segmentsGrob(x0, y, x0 - L, y, gp = gp)
      if (dir %in% c("fora", "ambos")) filhos[[length(filhos) + 1]] <<- segmentsGrob(x0, y, x0 + L, y, gp = gp)
    }
  }
  grupo(y2$ax$menores, ev$direcao_menores %||% "dentro", ev$comprimento_menores_pt, FALSE)
  grupo(y2$ax$maiores, ev$direcao_maiores %||% "dentro", ev$comprimento_maiores_pt, TRUE)    # maiores: só a metade de dentro
  if (!length(filhos)) return(NULL)
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
      gp <- gpar(col = e$cor_ticks, lwd = .lw(e$espessura_ticks_pt %||% 1) * ggplot2::.pt, lineend = "butt")
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
# Opções de aparência do eixo Y2 que, vazias (NULL), seguem o eixo Y.
.Y2_ESTILO <- c("direcao_maiores", "direcao_menores", "comprimento_maiores_pt", "comprimento_menores_pt", "espessura_ticks_pt",
                "cor_ticks", "mostrar_linha", "espessura_linha_pt", "cor_linha", "mostrar_rotulos", "tamanho_rotulos_pt",
                "cor_rotulos", "negrito_rotulos", "rotacao_rotulos", "mostrar_titulo", "tamanho_titulo_pt", "cor_titulo",
                "negrito_titulo", "italico_titulo", "distancia_rotulos_pt", "distancia_titulo_pt", "rotacao_titulo")

# Config do eixo Y2: a do eixo Y com o que o eixo_y2 define por cima (limites, ticks, formato). O divisor
# dos números (fator_divisao) é o do eixo_y2 se existir; senão herda o do eixo_y, como sempre foi.
# Limites, ticks e formato vazios no Y2 significam "automático" (não herdam os do Y); a aparência e a folga vazias herdam.
.eixo_y2_efetivo <- function(cfg) {
  sobre <- cfg$eixo_y2[intersect(names(cfg$eixo_y2), names(cfg$eixo_y))]
  herda <- names(sobre) %in% c(.Y2_ESTILO, "margem_percentual") & vapply(sobre, is.null, NA)
  e2 <- utils::modifyList(cfg$eixo_y, sobre[!herda])
  e2$fator_divisao <- cfg$eixo_y2$fator_divisao %||% cfg$eixo_y$fator_divisao
  e2$escala <- "linear"; e2$inverter <- FALSE
  e2
}
# Aparência do eixo Y2 (ticks, linha, números, título): a do eixo vertical `ev` com o que o eixo_y2 preencher por cima.
.estilo_y2 <- function(cfg, ev) {
  sobre <- cfg$eixo_y2[intersect(.Y2_ESTILO, names(cfg$eixo_y2))]
  sobre <- sobre[!vapply(sobre, is.null, NA)]
  out <- utils::modifyList(ev, sobre)
  out$mostrar_rotulos <- sobre$mostrar_rotulos %||% TRUE                       # sem pedir nada, o Y2 sempre mostra números e título
  out$mostrar_titulo <- if (isTRUE(cfg$.interno$sem_titulo_y2)) FALSE else (sobre$mostrar_titulo %||% TRUE)
  out
}
# Cores de cada parte do eixo Y2: a própria (cor_ticks, cor_rotulos...) ou, se vazia, a cor do eixo (cor_eixo / da série).
.cores_y2 <- function(cfg, cor_eixo) {
  e <- cfg$eixo_y2
  list(ticks = .cor(e$cor_ticks) %||% cor_eixo, rotulos = .cor(e$cor_rotulos) %||% cor_eixo,
       titulo = .cor(e$cor_titulo) %||% cor_eixo, linha = .cor(e$cor_linha) %||% cor_eixo)
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
      cam[[length(cam) + 1]] <- .camada_linha(d, L$ligacao, mapeado = TRUE, cfg = cfg)
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
        show.legend = TRUE, na.rm = TRUE, key_glyph = .key_escala(.draw_key_ponto_ou_nada, cfg))   # na.rm: células vazias sem aviso
      if (length(esf))
        cam[[length(cam) + 1]] <- geom_esfera(data = d[d$serie %in% esf, ], luz = cfg$serie_padrao$esfera_luz,
          mapping = aes(x = x, y = y, colour = serie, shape = serie, size = serie, stroke = serie), show.legend = TRUE,
          key_glyph = .key_escala(.draw_key_esfera, cfg))
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
      family = .fonte(cfg$texto$fonte), fontface = if (.neg(cfg)) "bold" else "plain")
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
.camada_linha <- function(d, ligacao, mapeado, e = NULL, cfg = NULL) {
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
        show.legend = TRUE,   # TRUE: a legenda mostra a série mesmo sem dados nesta camada (quebra de eixo)
        key_glyph = if (is.null(cfg)) "path" else .key_escala(ggplot2::draw_key_path, cfg))
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
                colour = .cor(B$rotulos_cor), family = .fonte(cfg$texto$fonte), fontface = if (.neg(cfg)) "bold" else "plain")
    else geom_text(data = rr, aes(x = xc, y = yl, label = rot), vjust = j, size = .tx(B$rotulos_tamanho_pt),
                   colour = .cor(B$rotulos_cor), family = .fonte(cfg$texto$fonte), fontface = if (.neg(cfg)) "bold" else "plain")
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
      colour = rd$cor, size = .tx(P$rotulos_tamanho_pt), lineheight = 0.95, family = .fonte(cfg$texto$fonte),
      fontface = if (.neg(cfg)) "bold" else "plain")
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
                                                   size = .tx(tam_n), family = .fonte(cfg$texto$fonte),
                                                   fontface = if (.neg(cfg)) "bold" else "plain")
      else geom_text(data = tn, aes(x = x, y = y, label = rot), vjust = -0.6,
                     size = .tx(tam_n), family = .fonte(cfg$texto$fonte), fontface = if (.neg(cfg)) "bold" else "plain")
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
      fontface = if (.neg(cfg, t$negrito)) "bold" else "plain", family = fonte)
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
  # escala atual da legenda, lida na hora de desenhar pelas chaves (símbolos/linhas) — assim eles acompanham a caixa
  esc_leg <- new.env(); esc_leg$v <- cfg$legenda$escala %||% 1
  cfg$.interno$esc_leg <- esc_leg
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
    sec_axis(transform = info$y2$para2, name = .texto(info$y2$titulo, .neg(cfg, cfg$eixo_y2$negrito_titulo %||% cfg$eixo_y$negrito_titulo)), breaks = a2$maiores,
             labels = a2$rotulos)
  } else sec_dup(info$ax_y)
  g <- g + .escala_continua(info$ax_x, "x", sec_x, if (x_topo) "top") +
    .escala_continua(info$ax_y, "y", sec_y, if (y_dir) "right")
  gm <- list(x = guide_axis(minor.ticks = length(info$ax_x$menores) > 0),
             y = guide_axis(minor.ticks = length(info$ax_y$menores) > 0))
  if (!is.null(sec_x)) gm$x.sec <- guide_axis(minor.ticks = length(info$ax_x$menores) > 0)
  if (!is.null(sec_y)) gm$y.sec <- guide_axis(minor.ticks = is.null(info$y2) && length(info$ax_y$menores) > 0)
  g <- g + do.call(guides, gm)
  g <- g + labs(x = .texto(info$titulo_x, .neg(cfg, cfg$eixo_x$negrito_titulo)),
                y = .texto(info$titulo_y, .neg(cfg, cfg$eixo_y$negrito_titulo)),
                title = .texto(cfg$titulos$titulo, .neg(cfg, cfg$titulos$negrito_titulo)),
                subtitle = .texto(cfg$titulos$subtitulo, .neg(cfg)))
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
  cfg <- .legenda_por_coordenadas(cfg, info)             # posição da legenda dada em unidades dos eixos (x_dados / y_dados)
  ev2 <- if (!is.null(info$y2)) .estilo_y2(cfg, ev) else NULL
  cor_y2 <- if (!is.null(info$y2)) .cores_y2(cfg, .cor(info$y2$cor)) else NULL
  g <- g + .tema(cfg, eh, ev, lados, cor_y2 = cor_y2, ev2 = ev2)
  if (y_dir && espelhar) {
    g <- g + theme(axis.text.y.left = element_blank(), axis.title.y.left = element_blank(),
                   axis.text.y.right = .elem_rotulo(ev, cfg,
                                                    "right"), axis.title.y.right = .elem_titulo(ev, cfg, "right"))
  }
  ti <- .ticks_internos(axh, axv, lados, info$ax_x, info$ax_y)
  if (!is.null(ti)) g <- g + ti
  if (!is.null(info$y2)) {
    tm <- .ticks_y2_menores(info$y2, info$ax_y, ev2, info$ax_x, cor_y2$ticks)
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
  cfg <- .resolver_herancas(cfg)
  g <- if (isTRUE(cfg$paineis$ativo)) .plotar_paineis(dados, cfg)
       else if (isTRUE(cfg$quebra$ativo)) .plotar_quebra(dados, cfg)
       else .plotar_um(dados, cfg)
  attr(g, "dados") <- dados
  attr(g, "cfg") <- cfg
  g
}

# Valores que, se vazios, seguem outro ajuste: a grossura dos traços e da linha dos eixos segue a da moldura
# (cfg$caixa$espessura_pt) — mudar a moldura padroniza tudo; escrever o valor no eixo vale mais.
.resolver_herancas <- function(cfg) {
  for (ax in c("eixo_x", "eixo_y")) {
    cfg[[ax]]$espessura_ticks_pt <- cfg[[ax]]$espessura_ticks_pt %||% cfg$caixa$espessura_pt
    cfg[[ax]]$espessura_linha_pt <- cfg[[ax]]$espessura_linha_pt %||% cfg$caixa$espessura_pt
  }
  cfg
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
  face <- if (.neg(cfg, e$negrito_titulo)) "bold" else "plain"
  patchwork::wrap_elements(full = textGrob(.texto(texto, .neg(cfg, e$negrito_titulo)),
    rot = e$rotacao_titulo %||% if (vertical) (if (direita) -90 else 90) else 0,
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
  if (isTRUE(cfg$eixo_y2$ativo) && identical(cfg$eixo_y2$modo, "independente"))   # as séries do eixo direito têm outra escala
    ys <- setdiff(ys, names(Filter(function(x) identical(x$eixo, "y2"), cfg$series)))
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
    nm <- Q[[paste0("n_menores_", parte)]]; nm2 <- Q[[paste0("y2_n_menores_", parte)]]      # ticks pequenos de cada parte
    if (!is.null(nm)) ck$eixo_y$n_menores <- nm
    if (!is.null(nm2) && !is.null(y2)) ck$eixo_y2$n_menores <- nm2
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
  if (is.null(grDevices::dev.list())) {           # ggplotGrob() precisa de um dispositivo: usa um descartável, sem arquivo
    dtmp <- .abrir_dispositivo_tmp(); on.exit(grDevices::dev.off(dtmp), add = TRUE)
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
               fontface = if (.neg(cfg, e$negrito_titulo)) "bold" else "plain",
               fontfamily = .fonte(cfg$texto$fonte), col = cor %||% e$cor_titulo %||% cfg$texto$cor)
    rot <- .angulo_titulo(e, if (lado == "esq") "left" else "right")
    lab <- .texto(texto, .neg(cfg, e$negrito_titulo))
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
  if (!is.null(y2) && !identical(y2$titulo, "")) {
    ev2 <- .estilo_y2(cfg, cfg$eixo_y)
    if (isTRUE(ev2$mostrar_titulo)) gt <- titulo_lateral(gt, y2$titulo, ev2, "dir", .cores_y2(cfg, .cor(y2$cor))$titulo)
  }
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
  esp <- if (fechada) cx$espessura_pt else (ev$espessura_linha_pt %||% cx$espessura_pt)
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

# Tamanho de saída. Com a caixa de tamanho fixo (cfg$caixa$painel_fixo, o padrão; tamanho em painel_largura_cm /
# painel_altura_cm ou painel_padrao_cm) a caixa do gráfico fica EXATAMENTE nesse tamanho, e a página cresce (ou
# encolhe) para caber números, títulos e legenda sem cortar nada (exportacao$ajustar_pagina = TRUE) — o gráfico tem o
# mesmo tamanho em todos os arquivos. Sem caixa fixa: o da página (cfg$exportacao).
# Entra: g e cfg. Sai: list(grob = NULL | gtable pronto para desenhar, larg, alt em polegadas).
.preparar_saida <- function(g, cfg) {
  pg <- .tamanho_pagina_in(cfg)
  fixo <- .painel_cm(cfg)
  if (is.null(fixo)) return(list(grob = NULL, larg = pg[1], alt = pg[2]))
  pw <- fixo$w; ph <- fixo$h
  gt <- attr(g, "gt")
  if (is.null(gt)) {
    if (inherits(g, "patchwork")) return(list(grob = NULL, larg = pg[1], alt = pg[2]))   # painéis empilhados: página
    if (is.null(grDevices::dev.list())) { dtmp <- .abrir_dispositivo_tmp(); on.exit(grDevices::dev.off(dtmp), add = TRUE) }
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
    if (f %in% c("pdf", "emf")) .avisar_fonte_so_registrada(cfg$texto$fonte, f)
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
  arq <- file.path(tempdir(), "previa_do_grafico.png")           # nomes fixos e legíveis (não números aleatórios)
  prep <- .preparar_saida(g, cfg)
  .abrir_dispositivo("png", arq, prep$larg, prep$alt, dpi, "white", usar_ragg = .ragg_ok(cfg))
  disp <- grDevices::dev.cur()
  tryCatch(.desenhar(prep, g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    html <- file.path(tempdir(), "previa_do_grafico.html")
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

# PDF e EMF usam as fontes INSTALADAS no sistema: uma fonte só registrada (como a Barlow vinda de fontes/) vira outra.
.avisar_fonte_so_registrada <- function(fonte, formato) {
  if (is.null(fonte) || fonte %in% c("sans", "serif", "mono") || !.tem("systemfonts")) return(invisible())
  instalada <- tolower(fonte) %in% tolower(systemfonts::system_fonts()$family)
  reg <- tolower(fonte) %in% tolower(systemfonts::registry_fonts()$family)
  if (reg && !instalada && !isTRUE(.fontes_cache$.avisou_pdf))
    { .fontes_cache$.avisou_pdf <- TRUE
      .aviso("O ", toupper(formato), " usa as fontes instaladas no Windows e a '", fonte, "' só está carregada pelo template: ",
             "o texto sairá em outra fonte. Instale-a (abra os arquivos .ttf de fontes/Barlow e clique em Instalar) ",
             "ou exporte em PNG, TIFF ou SVG, que usam a Barlow direto.") }
  invisible()
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
  .registrar_fontes_oficiais()
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
registrar_fonte <- function(nome, pasta = NULL, arquivos = NULL, silencioso = FALSE) {
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
  if (!silencioso) message("Fonte '", nome, "' registrada (", sum(!is.na(arquivos) & file.exists(arquivos)),
                           " arquivo(s)). Use cfg$texto$fonte <- \"", nome, "\".")
  invisible(nome)
}

# Fonte OFICIAL do template: Barlow (licença SIL OFL; os arquivos estão em fontes/Barlow/, ao lado dos scripts).
# É registrada sozinha na primeira vez que for usada — não precisa instalar nada no Windows.
# No script único (graficos_R_completo.R) há uma cópia embutida, usada se a pasta fontes/ não estiver junto.
.FONTES_OFICIAIS <- c("Barlow", "Barlow Condensed", "Barlow Semi Condensed")
.registrar_fontes_oficiais <- function() {
  if (isTRUE(.fontes_cache$.oficiais_tentado)) return(invisible(isTRUE(.fontes_cache$.oficiais_ok)))
  .fontes_cache$.oficiais_tentado <- TRUE
  if (!.tem("systemfonts")) return(invisible(FALSE))
  base <- get0(".motor_pasta", inherits = TRUE, ifnotfound = getwd())
  cand <- unique(c(file.path(base, "fontes", "Barlow"), file.path(getwd(), "fontes", "Barlow"),
                   file.path(getwd(), "graficos_R", "fontes", "Barlow")))
  pasta <- cand[dir.exists(cand)][1]
  if (is.na(pasta) && exists(".BARLOW_EMBUTIDA", inherits = TRUE)) {      # cópia embutida no script único
    pasta <- file.path(tempdir(), "Barlow"); dir.create(pasta, showWarnings = FALSE)
    emb <- get(".BARLOW_EMBUTIDA", inherits = TRUE)
    for (nm in names(emb)) {
      arq <- file.path(pasta, paste0("Barlow-", nm, ".ttf"))
      if (!file.exists(arq)) writeBin(memDecompress(jsonlite_b64(emb[[nm]]), type = "gzip"), arq)
    }
  }
  if (is.na(pasta)) return(invisible(FALSE))
  ok <- vapply(.FONTES_OFICIAIS, function(n) tryCatch({ registrar_fonte(n, pasta, silencioso = TRUE); TRUE },
                                                      error = function(e) FALSE), NA)
  .fontes_cache$.oficiais_ok <- any(ok)
  invisible(any(ok))
}
# Decodifica base64 (sem pacotes extras): usa o 'base64enc'/'jsonlite' se houver, senão o decodificador do utils.
jsonlite_b64 <- function(txt) {
  txt <- gsub("[\r\n ]", "", txt)
  if (requireNamespace("jsonlite", quietly = TRUE)) return(jsonlite::base64_dec(txt))
  if (requireNamespace("base64enc", quietly = TRUE)) return(base64enc::base64decode(txt))
  stop("Para usar a fonte embutida é preciso o pacote jsonlite (vem com o shiny/ragg).", call. = FALSE)
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
  quebra_y_ticks_menores_inferior = c("quebra", "n_menores_inferior"),
  quebra_y_ticks_menores_superior = c("quebra", "n_menores_superior"),
  quebra_y2_ticks_menores_inferior = c("quebra", "y2_n_menores_inferior"),
  quebra_y2_ticks_menores_superior = c("quebra", "y2_n_menores_superior"),
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
  negrito_geral = c("texto", "negrito_tudo"),
  x_numeros_negrito = c("eixo_x", "negrito_rotulos"), y_numeros_negrito = c("eixo_y", "negrito_rotulos"),
  legenda_negrito = c("legenda", "negrito_texto"), legenda_titulo_negrito = c("legenda", "negrito_titulo"),
  x_rotacao_titulo = c("eixo_x", "rotacao_titulo"), y_rotacao_titulo = c("eixo_y", "rotacao_titulo"),
  y2_rotacao_titulo = c("eixo_y2", "rotacao_titulo"),
  y2_primeiro_tick = c("eixo_y2", "primeiro_tick"), y2_folga_pct = c("eixo_y2", "margem_percentual"),
  y2_ticks_direcao = c("eixo_y2", "direcao_maiores"), y2_ticks_menores_direcao = c("eixo_y2", "direcao_menores"),
  y2_ticks_comprimento_pt = c("eixo_y2", "comprimento_maiores_pt"),
  y2_ticks_menores_comprimento_pt = c("eixo_y2", "comprimento_menores_pt"),
  y2_ticks_espessura_pt = c("eixo_y2", "espessura_ticks_pt"), y2_ticks_cor = c("eixo_y2", "cor_ticks"),
  y2_linha_espessura_pt = c("eixo_y2", "espessura_linha_pt"), y2_mostrar_numeros = c("eixo_y2", "mostrar_rotulos"),
  y2_numeros_tamanho_pt = c("eixo_y2", "tamanho_rotulos_pt"), y2_numeros_negrito = c("eixo_y2", "negrito_rotulos"),
  y2_rotacao_numeros = c("eixo_y2", "rotacao_rotulos"), y2_titulo_tamanho_pt = c("eixo_y2", "tamanho_titulo_pt"),
  y2_titulo_negrito = c("eixo_y2", "negrito_titulo"), y2_titulo_italico = c("eixo_y2", "italico_titulo"),
  quebra_marcas = c("quebra", "marcas"), quebra_marca_largura_pt = c("quebra", "marca_largura_pt"),
  quebra_marca_altura_pt = c("quebra", "marca_altura_pt"),
  painel_fixo = c("caixa", "painel_fixo"),
  legenda_largura_pt = c("legenda", "largura_pt"), legenda_espaco_texto_pt = c("legenda", "espaco_chave_texto_pt"),
  legenda_largura_chave_pt = c("legenda", "largura_chave_pt"),
  legenda_x_dados = c("legenda", "x_dados"), legenda_y_dados = c("legenda", "y_dados"),
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
  legenda_direcao = c("legenda", "direcao"), legenda_n_colunas = c("legenda", "n_colunas"), legenda_n_linhas = c("legenda", "n_linhas"),
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
  fundo_transparente = c("exportacao", "fundo_transparente"),
  largura_cm = c("exportacao", "largura"), altura_cm = c("exportacao", "altura"), dpi = c("exportacao", "dpi"),
  formatos = c("exportacao", "formatos"), nome_arquivo = c("exportacao", "nome_arquivo"),
  pasta_saida = c("exportacao", "pasta")
)

# Variáveis do painel que mexem no eixo Y da direita (Y2).
.Y2_VARIAVEIS <- c("y2_series", "y2_fator", "y2_deslocamento", "y2_titulo", "y2_inicio", "y2_fim", "y2_intervalo",
                   "y2_ticks_manuais", "y2_ticks_menores", "y2_cor", "y2_cor_eixo", "y2_dividir_por", "y2_casas_decimais",
                   "y2_notacao", "y2_prefixo", "y2_sufixo", "y2_igual_y1", "y2_legenda_sufixo", "y2_rotacao_titulo", "y2_distancia_titulo_pt",
                   "y2_distancia_numeros_pt", "y2_primeiro_tick", "y2_folga_pct", "y2_ticks_direcao", "y2_ticks_menores_direcao",
                   "y2_ticks_comprimento_pt", "y2_ticks_menores_comprimento_pt", "y2_ticks_espessura_pt", "y2_ticks_cor",
                   "y2_linha_espessura_pt", "y2_mostrar_numeros", "y2_numeros_tamanho_pt", "y2_numeros_negrito",
                   "y2_rotacao_numeros", "y2_titulo_tamanho_pt", "y2_titulo_negrito", "y2_titulo_italico")

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
      cy <- cfg$grafico$colunas_y                  # marcar uma coluna para o eixo direito também a coloca no gráfico
      if (is.character(cy) && is.character(y2s) && length(setdiff(y2s, cy))) cfg$grafico$colunas_y <- c(cy, setdiff(y2s, cy))
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
  nomes <- pega("legenda_nomes")                    # como cada série aparece escrita na legenda
  if (!is.null(nomes)) {
    if (is.null(names(nomes)) || any(!nzchar(names(nomes))))
      .erro("legenda_nomes precisa de nomes: c(\"WORLD\" = \"Mundo\", \"BRAZIL\" = \"Brasil\").")
    for (nm in names(nomes))
      cfg$series[[nm]] <- utils::modifyList(cfg$series[[nm]] %||% list(), list(nome_legenda = as.character(nomes[[nm]])))
    marca("legenda_nomes")
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

geom_esfera <- function(mapping = NULL, data = NULL, luz = c(-0.35, -0.45), show.legend = NA, na.rm = TRUE,
                        key_glyph = NULL, ...) {
  ggplot2::layer(geom = .GeomEsfera, stat = "identity", position = "identity", data = data, mapping = mapping,
                 show.legend = show.legend, inherit.aes = FALSE,
                 params = c(list(na.rm = na.rm, luz = luz), if (!is.null(key_glyph)) list(key_glyph = key_glyph), list(...)))
}

# Chave da legenda que acompanha a escala da caixa da legenda (cfg$legenda$escala, inclusive a reduzida sozinha para caber):
# o tamanho do símbolo, o contorno e a grossura da linha mudam junto. 'base' = função draw_key_*.
.key_escala <- function(base, cfg) {
  env <- cfg$.interno$esc_leg
  function(data, params, size) {
    e <- if (is.null(env)) 1 else (env$v %||% 1)
    if (!isTRUE(all.equal(e, 1)))
      for (k in c("size", "stroke", "linewidth")) if (!is.null(data[[k]])) data[[k]] <- data[[k]] * e
    base(data, params, size)
  }
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

# Tamanho (cm) da caixa do gráfico, ou NULL se não for fixa. Entra: cfg. Sai: NULL | list(w, h) (um deles pode ser NULL).
# Fixa por padrão (cfg$caixa$painel_fixo); pizza e painéis empilhados só têm caixa fixa se o tamanho for pedido.
.painel_cm <- function(cfg) {
  cx <- cfg$caixa
  if (!isTRUE(cx$painel_fixo %||% TRUE)) return(NULL)
  w <- cx$painel_largura_cm; h <- cx$painel_altura_cm
  if (is.null(w) && is.null(h)) {
    if (identical(cfg$grafico$tipo, "pizza") || isTRUE(cfg$paineis$ativo)) return(NULL)
    p <- cx$painel_padrao_cm %||% c(10, 7.5)
    w <- p[1]; h <- p[2]
    if (!is.null(cx$proporcao)) h <- w * cx$proporcao
    return(list(w = w, h = h))
  }
  if (is.null(h) && !is.null(w) && !is.null(cx$proporcao)) h <- w * cx$proporcao
  if (is.null(w) && !is.null(h) && !is.null(cx$proporcao)) w <- h / cx$proporcao
  list(w = w, h = h)
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
  k <- grep("^guide-box", gt$layout$name)                    # inside / right / left / top / bottom
  k <- k[!vapply(gt$grobs[k], function(x) inherits(x, "zeroGrob"), NA)]
  if (!length(k)) return(NULL)
  lg <- gt$grobs[[k[1]]]
  mede <- function(u, total) {                  # soma das partes absolutas; o que sobra é do painel
    nulas <- grid::unitType(u) == "null"
    abs_pt <- if (any(!nulas)) sum(grid::convertUnit(u[!nulas], "pt", valueOnly = TRUE)) else 0
    max(total * 72 - abs_pt, 1)
  }
  list(painel = c(mede(gt$widths, tam_in[1]), mede(gt$heights, tam_in[2])),
       legenda = c(grid::convertWidth(grid::grobWidth(lg), "pt", valueOnly = TRUE),
                   grid::convertHeight(grid::grobHeight(lg), "pt", valueOnly = TRUE)))
}

# Ajusta a escala da legenda: (1) com cfg$legenda$largura_pt a caixa fica EXATAMENTE com essa largura (símbolos e linhas
# acompanham); (2) senão, uma legenda "dentro" maior que a caixa do gráfico é reduzida até caber. Entra: g e cfg. Sai: g.
.ajustar_legenda <- function(g, cfg) {
  lg <- cfg$legenda
  manual <- !is.null(lg$largura_pt)
  if (!manual && (!identical(lg$posicao, "dentro") || !isTRUE(lg$ajustar_caixa %||% TRUE))) return(g)
  esc0 <- lg$escala %||% 1; esc <- esc0
  fr <- cfg$.interno$fracao_altura %||% 1       # quebra de eixo: a legenda mora só na parte de cima
  pf <- .painel_cm(cfg)
  fixo <- if (!is.null(pf) && !is.null(pf$w) && !is.null(pf$h)) c(pf$w, pf$h) else NULL
  refaz <- function(e) { c2 <- cfg; c2$legenda$escala <- e; g <<- g + .tema_legenda(c2, .fonte(cfg$texto$fonte)) }
  for (it in 1:(if (manual) 5 else 3)) {
    m <- tryCatch(.medir_legenda(g, .tamanho_pagina_in(cfg)), error = function(e) NULL)
    if (is.null(m)) break
    if (manual) {                                # largura pedida: escala até a caixa ter essa largura
      if (abs(m$legenda[1] - lg$largura_pt) < 0.4) break
      esc <- esc * max(min(lg$largura_pt / m$legenda[1], 4), 0.1)
      refaz(esc); next
    }
    painel <- m$painel
    if (length(fixo) == 2) painel <- fixo * 72 / 2.54          # caixa de tamanho fixo: as medidas são exatas
    d <- if (is.null(lg$distancia_pt)) c(0, 0) else rep_len(lg$distancia_pt, 2)
    f <- min(1, (painel[1] * 0.97 - d[1]) / m$legenda[1], (painel[2] * fr * 0.95 - d[2]) / m$legenda[2])
    if (!is.finite(f) || f >= 0.995) break
    esc <- esc * max(f * 0.99, 0.2)
    refaz(esc)
  }
  if (manual) {
    m <- tryCatch(.medir_legenda(g, .tamanho_pagina_in(cfg)), error = function(e) NULL)
    if (!is.null(m) && identical(lg$posicao, "dentro") && m$legenda[1] > (if (length(fixo) == 2) fixo[1] * 72 / 2.54 else m$painel[1]))
      .aviso("A largura pedida para a legenda (", lg$largura_pt, " pt) é maior que a caixa do gráfico.")
  } else if (esc < esc0 * 0.995)
    message("Legenda reduzida para ", round(100 * esc / esc0), "% para caber dentro da caixa ",
            "(cfg$legenda$ajustar_caixa <- FALSE desliga; legenda$escala, ou menos séries/colunas, também ajudam).")
  g
}

# Dispositivo descartável para medir/montar gtables (ragg: as mesmas fontes do arquivo final; sem aviso de fonte do pdf).
# Sai: o número do dispositivo aberto (feche com grDevices::dev.off(numero)).
.abrir_dispositivo_tmp <- function(larg = 7, alt = 5) {
  if (.tem("ragg")) ragg::agg_capture(width = larg, height = alt, units = "in", res = 72) else grDevices::pdf(NULL)
  grDevices::dev.cur()
}

# Posição da legenda por COORDENADAS DOS EIXOS: cfg$legenda$x_dados / y_dados (valores do eixo X e do eixo Y esquerdo,
# ex.: x = 2016, y = 600000). O canto SUPERIOR ESQUERDO da legenda fica nesse ponto. Um dos dois pode ficar vazio
# (aí vale o dentro_x / dentro_y). Entra: cfg e info (eixos calculados). Sai: cfg com dentro_x/dentro_y/ancora acertados.
.legenda_por_coordenadas <- function(cfg, info) {
  lg <- cfg$legenda
  if (is.null(lg$x_dados) && is.null(lg$y_dados)) return(cfg)
  if (!identical(lg$posicao, "dentro")) return(cfg)
  ax_h <- if (isTRUE(info$flip)) info$ax_y else info$ax_x          # eixo horizontal na TELA
  ax_v <- if (isTRUE(info$flip)) info$ax_x else info$ax_y
  conv <- function(v, ax, quem) {
    if (is.null(v)) return(NULL)
    if (is.null(ax) || !is.null(ax$categorias))
      .erro("cfg$legenda$", quem, ": este eixo é de categorias; use dentro_x / dentro_y (de 0 a 1).")
    if (!is.null(ax$tempo)) v <- .tempo_num(v, ax$tempo, paste0("cfg$legenda$", quem))
    f <- .npc(v, ax)
    if (!is.finite(f)) .erro("cfg$legenda$", quem, " = ", v, " não existe neste eixo.")
    if (f < -0.001 || f > 1.001)
      .aviso("cfg$legenda$", quem, " = ", v, " fica fora do eixo (", signif(ax$limites[1], 6), " a ", signif(ax$limites[2], 6),
             "); a legenda foi colocada na borda.")
    min(max(f, 0), 1)
  }
  fx <- conv(lg$x_dados, ax_h, "x_dados"); fy <- conv(lg$y_dados, ax_v, "y_dados")
  if (!is.null(fx)) cfg$legenda$dentro_x <- fx
  if (!is.null(fy)) cfg$legenda$dentro_y <- fy
  cfg$legenda$ancora <- c(if (!is.null(fx)) 0 else cfg$legenda$dentro_x, if (!is.null(fy)) 1 else cfg$legenda$dentro_y)
  if (!is.null(fx) && !is.null(fy)) cfg$legenda$ancora <- c(0, 1)
  cfg
}

# Onde a legenda "dentro" fica na figura, para o app desenhar uma caixa que se arrasta sobre a prévia.
# Entra: g (de plotar) e cfg. Sai: NULL (sem legenda dentro) ou list(pagina = c(larg, alt) em polegadas,
#   painel = c(esq, topo, larg, alt) e legenda = c(esq, topo, larg, alt), todos em FRAÇÃO da página (topo = a partir de cima)).
.geometria_legenda <- function(g, cfg) {
  lg <- cfg$legenda
  if (!identical(lg$posicao, "dentro") || isFALSE(lg$mostrar)) return(NULL)
  prep <- .preparar_saida(g, cfg)
  dtmp <- .abrir_dispositivo_tmp(prep$larg, prep$alt); on.exit(grDevices::dev.off(dtmp), add = TRUE)
  gt <- prep$grob %||% attr(g, "gt") %||% ggplot2::ggplotGrob(g)
  k <- which(gt$layout$name == "guide-box-inside")
  k <- k[!vapply(gt$grobs[k], function(x) inherits(x, "zeroGrob"), NA)]
  if (!length(k)) return(NULL)
  k <- k[1]; lay <- gt$layout[k, ]
  tam <- function(u, total_in, conv) {                 # tamanho de cada coluna/linha, em polegadas (null = parte do que sobra)
    nulo <- grid::unitType(u) == "null"
    r <- numeric(length(u))
    if (any(!nulo)) r[!nulo] <- conv(u[!nulo], "in", valueOnly = TRUE)
    if (any(nulo)) { v <- as.numeric(u[nulo]); r[nulo] <- max(total_in - sum(r[!nulo]), 0) * v / sum(v) }
    r
  }
  w <- tam(gt$widths, prep$larg, grid::convertWidth); h <- tam(gt$heights, prep$alt, grid::convertHeight)
  pw <- sum(w[lay$l:lay$r]); ph <- sum(h[lay$t:lay$b])
  pl <- sum(w[seq_len(lay$l - 1)]); pt <- sum(h[seq_len(lay$t - 1)])
  lw <- grid::convertWidth(grid::grobWidth(gt$grobs[[k]]), "in", valueOnly = TRUE)
  lh <- grid::convertHeight(grid::grobHeight(gt$grobs[[k]]), "in", valueOnly = TRUE)
  info <- attr(g, "info") %||% attr(attr(g, "partes")[[1]], "info")
  if (!is.null(info)) lg <- tryCatch(.legenda_por_coordenadas(cfg, info)$legenda, error = function(e) lg)
  anc <- if (identical(lg$ancora, "auto")) c(lg$dentro_x, lg$dentro_y) else lg$ancora
  esq <- lg$dentro_x * pw - anc[1] * lw                 # a legenda fica com o ponto 'anc' dela em (dentro_x, dentro_y) do painel
  base <- lg$dentro_y * ph - anc[2] * lh                # distância da base do painel
  list(pagina = c(prep$larg, prep$alt),
       painel = c(pl, pt, pw, ph) / c(prep$larg, prep$alt, prep$larg, prep$alt),
       legenda = c(pl + esq, pt + ph - base - lh, lw, lh) / c(prep$larg, prep$alt, prep$larg, prep$alt))
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
  nomes <- c(unlist(.PALETAS_GRUPOS, use.names = FALSE), "personalizada")
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
    theme_minimal(11) + theme(panel.grid = element_blank(), axis.text.y = element_text(face = "bold", size = 8))
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
#  PARTE 2B — FONTE OFICIAL BARLOW (embutida; não precisa editar)
#  Licença SIL Open Font License 1.1 (veja fontes/Barlow/OFL.txt no repositório). Se a pasta fontes/Barlow estiver
#  ao lado deste script, ela é usada no lugar desta cópia.
# #############################################################################
.BARLOW_EMBUTIDA <- list(
  Regular = "
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
w18k/MVv+UtvfayzfFbxv9fcNn+b+p1Cu67be9a1133PaKX2fY/JJ23+q1qXzf9NCP8Zrc7mPx7Kl3+y+VfStSHvlzaf3x+hHlfR
wBD+Ppu/QTaE8C+37f3Az4TVTlrQGUiMGyeKK31JeWgntSlxGrnqyaH2tDp0a2BfoH6gCg5mNgdhNhiXy2wIKsHj4SeP6gfbog51
OnJBpDtU00lpbm6e2DyhvbXRV1VRWJAzaGBavsfwFjkibjP6gYakdoOGJJF5PdrVju70cIRaOY7UxgwyFnXOnOdIG2SmlPdYze3q
7pSxugTROFKz89Q0o03e70guSeE083m7CXbbPM22yfW0MNxfwV9P3NcpPtIQKRrFJDFbbPBFDfCgt4dBdBW++sMYeTFuKQzSHUJf
5EFHLeeqJGBMZ2yUVJvBoqF8tcMozVfWh6DoFuuMpaio7nu6fFmTJ49pEmLy7MmndE3tbG+aNGYSitJQkJeXN2RwbpwxUM1j9WED
b0rwM8XcUGWZo9rrTQnOQahcPydB3a52MfP9LmeouTbMXzJvpT5iZMko2KXCIM+icSOmxkstcWpl8+n9nLrh/yM63c7hJ2frnhy3
lnRa0/DpSeickxeM/lD/Ttc9zaVljW5N/nKqfkbT+FHl7ua2cVP0osrReVmWscrynY7Ble2jk4cPj9Lz+pdXj/XoiQ53ma8kX1JB
CRXqRfFFNdXFcUO/Hl7dqA8bWjgMPj0R9trHba5OXGj2I3H9Sddi+AdePWgw7WlBDgU5XaZgmjk3qOs8RBpjNhjV1zSpFpPZ+yrR
SLtNQQKDpsLC/IqawTxosia+8tSaec9J6KD2neZUmKlcpVO2QnUN7YtNnN1S0JhC1sS0JlMaC1pPTWhyR0XH1BXk1UQbHo8nprqg
cGQ0dUyYPHRUW1YGhhFF5nT1IZADs8b69lYNK6tJGVQwJDu5uqy0KjmnsDDXnG/xQUfvwnfL1Ox6bPA8gdoWvya43jume4mkSVeZ
Q5koLcgtKHCi20yxWrzpQyoKuHhzgFkTy5uqa6pMh1Jq+OOixJiYhMVtY8/s5yBPuXSho28pL29CPYym8rJWeH1UGVpA3JKx7nZf
8cS28lHt42oSoiHo8sTlVVUV541uzB1aVVGg64Y6/p1U14a2adZD2Xqn1W/ex222J1/KTcuD9W7heo8XZ/miqknTsw21vc0KnrlC
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
7e3114XS6VCtL97rE98ksfc5hf4MfR2Stkrrc/NRJJOgDStyohbzHRCQVvNAPRnzYDI9jv0IxzqlCsc1kSS6aBwhUWnj5o3Tk4P9
vbGArxUEmlIx/vYkVNAFmupWDC/rVanyn4UgXBBzCBfIoxCqAnn2BcQuKkIuT4vNal3H91CHe7oNSk309A5Zlks/qIZ4gWSOdESQ
bB5+9wmnInuvw+kkqLci9Yz5h1uFz83PhD7/e3SoMC9fEb4k4jqIh0NG7oKX8IvFXOLSvPCJoLw8OSR8cDLSGdIF0k8ePiOE9e1J
HqibYggEyAGLCvax7vpQ/FFTJROeBbGu1qpQroA3rKkmZnpJ7szTyx9WD1iQSFPFH61Hp3gw113PZQUoqkdKH179CdBlYoegi4cu
OHT0nMP79+7avnXTwvzaybGRwb5UvDvi93a1tTbZGuqqhEdQo0g1KPwfhV+QfCr/Y4dxG2aCp/THKRyXpRK3FjLRoXsVnbhWd37k
LswjjI3Q6Z0uxlwpH7LMGN8M9RTW3m7GdlM0o3uuPaO7KTW1P6urrgKVRnx1b5xDrIOhZGab+aVtRZkTPy5xVsNizKfx49KctF0a
z+XmMpj7FTHheVVlESl3VFh5QG+rhjm1q2Hmc2Jv3bR+fkaQFtT8eNI9nuit4XbUKQnTeWrqGtACnpLk2ugzK8nCgSyWk4/yfZwx
w3no4opkqEyyNkrd79ZzcH8Y1sLQUg9+2lgLa6V96IFcTS1i2ItkqwtZCkZxVkzlKjGVJXiU7z4K+9NqLbU6OfLSKPfZNb4W7ONT
PT90kudb/pvv56Z2+vSel4zHtQNg241q5qLuL3la1S10xky7+xQ15LJVfHWD3X7kNT66yP/LtUnSnl2c3Y/lBvvSyXCwq73J0VAn
Vnb1spUtFVj7qU36TMFPT3eRSad8FQ18/CFjJedfIic17l/kiCYwrXr7frrSyC8s5vyScGs+qaUf5J6CW9YjsFRxsvf5lX72MG+5
v+Z9hl+tW0pKb9ZHyseIhfA1rafcU4XvkBWJCaYoGoyhMSoeKCDKUgkdWa3YYs7j8Tid3MfSk/QkuiNBv9Pt7GxrqXJU2euLY1Dq
bxkv+V7KEe3L3SMPG36Y3+N/29ud+V+J1XzJCrfMggfvfSZHW+FRiaU2cW4wuirGakDHWA2WY6xqBsaquzLGaqKAsXofaUfkbwS1
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
C3Vpi/WLvYvPL760+FpSTdKmpC1Je5MeSHok6UdJx5KeT3o56fdJ7yRdTVYmtyXvTX4g+a3kK0tilqQsyVtSsaRpySMpcSnulJGU
PSkfplxPbUptT+1P3Za6N/XB1EOpYuqJ1LOpr6a+kfpeWmuaI60/bVva3rSH0h5Pm0g3pq9IX6en+t36jzNGMl7JeD3jUuaKzHWZ
XVlBWVFZW7KeN+QYyg37DQcNouG04SXDBcPbhg8N17Pd2SPZe7L3Zx/MPpx9NPt0zlM5x3PO5LySW5fbluvOY79R3JDXk3cy71ze
a3lv5b2fX5E/lv9w/lP5p/JfyH89/3IBLagrWFPQWeAuGCnYV0gLHy18qvB44ZmiU8UNJU+UGkpHS/eXHio9Wnq29ELpe6XXy4LL
5pdllh0s+3hpzdJ1S3uXvr30anlB+YHyJ8rF8ivL1Mvilu1Z9uCyw8tOLHtp2RsVjRVjFW9UfFiprIypXFN5rvK9yuvGCGOiMc9Y
ZWwyOowjxqdN1BRuKjE1mPabDpqumRvM95kfMU+YT1rmWfQWt2XUst9yyHLUctZyoaq9qr+6rPqO6pdrFtZsqdlb81DN47Xq2rja
tNqJ2udrr9bV1K2rE+tO1H1Yr6yPqU+pL6lvqG+vP13/akNoQ0eDt2F3w4GGJxquLi9aXre8bbl7+ejys8svLH9v+fUVoyveW5m3
8uGVh1ZebsxpdDSeXGVYNdakbNrSdHZ11+oLzfObG5ofb1nYsrXl/TXta8S1jWufb6Wtea17rBHWHuv5dVXrDqxPWf/Q+sPrj68/
t/7C+kvrP2kLbpvXltZW0lbXtq5tU9tI21jbQ22H2463nWu7vAE2RGwQNhg2VGxo3NCxoX/DgQ1PbXh/w/X2kvb97Vc3btm4e+Ph
jsSOj23zbOU2t+2g7ePOFZ27O492Xuh8y662p9lz7OvsnXav/Uf2tx1BjjTHqGOf47TjqjPT2ehsd97vvL8rpetMd0336z0lPQ+4
gl0Pb4rYNLZJ3PTq5pTNDZsPbL7UC70X+pR9hr6qvn19j/Yd6/vQbXRvc1/zlHnMnvs9Z/vn9bf3n74t87Y3brviLRnIHLjoS/a9
OtizJXHLQ1veGlIPGYc6hw4OvbG1devR4eTh14ZfH1GO6EeMI70jD4ycGLl6e87tZbdvu/3ktvBtBdt2bHt821PbXt8etD1ue//2
c9sv75i3w7ijd8eWHU/veH+neeeKna07O3f27nxi58ujaaN5o+WjB0ev74rYlbgrb9eZXed3Xdp17Y7wO8LlrzXQo9APKviO9BWI
FGgGPAHgzvBoUAL7Z7J5eJ/wf/2hVu4hfaqxRPjXijWwkmMFzIU1HCshHDwcqyAMtnOsxvoxjoMgBB7kWIsyj3EcApEgchyK+DmO
w+B+eI3jcLSti/0kYaUWS/vJKMcEQukcjimE04UcszuYnmMlzMezX8YqvBeMcKzG+gc4DoIYvBPImN0dznAcAsl4xss4FJIVao7D
iKDw6w+HPGWDydM/7HV19/iEHEN2odDc4xSMNm+vZ0ho9Ho2Oe0+oXLQ1+PxDggpPT5f/0BJVla3y9cz2Jlp9/Rlber3ZXVK4qly
ryZn92CvzZudmWcoKm1uMlpL5foM3sB189Iap3fA5XELkvhMwWavq7NzWGge7nfWOb3OPoRSjd8In1SSjLhJVXOPa0Co8rh9wmpP
l2/I5nUKWNHrsjvdA06HMOh2OL2CD31dXdsgrOx3umXhBllAL0wblp0pSMp4X6bGtsXm6rV19jqFIYyEYBOqKlcJNl+JwAxBOwbs
Xle/D5ePqzfT4+3OWlnVcOsWMGH+9cMweMEF3dADeOPC97UBsvFFI2Cm94ATuRFsKNGLskNYakTsgU3YYpfkK2EQeQ/WeWEAyymS
Hh/qHYASvJFloWaXJDEInZCJvTzQh7WbUMKHvDNAe+qMsZpwjG7s1SvVZWPfPLStCErRsiaUtCIKlM+4ocdMu2e2rcESs9eFrW5s
ndb+eRqbpUh14t9hKT7D6IMT6iRdTvRKrp2WuTESvoC26Uh8MSk2Gy4pwlWSzSz2qxF1IRqSrGNzJUv0Irdj2Y0lJziwZhCxQ7JT
kObCKfWuxRergHtTvyQbqLlhhgY91twsYoyEAMtmjuu3xgZbkFxSDDvxk7UM8ZxgrWzcSlglYR/GQJiKiByPAdTJIsLyZQBHHJB0
ZUoZ143tK7F/w/9TH/B/TXnyGfa73j77B/d+9t9iKe5ai+FfiIJ93xzeuTUkiGjhn0kwCSGhJIyEQyeZBT8mEWQ2mYMjP4W7cBIk
w6cwie+tSBIFS+AvJBpfgyngJOy3d5wlc8k8Eo+39wVwjiwki+BXRCAJJJHocBWkAftdXUn4tkomSzD6L8CL8BJ8QlLgX0kqSSPp
RA8ZJAP9ycLbfxYx4FsAVy3JJjkkFzMiB18HvyZ5JJ8UkEJSBN2kGP6NlJBSUkaWknKyDF8Mlfiu/Rr8BE+RXPgr5n4+MeErqoBY
4CL8g1SRaigkNaQWV8SrpA7+HXpIPbxGGshysoKsJI1kFb45VpNm0kLWkLVQDCWklVjJOrIeV2UZvEva4GdkA2knG0kHLCU2eJt0
Eju+Upyki3STHuICM7jIJrKZ9JI+4iYe0g+byW3ESwaIj+CKI1tgExkiW8kw5lMfPAIWnLPreLR5yAi5HarhEtlG2O997yfb8R3r
JTvJKNlF7iB3wgDZTe7CF/ce8hV8E91Nxsg9ZB9mex38ndxL7iNfld7XXyP7ydcxC34DPvIA5ugQ+QY5AIPkm+RB8i3yEPk2LCcP
k+/ACnIQVpLvkkfI98ij8CfcAVeRx8gh8n3YivvDML6Bbyc/IE+QH5LD+ObcRn4EI+TH5CnyE3yLjZMJcoQ8TZ6B75GjeMKP46p7
H1dMC/kpOQZryLPwZ7hGjsPdsJb8jJyAVthBfk5OwijsIr+AneQU+Sd8zz1Hnie/JGfIP5Oz5F/IOfIr8gJ5kbxE/pW8TH5NXsGd
cB35N3z1/Tt5DdZDG7xHfgPHyXnyW3KB/A42kN/Df5A/kNfJH8kb5E04Bf9E3iJ/IhfJn/Gd+B/kHfIXcom8S94jfyXvkw/IZfI3
8iH5T3KFfEQ+Jv9FrpK/k0/IP8g18im5TibZj56llCrwfamiaqphP8uRBtMQGkrDaDidRSPobDqHRtIoGo0v0FgaR+fSeTSezqcL
6EK6iAo0gSZSHV1Mk2gyXYJv1FSaRtOpnmbQTJpFDTSb5tBcfLnm0wJaSItoMS2hpbSMLqXldBmtoJXUSE3UTC34tq2mNbSW1tF6
2kCX0xV0JW2kq2gTXU2baQtdQ9fi69eKt7eDdB1dT9vg23hbioJoiIFYiMPb2DyIxzvNBtpON9IOaqOd1E4d1Em7aDftoS66iW6m
vbSPuqmH9tPbqJcOUB8dpFvoEN1Kh+kIvZ1uo9vpDrqTjtJd9A56J5yAK/ARfEx307voHvoV9gME8J2/EJ7Ee9VjkAiP4n3tK3hX
U8McWIb3pVBohw4ohwqIoHthAo7Qu/Eceh5+CU/DM3AUfgo/hMNwEn6Bd7FgOkbvoftgN/wcNPReeBz+C+6i99GvwgF6P/0a3qw+
gMtwDHfRr0ICLIJvwAPwdfgBHMLdtRL2w8N0P/06PATfgu/jTe5BvMWdgWdBhze4vbAH7sGb5z64k36DHoCN8A7cQb8Jp+mD9Fv0
Ifpt+jD9Dj1Iv0sfod+jj9LH6CH6ffo4/QF9gv6QHqZP0h/RH9On6E+oSMfpBD2CN+XfwZvwOpyH++D3eNv4I1yAN+AP8Fv6NH2G
HqU/pcfos/Q4/Rk9QX9OTypXtDQ0qCs7vc4tTs2g25VtqbTI3FjAuYHzHM7zGDdkm8xcPo9zE+e8X2UR55Wccz2VOZrKPpvd63Fr
Kj3dHrdzc4jJ7vLaB/u6ep1bg00Oj89mx8uXT22221AKmddj86ktUkkaOyeH6zZyW018TBMfw8RtNeUFW6b08S7+rpUaCzfDIpvB
600h1QHmVE91V9bgzTekZrqND8HdMxVparm+Wlmfutbn6nU4Q+qmu6gbbPZBn1PdMO1Ldq5RvUKuXSHVKizublmlmXtj5iabuVdm
HnGz32seeZNFtRKv7m7eyg2z+HtxKTOPmcUQtrJn0N1t8w729doGfZqVsvnqJtmaJjn6q6VSyOqZfhuyi6qUzRgQdbMs1hKQQRZu
n6VA1TJtj4V7UcW9svjt43ZZLGEtM+xp4eFskcOpavG63N3qFimo6rWyWWunzdKudbjw5TDgGlCv7fbatjhDrDfOVVWe2io18SKP
X1WRep2kLnjdjGQxZOfk8DkqkHlevszzeblAbs/JLuK8Um0LXEpVPKcKOc/mPJdzrs7Ep6Qyn3P/0uL9Kos5N3LO9VTmamw8SDa+
lOwBuWufXkoOeZacgWuIKzVyI018MBNXbuJGmvKDnTeuIX9Xo8bJx3fOWENmeYj8YpkX8zBaqtTdkgUh3QFmdt8QdEu+sgczi0e0
KqQnYP24pOhqXZm9Hntvc1M9N5HHxVRMXZs0Lm6Siy9Dl5QxsrrcwpBNN2aypVjdK6d8b+CyNCl70TC1W25yy2vTiRnoCZhhMw+W
mUfEzINm5jNp9geVz6ipSuUJWKLcbou/F5cy8ymxZId5ZiwJj+xaiGeg1zbQI1vm5Uye4QF5XQxMO6n0sWXqk5sHp2w3ZPu3EQu3
1VKoGgxYrtyjKu6hxW8rt9FSFTY4w7ZBHnZ54eTyKBbyhcMXTD4vF+Ty6eUZko3a+TIflJb5oLzMh2R3hgKW+dDUMh+Sl/nwZ5Z5
vno4cJnzOagqVo/Iy3xkKuNCeL5mGgzZITzhGFbZMm29vhC+qhgOqt1Yl9nr6rYFd23s2uiahr0SDOreuEkGLg6UtswBu9YmjSgh
KfSIgvmaRxhum7Ydi6E2v29SB8kH1oEvcglyiwbsQTYWKElQihUilY19KjvZh5212KdGt0vzjwh3CKfD1dvLrAub3iFYFwd+qJ2+
Hibv8MsjYscva5cUOadUOv0iwXw/YQ45ZzrkDHAozBk4mtY55Z5z2j3nlHvKLvYh+dc9M3I5uUxZ9wzTmc0atmuwgot1cvntDHfN
NMkVYFIoE/XvJVqX3yKVaxMbzTVtl2vaLtak3DxlTW4hK/eyIXunQtM7IzS4l0iV0qJl0n3sQwque6qLe2aXvAJpMuQJdvsnWOlh
Rc+Ua56ZrnkC08fj9yZixh7CRvBMOab1+I3SeqayyCMN1c9yjH0pkMkpb2MfLLpa75TJ3pkm50uRkMYemJIZmMq7gem8C+Zrn8kz
gzQ+eea0vpkaC3KnhY1MeJAJDU65PzjT/cFA9wen3B+80f3B6XkdnF5Og3w5KbewjyGmY2hqpKGZIw0FjjTkH0nJ2pTDrG54qufw
zJ7DgT2Hp3qOsOLIVNRG/HEIGwlMc2mvzC2WL+C58q3AkGs0aUacXk+mr0uNvjDmG2IlnDyvk5U1XZ5Br8RdW6T2AddW1j6Aq8rN
gJN9QZgJuF2SAq2kz+H29AUxjRJgOhkIlrUyqJX0yohpluSYbklO1i5BWb8kKI0gIWkM92CfVxpDAmwMBvgYDMpjyIiNIcmxMSQ5
eQwJymNIgtIYDEnxMci3FeQ5nEtnT46hMI/zfM4LOC/kvIjzYi1aKOnvCZUsk/FACLOI41DJFF6Qx5FvcTmGbMOcnuH+Hqd7o8yk
00FqKrRw0yoNSsug1yPLGys5l/vzMxK5bGd2jmxnjqGA+5Ov7nO52R1gwGn3uB2yVHau1jngwy3M53Socf/GI0w+ao0mzo0yN/E0
MhRxXqiV0tLu6evUShnJEG8zcp7DuYnzAs4rtdIuEtAjL6zH49ls6/RsCajN5v2zczk3hmKedzp7PUPTQjlcaU4h59zA3HzOeTu/
Y+TmFoVweens9m83DHMjkbIDsCEAFwfgXI5zAuRzAuRzAuQZ9t9lOuX/nzEJs+B/8ydO/kufx+6fAEwWTSOoxr/lUE4rAWjN5N+n
y6xm8u/Iaxifqj+BciekvsX0xORVxJOT/5gs9o+haCPHGYmgF0RoabVYBaH+GISvqhfVq9e1innxYoq1o0sYa2kVaZLt2SAIArtd
1xmfkCCCVQSTzjyBPpo6jBki0YtCR1eGSPW6BF1ChqjQC44jiqhoMJrESJPQ0WEcp1Em43iSwiRSU/NWQQzVITDZHKKycesEpRTV
iAnO+QmsdiI8mhjnCwh1xolIEoltOhEaW53WiRhCpQGVelGRLkabWtl4YozJxAXiBYcgnmoUlcnrJlJImMlit4hqS2uCqEiyNq1v
ReH4sVZBbGzEqgqUFosYKrJahXFZGi1KwSpeEkQDazcwyVONrQJGY8wmsJ+K3IE1AmsLZqiAoYKO+A6r1RqP0RJDTXYRmlpFkH6E
cgKW4+vFhQwtrLcdiwA7kzimgk6r1WGziiTdauUeWAUH+qMzWjNElV5AC5RJNvRJY2psFTU6oxikM+IMYJeODFEthRsjITjGNZ1G
gTUyd+Nl89mnqOqw2EVVWgI2moQxYQzHGjeokjBCq1o7GuNtTdZWnTXBKogVq1uxLZ7FhZuSIWr0otaUPgFUnuYgLOqMOkwXndEm
0s4ukdjREFGTliFq9QKzNhzdUkKnwDSIFR1WJtJhlqwN1k9ow8FkMaYlTCVOiH5mIoXKWkg6mmBC1zsEy5jOxiZVCjbEswkRhXg0
0m8lTq3OZpaHCLtFd3Ex9oL4adcCO4XrJYeOhIWCwoKjxOsSrGmYxLP045RaRIfNnCFG6FFUEMRZpjqmAAHOkBjBSk1YipDmazYq
ipCCImAM7DiyONvUIYx1COJsDFuGOEdf39w6rnSYrYvFMKdua4YYqa9f1Vq/Wq6MT8D6SKk+Sj8Oc0wtreNz5phEYjOKs9PZksPU
Mo7PYh8R+CGSGJwLRVJj6zgLH/prHMMZxmEj0hJ02M2P4+V21gVXMquxoifVaH811s6crFtM4ThApA7jZRKhfIIQIs1WtB7GgVqa
W8U5OqNgEcMx/cJ0mHKYilFY04E2/DQujsBsiASj0cgiEYWGYNt4VFC6eE96fCLGLQadjU7PEGP144TxOAw843P14wrG5+nHlYzH
68dVjM/Xj6sZX6Af1zC+UD8exPgi/biW8XS9zj8RoroDQ64TMkWygS2bDFEf0Bgz1Xib3JgR0Jg81eiVGwU9iLPSb+Uw8/UZ2Vfm
aKB/CeifgHYlon+M69A/xhejf4wnoX+MJ6N/jC9B/xhPQf8YT0X/GE9D/xjP1AtlUuZm6XHYuA4Bdz/SYZLmFldjJkteg17MShez
cGFm45qoFm4xrTpbkY7t8J8rEc+8z/HP9Xi42sJST8xOG1eRaEsr7o7My9yA8NxKJk8v5EuW56M2Wcby2TFx/d7UFlYPMU9LB6W5
XFc0nkeima8FGA904Ob246qxFWWIhfrM2LIMseh/EsUMt6N4MU4RxCQJmUI12xswtLVjY9W6atxMWvEExO0Xj6YiQqKjMMIluInF
iLEopsR9NUkSGw8FoxhiSneOZeoEoWwMdZbOFBMyZX2iGlcDlxbEDra5VKxqPaIUVEL8EWWyap7VyLbcYNy9dVIPXVWHqDbduG47
2LYnH09KU4cDkxJPV2xWmmzxiDvYlndjHxuahgeBrgrnWIcjVLGjK9gkjYL6bjKITt5c1biIcTJUmHCqz2hFjcyIJGaEAj/5ljo9
FiZCmT8WAtaqknksdGUYpqVTTWKw1F6lq2aDslksnwohc0aOtAjNrZlCGZ7szHpeKTC7+FSI6iQs1QZeYuRJvFm289nSsZRfFmCJ
yT9dHeymc6PL/imuwP0jk0WxSow1tTbG4+EqlFkzxw0kCtdt5YzWpvjGGa3Gm/b9vB4mvViS/nkDmvViafoY2sZyDJ26pShOaKZo
wB4WyWWWn8ly5G14UzPKrrME1eHyycSVJ+uv0o8H46Hj7/K/TOnqLyuLmU9sHyvT4VYVkC8JVm5nNW7AJen+qNRgqTQ9Qcfjwr2Z
CkEthiBaXvZ4LcEVHpkpFuAqr7tFfT2qI1GRYiHiBr1YjGw5i6IFwy1U4Qnsj9YKPUtocTnClfoJgCoEjQgIA6v0E0SqaUIg1axm
MtUImpkMAy1MhoE1TIaBtfoj7BeiIWpFRCRk1R8hct06RHLdeiZHGGpjchLawOQk1M7kJLSRjWlB0MHGZMDGxmSgk43JgJ3J1CBw
MBkGnEyGgS4mw0C3ZJcZUY9kF0MuyS6GNkl2MbRZsouhXskuhvokuxhyS3Yx5MEYl01NYL9UEisQ3ibDSoReFnSpZMTSAJ61XMYn
QyYzKMkQLrMFOy+d0joklaQeW2XIegzLkImPoB4ucLsMmcA2GTKB7ShbPqVvh1SSxHfKkImPypCJ78KeXOAOGTKBO2XIBHaj7LIp
fXdJJUl8jwyZ+FdkyMT3Yk8ucLcMmcCYDJnAPfqJEOmKK6rjJ5RUYcHXE26DVmO6GOQUFYsbt/oPa/ajcgAfg2eb8GpJ7sPjTt45
+8dBYzwKlnxIUEEaK1SE1ilLgjLVyco4jSqYV62gRnWeMo0uUklVocaTc06Fnwo5pT2lrgAVhGDdbONJqJj6y+qeBQWmx/hisncV
Lu29razsMI+nsPKxIJArAG/J40tY1fGgUSDKir32Zn+D9MteQhtomdqgTKHzVKrwtGNk8i5ReS+e5eYjKocazGb//2AF+G/VkUZQ
",
  Bold = "
eNrMfQl8VNX1/z33LbMkZM8kZM8kmewJZGVNJoSdJCCLAqIQQHABREDcEcW91CJSt1pFtG51wR0VrbVUrXWrVUqJCypapdiqVYsL
mf/3nvfmZZJM0P4+v+XPcM7cue+8++492z13exEkhEgC0kXe2BmTJuAXCbr9YXy7J4wdN370q01vIqsCv7snTJs64w+n13wihMTv
0RsnzJg1ZnhZ52tCNO8QInHU1BnVNbNCt30gxLQvQb9g0fLOlQsLgqcLcdRMIcyqRWvX5PnjE+8TdG0hrm9dsnLp8psaUl/H711C
xKUu7Vy9EvkJ+J2lnr902VlLYvTYfCGOuUhQyrwTT+hcnDjygUxBp+zD9YYTkWF8a/xT0LJ0/C48cfmaM2fcWLoCv0cJ4d2z7NRF
nVcsnJAi6IwUIYwVyzvPXKl1x58n6NyLQJ+3onP5Cd6b370dv2/D9RtWnrp6za8W7D1f0IVBIVK6Vq46YeWK8zeNF/Srt0C/Wyhe
xQr17y0hhR88y0BethgGPELMAJ4lVgKvEZuBt4jrgG8QvwN+TvwR+BV8SLwm9gN/RG5B5KUAcDnVANfRUcAz6BjgObQU+CQ6VUha
SWcjfR79DPgquhn4FroD+C7aAbyTwD96g/YA76X3gf9GfxMkJ8lJQso22YZ0h5wKPEvOAl4hwR95qfyl0OSv5a+B75UPCw3tMZC7
Bff8XP4cudfI60GnKIgpJGsG2CpukwEhx45vmynilnWuWSFywAf8C4VQCqQG+ZUIs2XuuDxR19oyM08EW6cDt01pmZsnZs9UOYtn
Tp+SB05Z95DwiEQ7LVF+kp3WRIxIttM6+J5ipw0xSKTaaVPECZ+ddol4kSbSTzlh1QqxmfENjLcxvpvxg4yfYPws4xeXd646RbzO
+C3GHzH+jPG3CpPOOI5x+vJTlp9CfsZVjEcwHs94OuPjGZ/MeC14Eubdf/Vb8UVjLv/3pHTw0AS/3P8jaQ8k5Rd1YpQYK9rETDFP
LMaT3aCYTZJyaAT/MqnNOzdubMKexN2Jh7hWlPit9Z08z/pOWQsqfFduFqZU3/uFCRWjaq/1u7pQ0JAypk0UFaIGdjhGTBTTxWxx
vDhRrIAdni3Wi0vERtjjVljGgdBXCqOWEulv6WDoC849zL+30mehHT1UoW9UrnDJ6tCNEbkHYQ8i9G/gjNDHCotiTh9mvFdodDj0
lZQiWxrQUimDwifHQEdl9e2qpjXv1xxkOYjQR+xJROgArl3H1/bVfGxfe8u+9jSuXWTfBzqVCv0mdEjY/0BH1cuYA+PFNeJGsU3c
Ke4TD4snxDPwOS+J18Ue8Q78zQHxmfhafA/+uymOUiiD8ihAFVRDw6iJxtJkmkZHy4vkFXITLP9GuU3eKe8z95jvmPvNA+ZnLuly
u9e6z3Vf6L7MfaV7i/sG91b37e573A+6d7ifdu9yv+h+zb3b/Zb7fffH7n944NnEesXb/y/w9aEPjoCblOTE9dBelfO2nT9F6KEP
hQEwAS6AG+ABeAExgFjAIEAcIB6QAEgEJAGSASmAVIAPkAZIBwwGZAAyAeehbusA5wOuhhy3AH4OuAZwLeA6wPWAG0IviV8AbgT8
EnAT4GbAVsAtgLtx/z2hL2hl6EM6LfQWrQKsBqwBnA5YCzgDcCbgLMDZgHMAv8c9zwGeB7wA+APgz8h/A/AmYDfgL4A9gL2hl6gL
8BbgbcA7oZekP3RYFgCujeRfJA79tT8mL/i6AXzdAL5uAF83gK8bwNcN4OsG8HUD+LoBfN0Avm4AXzeArxvA1w3g6wbwdQP4ugF8
3QC+bgBfN4CvG8DXDeDrBvB1g8gKfSuyIcccQC4gD+AHFCC/CFAMKAGUAsoA5YAKQCWgClANGAIYCqgB1ALqAPWABkAjYBhgOGAE
yh0JGA1oC+0Us5A3BzAXv48FzAMcBzgeMB+wANAJWAhYBFgMOAGwBLAUcCLgJMDJgFMAywDLAacCVgJOQ9mr8X0GNPRMwFmAswHn
hh4QtyP/XviL+wD3A7YDHgA8CHgI8DDgEcCjgMcAOwCPA54APAnYCXgK8DTgN4BnAL8FPAv4HWAX4Dk853nAC4A/AP4IeAnwMuAV
wKuA1wB/ArwO+DPgDcCbgN2AvwD2AP4K2AvoArwFeBvwDuBdwD7Ae4APQ7vFR6Fbxd9Ct5In9CJ5ATGAWMAgQHzoAUoAJAGSASmA
VIAPkAZIBwwGZAAyAVmAbEAOIBeQB8gH+AEFgEJAAFAMKEH5pYAyPLsc3xWASkBV6HmqBgwBDAVAN6gutJvqAQ2ARsAwwEjAKMBo
QBOgGRAEtADGAFoBYwHjAOMBEwAT8azJeMYUQBt+t6P8DnxPBUwDHAWYHuqiGYCZgFmAowHHAGbj2hx8zwUcC5gHOA5wPGA+YAGg
M/QBLQQsAiwGLMXzTgQsw73LASuQXhnaQOeF3qZ1gPMB6wEXAC5EO6/C92bA1YAtgPsB2wEPAB4EPAR4GPAI4DHADsCTgGfwrN8C
ngX8DrAr9AF8xzb4jm2yMPSYLAJUh34jG0MPyHNDXfKK0NPwKdt6exPU8Csb67JUuHHHF+hZY9Czum2PfSysoAsWEIIFhGABIVhA
CBYQggWEYAEhWEAIFhCCBYRgASFYQAgWEIIFhGABIVhACBYQggWEYAEhWEAIFhCCBYRgASFYQAgW0AUL6IIFdMECumABXbCALlhA
FyygCxbQBQvoggV0wQK6YAFdsIAuWEAXLKALFtAFC+iCBXTBArpgAV2wgC5YQBcsoAsW0AUL6IIFdEH790P790PTu6DpXdD0Lmh6
FzS9C5reBU3vgqZ3QdO7oOld0PQuaHoXNL0Lmt4FTe+CpndB07ug6V3Q9C5oehc0vQua3gVN74KG74dWfwOt/gZa/Q20+hto4n5o
3zfQkP3QkP3QjP2Q1AFI6gCkpCQU+nF9K/28f9+gelj6q9XP9u8zBu45bGzSuaHv6BLAJsDW0NN0F74fD33HNULEFjiooqHS18sz
EBNmqygy9PfQG6G7Q5+G7kRf8/fQP0O/DP0x9GzoUfz6QBzxH9opQgdDH4X+gu9/cc5h+8q3ob2hw8CH4JH736e0pufXn0PPAb/A
6ecBD4ZeDd2KOrwV+iL0Qej5H6rFEWvoPD30Cco64Pz6QEWQoVcdwhjO/WKAUhBPhu4N7UY0Yf2+Eff/MYQxeeifamTW619cRNpt
3R36HPEMYuLIVuP3Z+DQ4QGeaLcZUnkb+O+9eRB6IfQNePPpkSQTOmDdA5lH/os/ArM0u7Z/h11F5WU0WfKVV0L7Izj9TOiesDyV
RuD3W6Ed0Kg/KfmG/tBHLgOV+ZVq/RGuvxJ6N0Kevw89q/jE6d8AfhHahc9r0M6XQp+Fn6PKVFKG9D507twdeqdnPME5f7e4Fubc
QDLia28qXilOh74EfIfnhe/62KGJvN8U/73/tAGvyIL72NIzSg9AJ9PYAv4FSbwZ+gocOPCDluNoHO46gHu/Dalx4Y/5Zzoykz9k
lX1bE43XiHPCqQOo+SGLxrKlPtptWfYh1TpQ7scHsu/RZljNA33Ikxy5xCC63cNezBW2ecUzeMFvI3XStq63bOv6Ilzyj9CVPnUN
dQ9IOhjlv9szhg29D4zf0FpCfH+grx6FXgy91yMtxgej8caheb13i7jsH9II+R963mi+VOazTpacXbINXE5kb4MeAnazBx4CXiJK
Oe+GXun1+w7c8Ql8yhcRWnHAlpbqPW7s5bEsKf0z9FqvMp5BGcrCPwrPFISehgf5KoLiSVA8xVoUprgHfdIXPXwKPWzDV+HWhh4J
PYr+QChpqX4gdBd08RXU4Vb7Lpn3AluktzSFZ+8gN7us72ws87bbNpsDSUvl5QTlbcvbAepYsU5kIXc74FHATsCzgBd43pTEG4C9
gH1q7hRwEKAikEOAbiHJh0dsBlwHuAlwG+BuxBp6H/ACEhwwQLMd5T2K532Ez7OAF/C8j/C8vepZods4htjE+MbQ58CPq8gntJlz
OqQEvovxM4yPY5zCeCLjMVIDnkqImkJbOOcoxssU7n6S0ysZr+ecOYqyezGnF3D+owpTvJgOnCznAWdBbkSD5S7gExnPVfWhuXIn
t1Glk9RdMlFhFgPlDsudF8FpNTt9E+A2wN0/mvNSKLs+G7AecAlgI3PekkgkhKUThs144k3/X3G0H59ygjlHQydi0S5oaCK4kQhu
JIIbieBGIriRCG4kghuJ4EYi9DARLU1E7RPRwsRuQUm60JL8QiRCDxOhh4lobeLdQk8qETIpC2lwOcnbB6CLSb4w0KOJDyc+kX6d
+iD1jJPqyXvOTr2U+LqTt8dJveOk9ke594CT+swppSfvayf1fTiVJPuV8lJPeUluJxUX5WlRUkkpViopIynPSQX651nfnFfR9yrS
NU5q2MB5SU1JY53U5P55Dn1T0jQndbSdmheRt9BJneikVkR5xljn3p68NU7q7CPWYL2duiRpY5TU5r55SN+U1D91m5VKujtpe3o4
9aiT2pne/2o49WxE3gtO6pV+dG8k7XXy9jl1+chJHbS/v3ByDiV1h1PJupPy9r2anJDss1NZyX4nVRIlrydVZafqkkcABzk13km1
Oanpdmp2RN7xTmqxkzrZSY1w7ugpeaWTWtuPrue5P3THuVHuDacuTL4M+ErO22LlAd9gt3Jr8u1O6p5+eQ8m73BST/fPC8sDebuc
9Iv292vJu4+Qeiv5feCPOfUPJ/Wlk/rWSdl0KaLnjhTTScX2pesp74fuSEmKcq+T4lr2yQvfgbLTw+1NyXFShU6q52qZ/T0kpcFJ
jXJSY/pdnRhB1+GkZjqpuU7JC5zUEvt7WUTegn4W71hPhLb3SLpHMj3ydfJSVqWc6aTWRcm7yE5dkbLJybvGSd3opLZFufdOJ3Wf
U0pP3sNO6gkn9Uy/Uq6IKO85J/VS/6c5/Imsgd3npexJecdJ7e+f59y7J+VA36tI271fytcp34dTyvL65jn0X6dKJ2X3ealxEXkp
TirDSeX1Ly+cSo3ryUsNOKmKI9bA7t9Sh6U6/Ubq2CipyUdMTTvSVfv30ZEpS74qlTrPSiW9kbrQoTjRSa1wUmuc1NlR6OxU6vqI
Ui5xUk7/lro5yr09dbzJSd0WJXW3/b3dydke0b5HndROJ/Vs/6vhngl54R7xUOorTg82on9eROoN+869qeglUz9SKaWnVir1oJN3
wMn7wk4disjrDqd8upPyOlfDJR/qeYYvwUn5Iul8WeEacOpQT566w075nJQ/nOopOZzylfjQ6/rqODXCSuGOoH11vK/NajlS051U
OG+273gntbh/XpjfyDvZTq30rY2SOtdOXeiD1fquVKlkJ+Xb4qScPGWrffJu6Lnq2+qkbu9Fd49T8j3OHfc4d9zj3GGlHnRSl/V9
Wo+V9Whij75EcGhlBA+O79fyCxn3aRs/l5/h2+Hc/bSTcnr7iKt2v+97zbfbSb3lpN7vd/XjCLp/OKkvndS34ZLThJMy7e/YiDzR
15tFepq0JIfO6ZPTnB47rTDK1bIoeUOi5EVL2X132qi0MU5qYv88h97JQ7rDSc0cOC9tbtoCJ7Wkf55DPzdtWZQ7elKrjnDvmWnr
nNRFUfLW9fA47Yq+qbRNTs41TupGJ7UpSmrbEa/aqbQ7nZye1H1pDzupJ5zcZ/pdfS7NjgXSXk/b46TeiZIXLbXfKfmAk/rMSX0d
5er3UfKipNKlk7IjgPS49BQnlRElL5zKSw84qYooedf1y6tJH3bE1HX98prSxzqpyU5qWpSrR0fJ60ld1y/vuvR5TsrpsdNPjHLV
iQDSnQgg3YkA0tdHuer0++lOv5++OUqenfr/Y/6o+zk6HJ5FCk2VFYJoKs8ldfD823JtLfAqXc0xTg2VqHxtMXAu53TobcDt2vec
D0o5Tvst0nu0g2r3pl4MPFnPU/RcTod2v8rRLgDO4Hm/Wn7KdL5ay7iCc+YzruOaVHK6na9W8VOK+Cl1XJ/H+FnP87PK1LNEiCkr
+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
XrL2/ck3HR1Sf8knKKaJS4OZo+vrNMOsUhuciz1SEwWER3kl+gtbn4pcpGa2NUOcJNTWZuF2h3XH44nQrNKB6VjHPJ4eHYub2q42
RaeVlBQVeaNuio6uawPuje6rhLJcqZURVQmNzUrnNtvz5fkPR+rkBmti/PAHUdVyqj1vXqKulhjdTb2VVK3XHpIkYzB+rhWjgyNK
lYcjoavNk5qzAqrW+Ho4E2ZKIBCoDdSkl1QU+flMqUvtCEDA4Ktt6NkyafZiiS+tEEGCWjcoDqRCN/FoxAB/NNHNZ0wLFqmF7YmG
nn9i09FnZKTGp62euvisQd17UuB878WgzlOZTwnVsUZKyjCqNfUJhi7N0sqO8TVHNZZNmLmm89iRg5INI5ty8i19stqm9Ok12/8/
GJH/pJXP44tXeo8vmC/jmC/Nol1MC7a3kqFYwqg6S03h8eEOTai+0V6IV2tTdpisdhLY86bBYLA92DZ+3OiRFWX+vCK/Wxn2AKzq
uwLYc5SrdzfxY5iY0V7lMip1p6Nwm9xTDDWDc3w/jrX5ZbCPygp3gtVNmDribc3MDWjeKSP6szwKvzfS8w6/5/GY7DV7TPZrOz83
gr4YY6KzQ/8m+z5bHv+2x3tcNo/PXrPHZ9udspN4fPaaPT7ryScen71mj88i8nl89po9Pns2In+vk38ZLYmoY4yjK1zHaHWLaPfl
6u/0OflfO/mb5ayI/Aec/KvUnk3WubH8rDHwc9ODU8dH6FwNqZeXa9I6RomoLKrWwf8uhOq1aB0Yjk1rnTppYrCpoiwv5we07ggH
sOoK/mPFyzxqqNSHOgey1GitzqNVS61pduqPUzx/uUsW5iUkauQZap/PiqnCkC128vAj6N0uh5+b6GnmZy76328QzwXUW7mDI7IQ
y3pI/VkBPi8PL4d4Tm2fsV0bn5e3u2H4yPriuoyKQFGB8m2FYT/WqGYKuc9Vrju83y0cvJm8rlzgV70v+lv6JiF9dcfis+JMKWOo
HsGE7s6cPNZilK7lWW7u16kWKzCY81T6nx0yYcbqzkB1rCZ9ScPqTBAaul4CL1c7fiM32oxz5ebb8Wo9vSjVnqFhwfpK0vRhfjQm
O04tnbepLWDo29eHN3w1c7RqD9gDUxCz82KOr9beHgSPU99YF9500Kt5PaN2Z54UWkfaCcdOWt/RGvTobtfwhrHTWocVVphkaqXS
gHloO3jSdBHw1eTWE9dNm7R8RIoWs9g0KLFpRH1bMgZ8muGSm9Qg5kRFvMhjnm3Fkqpdyj9/YPvn29k/k+OfSb07gk6QTyOqbA6O
KoVEh+ZKzYhYWId/Ngw2DLUNHWrRiRprzfYae2pDQC2z8+H6H1zChh92Frr5nTW1tXS8y9qNpjrkkaryI43ArCkB7oQLMo1OqVkL
3N0XMxvOMayfvqZx2ZIPK1FmYYy9Z6ooNJLHHeWIcE4Meoth1j7STOlMeyq9VBvOm9UZYdbWnl3nE4inPfmi3eBx0cnmBL0lFRh2
BvK52T2RsiX6sOSjBDEJaqTSL5Rcwa2/9oyCcq8eV5gTHKfLwKSW5WnxSamLx7SXSl03PGW5OWXeuFhPZW5emZu+43W9DSsNil06
SJrDmhCulDaPr5rUMXT05CroTHp3V12uPz4zPz8zp3ZYOr4z+NyQ4o+a7/zImu9c2X++06J50qZROrOv35yhRbPTouH+aW/EvXud
/MvorLBc5DjIZbiYKx6zZJFeRh69gUzPOGia2eTB1cGkedWOT3XJiHbJnjMod5PpIuE1EW16PNYYelx7DHm90SRaHUFtGM3tfIsY
+I45wZQRI0bMHTHnqKmBNB/PLvQ5vJf6YyQdEaDqapdMQ6Ql9BlOyCaIc7hxBAWwzGN493dlbvV2BGvXh+6K0AqqtuLTO46kFOq2
Z43H8jMSkqxwVk9M7FERa+xeB/QFrwk2BGszMML0E+n8xw61tvDemjDPJdkvZAB1IFAUKDKt3TY99s+7qBKjzsbQpoXcrMqiosqI
YSOVHiW9C2d2W16vvKSmpqT7zZ45l7c1KdXCDL9HUNWzVUWVQ0qKNd1ozJeaPjpDurUmIjfX2VCbUl2kudUfOeVXJeBKp4fc7sja
t4oxAT6oGcCQJOeILRjwhGaEekRtnVGlql9lezp2ZhcbR2htij3gGKp+DbV/tFutt88q0he8NnjQttNn+637WTSnOjQb6WXxkEXz
UHi/2FDgV2GzMSJTdDyaFq+mqeyN7j61wZR7urHKQprtDUyZwRQh1FkaoV5B7WRjaCdE5uDkRBTlLVQ7UZMiXkcm+5z4PL6yoqCg
otLf4pz8lKMq/QUVFQX+ysO7wIu/89JgqqH+Sqj6S5VPoX/uc6a0+YhnShsjzpSqw63WkVfmiyrvIPuvz+3xzGA+P/lXcCmF13E+
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
Hw7XaYyJxB8UX1sUX5+SEn2xM8TXlzShEGD/MHsHcZ50snXQmHnmPOFkG+HbInNer3Byn4i43wAFU8x5EhqIUf/fh/Z16IV2Kkse
XScwt5d+pyPtjPYiP9lq7EU0Iq1Wfg86UtjlL9rld9LeVevfjTIC0MONsO8wtxMYM99QiJm3ByGaiibNmPlcNlaIKbCC5kFd8NrH
toKb+7h8itJTVL9R43tktodrd6iyfD8h91PtJihiokhT/oux/5KZw3G3otztMC6ZbF6KttUsD5CXYKwieApSj6jNCPWCmXHMU252
GBX/WTFiEaktNhAx8rQI5jNKob1lk0ZE0lfStrYOmNnJroCDkAeI80Yn2wajso05bwBd8+O+3v071G+KFPPEFQpSGRg3TqUnYIim
dFU9/crcXAhparTv60DT3ebZ7vuFXZoU2aXL66DOtnqdX9p17iSfMOrQ4jpxQQtRR8gev1j1+XeT4TWev2zXuY+Or1HnWbvOO8gj
pXWMnBTkMZghbRhTX18B49FSGlM/VhJTD/t8Iaa+yGPMchVVbK0l2KIqP+GqcTx6LVeVl2Tl3wSPuRkUaYf6B0Xlx/H6QtWB3y8w
4uiN9uCcPmTKaXdIK8spvb9bKip/wa5/Fxks8rsu8xM+F58k8zzHsNcNocdpmBg6C0aH4WYrybdIKPuiY7aRoA+UcUJBQzTMcpxu
TrQLa5xyLtY42FZpiV1S2CeE6FNqlNs+cUGdq8Z9dHpLhMoKiNOORKAlqbkUxZFubo5rRfpMCtbQ+Obp1Nxi9/DCIJMjS1+PtIai
1Y0trY3+wdZoVVMryjYiLnKM4hn9mLQDrf5pwpm3ihJlABYPetbKC0A8TjEizoi2P4FwyLJCTmDAiLzbPNGSpc3btszNjg53dsQi
gaYYcJCzxQOXksDe6doKJurVqYKO3Rb0B25/dSZxjrtt4giKEZ4nSqPmfNNKSl1sJZmxNsQV9DJ8sVw0FVYYaKPxldQzMe22CD+l
fxOy+6/JbTbW3RT9klUOdLzNzLHwCqsp5OWXFhBjEz6hPvtb4bd0vnSV9Il883kzVNe2Lo64ZEqO5zBd12Wd8Vio0afKTDZdmjoq
iK5rh1xE04Y3VBfcm1QYLEYPgPjFUDKpUqiRXBSkeqna8Igr/uUa1XeDHCpddcVFJw7t37Vj86b5dRP5oYGe7nQyEm72e+urKoUj
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
xyDM7WZpe7k9AmnjsWQNg30dt60R3jLGdvz12SJG+RspnjPwbsMWIcEUv5E5ZyrJhMJFqqBL8M+goi19QdgicF/pAj6L+Vq2SD35
TssWYQ2LJXMUJI1NizNTQwOZdtMSET5HS0TUjhs1hkcwJs9KcCXcW7v0ytnO9ulqV4VeK7NaDbjLREfHVJWrQquR5Vrnp2Gsappd
DIaCsSp/0LWDM8YbaqobOAyjp7rCw98XbvaGkrGwrzngr69iclWtx+9vCLZFWhsa/d6aaplV1t+qO52uSrcMi9spayCV/NTldFW4
KmtqKp2VVZWVVU4d995asc5xvo/ifPeC3KEJucOa78J17crCDDalEFjehwvz3ZJR1q6F8z0RhwkfNoQUgSxb7om2ioSirjrd0wuj
Q/OCo/nq3E0ybQxF81UargEg7C6Mva9qcnLKOW+obqggQ6FPdo+Y07wWdrlO6JM7EfaGIvW4CrZWu2orXVV1iqLXuHWY9pjvhLhJ
jj5FVHIa5qxf0h6T6OeI38YO9pIG6UP0Cbi/BPcb8D75HGmw7/tJE8mL3y/D/SbzfpN9303qSYZ+iaiIobjK/VrSQLbj89HRaJXn
V5Makqafh/u4pnzmfV9R+7ykG99PEVuwxWx/i33fAc8PiufLqz7fTepIl/g9t9rHStvngfd/De4rcL/ZfH5z0fvvlz7Epkz63G8+
//4i+txP8mzOpM/K+27yHpJhkyZ9Vt6vJafIdjZt0ueUef9UEX3+hqTZuEmflfe9cL+bzZj0OWW2/1QRfU6RoHi+vOrv3fD7Lrbe
pM8pkz6nitqH758x6VP2fIksY5aNq0Fvq5DqBBChZaCKhNFAZSSvwX2eAOO7UZHJPbJzXlXkpavhE7SrhxwO5fQeh+WDITGBb0Ud
IoayUXpJxGEuY+58837TyvuUmPeBu7NrMc8g1Y37ZMq4T4PG75dfYa5Vfs/JP5p5hV5hx1f5PadZYyzg/l7xe5d5v9+8nzRoDfcj
4n6leZ+az/+duN+z/Cfpe9J7RFTo86efNMbi9JMWLaX48vulb0nvl5yYp1b4Ju8UFjfMf0c2wlenpPUw1BgM6Uk44cRhK3Mdq2Cj
zDl7uOIlZ8UvRU7dI5iCk/y7FKN3EX25WnhY6KefkWrxncvV8E50Pz39jBU3MrX8Ael/yM/hFQ2G7mKjBQMD34nOJofQIXKzJDV4
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
vKNcMBRsqAVFIBk2BY9QBiwZTmRAK4ILQrP5R9m9RLsEtlW6DibZN5iTiGQz32T035jzmqd1chtlKgsTx98DSf6vbrTwTw/gOZOV
S6ZTOmXkd67rzARhuQuQcF+DBwaTLTTlPUWlwNGJr0Hg/ew2fuPF3PwCRFQ4J5ERtCSNCyjZMNxuMm+LGwauOJ20quSbVpZLB8Qv
GCaD1oCjIP64vhb+eCy6Iv2tkV8vV0OOloCOb9PcRcmFU5FQOy/CGQ9BT7PA9B4XgdafFKP7o3h3IkQGTRz1KP2KFJF60J7eCEsv
LlMR3GkcbJ/Agz9O5BMKEcxSoCkekpBTQg96ot3xVDQCDRYp8E2PfitPdV+0NIoIC2k211vgkOSPaeK4800X3zp+4ehoTqlsDA9l
BxSishhRt26/ft0bhlVa09/aOTXYTvvet8XjfPPD11+0/nivj6njwY4Wqh6H2cESO5aUzRs4bWwe6c6g/ZbDWvoDcPqvg54SkBLS
gDQt3Wd4gKWchIPwpHCCrvQOTXFcKPDR8XgKLa2I+etSqRle0bNKbWFyMSDV4RfoXil+ph5yEVWdVBGXe3AwmWxulqTB6cGp/Ghy
INnf3dmcaI6HQ4Emj1v4t1UK+b/Uv42WKIy1Wdsq3iOV1cwW3XtsLpWaS6fWpZJzqQ5Yrie5vl6V2dJdXJ+fSaVaWtPpVrIXK5n/
WtLplpZ0qpXcDb+A3+G/ueTSdQXfZ/KP6Vas1Zpe8uNv1iWTWCe1FYtTra1pyzdZfjPw9BBVTd/ibvwkp9GvG5jmabbBjL/8FnCD
30r1KITkA80NVbK84vysXqrrF+dnBlcoCAOCE2SNo0lx9PkT/kVKn+Dael1+gtIvyvpClF1CyaWMXUrIpVmN3IaaG7kNxOkbxcna
jdpfKS9zAtLky4y9bMiw0eWHmIu+U9ouXSL93fyjcRTgAkSjMSJrICnI40SRZkBhwUzzxTf0wo3dxs/ancQhcergJ4DpSZpMtRMu
XcDnKBiEpkCbd0uweR6SVEXd3JTvXllfknVJ3u0iOv5IB8mt7Ee7874dOyRpxyU7Lj58EJq8rR3E6WwyEqvAKHJPIcVraUCNmSve
OpU3MniaE0cxr7OFgyxLnEETN83mSsLQrYNAmr5vkbkObp6JMtk90Nw37WCyUlmzoQNN0ZS4ZlzER7zekRr5huNb7tyu0Rsu7Nzk
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
NqKlbH9E14Cl7OyeQcZhjHLB7nQv4QWYAH98FvDjUBfkhNiRjN+BuhROI2OYvgZA3JvBv4Q1MAj4KLRP5wKdE8NsTa9SLAL96dzY
BDGyAlUp74U5AOMKdqTX/meQreBX76EMBZzeMJziyBEUDXaheiP8ZTjV/RQtpIB/BO2/DzETsKIG9hLAT+0AoMJZdFM4/TXYoW4E
qAZIg/RtAI8CfAfgOOTBfnX6WwCwi5xeD2krAJx+g3AcD9L79OAEEKT5G6D8CEKX7gScALAI/QFiXRubL2noURg/O8g8CbL9GOAP
KA30TmYyPMqeyR6Pt9P3hQQdcCpVQDunLoOfAPyIw5NUT3bHo/z/MnobfYQ1eAG2Yjtuxp14FE/iB/Fx/Dx+Ff8ef0gEkkJySSlZ
TjaSNxRLFQcVRxUnlcXKWmWL8rAqTpWhMqsmVIdUx4RSYbmwUegXdgkHhaPCSeGc8Krwe+ETtUF9j/oR9ccat2ZAs1tzj+Zd7Tbt
fu0J7Vnt69qL2mmdTjdPZ9FV6+p1N+qO6k7qDXq7vlnv1vfqzxtyDcOGCcMhw0dRmqjVUe6ogajdUYeijkWdjjof9VbUe9EoOi46
EL0n+u7oh6NPRJ+Nfj36Ysx4zL7YbbEvz7HN2TPn4pzpuNi4XXEH447GV8avjj8dP53QnTCecDrhfMJbCR8mColxiRmJpYn7Eo8k
PpZ4KvGlxDcTP0hSJvUl7Ui6O+lc8rxkS3J1clNyR/Lx5A9SlClJKTkpxSm1KS0pPSknU86lXEh5by6aa5ibMjdjrnWufe7qua/N
fXvuR6ma1AWp1lR7anNqZ+pA6vbU/amHUo+mHk89nXou9dXUt1LfS3sw7VjayXkT82Pnj87fPf/AgvQFlgWLF5xc2LBwk6gTR8Xd
4j1Gq7HSuNx4o7HHOGzcZdxvPGQ8ZjxpfN54Pr03fTT996ZmU6fpxYxNGX0ZOzL2ZdyX2Zf5XJY9qzmrM+tk1ptZF7Oms3XZSdnp
2Zbsxdm12U3ZN2b3ZY9nX8iJy1mQE8jZk/N4zpmcF3Ney3l3kX3R2dzc3NJce+6p3LN58/Jy8hbn1eY15bXl9eWN5+3JuzvvSN5j
eSfMotlsLjc7zQ3mNnOfeTwf5RvyU/JPWxZbXiiwFzxYcKzgpDXHWmyttr5ifbNwZeExW7nNaXvYJtmes71ie9N20fZxkbIotmii
6GDRg0XHik4WPV90vuhC8dHi48Wni8+V9JZsLzlQmlFqLa0sHS59qfT10ndKPyidLqsvO1z2eNmZspfL3ih7v5yUJ5RvKu8uD5Tv
KN9XfqQioeJ4xemKcxWvLj6zpK9yd1VqVXfVeNW+qiNVUtVzVa9UvVP1wVLl0qSlh5Z+uqx5Weey0WUfVgvVK6tPV5+vfq2muKa2
pqXmQs17dmSPs2fYS+3POxIco45Jx2HH407kPOA86TznvOB8z4Vcca4FLqur1rXf9Ybr3Vqx1la7q3Z/7Qd19XX31T1Wd6ru7PLc
5ZXLdy0/uPzo8pPLzy2/sPy9FW0rAivbVp5YFbeqc9XZVa+vurjq4/rh+on6Q9ctva7hugPXfbLasHp49a7VL6x+bfW7qz9dE71G
XGNbc3jN42veaShvWNmwqaGvYUfD+cbYxvTG4sbaxpbGhxtPNJ5tfL2pu+n1tfPWTqw90Eyanc3jzW+uc697Yf3K9ac3pGx4sCWp
paVlf8v7rX2tr2xs3nj++pzrn9xk29S/6bEblDfcd8OnN45uFjbfuPl99zb3Pvdh9zH3KfeL7gvui+5PPQbPPI/ZU+mp92zy9Hq2
efZ5DnuOeV72vOX5oI20xbWlt9na7G1NbaNtB9peanujXWzvaD/f0dexreMRb2lnamd1Z2fnoc6XuqxdB7pe6U7ptnev7A50H+k+
2v1K94Xui750X4tv3HfY94FvusfW093zUM/Znldv0sH/od7y3pe2HO6L7Zv0R/sP9Zv7T/e/tVXYunHr7q2vDRQPrBy4OJgy6Bzc
NHhs8LnB1wJioD/w2JBlaHho+9Dzw5rhjuHHR+wjj4+6RwOjp8dOjHeMn775wLb6W3S3HLzlwna0vXS7e/sjt0bfumNHwo6JnYt3
2nf27jy88/jOC7t0u4p3BXZJu57Z9cltlbedue393dW7e3YP7H5o94u7L9yee/v22x+//Y09wh7rnsV7xvec2KvcG703ZW/6XvPe
3r2H976/95MJ5UTnxNmJ1ycuTkzf8c4dH0/qJudNWiYt/DqREyiAVOib7BuIdLQKfQnyJ6ITYXWldxCl4qXh7x9WyDXYpwApzL/r
VqI1nFagJLSW00qkRz5Oq1AU9CLTAuTv5LQG6H2c1gLPvZyG9R49zGkD0N/ndBQ6gM5xOhpk20h/BVfSn1ruxgFOY2QgAqcJ0sC+
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
",
  Italic = "
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
KWQg5plGbjGTIuCHx6Hni0S/FyWWUS7FYuyTI1ZQgTidSsU9NF6cQUPFWfCDv6RKcTZ89i+oQtyLUfV5VAt/VSPW0xRxJXz2BTRC
XAWvfQWNEetokriGZogb6Sj0SbfT8egBFqAvmC8WYcy+hvzoNR+F958g7qOJ6PtelxfJC+VtcqO8Rd4h75Gb5L3yLnuVep28Sl4h
1yDmWi+vlJfLX6OXmSV+Q9PR58yEJ30K4+k/wMP/Hr3t44gnnsAo5kkRgyjVJbYIj3gI45qHRYR4BPHeg6IKsWqNeA8R7geIHP6G
XvYteN5d8Gp/R7/7pugQ34sx4jsxnwaLhZQmjqZ4cSwliuMoScyjZHEMJSAiGCJOoExxImWJkyhbLKEMcRGNEpfQaHEpNYnLqUWs
pVbxa2oTl1GzuAU9yc10NLzmseJWOo53J4ySo6VfNsrz5PmyVC6Fj5wpl8l58jjV9tQbLujv6D+ioPEWMdk/ASMrTZdon5qha8Yq
HnKRfoIKQVyGeYJH7UlzdeHLJY51q1mvScOHa2J4y/Dmxoa6mkJfTmbaYK8porQor5lU4kuqyq6si6/15WbnJGq1vrq62lr8r6n2
5eaYLpeZW5CjkqoqkxITXKap/rsSzNxc01dTbaWaufEI1K/U5HSEyN2n6DNeMcjQcrLz8nzZvmpdSs8Qr5SuqSNrGsksyU8fLA1T
z4yPGxwfEzc4TiKkfoQ0/XDnXlMvzPANTh2an5FXmhfvld7YEWPqh0WZQ2tSE1MT8nXz1/ExCanxMfFpqheNBEqBXNRbOcv9pTmE
4QHCDtlpqFknwBKE4A0TNDiPUTQxIy3Nl+Hz5VVXmt7UkqyCgmrUV1UvN6eOUD3UJDk+MSE3Ny8JdG2B5stxabRTpmjd72lUp3lq
Igy4HrfWrJt0oaem+zUp0dVTJ2lyi3uVpq1yR8h7dPw7PEt6tms60XWQxhJnpQU5rUJbVkVzycvoVXgI94OStjy3paYkhGe+w3OL
uCc8jx7r8Nwv/wU/Ax655XmHJ9CBfE63eESuvAatTfFeQTuYV6MQ3j75PRAuP+ZpcHg2D8SjHXB4tgzIc47D82vaDW/H9XumN0+P
nNbSrrAyOEd7yeF5UH5s8cgQHpbBqn4yCOan9ckvS/vaye8h+Y/++YFnqp7m8Dw8AE+GdsjheWQAnhTtcofnEtoevuywa6vsmlX2
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
xcWF+XJ20GhixJoz+qrcZg3vww69wqBvJkhoyb940LhSnnDlVb3biNLlq+mtA6Jz4m2FlgoYWkmUvM4xXt5eQEiMq6yk09xYRYqu
qjHf9L2BvtRo57ANsLmsGG91dnY2EUxEzuf3Xjj7G44YKss22OqbKZXHgv9Ffk1+BIYLvenWiuzohHiztFGNZaDkwOxPV+crlIJC
/KIi3g4cjeld0lFyIq2irLgEtrR+MfR2EjBZMrknCsvlDjm0eIHNZjDQk79tdlvjqjqDFQgrySjMKMjVpaclxjO7VRNa2Rq2W8kK
EzReGvspr1birSbLMc83mVqLKptMaw3dHI9/KKNbmfil1TKFbn5Nqd64pjTvY5dpbVGly9hSlGPOKtMX0xniW80241pji7W41bi0
cdm2xb9sNOWVNZTklS3pmgDD1GQ1tppKM8sz88wNpvwy8Vz+83wbjMu5RC6tUaYbgfT4An6TraW+wGWy8XpN8Hn8LHkLdJscqstR
1Y0PT9rU7DYUUrM7ma5YWp6x2VRtK2fnPLLjL1MSHsFz5JecIk9B5jH3okxeAJ3tPkK2gIx+i+AtpQp8JQ+9/UqYxK8FK23pWsU6
gmthyK0lZOksjN5nkXgOzdfIRyDVPWCRf7UtUAqSoMrASqLGvJK0p7MHTnxwi9EmNb0BlyhkfhiUEL3b0U+nM4wEuh+NvnJ0I0Gg
d4oK8m6QFFCZlIRTHgwnQ/8wlRs0OjTs3ewGsrqLCwsM8FdI32eh5NC5vRFqQugi7+TyS35ioR1rOYBeYxPRK4ktvB+SfhuUtpkQ
+2xjdIrXnmsGGpOrsyvrY6NjkjpNVakwdsrYvjhcyWenFznioueGu7+8O1bYM2Lemq6QaYiQu6dm9rA84ZqHtuYpFVGY5GRnV8ao
NCBO+bpsSzTxr9nTWmbZMqxNk/FpWqsxdXVtpqkyn3DJSjn/bzExmfp2p9nk2d1682iuzjeXGicoEsHiTss8PldcuOfrG5a2a/WV
CZn5eZnx1RnZ6sy8/AwYmywwfjlB/upRO9qGvA2avg5no82oT5QreY4q0PT291R2mKG40pjeV8wUM/FzakZEFP2IyuLZ50IHhp4b
v27dqlXrtq3buqp9VVuZIUcOaqW42mBFQ9ik82+XN5XSDVEpTIkLfYGVJ8JzCgqtn6sSvxYS9p6jkGUm3bhgVtYIslwNKGBDNZ3b
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
bYR6F+E65ERfRbHU4bvoOguo710oBcyhTRSf8gGcC8ugvihYDO6n4M6Cm0Vo6SPws8CVgKsENwkuXYSXFsEHfTQYAHc7uDFwFeDA
vA6Ctb0UROjCO+BTuA19H/XiQuTGVciLjgZ/iT5G63Eb2GdfB/d95IU26AUarBD3Ko4GGvtRP+RThB4KvgLpky5yceBiQo6dDYXQ
MenvdfQ+FjBIN27APdiL9+Kj+HYcwE/iF/Ab+DzhSTIxkFrSRPrJDvIm184FuCe5F/gD/HH+Hv4t2TbZbtms7BnZy7K3hSPCbcJ9
whPC88I54QO5Qq6VF8ir5a3yLfK/KIiiSXFG8bTiV4o/KWuVZ5UvKT9WaVQ6VbnKqepSDaqmVUdUJ1QnVW+rkbpPfUh9i/oe9QNR
8VFjUWeino76VXRldFP0LdH3Rj8a/Wz069HvawRNqqZYY9O0aDZpxjQHNAuaOzQPaJ7QPK85F7M35mjseOxjcRlx++Nejns7HsUf
ir8l/t6E8YSDCW8nmhKPJ96T+Gbih0lRSVlJ5qT6pI6kgaTJpENJx5PuSTqddDbppaS3kkeT55OPJT+Vok0xpaxO6UoZTDmd8mFq
VGpWqjm1PrUjdSB1MvXx1OdSX099P01Ii0/LSitOs6W1pPWlvZb2p7TzWpVWpy3XOrUbtKPaae1B7XHtHdp7tae1T2if1b6kPaf9
S/qZ9CfTf55xb2ZT5qnMxzOfyZrNOpR1PFuX/XL2m7qTOZocbY4p51c5b+S8l6vITczV5Zpyq3OduRtyB3PHc+f1eXqz/va8qLys
vGvyW/L78ofzJ/MPFBwteL1wuHC2cKHwFYNgiDfkGcyGekOLoc8wYBgzzBoOGb5guLuIFNmK7EW3Fd1X9ELRG0XvFS0VxxZ7i98z
bjGOGqeNfzF+bNpiGjXNm46YTpjuMT1getR01vS86RXTW6YPSsZL5kuOlJwoubMkUPJYydOl3tLdpfvLSsseN9ean7YUWMotqy1n
LE9afl5+pPxEBamYr8yoNFQuVN5SeW/lo5VnK5+vfKXyrcoPrGPWWesh63HrHdZ7raetT9hO256wPWt7qWp/1U1Vd1ebqqurndX7
q5+rfrn6zer3a1BNV83dNadqnqp5seb1mvdrhdrU2sHa8dr52iO1J2pP1uXWPVH3bN1LdedWkVX3r0lec38DaUhsKGiobmht2NIw
3nCw4VjDnQ2BRlPjsca37cgeb7/Hftq+5Jh1LDhOOM45PnAqnEectznvcz7m/LnzNdcm191NqqaMptKmhqabmrXN9ua+5uHm2eaF
5jua721+tPm5luSW0ZbplpMtZ9aStZq1u9c+0xrbmtta2drQerL1TBvfltxmaKtta2/b1ra7HbXHty+t61h3soN09Hfs6NjfcbST
70zuNHQ+0/lyV3LXdNeRrje63uuu7m7t3tI93n2w+0T3yZ7Yntye/p77ex7vea7n9Z73e1t6j/Xe2RvofbL3hb6sPnOfva+v7431
g+vv35C7oXjDwoZXNsZu3Lvxw/7B/nPucfeTm8Y2nd/csvng5je3jG95cWv/1te31W57a/ve7We3Lw1sGnjP0+N5YXDD4L1D7UMv
DJ0bet/LexO9ed5Kr9Pb5/V6p72HvF/wnvSe9j7lfcF7zvu+j/cV+2p9rb5Nvh2+ed+C73bffb7nfG8OFw/XDs8PvzTSMvLiyLnR
qNFD/kH/Ef8D/nM7tDsO7fjLTvPO8Z237bx757M7z4+hMdNY5ZhzbH4sMPbC2Ae7Wndt2LWw6/FdH4/njpvHvePeCWHi3t3tu9/b
s23Pc5ObJt+bmp0m08XTHdOnp1+fMc8cnblz75G9Z/ae2/vhvqZ9W/ZN7jszK8w2zD42h+YUcxvmbpn7y3zt/P1X6K549orX9huu
jLry2QPJB16+6tjBpoPPX51x9eqrZ6++8+o3rqm8JnBt8bX3HDp66Pihxw+9fZg/XHp4w+EDhx89/N7hj4/Yjuw/8tyRD6+zX7fj
usnr7rnu2etePmo+euho4OjL15PrTdfbrp++/v4FtKBaSFzIWjAseBeOL5xbeHvh/A39Nzx2w89veO2G944dOHb82D3HTh87e+ys
+K4BbN8rkQzdx95AGFAfuhHCD2mSEA9/CGyP1exNBv23VkzBfgV4wtI7YgF1SjAHNsp6CeZRNNolwTKA5yVYAPg6CVYgNfqCBCsh
/C4JVqMEdL8ERwH8AwmORsfR8xKsAdoG6THpvBKeTuD9EoxhztVIMAFYK8EczMMFEswjLdkgwTKAd0uwAPCCBCtQMjkpwUoIf1SC
1aiAvCDBUQB/KMHRWMfpJFiDKvkGx8TuuUn/yOi0rtxsqdL1jfp0ds/k2MQ+XdfkxA7f0LSucWZ6dGJySmcYnZ7ePVVbVjbinx6d
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
cLEnVnZ5uZS3XaLVIZXpkMpwSLQ6KlWucH5SklDSRrlLIsMlkiGFO9TNEeQ0h5PzLaDtqluW46QipOo5quVrpfzWivkJa6f9Y16f
unU5idDuGZqZ9gnty3WxVNiFDjG0g4VyrvERMUunVBunRLJTqpVT4rgzVGuJ8w6XrBPU9XEpViLMFUolYTklnrnM0Z2jM+MjnsmZ
XWOemWl5p0i+0CNS0yNyv5c9qXtX1ttsqW7i+4AhQp+Itj5CglwSfS6bbP0yPS6pFk1SrVwh+iS6XK7o9SvoWS+xc73ITtn6Sf/4
iLCeMVXYKJK1cZks5UavHyyGKf+UsHFk0rPXp3Zf3FZNlYKbRUmPEv+aqoVNLDvVphXCYraUl0ttZBP9SqvoW6VnmxhfbqmW/EbB
E9mVmiSZqpJ8i+RXSL6UnUNqkkar5Ie6lpSusUby7ZIv5dNYIfdITPJIXWkoQnaHlruSV2wlX2QfkjK1S0Q6pMIcUuYOiUiHVeW7
uA+FktrlPql834o+5BSLsNaIfo3ERleTMMIoUI9EkDlyEdNdVn4UJEviaJN6NKL/+Bl3lf7SsYmhsb6eNolEiS+OGuLfIfdLJPml
buhnEiNmV1Gl3nGxJLtqhDFR5Mciu6WDHwPChHExalzsmz6QwImIFnZKzHJKHHFKTHNKLekMMVVqUUeTbCKii0p0u0KpJCyn1CQu
S/TEii4xIVZNPTE15pkaFSmblDyxhafEfjG1XEl+mnbTaTF6Jky72RIaRlwSra4q2UxEd5Vq1CTV0BWiVaLR1RQ9s4K2GYntYsep
kLhYJXUcqcNYpWdbhdS8koRYIHepm8+wbj4jdvN9YnX2RXTzfeFuvk/s5nOf6OZWYS6ym0tt0FQjzIvdfD4scWpJXkvNZotaEjgK
yzylnrFptdSrKKxYu721dMw/4lENbx/e7l8GxxioGNm+QwT8EsB7SqeGlB5WIoMY6wFSSX0eQI1nmXZ4jPKE6sYSsDrQBFInZ6BE
0dSQwkMZxRAZrwCSeegvP0h/hmjMULj0Idb+AMEI4fP6x8YoddHLIwRN4oUfwTc9SvG9IXyA6PRL41lGvnCWvhCKShpPaIV8Kyvk
i6hQtC+yNKUvXD3fcvV84erxw/SH1W9kJefKK2hmIytIpzTL6ahBH/w0kT9Ep8a/kiR/BElRFDU0lij9IYpk/h20NP8yXf5lumgU
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
naFdqwj9XyKl8K8=
",
  BoldItalic = "
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
0yarAW0Fq7t843Lf0HwpabIhm2uKBekLqsNnp2x6Jz/PPnTbxalR6ofcwb8B/dht+3cuLmF/iP1rt+yXlSvZ6hfynC/b8/9zkucQ
h+dg35e2yb4PK+uKoxnCRRy4bhuhCkNxkFMQy29DAwmuCAznTQhdsCErJTuT8XhTKp3TVPQhhu7GBs55iFQ+VA6VyBFWoFrpyMg+
K7aOjGrLB9CGLg+Tv8Yx9HIaSzRWHxY542plwMY5OAIyYJOUAb9s89QrZb+zS69K3XNESRcTXpM6SaIrFWNQNaJ0JpLDrlZsVW8c
AOfvPkmzcuy6SSqeyIusI7Pr6y+d1A7vDnnJfvSreUyq43vwBwzfY1OHh631Itsk5d7nbZ72Z8vk3uo698LaWrlOxq1zJ4z7Jkvf
uepzzoD0u9JzWsvq3EP+beXnyL3veVsGen+V/Im03ippvQajYvX3USvJMHUTDEttCT0q1Q/KtuREV5t17LNiduFKX6nkyk7Etu4/
a155PuW9dT5RIzzExEj5g5SwyQ1V4yT1EouP7bvWS2Ntvlpu5RaOd/X1U1538eyycXPpd63b7/vJdZW0gU7NwfpLQ7+rcga7Gk43
Z7C+Ss5g9DT6KD0gcwb3AR+628oZ/C/Cc5MBD0C3ojMgu78Z3VReMpx3Mg+8M4vzOt5ogOzkOD6lLcenLjmts0rX0PCauFQH2t5W
wYDtbgW0dL9V+T09QufNG4XayslRZl5nhgW5jJlX1/BvcPNNJolxeoyZJw2QeE1VLH6Bc1I0TfvTd/a7hkHynC/+jZ0z2Gorzp0X
7ZzBTZX6zRXq3Et7V64j7eZetHMGp606dPXnnCGfrdKlglwJ4zUEtOvBfMvJljrOS0MmXaSsMetRsqMjGeQIg3Ly5ctSB6+cOdiy
SlPZX5M7iIF5gzcydpVq3OhhX2H0bcS8wSM2wm5ztTBuVIFWdZSTWsp1zv9MiD+TeYN/w9jiv6KG+qOMfVRXMG4ZoT3SjqQiZ7Cj
tupKd6EWGnMGV6Q2ttpXyhn8lEpClN6M2Yw1MkH5dVbS4JcsGQr+oxvUYXix4D/WtB9jyuD3c/qspZ+22oA0/YHNrz62bGyq69xL
vrhyHTl+P7D51bPLxq/6OWdAMqgeP5QUfi7PREAKMoj0HMNzdttzKW15LiFr73K8x+biBWsgh3PDpHJ3snL7uhI4r1FJgqu/NaXr
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
zXk8Z18w+SVCuxmDWt0OsPdWoEnd0gi9SZ6DJosxjzyvkGcsb0cpiO2xddQMMZc/z9WwhedLAXA15nc8nTAQ7nUquV76eJ+k6kuA
gCxHsuthRf+QdWriP/sB7bGLhfjPD+EyZn8rdRzYhuMwKt04TqoMKrXqiXAm2YutkFmmgSZAgUpUE7XiHwJaLkM6KA1w4mX0U9xi
pS84+OYZ6N8zlC/+mqnE0eYs5r+KMbEEeStsIpOafsRGO5wufgk2Fn3xdrWEKcNLI6yHtSidSD+G2/vbq9EqfOtU2sNNDXUcdoVg
iqXKICUp54ES458mFxHzCso02k0ANbRyE6Q1q2VfZHTxM9y88qsGeSvIunGifwPI8yvDat5/fthwbECtmF0Dyg1FM02EUuPD5GZb
rEwDIUwPI/N/k0PSbgW1ZJMyMXwcLrfYl+UFIeghIP56pwpMVIQ4K1Wh0sMqnUwmCxEpM1SlTLNV8MvSppVFT73Dmi1jcgIJTnt3
Gg0iaMtz59spgeIk1hkd0FPkP+wk4N4oI6wA7OyTMvzBJ6Tp5XdUM5rqiqLxLUWbW9pHv6gkAfmvK462wirrsrRo1on/CZTBBOEn
VCIZoUyHDNsLcMFUKpVP5dIZyeharKj1jq7VSoaQTzrOYn00J4eVFmyPF1V2jTa2Gk0P37r/cmpsvnxs3aDKmtpH8mtRwA8Tz+75
a8aenqkjNYMdnWvj/Sk6ddXE0Jq3ffTwPjO86ViumWnrEr0dVDvGPaxr96K6c6ug4fbO0WQX2jsK5eTS7+kv6JdBdmxTupRh9Lmz
DOe6vUQAYFIFQW8F3aPqJ/GYSSaKn9paAyI7O+jTTGa7uuRWqC51RXiPjJ5hon2svFE76COatl4DITEzMpLJtLfXgNg6sn5kanws
M5wpDPS1d7Wn49GatpqWYKMUhmur7Hz/396+BS7O4lp8Zr7HPllggeWxBBaWXTawLMvyDJCw7LIECOEVSFjyYoEFNhKIPEKCGqNG
TWKM0dpWrde+bK61ryVGa621qbVer/Z6bWtbr/W20Wtb9Vqv16vWepX9n5nv22XBxHp7vX/4zc75Zs7MnHPmzMyZ75uHaCarFnbr
lz8NlKMVmFVxMd/dXNZTUrvZ2eXYzeEfieqNKm7JLahbryorMOaVW7Ixv7msu6S2w9ntsJdZjHmugmx8rLPe0VPWWefsLluaj18x
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
IO53OB10YJqe/hkpQA9GXoD0CaucFpwy6tj5aQgdl/9fQG/AFFePbbgWt+NdeB++Gt+K78UP46fxefwWXiJJ9Dxv4iY9ZIS8wnVx
T3Pnubf4z/H38A8J9AbAk8LnhDdFIqaKt4n3ig+LPxdfFt9VKBVZCruiRtGm2KGYVLypJMoO5ePK55SvKT9Qdan+oHpPbVK71E3q
repx9az6OvVt6nvVD6if0KRqrJoFzbc15zQ/1TyndWvv1L6m/SBBlzCRcCjh5wkvJ7yrU+pydE6dR9erG9VN647oPpdIElMTTYmu
xKbErYnjiQuJ7yWpk0ny1uQH9dn6q/W36k+nbEjpShlKFVMzUo+mPp7mTPOknUi7Ky2c9mjas2nn094y8IZBw7ThkOGU4SuGs4bH
Dc+lt6QPpE+kn07/IEOXYcpwZTRl3JHxQsYbmShTn5mT6cz0ZPZmfiXzbObjmc9lvpb5bhbJ0mVlZdmzarIey3om66Wst41qY7bR
YXQbe4y7jHuMC8brjLcY7zLea3zA+KjxaePz2fdmP5D96Jp7cmpyHs55IufZ3CO5p3LvNOWbHjf9PO9k3gf5yvys/LP55/J/mv9S
/hv575tFs96cY3aa680t5l7za+Z3C3YVPFPwkqXF8rLlXavSmmo1Wd8v7C18vvD1wiVbr+1y21HbHbbTtjO2R2xP2n5le8n2hu39
teq1hrULa8NrHy5KLbIWtRftKtpTtL/oaNH54tni88WvF79nP2Q/bn/Z/mYJKdGVZJUUlVSVeEo6SgZKRkumSw6VvFHyvkN06B05
Dqej3tHi+Lnjt47XSu905jvPlNWW3VF2uuyMq9c16JooLyh3lt9dkV/xbMX5yubKnsqRyv2VV1eerLyj8nTlmSpnVX1VS1Vv1WDV
RNWBqiPVA9Wj1dPVh2rcNT01IzVvr0PrtOua1t257p51Z9edW/fTWlPtZO3h2ltq764N1z5a+2ztH+ocdbV1zXU9dbvq9tW9WX+0
/tb6L9V/c/0dGzoa9rmV7q3ucfeC+4T7LnfY/aj7Wfd591uNfOPRxjc9E55DnlPeKm+L91STuim7qaDp6qZbm077nD6Pr9c36jvg
O96c1Lyr+XzzWxv5jYaN4xuXWqwtNS1tLTtaJlsOt5xouavlbGtq62jrdOvp1gfblG2pbQfant2Uv6liU/Omnk0PbnqyPbvd0e5u
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
"
)

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
x_ticks_espessura_pt <- NULL   # GROSSURA dos traços do eixo X, em pt (vale para grandes e pequenos). Vazio = igual à da moldura. EX.: 1.5
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
moldura_espessura_pt <- NULL   # grossura da moldura, em pt. EX.: 1.5   — os traços e as linhas dos eixos seguem esta grossura (a menos que você dê x_/y_ticks_espessura_pt)
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
x_rotacao_titulo <- NULL   # ângulo do título do eixo X, em graus (padrão 0). EX.: 0
y_rotacao_titulo <- NULL   # ângulo do título do eixo Y (padrão 90, lendo de baixo para cima). EX.: 0 (na horizontal)
x_numeros_negrito <- NULL  # TRUE = números do eixo X em negrito
y_numeros_negrito <- NULL  # TRUE = números do eixo Y em negrito
negrito_geral    <- NULL   # TRUE = TODOS os nomes e números em negrito (títulos, eixos, legenda, rótulos de dados...)

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
quebra_y_ticks_menores_inferior <- NULL   # traços pequenos entre dois grandes na parte de baixo do eixo esquerdo (0 = sem). EX.: 4
quebra_y_ticks_menores_superior <- NULL   # ... e na de cima
quebra_y2_ticks_menores_inferior <- NULL  # o mesmo para o eixo direito
quebra_y2_ticks_menores_superior <- NULL
quebra_ligar_pontos      <- NULL   # FALSE = não liga os pontos através da quebra
quebra_marcas    <- NULL   # FALSE = sem as barras "//" na quebra
quebra_marca_largura_pt <- NULL    # largura de cada barra "//", em pt (padrão 2.5: curta, não encosta nos números). EX.: 4
quebra_marca_altura_pt  <- NULL    # altura de cada barra, em pt (padrão 3)
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
y2_rotacao_titulo <- NULL         # ângulo do título do eixo direito (padrão -90). EX.: 90
#  Aparência do eixo direito: as MESMAS opções do Y1. Vazio = igual ao eixo esquerdo.
y2_primeiro_tick <- NULL          # de onde começam os traços do Y2. EX.: 0
y2_folga_pct     <- NULL          # folga nas pontas do Y2, em %. EX.: 4
y2_ticks_direcao <- NULL          # traços grandes: "dentro" | "fora" | "ambos" | "nenhum"
y2_ticks_menores_direcao <- NULL  # traços pequenos: "dentro" | "fora" | "ambos" | "nenhum"
y2_ticks_comprimento_pt <- NULL   # comprimento do traço grande, pt. EX.: 5
y2_ticks_menores_comprimento_pt <- NULL  # comprimento do traço pequeno, pt. EX.: 3
y2_ticks_espessura_pt <- NULL     # grossura dos traços, pt (vazio = a do eixo esquerdo / moldura)
y2_ticks_cor     <- NULL          # cor dos traços (vazio = a cor do eixo direito)
y2_linha_espessura_pt <- NULL     # grossura da linha do eixo (aparece com a moldura aberta)
y2_mostrar_numeros <- NULL        # FALSE = esconde os números do eixo direito
y2_numeros_tamanho_pt <- NULL     # tamanho dos números, pt. EX.: 10
y2_numeros_negrito <- NULL        # TRUE = números em negrito
y2_rotacao_numeros <- NULL        # gira os números, em graus. EX.: 45
y2_titulo_tamanho_pt <- NULL      # tamanho do título do eixo direito, pt. EX.: 12
y2_titulo_negrito <- NULL         # TRUE = título em negrito
y2_titulo_italico <- NULL         # TRUE = título em itálico
#  As cores de cada série (esquerda ou direita) também podem vir de cores_por_serie (bloco 8).

# ---- 8. CORES, LINHAS E SÍMBOLOS ----------------------------------------------------------------
cores_paleta        <- NULL   # "classico" (padrão tipo Origin) | "origin_basico" | "origin_pastel" | "marca" | "okabe_ito" |
                              # "tableau" | "npg" | "seq_azul" | "div_espectro" | "viridis" | "cinza" | "brewer_Set1"...
                              # (a lista completa, com as cores desenhadas: mostrar_paletas())
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
painel_fixo      <- NULL   # TRUE (padrão) = a caixa do gráfico tem sempre o mesmo tamanho (mexer em números/títulos/legenda não
                           #   muda o gráfico, a página se ajusta) | FALSE = a caixa ocupa o que sobra da página (largura_cm x altura_cm)
painel_largura_cm <- NULL  # TAMANHO da caixa do gráfico (dentro dos eixos), em cm. Padrão 10 x 7.5.
painel_altura_cm  <- NULL  #   EX.: 9 e 6.5. Números, títulos e legenda ficam fora; a página se ajusta para caber tudo.

# ---- 11. LEGENDA: POSIÇÃO, FUNDO, BORDA E SOMBRA -------------------------------------------------------
legenda_mostrar  <- NULL   # FALSE = sem legenda
legenda_titulo   <- NULL   # título da legenda. EX.: "Região"
legenda_negrito  <- NULL   # TRUE = nomes das séries na legenda em negrito
legenda_titulo_negrito <- NULL  # TRUE = título da legenda em negrito
legenda_nomes    <- NULL   # como cada série aparece escrita na legenda. EX.: c("WORLD RSP" = "Mundo (RSP)")
#  Posição
legenda_posicao  <- NULL   # "dentro" (sobre o gráfico) | "direita" | "esquerda" | "topo" | "base" (fora do gráfico)
legenda_canto    <- NULL   # atalho para "dentro": "sup_esq" | "sup_centro" | "sup_dir" | "centro_esq" | "centro" |
                           #   "centro_dir" | "inf_esq" | "inf_centro" | "inf_dir". EX.: "sup_dir"
legenda_x        <- NULL   # posição fina com "dentro", de 0 (esquerda) a 1 (direita). EX.: 0.04
legenda_y        <- NULL   # de 0 (embaixo) a 1 (em cima). EX.: 0.96
legenda_x_dados  <- NULL   # posição por COORDENADA do eixo: valor de X onde fica o canto superior esquerdo da legenda. EX.: 2016
legenda_y_dados  <- NULL   # valor de Y (eixo esquerdo) do mesmo canto. EX.: 600000  (vale no lugar de legenda_x / legenda_y)
legenda_ancora   <- NULL   # qual ponto da caixa fica em (x, y): c(0, 1) = canto sup. esq. | c(1, 1) = sup. dir. ...
legenda_alinhar  <- NULL   # com a legenda FORA: onde ela fica ao longo do lado.
legenda_escala   <- NULL   # aumenta (> 1) ou diminui (< 1) a legenda toda. EX.: 0.8
legenda_largura_pt <- NULL   # LARGURA da caixa da legenda, em pt (como esticar uma caixa solta): o conteúdo escala até caber nela e os
                            #   símbolos e linhas acompanham. EX.: 110.  Vazio = a largura que o conteúdo pedir
legenda_espaco_texto_pt <- NULL  # espaço entre o símbolo e o nome (menor = mais compacta). EX.: 2
legenda_largura_chave_pt <- NULL # largura do espaço do símbolo. EX.: 12
legenda_distancia_pt <- NULL  # com "dentro": distância até a borda da caixa, em pt. EX.: 8  |  c(10, 6). Use com legenda_canto
legenda_ajustar_caixa <- NULL # TRUE (padrão) = se a legenda for maior que a caixa, é reduzida até caber | FALSE = como pedido
                           #   direita/esquerda: "topo" | "centro" | "base"; topo/base: "esquerda" | "centro" | "direita"
#  Disposição dos itens
legenda_direcao  <- NULL   # "vertical" (um embaixo do outro) | "horizontal" (lado a lado, numa linha)
legenda_n_colunas <- NULL  # em quantas COLUNAS os itens se organizam. EX.: 2
legenda_n_linhas  <- NULL  # em quantas LINHAS os itens se organizam. EX.: 2  (com "horizontal": 6 itens em 2 linhas de 3)
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
largura_cm   <- NULL       # EX.: 14   (só vale com painel_fixo <- FALSE ou ajustar_pagina <- FALSE; senão a página se ajusta sozinha)
altura_cm    <- NULL       # EX.: 10
ajustar_pagina <- NULL     # com caixa de tamanho fixo: TRUE (padrão) = a página cresce/encolhe para caber tudo |
                           #   FALSE = página sempre largura_cm x altura_cm (a caixa fica centralizada)
dpi          <- NULL       # EX.: 600
formatos     <- NULL       # EX.: c("png", "pdf")   (também "tiff", "svg", "jpeg", "emf")
fundo_transparente <- NULL # TRUE = arquivo sem fundo branco (PNG, TIFF, SVG, PDF; o JPEG não tem transparência)
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

