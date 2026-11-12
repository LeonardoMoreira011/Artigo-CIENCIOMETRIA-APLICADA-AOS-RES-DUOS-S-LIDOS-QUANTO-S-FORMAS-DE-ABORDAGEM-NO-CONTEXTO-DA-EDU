# =============================================================================
#  R/26_tipo_3d.R — mapa de cor (X, Y, Z), superfície 3D, barras 3D e dispersão 3D
# =============================================================================
#  A planilha tem os três eixos. Formato "matriz" (padrão): a 1ª coluna traz os valores de Y, os cabeçalhos das outras colunas são os valores
#  de X e as células são o Z. Formato "longo": uma linha por ponto, com X (cfg$grafico$coluna_x), Y (cfg$grafico$coluna_grupo; vazio = a 2ª
#  coluna) e Z (a 1ª das colunas Y; vazio = a 3ª). O formato vem de cfg$mapa_calor$formato e a cor de Z, de cfg$mapa_calor (esquema_cor,
#  cores_escala, limites, centro, barra), os mesmos do mapa de calor. O ângulo, os eixos e a caixa do 3D vêm de cfg$tridimensional.
#  O 3D é desenhado aqui mesmo, só com o ggplot2 (projeção ortográfica e pintura das faces de atras para a frente): sem pacote extra.
# =============================================================================

# ---- leitura da planilha XYZ ----------------------------------------------------------------------
.tri_num <- function(v) suppressWarnings(as.numeric(gsub(",", ".", as.character(v), fixed = TRUE)))

# Entra: dados e cfg. Sai: list(x, y, Z (linhas = Y, colunas = X), nome_x, nome_y, nome_z). x e y são números ou, se a coluna for texto, nomes.
.grade_xyz <- function(dados, cfg) {
  H <- cfg$mapa_calor; G <- cfg$grafico
  xcol <- .coluna(dados, G$coluna_x %||% 1, "cfg$grafico$coluna_x")
  if (identical(H$formato, "longo")) {
    gcol <- if (!is.null(G$coluna_grupo)) .coluna(dados, G$coluna_grupo, "cfg$grafico$coluna_grupo") else setdiff(names(dados), xcol)[1]
    if (is.na(gcol)) .erro("Formato \"longo\": precisa de três colunas (X, Y e Z). A planilha tem só uma.")
    zcol <- .colunas_y(dados, cfg, excluir = c(xcol, gcol))[1]
    vx <- dados[[xcol]]; vy <- dados[[gcol]]
    ux <- if (is.numeric(vx)) sort(unique(vx[is.finite(vx)])) else unique(as.character(vx[!is.na(vx)]))
    uy <- if (is.numeric(vy)) sort(unique(vy[is.finite(vy)])) else unique(as.character(vy[!is.na(vy)]))
    ix <- match(vx, ux); iy <- match(vy, uy)
    if (anyDuplicated(paste(ix, iy)[!is.na(ix) & !is.na(iy)])) .aviso("Há linhas repetidas para o mesmo par (", xcol, ", ", gcol, "): usei a média.")
    Z <- tapply(dados[[zcol]], list(factor(iy, seq_along(uy)), factor(ix, seq_along(ux))), mean, na.rm = TRUE)
    Z <- matrix(as.numeric(Z), length(uy), length(ux)); Z[is.nan(Z)] <- NA
    return(list(x = ux, y = uy, Z = Z, nome_x = xcol, nome_y = gcol, nome_z = zcol))
  }
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  if (length(ycols) < 2) .erro("Formato \"matriz\": a 1ª coluna traz os valores de Y e as outras colunas (os cabeçalhos são os valores de X) trazem o Z. ",
                               "Preciso de pelo menos 2 colunas de Z. Se a planilha tem uma linha por ponto, mude o formato para \"longo\".")
  hx <- .tri_num(ycols)
  ux <- if (all(is.finite(hx))) hx else ycols
  vy <- dados[[xcol]]; uy <- if (is.numeric(vy)) vy else as.character(vy)
  Z <- as.matrix(dados[ycols]); storage.mode(Z) <- "double"
  if (anyDuplicated(uy)) {
    .aviso("Valores repetidos na 1ª coluna ('", xcol, "'): usei a média das linhas repetidas.")
    f <- factor(uy, levels = unique(uy)); uy <- unique(uy)
    Z <- matrix(vapply(seq_len(ncol(Z)), function(j) as.numeric(tapply(Z[, j], f, mean, na.rm = TRUE)), numeric(length(uy))), length(uy))
  }
  if (anyDuplicated(ux)) .erro("Há cabeçalhos repetidos entre as colunas de Z (os valores de X devem ser diferentes).")
  oy <- if (is.numeric(uy)) order(uy) else seq_along(uy); ox <- if (is.numeric(ux)) order(ux) else seq_along(ux)
  Z <- unname(Z[oy, ox, drop = FALSE]); Z[is.nan(Z)] <- NA
  list(x = ux[ox], y = uy[oy], Z = Z, nome_x = "", nome_y = xcol, nome_z = NULL)
}

# Pontos (x, y, z) para a dispersão 3D: de um "longo" (uma linha por ponto) ou das células de uma matriz.
.pontos_xyz <- function(dados, cfg) {
  H <- cfg$mapa_calor; G <- cfg$grafico
  if (identical(H$formato, "longo")) {
    xcol <- .coluna(dados, G$coluna_x %||% 1, "cfg$grafico$coluna_x")
    ycol <- if (!is.null(G$coluna_grupo)) .coluna(dados, G$coluna_grupo, "cfg$grafico$coluna_grupo") else setdiff(names(dados), xcol)[1]
    if (is.na(ycol)) .erro("A dispersão 3D precisa de três colunas numéricas (X, Y e Z).")
    zcol <- .colunas_y(dados, cfg, excluir = c(xcol, ycol))[1]
    d <- data.frame(x = dados[[xcol]], y = dados[[ycol]], z = dados[[zcol]])
    if (!is.numeric(d$x) || !is.numeric(d$y)) .erro("Na dispersão 3D, as colunas '", xcol, "' (X) e '", ycol, "' (Y) precisam ser numéricas.")
    d <- d[is.finite(d$x) & is.finite(d$y) & is.finite(d$z), , drop = FALSE]
    return(list(d = d, nome_x = xcol, nome_y = ycol, nome_z = zcol))
  }
  m <- .grade_xyz(dados, cfg)
  if (!is.numeric(m$x) || !is.numeric(m$y)) .erro("Na dispersão 3D, a 1ª coluna e os cabeçalhos precisam ser números (os valores de Y e de X).")
  d <- data.frame(x = rep(m$x, each = length(m$y)), y = rep(m$y, times = length(m$x)), z = as.vector(m$Z))
  list(d = d[is.finite(d$z), , drop = FALSE], nome_x = m$nome_x, nome_y = m$nome_y, nome_z = m$nome_z)
}

# Deixa a grade com no máximo `maximo` células (pega 1 a cada k linhas/colunas) e avisa.
.limitar_grade <- function(m, maximo = 40000) {
  nx <- length(m$x); ny <- length(m$y)
  if ((nx - 1) * (ny - 1) <= maximo) return(m)
  k <- ceiling(sqrt((nx - 1) * (ny - 1) / maximo)); ix <- unique(c(seq(1, nx, by = k), nx)); iy <- unique(c(seq(1, ny, by = k), ny))
  .aviso("A grade tem ", nx, " x ", ny, " pontos; para o desenho não ficar pesado, usei 1 a cada ", k, " em cada eixo.")
  m$x <- m$x[ix]; m$y <- m$y[iy]; m$Z <- m$Z[iy, ix, drop = FALSE]; m
}

