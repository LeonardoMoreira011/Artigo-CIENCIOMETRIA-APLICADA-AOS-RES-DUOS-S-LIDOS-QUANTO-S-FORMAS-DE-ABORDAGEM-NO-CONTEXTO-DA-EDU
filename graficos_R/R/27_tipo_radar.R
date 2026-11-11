# =============================================================================
#  R/27_tipo_radar.R — radar (teia de aranha)
# =============================================================================
#  Planilha: a 1ª coluna (cfg$grafico$coluna_x) traz o nome de cada série; as outras colunas numéricas (ou cfg$grafico$colunas_y) são os eixos do radar (3 ou mais).
#  Cada linha vira um polígono. As cores e a legenda seguem a paleta e as opções de série, como nos outros gráficos. Opções em cfg$radar.
# =============================================================================

# Entra: dados e cfg. Sai: list(camadas, info) (info$mapa = TRUE: o gráfico é desenhado em coordenadas próprias, sem eixos comuns).
.construir_radar <- function(dados, cfg) {
  R <- cfg$radar; G <- cfg$grafico
  xcol <- .coluna(dados, G$coluna_x %||% 1, "cfg$grafico$coluna_x")
  eixos <- .colunas_y(dados, cfg, excluir = xcol)
  if (length(eixos) < 3) .erro("O radar precisa de pelo menos 3 colunas numéricas: cada coluna é um eixo do radar e cada linha da planilha é uma série (o nome dela fica na 1ª coluna).")
  nomes <- as.character(dados[[xcol]])
  if (anyDuplicated(nomes)) { .aviso("Nomes repetidos em '", xcol, "': acrescentei números para diferenciar as séries."); nomes <- make.unique(nomes) }
  V <- as.matrix(dados[eixos]); storage.mode(V) <- "double"; K <- length(eixos); ns <- nrow(V)
  if (isTRUE(R$normalizar))
    V <- apply(V, 2, function(v) { r <- range(v, na.rm = TRUE); if (!all(is.finite(r)) || diff(r) == 0) v * 0 + 0.5 else (v - r[1]) / diff(r) })
  if (!is.matrix(V)) V <- matrix(V, ns)
  if (all(is.na(V))) .erro("Não há valores numéricos para desenhar no radar.")
  rmin <- R$anel_min %||% min(0, min(V, na.rm = TRUE)); rmax <- R$anel_max %||% max(V, na.rm = TRUE)
  br <- pretty(c(rmin, rmax), n = R$aneis %||% 5)
  if (is.null(R$anel_min)) rmin <- min(br); if (is.null(R$anel_max)) rmax <- max(br)
  if (rmax <= rmin) .erro("O radar precisa de valores diferentes entre si (a escala vai de ", rmin, " a ", rmax, ").")
  aneis <- br[br >= rmin - 1e-9 & br <= rmax + 1e-9]
  fora <- sum(is.finite(V) & (V < rmin - 1e-9 | V > rmax + 1e-9))
  if (fora) .aviso(fora, " valor(es) fora da escala do radar (", rmin, " a ", rmax, ") foram encostados na borda.")
  if (anyNA(V)) .aviso("Células vazias no radar foram desenhadas no centro (valor mínimo da escala).")
  rn <- function(v) { v[!is.finite(v)] <- rmin; pmin(pmax((v - rmin) / (rmax - rmin), 0), 1) }
  dir <- if (identical(R$sentido, "antihorario")) -1 else 1
  th <- ((R$angulo_inicial %||% 0) + dir * 360 * (seq_len(K) - 1) / K) * pi / 180
  fonte <- .fonte(cfg$texto$fonte); pt_r <- R$rotulos_tamanho_pt %||% cfg$texto$tamanho_base_pt
  cor_grade <- .cor(R$grade_cor %||% "#BDBDBD"); lw_grade <- .lw(R$grade_espessura_pt %||% 0.5)
  cam <- list()
  # grade: anéis (polígono ou círculo) e os eixos
  rr <- (aneis - rmin) / (rmax - rmin); rr <- rr[rr > 1e-9]
  if (length(rr)) {
    circ <- identical(R$formato_grade, "circulo"); ang <- if (circ) seq(0, 2 * pi, length.out = 181) else c(th, th[1])
    g <- do.call(rbind, lapply(seq_along(rr), function(i) data.frame(x = rr[i] * sin(ang), y = rr[i] * cos(ang), grp = i)))
    cam[[length(cam) + 1]] <- geom_path(data = g, aes(x = x, y = y, group = grp), colour = cor_grade, linewidth = lw_grade)
  }
  cam[[length(cam) + 1]] <- geom_segment(data = data.frame(x = 0, y = 0, xend = sin(th), yend = cos(th)), aes(x = x, y = y, xend = xend, yend = yend), colour = cor_grade, linewidth = lw_grade)
  # séries
  est <- .estilos(cfg, nomes)
  pol <- do.call(rbind, lapply(seq_len(ns), function(i) { r <- rn(V[i, ]); data.frame(x = c(r * sin(th), r[1] * sin(th[1])), y = c(r * cos(th), r[1] * cos(th[1])), serie = nomes[i]) }))
  pol$serie <- factor(pol$serie, levels = nomes)
  op <- R$preencher_opacidade %||% 0.25
  cam[[length(cam) + 1]] <- geom_polygon(data = pol, aes(x = x, y = y, group = serie, fill = serie, colour = serie), alpha = op, linewidth = .lw(R$linha_espessura_pt %||% 1.2))
  if (isTRUE(R$pontos %||% TRUE)) {
    pp <- do.call(rbind, lapply(seq_len(ns), function(i) { r <- rn(V[i, ]); data.frame(x = r * sin(th), y = r * cos(th), serie = nomes[i]) })); pp$serie <- factor(pp$serie, levels = nomes)
    cam[[length(cam) + 1]] <- geom_point(data = pp, aes(x = x, y = y, colour = serie), size = .tx(R$ponto_tamanho_pt %||% 4), show.legend = FALSE)
  }
  # nomes dos eixos e valores dos anéis; o tamanho do texto é fixo em pontos, então os limites do desenho se ajustam ao espaço que ele ocupa (duas passadas)
  rot_r <- 1.09; sx <- sin(th); cy <- cos(th)
  lab <- data.frame(x = rot_r * sx, y = rot_r * cy, rot = eixos, hj = ifelse(sx > 0.25, 0, ifelse(sx < -0.25, 1, 0.5)), vj = ifelse(cy > 0.25, 0, ifelse(cy < -0.25, 1, 0.5)))
  cam[[length(cam) + 1]] <- geom_text(data = lab, aes(x = x, y = y, label = rot, hjust = hj, vjust = vj), size = .tx(pt_r), colour = .cor(cfg$texto$cor), family = fonte,
                                      fontface = if (.neg(cfg)) "bold" else "plain", lineheight = 0.9)
  if (isTRUE(R$rotulos_aneis %||% TRUE) && length(rr)) {
    va <- data.frame(x = rr * sin(th[1]) + 0.025, y = rr * cos(th[1]), rot = .fmt_num(aneis[(aneis - rmin) / (rmax - rmin) > 1e-9], R$rotulos_casas))
    cam[[length(cam) + 1]] <- geom_text(data = va, aes(x = x, y = y, label = rot), size = .tx(pt_r * 0.8), colour = .cor(cfg$texto$cor), family = fonte, hjust = 0, vjust = 0.5)
  }
  larg_in <- function(txt) max(nchar(strsplit(txt, "\n", fixed = TRUE)[[1]]), 1) * pt_r * 0.52 / 72
  pw_in <- (cfg$caixa$painel_largura_cm %||% 12) / 2.54; wl <- vapply(eixos, larg_in, 0)
  lim_x <- c(-1.2, 1.2)
  for (k in 1:3) {
    upi <- diff(lim_x) / pw_in
    ex <- c(lab$x - ifelse(lab$hj == 1, wl * upi, ifelse(lab$hj == 0.5, wl * upi / 2, 0)), lab$x + ifelse(lab$hj == 0, wl * upi, ifelse(lab$hj == 0.5, wl * upi / 2, 0)))
    lim_x <- range(c(ex, -1, 1)) + c(-0.03, 0.03) * upi * 2
  }
  upi <- diff(lim_x) / pw_in; alt <- pt_r / 72 * upi
  lim_y <- range(c(lab$y + ifelse(lab$vj == 0, alt * 1.2, ifelse(lab$vj == 1, -alt * 1.2, 0)), -1, 1)) + c(-0.03, 0.03)
  # a figura é quadrada em unidades: iguala os dois lados para o círculo não ficar achatado
  cx <- mean(lim_x); cyy <- mean(lim_y); meia <- max(diff(lim_x), diff(lim_y)) / 2
  list(camadas = c(cam, .escalas_legenda(est, c("colour", "fill"), cfg)),
       info = list(mapa = TRUE, xlim = c(cx - meia, cx + meia), ylim = c(cyy - meia, cyy + meia), legenda_auto = ns > 1, flip = FALSE))
}
