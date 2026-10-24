# =============================================================================
#  R/23_imagens.R — figuras anexadas (PNG ou JPEG) sobre o gráfico: logotipo, esquema, foto da amostra...
# =============================================================================
#  cfg$imagens é uma lista; cada item: arquivo, x, y, largura, altura, unidade ("fracao" | "dados"), ancora, opacidade,
#  angulo, borda_cor, borda_pt, borda_tipo, camada ("frente" | "atras").  Precisa dos pacotes png e jpeg (00_instalar_pacotes.R).
# =============================================================================

.cache_imagens <- new.env()
.cache_reduzidas <- new.env()     # versões reduzidas (média de blocos) para o tamanho em que a figura aparece
.cache_ordem <- character(0)      # ordem de leitura (a cache guarda no máximo 3 figuras: a mais antiga sai)
.IMAGEM_MAX_PX <- 3200            # lado maior guardado; figuras maiores são reduzidas (só para desenhar)

# Reduz um nativeRaster à metade fazendo a MÉDIA de cada bloco 2x2 (ponderada pela transparência). Pular pixels ou reduzir de uma vez só
# gera listras e serrilhado (aliasing) em figuras com detalhes finos; a média de blocos não. Processa em faixas de colunas (memória baixa).
.reduzir_metade <- function(nat) {
  d <- dim(nat); if (d[1] %/% 2L < 1L || d[2] %/% 2L < 1L) return(nat)
  # o nativeRaster guarda os pixels LINHA por linha (apesar de dim = altura x largura): para o R ver uma matriz na ordem certa, troca-se H e W
  H <- d[2]; W <- d[1]; h2 <- H %/% 2L; w2 <- W %/% 2L
  b <- writeBin(as.integer(unclass(nat)), raw())                 # R, G, B, A de cada pixel, na ordem de armazenamento
  saida <- matrix(0L, h2, w2); faixa <- 512L; i1 <- seq(1L, 2L * h2, by = 2L)
  for (c0 in seq(1L, w2, by = faixa)) {
    c1 <- min(c0 + faixa - 1L, w2); nc <- 2L * (c1 - c0 + 1L); j0 <- 2L * (c0 - 1L) + 1L
    v <- as.integer(b[((j0 - 1L) * H * 4L + 1L):((j0 + nc - 1L) * H * 4L)])
    canal <- function(k) matrix(v[seq(k, length(v), by = 4L)], H, nc)
    A <- canal(4L); j1 <- seq(1L, nc, by = 2L)
    soma <- function(M) M[i1, j1, drop = FALSE] + M[i1 + 1L, j1, drop = FALSE] + M[i1, j1 + 1L, drop = FALSE] + M[i1 + 1L, j1 + 1L, drop = FALSE]
    sa <- soma(A); sa1 <- pmax(sa, 1L)
    pond <- function(k) { s <- soma(canal(k) * A) / sa1; s[sa == 0L] <- 0; as.integer(round(s)) }   # cor média, com mais peso onde há opacidade
    ob <- raw(4L * length(sa))
    ob[seq(1L, length(ob), by = 4L)] <- as.raw(pond(1L)); ob[seq(2L, length(ob), by = 4L)] <- as.raw(pond(2L))
    ob[seq(3L, length(ob), by = 4L)] <- as.raw(pond(3L)); ob[seq(4L, length(ob), by = 4L)] <- as.raw(as.integer(round(sa / 4)))
    saida[, c0:c1] <- readBin(ob, "integer", n = length(sa))
  }
  dim(saida) <- c(d[1] %/% 2L, d[2] %/% 2L)                        # volta a altura x largura (os dados já estão na ordem de linhas)
  structure(saida, class = "nativeRaster", channels = 4L)
}
# dpi do dispositivo que está desenhando (ragg: o real; PDF, SVG e EMF são vetoriais: 300 dpi para a figura não perder detalhe)
.dpi_dispositivo <- function() {
  nome <- names(grDevices::dev.cur())
  if (length(nome) && grepl("^agg", nome[1])) {
    d <- tryCatch(grDevices::dev.size("px")[1] / grDevices::dev.size("in")[1], error = function(e) NA_real_)
    if (is.finite(d) && d > 0) return(d)
  }
  300
}
# Raster para desenhar com `w_in` polegadas de largura: usa a versão reduzida (média de blocos) mais próxima de ~1,25 a 2,5 vezes os pixels
# necessários, e então o desenho interpola o resto. Figuras pequenas na tela não ficam listradas e o arquivo final mantém os detalhes.
.raster_para_largura <- function(im, opacidade, w_in) {
  alvo <- max(w_in * .dpi_dispositivo(), 16); larg <- im$larg; nivel <- 0L
  while (larg %/% 2L >= alvo * 1.25 && larg >= 8L) { nivel <- nivel + 1L; larg <- larg %/% 2L }
  nat <- im$nat
  if (nivel > 0L) {
    chave <- paste(im$chave, nivel); r <- .cache_reduzidas[[chave]]
    if (is.null(r)) {
      if (length(ls(.cache_reduzidas)) >= 8) rm(list = ls(.cache_reduzidas), envir = .cache_reduzidas)
      r <- nat; for (k in seq_len(nivel)) r <- .reduzir_metade(r); .cache_reduzidas[[chave]] <- r
    }
    nat <- r
  }
  .raster_imagem(list(nat = nat), opacidade)
}