# Refina a grade por interpolação em spline cúbico (n subdivisões por célula): as cores e a superfície ficam fluidas, sem as quebras de uma grade grossa.
# Os valores não passam do menor e do maior da tabela. Só para eixos numéricos; com célula vazia (NA) a grade fica como está.
.refinar_grade <- function(m, n) {
  if (n < 2 || !is.numeric(m$x) || !is.numeric(m$y) || length(m$x) < 2 || length(m$y) < 2 || anyNA(m$Z)) return(m)
  sub <- function(v) unique(unlist(lapply(seq_len(length(v) - 1), function(i) seq(v[i], v[i + 1], length.out = n + 1))))
  nx <- sub(m$x); ny <- sub(m$y)
  f <- function(x, y, xo) if (length(x) >= 3) stats::spline(x, y, xout = xo, method = "natural")$y else stats::approx(x, y, xout = xo)$y
  Zx <- t(apply(m$Z, 1, function(r) f(m$x, r, nx)))
  Zy <- matrix(apply(Zx, 2, function(cl) f(m$y, cl, ny)), length(ny), length(nx))
  m$x <- nx; m$y <- ny; m$Z <- pmin(pmax(Zy, min(m$Z)), max(m$Z)); m
}
# Subdivisões por célula: o que o usuário escolheu (cfg$tridimensional$suavizar) ou, no automático, o bastante para chegar a ~alvo células no eixo maior.
.n_suavizar <- function(s, m, alvo, maximo = 12) {
  if (.modo_rapido()) { alvo <- alvo / 3; maximo <- min(maximo, 6); if (!is.null(s) && is.finite(s)) s <- min(s, 3) }
  if (!is.null(s) && is.finite(s)) return(as.integer(s))
  if (!is.numeric(m$x) || !is.numeric(m$y)) return(1L)
  as.integer(max(1, min(maximo, ceiling(alvo / max(length(m$x) - 1, length(m$y) - 1, 1)))))
}
# Clareia (f > 1) ou escurece (f < 1) uma cor.
.sombrear <- function(cor, f) {
  m <- grDevices::col2rgb(cor); f <- rep_len(f, ncol(m)); esc <- f < 1
  r <- m; r[, esc] <- t(t(m[, esc, drop = FALSE]) * f[esc])                                   # escurece
  r[, !esc] <- 255 - t(t(255 - m[, !esc, drop = FALSE]) * pmax(2 - f[!esc], 0))             # clareia
  grDevices::rgb(pmin(pmax(r[1, ], 0), 255), pmin(pmax(r[2, ], 0), 255), pmin(pmax(r[3, ], 0), 255), maxColorValue = 255)
}

# ---- eixos ---------------------------------------------------------------------------------------
# Eixo do 3D: faixa e traços. Numérico: usa os mesmos ajustes do eixo comum (início, fim, intervalo, casas...). Texto: uma posição por nome.
.eixo3d <- function(e, v, cat = FALSE, folga = 0) {
  if (cat) return(list(lo = 0.5, hi = length(v) + 0.5, pos = seq_along(v), rot = as.character(v), cat = TRUE))
  e$margem_percentual <- 0
  if (!identical(e$escala %||% "linear", "linear")) { .aviso("No 3D os eixos são lineares; a escala \"", e$escala, "\" foi ignorada."); e$escala <- "linear" }
  ax <- .calc_eixo(e, range(v[is.finite(v)]) + c(-folga, folga))
  rot <- if (is.function(ax$rotulos)) ax$rotulos(ax$maiores) else ax$rotulos
  list(lo = ax$limites[1], hi = ax$limites[2], pos = ax$maiores, rot = as.character(rot), cat = FALSE)
}
.n3 <- function(ej, v) {
  if (ej$cat) return((v - ej$lo) / (ej$hi - ej$lo))
  fora <- is.finite(v) & (v < ej$lo - 1e-9 * abs(ej$hi - ej$lo) | v > ej$hi + 1e-9 * abs(ej$hi - ej$lo))
  if (any(fora)) .aviso(sum(fora), " valor(es) fora do eixo (", ej$lo, " a ", ej$hi, ") foram encostados na borda.")
  (pmin(pmax(v, ej$lo), ej$hi) - ej$lo) / (ej$hi - ej$lo)
}
# Eixo Z: o estilo vem do eixo Y; início, fim, intervalo e título, de cfg$tridimensional.
.eixo_z <- function(cfg) {
  T <- cfg$tridimensional; e <- cfg$eixo_y
  e$inicio <- T$z_inicio; e$fim <- T$z_fim; e$titulo <- T$z_titulo; e$ticks_modo <- if (is.null(T$z_intervalo)) "auto" else "incremento"
  e$incremento <- T$z_intervalo; e$quantidade <- NULL; e$primeiro_tick <- NULL; e$ticks_manuais <- NULL; e$rotulos_manuais <- NULL; e$n_menores <- 0
  e
}

# ---- projeção ------------------------------------------------------------------------------------
# Visão ortográfica: gira em volta do eixo vertical (azimute) e inclina (elevação). x e y em 0..1, z em 0..H. d = profundidade (maior = mais longe).
.proj3d <- function(az, el, prof = 1, persp = 0) {
  a <- az * pi / 180; e <- el * pi / 180; prof <- prof %||% 1; persp <- min(max(persp %||% 0, 0), 1)
  function(x, y, z) {
    x <- x - 0.5; y <- (y - 0.5) * prof                                   # prof: profundidade do eixo Y em relação ao X
    xr <- x * cos(a) - y * sin(a); yr <- x * sin(a) + y * cos(a)
    d <- yr * cos(e) - z * sin(e); f <- 1 / (1 + persp * 0.5 * d)           # perspectiva: o que está longe encolhe um pouco
    list(sx = xr * f, sy = (z * cos(e) + yr * sin(e)) * f, d = d)
  }
}
# Modo rápido (durante o giro com o mouse): menos pontos e faixas, só para a prévia andar leve.
.modo_rapido <- function() isTRUE(getOption("cinabro.rapido"))
# Escurece uma cor (f < 1) para o lado das barras.
.escurecer <- function(cor, f) { m <- grDevices::col2rgb(cor) * f; grDevices::rgb(pmin(m[1, ], 255), pmin(m[2, ], 255), pmin(m[3, ], 255), maxColorValue = 255) }

# Polígonos (4 cantos cada) em tabela para o geom_polygon. cx, cy: matrizes n x 4 na ordem de desenho; ordem: do mais longe ao mais perto.
.tabela_faces <- function(cx, cy, extra = list()) {
  n <- nrow(cx); out <- data.frame(x = as.vector(t(cx)), y = as.vector(t(cy)), grp = rep(seq_len(n), each = ncol(cx)))
  for (k in names(extra)) out[[k]] <- rep(extra[[k]], each = ncol(cx))
  out
}

# Estilo do texto do 3D
.estilo3d <- function(cfg, e = cfg$eixo_x) {
  b <- cfg$texto$tamanho_base_pt; T <- cfg$tridimensional
  list(fonte = .fonte(cfg$texto$fonte), pt_rot = e$tamanho_rotulos_pt %||% b * 0.9, pt_tit = e$tamanho_titulo_pt %||% b,
       cor_rot = .cor(e$cor_rotulos %||% cfg$texto$cor), cor_tit = .cor(e$cor_titulo %||% cfg$texto$cor),
       face_rot = if (.neg(cfg, e$negrito_rotulos)) "bold" else "plain", face_tit = if (.neg(cfg, e$negrito_titulo)) "bold" else "plain",
       cor_linha = .cor(e$cor_linha %||% "black"), esp_linha = e$espessura_linha_pt %||% cfg$caixa$espessura_pt %||% 0.75,
       mostrar_rot = !identical(e$mostrar_rotulos, FALSE), mostrar_tit = !identical(e$mostrar_titulo, FALSE), mostrar_linha = !identical(e$mostrar_linha, FALSE),
       tick_in = if (identical(e$direcao_maiores, "nenhum")) 0 else (T$traco_comprimento_pt %||% e$comprimento_maiores_pt %||% 3.6) / 72)
}

