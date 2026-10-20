# =============================================================================
#  R/07_tema.R — tema (caixa, ticks, rótulos, grade, legenda) e fontes
# =============================================================================

# =============================================================================
#  TEMA (aparência: caixa, ticks, rótulos, grade, legenda)
# =============================================================================
# Comprimento do tick com sinal: negativo = para dentro, 0 = nenhum.
.comp_tick <- function(direcao, comp) {
  switch(direcao %||% "dentro", dentro = -comp, fora = comp, ambos = comp, nenhum = 0)
}

# Elemento de tema para os números de um eixo (tamanho, cor, rotação, distância).
.elem_rotulo <- function(e, cfg, lado, cor_forcada = NULL) {
  if (!isTRUE(e$mostrar_rotulos %||% TRUE)) return(element_blank())
  d <- e$distancia_rotulos_pt %||% 3
  m <- switch(lado, bottom = margin(t = d), top = margin(b = d),
              left = margin(r = d), right = margin(l = d))
  ang <- e$rotacao_rotulos %||% 0
  just <- if (ang == 0) list(h = NULL, v = NULL) else switch(lado,
    bottom = list(h = 1, v = if (ang == 90) 0.5 else 1),
    top = list(h = 0, v = if (ang == 90) 0.5 else 0),
    left = list(h = 1, v = 0.5), right = list(h = 0, v = 0.5))
  element_text(size = e$tamanho_rotulos_pt %||% cfg$texto$tamanho_base_pt,
               colour = cor_forcada %||% e$cor_rotulos %||% cfg$texto$cor,
               face = if (.neg(cfg, e$negrito_rotulos)) "bold" else "plain",
               angle = ang, hjust = just$h, vjust = just$v, margin = m)
}

# Negrito ligado neste texto OU em "todos os nomes" (cfg$texto$negrito_tudo).
.neg <- function(cfg, valor = FALSE) isTRUE(valor) || isTRUE(cfg$texto$negrito_tudo)

# Ângulo padrão do título de cada lado do gráfico (esquerda sobe, direita desce, em cima/embaixo na horizontal).
.angulo_titulo <- function(e, lado) e$rotacao_titulo %||% switch(lado, left = 90, right = -90, 0)

# Elemento de tema para o título de um eixo (tamanho, cor, estilo, distância, rotação).
.elem_titulo <- function(e, cfg, lado, cor_forcada = NULL) {
  if (!isTRUE(e$mostrar_titulo %||% TRUE)) return(element_blank())
  d <- e$distancia_titulo_pt %||% 4
  m <- switch(lado, bottom = margin(t = d), top = margin(b = d),
              left = margin(r = d), right = margin(l = d))
  neg <- .neg(cfg, e$negrito_titulo)
  face <- if (neg && isTRUE(e$italico_titulo)) "bold.italic"
          else if (neg) "bold" else if (isTRUE(e$italico_titulo)) "italic" else "plain"
  centro <- if (!is.null(e$rotacao_titulo)) 0.5 else NULL                    # rotação escolhida: centraliza no seu espaço
  element_text(size = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt,
               colour = cor_forcada %||% e$cor_titulo %||% cfg$texto$cor, face = face,
               angle = .angulo_titulo(e, lado), hjust = centro, vjust = centro, margin = m)
}

