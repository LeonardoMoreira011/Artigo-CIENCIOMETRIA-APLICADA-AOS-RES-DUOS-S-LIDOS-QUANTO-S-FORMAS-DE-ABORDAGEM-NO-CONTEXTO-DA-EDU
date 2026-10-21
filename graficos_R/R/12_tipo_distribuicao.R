# =============================================================================
#  R/12_tipo_distribuicao.R — histograma, densidade e ECDF
# =============================================================================

# ---- Distribuições ----------------------------------------------------------------
# Entra: dados e cfg. Sai: lista de amostras (uma por série ou grupo) para distribuições e boxplot.
.amostras <- function(dados, cfg) {
  gcol <- cfg$grafico$coluna_grupo
  if (!is.null(gcol)) {
    gcol <- .coluna(dados, gcol, "cfg$grafico$coluna_grupo")
    vcol <- .colunas_y(dados, cfg, excluir = gcol)[1]
    g <- as.character(dados[[gcol]])
    itens <- unique(g[!is.na(g)])
    if (!is.null(cfg$grafico$ordem_itens)) itens <- c(intersect(cfg$grafico$ordem_itens, itens),
                                                      setdiff(itens, cfg$grafico$ordem_itens))
    am <- lapply(itens, function(i) { v <- dados[[vcol]][g %in% i]; v[!is.na(v)] })
    return(list(am = stats::setNames(am, itens), nome_valor = vcol, nome_grupo = gcol))
  }
  ycols <- .colunas_y(dados, cfg, excluir = NULL)
  am <- lapply(ycols, function(y) { v <- dados[[y]]; v[!is.na(v)] })
  list(am = stats::setNames(am, ycols), nome_valor = if (length(ycols) == 1) ycols else .rot("Valor"), nome_grupo = NULL)
}

