# =============================================================================
#  R/15_quebra_continua.R — quebra de eixo CONTÍNUA (estilo Origin): uma moldura só
# =============================================================================
#  As duas partes ficam coladas dentro de UMA moldura. Nas bordas esquerda e direita, no ponto da
#  quebra, a linha é interrompida e aparecem duas barras "//". É montada com o gtable (que já vem
#  com o ggplot2), pois o patchwork não sabe desenhar uma moldura que atravessa dois gráficos.
# =============================================================================

# Entra: as duas partes (ggplot), cfg, cfg$quebra, a proporção da parte de cima (0 a 1), o estilo (continuo: TRUE) e os
#   títulos laterais (título do Y e info do Y2).
# Sai: um elemento do patchwork com as duas partes empilhadas (gtable). No estilo contínuo ficam coladas, com uma moldura
#   só; no separado cada uma tem a sua moldura. Os títulos dos eixos Y ficam ao lado, à distância pedida dos números.
#   O gtable também vai no atributo "gt" (usado para fixar o tamanho do gráfico).
.quebra_montar <- function(gs, gi, cfg, Q, pr, continuo, tit_y1 = NULL, y2 = NULL) {
  if (!requireNamespace("gtable",
                        quietly = TRUE)) .erro("A quebra de eixo precisa do pacote gtable (vem com o ggplot2).")
  zero <- unit(0, "pt")
  if (is.null(grDevices::dev.list())) {           # ggplotGrob() precisa de um dispositivo: usa um descartável, sem arquivo
    dtmp <- .abrir_dispositivo_tmp(); on.exit(grDevices::dev.off(dtmp), add = TRUE)
  }
  if (continuo) {
    # a moldura e as linhas dos eixos são desenhadas por cima (um traço só); aqui somem as de cada parte
    sem_linhas <- theme(panel.border = element_blank(), axis.line.x.bottom = element_blank(),
                        axis.line.x.top = element_blank(), axis.line.y.left = element_blank(),
                        axis.line.y.right = element_blank())
    gs <- gs + sem_linhas + theme(axis.ticks.x.bottom = element_blank(), axis.ticks.length.x.bottom = zero,
                                  axis.minor.ticks.x.bottom = element_blank(), axis.minor.ticks.length.x.bottom = zero)
    gi <- gi + sem_linhas + theme(axis.ticks.x.top = element_blank(), axis.ticks.length.x.top = zero,
                                  axis.minor.ticks.x.top = element_blank(), axis.minor.ticks.length.x.top = zero,
                                  axis.text.x.top = element_blank(), axis.title.x.top = element_blank())
  }
  ts <- ggplot2::ggplotGrob(gs); ti <- ggplot2::ggplotGrob(gi)
  # legenda à direita/esquerda existe só na parte de cima: dá à de baixo as mesmas colunas, vazias
  falta <- ncol(ts) - ncol(ti)
  if (falta > 0) {
    ti <- if (identical(cfg$legenda$posicao, "esquerda"))
      gtable::gtable_add_cols(ti, ts$widths[seq_len(falta)], pos = 0)
    else gtable::gtable_add_cols(ti, ts$widths[(ncol(ti) + 1):ncol(ts)], pos = -1)
  }
  if (ncol(ts) != ncol(ti)) .erro("Quebra de eixo: as duas partes ficaram com colunas diferentes. ",
                                  "Tente cfg$legenda$posicao <- \"dentro\".")
  gt <- rbind(ts, ti, size = "max")
  pan <- gt$layout[gt$layout$name == "panel", ]
  pan <- pan[order(pan$t), ]
  gt$heights[pan$t[1]] <- unit(pr, "null"); gt$heights[pan$t[2]] <- unit(1 - pr, "null")
  if (continuo) {
    moldura <- .moldura_quebra(cfg, Q, pr)
    gt <- gtable::gtable_add_grob(gt, moldura, t = pan$t[1], b = pan$b[2], l = pan$l[1], r = pan$r[1],
                                  clip = "off", z = Inf, name = "moldura-quebra")
  }
  # títulos dos eixos Y ao lado das duas partes (centrados nas duas), com a distância pedida dos números
  titulo_lateral <- function(gt, texto, e, lado, cor) {
    d <- e$distancia_titulo_pt %||% 4
    gp <- gpar(fontsize = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt,
               fontface = if (.neg(cfg, e$negrito_titulo)) "bold" else "plain",
               fontfamily = .fonte(cfg$texto$fonte), col = cor %||% e$cor_titulo %||% cfg$texto$cor)
    rot <- .angulo_titulo(e, if (lado == "esq") "left" else "right")
    lab <- .texto(texto, .neg(cfg, e$negrito_titulo))
    largura <- grid::grobWidth(textGrob(lab, rot = rot, gp = gp)) + unit(d, "pt")
    desl <- unit(if (lado == "esq") -d / 2 else d / 2, "pt")
    tg <- textGrob(lab, rot = rot, x = unit(0.5, "npc") + desl, gp = gp)
    pos <- if (lado == "esq") 0 else -1
    gt <- gtable::gtable_add_cols(gt, largura, pos = pos)
    gtable::gtable_add_grob(gt, tg, t = pan$t[1], b = pan$b[2], l = if (lado == "esq") 1 else ncol(gt),
                            r = if (lado == "esq") 1 else ncol(gt), clip = "off", name = paste0("titulo-y-", lado))
  }
  if (isTRUE(cfg$eixo_y$mostrar_titulo) && !is.null(tit_y1) && !identical(tit_y1, ""))
    gt <- titulo_lateral(gt, tit_y1, cfg$eixo_y, "esq", NULL)
  if (!is.null(y2) && isTRUE(cfg$eixo_y$mostrar_titulo) && !identical(y2$titulo, ""))
    gt <- titulo_lateral(gt, y2$titulo, utils::modifyList(cfg$eixo_y, Filter(Negate(is.null),
                         cfg$eixo_y2[c("distancia_titulo_pt", "rotacao_titulo")])), "dir", .cor(y2$cor))
  m <- cfg$caixa$margens_cm                          # margem externa esquerda/direita (as partes ficam sem ela)
  gt <- gtable::gtable_add_cols(gt, unit(m[4], "cm"), pos = 0)
  gt <- gtable::gtable_add_cols(gt, unit(m[2], "cm"), pos = -1)
  w <- patchwork::wrap_elements(full = gt)
  attr(w, "gt") <- gt
  w
}

