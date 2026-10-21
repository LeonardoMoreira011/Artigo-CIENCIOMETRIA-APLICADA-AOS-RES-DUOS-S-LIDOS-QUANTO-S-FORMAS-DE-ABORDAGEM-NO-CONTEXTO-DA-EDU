# =============================================================================
#  R/21_ajustes.R — ajustes de curva, estatísticas, testes e caixas de estatística
# =============================================================================
#  Tudo usa só o R base (stats): lm, nls, loess, cor.test, shapiro.test, t.test, wilcox.test, aov, kruskal.test,
#  TukeyHSD, bartlett.test, fligner.test, var.test. Os cálculos usam os dados DE VERDADE (também os de séries do eixo Y2
#  e os que a quebra de eixo esconde); o gráfico só desenha.
#
#  cfg$ajustes              lista de ajustes (uma curva por item)
#  cfg$marcas_estatisticas  lista de traços de média / mediana, com faixas de DP, EP, IC 95% ou mín–máx
#  cfg$caixas_estatisticas  lista de caixas de texto com números (estatísticas, ajuste, testes)
#  estatisticas(dados, cfg) devolve as mesmas tabelas em data.frames (para colar em relatório).
# =============================================================================

.AJUSTES_TIPOS <- c("linear", "exponencial", "potencia", "logaritmico", "polinomial", "loess", "formula")
.EST_ITENS_DESC <- c("n", "media", "mediana", "dp", "ep", "soma", "minimo", "maximo", "amplitude", "variancia", "cv", "q1", "q3", "ic95")
.EST_ITENS_AJUSTE <- c("equacao", "r2", "r2_aj", "rmse", "aic", "bic", "p_modelo", "parametros", "p_parametros", "shapiro_residuos")
.EST_ITENS_TESTE <- c("pearson", "spearman", "kendall", "shapiro", "ttest", "wilcoxon", "var_test", "anova", "kruskal", "tukey", "bartlett", "fligner")
.EST_ITENS <- c(.EST_ITENS_DESC, .EST_ITENS_AJUSTE, .EST_ITENS_TESTE)

# Rótulos (pt, en, es).
.ROT_EST <- list(
  n = c("n", "n", "n"), media = c("Média", "Mean", "Media"), mediana = c("Mediana", "Median", "Mediana"),
  dp = c("DP", "SD", "DE"), ep = c("EP", "SE", "EE"), soma = c("Soma", "Sum", "Suma"),
  minimo = c("Mín.", "Min.", "Mín."), maximo = c("Máx.", "Max.", "Máx."), amplitude = c("Amplitude", "Range", "Rango"),
  variancia = c("Variância", "Variance", "Varianza"), cv = c("CV", "CV", "CV"), q1 = c("Q1", "Q1", "Q1"), q3 = c("Q3", "Q3", "Q3"),
  ic95 = c("IC 95%", "95% CI", "IC 95%"), equacao = c("Equação", "Equation", "Ecuación"), r2 = c("R²", "R²", "R²"),
  r2_aj = c("R² aj.", "Adj. R²", "R² aj."), rmse = c("RMSE", "RMSE", "RMSE"), aic = c("AIC", "AIC", "AIC"), bic = c("BIC", "BIC", "BIC"),
  p_modelo = c("p (modelo)", "p (model)", "p (modelo)"), parametros = c("Parâmetros", "Parameters", "Parámetros"),
  shapiro_residuos = c("Shapiro (resíduos)", "Shapiro (residuals)", "Shapiro (residuos)"),
  pearson = c("Pearson", "Pearson", "Pearson"), spearman = c("Spearman", "Spearman", "Spearman"), kendall = c("Kendall", "Kendall", "Kendall"),
  shapiro = c("Shapiro-Wilk", "Shapiro-Wilk", "Shapiro-Wilk"), ttest = c("Teste t (Welch)", "t test (Welch)", "Prueba t (Welch)"),
  wilcoxon = c("Wilcoxon", "Wilcoxon", "Wilcoxon"), var_test = c("Teste F (variâncias)", "F test (variances)", "Prueba F (varianzas)"),
  anova = c("ANOVA", "ANOVA", "ANOVA"), kruskal = c("Kruskal-Wallis", "Kruskal-Wallis", "Kruskal-Wallis"), tukey = c("Tukey", "Tukey", "Tukey"),
  bartlett = c("Bartlett", "Bartlett", "Bartlett"), fligner = c("Fligner-Killeen", "Fligner-Killeen", "Fligner-Killeen"),
  linear = c("Linear", "Linear", "Lineal"), exponencial = c("Exponencial", "Exponential", "Exponencial"), potencia = c("Potência", "Power", "Potencia"),
  logaritmico = c("Logarítmico", "Logarithmic", "Logarítmico"), polinomial = c("Polinomial", "Polynomial", "Polinómico"),
  loess = c("Suavizado (loess)", "Smoothed (loess)", "Suavizado (loess)"), formula = c("Fórmula livre", "Free formula", "Fórmula libre"),
  gl = c("gl", "df", "gl"))
.re <- function(id) { r <- .ROT_EST[[id]]; if (is.null(r)) id else r[match(.idioma(), c("pt", "en", "es"))] }

# ---- formatação dos números -----------------------------------------------------------------------------------------------
.nf <- function(v, casas = NULL) vapply(v, function(z) {
  if (length(z) != 1 || is.na(z)) return("NA")
  if (!is.finite(z)) return(if (z > 0) "Inf" else "-Inf")
  if (!is.null(casas)) return(formatC(z, format = "f", digits = casas))
  if (z == 0) return("0")
  if (abs(z) >= 1e6 || abs(z) < 1e-3) return(formatC(z, format = "e", digits = 3))
  format(signif(z, 4), trim = TRUE, scientific = FALSE)
}, "")
.pf <- function(p) if (length(p) != 1 || is.na(p)) "p = NA" else if (p < 0.001) "p < 0.001" else paste0("p = ", formatC(p, format = "f", digits = if (p < 0.01) 4 else 3))
.pf_curto <- function(p) if (is.na(p)) "NA" else if (p < 0.001) "< 0.001" else formatC(p, format = "f", digits = if (p < 0.01) 4 else 3)

