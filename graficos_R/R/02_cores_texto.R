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

# Paletas prontas. Cada uma tem um nome curto (o que se escreve em cfg$cores$paleta) e um rótulo para a tela.
# "Estilo Origin": a sequência de cores básicas do Origin e conjuntos parecidos; as demais são paletas conhecidas
# de publicações científicas e de visualização (ColorBrewer, Paul Tol, ggsci, Tableau, D3).
.PALETAS <- list(
  # ---- estilo Origin
  classico  = c("#000000", "#D62728", "#1F4E9E", "#2CA02C", "#8E44AD", "#FF7F0E",
                "#17BECF", "#8C564B", "#E377C2", "#7F7F7F"),
  origin_basico = c("#000000", "#FF0000", "#0000FF", "#008000", "#FF00FF", "#008080", "#000080", "#800000",
                    "#800080", "#808000", "#FF8000", "#0080FF", "#8000FF", "#FF0080"),
  origin_vivo   = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFD700", "#A65628", "#F781BF", "#999999"),
  origin_escuro = c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666"),
  origin_pastel = c("#FBB4AE", "#B3CDE3", "#CCEBC5", "#DECBE4", "#FED9A6", "#FFFFCC", "#E5D8BD", "#FDDAEC", "#CCCCCC"),
  origin_suave  = c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854", "#FFD92F", "#E5C494", "#B3B3B3"),
  origin_pares  = c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", "#E31A1C", "#FDBF6F", "#FF7F00",
                    "#CAB2D6", "#6A3D9A", "#FFFF99", "#B15928"),
  origin_doce   = c("#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462", "#B3DE69", "#FCCDE5",
                    "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F"),
  # ---- marca
  marca     = c("#1B3A8C", "#0E9F4B", "#0B6E78", "#8CC63F", "#0F4C81", "#2FB5A0", "#5B7DB1", "#6BBF59"),
  # ---- acessíveis (daltonismo)
  okabe_ito = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9",
                "#000000", "#F0E442"),
  tol_brilhante = c("#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377", "#BBBBBB"),
  tol_vibrante  = c("#EE7733", "#0077BB", "#33BBEE", "#EE3377", "#CC3311", "#009988", "#BBBBBB"),
  tol_suave     = c("#CC6677", "#332288", "#DDCC77", "#117733", "#88CCEE", "#882255", "#44AA99", "#999933", "#AA4499"),
  tol_contraste = c("#004488", "#DDAA33", "#BB5566", "#000000"),
  # ---- publicações e software
  tableau   = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F", "#EDC948",
                "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC"),
  d3        = c("#1F77B4", "#FF7F0E", "#2CA02C", "#D62728", "#9467BD", "#8C564B", "#E377C2", "#7F7F7F", "#BCBD22", "#17BECF"),
  npg       = c("#E64B35", "#4DBBD5", "#00A087", "#3C5488", "#F39B7F", "#8491B4", "#91D1C2", "#DC0000", "#7E6148", "#B09C85"),
  lancet    = c("#00468B", "#ED0000", "#42B540", "#0099B4", "#925E9F", "#FDAF91", "#AD002A", "#ADB6B6", "#1B1919"),
  jco       = c("#0073C2", "#EFC000", "#868686", "#CD534C", "#7AA6DC", "#003C67", "#8F7700", "#3B3B3B", "#A73030", "#4A6990"),
  nejm      = c("#BC3C29", "#0072B5", "#E18727", "#20854E", "#7876B1", "#6F99AD", "#FFDC91", "#EE4C97"),
  # ---- degradês de uma cor (sequenciais): as séries percorrem do claro ao escuro
  seq_azul     = c("#C6DBEF", "#6BAED6", "#2171B5", "#08306B"),
  seq_verde    = c("#C7E9C0", "#74C476", "#238B45", "#00441B"),
  seq_laranja  = c("#FDD0A2", "#FD8D3C", "#D94801", "#7F2704"),
  seq_vermelho = c("#FCBBA1", "#FB6A4A", "#CB181D", "#67000D"),
  seq_roxo     = c("#DADAEB", "#9E9AC8", "#6A51A3", "#3F007D"),
  seq_azul_verde = c("#FFFFCC", "#A1DAB4", "#41B6C4", "#2C7FB8", "#253494"),
  seq_calor    = c("#FFFFB2", "#FECC5C", "#FD8D3C", "#F03B20", "#BD0026"),
  seq_frio     = c("#E0F7FA", "#80DEEA", "#26C6DA", "#00838F", "#004D40"),
  # ---- divergentes e arco-íris
  div_vermelho_azul = c("#B2182B", "#EF8A62", "#F7F7F7", "#67A9CF", "#2166AC"),
  div_espectro      = c("#D7191C", "#FDAE61", "#FFFFBF", "#ABDDA4", "#2B83BA"),
  div_marrom_verde  = c("#8C510A", "#D8B365", "#F5F5F5", "#5AB4AC", "#01665E"),
  arco_iris         = c("#9400D3", "#4B0082", "#0000FF", "#00AA00", "#FFD700", "#FF7F00", "#FF0000")
)
# As que percorrem um degradê (a n-ésima cor é interpolada ao longo da paleta inteira, não a n-ésima da lista).
.PALETAS_RAMPA <- c("seq_azul", "seq_verde", "seq_laranja", "seq_vermelho", "seq_roxo", "seq_azul_verde", "seq_calor",
                    "seq_frio", "div_vermelho_azul", "div_espectro", "div_marrom_verde", "arco_iris")

