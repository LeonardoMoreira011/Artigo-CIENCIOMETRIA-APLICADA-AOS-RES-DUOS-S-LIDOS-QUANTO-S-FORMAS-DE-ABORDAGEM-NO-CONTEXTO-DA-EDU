# =============================================================================
#  R/13_tipo_boxplot.R — boxplot, violino e média ± erro
# =============================================================================

# ---- Boxplot e variações ------------------------------------------------------------
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

.construir_boxplot <- function(dados, cfg) {
  X <- cfg$boxplot; var <- X$variacao
  A <- .amostras(dados, cfg); am <- A$am; itens <- names(am)
  if (any(vapply(am, length, 0) == 0)) .erro("Boxplot: série(s) sem dados: ", paste(itens[vapply(am, length, 0) == 0], collapse = ", "))
  flip <- identical(X$orientacao, "horizontal")
  est <- .estilos(cfg, itens, inverter_grad = flip)
  k <- length(itens); w <- X$largura
  contorno <- function(i) if (identical(X$contorno_cor, "serie")) est[[i]]$cor else .cor(X$contorno_cor)
  polys <- list(); segs <- list(); pts_media <- list(); pts_out <- list(); pts_dados <- list(); txt_n <- list()
  faixa <- range(unlist(am))
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
      tukey = { iqr <- q[3] - q[1]; c(min(x[x >= q[1] - X$bigode_coef * iqr]), max(x[x <= q[3] + X$bigode_coef * iqr])) },
      percentis = stats::quantile(x, X$bigode_percentis / 100, names = FALSE, type = 7),
      min_max = range(x),
      desvio_padrao = , erro_padrao = , ic95 = md + c(-1, 1) * erro_media(x, X$bigode))
    out <- if (X$bigode %in% c("tukey", "percentis")) x[x < wl[1] | x > wl[2]] else numeric(0)
    if (var == "media_erro") {
      er <- erro_media(x, X$media_erro_tipo)
      if (X$media_erro_estilo == "barra")
        polys[[length(polys) + 1]] <- data.frame(x = p + c(-w, w, w, -w) / 2, y = c(0, 0, md, md), item = it)
      segs[[length(segs) + 1]] <- data.frame(x = p, xend = p, y = md - er, yend = md + er, cor = cc, lw = X$contorno_espessura_pt)
      segs[[length(segs) + 1]] <- data.frame(x = p - w * X$bigode_chapeu / 2, xend = p + w * X$bigode_chapeu / 2,
                                             y = c(md - er, md + er), yend = c(md - er, md + er), cor = cc, lw = X$contorno_espessura_pt)
      if (X$media_erro_estilo == "ponto")
        pts_media[[length(pts_media) + 1]] <- data.frame(x = p, y = md, fill = est[[it]]$cor, tam = X$media_tamanho_pt * 1.4, item = it)
      faixa <- range(c(faixa, 0, md + er, md - er))
      if (isTRUE(X$mostrar_n)) txt_n[[length(txt_n) + 1]] <- data.frame(x = p, y = md + er, rot = paste0("n = ", length(x)))
      next
    }
    # caixa (ou violino)
    xb0 <- p - w / 2; xb1 <- p + w / 2
    if (var == "meio_box") { xb0 <- p; xb1 <- p + w / 2 }
    if (var == "violino_box") { xb0 <- p - w * 0.12; xb1 <- p + w * 0.12 }
    if (var %in% c("violino", "violino_box")) {
      dd <- stats::density(x, adjust = X$violino_ajuste_banda, cut = if (isTRUE(X$violino_cortar)) 0 else 3)
      lv <- dd$y / max(dd$y) * X$violino_largura / 2
      polys[[length(polys) + 1]] <- data.frame(x = c(p - lv, rev(p + lv)), y = c(dd$x, rev(dd$x)), item = it)
      faixa <- range(c(faixa, dd$x))
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
        segs[[length(segs) + 1]] <- data.frame(x = mx[1], xend = mx[2], y = q[2], yend = q[2], cor = cc, lw = X$mediana_espessura_pt)
      if (isTRUE(X$outliers) && length(out))
        pts_out[[length(pts_out) + 1]] <- data.frame(x = xm, y = out, cor = cc)
      faixa <- range(c(faixa, wl))
    }
    if (isTRUE(X$media)) pts_media[[length(pts_media) + 1]] <- data.frame(x = if (var == "meio_box") (xb0 + xb1) / 2 else p, y = md,
                                                                          fill = .cor(X$media_preenchimento), tam = X$media_tamanho_pt, item = it)
    if (var %in% c("box_pontos", "meio_box")) {
      centro <- if (var == "meio_box") p - w / 4 else p
      larg <- if (var == "meio_box") min(X$pontos_largura, w / 2 * 0.9) else X$pontos_largura
      xs <- switch(X$pontos_disposicao, coluna = rep(centro, length(x)),
                   jitter = centro + stats::runif(length(x), -larg / 2, larg / 2),
                   enxame = .enxame(x, centro, larg, range(unlist(am))))
      pts_dados[[length(pts_dados) + 1]] <- data.frame(x = xs, y = x, fill = .alfa(est[[it]]$cor, X$pontos_opacidade))
    }
    if (isTRUE(X$mostrar_n)) txt_n[[length(txt_n) + 1]] <- data.frame(x = p, y = max(wl[2], q[3], max(x)), rot = paste0("n = ", length(x)))
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
        colour = .cor(if (identical(X$contorno_cor, "serie")) "black" else X$contorno_cor), linewidth = .lw(X$contorno_espessura_pt))
    }
  }
  if (length(pts_dados)) {
    pd <- do.call(rbind, pts_dados)
    cam[[length(cam) + 1]] <- geom_point(data = pd, aes(x = x, y = y), shape = X$pontos_simbolo, fill = pd$fill,
      colour = if (X$pontos_simbolo >= 21) scales::alpha("black", 0.8) else pd$fill,
      size = .tx(X$pontos_tamanho_pt), stroke = .st(0.4))
  }
  if (length(segs)) {
    sg <- do.call(rbind, segs)
    cam[[length(cam) + 1]] <- geom_segment(data = sg, aes(x = x, xend = xend, y = y, yend = yend),
      colour = sg$cor, linewidth = .lw(sg$lw), lineend = "butt")
  }
  if (length(pts_out)) {
    po <- do.call(rbind, pts_out)
    cam[[length(cam) + 1]] <- geom_point(data = po, aes(x = x, y = y), shape = X$outliers_simbolo,
      colour = po$cor, size = .tx(X$outliers_tamanho_pt), stroke = .st(0.8))
  }
  if (length(pts_media)) {
    pm <- do.call(rbind, pts_media)
    cam[[length(cam) + 1]] <- geom_point(data = pm, aes(x = x, y = y), shape = X$media_simbolo, fill = pm$fill,
      colour = .cor(if (identical(X$contorno_cor, "serie")) "black" else X$contorno_cor), size = .tx(pm$tam), stroke = .st(0.9))
  }
  if (length(txt_n)) {
    tn <- do.call(rbind, txt_n); faixa <- range(c(faixa, tn$y + 0.06 * diff(faixa)))
    cam[[length(cam) + 1]] <- if (flip) geom_text(data = tn, aes(x = x, y = y, label = rot), hjust = -0.2,
                                                   size = .tx(cfg$texto$tamanho_base_pt * 0.8), family = .fonte(cfg$texto$fonte))
      else geom_text(data = tn, aes(x = x, y = y, label = rot), vjust = -0.6,
                     size = .tx(cfg$texto$tamanho_base_pt * 0.8), family = .fonte(cfg$texto$fonte))
  }
  ax_x <- .calc_eixo(cfg$eixo_x, c(0.5, k + 0.5), categorias = itens, forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa, forcar = cfg$.interno$forcar_y)
  aes_leg <- if (length(polys) && any(!grepl("^\\.branco\\.", do.call(rbind, polys)$item))) "fill" else character(0)
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = flip, titulo_x = cfg$eixo_x$titulo %||% (A$nome_grupo %||% ""),
                   titulo_y = cfg$eixo_y$titulo %||% A$nome_valor, legenda_auto = FALSE,
                   faixa_x = c(0.5, k + 0.5), faixa_y = faixa))
}
