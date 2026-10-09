# =============================================================================
#  R/06_eixos.R — limites, ticks maiores/menores e rótulos dos eixos
# =============================================================================

# =============================================================================
#  EIXOS: limites, ticks maiores/menores, rótulos
# =============================================================================
# Base do logaritmo da escala (10, e ou 2); NA se a escala não é logarítmica.
.base_log <- function(escala) switch(escala, log10 = 10, ln = exp(1), log2 = 2, NA)

# Transformação de escala do scales (linear, log, 1/x, raiz), com inversão opcional.
.transformacao <- function(escala, inverter) {
  t <- switch(escala,
              linear = scales::transform_identity(),
              log10 = scales::transform_log10(),
              ln = scales::transform_log(),
              log2 = scales::transform_log(2),
              reciproco = scales::transform_reciprocal(),
              raiz = scales::transform_sqrt())
  if (isTRUE(inverter)) t <- scales::transform_compose(t, scales::transform_reverse())
  t
}

# Limites automáticos de um eixo numérico a partir da faixa dos dados (décadas inteiras em log).
.limites_auto <- function(faixa, escala) {
  faixa <- faixa[is.finite(faixa)]
  if (!length(faixa)) return(c(0, 1))
  r <- range(faixa)
  b <- .base_log(escala)
  if (!is.na(b)) {
    r <- r[r > 0]
    if (!length(r)) .erro("Escala logarítmica precisa de valores > 0.")
    r <- range(r)
    lo <- b^floor(log(r[1], b) + 1e-9); hi <- b^ceiling(log(r[2], b) - 1e-9)
    if (lo == hi) { lo <- lo / b; hi <- hi * b }
    return(c(lo, hi))
  }
  if (diff(r) == 0) r <- r + c(-1, 1) * max(abs(r[1]) * 0.1, 1)
  p <- pretty(r, n = 5)
  lim <- range(p)
  if (escala %in% c("raiz") && lim[1] < 0) lim[1] <- 0
  lim
}

# Formata números com ponto decimal, sem zeros sobrando; casas fixas se informado.
.fmt_num <- function(v, casas = NULL, milhar = FALSE) {
  if (!length(v)) return(character(0))
  if (!is.null(casas)) {
    s <- formatC(v, format = "f", digits = casas, big.mark = if (milhar) "," else "",
                 decimal.mark = ".")
  } else {
    fin <- v[is.finite(v)]
    dig <- 0
    if (length(fin)) {
      for (d in 0:10) if (all(abs(round(fin, d) - fin) < 1e-9 * pmax(1, abs(fin)))) { dig <- d; break } else dig <- d
    }
    s <- formatC(v, format = "f", digits = dig, big.mark = if (milhar) "," else "",
                 decimal.mark = ".")
  }
  s[s %in% c("-0", sub("^", "-", formatC(0, format = "f", digits = casas %||% 0)))] <-
    formatC(0, format = "f", digits = casas %||% 0)
  s
}

# Entra: config do eixo. Sai: função que formata os rótulos (notação, casas, prefixo, sufixo, fator).
.formatador <- function(e) {
  casas <- e$casas_decimais
  fator <- e$fator_divisao %||% 1
  pre <- e$prefixo %||% ""; suf <- e$sufixo %||% ""
  notacao <- e$notacao %||% "normal"
  function(x) {
    if (!length(x)) return(character(0))
    na <- is.na(x)
    v <- x / fator
    out <- switch(notacao,
      normal = .fmt_num(v, casas),
      milhar = .fmt_num(v, casas, milhar = TRUE),
      percentual = paste0(.fmt_num(v * 100, casas), "%"),
      cientifica_E = {
        s <- formatC(v, format = "E", digits = casas %||% 1)
        s <- sub("E\\+?(-?)0*([0-9])", "E\\1\\2", s)
        s[v == 0] <- "0"
        if (is.null(casas)) s <- sub("\\.?0+E", "E", s)
        s
      },
      cientifica = , potencia10 = {
        ex <- ifelse(v == 0, 0, floor(log10(abs(v)) + 1e-9))
        m <- v / 10^ex
        expr <- vapply(seq_along(v), function(i) {
          if (is.na(v[i])) return('""')
          if (v[i] == 0) return('"0"')
          mi <- if (is.null(casas)) .fmt_num(round(m[i], 3)) else .fmt_num(m[i], casas)
          if (notacao == "potencia10" && abs(m[i] - round(m[i])) < 1e-9 && round(m[i]) %in% c(1, -1))
            return(paste0(if (m[i] < 0) "-" else "", "10^", ex[i]))
          paste0('"', mi, '"%*%10^', ex[i])
        }, "")
        if (nzchar(pre) || nzchar(suf))
          expr <- paste0(deparse(pre), "*", expr, "*", deparse(suf))
        out <- parse(text = expr)
        return(out)
      }
    )
    out <- paste0(pre, out, suf)
    out[na] <- ""
    out
  }
}