# Lê a figura como "nativeRaster" (4 bytes por pixel: uma figura de 4 megapixels fica com ~17 MB; antes ficava com 138 MB em quatro matrizes de
# números, que nunca saíam da memória, e a conversão para desenhar levava 4 s a CADA atualização do gráfico).
# Sai: list(nat, alt, larg).
.ler_imagem <- function(arq) {
  if (is.null(arq) || !is.character(arq) || length(arq) != 1 || !nzchar(arq)) .erro("cfg$imagens: cada figura precisa de 'arquivo' (caminho de um PNG ou JPEG).")
  if (!file.exists(arq)) .erro("cfg$imagens: não achei a figura '", arq, "'.")
  chave <- paste(normalizePath(arq, winslash = "/"), file.mtime(arq), file.size(arq))
  if (!is.null(.cache_imagens[[chave]])) return(.cache_imagens[[chave]])
  ext <- tolower(tools::file_ext(arq))
  if (!ext %in% c("png", "jpg", "jpeg")) .erro("cfg$imagens: formato '.", ext, "' não é aceito; use PNG ou JPEG.")
  pk <- if (ext == "png") "png" else "jpeg"
  if (!.tem(pk)) .erro("Para usar figuras é preciso o pacote ", pk, ": rode install.packages(\"", pk, "\") (ou 00_instalar_pacotes.R).")
  nat <- tryCatch(if (ext == "png") png::readPNG(arq, native = TRUE) else jpeg::readJPEG(arq, native = TRUE),
                  error = function(e) .erro("cfg$imagens: não consegui ler '", arq, "' (arquivo corrompido?)."))
  while (max(dim(nat)[1:2]) > .IMAGEM_MAX_PX) nat <- .reduzir_metade(nat)       # figuras gigantes: média de blocos (sem listras), uma vez só
  out <- list(nat = nat, alt = nrow(nat), larg = ncol(nat), chave = chave)
  .cache_imagens[[chave]] <- out
  ordem <- c(setdiff(.cache_ordem, chave), chave)
  if (length(ordem) > 3) { rm(list = ordem[1], envir = .cache_imagens); ordem <- ordem[-1] }
  .cache_ordem <<- ordem
  out
}

# Raster pronto para desenhar, com a opacidade pedida (só o byte de transparência é mexido; opacidade 1 devolve a própria figura).
.raster_imagem <- function(im, opacidade = 1) {
  if (!is.finite(opacidade) || opacidade >= 1) return(im$nat)
  x <- unclass(im$nat); dd <- dim(x)
  b <- writeBin(as.integer(x), raw()); k <- seq(4L, length(b), by = 4L)
  b[k] <- as.raw(pmin(pmax(round(as.integer(b[k]) * max(opacidade, 0)), 0), 255))
  y <- readBin(b, "integer", n = length(x)); dim(y) <- dd
  structure(y, class = "nativeRaster", channels = 4L)
}

