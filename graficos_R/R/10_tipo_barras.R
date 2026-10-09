# =============================================================================
#  R/10_tipo_barras.R — barras
# =============================================================================

# ---- Barras ---------------------------------------------------------------------
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
    if (!is.null(cfg$grafico$ordem_itens) && all(cfg$grafico$ordem_itens %in% cats) && !any(cfg$grafico$ordem_itens %in% ycols))
      cats <- c(cfg$grafico$ordem_itens, setdiff(cats, cfg$grafico$ordem_itens))
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
    rr$rot <- if (B$arranjo == "empilhado_100") paste0(.fmt_num(rr$valor, B$rotulos_casas), "%") else .fmt_num(rr$valor, B$rotulos_casas)
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
  if (isTRUE(B$rotulos_valor) && B$rotulos_posicao == "fora") faixa_y <- c(faixa_y, max(faixa_y) + 0.08 * diff(range(faixa_y)))
  ax_x <- .calc_eixo(cfg$eixo_x, c(r$xmin, r$xmax), categorias = cats, forcar = cfg$.interno$forcar_x)
  if (numerico && is.null(cfg$eixo_x$inicio) && is.null(cfg$.interno$forcar_x)) {
    ax_x <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(inicio = min(r$xmin) - (1 - B$largura) * passo / 2,
                                                         fim = max(r$xmax) + (1 - B$largura) * passo / 2)), c(r$xmin, r$xmax))
  }
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  tit_y <- cfg$eixo_y$titulo %||% (if (B$arranjo == "empilhado_100") "Percentual (%)" else if (n == 1) ycols else "Valor")
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = flip, titulo_x = cfg$eixo_x$titulo %||% xcol,
                   titulo_y = tit_y, legenda_auto = TRUE, faixa_x = c(r$xmin, r$xmax), faixa_y = faixa_y))
}
