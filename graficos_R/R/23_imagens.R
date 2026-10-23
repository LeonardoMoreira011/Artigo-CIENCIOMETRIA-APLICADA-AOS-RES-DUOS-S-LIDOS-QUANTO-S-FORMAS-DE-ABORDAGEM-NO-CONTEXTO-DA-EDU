# =============================================================================
#  R/23_imagens.R — figuras anexadas (PNG ou JPEG) sobre o gráfico: logotipo, esquema, foto da amostra...
# =============================================================================
#  cfg$imagens é uma lista; cada item: arquivo, x, y, largura, altura, unidade ("fracao" | "dados"), ancora, opacidade,
#  angulo, borda_cor, borda_pt, borda_tipo, camada ("frente" | "atras").  Precisa dos pacotes png e jpeg (00_instalar_pacotes.R).
# =============================================================================

.cache_imagens <- new.env()
.IMAGEM_MAX_PX <- 2400            # lado maior; figuras maiores são reduzidas (só para desenhar)

# Lê a figura. Sai: list(r, g, b, a, alt, larg) — canais de 0 a 1 em matrizes (altura x largura).
.ler_imagem <- function(arq) {
  if (is.null(arq) || !is.character(arq) || length(arq) != 1 || !nzchar(arq)) .erro("cfg$imagens: cada figura precisa de 'arquivo' (caminho de um PNG ou JPEG).")
  if (!file.exists(arq)) .erro("cfg$imagens: não achei a figura '", arq, "'.")
  chave <- paste(normalizePath(arq, winslash = "/"), file.mtime(arq), file.size(arq))
  if (!is.null(.cache_imagens[[chave]])) return(.cache_imagens[[chave]])
  ext <- tolower(tools::file_ext(arq))
  if (!ext %in% c("png", "jpg", "jpeg")) .erro("cfg$imagens: formato '.", ext, "' não é aceito; use PNG ou JPEG.")
  pk <- if (ext == "png") "png" else "jpeg"
  if (!.tem(pk)) .erro("Para usar figuras é preciso o pacote ", pk, ": rode install.packages(\"", pk, "\") (ou 00_instalar_pacotes.R).")
  a <- tryCatch(if (ext == "png") png::readPNG(arq) else jpeg::readJPEG(arq), error = function(e) .erro("cfg$imagens: não consegui ler '", arq, "' (arquivo corrompido?)."))
  d <- dim(a)
  if (length(d) == 2) a <- array(a, c(d, 1)); d <- dim(a)
  ch <- d[3]
  canal <- function(i) a[, , i]
  R <- G <- B <- NULL; A <- matrix(1, d[1], d[2])
  if (ch %in% c(1, 2)) { R <- G <- B <- canal(1); if (ch == 2) A <- canal(2) } else { R <- canal(1); G <- canal(2); B <- canal(3); if (ch >= 4) A <- canal(4) }
  passo <- ceiling(max(d[1:2]) / .IMAGEM_MAX_PX)
  if (passo > 1) { i <- seq(1, d[1], by = passo); j <- seq(1, d[2], by = passo); R <- R[i, j, drop = FALSE]; G <- G[i, j, drop = FALSE]; B <- B[i, j, drop = FALSE]; A <- A[i, j, drop = FALSE] }
  out <- list(r = R, g = G, b = B, a = A, alt = nrow(R), larg = ncol(R))
  .cache_imagens[[chave]] <- out
  out
}

# Raster (matriz de cores) com a opacidade pedida.
.raster_imagem <- function(im, opacidade = 1) {
  matrix(grDevices::rgb(as.vector(im$r), as.vector(im$g), as.vector(im$b), alpha = pmin(pmax(as.vector(im$a) * opacidade, 0), 1)), nrow = im$alt)
}

# Grob que mantém a proporção da figura: a largura vem do painel (npc) e a altura é calculada na hora de desenhar.
.grob_imagem_prop <- function(r, prop, largura, x, y, just, angulo, gp_borda) {
  gTree(r = r, prop = prop, largura = largura, x = x, y = y, just = just, angulo = angulo, gp_borda = gp_borda, cl = "imagem_prop")
}
makeContent.imagem_prop <- function(x) {
  w <- grid::convertWidth(x$largura, "in", valueOnly = TRUE); h <- w * x$prop
  vp <- viewport(x = x$x, y = x$y, width = unit(w, "in"), height = unit(h, "in"), just = x$just, angle = x$angulo)
  f <- list(rasterGrob(x$r, width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE),
            if (!is.null(x$gp_borda)) rectGrob(gp = x$gp_borda))
  grid::setChildren(x, do.call(gList, list(gTree(children = do.call(gList, Filter(Negate(is.null), f)), vp = vp))))
}
if (requireNamespace("grid", quietly = TRUE)) registerS3method("makeContent", "imagem_prop", makeContent.imagem_prop, envir = asNamespace("grid"))

