# =============================================================================
#  R/15_entrada_paineis.R — plotar() (ponto de entrada), painéis e quebra de eixo
# =============================================================================

# =============================================================================
#  PLOTAR (ponto de entrada) — simples, painéis ou quebra de eixo
# =============================================================================
plotar <- function(dados, cfg = get("cfg", envir = globalenv())) {
  if (missing(dados) || !is.data.frame(dados)) .erro("plotar(dados, cfg): 'dados' deve ser o resultado de ler_csv().")
  .validar(cfg)
  g <- if (isTRUE(cfg$paineis$ativo)) .plotar_paineis(dados, cfg)
       else if (isTRUE(cfg$quebra$ativo)) .plotar_quebra(dados, cfg)
       else .plotar_um(dados, cfg)
  attr(g, "dados") <- dados
  attr(g, "cfg") <- cfg
  g
}

.formatar_letra <- function(i, formato) {
  l <- letters[i]; L <- LETTERS[i]
  rom <- tolower(as.character(utils::as.roman(i)))
  switch(formato, "(a)" = paste0("(", l, ")"), "a)" = paste0(l, ")"), "a" = l,
         "(A)" = paste0("(", L, ")"), "A" = L, "(i)" = paste0("(", rom, ")"))
}

.rotulo_lateral <- function(texto, cfg, vertical = TRUE) {
  e <- if (vertical) cfg$eixo_y else cfg$eixo_x
  face <- if (isTRUE(e$negrito_titulo)) "bold" else "plain"
  patchwork::wrap_elements(full = textGrob(.texto(texto), rot = if (vertical) 90 else 0,
    gp = gpar(fontsize = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt, fontface = face,
              fontfamily = .fonte(cfg$texto$fonte), col = e$cor_titulo %||% cfg$texto$cor)))
}

.plotar_paineis <- function(dados, cfg) {
  P <- cfg$paineis; n <- length(P$lista)
  if (n < 1) .erro("cfg$paineis$ativo = TRUE, mas cfg$paineis$lista está vazia. Veja o exemplo em 01_config.R.")
  vertical <- P$direcao == "vertical"
  comum <- if (vertical) "eixo_x" else "eixo_y"
  cfgs <- lapply(seq_len(n), function(i) {
    p <- P$lista[[i]]
    if (!is.null(p[[comum]]) && length(setdiff(names(p[[comum]]), c("mostrar_rotulos", "mostrar_titulo"))))
      .aviso("Painel ", i, ": ajustes em ", comum, " são ignorados — o ", comum, " é comum a todos os painéis.")
    p[[comum]] <- NULL
    ci <- .mesclar(cfg, p)
    ci$paineis$ativo <- FALSE; ci$quebra$ativo <- FALSE
    ci$.interno <- list(em_painel = TRUE)
    .validar(ci)
    ci
  })
  # 1ª passada: faixa comum
  faixas <- lapply(cfgs, function(ci) {
    g <- .plotar_um(dados, ci); inf <- attr(g, "info")
    if (isTRUE(inf$pizza)) .erro("Pizza não pode ser usada em painéis com eixo comum.")
    if (vertical) inf$faixa_x else inf$faixa_y
  })
  tipos <- vapply(cfgs, function(ci) ci$grafico$tipo, "")
  conhecidos <- c(names(dados), unlist(lapply(names(dados), function(n) if (!is.numeric(dados[[n]])) unique(as.character(dados[[n]])))))
  for (s in setdiff(unique(unlist(lapply(cfgs, function(ci) names(ci$series)))), conhecidos))
    .aviso("cfg$series[[\"", s, "\"]] não corresponde a nenhuma coluna/categoria dos dados.")
  forcar <- if (vertical && all(tipos %in% c("barras", "boxplot")) || (!vertical && FALSE)) NULL else {
    ax <- .calc_eixo(cfg[[comum]], unlist(faixas))
    ax$limites
  }
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
    if (i > 1 || !is.null(cfg$titulos$titulo)) { if (i > 1) { ci$titulos$titulo <- NULL; ci$titulos$subtitulo <- NULL } }
    plots[[i]] <- .plotar_um(dados, ci)
  }
  tam <- P$tamanhos %||% rep(1, n)
  if (length(tam) != n) .erro("cfg$paineis$tamanhos deve ter ", n, " valores (um por painel).")
  pw <- if (vertical) patchwork::wrap_plots(plots, ncol = 1, heights = tam)
        else patchwork::wrap_plots(plots, nrow = 1, widths = tam)
  if (isTRUE(P$legenda_unica)) {
    pos <- switch(cfg$legenda$posicao, dentro = "right", direita = "right", esquerda = "left", topo = "top", base = "bottom")
    pw <- pw + patchwork::plot_layout(guides = "collect") & theme(legend.position = pos)
  }
  if (!is.null(P$titulo_unico)) {
    lab <- .rotulo_lateral(P$titulo_unico, cfg, vertical)
    pw <- if (vertical) patchwork::wrap_plots(lab, pw, nrow = 1, widths = grid::unit(c(1.6, 1), c("lines", "null")))
          else patchwork::wrap_plots(pw, lab, ncol = 1, heights = grid::unit(c(1, 1.6), c("null", "lines")))
  }
  pw
}