# ---- fórmula livre (só funções matemáticas permitidas) --------------------------------------------------------------------
.FUNCS_FORMULA <- c("exp", "log", "log10", "log2", "sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "sinh", "cosh", "tanh", "abs", "(", "+", "-", "*", "/", "^")
.ler_formula <- function(txt) {
  if (is.null(txt) || !is.character(txt) || length(txt) != 1 || !nzchar(trimws(txt)))
    .erro("cfg$ajustes: o tipo \"formula\" precisa de 'formula' (ex.: \"a*exp(-b*x) + c\").")
  t <- gsub("\\*\\*", "^", trimws(txt)); t <- sub("^y\\s*(=|~)\\s*", "", t); t <- sub("^~\\s*", "", t)
  e <- tryCatch(parse(text = t, keep.source = FALSE), error = function(e) .erro("cfg$ajustes: não entendi a fórmula '", txt, "'. Escreva como em a*exp(-b*x) + c (use x para o eixo X)."))
  if (length(e) != 1) .erro("cfg$ajustes: a fórmula deve ser uma expressão só.")
  e <- e[[1]]; params <- character(0); usa_x <- FALSE
  anda <- function(z) {
    if (is.numeric(z)) return(invisible())
    if (is.symbol(z)) {
      nm <- as.character(z)
      if (nm == "x") usa_x <<- TRUE
      else if (nm != "pi") {
        if (!grepl("^[A-Za-z][A-Za-z0-9_]*$", nm) || nm %in% c("T", "F", "y")) .erro("cfg$ajustes: nome '", nm, "' não pode ser parâmetro na fórmula.")
        params <<- union(params, nm)
      }
      return(invisible())
    }
    if (is.call(z)) {
      f <- z[[1]]
      if (!is.symbol(f) || !as.character(f) %in% .FUNCS_FORMULA)
        .erro("cfg$ajustes: a fórmula usa '", paste(deparse(f), collapse = ""), "', que não é permitido. Use + - * / ^ e exp, log, log10, log2, sqrt, sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, abs.")
      for (a in as.list(z)[-1]) anda(a)
      return(invisible())
    }
    .erro("cfg$ajustes: não entendi a fórmula '", txt, "'.")
  }
  anda(e)
  if (!usa_x) .erro("cfg$ajustes: a fórmula precisa usar x (o eixo X).")
  if (!length(params)) .erro("cfg$ajustes: a fórmula precisa de pelo menos um parâmetro a ajustar (a, b, c...).")
  if (length(params) > 8) .erro("cfg$ajustes: a fórmula tem parâmetros demais (máximo 8).")
  list(expr = e, params = params, texto = t)
}

# ---- ajuste de uma curva ---------------------------------------------------------------------------------------------------
# Entra: x, y (numéricos) e o item de cfg$ajustes. Sai: lista com $ok, $pred(xn), $eq, $par (tabela), $r2, $r2_aj, $rmse, $aic, $bic, $n, $p, $banda(xn, nivel)
.sup <- c("⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹")
.sinal_termo <- function(v, casas, sufixo = "", primeiro = FALSE) {
  s <- .nf(abs(v), casas)
  if (primeiro) paste0(if (v < 0) "-" else "", s, sufixo) else paste0(if (v < 0) " - " else " + ", s, sufixo)
}
.ajustar <- function(x, y, aj, casas = NULL) {
  aj <- .ex(aj)
  ok <- is.finite(x) & is.finite(y); x <- x[ok]; y <- y[ok]; n <- length(x)
  tipo <- aj$tipo %||% "linear"
  if (!tipo %in% .AJUSTES_TIPOS) .erro("cfg$ajustes: tipo '", tipo, "' não é válido.\n  OPÇÕES: ", paste0('"', .AJUSTES_TIPOS, '"', collapse = " | "))
  falha <- function(msg) list(ok = FALSE, tipo = tipo, msg = msg, n = n)
  minimo <- switch(tipo, linear = 2, exponencial = 3, potencia = 3, logaritmico = 3, polinomial = (aj$grau %||% 2) + 2, loess = 6, formula = 4)
  if (n < minimo) return(falha(paste0("poucos pontos (", n, ")")))
  if (tipo %in% c("potencia", "logaritmico") && any(x <= 0)) return(falha("exige X > 0"))
  g <- NULL; fpar <- NULL; mod <- NULL; cf <- NULL
  if (tipo == "linear") {
    mod <- if (isTRUE(aj$intercepto_zero)) stats::lm(y ~ 0 + x) else stats::lm(y ~ x)
  } else if (tipo == "logaritmico") {
    mod <- stats::lm(y ~ I(log(x)))
  } else if (tipo == "polinomial") {
    g <- aj$grau %||% 2
    if (!is.numeric(g) || g < 1 || g > 8 || g != round(g)) .erro("cfg$ajustes: grau deve ser um inteiro de 1 a 8.")
    mod <- stats::lm(y ~ stats::poly(x, g, raw = TRUE))
  } else if (tipo == "loess") {
    mod <- tryCatch(suppressWarnings(stats::loess(y ~ x, span = aj$suavizacao %||% 0.75, degree = 2)), error = function(e) NULL)
    if (is.null(mod)) return(falha("o suavizado (loess) não convergiu"))
  } else {
    if (tipo == "exponencial") {
      pn <- c("a", "b"); fpar <- function(x, p) p[["a"]] * exp(p[["b"]] * x)
      st <- if (all(y > 0)) { l <- stats::lm(log(y) ~ x); c(a = exp(unname(stats::coef(l)[1])), b = unname(stats::coef(l)[2])) } else c(a = mean(y), b = 0.01)
    } else if (tipo == "potencia") {
      pn <- c("a", "b"); fpar <- function(x, p) p[["a"]] * x^p[["b"]]
      st <- if (all(y > 0)) { l <- stats::lm(log(y) ~ log(x)); c(a = exp(unname(stats::coef(l)[1])), b = unname(stats::coef(l)[2])) } else c(a = mean(y), b = 1)
    } else {
      F <- .ler_formula(aj$formula); pn <- F$params
      fpar <- local({ ex <- F$expr; pnn <- pn; function(x, p) eval(ex, c(as.list(p), list(x = x, pi = pi)), baseenv()) })
      ini <- aj$inicio
      if (!is.null(ini)) { if (is.null(names(ini))) ini <- stats::setNames(rep_len(ini, length(pn)), pn) else ini <- ini[intersect(names(ini), pn)] }
      st <- stats::setNames(rep(1, length(pn)), pn)
      if (length(ini)) st[names(ini)] <- ini
    }
    dd <- data.frame(x = x, y = y)
    corpo <- if (tipo == "formula") F$expr else if (tipo == "exponencial") quote(a * exp(b * x)) else quote(a * x^b)
    fo <- stats::as.formula(call("~", quote(y), corpo))
    tentativas <- list(st)
    if (tipo == "formula" && is.null(aj$inicio)) {
      sc <- c(1, 0.1, 10, -1, mean(abs(y)), 0.01, stats::sd(y), diff(range(y)) / max(diff(range(x)), 1e-9))
      for (v in sc) tentativas[[length(tentativas) + 1]] <- stats::setNames(rep(v, length(pn)), pn)
      rg <- .guardar_rng(); on.exit(rg(), add = TRUE); set.seed(1)
      for (k in 1:12) tentativas[[length(tentativas) + 1]] <- stats::setNames(stats::rnorm(length(pn), mean(st), 2), pn)
    } else if (tipo != "formula") tentativas[[2]] <- stats::setNames(c(mean(y), 0.01), pn)
    melhor <- NULL
    for (s0 in tentativas) {
      m1 <- tryCatch(suppressWarnings(stats::nls(fo, data = dd, start = as.list(s0), control = stats::nls.control(maxiter = 200, warnOnly = FALSE))), error = function(e) NULL)
      if (is.null(m1)) m1 <- tryCatch(suppressWarnings(stats::nls(fo, data = dd, start = as.list(s0), algorithm = "port", control = stats::nls.control(maxiter = 300, warnOnly = TRUE))), error = function(e) NULL)
      if (!is.null(m1) && (is.null(melhor) || stats::deviance(m1) < stats::deviance(melhor))) melhor <- m1
      if (!is.null(melhor) && tipo != "formula") break
    }
    if (is.null(melhor)) return(falha("o ajuste não convergiu (dê valores iniciais em 'inicio')"))
    mod <- melhor; cf <- stats::coef(mod)
  }

  # predição e métricas -------------------------------------------------------------------------------------------------
  res <- stats::residuals(mod); rss <- sum(res^2); tss <- sum((y - mean(y))^2)
  if (tipo == "linear" && isTRUE(aj$intercepto_zero)) tss <- sum(y^2)
  npar <- if (tipo == "loess") mod$enp else length(stats::coef(mod))
  r2 <- if (tss > 0) 1 - rss / tss else NA_real_
  r2aj <- if (!is.na(r2) && n - npar > 0) 1 - (1 - r2) * (n - (if (tipo == "linear" && isTRUE(aj$intercepto_zero)) 0 else 1)) / (n - npar) else NA_real_
  aic <- tryCatch(stats::AIC(mod), error = function(e) NA_real_); bic <- tryCatch(stats::BIC(mod), error = function(e) NA_real_)
  pred <- function(xn) {
    if (!is.null(fpar)) fpar(xn, cf)
    else if (tipo == "logaritmico") stats::predict(mod, newdata = data.frame(x = xn))
    else suppressWarnings(as.numeric(stats::predict(mod, newdata = data.frame(x = xn))))
  }
  if (!is.null(fpar)) pred <- function(xn) as.numeric(fpar(xn, cf))
  # tabela de parâmetros
  par <- NULL; p_mod <- NA_real_; fst <- NA_real_; gl <- NA_real_
  if (tipo != "loess") {
    sm <- summary(mod)$coefficients
    nomes <- switch(tipo, linear = if (isTRUE(aj$intercepto_zero)) "b" else c("a", "b"), logaritmico = c("a", "b"),
                    polinomial = paste0("a", 0:g), rownames(sm))
    dfr <- stats::df.residual(mod); tq <- stats::qt(0.975, dfr)
    par <- data.frame(termo = nomes, estimativa = unname(sm[, 1]), ep = unname(sm[, 2]), t = unname(sm[, 3]), p = unname(sm[, 4]),
                      ic_inf = unname(sm[, 1] - tq * sm[, 2]), ic_sup = unname(sm[, 1] + tq * sm[, 2]), stringsAsFactors = FALSE)
    if (inherits(mod, "lm")) {
      s <- summary(mod); if (!is.null(s$fstatistic)) { fst <- unname(s$fstatistic[1]); gl <- unname(s$fstatistic[3]); p_mod <- stats::pf(fst, s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE) }
    } else if (nrow(par) >= 1 && length(y) > npar) {
      fst <- ((tss - rss) / max(npar - 1, 1)) / (rss / (n - npar)); gl <- n - npar
      p_mod <- stats::pf(fst, max(npar - 1, 1), n - npar, lower.tail = FALSE)
    }
  }
  # equação em texto
  cc <- stats::setNames(if (is.null(par)) numeric(0) else par$estimativa, if (is.null(par)) character(0) else par$termo)
  eq <- switch(tipo,
    linear = if (isTRUE(aj$intercepto_zero)) paste0("y = ", .nf(cc[["b"]], casas), "x")
             else paste0("y = ", .nf(cc[["b"]], casas), "x", .sinal_termo(cc[["a"]], casas)),
    exponencial = paste0("y = ", .nf(cf[["a"]], casas), "·exp(", .nf(cf[["b"]], casas), "x)"),
    potencia = paste0("y = ", .nf(cf[["a"]], casas), "·x^", .nf(cf[["b"]], casas)),
    logaritmico = paste0("y = ", .nf(cc[["a"]], casas), .sinal_termo(cc[["b"]], casas, "·ln(x)")),
    polinomial = { termos <- paste0(.nf(cc[["a0"]], casas)); for (k in seq_len(g)) termos <- paste0(termos, .sinal_termo(cc[[paste0("a", k)]], casas, paste0(if (k == 1) "x" else paste0("x", if (k <= 9) .sup[k + 1] else paste0("^", k)))))
                   paste0("y = ", termos) },
    loess = NA_character_,
    formula = { tx <- F$texto; for (nm in F$params) tx <- gsub(paste0("\\b", nm, "\\b"), .nf(cf[[nm]], casas), tx); paste0("y = ", tx) })
  if (is.null(par) && tipo != "loess") par <- NULL
  banda <- function(xn, nivel = 0.95) {
    tq <- stats::qt(1 - (1 - nivel) / 2, max(n - npar, 1))
    if (inherits(mod, "lm") && is.null(fpar)) {
      p <- suppressWarnings(stats::predict(mod, newdata = data.frame(x = xn), se.fit = TRUE))
      return(data.frame(x = xn, y = as.numeric(p$fit), inf = as.numeric(p$fit - tq * p$se.fit), sup = as.numeric(p$fit + tq * p$se.fit)))
    }
    if (tipo == "loess") {
      p <- tryCatch(suppressWarnings(stats::predict(mod, newdata = data.frame(x = xn), se = TRUE)), error = function(e) NULL)
      if (is.null(p)) return(NULL)
      return(data.frame(x = xn, y = as.numeric(p$fit), inf = as.numeric(p$fit - tq * p$se.fit), sup = as.numeric(p$fit + tq * p$se.fit)))
    }
    V <- tryCatch(stats::vcov(mod), error = function(e) NULL); if (is.null(V)) return(NULL)
    f0 <- as.numeric(fpar(xn, cf)); G <- matrix(0, length(xn), length(cf))
    for (j in seq_along(cf)) { h <- max(abs(cf[[j]]) * 1e-6, 1e-8); c2 <- cf; c2[[j]] <- c2[[j]] + h; G[, j] <- (as.numeric(fpar(xn, c2)) - f0) / h }
    se <- sqrt(pmax(rowSums((G %*% V) * G), 0))
    data.frame(x = xn, y = f0, inf = f0 - tq * se, sup = f0 + tq * se)
  }
  list(ok = TRUE, tipo = tipo, n = n, eq = eq, par = par, r2 = r2, r2_aj = r2aj, rmse = sqrt(rss / n), sigma = if (n > npar) sqrt(rss / (n - npar)) else NA_real_,
       aic = aic, bic = bic, p = p_mod, F = fst, gl = gl, npar = npar, residuos = as.numeric(res), pred = pred, banda = banda)
}

# ---- estatística descritiva -----------------------------------------------------------------------------------------------
.desc <- function(y) {
  y <- y[is.finite(y)]; n <- length(y)
  if (!n) return(NULL)
  m <- mean(y); s <- if (n > 1) stats::sd(y) else NA_real_; ep <- s / sqrt(n)
  tq <- if (n > 1) stats::qt(0.975, n - 1) else NA_real_
  q <- stats::quantile(y, c(0.25, 0.75), names = FALSE)
  list(n = n, media = m, mediana = stats::median(y), dp = s, ep = ep, soma = sum(y), minimo = min(y), maximo = max(y), amplitude = max(y) - min(y),
       variancia = s^2, cv = 100 * s / abs(m), q1 = q[1], q3 = q[2], ic_inf = m - tq * ep, ic_sup = m + tq * ep)
}
.linha_desc <- function(id, d, casas) {
  r <- .re(id)
  switch(id,
    n = paste0("n = ", d$n),
    cv = paste0(r, " = ", .nf(d$cv, 1), "%"),
    ic95 = paste0(r, ": [", .nf(d$ic_inf, casas), "; ", .nf(d$ic_sup, casas), "]"),
    paste0(r, " = ", .nf(d[[id]], casas)))
}

# ---- testes estatísticos -------------------------------------------------------------------------------------------------
# Cada teste devolve data.frame(teste, grupos, estatistica, gl, p, detalhe) com uma ou mais linhas e uma coluna 'linha' (texto).
.teste_linha <- function(id, rotulo, grupos, est, gl, p, detalhe, linha) data.frame(id = id, teste = rotulo, grupos = grupos, estatistica = est, gl = gl, p = p, detalhe = detalhe, linha = linha, stringsAsFactors = FALSE)
.teste_nd <- function(id, grupos) .teste_linha(id, .re(id), grupos, NA_real_, NA_character_, NA_real_, "", paste0(.re(id), ": n/d"))
.rodar_teste <- function(id, g, casas = NULL, x = NULL) {
  # g: lista nomeada de vetores y (um por série); x: lista nomeada de vetores x (para correlação)
  nm <- names(g); r <- .re(id); tab <- function(...) .teste_linha(id, r, ...)
  tryCatch(suppressWarnings({
    if (id %in% c("pearson", "spearman", "kendall")) {
      out <- do.call(rbind, lapply(nm, function(k) {
        ok <- is.finite(g[[k]]) & is.finite(x[[k]]); if (sum(ok) < 3) return(.teste_nd(id, k))
        ct <- stats::cor.test(x[[k]][ok], g[[k]][ok], method = id, exact = FALSE)
        simb <- switch(id, pearson = "r", spearman = "ρ", kendall = "τ")
        tab(k, unname(ct$estimate), if (!is.null(ct$parameter)) as.character(unname(ct$parameter)) else NA_character_, ct$p.value, "",
            paste0(r, ": ", simb, " = ", .nf(unname(ct$estimate), 3), "; ", .pf(ct$p.value)))
      }))
      out
    } else if (id == "shapiro") {
      do.call(rbind, lapply(nm, function(k) {
        v <- g[[k]][is.finite(g[[k]])]; if (length(v) < 3 || length(v) > 5000) return(.teste_nd(id, k))
        st <- stats::shapiro.test(v); tab(k, unname(st$statistic), NA_character_, st$p.value, "", paste0(r, ": W = ", .nf(unname(st$statistic), 3), "; ", .pf(st$p.value)))
      }))
    } else {
      g <- lapply(g, function(v) v[is.finite(v)]); g <- g[vapply(g, length, 1L) >= 2]
      k <- length(g)
      if (k < 2) return(.teste_nd(id, paste(nm, collapse = " × ")))
      nomes <- paste(names(g), collapse = " × ")
      dd <- data.frame(y = unlist(g, use.names = FALSE), grupo = factor(rep(names(g), vapply(g, length, 1L)), levels = names(g)))
      if (id == "ttest") {
        t2 <- stats::t.test(g[[1]], g[[2]]); nomes2 <- paste(names(g)[1:2], collapse = " × ")
        tab(nomes2, unname(t2$statistic), as.character(round(unname(t2$parameter), 2)), t2$p.value, paste0("Δ = ", .nf(unname(t2$estimate[1] - t2$estimate[2]), casas)),
            paste0(r, ": t = ", .nf(unname(t2$statistic), 3), "; ", .re("gl"), " = ", .nf(unname(t2$parameter), 1), "; ", .pf(t2$p.value)))
      } else if (id == "wilcoxon") {
        w <- stats::wilcox.test(g[[1]], g[[2]], exact = FALSE); nomes2 <- paste(names(g)[1:2], collapse = " × ")
        tab(nomes2, unname(w$statistic), NA_character_, w$p.value, "", paste0(r, ": W = ", .nf(unname(w$statistic), 1), "; ", .pf(w$p.value)))
      } else if (id == "var_test") {
        v <- stats::var.test(g[[1]], g[[2]]); nomes2 <- paste(names(g)[1:2], collapse = " × ")
        tab(nomes2, unname(v$statistic), paste(unname(v$parameter), collapse = "; "), v$p.value, "", paste0(r, ": F = ", .nf(unname(v$statistic), 3), "; ", .pf(v$p.value)))
      } else if (id == "anova") {
        a <- summary(stats::aov(y ~ grupo, data = dd))[[1]]
        eta <- a[1, "Sum Sq"] / sum(a[, "Sum Sq"])
        tab(nomes, a[1, "F value"], paste(a[, "Df"], collapse = "; "), a[1, "Pr(>F)"], paste0("η² = ", .nf(eta, 3)),
            paste0(r, ": F(", a[1, "Df"], "; ", a[2, "Df"], ") = ", .nf(a[1, "F value"], 3), "; ", .pf(a[1, "Pr(>F)"])))
      } else if (id == "kruskal") {
        kt <- stats::kruskal.test(y ~ grupo, data = dd)
        tab(nomes, unname(kt$statistic), as.character(unname(kt$parameter)), kt$p.value, "", paste0(r, ": χ²(", unname(kt$parameter), ") = ", .nf(unname(kt$statistic), 3), "; ", .pf(kt$p.value)))
      } else if (id == "bartlett") {
        b <- stats::bartlett.test(y ~ grupo, data = dd)
        tab(nomes, unname(b$statistic), as.character(unname(b$parameter)), b$p.value, "", paste0(r, ": K²(", unname(b$parameter), ") = ", .nf(unname(b$statistic), 3), "; ", .pf(b$p.value)))
      } else if (id == "fligner") {
        b <- stats::fligner.test(y ~ grupo, data = dd)
        tab(nomes, unname(b$statistic), as.character(unname(b$parameter)), b$p.value, "", paste0(r, ": χ²(", unname(b$parameter), ") = ", .nf(unname(b$statistic), 3), "; ", .pf(b$p.value)))
      } else if (id == "tukey") {
        tk <- stats::TukeyHSD(stats::aov(y ~ grupo, data = dd))$grupo
        do.call(rbind, lapply(seq_len(nrow(tk)), function(i) tab(rownames(tk)[i], tk[i, "diff"], NA_character_, tk[i, "p adj"], paste0("IC95: [", .nf(tk[i, "lwr"], casas), "; ", .nf(tk[i, "upr"], casas), "]"),
                                                                 paste0(r, " ", rownames(tk)[i], ": Δ = ", .nf(tk[i, "diff"], casas), "; ", .pf(tk[i, "p adj"])))))
      } else .teste_nd(id, nomes)
    }
  }), error = function(e) .teste_nd(id, paste(nm, collapse = " × ")))
}

# ---- reunir dados, ajustes e itens ---------------------------------------------------------------------------------------
# Pontos reais de cada série (do .construir_xy). Sai: data.frame(x, y, serie) ou NULL.
.pts_info <- function(info) info$pts$d
.series_pts <- function(info) if (is.null(info$pts)) character(0) else levels(info$pts$d$serie)
.dados_serie <- function(info, s) { d <- info$pts$d; d <- d[d$serie == s & is.finite(d$x) & is.finite(d$y), ]; d[order(d$x), ] }

# Expande cfg$ajustes: um item por série ("todas" = uma para cada série plotada). Sai: lista de lista(aj, serie).
.itens_ajuste <- function(cfg, info) {
  out <- list(); ss <- .series_pts(info)
  for (i in seq_along(cfg$ajustes)) {
    aj <- .ex(cfg$ajustes[[i]]); if (isFALSE(aj$ativo)) next
    alvo <- aj$serie %||% "todas"
    alvo <- if (identical(alvo, "todas")) ss else intersect(alvo, ss)
    if (!length(alvo) && !isTRUE(cfg$paineis$ativo) && !identical(aj$serie %||% "todas", "todas"))
      .aviso("cfg$ajustes[[", i, "]]: a série '", paste(aj$serie, collapse = ", "), "' não existe no gráfico.")
    for (s in alvo) out[[length(out) + 1]] <- list(aj = aj, serie = s, indice = i)
  }
  out
}
# Calcula os ajustes (lista de lista(aj, serie, fit)).
.calcular_ajustes <- function(cfg, info, casas = NULL) {
  its <- .itens_ajuste(cfg, info)
  lapply(its, function(it) {
    d <- .dados_serie(info, it$serie)
    it$fit <- .ajustar(d$x, d$y, it$aj, casas %||% it$aj$casas)
    if (!it$fit$ok) .aviso("Ajuste ", .re(it$fit$tipo), " da série '", it$serie, "': ", it$fit$msg, ".")
    it$nome <- it$aj$nome %||% .re(it$aj$tipo %||% "linear")
    it
  })
}

# Linhas de uma caixa de estatística. Sai: list(linhas, cores, negritos)
.linhas_caixa <- function(cx, cfg, info, fits) {
  cx <- .ex(cx)
  ss <- .series_pts(info); sel <- cx$series %||% ss; sel <- intersect(sel, ss)
  if (!length(sel)) return(NULL)
  casas <- cx$casas; itens <- cx$itens %||% c("n", "media", "dp")
  ruins <- setdiff(itens, .EST_ITENS)
  if (length(ruins)) .erro("cfg$caixas_estatisticas: item '", ruins[1], "' não existe.\n  OPÇÕES: ", paste0('"', .EST_ITENS, '"', collapse = " | "))
  cor_ser <- info$cores_serie
  L <- character(0); C <- character(0); N <- logical(0)
  add <- function(txt, cor = NULL, neg = FALSE) { L <<- c(L, txt); C <<- c(C, cor %||% .cor(cx$cor_texto %||% cfg$texto$cor)); N <<- c(N, neg) }
  if (!is.null(cx$titulo) && nzchar(cx$titulo)) for (tl in strsplit(gsub("\\n", "\n", cx$titulo, fixed = TRUE), "\n", fixed = TRUE)[[1]]) add(tl, NULL, TRUE)
  com_nome <- length(sel) > 1 || isTRUE(cx$mostrar_nome_serie)
  desc_ids <- intersect(itens, .EST_ITENS_DESC); aj_ids <- intersect(itens, .EST_ITENS_AJUSTE)
  cor_ids <- intersect(itens, c("pearson", "spearman", "kendall", "shapiro")); grp_ids <- intersect(itens, c("ttest", "wilcoxon", "var_test", "anova", "kruskal", "tukey", "bartlett", "fligner"))
  for (s in sel) {
    d <- .dados_serie(info, s); de <- .desc(d$y)
    cor_s <- if (isTRUE(cx$colorir_serie %||% TRUE) && !is.null(cor_ser[[s]])) cor_ser[[s]] else NULL
    if (com_nome) add(s, cor_s, TRUE)
    if (!is.null(de)) for (id in desc_ids) add(.linha_desc(id, de, casas), if (isTRUE(cx$colorir_serie %||% TRUE) && !com_nome) cor_s else NULL)
    meus <- Filter(function(f) identical(f$serie, s) && f$fit$ok && (is.null(cx$ajustes) || f$indice %in% cx$ajustes), fits)
    for (f in meus) {
      ft <- f$fit
      if (length(aj_ids) && length(meus) > 1) add(f$nome, NULL, TRUE)
      for (id in aj_ids) switch(id,
        equacao = if (!is.na(ft$eq)) add(ft$eq),
        r2 = add(paste0("R² = ", .nf(ft$r2, 4))),
        r2_aj = add(paste0(.re("r2_aj"), " = ", .nf(ft$r2_aj, 3))),
        rmse = add(paste0("RMSE = ", .nf(ft$rmse, casas))),
        aic = add(paste0("AIC = ", .nf(ft$aic, 1))), bic = add(paste0("BIC = ", .nf(ft$bic, 1))),
        p_modelo = if (!is.na(ft$p)) add(paste0(.re("p_modelo"), ": F = ", .nf(ft$F, 3), "; ", .pf(ft$p))),
        parametros = if (!is.null(ft$par)) for (k in seq_len(nrow(ft$par))) add(paste0(ft$par$termo[k], " = ", .nf(ft$par$estimativa[k], casas), " ± ", .nf(ft$par$ep[k], casas))),
        p_parametros = if (!is.null(ft$par)) for (k in seq_len(nrow(ft$par))) add(paste0("p(", ft$par$termo[k], ") ", sub("^p ", "", .pf(ft$par$p[k])))),
        shapiro_residuos = { t1 <- .rodar_teste("shapiro", list(r = ft$residuos)); add(sub("^Shapiro-Wilk", .re("shapiro_residuos"), t1$linha[1])) })
    }
    for (id in cor_ids) { t1 <- .rodar_teste(id, stats::setNames(list(d$y), s), casas, stats::setNames(list(d$x), s)); add(t1$linha[1]) }
  }
  if (length(grp_ids)) {
    g <- lapply(sel, function(s) .dados_serie(info, s)$y); names(g) <- sel
    for (id in grp_ids) { t1 <- .rodar_teste(id, g, casas); for (l in t1$linha) add(l) }
  }
  if (!length(L)) return(NULL)
  list(linhas = L, cores = C, negritos = N)
}

# ---- tabelas para o app / relatório ---------------------------------------------------------------------------------------
#  estatisticas(dados, cfg, testes = c("shapiro","anova",...)) -> list(descritiva, ajustes, parametros, testes)
estatisticas <- function(dados, cfg = get("cfg", envir = globalenv()), testes = NULL) {
  cfg <- .completar_cfg(cfg)
  info <- .plotar_um(dados, cfg, so_info = TRUE)
  ss <- .series_pts(info)
  if (!length(ss)) return(list(descritiva = data.frame(), ajustes = data.frame(), parametros = data.frame(), testes = data.frame()))
  desc <- do.call(rbind, lapply(ss, function(s) { d <- .desc(.dados_serie(info, s)$y); if (is.null(d)) return(NULL); data.frame(serie = s, as.data.frame(d), stringsAsFactors = FALSE) }))
  fits <- .calcular_ajustes(cfg, info)
  aj <- do.call(rbind, lapply(fits, function(f) { ft <- f$fit; if (!ft$ok) return(data.frame(serie = f$serie, ajuste = f$nome, equacao = paste0("(", ft$msg, ")"), n = ft$n, r2 = NA, r2_aj = NA, rmse = NA, aic = NA, bic = NA, p = NA, stringsAsFactors = FALSE))
    data.frame(serie = f$serie, ajuste = f$nome, equacao = ft$eq, n = ft$n, r2 = ft$r2, r2_aj = ft$r2_aj, rmse = ft$rmse, aic = ft$aic, bic = ft$bic, p = ft$p, stringsAsFactors = FALSE) }))
  pa <- do.call(rbind, lapply(fits, function(f) if (f$fit$ok && !is.null(f$fit$par)) data.frame(serie = f$serie, ajuste = f$nome, f$fit$par, stringsAsFactors = FALSE)))
  testes <- testes %||% c("pearson", "shapiro", if (length(ss) >= 2) c("anova", "kruskal", "bartlett"))
  g <- lapply(ss, function(s) .dados_serie(info, s)); names(g) <- ss
  gy <- lapply(g, function(d) d$y); gx <- lapply(g, function(d) d$x)
  te <- do.call(rbind, lapply(testes, function(id) { r <- .rodar_teste(id, gy, NULL, gx); r }))
  vazio <- function(x) if (is.null(x)) data.frame() else { rownames(x) <- NULL; x }
  list(descritiva = vazio(desc), ajustes = vazio(aj), parametros = vazio(pa), testes = vazio(te[, setdiff(names(te), "linha"), drop = FALSE]))
}

# ---- desenho -------------------------------------------------------------------------------------------------------------
.fator_y <- function(info, s) {                       # série do Y2: o gráfico desenha em Y1; devolve a função de conversão (ou identidade)
  if (!is.null(info$y2) && s %in% info$pts$ser_y2) info$y2$para1 else identity
}
.camadas_ajustes <- function(cfg, info) {
  antes <- list(); depois <- list()
  if (!is.null(info$pts)) {
    fonte <- .fonte(cfg$texto$fonte)
    # 1) faixas e traços de média / DP / EP
    for (i in seq_along(cfg$marcas_estatisticas)) {
      mk <- .ex(cfg$marcas_estatisticas[[i]]); if (isFALSE(mk$ativo)) next
      sel <- intersect(mk$serie %||% .series_pts(info), .series_pts(info))
      if (identical(mk$serie, "todas")) sel <- .series_pts(info)
      for (s in sel) {
        r <- .camadas_marca(cfg, info, mk, s, fonte)
        antes <- c(antes, r$antes); depois <- c(depois, r$depois)
      }
    }
    # 2) curvas de ajuste
    fits <- if (length(cfg$ajustes)) .calcular_ajustes(cfg, info) else list()
    for (f in fits) if (f$fit$ok) depois <- c(depois, .camada_curva(cfg, info, f))
    # 3) caixas de estatística
    if (!identical(cfg$.interno$parte, "inferior"))
      for (i in seq_along(cfg$caixas_estatisticas)) {
        cx <- .ex(cfg$caixas_estatisticas[[i]]); if (isFALSE(cx$ativo)) next
        lc <- .linhas_caixa(cx, cfg, info, fits); if (is.null(lc)) next
        it <- utils::modifyList(list(tipo = "texto", unidade = "fracao", x = 0.03, y = 0.97, ancora = "sup_esq", fundo = "white", opacidade_fundo = 0.9,
                                     borda = TRUE, borda_cor = "grey40", borda_pt = 0.6, raio_pt = if (identical(cx$cantos, "reto")) 0 else 5, margem_pt = 5),
                                unclass(cx)[setdiff(names(cx), c("itens", "series", "ajustes", "titulo", "casas", "colorir_serie", "mostrar_nome_serie", "ativo", "cantos"))])
        if (identical(cx$cantos, "reto")) it$raio_pt <- 0
        f <- .grob_forma(it, cfg, linhas = lc$linhas, cores = lc$cores, negritos = lc$negritos)
        depois[[length(depois) + 1]] <- .ann_forma(f, info)
      }
  }
  list(antes = antes, depois = depois)
}

.camada_curva <- function(cfg, info, f) {
  aj <- .ex(f$aj); ft <- f$fit; s <- f$serie
  d <- .dados_serie(info, s); ax <- info$ax_x
  de <- aj$de %||% (if (isTRUE(aj$estender)) ax$limites[1] else min(d$x)); ate <- aj$ate %||% (if (isTRUE(aj$estender)) ax$limites[2] else max(d$x))
  if (!is.finite(de) || !is.finite(ate) || de >= ate) return(list())
  npt <- aj$n_pontos %||% 200
  xs <- if (!is.na(.base_log(ax$escala %||% "linear")) && de > 0) exp(seq(log(de), log(ate), length.out = npt)) else seq(de, ate, length.out = npt)
  para <- .fator_y(info, s)
  lim <- info$ax_y$limites
  cor <- .cor(aj$cor) %||% info$cores_serie[[s]] %||% "red"
  tipo_l <- aj$tipo_linha %||% "dashed"
  cam <- list()
  if (isTRUE(aj$banda)) {
    b <- ft$banda(xs, aj$banda_nivel %||% 0.95)
    if (!is.null(b)) {
      b$inf <- para(b$inf); b$sup <- para(b$sup)
      cam[[length(cam) + 1]] <- geom_ribbon(data = b, aes(x = x, ymin = inf, ymax = sup), fill = .alfa(cor, aj$banda_opacidade %||% 0.18), colour = NA, inherit.aes = FALSE)
    }
  }
  yc <- para(ft$pred(xs)); yc[!is.finite(yc)] <- NA
  dc <- data.frame(x = xs, y = yc)
  cam[[length(cam) + 1]] <- geom_path(data = dc, aes(x = x, y = y), colour = .alfa(cor, aj$opacidade %||% 1), linetype = tipo_l,
                                     linewidth = .lw(aj$espessura_pt %||% 1.2), lineend = "round", na.rm = TRUE, inherit.aes = FALSE)
  cam
}

# Traços de média / mediana, faixas de DP / EP / IC 95% / mín–máx, ou barras de erro por X (replicatas).
.camadas_marca <- function(cfg, info, mk, s, fonte) {
  mk <- .ex(mk)
  antes <- list(); depois <- list()
  d <- .dados_serie(info, s); if (!nrow(d)) return(list(antes = antes, depois = depois))
  para <- .fator_y(info, s)
  cor <- .cor(mk$cor) %||% info$cores_serie[[s]] %||% "black"
  casas <- mk$casas; mult <- mk$multiplo %||% 1
  faixa <- mk$faixa %||% "dp"; centro <- mk$centro %||% "media"
  if (!faixa %in% c("dp", "ep", "ic95", "minmax", "nenhuma")) .erro("cfg$marcas_estatisticas: faixa '", faixa, "' não é válida.\n  OPÇÕES: \"dp\" | \"ep\" | \"ic95\" | \"minmax\" | \"nenhuma\"")
  if (!centro %in% c("media", "mediana", "nenhum")) .erro("cfg$marcas_estatisticas: centro '", centro, "' não é válido.\n  OPÇÕES: \"media\" | \"mediana\" | \"nenhum\"")
  if (identical(mk$modo, "barras_por_x")) {
    a <- stats::aggregate(d$y, list(x = d$x), function(v) c(m = mean(v), n = length(v), dp = stats::sd(v)))
    a <- data.frame(x = a$x, m = a$x.m, n = a$x.n, dp = a$x.dp)
    a$disp <- switch(faixa, dp = a$dp, ep = a$dp / sqrt(a$n), ic95 = stats::qt(0.975, pmax(a$n - 1, 1)) * a$dp / sqrt(a$n), minmax = NA_real_, nenhuma = NA_real_) * mult
    a <- a[is.finite(a$disp), ]
    if (!nrow(a)) return(list(antes = antes, depois = depois))
    a$ymin <- para(a$m - a$disp); a$ymax <- para(a$m + a$disp); a$ym <- para(a$m)
    larg <- (mk$chapeu_percentual %||% 1.5) / 100 * diff(info$ax_x$limites)
    depois[[1]] <- geom_errorbar(data = a, aes(x = x, ymin = ymin, ymax = ymax), colour = cor, width = larg, linewidth = .lw(mk$faixa_espessura_pt %||% 1),
                                 linetype = mk$faixa_tipo %||% "solid", inherit.aes = FALSE)
    if (isTRUE(mk$ponto_media)) depois[[2]] <- geom_point(data = a, aes(x = x, y = ym), colour = cor, size = .tx(mk$ponto_tamanho_pt %||% 5), inherit.aes = FALSE)
    return(list(antes = antes, depois = depois))
  }
  v <- if ((mk$eixo %||% "y") == "x") d$x else d$y
  de <- .desc(v); if (is.null(de)) return(list(antes = antes, depois = depois))
  c0 <- switch(centro, media = de$media, mediana = de$mediana, nenhum = de$media)
  lo_hi <- switch(faixa, dp = c(c0 - mult * de$dp, c0 + mult * de$dp), ep = c(c0 - mult * de$ep, c0 + mult * de$ep),
                  ic95 = c(de$ic_inf, de$ic_sup), minmax = c(de$minimo, de$maximo), nenhuma = c(NA, NA))
  nome_f <- switch(faixa, dp = paste0(if (mult != 1) paste0(.nf(mult), " "), .re("dp")), ep = paste0(if (mult != 1) paste0(.nf(mult), " "), .re("ep")),
                   ic95 = .re("ic95"), minmax = paste0(.re("minimo"), "/", .re("maximo")), nenhuma = "")
  horiz <- (mk$eixo %||% "y") == "y"
  conv <- if (horiz) para else identity
  linha <- function(val, esp, tp, rot = NULL, ladoq = 1) {
    cam <- if (horiz) geom_hline(yintercept = conv(val), colour = cor, linewidth = .lw(esp), linetype = tp, alpha = mk$opacidade %||% 1)
           else geom_vline(xintercept = val, colour = cor, linewidth = .lw(esp), linetype = tp, alpha = mk$opacidade %||% 1)
    out <- list(cam)
    if (isTRUE(mk$rotulo %||% TRUE) && !is.null(rot)) {
      tam <- .tx(mk$rotulo_tamanho_pt %||% 8)
      out[[2]] <- if (horiz) annotate("text", x = if (isTRUE(info$flip)) -Inf else Inf, y = conv(val), label = rot, hjust = 1.05, vjust = -0.4, colour = cor, size = tam, family = fonte)
                  else annotate("text", x = val, y = Inf, label = rot, hjust = 1.05, vjust = -0.4, angle = 90, colour = cor, size = tam, family = fonte)
    }
    out
  }
  if (faixa != "nenhuma" && isTRUE(mk$preencher %||% FALSE)) {
    antes[[1]] <- if (horiz) annotate("rect", ymin = conv(lo_hi[1]), ymax = conv(lo_hi[2]), xmin = .janela(info$ax_x)[1], xmax = .janela(info$ax_x)[2], fill = cor, alpha = mk$preencher_opacidade %||% 0.15)
                  else annotate("rect", xmin = lo_hi[1], xmax = lo_hi[2], ymin = .janela(info$ax_y)[1], ymax = .janela(info$ax_y)[2], fill = cor, alpha = mk$preencher_opacidade %||% 0.15)
  }
  if (faixa != "nenhuma") for (k in 1:2) {
    rk <- switch(faixa, dp = , ep = paste0(c("-", "+")[k], nome_f), ic95 = paste0(nome_f, c(" (-)", " (+)")[k]), minmax = c(.re("minimo"), .re("maximo"))[k])
    depois <- c(depois, linha(lo_hi[k], mk$faixa_espessura_pt %||% 0.8, mk$faixa_tipo %||% "dotted", paste0(rk, " = ", .nf(lo_hi[k], casas))))
  }
  if (centro != "nenhum") depois <- c(depois, linha(c0, mk$centro_espessura_pt %||% 1.2, mk$centro_tipo %||% "solid", paste0(.re(centro), " = ", .nf(c0, casas))))
  list(antes = antes, depois = depois)
}
