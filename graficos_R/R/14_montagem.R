# =============================================================================
#  R/14_montagem.R — montagem final de um gráfico (eixos + tema + anotações)
# =============================================================================

# =============================================================================
#  MONTAGEM FINAL (eixos + tema + anotações)
# =============================================================================
# Escala contínua X ou Y a partir de um eixo calculado (limites, ticks, rótulos, margem).
.escala_continua <- function(ax, xy, sec, posicao = NULL) {
  f <- if (xy == "x") scale_x_continuous else scale_y_continuous
  args <- list(limits = ax$limites, breaks = ax$maiores, minor_breaks = ax$menores,
               labels = ax$rotulos, transform = ax$trans, expand = expansion(mult = ax$mult),
               oob = scales::oob_keep)
  if (!is.null(sec)) args$sec.axis <- sec
  if (!is.null(posicao)) args$position <- posicao
  do.call(f, args)
}

# Camadas de anotação: faixas (antes do gráfico) e referências, setas, textos e letra (depois).
.camadas_extra <- function(cfg, info) {
  cam <- list(); fonte <- .fonte(cfg$texto$fonte)
  an <- cfg$anotacoes
  antes <- list()
  for (fx in an$faixas) {
    cor <- .cor(fx$cor %||% "grey60"); op <- fx$opacidade %||% 0.25
    antes[[length(antes) + 1]] <- if ((fx$eixo %||% "x") == "x")
      annotate("rect", xmin = fx$de, xmax = fx$ate, ymin = -Inf, ymax = Inf, fill = cor, alpha = op)
      else annotate("rect", ymin = fx$de, ymax = fx$ate, xmin = -Inf, xmax = Inf, fill = cor, alpha = op)
  }
  for (r in cfg$referencias) {
    if (is.null(r$valor)) .erro("cfg$referencias: cada linha precisa de 'valor'.")
    cor <- .cor(r$cor %||% "grey40"); esp <- .lw(r$espessura_pt %||% 0.75); tp <- r$tipo %||% "dashed"
    if ((r$eixo %||% "y") == "y") {
      cam[[length(cam) + 1]] <- geom_hline(yintercept = r$valor, colour = cor, linewidth = esp, linetype = tp)
      if (!is.null(r$rotulo)) cam[[length(cam) + 1]] <- annotate("text", x = Inf, y = r$valor, label = r$rotulo,
        hjust = 1.05, vjust = -0.4, colour = cor, size = .tx(r$rotulo_tamanho_pt %||% 8), family = fonte)
    } else {
      cam[[length(cam) + 1]] <- geom_vline(xintercept = r$valor, colour = cor, linewidth = esp, linetype = tp)
      if (!is.null(r$rotulo)) cam[[length(cam) + 1]] <- annotate("text", x = r$valor, y = Inf, label = r$rotulo,
        hjust = 1.05, vjust = -0.4, angle = 90, colour = cor, size = .tx(r$rotulo_tamanho_pt %||% 8), family = fonte)
    }
  }
  for (s in an$setas) {
    cam[[length(cam) + 1]] <- annotate("segment", x = s$x, y = s$y, xend = s$x_fim, yend = s$y_fim,
      colour = .cor(s$cor %||% cfg$texto$cor), linewidth = .lw(s$espessura_pt %||% 0.8),
      arrow = arrow(length = unit(s$tamanho_ponta_pt %||% 6, "pt"), type = "closed"))
  }
  for (t in an$textos) {
    pm <- .tem_formatacao(t$texto)
    cam[[length(cam) + 1]] <- annotate("text", x = t$x, y = t$y,
      label = if (pm) (if (isTRUE(t$negrito)) paste0("bold(", .plotmath(t$texto),
                                                     ")") else .plotmath(t$texto)) else t$texto,
      parse = pm,
      hjust = switch(t$alinhamento %||% "centro", esquerda = 0, centro = 0.5, direita = 1),
      colour = .cor(t$cor %||% cfg$texto$cor), size = .tx(t$tamanho_pt %||% cfg$texto$tamanho_base_pt),
      fontface = if (.neg(cfg, t$negrito)) "bold" else "plain", family = fonte)
  }
  if (!is.null(an$letra)) {
    cam[[length(cam) + 1]] <- annotation_custom(textGrob(an$letra, x = an$letra_posicao[1], y = an$letra_posicao[2],
      hjust = 0, vjust = 1, gp = gpar(fontsize = an$letra_tamanho_pt %||% cfg$texto$tamanho_base_pt,
                                      fontface = if (isTRUE(an$letra_negrito)) "bold" else "plain",
                                      fontfamily = fonte, col = cfg$texto$cor)),
      xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
  }
  list(antes = antes, depois = cam)
}

# Monta UM gráfico. Entra: dados e cfg. Sai: objeto ggplot (com attr "info" = eixos calculados) ou,
# com so_info = TRUE, só a lista 'info' (faixas de dados e eixos), sem montar nada: é o que a
# passada prévia dos painéis precisa.
.plotar_um <- function(dados, cfg, so_info = FALSE) {
  tipo <- cfg$grafico$tipo
  # escala atual da legenda, lida na hora de desenhar pelas chaves (símbolos/linhas) — assim eles acompanham a caixa
  esc_leg <- new.env(); esc_leg$v <- cfg$legenda$escala %||% 1
  cfg$.interno$esc_leg <- esc_leg
  res <- switch(tipo,
    pontos = , linha = , linha_pontos = , area = , area_empilhada = .construir_xy(dados, cfg),
    barras = .construir_barras(dados, cfg),
    pizza = .construir_pizza(dados, cfg),
    histograma = , densidade = , ecdf = .construir_distribuicao(dados, cfg),
    boxplot = .construir_boxplot(dados, cfg))
  info <- res$info
  if (isTRUE(so_info)) return(info)
  extra <- .camadas_extra(cfg, info)
  g <- ggplot() + extra$antes + res$camadas + extra$depois
  mostrar_leg <- if (identical(cfg$legenda$mostrar, "auto")) info$legenda_auto else isTRUE(cfg$legenda$mostrar)

  if (isTRUE(info$pizza)) {
    g <- g + coord_fixed(xlim = c(-info$lim, info$lim), ylim = c(-info$lim, info$lim), expand = FALSE, clip = "off") +
      .tema(cfg, cfg$eixo_x, cfg$eixo_y, list(hor = "bottom", ver = "left", lado_y2 = ""), sem_eixos = TRUE) +
      labs(title = .texto(cfg$titulos$titulo, cfg$titulos$negrito_titulo), subtitle = .texto(cfg$titulos$subtitulo))
    if (!mostrar_leg) g <- g + theme(legend.position = "none")
    attr(g, "info") <- info
    return(g)
  }

  if (is.null(info$y2) && isTRUE(cfg$eixo_y2$ativo) && identical(cfg$eixo_y2$modo, "transformado")) {
    if (isTRUE(info$flip)) .erro("eixo_y2 \"transformado\" não é suportado em barras/caixas horizontais.")
    if (info$ax_y$escala != "linear") .erro("eixo_y2 \"transformado\" exige eixo_y linear.")
    fa <- cfg$eixo_y2$fator %||% 1; de <- cfg$eixo_y2$deslocamento %||% 0
    if (fa == 0) .erro("cfg$eixo_y2$fator não pode ser 0.")
    e2 <- .eixo_y2_efetivo(cfg)
    l2 <- sort(fa * info$ax_y$limites + de)
    e2$inicio <- e2$inicio %||% l2[1]; e2$fim <- e2$fim %||% l2[2]
    if (e2$inicio != l2[1] || e2$fim != l2[2]) {
      .aviso("eixo_y2 \"transformado\": os limites seguem o eixo_y (", l2[1], " a ", l2[2],
             "); inicio/fim do y2 ignorados.")
      e2$inicio <- l2[1]; e2$fim <- l2[2]
    }
    ax2 <- .calc_eixo(e2, l2)
    cor2 <- if (is.null(cfg$eixo_y2$cor_eixo) || identical(cfg$eixo_y2$cor_eixo,
                                                           "serie")) NULL else cfg$eixo_y2$cor_eixo
    info$y2 <- list(ax = ax2, para2 = function(v) fa * v + de, para1 = function(v) (v - de) / fa,
                    titulo = cfg$eixo_y2$titulo %||% "",
                    cor = cor2 %||% cfg$texto$cor)
  }
  cx <- cfg$caixa; it <- cfg$.interno %||% list()
  espelhar <- isTRUE(cx$fechada) && isTRUE(cx$ticks_espelhados)
  sec_dup <- function(ax) {
    if (!espelhar) return(NULL)
    dup_axis(name = NULL, labels = if (isTRUE(cx$rotulos_espelhados)) derive() else NULL)
  }
  y_dir <- isTRUE(it$y_direita) && is.null(info$y2)
  x_topo <- isTRUE(it$x_topo)
  # secundários
  sec_x <- sec_dup(info$ax_x)
  sec_y <- if (!is.null(info$y2)) {
    a2 <- info$y2$ax
    sec_axis(transform = info$y2$para2, name = .texto(info$y2$titulo, .neg(cfg, cfg$eixo_y2$negrito_titulo %||% cfg$eixo_y$negrito_titulo)), breaks = a2$maiores,
             labels = a2$rotulos)
  } else sec_dup(info$ax_y)
  g <- g + .escala_continua(info$ax_x, "x", sec_x, if (x_topo) "top") +
    .escala_continua(info$ax_y, "y", sec_y, if (y_dir) "right")
  gm <- list(x = guide_axis(minor.ticks = length(info$ax_x$menores) > 0),
             y = guide_axis(minor.ticks = length(info$ax_y$menores) > 0))
  if (!is.null(sec_x)) gm$x.sec <- guide_axis(minor.ticks = length(info$ax_x$menores) > 0)
  if (!is.null(sec_y)) gm$y.sec <- guide_axis(minor.ticks = is.null(info$y2) && length(info$ax_y$menores) > 0)
  g <- g + do.call(guides, gm)
  g <- g + labs(x = .texto(info$titulo_x, .neg(cfg, cfg$eixo_x$negrito_titulo)),
                y = .texto(info$titulo_y, .neg(cfg, cfg$eixo_y$negrito_titulo)),
                title = .texto(cfg$titulos$titulo, .neg(cfg, cfg$titulos$negrito_titulo)),
                subtitle = .texto(cfg$titulos$subtitulo, .neg(cfg)))
  g <- g + if (isTRUE(info$flip)) coord_flip(clip = if (isTRUE(cx$recortar)) "on" else "off")
           else coord_cartesian(clip = if (isTRUE(cx$recortar)) "on" else "off")

  # eixos na TELA (com barras/box horizontais, x e y trocam de lugar)
  eh <- if (isTRUE(info$flip)) cfg$eixo_y else cfg$eixo_x
  ev <- if (isTRUE(info$flip)) cfg$eixo_x else cfg$eixo_y
  axh <- if (isTRUE(info$flip)) info$ax_y else info$ax_x
  axv <- if (isTRUE(info$flip)) info$ax_x else info$ax_y
  tem_sec_v <- !is.null(sec_y); tem_sec_h <- !is.null(sec_x)
  if (isTRUE(info$flip)) { tmp <- tem_sec_v; tem_sec_v <- tem_sec_h; tem_sec_h <- tmp }
  lados <- list(hor = c("bottom", if (tem_sec_h) "top"), ver = c("left", if (tem_sec_v) "right"),
                lado_y2 = if (!is.null(info$y2)) "right" else "",
                grade_x_maior = if (isTRUE(info$flip)) cfg$grade$maior_y else cfg$grade$maior_x,
                grade_y_maior = if (isTRUE(info$flip)) cfg$grade$maior_x else cfg$grade$maior_y,
                grade_x_menor = if (isTRUE(info$flip)) cfg$grade$menor_y else cfg$grade$menor_x,
                grade_y_menor = if (isTRUE(info$flip)) cfg$grade$menor_x else cfg$grade$menor_y)
  cfg <- .legenda_por_coordenadas(cfg, info)             # posição da legenda dada em unidades dos eixos (x_dados / y_dados)
  ev2 <- if (!is.null(info$y2)) .estilo_y2(cfg, ev) else NULL
  cor_y2 <- if (!is.null(info$y2)) .cores_y2(cfg, .cor(info$y2$cor)) else NULL
  g <- g + .tema(cfg, eh, ev, lados, cor_y2 = cor_y2, ev2 = ev2)
  if (y_dir && espelhar) {
    g <- g + theme(axis.text.y.left = element_blank(), axis.title.y.left = element_blank(),
                   axis.text.y.right = .elem_rotulo(ev, cfg,
                                                    "right"), axis.title.y.right = .elem_titulo(ev, cfg, "right"))
  }
  ti <- .ticks_internos(axh, axv, lados, info$ax_x, info$ax_y)
  if (!is.null(ti)) g <- g + ti
  if (!is.null(info$y2)) {
    tm <- .ticks_y2_menores(info$y2, info$ax_y, ev2, info$ax_x, cor_y2$ticks)
    if (!is.null(tm)) g <- g + tm
  }
  if (!mostrar_leg) g <- g + theme(legend.position = "none")
  else g <- .ajustar_legenda(g, cfg)
  attr(g, "info") <- info
  g
}