# Entra: cfg, config do eixo horizontal e do vertical (como aparecem na tela) e os lados com eixo.
# Sai: tema ggplot2 completo.
.tema <- function(cfg, eh, ev, lados, sem_eixos = FALSE, cor_y2 = NULL) {
  # eh = config do eixo HORIZONTAL na tela; ev = do VERTICAL
  # lados = lista(hor = c("bottom", "top"?), ver = c("left", "right"?)), lado_principal
  tx <- cfg$texto; cx <- cfg$caixa; gr <- cfg$grade; lg <- cfg$legenda
  fonte <- .fonte(tx$fonte)
  fundo <- function(v) if (identical(v, "transparente")) NA else .cor(v)
  t <- theme_grey(base_size = tx$tamanho_base_pt, base_family = fonte) +
    theme(text = element_text(colour = tx$cor, family = fonte),
          plot.background = element_rect(fill = fundo(cx$fundo_pagina), colour = NA),
          panel.background = element_rect(fill = fundo(cx$fundo_painel), colour = NA),
          plot.margin = margin(cx$margens_cm[1], cx$margens_cm[2], cx$margens_cm[3],
                               cx$margens_cm[4], unit = "cm"),
          aspect.ratio = cx$proporcao,
          strip.background = element_blank())
  # grade (respeita o que está na horizontal/vertical da TELA)
  gl <- function(on, cor, esp, tipo, opac = 1) {
    if (!isTRUE(on)) return(element_blank())
    element_line(colour = .alfa(.cor(cor, "grade"), opac), linewidth = .lw(esp), linetype = tipo)
  }
  t <- t + theme(
    panel.grid.major.x = gl(lados$grade_x_maior, gr$cor_maior, gr$espessura_maior_pt, gr$tipo_maior,
                            gr$opacidade_maior),
    panel.grid.major.y = gl(lados$grade_y_maior, gr$cor_maior, gr$espessura_maior_pt, gr$tipo_maior,
                            gr$opacidade_maior),
    panel.grid.minor.x = gl(lados$grade_x_menor, gr$cor_menor, gr$espessura_menor_pt, gr$tipo_menor,
                            gr$opacidade_menor),
    panel.grid.minor.y = gl(lados$grade_y_menor, gr$cor_menor, gr$espessura_menor_pt, gr$tipo_menor,
                            gr$opacidade_menor))
  if (sem_eixos) {
    t <- t + theme(axis.text = element_blank(), axis.title = element_blank(),
                   axis.ticks = element_blank(), axis.line = element_blank(),
                   panel.grid = element_blank(), panel.border = element_blank())
  } else {
    # caixa / linhas de eixo
    if (isTRUE(cx$fechada)) {
      t <- t + theme(panel.border = element_rect(fill = NA, colour = .cor(cx$cor), linewidth = .lw(cx$espessura_pt)),
                     axis.line = element_blank())
    } else {
      # linha de cada eixo (só se mostrar_linha e, nos lados opostos, só se o lado existe)
      linha <- function(e, ativo, cor = NULL, ponta = NULL) {
        if (!(isTRUE(e$mostrar_linha) && ativo)) return(element_blank())
        element_line(colour = cor %||% e$cor_linha, linewidth = .lw(e$espessura_linha_pt %||% cx$espessura_pt),
                     lineend = ponta)
      }
      t <- t + theme(panel.border = element_blank(),
        axis.line.x.bottom = linha(eh, TRUE, ponta = "square"),
        axis.line.y.left   = linha(ev, TRUE, ponta = "square"),
        axis.line.y.right  = linha(ev, "right" %in% lados$ver, cor = cor_y2),
        axis.line.x.top    = linha(eh, "top" %in% lados$hor))
    }
    # ticks
    # espessura dos traços: a do eixo, ou (se vazia) a da moldura — mudar a grossura da caixa padroniza tudo
    tk <- function(e, cor = NULL) element_line(colour = cor %||% e$cor_ticks,
                                               linewidth = .lw(e$espessura_ticks_pt %||% cx$espessura_pt))
    for (lado in c("bottom", "top", "left", "right")) {
      e <- if (lado %in% c("bottom", "top")) eh else ev
      xy <- if (lado %in% c("bottom", "top")) "x" else "y"
      cor_l <- if (lado == lados$lado_y2) cor_y2 else NULL
      el <- list()
      el[[paste0("axis.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.ticks.length.", xy, ".", lado)]] <- unit(.comp_tick(e$direcao_maiores, e$comprimento_maiores_pt),
                                                                "pt")
      el[[paste0("axis.minor.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.minor.ticks.length.", xy, ".",
                 lado)]] <- unit(.comp_tick(e$direcao_menores, e$comprimento_menores_pt), "pt")
      el[[paste0("axis.text.", xy, ".", lado)]] <- .elem_rotulo(e, cfg, lado, cor_l)
      el[[paste0("axis.title.", xy, ".", lado)]] <- .elem_titulo(e, cfg, lado, cor_l)
      t <- t + do.call(theme, el)
    }
  }
  # legenda
  t <- t + .tema_legenda(cfg, fonte)
  # títulos
  ti <- cfg$titulos
  hj <- switch(ti$alinhamento, esquerda = 0, centro = 0.5, direita = 1)
  t + theme(plot.title = element_text(hjust = hj, size = ti$tamanho_titulo_pt %||% (tx$tamanho_base_pt * 1.2),
                                      face = if (.neg(cfg, ti$negrito_titulo)) "bold" else "plain"),
            plot.subtitle = element_text(hjust = hj, size = ti$tamanho_subtitulo_pt %||% tx$tamanho_base_pt,
                                         face = if (.neg(cfg)) "bold" else "plain"),
            plot.title.position = "panel")
}

