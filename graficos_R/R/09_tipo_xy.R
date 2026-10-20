# =============================================================================
#  R/09_tipo_xy.R — pontos, linhas e áreas
# =============================================================================

# ---- Pontos / linhas / áreas --------------------------------------------------
# Opções de aparência do eixo Y2 que, vazias (NULL), seguem o eixo Y.
.Y2_ESTILO <- c("direcao_maiores", "direcao_menores", "comprimento_maiores_pt", "comprimento_menores_pt", "espessura_ticks_pt",
                "cor_ticks", "mostrar_linha", "espessura_linha_pt", "cor_linha", "mostrar_rotulos", "tamanho_rotulos_pt",
                "cor_rotulos", "negrito_rotulos", "rotacao_rotulos", "mostrar_titulo", "tamanho_titulo_pt", "cor_titulo",
                "negrito_titulo", "italico_titulo", "distancia_rotulos_pt", "distancia_titulo_pt", "rotacao_titulo")

# Config do eixo Y2: a do eixo Y com o que o eixo_y2 define por cima (limites, ticks, formato). O divisor
# dos números (fator_divisao) é o do eixo_y2 se existir; senão herda o do eixo_y, como sempre foi.
# Limites, ticks e formato vazios no Y2 significam "automático" (não herdam os do Y); a aparência e a folga vazias herdam.
.eixo_y2_efetivo <- function(cfg) {
  sobre <- cfg$eixo_y2[intersect(names(cfg$eixo_y2), names(cfg$eixo_y))]
  herda <- names(sobre) %in% c(.Y2_ESTILO, "margem_percentual") & vapply(sobre, is.null, NA)
  e2 <- utils::modifyList(cfg$eixo_y, sobre[!herda])
  e2$fator_divisao <- cfg$eixo_y2$fator_divisao %||% cfg$eixo_y$fator_divisao
  e2$escala <- "linear"; e2$inverter <- FALSE
  e2
}
# Aparência do eixo Y2 (ticks, linha, números, título): a do eixo vertical `ev` com o que o eixo_y2 preencher por cima.
.estilo_y2 <- function(cfg, ev) {
  sobre <- cfg$eixo_y2[intersect(.Y2_ESTILO, names(cfg$eixo_y2))]
  sobre <- sobre[!vapply(sobre, is.null, NA)]
  out <- utils::modifyList(ev, sobre)
  out$mostrar_rotulos <- sobre$mostrar_rotulos %||% TRUE                       # sem pedir nada, o Y2 sempre mostra números e título
  out$mostrar_titulo <- if (isTRUE(cfg$.interno$sem_titulo_y2)) FALSE else (sobre$mostrar_titulo %||% TRUE)
  out
}
# Cores de cada parte do eixo Y2: a própria (cor_ticks, cor_rotulos...) ou, se vazia, a cor do eixo (cor_eixo / da série).
.cores_y2 <- function(cfg, cor_eixo) {
  e <- cfg$eixo_y2
  list(ticks = .cor(e$cor_ticks) %||% cor_eixo, rotulos = .cor(e$cor_rotulos) %||% cor_eixo,
       titulo = .cor(e$cor_titulo) %||% cor_eixo, linha = .cor(e$cor_linha) %||% cor_eixo)
}
# Avisa quantos pontos saem do gráfico por não existirem na escala do eixo (<= 0 em log, 0 em 1/x).
.avisar_omitidos <- function(n, eixo, escala) {
  if (n > 0)
    .aviso("Eixo ", eixo, " em escala ", escala, ": ", n, " ponto(s) com valor ",
           if (identical(escala, "reciproco")) "igual a 0" else "<= 0",
           " não existe(m) nessa escala e foi(ram) omitido(s) do gráfico.")
}

# Decide se a coluna X de texto é um eixo de datas (cfg$eixo_x$tempo = "auto", TRUE ou FALSE).
# Sai: NULL (eixo categórico) ou o resultado de .detectar_tempo().
.tempo_do_eixo <- function(v, e) {
  modo <- e$tempo %||% "auto"
  if (identical(modo, FALSE)) return(NULL)
  d <- .detectar_tempo(v, e$formato_data)
  if (is.null(d) && isTRUE(modo))
    .erro("cfg$eixo_x$tempo = TRUE, mas a coluna X não é reconhecida como data. ",
          "Defina cfg$eixo_x$formato_data (ex.: \"%d/%m/%Y %H:%M\").")
  d
}

