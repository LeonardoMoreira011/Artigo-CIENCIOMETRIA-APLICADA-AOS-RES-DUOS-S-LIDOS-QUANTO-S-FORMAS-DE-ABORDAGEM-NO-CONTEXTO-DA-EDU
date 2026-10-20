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
  pf <- .painel_cm(cfg)
  fixo <- if (!is.null(pf) && !is.null(pf$w) && !is.null(pf$h)) c(pf$w, pf$h) else NULL
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

# Dispositivo descartável para medir/montar gtables (ragg: as mesmas fontes do arquivo final; sem aviso de fonte do pdf).
# Sai: o número do dispositivo aberto (feche com grDevices::dev.off(numero)).
.abrir_dispositivo_tmp <- function(larg = 7, alt = 5) {
  if (.tem("ragg")) ragg::agg_capture(width = larg, height = alt, units = "in", res = 72) else grDevices::pdf(NULL)
  grDevices::dev.cur()
}