# Parte do tema que controla posição, moldura, fundo, textos e espaçamento da legenda.
.tema_legenda <- function(cfg, fonte) {
  lg <- cfg$legenda; tx <- cfg$texto
  pos <- switch(lg$posicao, dentro = "inside", direita = "right", esquerda = "left",
                topo = "top", base = "bottom")
  sombra <- isTRUE(lg$sombra)
  fundo <- if (identical(lg$fundo, "transparente")) { if (sombra) "white" else NA } else .cor(lg$fundo)
  if (!is.na(fundo) && (lg$fundo_opacidade %||% 1) < 1) fundo <- .alfa(fundo, lg$fundo_opacidade)
  caixa <- element_rect(fill = fundo, colour = if (isTRUE(lg$moldura)) .cor(lg$cor_moldura) else NA,
                        linewidth = .lw(lg$espessura_moldura_pt))
  if (!identical(lg$tipo_moldura %||% "solid", "solid")) caixa <- element_rect(fill = fundo, colour = caixa$colour,
                                                                               linewidth = caixa$linewidth,
                                                                               linetype = lg$tipo_moldura)
  if (sombra) {
    d <- rep_len(lg$sombra_deslocamento_pt, 2)
    attr(caixa, "sombra") <- list(cor = .alfa(.cor(lg$sombra_cor), lg$sombra_opacidade), dx = d[1], dy = d[2])
    class(caixa) <- c("element_sombra", class(caixa))
  }
  esc <- lg$escala %||% 1                      # aumenta/diminui tudo na legenda: texto, quadradinhos, espaços e folgas
  if (!is.null(cfg$.interno$esc_leg)) cfg$.interno$esc_leg$v <- esc       # os símbolos/linhas das chaves seguem esta escala
  gap <- lg$espaco_chave_texto_pt             # espaço entre o símbolo e o texto (NULL = o padrão do ggplot2)
  t <- theme(
    legend.position = pos,
    legend.background = caixa,
    legend.key = element_rect(fill = NA, colour = NA),
    legend.key.size = unit(lg$tamanho_chave_pt * esc, "pt"),
    legend.key.spacing.y = unit(lg$espacamento_pt * esc, "pt"),
    legend.text = element_text(size = (lg$tamanho_texto_pt %||% tx$tamanho_base_pt) * esc,
                               face = if (.neg(cfg, lg$negrito_texto)) "bold" else "plain",
                               margin = if (!is.null(gap)) margin(l = gap * esc) else NULL),
    legend.title = if (is.null(lg$titulo)) element_blank() else
      element_text(size = (lg$tamanho_titulo_pt %||% tx$tamanho_base_pt) * esc,
                   face = if (.neg(cfg, lg$negrito_titulo)) "bold" else "plain"),
    legend.margin = do.call(margin, as.list(lg$margem_interna_pt * esc)))
  if (!is.null(lg$largura_chave_pt)) t <- t + theme(legend.key.width = unit(lg$largura_chave_pt * esc, "pt"))
  if (pos == "inside") {
    anc <- if (identical(lg$ancora, "auto")) c(lg$dentro_x, lg$dentro_y) else lg$ancora
    t <- t + theme(legend.position.inside = c(lg$dentro_x, lg$dentro_y),
                   legend.justification.inside = anc)
    if (!is.null(lg$distancia_pt)) {            # distância da legenda até a borda da caixa, em pt (para dentro)
      d <- rep_len(lg$distancia_pt, 2)
      t <- t + theme(legend.box.margin = margin(t = if (anc[2] > 0.5) d[2] else 0, r = if (anc[1] > 0.5) d[1] else 0,
                                                b = if (anc[2] < 0.5) d[2] else 0, l = if (anc[1] < 0.5) d[1] else 0))
    }
  }
  if (pos %in% c("top", "bottom")) t <- t + theme(legend.direction = "horizontal")
  if (!is.null(lg$direcao)) t <- t + theme(legend.direction = lg$direcao)
  if (!is.null(lg$alinhar) && pos != "inside") {
    j <- c(esquerda = 0, base = 0, centro = 0.5, topo = 1, direita = 1)[[lg$alinhar]]
    t <- t + theme(legend.justification = if (pos %in% c("top", "bottom")) c(j, 0.5) else c(0.5, j))
  }
  t
}

