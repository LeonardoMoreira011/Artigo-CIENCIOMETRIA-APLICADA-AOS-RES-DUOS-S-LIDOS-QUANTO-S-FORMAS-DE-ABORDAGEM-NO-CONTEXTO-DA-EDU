# =============================================================================
#  R/19_marcadores.R — formas dos símbolos (nomes) e o símbolo "esfera" (bolinha com profundidade)
# =============================================================================

# Formas pelo nome (o número do R, de 0 a 25, continua valendo). "esfera" é o símbolo com volume (veja abaixo).
.SIMBOLOS_NOME <- c(circulo = 21, quadrado = 22, losango = 23, triangulo = 24, triangulo_invertido = 25,
                    circulo_vazio = 1, quadrado_vazio = 0, triangulo_vazio = 2, losango_vazio = 5,
                    triangulo_invertido_vazio = 6, cruz = 3, x = 4, estrela = 8, esfera = 99)
.COD_ESFERA <- 99

# Entra: nome ("quadrado") ou número (22). Sai: o código numérico. Erro claro se não existir.
.simbolo_codigo <- function(x, onde = "simbolo") {
  if (is.numeric(x)) return(x)
  if (length(x) != 1 || !x %in% names(.SIMBOLOS_NOME))
    .erro(onde, " = '", paste(x, collapse = ","), "' não é um símbolo válido. OPÇÕES: um número de 0 a 25 ou ",
          paste0('"', names(.SIMBOLOS_NOME), '"', collapse = " | "))
  unname(.SIMBOLOS_NOME[x])
}

# Escurece (f < 0) ou clareia (f > 0) uma cor. f entre -1 e 1.
.tom <- function(cor, f) {
  m <- grDevices::col2rgb(cor) / 255
  m <- if (f >= 0) m + (1 - m) * f else m * (1 + f)
  grDevices::rgb(m[1, ], m[2, ], m[3, ])
}

# Desenha esferas: círculos concentrados na direção da luz, do tom escuro (borda) ao claro (miolo), e um brilho.
# x, y: posições (unit); r_pt: raio em pt (vetor); cores: vetor; luz: c(x, y) de -1 a 1 (direção do brilho).
.grob_esferas <- function(x, y, r_pt, cores, luz = c(-0.35, -0.45), passos = 18) {
  n <- length(x)
  cores <- rep_len(cores, n); r_pt <- rep_len(r_pt, n)
  norma <- sqrt(sum(luz^2)); luz <- if (norma > 0) luz / norma else c(-0.6, -0.8)   # só a direção importa
  unicas <- unique(cores)                                # uma rampa de tons por cor (não por ponto)
  rampas <- lapply(unicas, function(cr) grDevices::colorRampPalette(c(.tom(cr, -0.45), cr, .tom(cr, 0.55)))(21))
  idx <- match(cores, unicas)
  filhos <- list()
  for (k in seq_len(passos)) {
    t <- (k - 1) / (passos - 1)                         # 0 = borda ... 1 = miolo claro
    raio <- r_pt * (1 - 0.82 * t)
    desloc <- (r_pt - raio) * 0.85                       # o miolo se afasta do centro, rumo à luz
    j <- 1 + round(t^1.15 * 20)
    col_k <- vapply(idx, function(i) rampas[[i]][j], "")
    filhos[[k]] <- grid::circleGrob(x = x + grid::unit(luz[1] * desloc, "pt"),
                                    y = y + grid::unit(luz[2] * desloc, "pt"),
                                    r = grid::unit(raio, "pt"), gp = grid::gpar(fill = col_k, col = NA))
  }
  brilho <- c(0.36, 0.25, 0.14)                          # brilho: 3 círculos brancos pequenos e translúcidos
  for (j in seq_along(brilho)) {
    filhos[[length(filhos) + 1]] <- grid::circleGrob(
      x = x + grid::unit(luz[1] * r_pt * 0.5, "pt"), y = y + grid::unit(luz[2] * r_pt * 0.5, "pt"),
      r = grid::unit(r_pt * brilho[j], "pt"), gp = grid::gpar(fill = grDevices::rgb(1, 1, 1, c(0.18, 0.32, 0.6)[j]),
                                                              col = NA))
  }
  do.call(grid::grobTree, filhos)
}

# Raio (pt) de um símbolo do ggplot (círculo 21): o mesmo cálculo do R base.
.raio_simbolo_pt <- function(size, stroke) 0.375 * (size * ggplot2::.pt + stroke * ggplot2::.stroke / 2)

# Chave da legenda da esfera: só desenha se a série for esfera (shape = 99).
.draw_key_esfera <- function(data, params, size) {
  if (!isTRUE(all(data$shape == .COD_ESFERA))) return(grid::nullGrob())
  .grob_esferas(grid::unit(0.5, "npc"), grid::unit(0.5, "npc"), .raio_simbolo_pt(data$size, data$stroke %||% 0.5),
                data$colour, luz = params$luz %||% c(-0.35, -0.45))
}

# Chave comum de ponto que não desenha as séries que são esfera (senão o R desenharia o caractere 99).
.draw_key_ponto_ou_nada <- function(data, params, size) {
  if (isTRUE(all(data$shape == .COD_ESFERA))) return(grid::nullGrob())
  ggplot2::draw_key_point(data, params, size)
}

.GeomEsfera <- ggplot2::ggproto("GeomEsfera", ggplot2::Geom,
  required_aes = c("x", "y"),
  default_aes = ggplot2::aes(colour = "black", size = 2, stroke = 0.5, shape = 99, alpha = NA, fill = NA),
  draw_key = .draw_key_esfera,
  extra_params = c("na.rm", "luz"),
  draw_panel = function(data, panel_params, coord, luz = c(-0.35, -0.45), na.rm = FALSE) {
    if (!nrow(data)) return(grid::nullGrob())
    co <- coord$transform(data, panel_params)
    .grob_esferas(grid::unit(co$x, "npc"), grid::unit(co$y, "npc"), .raio_simbolo_pt(co$size, co$stroke),
                  co$colour, luz = luz)
  })

geom_esfera <- function(mapping = NULL, data = NULL, luz = c(-0.35, -0.45), show.legend = NA, na.rm = TRUE,
                        key_glyph = NULL, ...) {
  ggplot2::layer(geom = .GeomEsfera, stat = "identity", position = "identity", data = data, mapping = mapping,
                 show.legend = show.legend, inherit.aes = FALSE,
                 params = c(list(na.rm = na.rm, luz = luz), if (!is.null(key_glyph)) list(key_glyph = key_glyph), list(...)))
}

# Chave da legenda que acompanha a escala da caixa da legenda (cfg$legenda$escala, inclusive a reduzida sozinha para caber):
# o tamanho do símbolo, o contorno e a grossura da linha mudam junto. 'base' = função draw_key_*.
.key_escala <- function(base, cfg) {
  env <- cfg$.interno$esc_leg
  function(data, params, size) {
    e <- if (is.null(env)) 1 else (env$v %||% 1)
    if (!isTRUE(all.equal(e, 1)))
      for (k in c("size", "stroke", "linewidth")) if (!is.null(data[[k]])) data[[k]] <- data[[k]] * e
    base(data, params, size)
  }
}
