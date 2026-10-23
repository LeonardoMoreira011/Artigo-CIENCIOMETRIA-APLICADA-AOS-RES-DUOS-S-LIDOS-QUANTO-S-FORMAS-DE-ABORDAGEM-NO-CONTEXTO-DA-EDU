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
# As do Cinabro são originais (cinabro, marca); okabe_ito é uma paleta publicada para daltonismo; as demais vêm de
# trabalhos com licença livre (cores em R/02_paletas_dados.R, avisos em NOTICE.md).
.PALETAS_PROPRIAS <- list(
  # a paleta padrão do Cinabro: preto, vermelho-cinábrio, azul-marinho, azul-céu, ardósia, ocre, violeta, siena, verde, verde-petróleo.
  # A ordem foi escolhida para que as primeiras cores sejam bem diferentes entre si, também para quem tem daltonismo.
  cinabro   = c("#000000", "#E34234", "#1B3A8C", "#2FA7D6", "#6B7B8C", "#E0A526", "#7B4FA3", "#8A4B2A", "#0E9F4B", "#0B6E78"),
  # as cores da marca (azul e verde), numa ordem pensada: as 4 primeiras são bem distintas entre si (inclusive para daltonismo);
  # a 5ª em diante se parecem mais (tons de azul e de verde). Com muitas séries, combine com formas e tipos de linha diferentes.
  marca     = c("#1B3A8C", "#0E9F4B", "#8CC63F", "#0B6E78", "#2FB5A0", "#5B7DB1", "#6BBF59", "#0F4C81"),
  # a identidade visual do Cinabro (sem o creme, que é o fundo): vermelho-cinábrio, azul-petróleo, tinta e terracota; com mais de 4 séries, varie também a forma e a linha
  identidade = c("#B3262E", "#2F6670", "#20242B", "#C96A4A"),
  okabe_ito = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9", "#000000", "#F0E442")
)
.PALETAS <- c(.PALETAS_PROPRIAS, .PALETAS_DADOS)
# As que percorrem um degradê (a n-ésima cor é interpolada ao longo da paleta inteira, não a n-ésima da lista).
.PALETAS_RAMPA <- c(grep("^brewer_(Blues|Greens|Oranges|Reds|Purples|YlGnBu|YlOrRd|RdYlGn|Spectral|RdYlBu|RdBu|BrBG|PiYG|PRGn)$", names(.PALETAS), value = TRUE),
                    "tol_por_do_sol", "tol_iridescente", "tol_BuRd", grep("^(cmo|crameri)_", names(.PALETAS), value = TRUE))
.PALETAS_VIRIDIS <- c("viridis", "magma", "plasma", "cividis", "inferno", "turbo", "mako", "rocket")   # do pacote viridisLite

# Para a tela e para mostrar_paletas(): grupo -> c(rótulo = nome).
.PALETAS_GRUPOS <- list(
  "Do Cinabro" = c("Cinabro (padrão)" = "cinabro", "Marca (azul e verde)" = "marca", "Identidade Cinabro (vermelho, petróleo, tinta, terracota)" = "identidade"),
  "Acessíveis (daltonismo)" = c("Okabe-Ito" = "okabe_ito", "Tol: brilhante" = "tol_brilhante", "Tol: vibrante" = "tol_vibrante",
                                "Tol: suave" = "tol_suave", "Tol: alto contraste" = "tol_alto_contraste",
                                "Tol: contraste médio" = "tol_medio_contraste", "Tol: claro" = "tol_claro",
                                "Tol: escuro" = "tol_escuro", "Tol: pálido" = "tol_palido"),
  "Qualitativas (Brewer)" = c("Vivas (Set1)" = "brewer_Set1", "Suaves (Set2)" = "brewer_Set2", "Escuras (Dark2)" = "brewer_Dark2",
                              "Em pares (Paired)" = "brewer_Paired", "Destaque (Accent)" = "brewer_Accent",
                              "Pastel 1" = "brewer_Pastel1", "Pastel 2" = "brewer_Pastel2", "Doces (Set3)" = "brewer_Set3"),
  "Degradês de uma cor (Brewer)" = c("Azuis" = "brewer_Blues", "Verdes" = "brewer_Greens", "Laranjas" = "brewer_Oranges",
                                     "Vermelhos" = "brewer_Reds", "Roxos" = "brewer_Purples", "Amarelo → azul" = "brewer_YlGnBu",
                                     "Amarelo → vermelho" = "brewer_YlOrRd"),
  "Divergentes (Brewer)" = c("Vermelho-escuro → verde" = "brewer_RdYlGn", "Espectro (vermelho → violeta)" = "brewer_Spectral",
                             "Vermelho → azul, com amarelo" = "brewer_RdYlBu", "Vermelho ↔ azul" = "brewer_RdBu",
                             "Marrom ↔ verde-azulado" = "brewer_BrBG", "Rosa ↔ verde" = "brewer_PiYG", "Roxo ↔ verde" = "brewer_PRGn"),
  "Contínuas (viridis)" = c("Viridis" = "viridis", "Magma" = "magma", "Plasma" = "plasma", "Cividis" = "cividis",
                            "Inferno" = "inferno", "Turbo" = "turbo", "Mako" = "mako", "Rocket" = "rocket"),
  "Contínuas (cmocean)" = c("Térmica" = "cmo_thermal", "Salinidade" = "cmo_haline", "Algas" = "cmo_algae", "Matéria" = "cmo_matter",
                            "Profundidade" = "cmo_deep", "Balanço" = "cmo_balance", "Delta" = "cmo_delta", "Curl" = "cmo_curl"),
  "Contínuas (Crameri)" = c("Batlow" = "crameri_batlow", "Roma (vermelho-marrom → azul)" = "crameri_roma",
                            "Bam (magenta → verde)" = "crameri_bam", "Vik" = "crameri_vik", "Lajolla" = "crameri_lajolla",
                            "Bilbao" = "crameri_bilbao", "Oslo" = "crameri_oslo", "La Paz" = "crameri_lapaz",
                            "Havaí" = "crameri_hawaii", "Tóquio" = "crameri_tokyo", "Berlim" = "crameri_berlin"),
  "Contínuas (Tol)" = c("Pôr do sol" = "tol_por_do_sol", "Iridescente" = "tol_iridescente", "Azul ↔ vermelho" = "tol_BuRd"),
  "Cinza" = c("Tons de cinza" = "cinza")
)

