# =============================================================================
#  R/24_tipo_multivariada.R — PCA, CA e CCA (biplots)
# =============================================================================
#  Usa o pacote vegan (rda para o PCA, cca para o CA e o CCA). A planilha tem uma linha por amostra; as colunas são
#  divididas em variáveis (matriz principal) e ambientais (cfg$multivariada). Veja cfg$multivariada no 01_config.R.
# =============================================================================

# Tabela que o app e o motor usam para dizer como cada coluna foi tratada. Entra: dados e cfg. Sai: list(x, grupo, variaveis, ambientais).
.colunas_multivariada <- function(dados, cfg) {
  M <- cfg$multivariada; G <- cfg$grafico
  nome <- function(refs, onde) if (is.null(refs)) NULL else unname(vapply(refs, function(r) .coluna(dados, r, onde), ""))
  xcol <- if (is.null(G$coluna_x)) NULL else .coluna(dados, G$coluna_x, "cfg$grafico$coluna_x")
  gcol <- nome(G$coluna_grupo, "cfg$grafico$coluna_grupo")
  amb <- nome(M$ambientais, "cfg$multivariada$ambientais")
  vars <- nome(M$variaveis %||% G$colunas_y, "cfg$multivariada$variaveis")
  if (is.null(vars)) {
    numericas <- names(dados)[vapply(dados, is.numeric, NA)]
    vars <- setdiff(numericas, c(xcol, gcol, amb))
  }
  vars <- setdiff(vars, c(xcol, gcol, amb))
  if (length(vars) < 2) .erro("PCA/CA/CCA precisam de pelo menos 2 variáveis numéricas (colunas). Defina cfg$multivariada$variaveis.")
  nao_num <- c(vars, amb)[!vapply(dados[c(vars, amb)], is.numeric, NA)]
  if (length(nao_num)) .erro("A(s) coluna(s) ", paste0("'", nao_num, "'", collapse = ", "), " não é(são) numérica(s). ",
                             "Se o arquivo usa vírgula decimal, veja cfg$dados$decimal_virgula.")
  list(x = xcol, grupo = gcol, variaveis = vars, ambientais = amb)
}

# Transformações da matriz de variáveis antes da ordenação.
.transformar_matriz <- function(X, modo) {
  if (modo %in% c("log1p", "raiz", "hellinger") && any(X < 0, na.rm = TRUE))
    .erro("A transformação \"", modo, "\" não aceita valores negativos (há ", sum(X < 0, na.rm = TRUE), " na matriz).")
  switch(modo,
    nenhuma = X,
    padronizar = { v <- apply(X, 2, stats::sd); X[, v > 0] <- scale(X[, v > 0, drop = FALSE]); X },
    log1p = log1p(X),
    raiz = sqrt(X),
    hellinger = { rs <- rowSums(X); rs[rs == 0] <- NA; sqrt(X / rs) })
}

# Pontos de uma elipse por grupo. tipo "dados": contém a fração `nivel` dos pontos; "confianca": elipse de confiança da média.
.elipse_grupo <- function(xy, tipo, nivel) {
  n <- nrow(xy); if (n < 4) return(NULL)
  mu <- colMeans(xy); S <- stats::cov(xy)
  if (any(!is.finite(S)) || abs(det(S)) < 1e-12) return(NULL)
  r <- if (tipo == "dados") sqrt(stats::qchisq(nivel, 2)) else sqrt(2 * stats::qf(nivel, 2, n - 2) / n)
  th <- seq(0, 2 * pi, length.out = 101)
  L <- t(chol(S))
  t(mu + r * (L %*% rbind(cos(th), sin(th))))
}

