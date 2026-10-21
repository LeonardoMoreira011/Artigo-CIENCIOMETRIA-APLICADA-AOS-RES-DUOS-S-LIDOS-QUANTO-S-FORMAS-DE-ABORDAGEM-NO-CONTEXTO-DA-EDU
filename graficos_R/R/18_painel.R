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
  # listas livres: ajustes, marcas e caixas de estatística, formas
  for (nome in .BLOCOS_LISTA) {
    v <- pega(nome)
    if (is.null(v)) next
    if (!is.list(v) || (length(v) && is.null(names(v)) == FALSE && !is.list(v[[1]])))
      .erro("A variável '", nome, "' deve ser uma lista de itens: ", nome, " <- list(list(...), list(...)).")
    cfg[[nome]] <- v; marca(nome)
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
  idm <- pega("idioma")                  # idioma das mensagens e dos textos automáticos do gráfico: "pt" | "en" | "es"
  if (!is.null(idm)) {
    if (!idm %in% c("pt", "en", "es")) .erro("idioma precisa ser \"pt\", \"en\" ou \"es\".")
    options(cinabro.idioma = idm); marca("idioma")
  }
  if (length(aplicados)) message("Painel de ajustes aplicado: ", paste(aplicados, collapse = ", "))
  else message("Painel de ajustes: nenhum ajuste ativo (tudo NULL = padrão do template).")
  cfg
}
