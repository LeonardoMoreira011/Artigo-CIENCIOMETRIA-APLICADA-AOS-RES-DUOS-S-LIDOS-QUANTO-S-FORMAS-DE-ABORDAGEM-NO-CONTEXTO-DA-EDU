# =============================================================================
#  R/11_tipo_pizza.R — pizza e rosca
# =============================================================================

# ---- Pizza ----------------------------------------------------------------------
.construir_pizza <- function(dados, cfg) {
  P <- cfg$pizza
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycol <- .colunas_y(dados, cfg, excluir = xcol)[1]
  cat_ <- as.character(dados[[xcol]]); val <- dados[[ycol]]
  ok <- !is.na(cat_) & !is.na(val)
  if (any(val[ok] < 0)) .aviso("Pizza: valores negativos em '", ycol, "' foram ignorados.")
  ok <- ok & val > 0
  cat_ <- cat_[ok]; val <- val[ok]
  if (anyDuplicated(cat_)) { ag <- tapply(val, factor(cat_, levels = unique(cat_)), sum); cat_ <- names(ag); val <- as.numeric(ag) }
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
    rr <- switch(P$rotulos_posicao, dentro = if (r0 > 0) (1 + r0) / 2 else 0.62,
                 borda = 1.08, fora = P$rotulos_distancia)
    lado <- sin(am)
    hj <- if (P$rotulos_posicao == "dentro") 0.5 else if (abs(lado) < 0.15) 0.5 else if (lado > 0) 0 else 1
    corr <- if (identical(P$rotulos_cor, "auto")) {
      if (P$rotulos_posicao == "dentro") (if (.luminancia(est[[i]]$cor) < 0.5) "white" else "black") else cfg$texto$cor
    } else .cor(P$rotulos_cor)
    if (nzchar(texto) && pct[i] >= (P$ocultar_rotulo_abaixo %||% 0))
      rot[[length(rot) + 1]] <- data.frame(x = cx + rr * sin(am), y = cy + rr * cos(am), rot = texto,
        hj = hj, cor = corr, gx0 = cx + 1.0 * sin(am), gy0 = cy + 1.0 * cos(am),
        gx1 = cx + (rr - 0.07) * sin(am), gy1 = cy + (rr - 0.07) * cos(am))
  }
  pl <- do.call(rbind, polys); pl$serie <- factor(pl$serie, levels = cat_)
  cam <- list(geom_polygon(data = pl, aes(x = x, y = y, group = serie, fill = serie),
                           colour = if (is.na(P$contorno_cor)) NA else .cor(P$contorno_cor),
                           linewidth = .lw(P$contorno_espessura_pt)))
  lim <- 1 + max(c(0, P$deslocamento_explosao / 100 * (length(P$explodir) > 0)))
  if (length(rot)) {
    rd <- do.call(rbind, rot)
    if (P$rotulos_posicao == "fora" && isTRUE(P$linha_guia))
      cam[[length(cam) + 1]] <- geom_segment(data = rd, aes(x = gx0, y = gy0, xend = gx1, yend = gy1),
                                             colour = cfg$texto$cor, linewidth = .lw(0.6))
    cam[[length(cam) + 1]] <- geom_text(data = rd, aes(x = x, y = y, label = rot), hjust = rd$hj,
      colour = rd$cor, size = .tx(P$rotulos_tamanho_pt), lineheight = 0.95, family = .fonte(cfg$texto$fonte))
    if (P$rotulos_posicao != "dentro") lim <- max(lim, max(abs(c(rd$x, rd$y))) + 0.15)
  }
  leg <- !("categoria" %in% P$rotulos)
  list(camadas = c(cam, .escalas_legenda(est, "fill", cfg)),
       info = list(pizza = TRUE, lim = lim, legenda_auto = leg))
}