# Nomes de paletas que existiram antes e foram retiradas (paletas ligadas a programas, revistas ou marcas): quem ainda os usa recebe
# uma paleta livre parecida e um aviso, em vez de um erro.
.PALETAS_ANTIGAS <- c(classico = "cinabro", tableau = "okabe_ito", d3 = "okabe_ito", npg = "okabe_ito", lancet = "okabe_ito", jco = "okabe_ito",
                      nejm = "okabe_ito", seq_azul = "brewer_Blues", seq_verde = "brewer_Greens", seq_laranja = "brewer_Oranges",
                      seq_vermelho = "brewer_Reds", seq_roxo = "brewer_Purples", seq_azul_verde = "brewer_YlGnBu", seq_calor = "brewer_YlOrRd",
                      seq_frio = "brewer_Blues", div_vermelho_azul = "brewer_RdBu", div_espectro = "brewer_Spectral",
                      div_marrom_verde = "brewer_BrBG", arco_iris = "brewer_Spectral", tol_contraste = "tol_alto_contraste")

# Entra: nome da paleta e n. Sai: vetor com n cores (interpola se a paleta for menor que n).
.paleta <- function(nome, n, cfg_cores = NULL) {
  n <- max(n, 1)
  if (nome %in% names(.PALETAS_ANTIGAS)) {                    # nome antigo: usa a paleta livre equivalente
    novo <- .PALETAS_ANTIGAS[[nome]]
    if (nome != "classico") .aviso("A paleta '", nome, "' foi retirada do Cinabro (só ficam paletas de licença livre); usei '", novo, "'. Veja mostrar_paletas().")
    nome <- novo
  }
  base <- if (nome %in% names(.PALETAS)) {
    b <- .PALETAS[[nome]]
    if (nome %in% .PALETAS_RAMPA) return(if (n == 1) b[length(b) - 1] else grDevices::colorRampPalette(b)(n))
    b
  } else if (nome %in% .PALETAS_VIRIDIS) {
    if (!.tem("viridisLite")) .erro("Paleta '", nome, "' precisa do pacote viridisLite.")
    fun <- getExportedValue("viridisLite", nome)
    return(fun(n, end = if (nome %in% c("viridis", "cividis")) 0.92 else 0.88))
  } else if (nome == "cinza") {
    return(grDevices::grey.colors(n, start = 0, end = 0.75))
  } else if (startsWith(nome, "brewer_")) {                    # as demais do ColorBrewer, pelo pacote RColorBrewer
    if (!.tem("RColorBrewer")) .erro("Paletas brewer_ precisam do pacote RColorBrewer.")
    pal <- sub("^brewer_", "", nome)
    info <- RColorBrewer::brewer.pal.info
    if (!pal %in% rownames(info))
      .erro("Paleta ColorBrewer '", pal, "' não existe. Opções: ",
            paste(rownames(info), collapse = ", "))
    b <- RColorBrewer::brewer.pal(info[pal, "maxcolors"], pal)
    if (info[pal, "category"] != "qual") return(if (n == 1) b[length(b) - 1] else grDevices::colorRampPalette(b)(n))
    b
  } else if (nome == "personalizada") {
    vapply(cfg_cores$personalizada, .cor, character(1), onde = "cores$personalizada")
  } else {
    .erro("Paleta '", nome, "' desconhecida. Opções: ", paste(c(names(.PALETAS), .PALETAS_VIRIDIS, "cinza"), collapse = ", "),
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
