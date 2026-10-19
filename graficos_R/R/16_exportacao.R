# =============================================================================
#  R/16_exportacao.R — exportação (salvar), prévia (visualizar) e lote
# =============================================================================

# =============================================================================
#  EXPORTAÇÃO E PRÉVIA
# =============================================================================
# TRUE se o cfg (ou algum painel) usa preenchimento em gradiente.
.usa_gradiente <- function(cfg) {
  identical(cfg$cores$preenchimento, "gradiente") ||
    (isTRUE(cfg$paineis$ativo) && any(vapply(cfg$paineis$lista,
                                             function(p) identical(p$cores$preenchimento, "gradiente"), TRUE)))
}

# TRUE se o ragg pode ser usado (e, se o gradiente é radial, se a versão corrige o bug do ragg < 1.5).
.ragg_ok <- function(cfg = NULL) {
  if (!.tem("ragg")) return(FALSE)
  # ragg < 1.5 desenha errado gradiente radial (claro -> escuro): usa Cairo nesse caso
  if (!is.null(cfg) && identical(cfg$cores$preenchimento, "gradiente") &&
      grepl("radial", cfg$cores$gradiente_direcao) && utils::packageVersion("ragg") < "1.5.0") return(FALSE)
  TRUE
}

# Abre o dispositivo gráfico do formato pedido (png, tiff, jpeg, pdf, svg, emf), com os fallbacks do R base.
.abrir_dispositivo <- function(formato, arq, larg_in, alt_in, dpi, fundo, usar_ragg = .tem("ragg")) {
  fundo_jpeg <- if (identical(fundo, "transparent")) "white" else fundo   # JPEG não tem transparência
  switch(formato,
    png = if (usar_ragg) ragg::agg_png(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                       background = fundo)
          else grDevices::png(arq, width = larg_in, height = alt_in, units = "in", res = dpi, bg = fundo,
                              type = if (capabilities("cairo")) "cairo" else "windows"),
    tiff = if (usar_ragg) ragg::agg_tiff(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                            background = fundo, compression = "lzw")
           else grDevices::tiff(arq, width = larg_in, height = alt_in, units = "in", res = dpi, bg = fundo,
                                compression = "lzw", type = if (capabilities("cairo")) "cairo" else "windows"),
    jpeg = if (usar_ragg) ragg::agg_jpeg(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                         background = fundo_jpeg, quality = 95)
           else grDevices::jpeg(arq, width = larg_in, height = alt_in, units = "in", res = dpi, quality = 95,
                                bg = fundo_jpeg),
    pdf = if (capabilities("cairo")) grDevices::cairo_pdf(arq, width = larg_in, height = alt_in, bg = fundo)
          else grDevices::pdf(arq, width = larg_in, height = alt_in, bg = fundo, useDingbats = FALSE),
    svg = if (.tem("svglite")) svglite::svglite(arq, width = larg_in, height = alt_in, bg = fundo)
          else grDevices::svg(arq, width = larg_in, height = alt_in, bg = fundo),
    emf = if (.tem("devEMF")) devEMF::emf(arq, width = larg_in, height = alt_in, bg = fundo, emfPlus = TRUE)
          else .erro("Formato emf precisa do pacote devEMF (rode 00_instalar_pacotes.R)."),
    .erro("Formato '", formato, "' desconhecido. OPÇÕES: png, tiff, jpeg, pdf, svg, emf"))
}

# Cópia do cfg com todos os preenchimentos em cor sólida (formatos sem gradiente).
.sem_gradiente <- function(cfg) {
  cfg$cores$preenchimento <- "solido"
  if (isTRUE(cfg$paineis$ativo))
    cfg$paineis$lista <- lapply(cfg$paineis$lista, function(p) {
      if (!is.null(p$cores)) p$cores$preenchimento <- "solido"
      p
    })
  cfg
}

#' Exporta o gráfico nos formatos de cfg$exportacao
# Deixa transparentes o fundo da página e o do painel SEM refazer o gráfico, para não perder o que
# o usuário somou ao objeto (+ theme(), + labs(), + camadas). Serve para ggplot e para patchwork.
.fundo_transparente <- function(g) {
  t <- theme(plot.background = element_rect(fill = NA, colour = NA),
             panel.background = element_rect(fill = NA, colour = NA))
  if (inherits(g, "patchwork")) g & t else g + t
}