# Números e títulos de eixos diferentes não podem ficar um sobre o outro (ex.: o 450 do X e o 0,5 do Y no mesmo canto). Cada texto vira uma fila de círculos
# (do tamanho da letra, ao longo do texto); se encosta num texto de OUTRO eixo, ele sai um pouco mais para fora, na sua própria direção, até ficar livre.
.desencostar_rotulos3d <- function(rt, tt, S, upi, larg_in) {
  if (is.null(rt)) return(list(rot = rt, tit = tt))
  circulos <- function(x, y, xe, ye, comp, w, h) {                  # (em polegadas) centros e raio
    if (comp > 0) { n <- max(2, ceiling(comp / h)); k <- seq(0, 1, length.out = n); cbind(x + (xe - x) * k, y + (ye - y) * k) }
    else { n <- max(1, ceiling(w / h)); k <- if (n == 1) 0 else seq(-0.5, 0.5, length.out = n) * (w - h); cbind(x + k, rep(y, n)) }
  }
  achar <- function(d, C, r, outro) any(vapply(C, function(Q) { if (is.null(Q)) return(FALSE); dd <- sqrt(outer(d[, 1], Q$c[, 1], "-")^2 + outer(d[, 2], Q$c[, 2], "-")^2); any(dd < (r + Q$r) * 0.9) }, NA))
  pos <- list()
  for (i in seq_len(nrow(rt))) {
    h <- rt$pt[i] / 72; w <- larg_in(rt$lab[i], rt$pt[i]); x <- rt$x[i] / upi; y <- rt$y[i] / upi; xe <- rt$xe[i] / upi; ye <- rt$ye[i] / upi
    outros <- pos[vapply(pos, function(q) !identical(q$eix, rt$eix[i]), NA)]
    for (k in 0:12) {
      dx <- rt$ux[i] * k * 0.3 * h; dy <- rt$uy[i] * k * 0.3 * h
      cc <- circulos(x + dx, y + dy, xe + dx, ye + dy, rt$comp[i], w, h)
      if (!achar(cc, outros, h / 2, NULL) || k == 12) break
    }
    rt$x[i] <- (x + dx) * upi; rt$y[i] <- (y + dy) * upi; rt$xe[i] <- (xe + dx) * upi; rt$ye[i] <- (ye + dy) * upi
    pos[[length(pos) + 1]] <- list(eix = rt$eix[i], c = cc, r = h / 2)
  }
  if (!is.null(tt)) {
    for (i in seq_len(nrow(tt))) {
      ht <- tt$pt[i] / 72; w <- larg_in(tt$lab[i], tt$pt[i]); x <- tt$x[i] / upi; y <- tt$y[i] / upi; a <- tt$ang[i] * pi / 180
      for (k in 0:12) {
        dx <- tt$ux[i] * k * 0.3 * ht; dy <- tt$uy[i] * k * 0.3 * ht
        n <- max(2, ceiling(w / ht)); s <- seq(-0.5, 0.5, length.out = n) * (w - ht); cc <- cbind(x + dx + s * cos(a), y + dy + s * sin(a))
        if (!achar(cc, pos, ht / 2, NULL) || k == 12) break
      }
      tt$x[i] <- (x + dx) * upi; tt$y[i] <- (y + dy) * upi
    }
  }
  list(rot = rt, tit = tt)
}