.plotar_quebra <- function(dados, cfg) {
  Q <- cfg$quebra
  if (is.null(Q$de) || is.null(Q$ate) || Q$de >= Q$ate) .erro("cfg$quebra: defina de < ate (ex.: de = 20, ate = 80).")
  if (cfg$grafico$tipo == "pizza") .erro("Quebra de eixo não se aplica a pizza.")
  base <- cfg; base$quebra$ativo <- FALSE
  g0 <- .plotar_um(dados, base); inf <- attr(g0, "info")
  lim <- inf$ax_y$limites
  if (Q$de <= lim[1] || Q$ate >= lim[2]) .erro("cfg$quebra: o trecho omitido (", Q$de, " a ", Q$ate,
                                               ") precisa estar dentro do eixo Y (", lim[1], " a ", lim[2], ").")
  inferior <- base; superior <- base
  inferior$eixo_y$inicio <- lim[1]; inferior$eixo_y$fim <- Q$de
  superior$eixo_y$inicio <- Q$ate; superior$eixo_y$fim <- lim[2]
  for (k in c("inferior", "superior")) {
    ck <- get(k)
    ck$eixo_y$mostrar_titulo <- FALSE
    m <- cfg$caixa$margens_cm; esp <- Q$espaco_pt / 2 / 72 * 2.54
    ck$caixa$margens_cm <- if (k == "superior") c(m[1], m[2], esp, m[4]) else c(esp, m[2], m[3], m[4])
    if (k == "superior") { ck$eixo_x$mostrar_rotulos <- FALSE; ck$eixo_x$mostrar_titulo <- FALSE }
    else { ck$legenda$mostrar <- FALSE; ck$titulos$titulo <- NULL; ck$titulos$subtitulo <- NULL; ck$anotacoes$letra <- NULL }
    assign(k, ck)
  }
  gs <- .plotar_um(dados, superior); gi <- .plotar_um(dados, inferior)
  if (isTRUE(Q$marcas)) {
    marca <- function(y) {
      gp <- gpar(col = cfg$caixa$cor, lwd = .lw(cfg$caixa$espessura_pt) * ggplot2::.pt)
      dx <- unit(5, "pt"); dy <- unit(4, "pt")
      gTree(children = gList(
        segmentsGrob(unit(0, "npc") - dx, unit(y, "npc") - dy, unit(0, "npc") + dx, unit(y, "npc") + dy, gp = gp),
        segmentsGrob(unit(1, "npc") - dx, unit(y, "npc") - dy, unit(1, "npc") + dx, unit(y, "npc") + dy, gp = gp)))
    }
    gs <- gs + annotation_custom(marca(0), -Inf, Inf, -Inf, Inf)
    gi <- gi + annotation_custom(marca(1), -Inf, Inf, -Inf, Inf)
  }
  pr <- Q$proporcao_superior
  pw <- patchwork::wrap_plots(gs, gi, ncol = 1, heights = c(pr, 1 - pr))
  tit <- inf$titulo_y
  if (isTRUE(cfg$eixo_y$mostrar_titulo) && !identical(tit, ""))
    pw <- patchwork::wrap_plots(.rotulo_lateral(tit, cfg, TRUE), pw, nrow = 1,
                                widths = grid::unit(c(1.6, 1), c("lines", "null")))
  pw
}
