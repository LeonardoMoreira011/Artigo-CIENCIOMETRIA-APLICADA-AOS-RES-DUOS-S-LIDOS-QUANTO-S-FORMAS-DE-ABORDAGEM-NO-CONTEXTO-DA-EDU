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
    if (cfg$grafico$tipo %in% c("pizza", "mapa_mundo", "mapa_brasil") || isTRUE(cfg$paineis$ativo)) return(NULL)
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
    message(.traduzir_msg(paste0("Legenda reduzida para ", round(100 * esc / esc0), "% para caber dentro da caixa ",
            "(cfg$legenda$ajustar_caixa <- FALSE desliga; legenda$escala, ou menos séries/colunas, também ajudam).")))
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
.geometria_legenda <- function(g, cfg, prep = NULL) {
  cfg <- .resolver_herancas(cfg)                                  # (a barra de cores dos mapas pode mudar a posição da legenda)
  lg <- cfg$legenda
  if (!identical(lg$posicao, "dentro") || isFALSE(lg$mostrar)) return(NULL)
  prep <- prep %||% .preparar_saida(g, cfg)                       # o app passa o 'prep' já calculado: o gráfico é montado uma vez só
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

# Onde estão o título do gráfico e os títulos dos eixos na página (frações da página: x, y de cima, largura, altura), para o app
# desenhar zonas clicáveis sobre a prévia. Título ausente: uma faixa logo acima do painel. Sai NULL se não for possível medir.
.geometria_zonas <- function(g, cfg, prep = NULL) {
  prep <- prep %||% .preparar_saida(g, cfg)
  dtmp <- .abrir_dispositivo_tmp(prep$larg, prep$alt); on.exit(grDevices::dev.off(dtmp), add = TRUE)
  gt <- prep$grob %||% attr(g, "gt") %||% ggplot2::ggplotGrob(g)
  if (!inherits(gt, "gtable") || !"panel" %in% gt$layout$name) return(NULL)
  tam <- function(u, total_in, conv) {
    nulo <- grid::unitType(u) == "null"; r <- numeric(length(u))
    if (any(!nulo)) r[!nulo] <- conv(u[!nulo], "in", valueOnly = TRUE)
    if (any(nulo)) { v <- as.numeric(u[nulo]); r[nulo] <- max(total_in - sum(r[!nulo]), 0) * v / sum(v) }
    r
  }
  w <- tam(gt$widths, prep$larg, grid::convertWidth); h <- tam(gt$heights, prep$alt, grid::convertHeight)
  caixa <- function(nome) {
    k <- which(gt$layout$name == nome); if (!length(k)) return(NULL); k <- k[1]; lay <- gt$layout[k, ]
    list(l = sum(w[seq_len(lay$l - 1)]), t = sum(h[seq_len(lay$t - 1)]), w = sum(w[lay$l:lay$r]), h = sum(h[lay$t:lay$b]), vazio = inherits(gt$grobs[[k]], "zeroGrob"))
  }
  fr <- function(b) round(pmin(pmax(c(b$l / prep$larg, b$t / prep$alt, b$w / prep$larg, b$h / prep$alt), 0), 1), 5)
  pan <- caixa("panel"); out <- list()
  tit <- caixa("title")
  if (!is.null(tit) && !tit$vazio && tit$h > 0.05) out$titulo <- fr(tit)
  else out$titulo <- fr(list(l = pan$l, t = max(pan$t - 0.28, 0), w = pan$w, h = min(0.28, pan$t)))
  xl <- caixa("xlab-b"); if (!is.null(xl) && !xl$vazio && xl$h > 0.05) out$xlab <- fr(xl)
  yl <- caixa("ylab-l"); if (!is.null(yl) && !yl$vazio && yl$w > 0.05) out$ylab <- fr(yl)
  out
}

# Intervalos do painel (x e y, na unidade dos dados) para caixas em "unidades dos eixos" poderem ser movidas com o mouse. Só vale com eixos
# contínuos sem transformação (nem log, nem data) e coordenadas cartesianas comuns; fora disso sai NULL (essas caixas ficam sem moldura).
.faixa_dados_painel <- function(g) {
  tryCatch({
    if (!identical(class(g$coordinates)[1], "CoordCartesian")) return(NULL)
    b <- ggplot2::ggplot_build(g); pp <- b$layout$panel_params[[1]]
    sx <- b$layout$panel_scales_x[[1]]; sy <- b$layout$panel_scales_y[[1]]
    nome <- function(sc) { tr <- sc$trans %||% sc$transformation; if (is.null(tr)) NA_character_ else tr$name }
    if (!inherits(sx, "ScaleContinuous") || !inherits(sy, "ScaleContinuous") || !identical(nome(sx), "identity") || !identical(nome(sy), "identity")) return(NULL)
    xr <- as.numeric(pp$x$continuous_range); yr <- as.numeric(pp$y$continuous_range)
    if (length(xr) != 2 || length(yr) != 2 || !all(is.finite(c(xr, yr))) || diff(xr) <= 0 || diff(yr) <= 0) return(NULL)
    list(x = xr, y = yr)
  }, error = function(e) NULL)
}

# Onde está cada caixa móvel (caixa de estatística, texto, forma, figura anexada) na página, para o app desenhar uma moldura que se arrasta
# e se estica sobre a prévia. Vale para caixas em "fração da caixa do gráfico" e, com eixos contínuos sem transformação, também para as em
# unidades dos eixos; só para gráficos de um painel (sem quebra de eixo). Sai NULL ou list(painel = c(esq, topo, larg, alt), itens = lista,
# faixa = list(x, y) quando há caixas em unidades dos eixos); tudo em fração da página (topo = de cima).
# Cada item: id ("cx1", "fm2", "im1": prefixo + número do cartão no app), grupo, tipo ("estatistica" | "texto" | "forma" | "figura"), forma, rect,
# jx/jy (ponto da caixa que fica em x,y), auto (a caixa tem o tamanho do texto/da figura: esticar muda o tamanho da letra / mantém a proporção),
# tam (pt), dados (TRUE = x, y, largura e altura estão nas unidades dos eixos), regiao (dados: o retângulo é a própria região largura × altura)
# e vert (vértices em fração do painel).
.geometria_caixas <- function(g, cfg, prep = NULL) {
  if (!is.null(attr(g, "partes")) || inherits(g, "patchwork") || is.null(g$layers)) return(NULL)
  ls <- Filter(function(l) !is.null(attr(l, "caixa")) && (isTRUE(attr(l, "caixa")$fracao) || isTRUE(attr(l, "caixa")$dados)), g$layers)
  if (!length(ls) && is.null(attr(g, "info")$rotulos)) return(NULL)
  faixa <- if (any(vapply(ls, function(l) isTRUE(attr(l, "caixa")$dados), NA))) .faixa_dados_painel(g) else NULL
  ls <- Filter(function(l) { d <- attr(l, "caixa"); isTRUE(d$fracao) || (isTRUE(d$dados) && !is.null(faixa) && all(is.finite(d$lim))) }, ls)
  rot <- attr(g, "info")$rotulos                                    # nomes (PCA/CA/CCA, mapas) que se arrastam
  if (!length(ls) && is.null(rot)) return(NULL)
  prep <- prep %||% .preparar_saida(g, cfg)
  dtmp <- .abrir_dispositivo_tmp(prep$larg, prep$alt); on.exit(grDevices::dev.off(dtmp), add = TRUE)
  gt <- prep$grob %||% attr(g, "gt") %||% ggplot2::ggplotGrob(g)
  if (!inherits(gt, "gtable") || sum(gt$layout$name == "panel") != 1) return(NULL)
  tam <- function(u, total_in, conv) {
    nulo <- grid::unitType(u) == "null"; r <- numeric(length(u))
    if (any(!nulo)) r[!nulo] <- conv(u[!nulo], "in", valueOnly = TRUE)
    if (any(nulo)) { v <- as.numeric(u[nulo]); r[nulo] <- max(total_in - sum(r[!nulo]), 0) * v / sum(v) }
    r
  }
  w <- tam(gt$widths, prep$larg, grid::convertWidth); h <- tam(gt$heights, prep$alt, grid::convertHeight)
  lay <- gt$layout[gt$layout$name == "panel", ]
  pl <- sum(w[seq_len(lay$l - 1)]); pt <- sum(h[seq_len(lay$t - 1)]); pw <- sum(w[lay$l:lay$r]); ph <- sum(h[lay$t:lay$b])
  grid::pushViewport(grid::viewport(width = grid::unit(pw, "in"), height = grid::unit(ph, "in")))
  pg <- c(prep$larg, prep$alt)
  # medida em polegadas: "npc" é relativo à região da caixa (o painel, ou o retângulo em unidades dos eixos); o resto (texto, pt) é absoluto
  em_in <- function(u, ref, conv) if (all(grid::unitType(u) == "npc")) as.numeric(u) * ref else conv(u, "in", valueOnly = TRUE)
  itens <- lapply(ls, function(l) {
    d <- attr(l, "caixa"); dados <- isTRUE(d$dados)
    if (dados) { fa <- (d$lim[1] - faixa$x[1]) / diff(faixa$x); fb <- (d$lim[2] - faixa$x[1]) / diff(faixa$x)
                 ga <- (d$lim[3] - faixa$y[1]) / diff(faixa$y); gb <- (d$lim[4] - faixa$y[1]) / diff(faixa$y) }
    else { fa <- 0; fb <- 1; ga <- 0; gb <- 1 }
    rw <- (fb - fa) * pw; rh <- (gb - ga) * ph
    bw <- em_in(d$W, rw, grid::convertWidth)
    bh <- if (!is.null(d$H)) em_in(d$H, rh, grid::convertHeight) else bw * d$prop
    esq <- pl + fa * pw + d$cx * rw - d$jx * bw; base <- ga * ph + d$cy * rh - d$jy * bh
    vert <- if (!is.null(d$vert)) {
      v <- d$vert
      if (dados) v <- cbind((v[, 1] - faixa$x[1]) / diff(faixa$x), (v[, 2] - faixa$y[1]) / diff(faixa$y))
      unname(split(round(v, 5), row(v)))
    }
    Filter(Negate(is.null), list(id = d$id, grupo = d$grupo, tipo = d$tipo, forma = d$forma, jx = d$jx, jy = d$jy, auto = isTRUE(d$auto), tam = d$tam,
         dados = if (dados) TRUE, regiao = if (dados && all(grid::unitType(d$W) == "npc")) TRUE,
         rect = unname(round(c(esq / pg[1], (pt + ph - base - bh) / pg[2], bw / pg[1], bh / pg[2]), 5)), vert = vert))
  })
  if (!is.null(rot)) {                                              # nomes arrastáveis: o retângulo de cada um, em fração da página
    ri <- rot$itens; fxr <- (ri$x - rot$lim_x[1]) / diff(rot$lim_x); fyr <- (ri$y - rot$lim_y[1]) / diff(rot$lim_y)
    rect <- cbind((pl + fxr * pw - ri$w_in / 2) / pg[1], (pt + (1 - fyr) * ph - ri$h_in / 2) / pg[2], ri$w_in / pg[1], ri$h_in / pg[2])
    itens <- c(itens, lapply(seq_len(nrow(ri)), function(i)
      list(id = paste0("rt", i), tipo = "rotulo", chave = ri$chave[i], campo = rot$campo, grupo = ri$conj[i], rect = unname(round(rect[i, ], 5)),
           lx = rot$lim_x, ly = rot$lim_y)))
  }
  out <- list(painel = round(c(pl / pg[1], pt / pg[2], pw / pg[1], ph / pg[2]), 5), itens = unname(itens))
  if (!is.null(faixa)) out$faixa <- faixa
  out
}

