# =============================================================================
#  R/15_quebra_continua.R — quebra de eixo CONTÍNUA (estilo Origin): uma moldura só
# =============================================================================
#  As duas partes ficam coladas dentro de UMA moldura. Nas bordas esquerda e direita, no ponto da
#  quebra, a linha é interrompida e aparecem duas barras "//". É montada com o gtable (que já vem
#  com o ggplot2), pois o patchwork não sabe desenhar uma moldura que atravessa dois gráficos.
# =============================================================================

# Entra: as duas partes (ggplot), cfg, cfg$quebra e a proporção da parte de cima (0 a 1).
# Sai: um elemento do patchwork com as duas partes empilhadas, sem espaço entre elas, e a moldura contínua.
.quebra_continua <- function(gs, gi, cfg, Q, pr) {
  if (!requireNamespace("gtable", quietly = TRUE)) .erro("A quebra contínua precisa do pacote gtable (vem com o ggplot2).")
  zero <- unit(0, "pt")
  if (is.null(grDevices::dev.list())) {           # ggplotGrob() precisa de um dispositivo: usa um nulo, sem arquivo
    grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  }
  # a moldura e as linhas dos eixos são desenhadas por cima (um traço só); aqui somem as de cada parte
  sem_linhas <- theme(panel.border = element_blank(), axis.line.x.bottom = element_blank(),
                      axis.line.x.top = element_blank(), axis.line.y.left = element_blank(),
                      axis.line.y.right = element_blank())
  gs <- gs + sem_linhas + theme(axis.ticks.x.bottom = element_blank(), axis.ticks.length.x.bottom = zero,
                                axis.minor.ticks.x.bottom = element_blank(), axis.minor.ticks.length.x.bottom = zero)
  gi <- gi + sem_linhas + theme(axis.ticks.x.top = element_blank(), axis.ticks.length.x.top = zero,
                                axis.minor.ticks.x.top = element_blank(), axis.minor.ticks.length.x.top = zero,
                                axis.text.x.top = element_blank(), axis.title.x.top = element_blank())
  ts <- ggplot2::ggplotGrob(gs); ti <- ggplot2::ggplotGrob(gi)
  # legenda à direita/esquerda existe só na parte de cima: dá à de baixo as mesmas colunas, vazias
  falta <- ncol(ts) - ncol(ti)
  if (falta > 0) {
    ti <- if (identical(cfg$legenda$posicao, "esquerda"))
      gtable::gtable_add_cols(ti, ts$widths[seq_len(falta)], pos = 0)
    else gtable::gtable_add_cols(ti, ts$widths[(ncol(ti) + 1):ncol(ts)], pos = -1)
  }
  if (ncol(ts) != ncol(ti)) .erro("Quebra contínua: as duas partes ficaram com colunas diferentes. ",
                                  "Tente cfg$legenda$posicao <- \"dentro\" ou cfg$quebra$estilo <- \"separado\".")
  gt <- rbind(ts, ti, size = "max")
  pan <- gt$layout[gt$layout$name == "panel", ]
  pan <- pan[order(pan$t), ]
  gt$heights[pan$t[1]] <- unit(pr, "null"); gt$heights[pan$t[2]] <- unit(1 - pr, "null")
  moldura <- .moldura_quebra(cfg, Q, pr)
  gt <- gtable::gtable_add_grob(gt, moldura, t = pan$t[1], b = pan$b[2], l = pan$l[1], r = pan$r[1],
                                clip = "off", z = Inf, name = "moldura-quebra")
  patchwork::wrap_elements(full = gt)
}

# Moldura contínua com as barras "//" no ponto da quebra (coordenadas relativas às duas partes juntas).
# Com marcas = FALSE a moldura fica sem interrupção. Moldura aberta: só eixo esquerdo e inferior.
.moldura_quebra <- function(cfg, Q, pr) {
  cx <- cfg$caixa; fechada <- isTRUE(cx$fechada)
  ev <- cfg$eixo_y; eh <- cfg$eixo_x
  cor <- if (fechada) .cor(cx$cor) else .cor(ev$cor_linha)
  esp <- if (fechada) cx$espessura_pt else ev$espessura_linha_pt
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