# Fundo do 3D: piso, paredes de atras, grade, eixos, traços, números e títulos. Devolve camadas e a caixa que ocupam (para os limites do gráfico).
# upi = unidades do desenho por polegada (o tamanho dos textos e dos afastamentos é em pontos, não depende do zoom).
.fundo3d <- function(P, E, H, cfg, upi, titulos) {
  T <- cfg$tridimensional; a <- T$azimute * pi / 180
  SS <- list(x = .estilo3d(cfg, cfg$eixo_x), y = .estilo3d(cfg, cfg$eixo_y), z = .estilo3d(cfg, .eixo_z(cfg))); S <- SS$x
  cam <- list(); ext <- matrix(numeric(0), 0, 2)
  gap_in <- 0.05
  # paredes de atras: a normal de fora aponta para longe de quem olha
  paredes <- list(list(n = c(-1, 0), pts = rbind(c(0, 0, 0), c(0, 1, 0), c(0, 1, H), c(0, 0, H))),
                  list(n = c(1, 0), pts = rbind(c(1, 0, 0), c(1, 1, 0), c(1, 1, H), c(1, 0, H))),
                  list(n = c(0, -1), pts = rbind(c(0, 0, 0), c(1, 0, 0), c(1, 0, H), c(0, 0, H))),
                  list(n = c(0, 1), pts = rbind(c(0, 1, 0), c(1, 1, 0), c(1, 1, H), c(0, 1, H))))
  atras <- Filter(function(w) w$n[1] * sin(a) + w$n[2] * cos(a) > 1e-9, paredes)
  piso <- list(n = c(0, 0), pts = rbind(c(0, 0, 0), c(1, 0, 0), c(1, 1, 0), c(0, 1, 0)))
  tx <- .n3(E$x, E$x$pos); ty <- .n3(E$y, E$y$pos); tz <- .n3(E$z, E$z$pos) * H
  faces <- if (identical(T$caixa, "paredes")) c(list(piso), atras) else if (identical(T$caixa, "base")) list(piso) else list()
  if (length(faces)) {
    pol <- do.call(rbind, lapply(seq_along(faces), function(i) { p <- P(faces[[i]]$pts[, 1], faces[[i]]$pts[, 2], faces[[i]]$pts[, 3]); data.frame(x = p$sx, y = p$sy, grp = i) }))
    cam[[length(cam) + 1]] <- geom_polygon(data = pol, aes(x = x, y = y, group = grp), fill = .cor(T$cor_paredes), colour = .cor(T$cor_caixa), linewidth = .lw(T$caixa_espessura_pt %||% 0.4))
    # grade sobre o piso e as paredes
    seg <- list(); add <- function(p0, p1) seg[[length(seg) + 1]] <<- c(p0, p1)
    add_f <- function(f) {
      if (all(f$n == 0)) { for (t in tx) add(c(t, 0, 0), c(t, 1, 0)); for (t in ty) add(c(0, t, 0), c(1, t, 0)) }
      else if (f$n[1] != 0) { c0 <- if (f$n[1] < 0) 0 else 1; for (t in ty) add(c(c0, t, 0), c(c0, t, H)); for (t in tz) add(c(c0, 0, t), c(c0, 1, t)) }
      else { c0 <- if (f$n[2] < 0) 0 else 1; for (t in tx) add(c(t, c0, 0), c(t, c0, H)); for (t in tz) add(c(0, c0, t), c(1, c0, t)) }
    }
    if (!identical(T$grade_mostrar, FALSE)) for (f in faces) add_f(f)
    if (length(seg)) {
      s <- do.call(rbind, seg); p0 <- P(s[, 1], s[, 2], s[, 3]); p1 <- P(s[, 4], s[, 5], s[, 6])
      cam[[length(cam) + 1]] <- geom_segment(data = data.frame(x = p0$sx, y = p0$sy, xend = p1$sx, yend = p1$sy), aes(x = x, y = y, xend = xend, yend = yend),
                                              colour = .cor(T$cor_grade), linewidth = .lw(T$grade_espessura_pt %||% 0.3))
    }
  }
  pc <- P(0.5, 0.5, 0); centro <- c(pc$sx, pc$sy)
  # meia extensão (polegadas) de um texto w x h, girado th graus, na direção u
  alvo_in <- function(w, h, u, th = 0) { d <- th * pi / 180 - atan2(u[2], u[1]); (w * abs(cos(d)) + h * abs(sin(d))) / 2 }
  larg_in <- function(txt, pt) max(nchar(txt), 1) * pt * 0.52 / 72
  rots <- list(); tks <- list(); tits <- list()
  # eixo ao longo de uma aresta: p(t) = ponto da aresta no parâmetro t (0..1); ticks em t = tt, rótulos em rot.
  # Se os nomes não cabem lado a lado, ficam em leque: cada um sai do traço, girado na direção para fora.
  eixo_aresta <- function(p, tt, rot, titulo, u_fix = NULL, ang_fix = NULL, nome = "", S = SS$x) {
    tick_in <- S$tick_in; if (!isTRUE(S$mostrar_rot)) rot <- rep("", length(rot)); if (!isTRUE(S$mostrar_tit)) titulo <- ""
    m <- p(0.5); p0 <- p(0); p1 <- p(1)
    u <- u_fix %||% { ev <- c(p1$sx - p0$sx, p1$sy - p0$sy); ev <- ev / max(sqrt(sum(ev^2)), 1e-9); pp <- c(-ev[2], ev[1])           # perpendicular à aresta, para fora
                      if (sum(pp * (c(m$sx, m$sy) - centro)) < 0) -pp else pp }
    ang <- ang_fix %||% (atan2(p1$sy - p0$sy, p1$sx - p0$sx) * 180 / pi)
    if (ang > 90) ang <- ang - 180; if (ang <= -90) ang <- ang + 180
    pt <- p(tt); pt$sx <- rep_len(pt$sx, length(tt)); pt$sy <- rep_len(pt$sy, length(tt)); h <- S$pt_rot / 72
    ws <- vapply(rot, larg_in, 0, pt = S$pt_rot)
    colide <- length(tt) > 1 && any(vapply(seq_len(length(tt) - 1), function(i) abs(pt$sx[i + 1] - pt$sx[i]) / upi < (ws[i] + ws[i + 1]) / 2 + 0.02 && abs(pt$sy[i + 1] - pt$sy[i]) / upi < h * 1.4, NA))
    # eixo quase de ponta para o olhar (vista de lado ou de cima): os números não cabem em fila; fica só o que não encosta no vizinho
    manter <- rep(TRUE, length(tt))
    if (sqrt((p1$sx - p0$sx)^2 + (p1$sy - p0$sy)^2) / upi < h * 3.2) { manter[] <- FALSE; titulo <- ""; colide <- FALSE }      # aresta quase de ponta (vista de cima ou de trás): sem números nem título, para não empilhar
    else if (colide && length(tt) > 2) {
      lim <- h * 1.5; dis <- function(i, j) sqrt((pt$sx[i] - pt$sx[j])^2 + (pt$sy[i] - pt$sy[j])^2) / upi
      k_ <- 1L; for (i in seq_along(tt)[-1]) if (dis(i, k_[length(k_)]) >= lim) k_ <- c(k_, i)
      n_ <- length(tt); if (!(n_ %in% k_)) { if (length(k_) > 1 && dis(n_, k_[length(k_) - 1]) >= lim) k_[length(k_)] <- n_ else if (length(k_) == 1L && dis(n_, 1L) >= lim) k_ <- c(k_, n_) }
      if (length(k_) < 2L) k_ <- integer(0)
      manter <- seq_along(tt) %in% k_; colide <- FALSE; ws <- ws * 0 + max(ws)
      if (any(manter)) { ws2 <- ws[manter]; if (length(k_) > 1) colide <- any(vapply(seq_len(length(k_) - 1), function(i) abs(pt$sx[k_[i + 1]] - pt$sx[k_[i]]) / upi < max(ws2) + 0.02 && abs(pt$sy[k_[i + 1]] - pt$sy[k_[i]]) / upi < h * 1.4, NA)) }
    }
    th <- 0; hj <- 0.5
    if (colide) { th <- atan2(u[2], u[1]) * 180 / pi; if (abs(th) > 90) { th <- th + if (th > 0) -180 else 180; hj <- 1 } else hj <- 0 }
    ext_rot <- if (colide) max(ws) else alvo_in(max(ws), h, u)
    for (i in seq_along(tt)) {
      if (!manter[i]) next
      d_in <- tick_in + gap_in + if (colide) 0 else alvo_in(ws[i], h, u)
      tks[[length(tks) + 1]] <<- data.frame(eix = nome, x = pt$sx[i], y = pt$sy[i], xend = pt$sx[i] + u[1] * tick_in * upi, yend = pt$sy[i] + u[2] * tick_in * upi)
      sobe <- if (!is.null(ang_fix) && tt[i] <= 1e-9) 0.55 * h * upi else 0          # no eixo Z, o número do piso sobe um pouco (não encosta no do eixo Y)
      rots[[length(rots) + 1]] <<- data.frame(x = pt$sx[i] + u[1] * d_in * upi, y = pt$sy[i] + u[2] * d_in * upi + sobe, lab = rot[i], pt = S$pt_rot, ang = th, hj = hj, comp = if (colide) ws[i] else 0, ux = u[1], uy = u[2], eix = nome, xe = pt$sx[i] + u[1] * (d_in + ws[i]) * upi, ye = pt$sy[i] + u[2] * (d_in + ws[i]) * upi + sobe)
    }
    if (nzchar(titulo)) {
      ht <- S$pt_tit / 72; d_in <- tick_in + gap_in + (if (colide) ext_rot else 2 * ext_rot) + gap_in + alvo_in(larg_in(titulo, S$pt_tit), ht, u, ang)
      tits[[length(tits) + 1]] <<- data.frame(x = m$sx + u[1] * d_in * upi, y = m$sy + u[2] * d_in * upi, lab = titulo, pt = S$pt_tit, ang = ang, ux = u[1], uy = u[2], eix = nome)
    }
  }
  # arestas do piso mais perto de quem olha
  y_fr <- if (cos(a) > 1e-9 || abs(cos(a)) <= 1e-9) 0 else 1
  cantos <- expand.grid(x = c(0, 1), y = c(0, 1)); sxs <- P(cantos$x, cantos$y, 0)$sx; k <- which.min(sxs)               # o eixo Z fica na aresta vertical mais à esquerda
  x_fr <- if (abs(sin(a)) < 0.45) 1 - cantos$x[k] else if (sin(a) > 0) 0 else 1      # vista quase de frente: o eixo de profundidade vai para o lado de fora, longe dos números do X
  px <- function(t) P(t, y_fr, 0); py <- function(t) P(x_fr, t, 0)
  eixo_aresta(px, tx, E$x$rot, titulos$x, nome = "x", S = SS$x); eixo_aresta(py, ty, E$y$rot, titulos$y, nome = "y", S = SS$y)
  # eixo Z: a aresta vertical que fica mais à esquerda na tela
  pz <- function(t) P(cantos$x[k], cantos$y[k], t * H)
  eixo_aresta(pz, tz / H, E$z$rot, titulos$z, u_fix = c(-1, 0), ang_fix = 90, nome = "z", S = SS$z)
  lin <- list(px(0), px(1), py(0), py(1), pz(0), pz(1))
  # aresta dos eixos (linha mais forte), traços, números e títulos: cada eixo com o seu estilo (cor, grossura, fonte, tamanho, negrito)
  ar <- function(p) { p0 <- p(0); p1 <- p(1); data.frame(x = p0$sx, y = p0$sy, xend = p1$sx, yend = p1$sy) }
  tk <- do.call(rbind, tks); rt <- do.call(rbind, rots); tt <- do.call(rbind, tits)
  dz <- .desencostar_rotulos3d(rt, tt, S, upi, larg_in); rt <- dz$rot; tt <- dz$tit            # números de eixos diferentes nunca ficam um sobre o outro
  arestas <- list(x = px, y = py, z = pz)
  for (eje in c("x", "y", "z")) {
    Sk <- SS[[eje]]
    if (isTRUE(Sk$mostrar_linha)) cam[[length(cam) + 1]] <- geom_segment(data = ar(arestas[[eje]]), aes(x = x, y = y, xend = xend, yend = yend), colour = Sk$cor_linha, linewidth = .lw(Sk$esp_linha), lineend = "round")
    tk_k <- if (!is.null(tk)) tk[tk$eix == eje & (tk$xend != tk$x | tk$yend != tk$y), , drop = FALSE]
    if (!is.null(tk_k) && nrow(tk_k)) cam[[length(cam) + 1]] <- geom_segment(data = tk_k, aes(x = x, y = y, xend = xend, yend = yend), colour = Sk$cor_linha, linewidth = .lw(Sk$esp_linha))
    rt_k <- if (!is.null(rt)) rt[rt$eix == eje & nzchar(rt$lab), , drop = FALSE]
    if (!is.null(rt_k) && nrow(rt_k)) cam[[length(cam) + 1]] <- geom_text(data = rt_k, aes(x = x, y = y, label = lab, angle = ang, hjust = hj), size = .tx(Sk$pt_rot), colour = Sk$cor_rot, family = Sk$fonte, fontface = Sk$face_rot)
    tt_k <- if (!is.null(tt)) tt[tt$eix == eje & nzchar(tt$lab), , drop = FALSE]
    if (!is.null(tt_k) && nrow(tt_k)) cam[[length(cam) + 1]] <- geom_text(data = tt_k, aes(x = x, y = y, label = lab, angle = ang), size = .tx(Sk$pt_tit), colour = Sk$cor_tit, family = Sk$fonte, fontface = Sk$face_tit)
  }
  rt <- if (!is.null(rt)) rt[nzchar(rt$lab), , drop = FALSE]; tt <- if (!is.null(tt)) tt[nzchar(tt$lab), , drop = FALSE]
  lin <- list(px(0), px(1), py(0), py(1), pz(0), pz(1))
  # caixa ocupada (centros dos textos mais metade do tamanho de cada um)
  caixa <- rbind(do.call(rbind, lapply(lin, function(p) c(p$sx, p$sy))),
                 if (!is.null(tk)) cbind(c(tk$x, tk$xend), c(tk$y, tk$yend)),
                 if (!is.null(rt) && nrow(rt)) { wl <- mapply(larg_in, rt$lab, rt$pt); lf <- rt$comp > 0                      # nomes em leque: do ponto até o fim do texto; senão, centrados
                   cbind(c(ifelse(lf, rt$x, rt$x - wl / 2 * upi), ifelse(lf, rt$xe, rt$x + wl / 2 * upi)), c(ifelse(lf, rt$y, rt$y - rt$pt / 144 * upi), ifelse(lf, rt$ye, rt$y + rt$pt / 144 * upi))) },
                 if (!is.null(tt) && nrow(tt)) { wt <- mapply(larg_in, tt$lab, tt$pt); cbind(c(tt$x - wt / 2 * upi, tt$x + wt / 2 * upi), c(tt$y - tt$pt / 72 * upi, tt$y + tt$pt / 72 * upi)) })
  list(camadas = cam, caixa = caixa)
}