# Calcula a ordenação. Entra: dados e cfg. Sai: lista com coordenadas das amostras, variáveis e ambientais, e a variância explicada.
.ordenacao <- function(dados, cfg) {
  if (!.tem("vegan")) .erro("PCA, CA e CCA precisam do pacote vegan. Instale com install.packages(\"vegan\") (ou rode o 00_instalar_pacotes.R).")
  M <- cfg$multivariada; tipo <- cfg$grafico$tipo
  col <- .colunas_multivariada(dados, cfg)
  if (tipo == "cca" && !length(col$ambientais))
    .erro("CCA precisa das variáveis ambientais: escolha as colunas em \"Variáveis ambientais\" (no código: cfg$multivariada$ambientais). Elas podem estar na mesma planilha.")
  usar <- c(col$variaveis, col$ambientais)
  completo <- stats::complete.cases(dados[usar])
  if (!all(completo)) .aviso(sum(!completo), " amostra(s) com valor vazio em variáveis/ambientais foram ignoradas na ordenação.")
  d <- dados[completo, , drop = FALSE]
  X <- as.matrix(d[col$variaveis]); storage.mode(X) <- "double"
  X <- .transformar_matriz(X, M$transformacao %||% "nenhuma")
  rotulos <- if (!is.null(col$x)) as.character(d[[col$x]]) else as.character(seq_len(nrow(d)))
  grupo <- if (!is.null(col$grupo)) as.character(d[[col$grupo]]) else NULL
  ok <- stats::complete.cases(X)
  if (!all(ok)) { .aviso(sum(!ok), " amostra(s) ficaram sem valor após a transformação e foram ignoradas."); X <- X[ok, , drop = FALSE]
                  d <- d[ok, , drop = FALSE]; rotulos <- rotulos[ok]; grupo <- grupo[ok] }
  if (nrow(X) < 4) .erro("A ordenação precisa de pelo menos 4 amostras (linhas); há ", nrow(X), ".")
  constante <- apply(X, 2, stats::sd) == 0
  if (any(constante) && tipo == "pca") { .aviso("Variável(is) sem variação foram ignoradas: ", paste(colnames(X)[constante], collapse = ", ")); X <- X[, !constante, drop = FALSE] }
  if (tipo %in% c("ca", "cca")) {
    if (any(X < 0)) .erro("CA e CCA exigem valores >= 0 (contagens, abundâncias). Há valores negativos na matriz; use o PCA, ou outra transformação.")
    zero <- rowSums(X) == 0
    if (any(zero)) { .aviso(sum(zero), " amostra(s) com soma zero foram ignoradas (o CA/CCA não as aceita)."); X <- X[!zero, , drop = FALSE]
                     d <- d[!zero, , drop = FALSE]; rotulos <- rotulos[!zero]; grupo <- grupo[!zero] }
    colzero <- colSums(X) == 0
    if (any(colzero)) X <- X[, !colzero, drop = FALSE]
  }
  if (ncol(X) < 2) .erro("Sobraram menos de 2 variáveis com variação; confira as colunas escolhidas.")
  E <- if (length(col$ambientais)) as.data.frame(d[col$ambientais]) else NULL
  ord <- suppressWarnings(switch(tipo,
    pca = vegan::rda(X, scale = isTRUE(M$escalar_variaveis)),
    ca = vegan::cca(X),
    cca = vegan::cca(X, E)))
  ev <- vegan::eigenvals(ord); prop <- ev / sum(ev)
  ch <- c(M$eixo_horizontal %||% 1, M$eixo_vertical %||% 2)
  if (ch[1] == ch[2]) .erro("cfg$multivariada: eixo_horizontal e eixo_vertical não podem ser o mesmo eixo.")
  if (max(ch) > length(ev)) .erro("A ordenação só tem ", length(ev), " eixo(s); pedi os eixos ", ch[1], " e ", ch[2], " (cfg$multivariada$eixo_horizontal/eixo_vertical).")
  esc <- switch(M$escalonamento %||% "auto", amostras = 1, variaveis = 2, simetrica = 3, auto = if (tipo == "pca") 2 else 3)
  pega <- function(...) tryCatch(suppressWarnings(vegan::scores(ord, choices = ch, scaling = esc, ...)), error = function(e) NULL)
  sc_sites <- pega(display = "sites"); sc_vars <- pega(display = "species")
  nomes_eixos <- colnames(sc_sites)
  amb <- NULL
  if (tipo == "cca") {
    amb <- pega(display = "bp")
  } else if (length(col$ambientais)) {
    numE <- E[vapply(E, is.numeric, NA)]
    ef <- tryCatch(suppressWarnings(vegan::envfit(ord, numE, choices = ch, scaling = esc, permutations = 0)), error = function(e) NULL)
    if (!is.null(ef) && !is.null(ef$vectors)) {
      amb <- ef$vectors$arrows * sqrt(ef$vectors$r)
      colnames(amb) <- nomes_eixos
    }
  }
  list(tipo = tipo, sites = as.matrix(sc_sites), vars = as.matrix(sc_vars), amb = if (!is.null(amb)) as.matrix(amb), rotulos = rotulos,
       grupo = grupo, eixos = nomes_eixos, prop = as.numeric(prop[ch]), escalonamento = esc,
       resumo = list(prop_total = as.numeric(prop), eixos_total = names(ev), n = nrow(X), n_vars = ncol(X),
                     restrita = if (tipo == "cca") ord$CCA$tot.chi / ord$tot.chi else NA_real_))
}

