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
