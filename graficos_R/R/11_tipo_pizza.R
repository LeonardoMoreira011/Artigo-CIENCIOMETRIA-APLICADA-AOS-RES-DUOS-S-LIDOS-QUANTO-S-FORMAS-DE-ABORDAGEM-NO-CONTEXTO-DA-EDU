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