# ---- posicionamento dos nomes (rótulos) ----------------------------------------------------------------------------------------
# Mede textos (largura e altura em polegadas) com a mesma fonte do arquivo final. Entra: textos, tamanho (pt), fonte e estilo.
.medir_textos <- function(txt, tam_pt, fonte, face = "plain") {
  dev_ant <- grDevices::dev.cur(); dn <- .abrir_dispositivo_tmp()
  on.exit({ if (dn %in% grDevices::dev.list()) grDevices::dev.off(dn); if (dev_ant %in% grDevices::dev.list()) grDevices::dev.set(dev_ant) })
  gp <- grid::gpar(fontsize = tam_pt, fontfamily = fonte, fontface = face, lineheight = 0.95)
  w <- vapply(txt, function(t) grid::convertWidth(grid::grobWidth(grid::textGrob(t, gp = gp)), "in", valueOnly = TRUE), 0)
  h <- vapply(txt, function(t) grid::convertHeight(grid::grobHeight(grid::textGrob(t, gp = gp)), "in", valueOnly = TRUE), 0)
  list(w = unname(w) + 0.02, h = unname(h) + 0.03)
}

# "Nome=x,y; Nome2=x,y" (ou lista nomeada) -> lista nome -> c(x, y).
.ler_posicoes <- function(p) {
  if (is.null(p) || (is.character(p) && !nzchar(trimws(paste(p, collapse = ""))))) return(list())
  if (is.list(p)) return(lapply(p, as.numeric))
  partes <- trimws(strsplit(paste(p, collapse = ";"), ";", fixed = TRUE)[[1]]); partes <- partes[nzchar(partes)]
  out <- list()
  for (z in partes) {
    k <- regexpr("=[^=]*$", z); if (k < 0) next
    nome <- trimws(substr(z, 1, k - 1)); v <- suppressWarnings(as.numeric(strsplit(gsub(",", ".", substr(z, k + 1, nchar(z))), "[ ;]+")[[1]]))
    # "x,y": a vírgula separa x de y (o ponto é o decimal)
    xy <- suppressWarnings(as.numeric(strsplit(substr(z, k + 1, nchar(z)), ",", fixed = TRUE)[[1]]))
    if (length(xy) == 2 && !anyNA(xy)) out[[nome]] <- xy
  }
  out
}

