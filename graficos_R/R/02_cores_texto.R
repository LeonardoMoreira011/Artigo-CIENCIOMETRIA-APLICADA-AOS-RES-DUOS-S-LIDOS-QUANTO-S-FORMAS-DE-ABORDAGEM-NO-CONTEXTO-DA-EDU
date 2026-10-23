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
# A do Cinabro (cinabro) é original; as demais vêm de trabalhos com licença livre (cores em R/02_paletas_dados.R, avisos em NOTICE.md).
.PALETAS_PROPRIAS <- list(
  # a paleta padrão do Cinabro: as cores da identidade (vermelho-cinábrio, azul-petróleo, tinta e terracota) e variações delas
  # (petróleo claro, ardósia, coral, petróleo profundo, areia, petróleo médio). As 4 primeiras são as da marca e as mais distintas
  # entre si; da 5ª em diante as cores se parecem mais, então o app já varia também a forma dos pontos de cada série.
  cinabro   = c("#B3262E", "#2F6670", "#20242B", "#C96A4A", "#93C9D4", "#797D85", "#E8908A", "#00454F", "#E3B08F", "#679DA7")
)
.PALETAS <- c(.PALETAS_PROPRIAS, .PALETAS_DADOS)
# As que percorrem um degradê (a n-ésima cor é interpolada ao longo da paleta inteira, não a n-ésima da lista).
.PALETAS_RAMPA <- c(grep("^brewer_", names(.PALETAS), value = TRUE), grep("^(cmo|crameri)_", names(.PALETAS), value = TRUE))
.PALETAS_VIRIDIS <- c("magma", "inferno", "turbo")   # do pacote viridisLite

# Para a tela e para mostrar_paletas(): grupo -> c(rótulo = nome).
.PALETAS_GRUPOS <- list(
  "Do Cinabro" = c("Cinabro (padrão: cores da marca e variações)" = "cinabro"),
  "Degradês" = c("Vermelhos" = "brewer_Reds", "Roxos" = "brewer_Purples", "Amarelo → azul" = "brewer_YlGnBu",
                 "Amarelo → vermelho" = "brewer_YlOrRd", "Algas" = "cmo_algae", "Oslo" = "crameri_oslo"),
  "Divergentes" = c("Vermelho-escuro → verde" = "brewer_RdYlGn", "Espectro (vermelho → violeta)" = "brewer_Spectral"),
  "Contínuas" = c("Magma" = "magma", "Inferno" = "inferno", "Turbo" = "turbo")
)

# Nomes de paletas que existiram antes e foram retiradas (para deixar a lista curta; programas, revistas e marcas saíram antes):
# quem ainda os usa (script, configuração salva) recebe a paleta mantida mais parecida e um aviso, em vez de um erro.
.PALETAS_ANTIGAS <- c(
  classico = "cinabro", marca = "cinabro", identidade = "cinabro", okabe_ito = "cinabro",
  tableau = "cinabro", d3 = "cinabro", npg = "cinabro", lancet = "cinabro", jco = "cinabro", nejm = "cinabro",
  tol_brilhante = "cinabro", tol_vibrante = "cinabro", tol_suave = "cinabro", tol_alto_contraste = "cinabro", tol_contraste = "cinabro",
  tol_medio_contraste = "cinabro", tol_claro = "cinabro", tol_escuro = "cinabro", tol_palido = "cinabro",
  brewer_Set1 = "cinabro", brewer_Set2 = "cinabro", brewer_Dark2 = "cinabro", brewer_Paired = "cinabro", brewer_Accent = "cinabro",
  brewer_Pastel1 = "cinabro", brewer_Pastel2 = "cinabro", brewer_Set3 = "cinabro",
  brewer_Blues = "brewer_YlGnBu", brewer_Greens = "brewer_YlGnBu", brewer_Oranges = "brewer_YlOrRd",
  brewer_RdYlBu = "brewer_Spectral", brewer_RdBu = "brewer_Spectral", brewer_BrBG = "brewer_RdYlGn", brewer_PiYG = "brewer_RdYlGn",
  brewer_PRGn = "brewer_RdYlGn",
  viridis = "brewer_YlGnBu", cividis = "brewer_YlGnBu", plasma = "magma", mako = "crameri_oslo", rocket = "magma",
  cmo_thermal = "inferno", cmo_haline = "brewer_YlGnBu", cmo_matter = "brewer_YlOrRd", cmo_deep = "crameri_oslo",
  cmo_balance = "brewer_Spectral", cmo_delta = "brewer_Spectral", cmo_curl = "brewer_Spectral",
  crameri_batlow = "turbo", crameri_roma = "brewer_Spectral", crameri_bam = "brewer_Spectral", crameri_vik = "brewer_Spectral",
  crameri_berlin = "brewer_Spectral", crameri_lajolla = "brewer_YlOrRd", crameri_bilbao = "brewer_YlOrRd",
  crameri_lapaz = "crameri_oslo", crameri_hawaii = "crameri_oslo", crameri_tokyo = "crameri_oslo",
  tol_por_do_sol = "brewer_YlOrRd", tol_iridescente = "brewer_Spectral", tol_BuRd = "brewer_Spectral",
  seq_azul = "brewer_YlGnBu", seq_verde = "brewer_YlGnBu", seq_laranja = "brewer_YlOrRd", seq_vermelho = "brewer_Reds",
  seq_roxo = "brewer_Purples", seq_azul_verde = "brewer_YlGnBu", seq_calor = "brewer_YlOrRd", seq_frio = "brewer_YlGnBu",
  div_vermelho_azul = "brewer_Spectral", div_espectro = "brewer_Spectral", div_marrom_verde = "brewer_RdYlGn", arco_iris = "brewer_Spectral")

# Entra: nome da paleta e n. Sai: vetor com n cores (interpola se a paleta for menor que n).
.paleta <- function(nome, n, cfg_cores = NULL) {
  n <- max(n, 1)
  if (nome %in% names(.PALETAS_ANTIGAS)) {                    # nome antigo: usa a paleta livre equivalente
    novo <- .PALETAS_ANTIGAS[[nome]]
    if (nome != "classico") .aviso("A paleta '", nome, "' foi retirada do Cinabro; usei '", novo, "'. Veja mostrar_paletas().")
    nome <- novo
  }
  base <- if (nome %in% names(.PALETAS)) {
    b <- .PALETAS[[nome]]
    if (nome %in% .PALETAS_RAMPA) return(if (n == 1) b[length(b) - 1] else grDevices::colorRampPalette(b)(n))
    b
  } else if (nome %in% .PALETAS_VIRIDIS) {
    if (!.tem("viridisLite")) .erro("Paleta '", nome, "' precisa do pacote viridisLite.")
    fun <- getExportedValue("viridisLite", nome)
    return(fun(n, end = 0.88))
  } else if (nome == "cinza") {                                # não aparece na lista; o estilo "publicacao_classico" (preto e branco) usa
    return(grDevices::grey.colors(n, start = 0, end = 0.75))
  } else if (nome == "personalizada") {
    vapply(cfg_cores$personalizada, .cor, character(1), onde = "cores$personalizada")
  } else {
    .erro("Paleta '", nome, "' desconhecida. Opções: ", paste(c(names(.PALETAS), .PALETAS_VIRIDIS), collapse = ", "),
          ", personalizada. Veja mostrar_paletas().")
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
