# =============================================================================
#  R/22_formas.R — caixas de texto e formas (retângulo, elipse, triângulo, polígono...) sobre o gráfico
# =============================================================================
#  Também é a peça que desenha as caixas de estatística (R/21_ajustes.R): uma caixa com linhas de texto,
#  fundo, borda (reta ou arredondada) e sombra. As posições podem ser em fração da caixa do gráfico
#  (unidade "fracao": 0 a 1) ou em unidades dos eixos (unidade "dados").
# =============================================================================

# Item de lista livre (forma, ajuste, caixa...): o "$" só aceita o nome EXATO (por padrão o R aceita abreviação: it$borda acharia it$borda_tipo).
.ex <- function(l) if (is.list(l)) structure(l, class = "item_exato") else l
`$.item_exato` <- function(x, name) .subset2(x, name)

# Janela que o painel mostra em um eixo, em unidades dos dados. Em escala não linear o ±Inf do annotation_custom/annotate vira
# estes números finitos (log(-Inf) daria o aviso "NaNs produced"). Escala linear: ±Inf mesmo.
.janela <- function(ax) {
  if (is.null(ax) || is.null(ax$trans) || identical(ax$escala, "linear")) return(c(-Inf, Inf))
  l <- sort(ax$trans$transform(ax$limites)); d <- diff(l)
  r <- tryCatch(sort(ax$trans$inverse(l + c(-1, 1) * (ax$mult %||% 0) * abs(d))), error = function(e) c(-Inf, Inf))
  if (all(is.finite(r))) r else c(-Inf, Inf)
}
.fin <- function(v, jan) if (is.infinite(v)) (if (v < 0) jan[1] else jan[2]) else v
# annotation_custom de um grob de .grob_forma, com a janela do painel em eixos não lineares.
.ann_forma <- function(f, info) {
  jx <- .janela(info$ax_x); jy <- .janela(info$ax_y)
  if (isTRUE(info$flip)) { jx <- c(-Inf, Inf); jy <- c(-Inf, Inf) }
  annotation_custom(f$grob, xmin = .fin(f$xmin, jx), xmax = .fin(f$xmax, jx), ymin = .fin(f$ymin, jy), ymax = .fin(f$ymax, jy))
}

.ANCORAS <- list(sup_esq = c(0, 1), sup_centro = c(0.5, 1), sup_dir = c(1, 1), centro_esq = c(0, 0.5), centro = c(0.5, 0.5),
                 centro_dir = c(1, 0.5), inf_esq = c(0, 0), inf_centro = c(0.5, 0), inf_dir = c(1, 0))
.FORMAS_TIPOS <- c("texto", "retangulo", "retangulo_arredondado", "elipse", "triangulo", "losango", "hexagono", "estrela", "poligono")

# Vértices de um polígono livre: "1,2; 3,4; 5,1" | c(1,2,3,4,5,1) | lista de pares | matriz n x 2  ->  matriz n x 2.
.ler_vertices <- function(v) {
  if (is.null(v)) return(NULL)
  if (is.character(v)) {
    partes <- trimws(strsplit(paste(v, collapse = ";"), "[;\n]")[[1]]); partes <- partes[nzchar(partes)]
    v <- suppressWarnings(as.numeric(unlist(strsplit(partes, "[,[:space:]]+"))))
  } else if (is.list(v)) v <- unlist(v)
  if (is.matrix(v)) { m <- v } else {
    if (anyNA(v) || length(v) %% 2 != 0 || length(v) < 6) return(NULL)
    m <- matrix(v, ncol = 2, byrow = TRUE)
  }
  if (ncol(m) != 2 || nrow(m) < 3 || anyNA(m)) return(NULL)
  m
}

# Contorno normalizado (0 a 1) das formas que não são retângulo.
.contorno_forma <- function(tipo) {
  th <- function(n, ini = pi / 2) ini + 2 * pi * (0:(n - 1)) / n
  switch(tipo,
    triangulo = rbind(c(0, 0), c(1, 0), c(0.5, 1)),
    losango = rbind(c(0.5, 0), c(1, 0.5), c(0.5, 1), c(0, 0.5)),
    hexagono = rbind(c(0.25, 0), c(0.75, 0), c(1, 0.5), c(0.75, 1), c(0.25, 1), c(0, 0.5)),
    elipse = { t <- th(120); cbind(0.5 + 0.5 * cos(t), 0.5 + 0.5 * sin(t)) },
    estrela = { t <- th(10); r <- rep(c(0.5, 0.2), 5); cbind(0.5 + r * cos(t), 0.5 + r * sin(t)) },
    NULL)
}