# Pontos, linhas e áreas. Entra: dados e cfg. Sai: list(camadas, info) com os eixos já calculados.
.construir_xy <- function(dados, cfg) {
  tipo <- cfg$grafico$tipo; L <- cfg$linhas
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  cats <- NULL; tempo <- NULL
  if (!is.numeric(dados[[xcol]])) {
    d_tempo <- .tempo_do_eixo(dados[[xcol]], cfg$eixo_x)
    if (!is.null(d_tempo)) {                     # coluna de datas/horas: eixo temporal
      dados[[xcol]] <- d_tempo$num
      tempo <- d_tempo[c("classe", "formato")]
    } else {                                     # texto: eixo categórico
      cats <- unique(as.character(dados[[xcol]][!is.na(dados[[xcol]])]))
      dados[[xcol]] <- match(as.character(dados[[xcol]]), cats)
    }
  }
  est <- .estilos(cfg, ycols)
  mc <- if (!is.null(cfg$cores$mapear_coluna)) .coluna(dados, cfg$cores$mapear_coluna,
                                                       "cfg$cores$mapear_coluna") else NULL
  if (!is.null(mc) && !is.numeric(dados[[mc]])) .erro("cfg$cores$mapear_coluna: a coluna '", mc,
                                                      "' precisa ser numérica.")
  d <- .serie_longa(dados, xcol, ycols, est, mc)
  invalido <- function(v, esc) if (!is.na(.base_log(esc %||% "linear"))) !is.na(v) & v <= 0
                               else if (identical(esc, "reciproco")) !is.na(v) & v == 0 else rep(FALSE, length(v))
  if (is.null(cats)) {
    inv_x <- invalido(d$x, cfg$eixo_x$escala)
    .avisar_omitidos(sum(inv_x), "X", cfg$eixo_x$escala)
    d$x[inv_x] <- NA
  }
  inv_y <- invalido(d$y, cfg$eixo_y$escala)
  .avisar_omitidos(sum(inv_y), "Y", cfg$eixo_y$escala)
  d$y[inv_y] <- NA
  d <- d[!is.na(d$x), ]
  d$serie <- factor(d$serie, levels = ycols)
  if (isTRUE(L$ordenar_x)) d <- d[order(d$serie, d$x), ]

  usa_y2 <- isTRUE(cfg$eixo_y2$ativo) && identical(cfg$eixo_y2$modo, "independente")
  ser_y2 <- if (usa_y2) ycols[vapply(est, function(e) identical(e$eixo, "y2"), logical(1))] else character(0)
  # quebra de eixo sem ligar através: cada série só mostra os valores desta parte (Y1 e Y2 têm faixas próprias)
  rec <- cfg$.interno$recortar_y; rec2 <- cfg$.interno$recortar_y2 %||% rec
  if (!is.null(rec)) {
    r <- if (length(ser_y2)) { e2 <- d$serie %in% ser_y2; list(lo = ifelse(e2, rec2[1], rec[1]),
                                                               hi = ifelse(e2, rec2[2], rec[2])) }
         else list(lo = rec[1], hi = rec[2])
    d <- d[is.na(d$y) | (d$y >= r$lo & d$y <= r$hi), ]
  }
  if (usa_y2 && !length(ser_y2))
    .erro("eixo_y2 ativo no modo \"independente\", mas nenhuma série tem eixo = \"y2\".\n",
          "  Ex.: cfg$series[[\"", ycols[length(ycols)], "\"]] <- list(eixo = \"y2\")")

  com_pontos <- tipo %in% c("pontos", "linha_pontos")
  com_linha <- tipo %in% c("linha", "linha_pontos", "area", "area_empilhada")
  preench <- L$preencher_area
  if (tipo == "area" && preench == "nenhum") preench <- "ate_zero"

  # empilhamento
  if (tipo == "area_empilhada") {
    if (usa_y2) .erro("area_empilhada não combina com eixo_y2.")
    larga <- stats::reshape(d[, c("x", "y", "serie")], idvar = "x", timevar = "serie", direction = "wide")
    larga <- larga[order(larga$x), ]
    acum <- 0
    pilha <- list()
    for (s in ycols) {
      v <- larga[[paste0("y.", s)]]; v[is.na(v)] <- 0
      pilha[[s]] <- data.frame(x = larga$x, ymin = acum, y = acum + v, serie = s)
      acum <- acum + v
    }
    d <- do.call(rbind, pilha); d$serie <- factor(d$serie, levels = ycols)
    d$e_inf <- d$e_sup <- d$e_x <- NA_real_
  }

  # faixa de dados para Y1 e Y2
  d1 <- d[!d$serie %in% ser_y2, ]
  faixa_y <- c(d1$y, d1$y - d1$e_inf, d1$y + d1$e_sup, if (tipo == "area_empilhada") 0,
               if (preench == "ate_zero") 0)
  faixa_x <- c(d$x, d$x - d$e_x, d$x + d$e_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  ax_x <- .calc_eixo(cfg$eixo_x, faixa_x, categorias = cats, forcar = cfg$.interno$forcar_x, tempo = tempo)

  y2 <- NULL
  if (usa_y2) {
    if (ax_y$escala != "linear") .erro("eixo_y2 \"independente\" exige eixo_y linear.")
    d2 <- d[d$serie %in% ser_y2, ]
    e2 <- .eixo_y2_efetivo(cfg)
    ax2 <- .calc_eixo(e2, c(d2$y, d2$y - d2$e_inf, d2$y + d2$e_sup))
    l1 <- ax_y$limites; l2 <- ax2$limites
    para1 <- function(v) l1[1] + (v - l2[1]) * diff(l1) / diff(l2)
    para2 <- function(v) l2[1] + (v - l1[1]) * diff(l2) / diff(l1)
    sel <- d$serie %in% ser_y2
    d$y[sel] <- para1(d$y[sel])
    d$e_inf[sel] <- d$e_inf[sel] * diff(l1) / diff(l2)
    d$e_sup[sel] <- d$e_sup[sel] * diff(l1) / diff(l2)
    y2 <- list(ax = ax2, para2 = para2, para1 = para1,
               titulo = cfg$eixo_y2$titulo %||% paste(ser_y2, collapse = ", "),
               cor = if (identical(cfg$eixo_y2$cor_eixo, "serie")) est[[ser_y2[1]]]$cor else cfg$eixo_y2$cor_eixo)
  }

  cam <- list()
  mapa <- !is.null(cfg$cores$mapear_coluna) && com_pontos
  # áreas
  if (preench != "nenhum" || tipo == "area_empilhada") {
    base_y <- 0
    if (preench == "ate_base") base_y <- ax_y$limites[if (isTRUE(cfg$eixo_y$inverter)) 2 else 1]
    for (i in seq_along(ycols)) {
      s <- ycols[i]; ds <- d[d$serie == s, ]; ds <- ds[order(ds$x), ]
      if (!nrow(ds)) next
      if (tipo == "area_empilhada") {
        rib <- data.frame(x = ds$x, ymin = ds$ymin, ymax = ds$y)
      } else if (preench == "proxima_serie") {
        if (i == length(ycols)) next
        prox <- d[d$serie == ycols[i + 1], ]
        yb <- stats::approx(prox$x, prox$y, xout = ds$x, rule = 2)$y
        rib <- data.frame(x = ds$x, ymin = pmin(ds$y, yb), ymax = pmax(ds$y, yb))
      } else rib <- data.frame(x = ds$x, ymin = base_y, ymax = ds$y)
      e <- est[[s]]
      a_area <- if (tipo == "area_empilhada") e$opf else L$opacidade_area
      fill <- if (identical(cfg$cores$preenchimento, "gradiente"))
        .gradiente(.alfa(e$cor, a_area), .alfa(e$cor2, a_area), cfg$cores$gradiente_direcao, FALSE)
        else .alfa(e$cor, a_area)
      cam[[length(cam) + 1]] <- geom_ribbon(data = rib, aes(x = x, ymin = ymin, ymax = ymax),
                                            fill = fill, colour = NA, inherit.aes = FALSE)
    }
  }
  # linhas de queda
  if (L$linhas_queda != "nenhuma") {
    bx <- if (isTRUE(cfg$eixo_x$inverter)) ax_x$limites[2] else ax_x$limites[1]
    by <- if (isTRUE(cfg$eixo_y$inverter)) ax_y$limites[2] else ax_y$limites[1]
    if (L$linhas_queda %in% c("vertical", "ambas"))
      cam[[length(cam) + 1]] <- geom_segment(data = d, aes(x = x, xend = x, y = y, yend = by, colour = serie),
        linetype = L$linhas_queda_tipo, linewidth = .lw(L$linhas_queda_espessura_pt), show.legend = FALSE)
    if (L$linhas_queda %in% c("horizontal", "ambas"))
      cam[[length(cam) + 1]] <- geom_segment(data = d, aes(x = x, xend = bx, y = y, yend = y, colour = serie),
        linetype = L$linhas_queda_tipo, linewidth = .lw(L$linhas_queda_espessura_pt), show.legend = FALSE)
  }
  # barras de erro
  de <- d[!is.na(d$e_inf) | !is.na(d$e_sup), ]
  if (nrow(de)) {
    larg <- if (ax_x$escala == "linear") L$erro_chapeu_percentual / 100 * diff(ax_x$limites) else 0
    de$ymin <- if (L$erro_lado == "superior") de$y else de$y - de$e_inf
    de$ymax <- if (L$erro_lado == "inferior") de$y else de$y + de$e_sup
    cam[[length(cam) + 1]] <- geom_errorbar(data = de, aes(x = x, ymin = ymin, ymax = ymax, colour = serie),
      width = larg, linewidth = .lw(L$erro_espessura_pt), show.legend = FALSE, inherit.aes = FALSE)
  }
  dx <- d[!is.na(d$e_x), ]
  if (nrow(dx)) {
    alt <- if (ax_y$escala == "linear") L$erro_chapeu_percentual / 100 * diff(ax_y$limites) else 0
    cam[[length(cam) + 1]] <- geom_errorbar(data = dx, aes(y = y, xmin = x - e_x, xmax = x + e_x, colour = serie),
      width = alt, orientation = "y", linewidth = .lw(L$erro_espessura_pt), show.legend = FALSE, inherit.aes = FALSE)
  }
  aes_leg <- character(0)
  # linhas
  if (com_linha) {
    if (mapa) {
      for (s in ycols) cam[[length(cam) + 1]] <- .camada_linha(d[d$serie == s, ], L$ligacao, mapeado = FALSE,
                                                               e = est[[s]])
    } else {
      cam[[length(cam) + 1]] <- .camada_linha(d, L$ligacao, mapeado = TRUE, cfg = cfg)
      aes_leg <- c(aes_leg, "colour", "linetype", "linewidth", "alpha")
    }
  }
  # pontos
  if (com_pontos) {
    if (mapa) {
      cam[[length(cam) + 1]] <- geom_point(data = d, aes(x = x, y = y, colour = mapa, fill = mapa,
                                                         shape = serie, size = serie, stroke = serie),
                                                  na.rm = TRUE)   # células vazias: sem aviso em inglês
      aes_leg <- unique(c(aes_leg, "shape", "size", "stroke"))
    } else {
      esf <- ycols[vapply(est[ycols], function(e) isTRUE(e$simbolo == .COD_ESFERA), NA)]   # séries "esfera"
      if (length(setdiff(ycols, esf)))
      cam[[length(cam) + 1]] <- geom_point(data = d[!d$serie %in% esf, ],
                                           aes(x = x, y = y, colour = serie, fill = serie,
                                                         shape = serie, size = serie, stroke = serie, alpha = serie),
        show.legend = TRUE, na.rm = TRUE, key_glyph = .key_escala(.draw_key_ponto_ou_nada, cfg))   # na.rm: células vazias sem aviso
      if (length(esf))
        cam[[length(cam) + 1]] <- geom_esfera(data = d[d$serie %in% esf, ], luz = cfg$serie_padrao$esfera_luz,
          mapping = aes(x = x, y = y, colour = serie, shape = serie, size = serie, stroke = serie), show.legend = TRUE,
          key_glyph = .key_escala(.draw_key_esfera, cfg))
      aes_leg <- unique(c(aes_leg, "colour", "shape", "size", "stroke",
                          if (length(setdiff(ycols, esf))) c("fill_simb",
                                                             "alpha")))   # só esferas: sem escalas de fill/alpha
    }
  }
  # rótulos de dados
  if (L$rotulos_dados != "nenhum") {
    dd <- d
    if (usa_y2) { sel <- dd$serie %in% ser_y2; dd$yv <- dd$y; dd$yv[sel] <- y2$para2(dd$y[sel]) } else dd$yv <- dd$y
    xv <- if (!is.null(cats)) cats[dd$x]
          else if (!is.null(tempo)) .formatador_tempo(cfg$eixo_x, tempo$classe, ax_x$limites, ax_x$maiores)(dd$x)
          else .fmt_num(dd$x, L$rotulos_casas)
    dd$rot <- switch(L$rotulos_dados,
                     y = .fmt_num(dd$yv, L$rotulos_casas), x = xv,
                     xy = paste0("(", xv, ", ", .fmt_num(dd$yv, L$rotulos_casas), ")"),
                     serie = as.character(dd$serie))
    k <- L$rotulos_deslocamento_pt / L$rotulos_tamanho_pt
    cam[[length(cam) + 1]] <- geom_text(data = dd, aes(x = x, y = y, label = rot, colour = serie),
      size = .tx(L$rotulos_tamanho_pt), vjust = if (k >= 0) -k else 1 - k, show.legend = FALSE,
      family = .fonte(cfg$texto$fonte), fontface = if (.neg(cfg)) "bold" else "plain")
  }
  usa_cor <- com_linha || nrow(de) || L$linhas_queda != "nenhuma" || L$rotulos_dados != "nenhum"
  if (!"colour" %in% aes_leg && !mapa && usa_cor) aes_leg <- c(aes_leg, "colour")
  escalas <- .escalas_legenda(est, aes_leg, cfg)
  if (mapa) escalas <- c(escalas, .escala_mapa(cfg, dados))
  if (!com_pontos && !com_linha) escalas <- c(escalas, list(guides(fill = "none")))

  titulo_y <- cfg$eixo_y$titulo %||% (if (length(setdiff(ycols, ser_y2)) == 1) setdiff(ycols, ser_y2) else "Y")
  list(camadas = c(cam, escalas),
       info = list(ax_x = ax_x, ax_y = ax_y, y2 = y2, flip = FALSE,
                   titulo_x = cfg$eixo_x$titulo %||% xcol, titulo_y = titulo_y,
                   legenda_auto = TRUE, faixa_x = faixa_x, faixa_y = faixa_y))
}

# Camada de linha (reta, spline ou degrau) de uma série ou de todas, com estilo mapeado ou fixo.
.camada_linha <- function(d, ligacao, mapeado, e = NULL, cfg = NULL) {
  d <- d[!is.na(d$y), ]
  if (ligacao == "spline") {
    niveis <- levels(d$serie)
    partes <- lapply(split(d, d$serie, drop = TRUE), function(s) {
      nm <- as.character(s$serie[1])
      s <- stats::aggregate(y ~ x, data = s, FUN = mean)
      if (nrow(s) < 3) return(data.frame(x = s$x, y = s$y, serie = nm))
      sp <- stats::spline(s$x, s$y, n = max(200, 10 * nrow(s)), method = "fmm")
      data.frame(x = sp$x, y = sp$y, serie = nm)
    })
    d <- do.call(rbind, partes)
    d$serie <- factor(d$serie, levels = niveis)
  }
  geo <- switch(ligacao, reta = geom_path, spline = geom_path,
                degrau_hv = function(...) geom_step(..., direction = "hv"),
                degrau_vh = function(...) geom_step(..., direction = "vh"),
                degrau_meio = function(...) geom_step(..., direction = "mid"))
  if (mapeado) {
    geo(data = d, aes(x = x, y = y, colour = serie, linetype = serie, linewidth = serie,
                      alpha = serie, group = serie), lineend = "round", linejoin = "round",
        show.legend = TRUE,   # TRUE: a legenda mostra a série mesmo sem dados nesta camada (quebra de eixo)
        key_glyph = if (is.null(cfg)) "path" else .key_escala(ggplot2::draw_key_path, cfg))
  } else {
    geo(data = d, aes(x = x, y = y), colour = .alfa(e$cor, e$op), linetype = e$lt,
        linewidth = .lw(e$lw), lineend = "round", linejoin = "round")
  }
}

# Escala e barra de cores para o mapa de cor por coluna numérica (2 ou 3 cores).
.escala_mapa <- function(cfg, dados) {
  c0 <- cfg$cores
  tit <- c0$mapa_titulo %||% c0$mapear_coluna
  guia <- guide_colourbar(title = if (identical(tit, "")) NULL else .texto(tit))
  cores <- vapply(c0$mapa_cores, .cor, "", onde = "cores$mapa_cores")
  if (length(cores) >= 3) {
    mc <- dados[[c0$mapear_coluna]]
    meio <- c0$mapa_ponto_medio %||% mean(range(mc, na.rm = TRUE))
    sc <- scale_colour_gradient2(low = cores[1], mid = cores[2], high = cores[3], midpoint = meio,
                                 limits = c0$mapa_limites, aesthetics = c("colour", "fill"),
                                 guide = guia, labels = .formatador(list()))
  } else {
    sc <- scale_colour_gradient(low = cores[1], high = cores[2], limits = c0$mapa_limites,
                                aesthetics = c("colour", "fill"), guide = guia,
                                labels = .formatador(list()))
  }
  list(sc)
}