# Monta o 3D inteiro: fundo (calculado duas vezes, para o tamanho dos textos acertar com o zoom real) + a camada de dados.
# dados3d(P, H) devolve as camadas de dados e os pontos projetados (para a caixa). Sai: list(camadas, xlim, ylim).
.montar3d <- function(cfg, E, titulos, dados3d) {
  T <- cfg$tridimensional; H <- T$altura_relativa; P <- .proj3d(T$azimute, T$elevacao, T$profundidade, T$perspectiva)
  dd <- dados3d(P, H)
  cb <- expand.grid(x = c(0, 1), y = c(0, 1), z = c(0, H)); pcb <- P(cb$x, cb$y, cb$z)
  corpo <- rbind(cbind(pcb$sx, pcb$sy), dd$caixa)
  pw_in <- (cfg$caixa$painel_largura_cm %||% 12) / 2.54
  upi <- diff(range(corpo[, 1])) / (pw_in * 0.7)
  for (k in 1:2) {
    fu <- .fundo3d(P, E, H, cfg, upi, titulos); cx <- rbind(corpo, fu$caixa)
    upi <- diff(range(cx[, 1])) / pw_in
  }
  fu <- .fundo3d(P, E, H, cfg, upi, titulos); cx <- rbind(corpo, fu$caixa)
  pad <- 0.04 * upi
  list(camadas = c(fu$camadas, dd$camadas), xlim = range(cx[, 1]) + c(-pad, pad), ylim = range(cx[, 2]) + c(-pad, pad))
}

# Camada invisível que só serve para a barra de cores aparecer quando as faces usam cor pronta (I()).
.camada_barra3d <- function(esc, x = 0, y = 0) geom_point(data = data.frame(x = x, y = y, z = esc$limites), aes(x = x, y = y, fill = z), shape = 21, alpha = 0, size = 0.1, inherit.aes = FALSE)