# Retângulo da legenda com sombra projetada: o element_rect comum, precedido de um retângulo deslocado.
# (Método S3 próprio, registrado no ggplot2 — funciona igual no 3.5 e no 4.0.)
.element_grob_sombra <- function(element, ...) {
  base <- NextMethod()
  sh <- attr(element, "sombra")
  sombra <- grid::rectGrob(x = unit(0.5, "npc") + unit(sh$dx, "pt"), y = unit(0.5, "npc") - unit(sh$dy, "pt"),
                           width = unit(1, "npc"), height = unit(1, "npc"), gp = gpar(fill = sh$cor, col = NA))
  grid::gTree(children = grid::gList(sombra, base))
}
registerS3method("element_grob", "element_sombra", .element_grob_sombra, envir = asNamespace("ggplot2"))

.fontes_cache <- new.env()
# Nome de fonte utilizável: o pedido se existir no sistema; senão 'sans', com aviso.
.fonte <- function(f) {
  if (is.null(f) || f %in% c("sans", "serif", "mono", "")) return(f %||% "sans")
  if (!is.null(.fontes_cache[[f]])) return(.fontes_cache[[f]])
  ok <- TRUE
  if (.tem("systemfonts")) {
    if (f %in% .FONTES_OFICIAIS) .registrar_fontes_oficiais()        # Barlow: vem junto com o template
    fams <- unique(.familias_fontes())
    ok <- tolower(f) %in% tolower(fams)
  }
  res <- if (ok) f else {
    .aviso("Fonte '", f, "' não encontrada", if (f %in% .FONTES_OFICIAIS) " (pasta fontes/Barlow ausente)" else " no sistema",
           "; usando 'sans'. Veja listar_fontes().")
    "sans"
  }
  .fontes_cache[[f]] <- res
  res
}

# Bordas do painel para annotation_custom(). O ggplot2 4.0 lê esses limites em unidades de DADOS e os
# transforma pela escala: em log/raiz/recíproca -Inf viraria NaN (e um aviso), então usa as bordas reais.
# O ggplot2 3.5 NÃO transforma (já espera espaço transformado), e lá c(-Inf, Inf) serve para qualquer escala.
.borda_painel <- function(ax) {
  if (!.GG4 || is.null(ax) || identical(ax$escala, "linear") || !is.null(ax$categorias)) return(c(-Inf, Inf))
  r <- sort(ax$trans$transform(ax$limites))
  r <- r + c(-1, 1) * diff(r) * ax$mult
  sort(ax$trans$inverse(r))
}