# Para a tela e para mostrar_paletas(): grupo -> c(nome = "rótulo").
.PALETAS_GRUPOS <- list(
  "Estilo Origin" = c("Clássica (preto, vermelho, azul...)" = "classico", "Origin: cores básicas" = "origin_basico",
                      "Origin: vivas" = "origin_vivo", "Origin: escuras" = "origin_escuro", "Origin: pastel" = "origin_pastel",
                      "Origin: suaves" = "origin_suave", "Origin: em pares" = "origin_pares", "Origin: doces" = "origin_doce"),
  "Marca" = c("Marca (azul e verde)" = "marca"),
  "Acessíveis (daltonismo)" = c("Okabe-Ito" = "okabe_ito", "Paul Tol: brilhante" = "tol_brilhante", "Paul Tol: vibrante" = "tol_vibrante",
                                "Paul Tol: suave" = "tol_suave", "Paul Tol: alto contraste" = "tol_contraste"),
  "Revistas e programas" = c("Tableau" = "tableau", "D3 (Category10)" = "d3", "Nature (NPG)" = "npg", "The Lancet" = "lancet",
                             "J. Clinical Oncology (JCO)" = "jco", "NEJM" = "nejm"),
  "Degradês de uma cor" = c("Azul" = "seq_azul", "Verde" = "seq_verde", "Laranja" = "seq_laranja", "Vermelho" = "seq_vermelho",
                            "Roxo" = "seq_roxo", "Amarelo → azul" = "seq_azul_verde", "Calor" = "seq_calor", "Frio" = "seq_frio"),
  "Divergentes e arco-íris" = c("Vermelho ↔ azul" = "div_vermelho_azul", "Espectro" = "div_espectro",
                                "Marrom ↔ verde" = "div_marrom_verde", "Arco-íris" = "arco_iris"),
  "Contínuas (viridis)" = c("Viridis" = "viridis", "Magma" = "magma", "Plasma" = "plasma", "Cividis" = "cividis",
                            "Inferno" = "inferno", "Turbo" = "turbo"),
  "Cinza" = c("Tons de cinza" = "cinza")
)

# Entra: nome da paleta e n. Sai: vetor com n cores (interpola se a paleta for menor que n).
.paleta <- function(nome, n, cfg_cores = NULL) {
  n <- max(n, 1)
  base <- if (nome %in% names(.PALETAS)) {
    b <- .PALETAS[[nome]]
    if (nome %in% .PALETAS_RAMPA) return(if (n == 1) b[length(b) - 1] else grDevices::colorRampPalette(b)(n))
    b
  } else if (nome %in% c("viridis", "magma", "plasma", "cividis", "inferno", "turbo")) {
    if (!.tem("viridisLite")) .erro("Paleta '", nome, "' precisa do pacote viridisLite.")
    fun <- getExportedValue("viridisLite", nome)
    return(fun(n, end = if (nome %in% c("viridis", "cividis")) 0.92 else 0.88))
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
    .erro("Paleta '", nome, "' desconhecida. Opções: ", paste(c(names(.PALETAS), "viridis", "magma", "plasma", "cividis", "inferno", "turbo", "cinza"), collapse = ", "),
          ", brewer_<nome>, personalizada. Veja mostrar_paletas().")
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
# negrito = TRUE: o plotmath ignora a face "bold" do tema, então a expressão é envolvida em bold().
.texto <- function(s, negrito = FALSE) {
  if (is.null(s)) return(NULL)
  if (!.tem_formatacao(s)) return(s)
  expr <- parse(text = .plotmath(s))[[1]]
  if (isTRUE(negrito)) call("bold", expr) else expr
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