# Exporta o gráfico nos formatos de cfg$exportacao. Entra: g (de plotar), cfg e nome opcional. Sai: caminhos gravados.
salvar <- function(g, cfg = attr(g, "cfg") %||% get("cfg", envir = globalenv()), nome = NULL) {
  cfg <- .completar_cfg(cfg)
  ex <- cfg$exportacao
  fator <- switch(ex$unidade, cm = 1 / 2.54, mm = 1 / 25.4, `in` = 1)
  larg <- ex$largura * fator; alt <- ex$altura * fator
  ex$pasta <- .pasta_proj(ex$pasta)
  if (!dir.exists(ex$pasta)) dir.create(ex$pasta, recursive = TRUE)
  dados <- attr(g, "dados")
  base <- nome %||% ex$nome_arquivo %||% paste0(
    if (!is.null(attr(dados, "arquivo"))) tools::file_path_sans_ext(basename(attr(dados, "arquivo"))) else "grafico",
    "_", cfg$grafico$tipo)
  if (isTRUE(ex$carimbo_data)) base <- paste0(base, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  fundo <- if (isTRUE(ex$fundo_transparente)) "transparent" else "white"
  transparente <- isTRUE(ex$fundo_transparente)
  if (transparente) {
    # quebra contínua: as partes têm fundo próprio e só nascem transparentes ao montar o gráfico
    if (isTRUE(attr(g, "quebra_continua")) && !is.null(dados)) g <- plotar(dados, cfg)
    g <- .fundo_transparente(g)
  }
  saidas <- character(0)
  for (f in tolower(ex$formatos)) {
    ext <- switch(f, jpeg = "jpg", f)
    arq <- file.path(ex$pasta, paste0(base, ".", ext))
    if (!isTRUE(ex$sobrescrever)) {
      k <- 2
      while (file.exists(arq)) {
        arq <- file.path(ex$pasta, paste0(base, "_", k, ".", ext))
        k <- k + 1
      }
    }
    .abrir_dispositivo(f, arq, larg, alt, ex$dpi, fundo, usar_ragg = .ragg_ok(cfg))
    disp <- grDevices::dev.cur()
    tryCatch({
      gg <- g
      if (.usa_gradiente(cfg)) {
        cap <- tryCatch(unlist(grDevices::dev.capabilities()$patterns), error = function(e) character(0))
        if (!"LinearGradient" %in% cap) {
          .aviso("O formato '", f, "' não suporta gradiente; usando cor sólida neste arquivo ",
                 "(o gráfico é refeito a partir do cfg: ajustes feitos depois com + theme() ou ",
                 "+ camadas não entram nele).")
          if (!is.null(dados)) {
            gg <- plotar(dados, .sem_gradiente(cfg))
            if (transparente) gg <- .fundo_transparente(gg)
          }
        }
      }
      print(gg)
    }, finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
    saidas <- c(saidas, arq)
  }
  message("Salvo: ", paste(normalizePath(saidas, winslash = "/", mustWork = FALSE), collapse = "\n       "))
  invisible(saidas)
}

#' Prévia fiel (mesmo tamanho e fontes do arquivo final) no Viewer do RStudio
visualizar <- function(g, cfg = attr(g, "cfg") %||% get("cfg", envir = globalenv()), dpi = 150) {
  cfg <- .completar_cfg(cfg)
  ex <- cfg$exportacao
  fator <- switch(ex$unidade, cm = 1 / 2.54, mm = 1 / 25.4, `in` = 1)
  arq <- tempfile("previa_", fileext = ".png")
  .abrir_dispositivo("png", arq, ex$largura * fator, ex$altura * fator, dpi, "white", usar_ragg = .ragg_ok(cfg))
  disp <- grDevices::dev.cur()
  tryCatch(print(g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    html <- tempfile("previa_", fileext = ".html")
    writeLines(sprintf(paste0(
      '<html><body style="margin:0;background:#e5e5e5;display:flex;justify-content:center;',
      'align-items:flex-start;padding:12px"><img src="%s" style="max-width:100%%;',
      'box-shadow:0 1px 6px #888"></body></html>'), basename(arq)), html)
    file.copy(arq, file.path(dirname(html), basename(arq)), overwrite = TRUE)
    viewer(html)
  } else {
    print(g)
  }
  invisible(arq)
}

#' Aplica o mesmo cfg a todos os CSVs de uma pasta
exportar_lote <- function(pasta = "dados", cfg = get("cfg", envir = globalenv()), padrao = "\\.csv$") {
  pasta <- .pasta_proj(pasta)
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE, ignore.case = TRUE)
  if (!length(arqs)) .erro("Nenhum CSV em '", pasta, "'.")
  res <- list()
  for (a in arqs) {
    message("\n>> ", basename(a))
    r <- tryCatch({
      d <- ler_csv(a, cfg$dados); g <- plotar(d, cfg)
      c2 <- cfg; c2$exportacao$nome_arquivo <- NULL
      salvar(g, c2)
    }, error = function(e) { message("   ERRO: ", conditionMessage(e)); NULL })
    res[[basename(a)]] <- r
  }
  invisible(res)
}