# Ticks menores do eixo Y2: o sec_axis() do ggplot2 não os desenha na escala própria do Y2, então
# são traços no lado direito nas posições dos menores calculados para o Y2.
# Entra: y2 (list(ax, para1, cor)), eixo Y1 calculado e a config do eixo vertical.
.ticks_y2_menores <- function(y2, ax_y, ev, ax_x = NULL) {
  menores <- y2$ax$menores
  dir <- ev$direcao_menores %||% "dentro"
  if (!length(menores) || identical(dir, "nenhum") || is.null(y2$para1)) return(NULL)
  p <- .npc(y2$para1(menores), ax_y)
  p <- p[p >= -1e-6 & p <= 1 + 1e-6]
  if (!length(p)) return(NULL)
  L <- unit(ev$comprimento_menores_pt, "pt")
  gp <- gpar(col = .cor(y2$cor), lwd = .lw(ev$espessura_ticks_pt %||% 1) * ggplot2::.pt, lineend = "butt")
  x0 <- unit(1, "npc"); y <- unit(p, "npc")
  filhos <- switch(dir,
    dentro = list(segmentsGrob(x0, y, x0 - L, y, gp = gp)),
    fora   = list(segmentsGrob(x0, y, x0 + L, y, gp = gp)),
    ambos  = list(segmentsGrob(x0, y, x0 - L, y, gp = gp), segmentsGrob(x0, y, x0 + L, y, gp = gp)))
  bx <- .borda_painel(ax_x); by <- .borda_painel(ax_y)
  annotation_custom(gTree(children = do.call(gList, filhos)), xmin = bx[1], xmax = bx[2], ymin = by[1], ymax = by[2])
}

# Ticks "ambos" (cruzando o eixo): parte interna desenhada como anotação
.ticks_internos <- function(axh, axv, lados, ax_x = NULL, ax_y = NULL) {
  segs <- list()
  add <- function(ax, lado) {
    e <- ax$cfg
    for (tipo in c("maiores", "menores")) {
      dir <- if (tipo == "maiores") e$direcao_maiores else e$direcao_menores
      if (!identical(dir, "ambos")) next
      v <- if (tipo == "maiores") ax$maiores else ax$menores
      if (!length(v)) next
      p <- .npc(v, ax); p <- p[p >= -1e-6 & p <= 1 + 1e-6]
      L <- unit(if (tipo == "maiores") e$comprimento_maiores_pt else e$comprimento_menores_pt, "pt")
      gp <- gpar(col = e$cor_ticks, lwd = .lw(e$espessura_ticks_pt %||% 1) * ggplot2::.pt, lineend = "butt")
      g <- switch(lado,
        bottom = segmentsGrob(unit(p, "npc"), unit(0, "npc"), unit(p, "npc"), L, gp = gp),
        top    = segmentsGrob(unit(p, "npc"), unit(1, "npc"), unit(p, "npc"), unit(1, "npc") - L, gp = gp),
        left   = segmentsGrob(unit(0, "npc"), unit(p, "npc"), L, unit(p, "npc"), gp = gp),
        right  = segmentsGrob(unit(1, "npc"), unit(p, "npc"), unit(1, "npc") - L, unit(p, "npc"), gp = gp))
      segs[[length(segs) + 1]] <<- g
    }
  }
  for (l in lados$hor) add(axh, l)
  for (l in lados$ver) if (!(l == lados$lado_y2)) add(axv, l)
  if (!length(segs)) return(NULL)
  bx <- .borda_painel(ax_x); by <- .borda_painel(ax_y)   # eixos de DADOS (antes de qualquer coord_flip)
  annotation_custom(do.call(gTree, list(children = do.call(gList, segs))),
                    xmin = bx[1], xmax = bx[2], ymin = by[1], ymax = by[2])
}