# Histograma, densidade e ECDF. Entra: dados e cfg. Sai: list(camadas, info).
.construir_distribuicao <- function(dados, cfg) {
  D <- cfg$distribuicao; tipo <- cfg$grafico$tipo
  A <- .amostras(dados, cfg); am <- A$am; itens <- names(am)
  vazio <- vapply(am, length, 0) < 2
  if (any(vazio)) .erro("Distribuição: a(s) série(s) ", paste(itens[vazio], collapse = ", "),
                        " tem(têm) menos de 2 valores.")
  est <- .estilos(cfg, itens)
  multi <- length(itens) > 1
  todos <- unlist(am)
  cam <- list(); faixa_y <- 0; aes_leg <- character(0); tit_y <- NULL
  escalar <- function(dens, n, w) switch(D$medida, contagem = dens * n * w, frequencia = dens * w,
                                         percentual = dens * w * 100, densidade = dens)
  if (tipo == "histograma") {
    if (!is.null(D$largura_classe)) {
      w <- D$largura_classe
      ini <- D$inicio_classe %||% (floor(min(todos) / w) * w)
      quebras <- seq(ini, max(todos) + w, by = w)
      quebras <- quebras[seq_len(max(2, which(quebras > max(todos))[1]))]
    } else if (!is.null(D$n_classes)) {
      ini <- D$inicio_classe %||% min(todos)
      quebras <- seq(ini, max(todos), length.out = D$n_classes + 1)
    } else {
      quebras <- graphics::hist(todos, plot = FALSE)$breaks
      if (!is.null(D$inicio_classe)) { w <- diff(quebras)[1]; quebras <- seq(D$inicio_classe, max(todos) + w, by = w) }
    }
    if (min(todos) < min(quebras)) .erro("distribuicao$inicio_classe (", min(quebras), ") é maior que o menor dado (",
                                         min(todos), ").")
    ret <- do.call(rbind, lapply(itens, function(i) {
      h <- graphics::hist(am[[i]], breaks = quebras, plot = FALSE, right = FALSE, include.lowest = TRUE)
      n <- length(am[[i]]); w <- diff(quebras)
      y <- switch(D$medida, contagem = h$counts, frequencia = h$counts / n,
                  percentual = h$counts / n * 100, densidade = h$counts / (n * w))
      data.frame(xmin = quebras[-length(quebras)], xmax = quebras[-1], ymin = 0, ymax = y, serie = i)
    }))
    ret$serie <- factor(ret$serie, levels = itens)
    if (multi && all(vapply(est, function(e) e$opf >= 1, TRUE))) {
      cfg2 <- cfg; cfg2$serie_padrao$opacidade_preenchimento <- D$opacidade_multiplas %||% 0.55
      est <- .estilos(cfg2, itens)
    }
    cam[[1]] <- geom_rect(data = ret, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = serie),
                          colour = if (is.na(D$contorno_cor)) NA else .cor(D$contorno_cor),
                          linewidth = .lw(D$contorno_espessura_pt))
    aes_leg <- "fill"; faixa_y <- c(0, ret$ymax); faixa_x <- range(quebras)
    tit_y <- switch(D$medida, contagem = .rot("Contagem"), frequencia = .rot("Frequência relativa"),
                    percentual = .rot("Frequência (%)"), densidade = .rot("Densidade"))
    curvas <- list()
    for (i in itens) {
      x <- am[[i]]; n <- length(x); w <- diff(quebras)[1]
      grade <- seq(min(quebras), max(quebras), length.out = 300)
      if (isTRUE(D$curva_densidade)) {
        dd <- stats::density(x, adjust = D$ajuste_banda, from = min(grade), to = max(grade), n = 300)
        curvas[[length(curvas) + 1]] <- data.frame(x = dd$x, y = escalar(dd$y, n, w), serie = i, tipo = "dens")
      }
      if (isTRUE(D$curva_normal)) {
        curvas[[length(curvas) + 1]] <- data.frame(x = grade,
                                                   y = escalar(stats::dnorm(grade, mean(x), stats::sd(x)), n, w),
                                                   serie = i, tipo = "normal")
      }
    }
    if (length(curvas)) {
      cv <- do.call(rbind, curvas); cv$serie <- factor(cv$serie, levels = itens)
      cam[[length(cam) + 1]] <- geom_line(
        data = cv, aes(x = x, y = y, colour = serie, group = interaction(serie, tipo), linetype = tipo),
        linewidth = .lw(D$espessura_curva_pt), show.legend = FALSE)
      cam[[length(cam) + 1]] <- scale_linetype_manual(values = c(dens = "solid", normal = "dashed"), guide = "none")
      aes_leg <- c(aes_leg, "colour"); faixa_y <- c(faixa_y, cv$y)
    }
  } else if (tipo == "densidade") {
    dd <- do.call(rbind, lapply(itens, function(i) {
      d <- stats::density(am[[i]], adjust = D$ajuste_banda)
      data.frame(x = d$x, y = d$y, serie = i)
    }))
    dd$serie <- factor(dd$serie, levels = itens)
    if (isTRUE(D$preencher_densidade)) {
      for (i in itens) {
        e <- est[[i]]; s <- dd[dd$serie == i, ]
        fill <- if (identical(cfg$cores$preenchimento, "gradiente"))
          .gradiente(.alfa(e$cor, D$opacidade_area), .alfa(e$cor2, D$opacidade_area), cfg$cores$gradiente_direcao)
          else .alfa(e$cor, D$opacidade_area)
        cam[[length(cam) + 1]] <- geom_ribbon(data = s, aes(x = x, ymin = 0, ymax = y), fill = fill, colour = NA)
      }
    }
    cam[[length(cam) + 1]] <- geom_line(data = dd, aes(x = x, y = y, colour = serie, linetype = serie,
                                                       linewidth = serie, alpha = serie))
    aes_leg <- c("colour", "linetype", "linewidth", "alpha")
    faixa_y <- c(0, dd$y); faixa_x <- range(dd$x); tit_y <- .rot("Densidade")
  } else {
    ec <- do.call(rbind, lapply(itens, function(i) {
      x <- sort(am[[i]]); n <- length(x)
      data.frame(x = c(x[1], x), y = c(0, seq_len(n) / n), serie = i)
    }))
    ec$serie <- factor(ec$serie, levels = itens)
    cam[[1]] <- geom_step(data = ec, aes(x = x, y = y, colour = serie, linetype = serie, linewidth = serie,
                                         alpha = serie),
                          direction = "hv")
    aes_leg <- c("colour", "linetype", "linewidth", "alpha")
    faixa_y <- c(0, 1); faixa_x <- range(ec$x); tit_y <- .rot("Probabilidade acumulada")
  }
  if (isTRUE(D$marcas_rug)) {
    escura <- vapply(itens, function(i) grDevices::colorRampPalette(c(est[[i]]$cor, "black"))(3)[2], "")
    rg <- data.frame(x = todos, cor = rep(escura, vapply(am, length, 0)))
    cam[[length(cam) + 1]] <- geom_rug(data = rg, aes(x = x), colour = rg$cor, sides = "b",
                                       length = unit(D$rug_comprimento_pt, "pt"), linewidth = .lw(D$rug_espessura_pt),
                                       inherit.aes = FALSE)
  }
  ax_x <- .calc_eixo(cfg$eixo_x, faixa_x, forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = FALSE,
                   titulo_x = cfg$eixo_x$titulo %||% A$nome_valor, titulo_y = cfg$eixo_y$titulo %||% tit_y,
                   legenda_auto = TRUE, faixa_x = faixa_x, faixa_y = faixa_y))
}
