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

# Blocos que são listas livres de itens (cada item tem as suas chaves; conferidas em .CHAVES_ITENS)
.BLOCOS_LISTA <- c("ajustes", "marcas_estatisticas", "caixas_estatisticas", "formas", "imagens")

# Completa o cfg com os padrões do 01_config.R para tudo o que faltar nos blocos. Assim continuam
# funcionando scripts que SUBSTITUEM um bloco inteiro (cfg$quebra <- list(...)) e estilos salvos
# antes de um parâmetro existir. Não mexe em cfg$series e cfg$referencias (livres).
.completar_cfg <- function(cfg) {
  ref <- .cfg_ref
  if (is.null(ref)) return(cfg)
  for (bl in setdiff(names(ref), c("series", "referencias", .BLOCOS_LISTA))) {
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

# Avisa blocos e parâmetros do cfg que não existem (digitados errado), comparando com o 01_config.R.
.checar_nomes <- function(cfg) {
  ref <- .cfg_ref
  if (is.null(ref)) return(invisible())
  livres <- c("series", "referencias", "interno", .BLOCOS_LISTA)
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
  faixas = c("eixo", "de", "ate", "cor", "opacidade"),
  ajustes = c("serie", "tipo", "formula", "inicio", "grau", "suavizacao", "intercepto_zero", "cor", "tipo_linha", "espessura_pt", "opacidade", "de", "ate",
              "estender", "banda", "banda_nivel", "banda_opacidade", "nome", "casas", "n_pontos", "pontos", "parametros", "interpolacao", "cartao", "ativo"),
  marcas_estatisticas = c("serie", "eixo", "centro", "faixa", "multiplo", "cor", "opacidade", "centro_espessura_pt", "centro_tipo", "faixa_espessura_pt",
                          "faixa_tipo", "preencher", "preencher_opacidade", "rotulo", "rotulo_tamanho_pt", "casas", "modo", "ponto_media", "ponto_tamanho_pt",
                          "chapeu_percentual", "cartao", "ativo"),
  caixas_estatisticas = c("series", "titulo", "itens", "ajustes", "casas", "x", "y", "ancora", "tamanho_pt", "cor_texto", "negrito", "italico", "alinhamento",
                          "colorir_serie", "mostrar_nome_serie", "fundo", "opacidade_fundo", "borda", "borda_cor", "borda_pt", "borda_tipo", "cantos", "raio_pt",
                          "margem_pt", "sombra", "sombra_cor", "sombra_opacidade", "sombra_dx_pt", "sombra_dy_pt", "cartao", "ativo"),
  imagens = c("arquivo", "x", "y", "largura", "altura", "unidade", "ancora", "opacidade", "angulo", "borda_cor", "borda_pt", "borda_tipo", "camada", "cartao", "ativo"),
  formas = c("tipo", "x", "y", "unidade", "largura", "altura", "vertices", "texto", "tamanho_pt", "cor_texto", "negrito", "italico", "alinhamento", "angulo",
             "fundo", "opacidade_fundo", "borda", "borda_cor", "borda_pt", "borda_tipo", "raio_pt", "cantos", "margem_pt", "sombra", "sombra_cor",
             "sombra_opacidade", "sombra_dx_pt", "sombra_dy_pt", "camada", "ancora", "cartao", "ativo"))

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
  for (t in .BLOCOS_LISTA) um(cfg[[t]], t, paste0("cfg$", t))
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