# Uma figura: devolve list(grob, xmin, xmax, ymin, ymax) para annotation_custom() (mesmo formato de .grob_forma).
.grob_imagem <- function(it, cfg) {
  it <- .ex(it)
  un <- it$unidade %||% "fracao"
  if (!un %in% c("fracao", "dados")) .erro("cfg$imagens: unidade deve ser \"fracao\" ou \"dados\".")
  a <- .ANCORAS[[it$ancora %||% "centro"]]
  if (is.null(a)) .erro("cfg$imagens: ancora '", it$ancora, "' não é válida.\n  OPÇÕES: ", paste0('"', names(.ANCORAS), '"', collapse = " | "))
  im <- .ler_imagem(it$arquivo)
  r <- .raster_imagem(im, it$opacidade %||% 1)
  prop <- im$alt / im$larg
  gp_b <- if (!is.null(it$borda_cor) || !is.null(it$borda_pt) || !is.null(it$borda_tipo))
    gpar(col = .cor(it$borda_cor %||% "black"), fill = NA, lwd = .lw(it$borda_pt %||% 0.75) * ggplot2::.pt, lty = it$borda_tipo %||% "solid") else NULL
  cx <- it$x %||% 0.5; cy <- it$y %||% 0.5; ang <- it$angulo %||% 0
  if (un == "dados") {
    if (is.null(it$largura) || is.null(it$altura)) .erro("cfg$imagens: em unidades dos dados, informe largura e altura (ou use unidade = \"fracao\").")
    f <- gList(rasterGrob(r, width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE), if (!is.null(gp_b)) rectGrob(gp = gp_b))
    g <- gTree(children = gList(gTree(children = f, vp = viewport(angle = ang))))
    return(list(grob = g, xmin = cx - it$largura / 2, xmax = cx + it$largura / 2, ymin = cy - it$altura / 2, ymax = cy + it$altura / 2, caixa = list(fracao = FALSE)))
  }
  larg <- it$largura %||% 0.2
  if (!is.null(it$altura)) {                     # largura e altura dadas: preenche o retângulo (pode deformar)
    vp <- viewport(x = unit(cx, "npc"), y = unit(cy, "npc"), width = unit(larg, "npc"), height = unit(it$altura, "npc"), just = a, angle = ang)
    f <- gList(rasterGrob(r, width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE), if (!is.null(gp_b)) rectGrob(gp = gp_b))
    g <- gTree(children = gList(gTree(children = f, vp = vp)))
  } else g <- gTree(children = gList(.grob_imagem_prop(r, prop, unit(larg, "npc"), unit(cx, "npc"), unit(cy, "npc"), a, ang, gp_b)))
  list(grob = g, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf,
       caixa = list(W = unit(larg, "npc"), H = if (!is.null(it$altura)) unit(it$altura, "npc"), prop = prop, cx = cx, cy = cy, jx = a[1], jy = a[2], fracao = TRUE,
                    tipo = "figura", forma = "figura", auto = is.null(it$altura)))
}

# Camadas das figuras. Sai: list(antes, depois).
.camadas_imagens <- function(cfg, info = list()) {
  antes <- list(); depois <- list(); parte <- cfg$.interno$parte
  for (i in seq_along(cfg$imagens)) {
    it <- .ex(cfg$imagens[[i]]); if (isFALSE(it$ativo)) next
    if (identical(parte, "inferior") && identical(it$unidade %||% "fracao", "fracao")) next
    f <- .grob_imagem(it, cfg)
    ac <- .ann_forma(f, info); attr(ac, "caixa") <- c(f$caixa, list(grupo = "imagens", id = paste0("im", it$cartao %||% i)))
    if (identical(it$camada, "atras")) antes[[length(antes) + 1]] <- ac else depois[[length(depois) + 1]] <- ac
  }
  list(antes = antes, depois = depois)
}