# ---- superfície 3D ------------------------------------------------------------------------------------
.construir_superficie_3d <- function(dados, cfg) {
  T <- cfg$tridimensional; H <- cfg$mapa_calor
  m0 <- .grade_xyz(dados, cfg); m <- .limitar_grade(.refinar_grade(m0, .n_suavizar(T$suavizar, m0, 70)))
  nx <- length(m$x); ny <- length(m$y)
  if (nx < 2 || ny < 2) .erro("A superfície precisa de pelo menos 2 valores em X e 2 em Y (a planilha tem ", nx, " x ", ny, ").")
  if (all(is.na(m$Z))) .erro("Não há valores numéricos de Z para desenhar.")
  E <- list(x = .eixo3d(cfg$eixo_x, m$x, !is.numeric(m$x)), y = .eixo3d(cfg$eixo_y, m$y, !is.numeric(m$y)), z = .eixo3d(.eixo_z(cfg), m$Z))
  Xn <- .n3(E$x, if (is.numeric(m$x)) m$x else seq_along(m$x)); Yn <- .n3(E$y, if (is.numeric(m$y)) m$y else seq_along(m$y))
  esc <- .escala_z(cfg, m$Z, m$nome_z %||% if (nzchar(m$nome_x)) .rot("Valor") else .rot("Valor"))
  titulos <- list(x = cfg$eixo_x$titulo %||% m$nome_x, y = cfg$eixo_y$titulo %||% m$nome_y, z = T$z_titulo %||% m$nome_z %||% .rot("Valor"))
  dados3d <- function(P, Hh) {
    Zn <- .n3(E$z, m$Z) * Hh; Zv <- m$Z
    ii <- rep(seq_len(ny - 1), times = nx - 1); jj <- rep(seq_len(nx - 1), each = ny - 1)
    cn <- function(di, dj) { i <- ii + di; j <- jj + dj; k <- cbind(i, j); list(x = Xn[j], y = Yn[i], z = Zn[k], v = Zv[k]) }
    cs <- list(cn(0, 0), cn(0, 1), cn(1, 1), cn(1, 0))
    ok <- is.finite(cs[[1]]$z + cs[[2]]$z + cs[[3]]$z + cs[[4]]$z)
    if (!any(ok)) .erro("Todas as células da grade têm algum Z vazio; não há superfície para desenhar.")
    pr <- lapply(cs, function(c) P(c$x[ok], c$y[ok], c$z[ok]))
    dep <- (pr[[1]]$d + pr[[2]]$d + pr[[3]]$d + pr[[4]]$d) / 4; zm <- (cs[[1]]$v[ok] + cs[[2]]$v[ok] + cs[[3]]$v[ok] + cs[[4]]$v[ok]) / 4
    o <- order(dep, decreasing = TRUE)
    cx <- cbind(pr[[1]]$sx, pr[[2]]$sx, pr[[3]]$sx, pr[[4]]$sx)[o, , drop = FALSE]; cy <- cbind(pr[[1]]$sy, pr[[2]]$sy, pr[[3]]$sy, pr[[4]]$sy)[o, , drop = FALSE]
    # luz: vem do alto, à esquerda de quem olha; a inclinação de cada face (a partir dos cantos) clareia ou escurece a cor
    ang <- T$azimute * pi / 180
    zx <- ((cs[[2]]$z - cs[[1]]$z) + (cs[[3]]$z - cs[[4]]$z))[ok] / 2 / pmax(cs[[2]]$x[ok] - cs[[1]]$x[ok], 1e-9)
    zy <- ((cs[[4]]$z - cs[[1]]$z) + (cs[[3]]$z - cs[[2]]$z))[ok] / 2 / pmax(cs[[4]]$y[ok] - cs[[1]]$y[ok], 1e-9)
    nxv <- -zx * cos(ang) + zy * sin(ang); nyv <- -zx * sin(ang) - zy * cos(ang); nzv <- 1
    nl <- sqrt(nxv^2 + nyv^2 + nzv^2); L <- c(-0.45, -0.55, 0.7); L <- L / sqrt(sum(L^2))
    luz <- (nxv * L[1] + nyv * L[2] + nzv * L[3]) / nl
    f <- if (isTRUE(T$sombreado %||% TRUE)) 0.62 + 0.62 * pmax(luz, 0) else rep(1, length(luz))
    cor <- .sombrear(esc$cor_de(zm), f)[o]
    tab <- .tabela_faces(cx, cy, list(cor = cor)); tab$cor <- I(tab$cor)
    borda <- if (isTRUE(T$malha)) list(colour = if (is.na(H$contorno_cor)) NA else .cor(H$contorno_cor), linewidth = .lw(H$contorno_espessura_pt)) else NULL
    cam <- list(.camada_barra3d(esc),
                if (is.null(borda)) geom_polygon(data = tab, aes(x = x, y = y, group = grp, fill = I(cor), colour = I(cor)), linewidth = .lw(0.35))
                else geom_polygon(data = tab, aes(x = x, y = y, group = grp, fill = I(cor)), colour = borda$colour, linewidth = borda$linewidth), esc$escala)
    list(camadas = cam, caixa = cbind(tab$x, tab$y))
  }
  r <- .montar3d(cfg, E, titulos, dados3d)
  list(camadas = r$camadas, info = list(mapa = TRUE, xlim = r$xlim, ylim = r$ylim, legenda_auto = TRUE, flip = FALSE, titulo_barra = esc$titulo))
}

# ---- barras 3D ----------------------------------------------------------------------------------------
.construir_barras_3d <- function(dados, cfg) {
  T <- cfg$tridimensional; H <- cfg$mapa_calor
  m <- .limitar_grade(.grade_xyz(dados, cfg), 20000)
  nx <- length(m$x); ny <- length(m$y)
  if (all(is.na(m$Z))) .erro("Não há valores numéricos de Z para desenhar.")
  px <- if (is.numeric(m$x)) m$x else seq_along(m$x); py <- if (is.numeric(m$y)) m$y else seq_along(m$y)
  passo <- function(v) if (length(v) > 1) min(diff(sort(v))) else 1
  E <- list(x = .eixo3d(cfg$eixo_x, m$x, !is.numeric(m$x), folga = passo(px) / 2), y = .eixo3d(cfg$eixo_y, m$y, !is.numeric(m$y), folga = passo(py) / 2),
            z = .eixo3d(.eixo_z(cfg), c(0, m$Z)))
  Xn <- .n3(E$x, px); Yn <- .n3(E$y, py); fr <- T$barras_largura %||% 0.7
  dx <- (if (nx > 1) passo(Xn) else 1) * fr / 2; dy <- (if (ny > 1) passo(Yn) else 1) * fr / 2
  esc <- .escala_z(cfg, m$Z, m$nome_z %||% .rot("Valor"))
  titulos <- list(x = cfg$eixo_x$titulo %||% m$nome_x, y = cfg$eixo_y$titulo %||% m$nome_y, z = T$z_titulo %||% m$nome_z %||% .rot("Valor"))
  dados3d <- function(P, Hh) {
    base <- min(max(0, E$z$lo), E$z$hi); zb0 <- (base - E$z$lo) / (E$z$hi - E$z$lo) * Hh
    ii <- rep(seq_len(ny), times = nx); jj <- rep(seq_len(nx), each = ny); v <- m$Z[cbind(ii, jj)]
    ok <- is.finite(v); ii <- ii[ok]; jj <- jj[ok]; v <- v[ok]; n <- length(v)
    zv <- .n3(E$z, v) * Hh; zt <- pmax(zv, zb0); zb <- pmin(zv, zb0)
    x0 <- Xn[jj] - dx; x1 <- Xn[jj] + dx; y0 <- Yn[ii] - dy; y1 <- Yn[ii] + dy
    a <- T$azimute * pi / 180; cor <- esc$cor_de(v)
    o <- order(P(Xn[jj], Yn[ii], (zt + zb) / 2)$d, decreasing = TRUE)      # do mais longe ao mais perto
    posicao <- integer(n); posicao[o] <- seq_len(n)
    cara <- function(xs, ys, zs, cores, sub) {
      pp <- lapply(1:4, function(q) P(xs[[q]], ys[[q]], zs[[q]]))
      data.frame(x = as.vector(rbind(pp[[1]]$sx, pp[[2]]$sx, pp[[3]]$sx, pp[[4]]$sx)), y = as.vector(rbind(pp[[1]]$sy, pp[[2]]$sy, pp[[3]]$sy, pp[[4]]$sy)),
                 caixa = rep(posicao, each = 4), sub = sub, cor = rep(cores, each = 4), stringsAsFactors = FALSE)
    }
    lat <- list(list(n = c(-1, 0), xs = list(x0, x0, x0, x0), ys = list(y0, y1, y1, y0)), list(n = c(1, 0), xs = list(x1, x1, x1, x1), ys = list(y0, y1, y1, y0)),
                list(n = c(0, -1), xs = list(x0, x1, x1, x0), ys = list(y0, y0, y0, y0)), list(n = c(0, 1), xs = list(x0, x1, x1, x0), ys = list(y1, y1, y1, y1)))
    partes <- list(); k <- 0L
    for (l in lat) if (l$n[1] * sin(a) + l$n[2] * cos(a) < -1e-9) {                 # só os lados virados para quem olha
      k <- k + 1L; sh <- 0.8 - 0.14 * (l$n[1] * cos(a) - l$n[2] * sin(a))
      partes[[k]] <- cara(l$xs, l$ys, list(zb, zb, zt, zt), .escurecer(cor, sh), k)
    }
    partes[[k + 1L]] <- cara(list(x0, x1, x1, x0), list(y0, y0, y1, y1), list(zt, zt, zt, zt), cor, k + 1L)
    tab <- do.call(rbind, partes); tab <- tab[order(tab$caixa, tab$sub), ]
    tab$grp <- cumsum(c(TRUE, diff(tab$caixa) != 0 | diff(tab$sub) != 0))
    tab$cor <- I(tab$cor)
    cam <- list(.camada_barra3d(esc), geom_polygon(data = tab, aes(x = x, y = y, group = grp, fill = I(cor)), colour = if (is.na(T$cor_borda_barras)) NA else .cor(T$cor_borda_barras), linewidth = .lw(0.25)), esc$escala)
    list(camadas = cam, caixa = cbind(tab$x, tab$y))
  }
  r <- .montar3d(cfg, E, titulos, dados3d)
  list(camadas = r$camadas, info = list(mapa = TRUE, xlim = r$xlim, ylim = r$ylim, legenda_auto = TRUE, flip = FALSE, titulo_barra = esc$titulo))
}