# Moldura contínua com as barras "//" no ponto da quebra (coordenadas relativas às duas partes juntas).
# Com marcas = FALSE a moldura fica sem interrupção. Moldura aberta: só eixo esquerdo e inferior.
.moldura_quebra <- function(cfg, Q, pr) {
  cx <- cfg$caixa; fechada <- isTRUE(cx$fechada)
  ev <- cfg$eixo_y; eh <- cfg$eixo_x
  cor <- if (fechada) .cor(cx$cor) else .cor(ev$cor_linha)
  esp <- if (fechada) cx$espessura_pt else (ev$espessura_linha_pt %||% cx$espessura_pt)
  gp <- gpar(col = cor, lwd = .lw(esp) * ggplot2::.pt, lineend = "square")
  esquerda <- fechada || isTRUE(ev$mostrar_linha)
  direita <- fechada
  base <- fechada || isTRUE(eh$mostrar_linha)
  yj <- unit(1 - pr, "npc")                      # a quebra fica na divisa entre as duas partes
  dx <- unit(Q$marca_largura_pt, "pt"); dy <- unit(Q$marca_altura_pt, "pt"); g <- unit(Q$marca_altura_pt * 0.75, "pt")
  yu <- yj + g; yl <- yj - g                     # centro das duas barras (a linha some entre elas)
  seg <- function(x1, y1, x2, y2) segmentsGrob(x1, y1, x2, y2, gp = gp)
  borda <- function(x) {
    x <- unit(x, "npc")
    if (!isTRUE(Q$marcas)) return(list(seg(x, unit(0, "npc"), x, unit(1, "npc"))))
    list(seg(x, unit(1, "npc"), x, yu), seg(x, yl, x, unit(0, "npc")),
         seg(x - dx, yu - dy, x + dx, yu + dy), seg(x - dx, yl - dy, x + dx, yl + dy))
  }
  filhos <- c(if (esquerda) borda(0), if (direita) borda(1),
              if (fechada) list(seg(unit(0, "npc"), unit(1, "npc"), unit(1, "npc"), unit(1, "npc"))),
              if (base) list(seg(unit(0, "npc"), unit(0, "npc"), unit(1, "npc"), unit(0, "npc"))))
  gTree(children = do.call(gList, filhos))
}
