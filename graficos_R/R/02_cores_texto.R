# =============================================================================
#  R/02_cores_texto.R — cores, paletas, gradientes, sobrescrito/subscrito, mescla de listas
# =============================================================================

# ---- Cores ------------------------------------------------------------------
# Valida e normaliza uma cor (nome, #RRGGBB, c(R,G,B) ou "transparente"). Erro em português se inválida.
.cor <- function(x, onde = "cor") {
  if (is.null(x)) return(NULL)
  if (length(x) == 3 && is.numeric(x)) return(grDevices::rgb(x[1], x[2], x[3], maxColorValue = 255))
  if (length(x) == 1 && is.na(x)) return(NA_character_)
  if (identical(x, "transparente")) return("transparent")
  ok <- tryCatch({ grDevices::col2rgb(x); TRUE }, error = function(e) FALSE)
  if (!ok) .erro("Cor inválida em ", onde, ": '", x, "'. Use nome (\"red\"), \"#RRGGBB\" ou c(R,G,B).")
  x
}
# Aplica opacidade a uma cor (a = 1 não altera; NA e NULL passam direto).
.alfa <- function(cor, a) {
  if (is.null(cor) || (length(cor) == 1 && is.na(cor))) return(cor)
  if (is.null(a) || a >= 1) return(cor)
  scales::alpha(cor, a)
}
# Cor intermediária entre c1 e c2.
.cor_media <- function(c1, c2) grDevices::colorRampPalette(c(c1, c2))(3)[2]
# Brilho percebido (0 a 1) de uma cor; decide texto branco ou preto sobre ela.
.luminancia <- function(cor) {
  v <- grDevices::col2rgb(cor) / 255
  sum(c(0.299, 0.587, 0.114) * v)
}

.PALETAS <- list(
  classico  = c("#000000", "#D62728", "#1F4E9E", "#2CA02C", "#8E44AD", "#FF7F0E",
                "#17BECF", "#8C564B", "#E377C2", "#7F7F7F"),
  okabe_ito = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9",
                "#000000", "#F0E442"),
  tableau   = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F", "#EDC948",
                "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC")
)

# Entra: nome da paleta e n. Sai: vetor com n cores (interpola se a paleta for menor que n).
.paleta <- function(nome, n, cfg_cores = NULL) {
  n <- max(n, 1)
  base <- if (nome %in% names(.PALETAS)) {
    .PALETAS[[nome]]
  } else if (nome %in% c("viridis", "magma", "plasma", "cividis", "inferno")) {
    if (!.tem("viridisLite")) .erro("Paleta '", nome, "' precisa do pacote viridisLite.")
    fun <- getExportedValue("viridisLite", nome)
    return(fun(n, end = if (nome == "viridis" || nome == "cividis") 0.92 else 0.88))
  } else if (nome == "cinza") {
    return(grDevices::grey.colors(n, start = 0, end = 0.75))
  } else if (startsWith(nome, "brewer_")) {
    if (!.tem("RColorBrewer")) .erro("Paletas brewer_ precisam do pacote RColorBrewer.")
    pal <- sub("^brewer_", "", nome)
    info <- RColorBrewer::brewer.pal.info
    if (!pal %in% rownames(info))
      .erro("Paleta ColorBrewer '", pal, "' não existe. Opções: ",
            paste(rownames(info), collapse = ", "))
    RColorBrewer::brewer.pal(info[pal, "maxcolors"], pal)
  } else if (nome == "personalizada") {
    vapply(cfg_cores$personalizada, .cor, character(1), onde = "cores$personalizada")
  } else {
    .erro("Paleta '", nome, "' desconhecida. Opções: classico, okabe_ito, tableau, viridis, ",
          "magma, plasma, cividis, cinza, brewer_<nome>, personalizada. Veja mostrar_paletas().")
  }
  if (n <= length(base)) base[seq_len(n)] else grDevices::colorRampPalette(base)(n)
}