# Escolhe onde cada nome fica: ao lado do seu ponto/seta, sem cobrir pontos, pontas de seta, outros nomes, e dentro do painel.
# Entra: anc (data.frame x, y em unidades dos dados), w e h (polegadas), sx e sy (polegadas por unidade), lim = c(x0, x1, y0, y1),
# obst (data.frame x, y, r_in dos pontos a desviar), pref (ângulo preferido, radianos), fixas (lista: NULL ou c(x, y) = centro à mão).
# A ordem das linhas de 'anc' é a prioridade (os primeiros escolhem primeiro). Sai: data.frame(x, y, longe) com o CENTRO de cada nome.
.posicionar_rotulos <- function(anc, w, h, sx, sy, lim, obst = NULL, pref = NULL, fixas = NULL, raio_ancora = 0.05, centro = FALSE) {
  n <- nrow(anc); if (!n) return(data.frame(x = numeric(0), y = numeric(0), longe = logical(0)))
  ax <- anc$x * sx; ay <- anc$y * sy
  caixa <- c(lim[1] * sx, lim[2] * sx, lim[3] * sy, lim[4] * sy)
  ox <- c(if (!is.null(obst)) obst$x * sx, ax); oy <- c(if (!is.null(obst)) obst$y * sy, ay)
  orad <- c(if (!is.null(obst)) obst$r_in, rep(0.035, n)); dono <- c(rep(0L, if (is.null(obst)) 0 else nrow(obst)), seq_len(n))
  pref <- pref %||% rep(pi / 4, n); pref[is.na(pref)] <- pi / 4
  cx <- cy <- rep(NA_real_, n)
  for (i in seq_len(n)) if (!is.null(fixas[[i]]) && !anyNA(fixas[[i]])) { cx[i] <- fixas[[i]][1] * sx; cy[i] <- fixas[[i]][2] * sy }
  fixo <- !is.na(cx)
  sobre <- function(x1, x2, y1, y2, X1, X2, Y1, Y2) pmax(0, pmin(x2, X2) - pmax(x1, X1)) * pmax(0, pmin(y2, Y2) - pmax(y1, Y1))
  custo <- function(i, px, py, a, r) {
    x1 <- px - w[i] / 2; x2 <- px + w[i] / 2; y1 <- py - h[i] / 2; y2 <- py + h[i] / 2
    fora <- w[i] * h[i] - sobre(x1, x2, y1, y2, caixa[1], caixa[2], caixa[3], caixa[4])
    ok <- which(!is.na(cx) & seq_len(n) != i)
    lab <- if (length(ok)) sum(sobre(x1, x2, y1, y2, cx[ok] - w[ok] / 2, cx[ok] + w[ok] / 2, cy[ok] - h[ok] / 2, cy[ok] + h[ok] / 2)) else 0
    o <- which(dono != i)
    pt <- if (length(o)) sum(sobre(x1, x2, y1, y2, ox[o] - orad[o], ox[o] + orad[o], oy[o] - orad[o], oy[o] + orad[o])) else 0
    dang <- abs(atan2(sin(a - pref[i]), cos(a - pref[i])))
    fora * 5000 + lab * 1500 + pt * 400 + r * 3 + dang * 0.04
  }
  angulos <- (0:11) * pi / 6; raios <- c(0.01, 0.05, 0.10, 0.18, 0.28, 0.40)
  escolhe <- function(i) {
    melhor <- Inf; bx <- by <- NA
    if (centro) { cst <- custo(i, ax[i], ay[i], pref[i], 0); melhor <- cst - 0.5; bx <- ax[i]; by <- ay[i] }       # nos mapas: o nome fica em cima do local, se couber
    for (a0 in angulos) { a <- pref[i] + a0
      for (r in raios) {
        dx <- cos(a); dy <- sin(a); ext <- 0.5 * (abs(dx) * w[i] + abs(dy) * h[i])
        px <- ax[i] + dx * (raio_ancora + r + ext); py <- ay[i] + dy * (raio_ancora + r + ext)
        cst <- custo(i, px, py, a, r)
        if (cst < melhor) { melhor <- cst; bx <- px; by <- py }
      } }
    c(bx, by)
  }
  for (i in which(!fixo)) { p <- escolhe(i); cx[i] <- p[1]; cy[i] <- p[2] }
  for (volta in 1:2) for (i in which(!fixo)) { cx[i] <- NA; p <- escolhe(i); cx[i] <- p[1]; cy[i] <- p[2] }   # refina: cada um reconsidera com os outros no lugar
  dist <- pmax(0, sqrt((cx - ax)^2 + (cy - ay)^2) - 0.5 * (w + h) / 2)
  if (centro) dist <- pmax(0, sqrt((cx - ax)^2 + (cy - ay)^2) - 0.5 * pmax(w, h))
  data.frame(x = cx / sx, y = cy / sy, longe = dist > 0.12)
}

# Fio de ligação entre o ponto (ax, ay) e a borda do nome (centro cx, cy; largura w, altura h) — em unidades dos dados via sx, sy.
.fios_rotulos <- function(anc, pos, w, h, sx, sy) {
  if (!any(pos$longe)) return(NULL)
  d <- do.call(rbind, lapply(which(pos$longe), function(i) {
    ux <- (anc$x[i] - pos$x[i]) * sx; uy <- (anc$y[i] - pos$y[i]) * sy; n <- sqrt(ux^2 + uy^2); if (n == 0) return(NULL)
    t <- min((w[i] / 2 + 0.01) / max(abs(ux), 1e-9), (h[i] / 2 + 0.01) / max(abs(uy), 1e-9))        # sai da borda do retângulo do nome
    data.frame(x = pos$x[i] + ux * t / sx, y = pos$y[i] + uy * t / sy, xend = anc$x[i], yend = anc$y[i])
  }))
  d
}