# ---- dispersão 3D -------------------------------------------------------------------------------------
.construir_dispersao_3d <- function(dados, cfg) {
  T <- cfg$tridimensional; p <- .pontos_xyz(dados, cfg); d <- p$d
  if (nrow(d) < 1) .erro("Não há pontos com X, Y e Z numéricos para desenhar.")
  E <- list(x = .eixo3d(cfg$eixo_x, d$x), y = .eixo3d(cfg$eixo_y, d$y), z = .eixo3d(.eixo_z(cfg), c(d$z, if (isTRUE(T$hastes)) 0)))
  esc <- .escala_z(cfg, d$z, p$nome_z %||% .rot("Valor"))
  titulos <- list(x = cfg$eixo_x$titulo %||% p$nome_x, y = cfg$eixo_y$titulo %||% p$nome_y, z = T$z_titulo %||% p$nome_z %||% .rot("Valor"))
  dados3d <- function(P, Hh) {
    xn <- .n3(E$x, d$x); yn <- .n3(E$y, d$y); zn <- .n3(E$z, d$z) * Hh
    pr <- P(xn, yn, zn); o <- order(pr$d, decreasing = TRUE)
    pts <- data.frame(x = pr$sx[o], y = pr$sy[o], z = d$z[o]); cam <- list()
    if (isTRUE(T$hastes)) {
      base <- min(max(0, E$z$lo), E$z$hi); zb <- (base - E$z$lo) / (E$z$hi - E$z$lo) * Hh; pb <- P(xn[o], yn[o], zb)
      cam[[1]] <- geom_segment(data = data.frame(x = pr$sx[o], y = pr$sy[o], xend = pb$sx, yend = pb$sy), aes(x = x, y = y, xend = xend, yend = yend), colour = .cor(T$cor_hastes), linewidth = .lw(0.4))
    }
    tam <- T$ponto_tamanho_pt %||% 6
    cam <- c(cam, list(geom_point(data = pts, aes(x = x, y = y, fill = z), shape = 21, size = .tx(tam), stroke = .lw(0.3),
                                   colour = if (is.na(T$cor_borda_pontos)) NA else .cor(T$cor_borda_pontos)), esc$escala))
    list(camadas = cam, caixa = cbind(c(pts$x, if (isTRUE(T$hastes)) pb$sx), c(pts$y, if (isTRUE(T$hastes)) pb$sy)))
  }
  r <- .montar3d(cfg, E, titulos, dados3d)
  list(camadas = r$camadas, info = list(mapa = TRUE, xlim = r$xlim, ylim = r$ylim, legenda_auto = TRUE, flip = FALSE, titulo_barra = esc$titulo))
}

# ---- mapa de cor (X, Y, Z): plano, com eixos numéricos de verdade ------------------------------------------------------
.construir_mapa_cor <- function(dados, cfg) {
  T <- cfg$tridimensional; H <- cfg$mapa_calor
  m0 <- .grade_xyz(dados, cfg)
  if (!is.numeric(m0$x) || !is.numeric(m0$y)) .erro("O mapa de cor precisa de números nos dois eixos (a 1ª coluna e os cabeçalhos). Para nomes (genes, amostras...), use o mapa de calor.")
  if (length(m0$x) < 2 || length(m0$y) < 2) .erro("O mapa de cor precisa de pelo menos 2 valores em X e 2 em Y.")
  faixas <- !is.null(H$niveis_cor) && is.finite(H$niveis_cor) && H$niveis_cor >= 2
  ns <- .n_suavizar(T$suavizar, m0, if (faixas) 360 else 240, maximo = 64)      # grade fina: a cor sai contínua (com faixas, as bordas das faixas saem nítidas)
  while (ns > 1 && (length(m0$x) - 1) * ns * (length(m0$y) - 1) * ns > 250000) ns <- ns - 1L
  m <- if (ns > 1) .refinar_grade(m0, ns) else .limitar_grade(m0)
  bordas <- function(v) { mid <- (v[-1] + v[-length(v)]) / 2
    if (ns > 1) c(v[1], mid, v[length(v)]) else c(v[1] - (v[2] - v[1]) / 2, mid, v[length(v)] + (v[length(v)] - v[length(v) - 1]) / 2) }
  bx <- bordas(m$x); by <- bordas(m$y); nx <- length(m$x); ny <- length(m$y)
  ex <- 0.01 * min(diff(bx)); ey <- 0.01 * min(diff(by))       # as células se sobrepõem um pouco: sem fios claros entre elas
  d <- data.frame(xmin = rep(bx[-(nx + 1)], each = ny) - ex, xmax = rep(bx[-1], each = ny) + ex, ymin = rep(by[-(ny + 1)], times = nx) - ey, ymax = rep(by[-1], times = nx) + ey, z = as.vector(m$Z),
                  x = rep(m$x, each = ny), y = rep(m$y, times = nx))
  d$xmin[d$xmin < min(bx)] <- min(bx); d$xmax[d$xmax > max(bx)] <- max(bx); d$ymin[d$ymin < min(by)] <- min(by); d$ymax[d$ymax > max(by)] <- max(by)
  esc <- .escala_z(cfg, d$z, m$nome_z %||% .rot("Valor"))
  if (ns > 1) {          # imagem contínua (um pixel por ponto da grade fina, suavizada pelo desenho): sem quadradinhos nem fios
    R <- matrix(esc$cor_de(as.vector(m$Z)), ny, nx)[ny:1, , drop = FALSE]
    cam <- list(.camada_barra3d(esc, mean(range(bx)), mean(range(by))),
                annotation_raster(R, xmin = min(bx), xmax = max(bx), ymin = min(by), ymax = max(by), interpolate = !faixas), esc$escala)
  } else cam <- list(geom_rect(data = d, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = z, colour = z), linewidth = .lw(0.3), na.rm = FALSE), esc$escala, esc$escala_cor)
  nn <- T$niveis %||% 0
  if (nn > 0 && !anyNA(m$Z)) {
    lim <- esc$limites; qb <- pretty(lim, n = nn + 1); qb <- qb[qb > lim[1] & qb < lim[2]]
    cam[[length(cam) + 1]] <- tryCatch(geom_contour(data = d, aes(x = x, y = y, z = z), breaks = qb, colour = .cor(T$cor_niveis), linewidth = .lw(T$niveis_espessura_pt %||% 0.4), inherit.aes = FALSE),
                                        error = function(e) { .aviso("Não consegui traçar as linhas de nível: ", conditionMessage(e)); NULL })
    cam <- Filter(Negate(is.null), cam)
  }
  lim_x <- if (is.null(cfg$eixo_x$inicio) && is.null(cfg$eixo_x$fim)) range(bx) else NULL       # o eixo acompanha a cor (sem margem), a não ser que você escolha início e fim
  lim_y <- if (is.null(cfg$eixo_y$inicio) && is.null(cfg$eixo_y$fim)) range(by) else NULL
  ax_x <- .calc_eixo(cfg$eixo_x, range(bx), forcar = cfg$.interno$forcar_x %||% lim_x)
  ax_y <- .calc_eixo(cfg$eixo_y, range(by), forcar = cfg$.interno$forcar_y %||% lim_y)
  list(camadas = cam,
       info = list(ax_x = ax_x, ax_y = ax_y, flip = FALSE, titulo_x = cfg$eixo_x$titulo %||% m$nome_x, titulo_y = cfg$eixo_y$titulo %||% m$nome_y,
                   legenda_auto = TRUE, faixa_x = range(bx), faixa_y = range(by), titulo_barra = esc$titulo, alinhar_cantos = TRUE))
}