# Calcula a escala de um eixo. Entra: config do eixo (e), valores dos dados (faixa), rótulos das
# categorias (eixo categórico), limites impostos pelos painéis (forcar) e a informação de
# tempo (list(classe, formato) de .detectar_tempo(), para eixo de datas/horas).
# Sai: list(limites, maiores, menores, rotulos, trans, mult, cfg, escala, categorias, tempo).
.calc_eixo <- function(e, faixa, categorias = NULL, forcar = NULL, tempo = NULL) {
  escala <- if (!is.null(categorias)) "linear" else e$escala %||% "linear"
  if (!is.null(tempo) && !identical(escala, "linear"))
    .erro("Eixo de datas/horas exige escala linear (cfg$eixo_x$escala = \"linear\").")
  b <- .base_log(escala)
  if ((!is.na(b) || escala == "reciproco") && is.null(forcar)) {
    ruins <- sum(is.finite(faixa) & faixa <= 0)
    if (ruins && !is.na(b)) .aviso("Escala ", escala, ": ", ruins,
                                   " valor(es) <= 0 não podem ser desenhados e serão omitidos.")
    if (escala == "reciproco" && any(faixa == 0, na.rm = TRUE))
      .aviso("Escala recíproca: valores iguais a 0 (1/0 = infinito) serão omitidos.")
  }
  auto <- if (!is.null(categorias)) c(0.5, length(categorias) + 0.5)
          else if (!is.null(tempo)) .limites_tempo(faixa, tempo$classe)
          else .limites_auto(faixa, escala)
  if (!is.null(forcar)) auto <- forcar
  ini_usuario <- if (!is.null(tempo)) .tempo_num(e$inicio, tempo, "cfg$eixo_x$inicio") else e$inicio
  fim_usuario <- if (!is.null(tempo)) .tempo_num(e$fim, tempo, "cfg$eixo_x$fim") else e$fim
  lo <- ini_usuario %||% auto[1]; hi <- fim_usuario %||% auto[2]
  if (lo >= hi) {
    if (!is.null(tempo) && !is.null(ini_usuario) && !is.null(fim_usuario))
      .erro("cfg$eixo_x$inicio deve ser anterior a cfg$eixo_x$fim.")
    folga <- if (!is.null(tempo)) (if (tempo$classe == "Date") 1 else 3600) else NULL
    if (is.null(ini_usuario)) lo <- hi - (folga %||% (abs(hi) * 0.1 + 1))
    else hi <- lo + (folga %||% (abs(lo) * 0.1 + 1))
  }
  if (!is.na(b) && lo <= 0)
    .erro("Escala logarítmica: o início do eixo deve ser > 0 (atual: ", lo, ").")
  if (escala == "reciproco" && lo <= 0 && hi >= 0)
    .erro("Escala recíproca não pode incluir o zero (", lo, " a ", hi, ").")
  if (escala == "raiz" && lo < 0) .erro("Escala raiz: o início do eixo deve ser >= 0.")
  lim <- c(lo, hi)
  tol <- 1e-9 * max(abs(lim))
  # em escala log a tolerância é relativa (senão 1e-9 "gruda" em 1e-10 num eixo de 10 décadas)
  perto <- function(v, alvo) if (!is.na(b)) abs(v / alvo - 1) <= 1e-9 else abs(v - alvo) <= tol
  dentro <- function(v) if (!is.na(b)) v >= lo * (1 - 1e-9) & v <= hi * (1 + 1e-9) else v >= lo - tol & v <= hi + tol

  modo <- e$ticks_modo %||% "auto"
  if (!is.null(tempo) && modo %in% c("auto", "incremento", "manual")) {
    maiores <- .maiores_tempo(e, lo, hi, tempo, modo)
  } else if (!is.null(categorias) && modo == "auto") {
    maiores <- seq_along(categorias)
  } else if (modo == "auto") {
    maiores <- if (!is.na(b)) {
      ex <- seq(ceiling(log(lo, b) - 1e-9), floor(log(hi, b) + 1e-9))
      if (length(ex) > 8) ex <- ex[ex %% ceiling(length(ex) / 6) == 0]
      if (length(ex) < 2) scales::breaks_log(5, base = b)(lim) else b^ex
    } else if (escala == "reciproco") {
      dec <- 10^(floor(log10(min(abs(lim)))):ceiling(log10(max(abs(lim)))))
      cand <- sort(unique(c(lo, hi, sign(hi) * as.vector(outer(c(1, 1.5, 2, 2.5, 3, 4, 5, 6, 8), dec)))))
      cand <- cand[cand >= lo & cand <= hi & cand != 0]
      alvo <- 1 / seq(1 / hi, 1 / lo, length.out = 6)
      unique(vapply(alvo, function(a) cand[which.min(abs(1 / cand - 1 / a))], 0))
    } else pretty(lim, n = 5)
  } else if (modo == "incremento") {
    if (!is.na(b)) {
      ex0 <- if (!is.null(e$primeiro_tick)) log(e$primeiro_tick, b) else ceiling(log(lo, b) - 1e-9)
      maiores <- b^seq(ex0, log(hi, b) + 1e-9, by = e$incremento)
    } else {
      ini <- e$primeiro_tick %||% lo
      n <- floor((hi - ini) / e$incremento + 1e-9)
      if (n > 1000) .erro("incremento muito pequeno: geraria ", n, " ticks.")
      maiores <- round(ini + (0:max(n, 0)) * e$incremento, 12)
    }
  } else if (modo == "quantidade") {
    maiores <- if (!is.na(b)) exp(seq(log(lo), log(hi), length.out = e$quantidade))
               else seq(lo, hi, length.out = e$quantidade)
  } else if (modo == "min_max") {
    maiores <- lim
  } else {
    maiores <- e$ticks_manuais
  }
  .ajustar <- function(v) {
    v <- signif(v, 12)
    v[perto(v, lo)] <- lo; v[perto(v, hi)] <- hi
    v
  }
  maiores <- .ajustar(maiores)
  if (modo != "manual") maiores <- maiores[dentro(maiores)]

  # ticks menores
  nm <- if (!is.null(categorias)) 0 else e$n_menores %||% 0
  menores <- NULL
  mm <- sort(unique(maiores))
  if (nm > 0 && length(mm) >= 2) {
    entre <- function(a, z) a + (seq_len(nm)) * (z - a) / (nm + 1)
    menores <- unlist(lapply(seq_len(length(mm) - 1), function(i) entre(mm[i], mm[i + 1])))
    if (!is.na(b) || escala == "reciproco") {
      r1 <- mm[2] / mm[1]; r2 <- mm[length(mm)] / mm[length(mm) - 1]
      ext <- c(entre(mm[1] / r1, mm[1]), entre(mm[length(mm)], mm[length(mm)] * r2))
    } else {
      d1 <- mm[2] - mm[1]; d2 <- mm[length(mm)] - mm[length(mm) - 1]
      ext <- c(unlist(lapply(1:20, function(k) entre(mm[1] - k * d1, mm[1] - (k - 1) * d1))),
               unlist(lapply(1:20, function(k) entre(mm[length(mm)] + (k - 1) * d2, mm[length(mm)] + k * d2))))
    }
    menores <- .ajustar(c(menores, ext))
    menores <- menores[dentro(menores)]
  }

  rotulos <- if (!is.null(e$rotulos_manuais)) as.character(e$rotulos_manuais)
             else if (!is.null(categorias) && modo == "auto") categorias
             else if (!is.null(tempo)) .formatador_tempo(e, tempo$classe, lim, maiores)
             else .formatador(e)
  # painéis colados: esconde o número que encosta no painel vizinho
  ocultar <- e$.ocultar_extremo
  if (!is.null(ocultar)) {
    alvo <- if (identical(ocultar, "max")) hi else lo
    if (is.function(rotulos)) {
      f0 <- rotulos
      rotulos <- function(x) {
        r <- f0(x); sel <- !is.na(x) & perto(x, alvo)
        if (is.expression(r)) { r <- as.list(r); r[sel] <- list(""); return(as.expression(r)) }
        r[sel] <- ""; r
      }
    } else if (is.character(rotulos) && is.null(categorias) && length(rotulos) == length(maiores)) {
      rotulos[perto(maiores, alvo)] <- ""      # rótulos manuais: esconde o do extremo
    }
  }
  list(limites = lim, maiores = maiores, menores = menores %||% numeric(0),
       rotulos = rotulos, trans = .transformacao(escala, e$inverter),
       mult = (e$margem_percentual %||% 0) / 100, cfg = e, escala = escala,
       categorias = categorias, tempo = tempo)
}

# posição (0-1 no painel) de valores num eixo calculado
.npc <- function(v, ax) {
  tl <- sort(ax$trans$transform(ax$limites))
  r <- tl + c(-1, 1) * diff(tl) * ax$mult
  (ax$trans$transform(v) - r[1]) / diff(r)
}