# Estilo de texto de um tipo de nome (amostras, variaveis, ambientais): fonte, tamanho, face e cor.
.estilo_texto_mv <- function(cfg, tipo, cor_padrao) {
  M <- cfg$multivariada; g <- function(k) M[[paste0(tipo, "_", k)]]
  neg <- .neg(cfg, g("negrito")); ita <- isTRUE(g("italico"))
  list(fonte = .fonte(g("fonte") %||% cfg$texto$fonte), pt = g("tamanho_pt") %||% cfg$texto$tamanho_base_pt * 0.85,
       face = if (neg && ita) "bold.italic" else if (neg) "bold" else if (ita) "italic" else "plain",
       cor = .cor(g("cor") %||% cor_padrao, paste0("cfg$multivariada$", tipo, "_cor")))
}

# Biplot de PCA, CA e CCA. Entra: dados e cfg. Sai: list(camadas, info).
.construir_multivariada <- function(dados, cfg) {
  M <- cfg$multivariada; tipo <- cfg$grafico$tipo
  o <- .ordenacao(dados, cfg)
  S <- as.data.frame(o$sites); names(S) <- c("x", "y"); S$rot <- o$rotulos
  grupos <- if (!is.null(o$grupo)) { ordem <- cfg$grafico$ordem_itens; g <- unique(o$grupo[!is.na(o$grupo)])
                                       if (!is.null(ordem)) c(intersect(ordem, g), setdiff(g, ordem)) else g } else "Amostras"
  S$serie <- factor(if (is.null(o$grupo)) "Amostras" else o$grupo, levels = grupos)
  est <- .estilos(cfg, grupos)
  for (i in names(est)) if (isTRUE(est[[i]]$simbolo == .COD_ESFERA)) est[[i]]$simbolo <- 21
  mul <- function(v) {                                              # setas esticadas para caber na nuvem de amostras
    if (!isTRUE(M$ajustar_setas) || !nrow(v)) return(1)
    lim <- apply(abs(o$sites), 2, max); mx <- apply(abs(v), 2, max); mx[mx == 0] <- 1e-9
    0.9 * min(lim / mx)
  }
  # variáveis e ambientais (coordenadas finais)
  V <- NULL; estilo_v <- NULL
  if (isTRUE(M$mostrar_variaveis) && !is.null(o$vars)) {
    V <- as.data.frame(o$vars); names(V) <- c("x", "y"); V$rot <- rownames(o$vars)
    if (!is.null(M$max_variaveis) && nrow(V) > M$max_variaveis) V <- V[order(-(V$x^2 + V$y^2))[seq_len(M$max_variaveis)], , drop = FALSE]
    estilo_v <- if (identical(M$variaveis_estilo, "auto") || is.null(M$variaveis_estilo)) (if (tipo == "pca") "setas" else "pontos") else M$variaveis_estilo
    if (estilo_v == "setas") { k <- mul(as.matrix(V[c("x", "y")])); V$x <- V$x * k; V$y <- V$y * k }
  }
  A <- NULL
  if (isTRUE(M$mostrar_ambientais) && !is.null(o$amb)) {
    A <- as.data.frame(o$amb); names(A) <- c("x", "y"); A$rot <- rownames(o$amb)
    k <- mul(as.matrix(A[c("x", "y")])); A$x <- A$x * k; A$y <- A$y * k
  }
  el <- NULL                                                       # elipses por grupo (entram nos limites dos eixos)
  if (!identical(M$elipses %||% "nenhuma", "nenhuma")) {
    if (is.null(o$grupo)) .aviso("cfg$multivariada$elipses precisa de grupos: defina cfg$grafico$coluna_grupo.")
    else {
      el <- do.call(rbind, lapply(grupos, function(g) {
        p <- .elipse_grupo(o$sites[o$grupo %in% g, , drop = FALSE], M$elipses, M$elipse_nivel %||% 0.95)
        if (is.null(p)) { .aviso("Elipse do grupo '", g, "' ignorada (precisa de pelo menos 4 amostras com variação)."); return(NULL) }
        data.frame(x = p[, 1], y = p[, 2], serie = g)
      }))
      if (!is.null(el)) el$serie <- factor(el$serie, levels = grupos)
    }
  }
  # limites dos eixos: dados + folga; com escala_igual os dois eixos têm a mesma escala (o retângulo do painel decide)
  xr <- range(c(S$x, V$x, A$x, el$x, 0)); yr <- range(c(S$y, V$y, A$y, el$y, 0))
  folga <- function(r) r + c(-1, 1) * 0.07 * max(diff(r), 1e-9)
  xr <- folga(xr); yr <- folga(yr)
  fx <- .painel_cm(cfg); pw_cm <- fx$w %||% 10; ph_cm <- fx$h %||% 7.5
  if (isTRUE(M$escala_igual) && !is.null(fx)) {
    alvo <- ph_cm / pw_cm
    if (diff(yr) / diff(xr) < alvo) { m <- mean(yr); yr <- m + c(-1, 1) * diff(xr) * alvo / 2 } else { m <- mean(xr); xr <- m + c(-1, 1) * diff(yr) / alvo / 2 }
  }
  ex <- cfg$eixo_x; ey <- cfg$eixo_y
  if (is.null(ex$inicio) && is.null(ex$fim)) ex <- utils::modifyList(ex, list(inicio = xr[1], fim = xr[2]))
  if (is.null(ey$inicio) && is.null(ey$fim)) ey <- utils::modifyList(ey, list(inicio = yr[1], fim = yr[2]))
  ax_x <- .calc_eixo(ex, xr, forcar = cfg$.interno$forcar_x); ax_y <- .calc_eixo(ey, yr, forcar = cfg$.interno$forcar_y)
  lx <- range(ax_x$limites); ly <- range(ax_y$limites)
  pw_in <- pw_cm / 2.54; ph_in <- ph_cm / 2.54; sx <- pw_in / diff(lx); sy <- ph_in / diff(ly)
  # nomes: posição própria, sem encostar em nada
  est_a <- .estilo_texto_mv(cfg, "amostras", cfg$texto$cor); est_v <- .estilo_texto_mv(cfg, "variaveis", M$cor_variaveis %||% "grey30")
  est_e <- .estilo_texto_mv(cfg, "ambientais", M$cor_ambientais %||% "#B3262E")
  posicoes <- .ler_posicoes(M$rotulos_posicoes)
  conj <- list()                                                    # cada conjunto: data.frame(x, y, rot) + estilo + chave de arrastar
  if (!is.null(A)) conj[["amb"]] <- list(d = A, e = est_e, tipo = "ambientais")
  if (!is.null(V) && isTRUE(M$rotulos_variaveis)) conj[["var"]] <- list(d = V, e = est_v, tipo = "variaveis")
  if (isTRUE(M$rotulos_amostras)) conj[["amo"]] <- list(d = S[c("x", "y", "rot")], e = est_a, tipo = "amostras")
  obst <- data.frame(x = S$x, y = S$y, r_in = 0.045)
  if (!is.null(V) && estilo_v == "pontos") obst <- rbind(obst, data.frame(x = V$x, y = V$y, r_in = 0.03))
  corpo_seta <- function(P) if (is.null(P)) NULL else do.call(rbind, lapply(c(0.4, 0.55, 0.7, 0.85), function(t) data.frame(x = P$x * t, y = P$y * t, r_in = 0.018)))   # o corpo das setas também é obstáculo
  if (!is.null(A) || identical(estilo_v, "setas")) obst <- rbind(obst, corpo_seta(A), if (identical(estilo_v, "setas")) corpo_seta(V))
  camada_rot <- list(); fios <- list(); lista_rot <- list(); colocados <- NULL
  for (nm in names(conj)) {
    cj <- conj[[nm]]; d <- cj$d[!duplicated(cj$d$rot) | TRUE, , drop = FALSE]; d <- d[order(-(d$x^2 + d$y^2)), , drop = FALSE]        # os mais afastados escolhem primeiro
    me <- .medir_textos(d$rot, cj$e$pt, cj$e$fonte, cj$e$face)
    pref <- atan2(d$y * sy, d$x * sx)                                 # para fora da origem
    fixas <- lapply(d$rot, function(r) posicoes[[r]])
    pos <- .posicionar_rotulos(d[c("x", "y")], me$w, me$h, sx, sy, c(lx, ly), obst = rbind(obst, colocados), pref = pref, fixas = fixas)
    colocados <- rbind(colocados, data.frame(x = pos$x, y = pos$y, r_in = 0.5 * min(me$h)))   # (aproximação: o nome já colocado vira obstáculo menor)
    dd <- data.frame(x = pos$x, y = pos$y, rot = d$rot)
    camada_rot[[length(camada_rot) + 1]] <- geom_text(data = dd, aes(x = x, y = y, label = rot), colour = cj$e$cor, size = .tx(cj$e$pt), family = cj$e$fonte,
                                                      fontface = cj$e$face, show.legend = FALSE, lineheight = 0.95)
    if (isTRUE(M$linha_guia)) { f <- .fios_rotulos(d[c("x", "y")], pos, me$w, me$h, sx, sy)
      if (!is.null(f)) fios[[length(fios) + 1]] <- geom_segment(data = f, aes(x = x, y = y, xend = xend, yend = yend), colour = cj$e$cor, linewidth = .lw(0.3), alpha = 0.6, show.legend = FALSE) }
    lista_rot[[length(lista_rot) + 1]] <- data.frame(chave = d$rot, x = pos$x, y = pos$y, w_in = me$w, h_in = me$h, conj = cj$tipo, stringsAsFactors = FALSE)
  }
  cam <- list()
  if (isTRUE(M$linhas_zero))
    cam <- c(cam, list(geom_hline(yintercept = 0, colour = "grey65", linewidth = .lw(0.4), linetype = "dashed"),
                       geom_vline(xintercept = 0, colour = "grey65", linewidth = .lw(0.4), linetype = "dashed")))
  if (!is.null(el)) {
    if (isTRUE(M$elipse_preencher)) cam[[length(cam) + 1]] <- geom_polygon(data = el, aes(x = x, y = y, fill = serie, group = serie), alpha = 0.10, colour = NA, show.legend = FALSE)
    cam[[length(cam) + 1]] <- geom_path(data = el, aes(x = x, y = y, colour = serie, group = serie), linewidth = .lw(M$elipse_espessura_pt %||% 0.8), show.legend = FALSE)
  }
  ponta <- arrow(length = unit(M$setas_ponta_pt %||% 5, "pt"), type = if (identical(M$setas_ponta, "aberta")) "open" else "closed", angle = 22)
  if (!is.null(V)) {
    cor_v <- est_v$cor
    cam[[length(cam) + 1]] <- if (estilo_v == "setas")
      geom_segment(data = V, aes(x = 0, y = 0, xend = x, yend = y), colour = cor_v, linewidth = .lw(M$espessura_setas_pt %||% 0.6), arrow = ponta, show.legend = FALSE)
      else geom_point(data = V, aes(x = x, y = y), colour = cor_v, shape = .simbolo_codigo(M$variaveis_simbolo %||% "cruz", "cfg$multivariada$variaveis_simbolo"),
                      size = .tx(M$variaveis_tamanho_ponto_pt %||% cfg$serie_padrao$tamanho_simbolo_pt * 0.75), stroke = .st(0.9), show.legend = FALSE)
  }
  if (!is.null(A))
    cam[[length(cam) + 1]] <- geom_segment(data = A, aes(x = 0, y = 0, xend = x, yend = y), colour = est_e$cor, linewidth = .lw((M$espessura_setas_pt %||% 0.6) * 1.3), arrow = ponta, show.legend = FALSE)
  aes_leg <- character(0)
  if (isTRUE(M$mostrar_amostras)) {
    cam[[length(cam) + 1]] <- geom_point(data = S, aes(x = x, y = y, colour = serie, fill = serie, shape = serie, size = serie, stroke = serie, alpha = serie),
                                         show.legend = TRUE, na.rm = TRUE, key_glyph = .key_escala(.draw_key_ponto_ou_nada, cfg))
    aes_leg <- c("colour", "shape", "size", "stroke", "fill_simb", "alpha")
  }
  cam <- c(cam, fios, camada_rot)
  gcol <- if (!is.null(o$grupo)) .colunas_multivariada(dados, cfg)$grupo else NULL
  if (is.null(cfg$legenda$titulo) && !is.null(gcol)) cfg$legenda$titulo <- gcol                     # o título da legenda é o nome da coluna dos grupos
  escalas <- if (isTRUE(M$mostrar_amostras)) .escalas_legenda(est, aes_leg, cfg) else list()
  tit <- function(i) paste0(o$eixos[i], " (", .fmt_num(o$prop[i] * 100, 1), "%)")
  list(camadas = c(cam, escalas),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = FALSE, titulo_x = cfg$eixo_x$titulo %||% tit(1), titulo_y = cfg$eixo_y$titulo %||% tit(2),
                   legenda_auto = length(grupos) > 1, faixa_x = lx, faixa_y = ly, ordenacao = o$resumo, titulo_barra = gcol,
                   rotulos = if (length(lista_rot)) list(campo = "multi_rotulos_posicoes", itens = do.call(rbind, lista_rot), lim_x = lx, lim_y = ly)))
}