# Gradiente de 2 cores (padrão grid). grupo = TRUE: relativo ao conjunto inteiro.
.gradiente <- function(c1, c2, direcao, grupo = FALSE) {
  cores <- c(c1, c2)
  if (grepl("invertido", direcao)) cores <- rev(cores)
  dir <- sub("_invertido", "", direcao)
  args <- list(colours = cores)
  if (.R42) args$group <- grupo
  if (dir == "radial") {
    args$colours <- rev(args$colours)   # centro = cor2 (clara), borda = cor da série
    args <- c(args, list(cx1 = 0.5, cy1 = 0.5, r1 = 0, cx2 = 0.5, cy2 = 0.5, r2 = 0.5))
    return(do.call(grid::radialGradient, args))
  }
  xy <- switch(dir,
               vertical   = c(0.5, 0, 0.5, 1),
               horizontal = c(0, 0.5, 1, 0.5),
               diagonal   = c(0, 0, 1, 1),
               .erro("gradiente_direcao '", direcao, "' inválida."))
  args <- c(args, list(x1 = xy[1], y1 = xy[2], x2 = xy[3], y2 = xy[4]))
  do.call(grid::linearGradient, args)
}

# ---- Texto com sobrescrito ^{ } e subscrito _{ } -----------------------------
# TRUE se o texto tem sobrescrito ^{ } ou subscrito _{ }.
.tem_formatacao <- function(s) is.character(s) && length(s) == 1 && grepl("[\\^_]\\{", s)

# Converte "Área (m^{2})" em string plotmath: "Área (m"*""^"2"*")"
.plotmath <- function(s) {
  if (!.tem_formatacao(s)) return(deparse(s))
  partes <- character(0)
  resto <- s
  while (nchar(resto) > 0) {
    m <- regexpr("[\\^_]\\{[^}]*\\}", resto)
    if (m == -1) { partes <- c(partes, deparse(resto)); break }
    if (m > 1) partes <- c(partes, deparse(substr(resto, 1, m - 1)))
    tok <- regmatches(resto, m)
    conteudo <- substr(tok, 3, nchar(tok) - 1)
    partes <- c(partes, if (substr(tok, 1, 1) == "^")
      paste0('""^', deparse(conteudo)) else paste0('""[', deparse(conteudo), "]"))
    resto <- substr(resto, m + attr(m, "match.length"), nchar(resto))
  }
  paste(partes, collapse = "*")
}
# Texto simples ou expressão plotmath (se tiver ^{ } ou _{ }), pronto para títulos e rótulos.
.texto <- function(s) {
  if (is.null(s)) return(NULL)
  if (.tem_formatacao(s)) parse(text = .plotmath(s))[[1]] else s
}
# Rótulos de legenda: vetor de textos ou expressões, conforme tenham ^{ } / _{ }.
.rotulos_legenda <- function(x) {
  if (any(vapply(x, .tem_formatacao, logical(1))))
    parse(text = vapply(x, .plotmath, character(1)))
  else x
}

# ---- Mescla de listas (para painéis e estilos) -------------------------------
# Entra: lista base e lista novo. Sai: base com os valores de novo por cima (recursivo; séries por nome).
.mesclar <- function(base, novo) {
  if (!is.list(novo) || is.null(names(novo))) return(novo)
  for (nm in names(novo)) {
    if (is.list(base[[nm]]) && !is.null(names(base[[nm]])) && is.list(novo[[nm]]) &&
        !is.null(names(novo[[nm]])) && !nm %in% c("series")) {
      base[[nm]] <- .mesclar(base[[nm]], novo[[nm]])
    } else if (nm == "series" && is.list(novo[[nm]])) {
      for (s in names(novo[[nm]]))
        base$series[[s]] <- utils::modifyList(base$series[[s]] %||% list(), novo[[nm]][[s]])
    } else {
      base[nm] <- list(novo[[nm]])
    }
  }
  base
}