# Grob que mantém a proporção da figura: a largura vem do painel (npc) e a altura é calculada na hora de desenhar.
.grob_imagem_prop <- function(im, opac, prop, largura, x, y, just, angulo, gp_borda) {
  gTree(im = im, opac = opac, prop = prop, largura = largura, x = x, y = y, just = just, angulo = angulo, gp_borda = gp_borda, cl = "imagem_prop")
}
makeContent.imagem_prop <- function(x) {
  w <- grid::convertWidth(x$largura, "in", valueOnly = TRUE); h <- w * x$prop
  vp <- viewport(x = x$x, y = x$y, width = unit(w, "in"), height = unit(h, "in"), just = x$just, angle = x$angulo)
  f <- list(rasterGrob(.raster_para_largura(x$im, x$opac, w), width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE),
            if (!is.null(x$gp_borda)) rectGrob(gp = x$gp_borda))
  grid::setChildren(x, do.call(gList, list(gTree(children = do.call(gList, Filter(Negate(is.null), f)), vp = vp))))
}
# Figura com tamanho próprio (largura e altura dadas, ou em unidades dos dados): o viewport do gTree já é o retângulo da figura.
.grob_imagem_fixa <- function(im, opac, gp_borda, vp) gTree(im = im, opac = opac, gp_borda = gp_borda, vp = vp, cl = "imagem_fixa")
makeContent.imagem_fixa <- function(x) {
  w <- grid::convertWidth(unit(1, "npc"), "in", valueOnly = TRUE)
  f <- list(rasterGrob(.raster_para_largura(x$im, x$opac, w), width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE),
            if (!is.null(x$gp_borda)) rectGrob(gp = x$gp_borda))
  grid::setChildren(x, do.call(gList, Filter(Negate(is.null), f)))
}
if (requireNamespace("grid", quietly = TRUE)) {
  registerS3method("makeContent", "imagem_prop", makeContent.imagem_prop, envir = asNamespace("grid"))
  registerS3method("makeContent", "imagem_fixa", makeContent.imagem_fixa, envir = asNamespace("grid"))
}

# Uma figura: devolve list(grob, xmin, xmax, ymin, ymax) para annotation_custom() (mesmo formato de .grob_forma).
.grob_imagem <- function(it, cfg) {
  it <- .ex(it)
  un <- it$unidade %||% "fracao"
  if (!un %in% c("fracao", "dados")) .erro("cfg$imagens: unidade deve ser \"fracao\" ou \"dados\".")
  a <- .ANCORAS[[it$ancora %||% "centro"]]
  if (is.null(a)) .erro("cfg$imagens: ancora '", it$ancora, "' não é válida.\n  OPÇÕES: ", paste0('"', names(.ANCORAS), '"', collapse = " | "))
  im <- .ler_imagem(it$arquivo); opac <- it$opacidade %||% 1       # o raster é escolhido na hora de desenhar (depende do tamanho real)
  prop <- im$alt / im$larg
  gp_b <- if (!is.null(it$borda_cor) || !is.null(it$borda_pt) || !is.null(it$borda_tipo))
    gpar(col = .cor(it$borda_cor %||% "black"), fill = NA, lwd = .lw(it$borda_pt %||% 0.75) * ggplot2::.pt, lty = it$borda_tipo %||% "solid") else NULL
  cx <- it$x %||% 0.5; cy <- it$y %||% 0.5; ang <- it$angulo %||% 0
  if (un == "dados") {
    if (is.null(it$largura) || is.null(it$altura)) .erro("cfg$imagens: em unidades dos dados, informe largura e altura (ou use unidade = \"fracao\").")
    g <- gTree(children = gList(.grob_imagem_fixa(im, opac, gp_b, viewport(angle = ang))))
    return(list(grob = g, xmin = cx - it$largura / 2, xmax = cx + it$largura / 2, ymin = cy - it$altura / 2, ymax = cy + it$altura / 2, caixa = list(W = unit(1, "npc"), H = unit(1, "npc"), prop = prop, cx = 0.5, cy = 0.5, jx = 0.5, jy = 0.5, fracao = FALSE, dados = TRUE,
                 lim = c(cx - it$largura / 2, cx + it$largura / 2, cy - it$altura / 2, cy + it$altura / 2), tipo = "figura", forma = "figura", auto = FALSE)))
  }
  larg <- it$largura %||% 0.2
  if (!is.null(it$altura)) {                     # largura e altura dadas: preenche o retângulo (pode deformar)
    vp <- viewport(x = unit(cx, "npc"), y = unit(cy, "npc"), width = unit(larg, "npc"), height = unit(it$altura, "npc"), just = a, angle = ang)
    g <- gTree(children = gList(.grob_imagem_fixa(im, opac, gp_b, vp)))
  } else g <- gTree(children = gList(.grob_imagem_prop(im, opac, prop, unit(larg, "npc"), unit(cx, "npc"), unit(cy, "npc"), a, ang, gp_b)))
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