# Texto da forma: rótulo (com ^{ } e _{ } virando expoente/índice) para o textGrob.
.rotulo_forma <- function(txt, negrito = FALSE) {
  if (is.null(txt) || !nzchar(txt)) return(NULL)
  txt <- gsub("\\n", "\n", txt, fixed = TRUE)                  # "\n" digitado vira quebra de linha
  if (.tem_formatacao(txt)) as.expression(.texto(txt, negrito)) else txt
}

.estilo_fonte <- function(neg, ita) if (neg && ita) "bold.italic" else if (neg) "bold" else if (ita) "italic" else "plain"

# Uma caixa/forma: devolve list(grob, xmin, xmax, ymin, ymax) para annotation_custom().
#   it: x, y, tipo, texto, largura, altura, unidade, ancora, vertices, tamanho_pt, cor_texto, negrito, italico, alinhamento,
#       fundo, opacidade_fundo, borda_cor, borda_pt, borda_tipo, raio_pt, margem_pt, angulo, sombra, sombra_cor,
#       sombra_opacidade, sombra_dx_pt, sombra_dy_pt
#   linhas: (opcional) vetor de linhas de texto, com cores/negritos por linha — usado nas caixas de estatística
.grob_forma <- function(it, cfg, linhas = NULL, cores = NULL, negritos = NULL) {
  it <- .ex(it)
  tipo <- it$tipo %||% "texto"
  if (!tipo %in% .FORMAS_TIPOS) .erro("cfg$formas: tipo '", tipo, "' não é válido.\n  OPÇÕES: ", paste0('"', .FORMAS_TIPOS, '"', collapse = " | "))
  fonte <- .fonte(cfg$texto$fonte)
  un <- it$unidade %||% "fracao"
  if (!un %in% c("fracao", "dados")) .erro("cfg$formas: unidade deve ser \"fracao\" ou \"dados\".")
  m <- it$margem_pt %||% (if (tipo == "texto") 4 else 3)
  tam <- it$tamanho_pt %||% cfg$texto$tamanho_base_pt
  neg <- .neg(cfg, it$negrito); ita <- isTRUE(it$italico)
  cor_t <- .cor(it$cor_texto %||% cfg$texto$cor)
  alin <- it$alinhamento %||% (if (!is.null(linhas)) "esquerda" else "centro")
  hj_t <- switch(alin, esquerda = 0, centro = 0.5, direita = 1, 0.5)

  # texto: várias linhas (caixa de estatística) ou um texto só (com quebras de linha "\n")
  filhos_txt <- NULL; wt <- unit(0, "pt"); ht <- unit(0, "pt")
  if (!is.null(linhas) && length(linhas)) {
    lh <- tam * 1.3
    cores <- rep_len(cores %||% cor_t, length(linhas)); negritos <- rep_len(negritos %||% neg, length(linhas))
    gs <- lapply(seq_along(linhas), function(i) {
      x <- switch(alin, esquerda = unit(m, "pt"), centro = unit(0.5, "npc"), direita = unit(1, "npc") - unit(m, "pt"))
      textGrob(linhas[i], x = x, y = unit(1, "npc") - unit(m, "pt") - unit((i - 0.5) * lh, "pt"), hjust = hj_t, vjust = 0.5,
               gp = gpar(fontsize = tam, fontfamily = fonte, col = cores[i], fontface = .estilo_fonte(isTRUE(negritos[i]), ita)))
    })
    filhos_txt <- gs
    gm <- lapply(linhas, function(l) textGrob(l, gp = gpar(fontsize = tam, fontfamily = fonte, fontface = "plain")))
    wt <- do.call(max, lapply(gm, grobWidth)); ht <- unit(length(linhas) * lh - (lh - tam) , "pt")
  } else if (!is.null(it$texto) && nzchar(it$texto)) {
    lab <- .rotulo_forma(it$texto, neg)
    gp_t <- gpar(fontsize = tam, fontfamily = fonte, col = cor_t, fontface = if (is.expression(lab)) "plain" else .estilo_fonte(neg, ita), lineheight = 1.05)
    medida <- textGrob(lab, gp = gp_t)
    wt <- grobWidth(medida); ht <- grobHeight(medida)
    x <- switch(alin, esquerda = unit(m, "pt"), centro = unit(0.5, "npc"), direita = unit(1, "npc") - unit(m, "pt"))
    filhos_txt <- list(textGrob(lab, x = x, y = unit(0.5, "npc"), hjust = hj_t, vjust = 0.5, gp = gp_t))
  }
  tem_texto <- length(filhos_txt) > 0

  # aparência
  borda_dada <- !is.null(it$borda_cor) || !is.null(it$borda_pt) || !is.null(it$borda_tipo)
  com_borda <- if (!is.null(it$borda)) isTRUE(it$borda) else (tipo != "texto" || borda_dada)
  fundo_padrao <- if (tipo == "texto") NA else "#E6ECF5"
  fundo <- it$fundo %||% fundo_padrao
  fill <- if (length(fundo) == 1 && is.na(fundo)) NA else .alfa(.cor(fundo, "formas$fundo"), it$opacidade_fundo %||% 1)
  col_borda <- if (com_borda) .cor(it$borda_cor %||% cor_t) else NA
  lwd <- .lw(it$borda_pt %||% 0.75) * ggplot2::.pt
  lty <- it$borda_tipo %||% "solid"
  raio <- it$raio_pt %||% (if (identical(it$cantos, "arredondado")) 6 else 0)
  if (tipo == "retangulo_arredondado" && is.null(it$raio_pt) && !identical(it$cantos, "reto")) raio <- 8

  desenho <- function(dx = 0, dy = 0, gp) {
    xo <- unit(0.5, "npc") + unit(dx, "pt"); yo <- unit(0.5, "npc") + unit(dy, "pt")
    if (tipo %in% c("texto", "retangulo", "retangulo_arredondado")) {
      if (raio > 0) roundrectGrob(x = xo, y = yo, width = unit(1, "npc"), height = unit(1, "npc"), r = unit(raio, "pt"), gp = gp)
      else rectGrob(x = xo, y = yo, width = unit(1, "npc"), height = unit(1, "npc"), gp = gp)
    } else {
      pts <- if (tipo == "poligono") it$.vertices_norm else .contorno_forma(tipo)
      px <- unit(pts[, 1], "npc") + unit(dx, "pt"); py <- unit(pts[, 2], "npc") + unit(dy, "pt")
      # preenchimento e contorno separados (o contorno tracejado de polígonos some em alguns dispositivos)
      gp_f <- gp; gp_f$col <- NA
      gp_l <- gp; gp_l$fill <- NA; gp_l$linejoin <- "round"; gp_l$lineend <- "round"
      gTree(children = gList(polygonGrob(x = px, y = py, gp = gp_f),
                             if (!is.na(gp$col %||% NA)) polylineGrob(x = unit.c(px, px[1]), y = unit.c(py, py[1]), gp = gp_l)))
    }
  }

  # tamanho e posição
  largura <- it$largura; altura <- it$altura
  cx <- it$x; cy <- it$y
  if (tipo == "poligono") {
    vv <- .ler_vertices(it$vertices)
    if (is.null(vv)) .erro("cfg$formas: o polígono precisa de pelo menos 3 vértices (ex.: vertices = \"0.2,0.2; 0.4,0.2; 0.3,0.5\").")
    if (un == "dados") {
      xr <- range(vv[, 1]); yr <- range(vv[, 2])
      it$.vertices_norm <- cbind((vv[, 1] - xr[1]) / max(diff(xr), 1e-12), (vv[, 2] - yr[1]) / max(diff(yr), 1e-12))
      lim <- list(xmin = xr[1], xmax = xr[2], ymin = yr[1], ymax = yr[2])
      cx <- 0.5; cy <- 0.5; W <- unit(1, "npc"); H <- unit(1, "npc"); jx <- 0.5; jy <- 0.5
    } else {
      xr <- range(vv[, 1]); yr <- range(vv[, 2])
      it$.vertices_norm <- cbind((vv[, 1] - xr[1]) / max(diff(xr), 1e-12), (vv[, 2] - yr[1]) / max(diff(yr), 1e-12))
      lim <- list(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
      cx <- mean(xr); cy <- mean(yr); W <- unit(max(diff(xr), 1e-6), "npc"); H <- unit(max(diff(yr), 1e-6), "npc"); jx <- 0.5; jy <- 0.5
    }
  } else {
    cx <- cx %||% 0.5; cy <- cy %||% 0.5
    a <- .ANCORAS[[it$ancora %||% "centro"]]
    if (is.null(a)) .erro("cfg$formas: ancora '", it$ancora, "' não é válida.\n  OPÇÕES: ", paste0('"', names(.ANCORAS), '"', collapse = " | "))
    if (un == "dados" && !is.null(largura) && !is.null(altura)) {
      lim <- list(xmin = cx - largura / 2, xmax = cx + largura / 2, ymin = cy - altura / 2, ymax = cy + altura / 2)
      cx <- 0.5; cy <- 0.5; W <- unit(1, "npc"); H <- unit(1, "npc"); jx <- 0.5; jy <- 0.5
    } else {
      if (un == "dados") { lim <- list(xmin = cx, xmax = cx, ymin = cy, ymax = cy); cx <- 0.5; cy <- 0.5 }
      else lim <- list(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
      auto_w <- tem_texto; auto_h <- tem_texto
      if (un == "dados" && !tem_texto) .erro("cfg$formas: em unidades dos dados, informe largura e altura (ou use unidade = \"fracao\").")
      W <- if (!is.null(largura)) unit(largura, "npc") else if (auto_w) wt + unit(2 * m, "pt") else unit(0.15, "npc")
      H <- if (!is.null(altura)) unit(altura, "npc") else if (auto_h) ht + unit(2 * m, "pt") else unit(0.15, "npc")
      jx <- a[1]; jy <- a[2]
    }
  }
  # filhos: sombra, forma, texto
  gp_forma <- gpar(fill = fill, col = col_borda, lwd = lwd, lty = lty)
  fil <- list()
  if (isTRUE(it$sombra)) {
    gp_s <- gpar(fill = .alfa(.cor(it$sombra_cor %||% "grey20"), it$sombra_opacidade %||% 0.3), col = NA)
    fil[[1]] <- desenho(it$sombra_dx_pt %||% 3, -(it$sombra_dy_pt %||% 3), gp_s)
  }
  if (tipo != "texto" || !(length(fill) == 1 && is.na(fill)) || com_borda) fil[[length(fil) + 1]] <- desenho(0, 0, gp_forma)
  fil <- c(fil, filhos_txt)
  vp <- viewport(x = unit(cx, "npc"), y = unit(cy, "npc"), width = W, height = H, just = c(jx, jy), angle = it$angulo %||% 0)
  list(grob = gTree(children = gList(gTree(children = do.call(gList, fil), vp = vp))),   # (o annotation_custom troca o vp do grob de fora)
        xmin = lim$xmin, xmax = lim$xmax, ymin = lim$ymin, ymax = lim$ymax)
}

# Camadas (annotation_custom) de uma lista de formas. Sai: list(antes, depois).
.camadas_formas <- function(cfg, info = list()) {
  antes <- list(); depois <- list()
  parte <- cfg$.interno$parte
  for (i in seq_along(cfg$formas)) {
    it <- .ex(cfg$formas[[i]])
    if (identical(parte, "inferior") && identical(it$unidade %||% "fracao", "fracao")) next      # quebra de eixo: formas em fração ficam na parte de cima
    f <- .grob_forma(it, cfg)
    ac <- .ann_forma(f, info)
    if (identical(it$camada, "atras")) antes[[length(antes) + 1]] <- ac else depois[[length(depois) + 1]] <- ac
  }
  im <- .camadas_imagens(cfg, info)                  # figuras anexadas (R/23_imagens.R)
  list(antes = c(antes, im$antes), depois = c(depois, im$depois))
}