# ---- linhas 3D (cascata) -------------------------------------------------------------------------------
# Planilha: a 1ª coluna é o X (número); cada outra coluna é uma linha (uma série) e o cabeçalho dela diz onde fica na profundidade (Y): um número (tempo, dose...)
# ou um nome. Entra: dados e cfg. Sai: list(x, Z (linhas = X, colunas = séries), y (posição de cada série), ynomes, ycat, nome_x).
.series_xyz <- function(dados, cfg) {
  G <- cfg$grafico
  xcol <- .coluna(dados, G$coluna_x %||% 1, "cfg$grafico$coluna_x")
  if (!is.numeric(dados[[xcol]])) .erro("As linhas 3D precisam de números na coluna do eixo X ('", xcol, "'), por exemplo o comprimento de onda.")
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  if (length(ycols) < 2) .erro("As linhas 3D precisam de pelo menos 2 colunas de série: cada coluna é uma linha e o cabeçalho dela diz onde fica na profundidade (um número, como o tempo, ou um nome).")
  hy <- .tri_num(ycols); ycat <- !all(is.finite(hy))
  x <- dados[[xcol]]; o <- order(x); o <- o[is.finite(x[o])]
  Z <- as.matrix(dados[ycols])[o, , drop = FALSE]; storage.mode(Z) <- "double"; x <- x[o]
  if (!ycat) { oy <- order(hy); ycols <- ycols[oy]; hy <- hy[oy]; Z <- Z[, oy, drop = FALSE] }
  list(x = x, Z = unname(Z), y = if (ycat) seq_along(ycols) else hy, ynomes = ycols, ycat = ycat, nome_x = xcol)
}

.construir_linhas_3d <- function(dados, cfg) {
  T <- cfg$tridimensional; H <- cfg$mapa_calor
  s <- .series_xyz(dados, cfg)
  if (ncol(s$Z) > (if (.modo_rapido()) 40 else 80)) { k <- unique(round(seq(1, ncol(s$Z), length.out = if (.modo_rapido()) 40 else 80))); .aviso("A tabela tem ", ncol(s$Z), " séries; para o desenho não ficar pesado, usei 80 delas."); s$Z <- s$Z[, k, drop = FALSE]; s$y <- s$y[k]; s$ynomes <- s$ynomes[k] }
  if (length(s$x) > 300) { k <- unique(round(seq(1, length(s$x), length.out = 300))); s$x <- s$x[k]; s$Z <- s$Z[k, , drop = FALSE] }
  ns <- ncol(s$Z); if (all(is.na(s$Z))) .erro("Não há valores numéricos de Z para desenhar.")
  E <- list(x = .eixo3d(cfg$eixo_x, s$x), y = .eixo3d(cfg$eixo_y, if (s$ycat) s$ynomes else s$y, s$ycat), z = .eixo3d(.eixo_z(cfg), c(0, s$Z)))
  Xn <- .n3(E$x, s$x); Yn <- .n3(E$y, if (s$ycat) seq_len(ns) else s$y)
  esc <- .escala_z(cfg, s$Z, .rot("Valor"))
  titulos <- list(x = cfg$eixo_x$titulo %||% s$nome_x, y = cfg$eixo_y$titulo %||% "", z = T$z_titulo %||% .rot("Valor"))
  modo <- T$linhas_preencher %||% "gradiente"; B <- max(1L, as.integer(T$linhas_faixas %||% 10)); if (.modo_rapido()) B <- min(B, 10L)
  dados3d <- function(P, Hh) {
    base <- min(max(0, E$z$lo), E$z$hi); zb0 <- (base - E$z$lo) / (E$z$hi - E$z$lo) * Hh
    zn <- .n3(E$z, s$Z) * Hh; zn[!is.finite(zn)] <- zb0; zn <- pmax(zn, zb0)
    ordem <- order(P(0.5, Yn, 0)$d, decreasing = TRUE)                       # da série mais longe para a mais perto
    niv <- seq(zb0, Hh, length.out = B + 1); niv_dado <- E$z$lo + niv / Hh * (E$z$hi - E$z$lo)
    cam <- list(.camada_barra3d(esc)); pts <- matrix(numeric(0), 0, 2)
    for (j in ordem) {
      zc <- zn[, j]; tab <- NULL
      if (identical(modo, "gradiente")) {
        partes <- list(); g <- 0L
        for (b in seq_len(B)) {
          ativo <- which(zc > niv[b] + 1e-9); if (!length(ativo)) next
          i0 <- max(1L, min(ativo) - 1L); i1 <- min(length(zc), max(ativo) + 1L); xs <- Xn[i0:i1]; zs <- zc[i0:i1]      # só o trecho da linha que passa deste nível (menos pontos)
          topo <- pmin(zs, niv[b + 1]); fundo <- pmin(zs, niv[b])
          if (max(topo - fundo) <= 1e-9) next
          p <- P(c(xs, rev(xs)), Yn[j], c(topo, rev(fundo))); g <- g + 1L
          partes[[g]] <- data.frame(x = p$sx, y = p$sy, grp = g, cor = esc$cor_de((niv_dado[b] + niv_dado[b + 1]) / 2))
        }
        if (length(partes)) tab <- do.call(rbind, partes)
      } else if (identical(modo, "branco")) {
        p <- P(c(Xn, rev(Xn)), Yn[j], c(zc, rep(zb0, length(Xn)))); tab <- data.frame(x = p$sx, y = p$sy, grp = 1L, cor = "white")
      }
      if (!is.null(tab)) { tab$cor <- I(tab$cor); cam[[length(cam) + 1]] <- geom_polygon(data = tab, aes(x = x, y = y, group = grp, fill = I(cor), colour = I(cor)), linewidth = .lw(0.3)) }
      pl <- P(Xn, Yn[j], zc); linha <- data.frame(x = pl$sx, y = pl$sy)
      cam[[length(cam) + 1]] <- geom_path(data = linha, aes(x = x, y = y), colour = .cor(T$linhas_cor %||% "black"), linewidth = .lw(T$linhas_espessura_pt %||% 0.4), lineend = "round")
      pts <- rbind(pts, cbind(pl$sx, pl$sy))
    }
    list(camadas = c(cam, list(esc$escala)), caixa = pts)
  }
  r <- .montar3d(cfg, E, titulos, dados3d)
  list(camadas = r$camadas, info = list(mapa = TRUE, xlim = r$xlim, ylim = r$ylim, legenda_auto = TRUE, flip = FALSE, titulo_barra = esc$titulo))
}
