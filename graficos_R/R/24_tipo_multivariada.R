# =============================================================================
#  R/24_tipo_multivariada.R — PCA, CA e CCA (biplots)
# =============================================================================
#  Usa o pacote vegan (rda para o PCA, cca para o CA e o CCA). A planilha tem uma linha por amostra; as colunas são
#  divididas em variáveis (matriz principal) e ambientais (cfg$multivariada). Veja cfg$multivariada no 01_config.R.
# =============================================================================

# Tabela que o app e o motor usam para dizer como cada coluna foi tratada. Entra: dados e cfg. Sai: list(x, grupo, variaveis, ambientais).
.colunas_multivariada <- function(dados, cfg) {
  M <- cfg$multivariada; G <- cfg$grafico
  nome <- function(refs, onde) if (is.null(refs)) NULL else vapply(refs, function(r) .coluna(dados, r, onde), "")
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

# Biplot de PCA, CA e CCA. Entra: dados e cfg. Sai: list(camadas, info).
.construir_multivariada <- function(dados, cfg) {
  M <- cfg$multivariada; tipo <- cfg$grafico$tipo
  o <- .ordenacao(dados, cfg)
  fonte <- .fonte(cfg$texto$fonte); tam_rot <- .tx(M$tamanho_rotulos_pt %||% cfg$texto$tamanho_base_pt * 0.85)
  face <- if (.neg(cfg)) "bold" else "plain"
  rotular <- function(d, cor, ...) {
    if (!nrow(d)) return(NULL)
    if (.tem("ggrepel")) ggrepel::geom_text_repel(data = d, aes(x = x, y = y, label = rot), colour = cor, size = tam_rot, family = fonte, fontface = face,
                                                   max.overlaps = 100, min.segment.length = 0.3, segment.size = 0.25, segment.colour = "grey60",
                                                   box.padding = 0.25, point.padding = 0.15, seed = 1, show.legend = FALSE, ...)
    else geom_text(data = d, aes(x = x, y = y, label = rot), colour = cor, size = tam_rot, family = fonte, fontface = face, vjust = -0.6, check_overlap = TRUE, show.legend = FALSE)
  }
  S <- as.data.frame(o$sites); names(S) <- c("x", "y"); S$rot <- o$rotulos
  grupos <- if (!is.null(o$grupo)) { ordem <- cfg$grafico$ordem_itens; g <- unique(o$grupo[!is.na(o$grupo)])
                                       if (!is.null(ordem)) c(intersect(ordem, g), setdiff(g, ordem)) else g } else "Amostras"
  S$serie <- factor(if (is.null(o$grupo)) "Amostras" else o$grupo, levels = grupos)
  est <- .estilos(cfg, grupos)
  for (i in names(est)) if (isTRUE(est[[i]]$simbolo == .COD_ESFERA)) est[[i]]$simbolo <- 21
  cam <- list(); aes_leg <- character(0)
  # setas esticadas para caber na nuvem de amostras (só a direção e o tamanho relativo valem)
  mul <- function(v) {
    if (!isTRUE(M$ajustar_setas) || !nrow(v)) return(1)
    lim <- apply(abs(o$sites), 2, max); mx <- apply(abs(v), 2, max); mx[mx == 0] <- 1e-9
    0.9 * min(lim / mx)
  }
  if (isTRUE(M$linhas_zero))
    cam <- c(cam, list(geom_hline(yintercept = 0, colour = "grey60", linewidth = .lw(0.4), linetype = "dashed"),
                       geom_vline(xintercept = 0, colour = "grey60", linewidth = .lw(0.4), linetype = "dashed")))
  if (!identical(M$elipses %||% "nenhuma", "nenhuma")) {
    if (is.null(o$grupo)) .aviso("cfg$multivariada$elipses precisa de grupos: defina cfg$grafico$coluna_grupo.")
    else {
      el <- do.call(rbind, lapply(grupos, function(g) {
        p <- .elipse_grupo(o$sites[o$grupo %in% g, , drop = FALSE], M$elipses, M$elipse_nivel %||% 0.95)
        if (is.null(p)) { .aviso("Elipse do grupo '", g, "' ignorada (precisa de pelo menos 4 amostras com variação)."); return(NULL) }
        data.frame(x = p[, 1], y = p[, 2], serie = g)
      }))
      if (!is.null(el)) { el$serie <- factor(el$serie, levels = grupos)
        cam[[length(cam) + 1]] <- geom_path(data = el, aes(x = x, y = y, colour = serie, group = serie), linewidth = .lw(0.8), show.legend = FALSE) }
    }
  }
  # variáveis
  V <- NULL; Vlab <- NULL
  if (isTRUE(M$mostrar_variaveis) && !is.null(o$vars)) {
    V <- as.data.frame(o$vars); names(V) <- c("x", "y"); V$rot <- rownames(o$vars)
    if (!is.null(M$max_variaveis) && nrow(V) > M$max_variaveis) V <- V[order(-(V$x^2 + V$y^2))[seq_len(M$max_variaveis)], , drop = FALSE]
    estilo <- if (identical(M$variaveis_estilo, "auto") || is.null(M$variaveis_estilo)) (if (tipo == "pca") "setas" else "pontos") else M$variaveis_estilo
    if (estilo == "setas") { k <- mul(as.matrix(V[c("x", "y")])); V$x <- V$x * k; V$y <- V$y * k }
    cor_v <- .cor(M$cor_variaveis %||% "grey30", "cfg$multivariada$cor_variaveis")
    cam[[length(cam) + 1]] <- if (estilo == "setas")
      geom_segment(data = V, aes(x = 0, y = 0, xend = x, yend = y), colour = cor_v, linewidth = .lw(M$espessura_setas_pt %||% 0.6),
                   arrow = arrow(length = unit(5, "pt"), type = "closed"), show.legend = FALSE)
      else geom_point(data = V, aes(x = x, y = y), colour = cor_v, shape = 17, size = .tx(cfg$serie_padrao$tamanho_simbolo_pt * 0.8), show.legend = FALSE)
    if (isTRUE(M$rotulos_variaveis)) Vlab <- rotular(V, cor_v)
  }
  # ambientais
  A <- NULL; Alab <- NULL
  if (isTRUE(M$mostrar_ambientais) && !is.null(o$amb)) {
    A <- as.data.frame(o$amb); names(A) <- c("x", "y"); A$rot <- rownames(o$amb)
    k <- mul(as.matrix(A[c("x", "y")])); A$x <- A$x * k; A$y <- A$y * k
    cor_a <- .cor(M$cor_ambientais %||% "#B3262E", "cfg$multivariada$cor_ambientais")
    cam[[length(cam) + 1]] <- geom_segment(data = A, aes(x = 0, y = 0, xend = x, yend = y), colour = cor_a, linewidth = .lw((M$espessura_setas_pt %||% 0.6) * 1.2),
                                           arrow = arrow(length = unit(5, "pt"), type = "closed"), show.legend = FALSE)
    Alab <- rotular(A, cor_a)
  }
  # amostras
  if (isTRUE(M$mostrar_amostras)) {
    cam[[length(cam) + 1]] <- geom_point(data = S, aes(x = x, y = y, colour = serie, fill = serie, shape = serie, size = serie, stroke = serie, alpha = serie),
                                         show.legend = TRUE, na.rm = TRUE, key_glyph = .key_escala(.draw_key_ponto_ou_nada, cfg))
    aes_leg <- c("colour", "shape", "size", "stroke", "fill_simb", "alpha")
  }
  cam <- c(cam, Vlab, Alab)
  if (isTRUE(M$rotulos_amostras)) cam[[length(cam) + 1]] <- rotular(S, cfg$texto$cor)
  escalas <- .escalas_legenda(est, aes_leg, cfg)
  if (!isTRUE(M$mostrar_amostras)) escalas <- list()
  faixa_x <- range(c(S$x, V$x, A$x, 0)); faixa_y <- range(c(S$y, V$y, A$y, 0))
  folga <- function(r) r + c(-1, 1) * 0.06 * max(diff(r), 1e-9)
  faixa_x <- folga(faixa_x); faixa_y <- folga(faixa_y)
  ax_x <- .calc_eixo(cfg$eixo_x, faixa_x, forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  tit <- function(i) paste0(o$eixos[i], " (", .fmt_num(o$prop[i] * 100, 1), "%)")
  list(camadas = c(cam, escalas),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = FALSE, titulo_x = cfg$eixo_x$titulo %||% tit(1), titulo_y = cfg$eixo_y$titulo %||% tit(2),
                   legenda_auto = length(grupos) > 1, faixa_x = faixa_x, faixa_y = faixa_y, ordenacao = o$resumo))
}
