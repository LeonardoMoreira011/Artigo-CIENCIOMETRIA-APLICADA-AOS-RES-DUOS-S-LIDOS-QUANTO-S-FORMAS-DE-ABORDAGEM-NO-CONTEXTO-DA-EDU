# =============================================================================
#  R/15_entrada_paineis.R — plotar() (ponto de entrada), painéis e quebra de eixo
# =============================================================================

# =============================================================================
#  PLOTAR (ponto de entrada) — simples, painéis ou quebra de eixo
# =============================================================================
# Ponto de entrada: monta o gráfico, os painéis ou a quebra de eixo conforme o cfg.
# Entra: dados (de ler_csv) e cfg. Sai: ggplot ou patchwork, com attr "cfg" e "dados".
plotar <- function(dados, cfg = get("cfg", envir = globalenv())) {
  if (missing(dados) || !is.data.frame(dados)) .erro("plotar(dados, cfg): 'dados' deve ser o resultado de ler_csv().")
  .checar_nomes(cfg); .checar_itens(cfg)   # avisa nomes digitados errado ANTES de completar com os padrões
  cfg <- .completar_cfg(cfg)
  .validar(cfg, checar_nomes = FALSE)
  g <- if (isTRUE(cfg$paineis$ativo)) .plotar_paineis(dados, cfg)
       else if (isTRUE(cfg$quebra$ativo)) .plotar_quebra(dados, cfg)
       else .plotar_um(dados, cfg)
  attr(g, "dados") <- dados
  attr(g, "cfg") <- cfg
  g
}

# Letra do painel (a), (A), (i)... conforme o formato escolhido.
.formatar_letra <- function(i, formato) {
  l <- letters[i]; L <- LETTERS[i]
  rom <- tolower(as.character(utils::as.roman(i)))
  switch(formato, "(a)" = paste0("(", l, ")"), "a)" = paste0(l, ")"), "a" = l,
         "(A)" = paste0("(", L, ")"), "A" = L, "(i)" = paste0("(", rom, ")"))
}

# Título único (vertical ou horizontal) ao lado de um conjunto de painéis.
.rotulo_lateral <- function(texto, cfg, vertical = TRUE) {
  e <- if (vertical) cfg$eixo_y else cfg$eixo_x
  face <- if (isTRUE(e$negrito_titulo)) "bold" else "plain"
  patchwork::wrap_elements(full = textGrob(.texto(texto, isTRUE(e$negrito_titulo)), rot = if (vertical) 90 else 0,
    gp = gpar(fontsize = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt, fontface = face,
              fontfamily = .fonte(cfg$texto$fonte), col = e$cor_titulo %||% cfg$texto$cor)))
}

# Painéis com eixo comum: calcula os limites comuns e monta cada painel. Entra: dados e cfg. Sai: patchwork.
.plotar_paineis <- function(dados, cfg) {
  P <- cfg$paineis; n <- length(P$lista)
  if (n < 1) .erro("cfg$paineis$ativo = TRUE, mas cfg$paineis$lista está vazia. Veja o exemplo em 01_config.R.")
  vertical <- P$direcao == "vertical"
  comum <- if (vertical) "eixo_x" else "eixo_y"
  cfgs <- lapply(seq_len(n), function(i) {
    p <- P$lista[[i]]
    if (!is.null(p[[comum]]) && length(setdiff(names(p[[comum]]), c("mostrar_rotulos", "mostrar_titulo"))))
      .aviso("Painel ", i, ": ajustes em ", comum, " são ignorados — o ", comum, " é comum a todos os painéis.")
    ajustes <- p[[comum]][intersect(names(p[[comum]]), c("mostrar_rotulos", "mostrar_titulo"))]
    p[[comum]] <- if (length(ajustes)) ajustes else NULL   # só estes dois valem por painel
    ci <- .mesclar(cfg, p)
    ci$paineis$ativo <- FALSE; ci$quebra$ativo <- FALSE
    ci$.interno <- list(em_painel = TRUE)
    .validar(ci)
    ci
  })
  # 1ª passada: só as faixas de dados de cada painel (sem montar o gráfico e sem repetir os avisos,
  # que saem na 2ª passada), para calcular o eixo comum
  previas <- lapply(cfgs, function(ci) suppressWarnings(.plotar_um(dados, ci, so_info = TRUE)))
  faixas <- lapply(previas, function(inf) {
    if (isTRUE(inf$pizza)) .erro("Pizza não pode ser usada em painéis com eixo comum.")
    if (vertical) inf$faixa_x else inf$faixa_y
  })
  tempos <- Filter(Negate(is.null), lapply(previas, function(inf) inf$ax_x$tempo))
  tempo_comum <- if (vertical && length(tempos)) tempos[[1]] else NULL
  tipos <- vapply(cfgs, function(ci) ci$grafico$tipo, "")
  categorias <- lapply(names(dados), function(n) if (!is.numeric(dados[[n]])) unique(as.character(dados[[n]])))
  conhecidos <- c(names(dados), unlist(categorias))
  for (s in setdiff(unique(unlist(lapply(cfgs, function(ci) names(ci$series)))), conhecidos))
    .aviso("cfg$series[[\"", s, "\"]] não corresponde a nenhuma coluna/categoria dos dados.")
  forcar <- if (vertical && all(tipos %in% c("barras", "boxplot"))) NULL
            else .calc_eixo(cfg[[comum]], unlist(faixas), tempo = tempo_comum)$limites
  plots <- vector("list", n)
  for (i in seq_len(n)) {
    ci <- cfgs[[i]]
    ci$.interno <- list(em_painel = TRUE)
    if (vertical) ci$.interno$forcar_x <- forcar else ci$.interno$forcar_y <- forcar
    ultimo <- if (vertical) i == n else i == 1
    if (P$rotulos_eixo_comum == "ultimo" && !ultimo) {
      ci[[comum]]$mostrar_rotulos <- FALSE; ci[[comum]]$mostrar_titulo <- FALSE
    }
    if (isTRUE(P$alternar_lado) && i %% 2 == 0) {
      if (vertical) ci$.interno$y_direita <- TRUE else ci$.interno$x_topo <- TRUE
    }
    outro <- if (vertical) "eixo_y" else "eixo_x"
    if (isTRUE(P$ocultar_rotulo_encostado) && P$espaco_pt < 10) {
      if (vertical && i > 1) ci[[outro]]$.ocultar_extremo <- if (isTRUE(ci[[outro]]$inverter)) "min" else "max"
      if (!vertical && i < n) ci[[outro]]$.ocultar_extremo <- if (isTRUE(ci[[outro]]$inverter)) "min" else "max"
    }
    if (!is.null(P$titulo_unico)) ci[[outro]]$mostrar_titulo <- FALSE
    if (isTRUE(P$letras)) ci$anotacoes$letra <- ci$anotacoes$letra %||% .formatar_letra(i, P$formato_letra)
    m <- cfg$caixa$margens_cm; esp <- P$espaco_pt / 2 / 72 * 2.54
    if (vertical) {
      ci$caixa$margens_cm <- c(if (i == 1) m[1] else esp, m[2], if (i == n) m[3] else esp, m[4])
    } else {
      ci$caixa$margens_cm <- c(m[1], if (i == n) m[2] else esp, m[3], if (i == 1) m[4] else esp)
    }
    if (i > 1) { ci$titulos$titulo <- NULL; ci$titulos$subtitulo <- NULL }   # título só no 1º painel
    plots[[i]] <- .plotar_um(dados, ci)
  }
  tam <- P$tamanhos %||% rep(1, n)
  if (length(tam) != n) .erro("cfg$paineis$tamanhos deve ter ", n, " valores (um por painel).")
  pw <- if (vertical) patchwork::wrap_plots(plots, ncol = 1, heights = tam)
        else patchwork::wrap_plots(plots, nrow = 1, widths = tam)
  if (isTRUE(P$legenda_unica)) {
    pos <- switch(cfg$legenda$posicao, dentro = "right", direita = "right", esquerda = "left", topo = "top",
                  base = "bottom")
    pw <- pw + patchwork::plot_layout(guides = "collect") & theme(legend.position = pos)
  }
  if (!is.null(P$titulo_unico)) {
    lab <- .rotulo_lateral(P$titulo_unico, cfg, vertical)
    pw <- if (vertical) patchwork::wrap_plots(lab, pw, nrow = 1, widths = grid::unit(c(1.6, 1), c("lines", "null")))
          else patchwork::wrap_plots(pw, lab, ncol = 1, heights = grid::unit(c(1, 1.6), c("null", "lines")))
  }
  pw
}

# Sugere cfg$quebra$de e cfg$quebra$ate: o MAIOR VAZIO entre os valores Y dos seus dados (quando um
# grupo de valores está muito longe do outro). Entra: dados e cfg. Sai (invisível): list(de, ate).
# Imprime as linhas prontas para colar. Só olha o maior vazio; para outro, escolha de/ate à mão.
sugerir_quebra <- function(dados, cfg = get("cfg", envir = globalenv())) {
  cfg <- .completar_cfg(cfg)
  ys <- .colunas_y(dados, cfg, excluir = .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x"))
  v <- sort(unique(unlist(lapply(ys, function(y) dados[[y]]))))
  v <- v[is.finite(v)]
  if (length(v) < 2) .erro("Preciso de pelo menos 2 valores Y diferentes para procurar um vazio.")
  vazios <- diff(v); i <- which.max(vazios)
  folga <- vazios[i] * 0.05                              # 5 % de folga de cada lado do vazio
  de <- v[i] + folga; ate <- v[i + 1] - folga
  passo <- 10^(floor(log10(vazios[i])) - 1)              # arredonda para um número "redondo" dentro do vazio
  de2 <- ceiling(de / passo) * passo; ate2 <- floor(ate / passo) * passo
  if (de2 < ate2) { de <- de2; ate <- ate2 }
  cat(sprintf("Maior vazio entre os dados: de %s a %s (largura %s).\n",
              format(v[i], big.mark = ""), format(v[i + 1], big.mark = ""), format(vazios[i], big.mark = "")))
  cat("Cole estas linhas para quebrar o eixo Y nesse trecho:\n")
  cat(sprintf("  cfg$quebra$ativo <- TRUE; cfg$quebra$de <- %s; cfg$quebra$ate <- %s\n",
              format(de, scientific = FALSE), format(ate, scientific = FALSE)))
  invisible(list(de = de, ate = ate))
}

# Eixo Y com trecho omitido: monta as duas partes e as junta. Entra: dados e cfg. Sai: patchwork.
.plotar_quebra <- function(dados, cfg) {
  Q <- cfg$quebra
  if (is.null(Q$de) || is.null(Q$ate) || Q$de >= Q$ate) .erro("cfg$quebra: defina de < ate (ex.: de = 20, ate = 80).")
  if (cfg$grafico$tipo == "pizza") .erro("Quebra de eixo não se aplica a pizza.")
  base <- cfg; base$quebra$ativo <- FALSE
  inf <- .plotar_um(dados, base, so_info = TRUE)
  lim <- inf$ax_y$limites
  if (Q$de <= lim[1] || Q$ate >= lim[2]) .erro("cfg$quebra: o trecho omitido (", Q$de, " a ", Q$ate,
                                               ") precisa estar dentro do eixo Y (", lim[1], " a ", lim[2], ").")
  inferior <- base; superior <- base
  inferior$eixo_y$inicio <- lim[1]; inferior$eixo_y$fim <- Q$de
  superior$eixo_y$inicio <- Q$ate; superior$eixo_y$fim <- lim[2]
  m <- cfg$caixa$margens_cm; esp <- Q$espaco_pt / 2 / 72 * 2.54
  # a parte de cima fica sem números/título do X; a de baixo sem legenda, títulos e letra
  sem_ligar <- isFALSE(Q$ligar_atraves) && cfg$grafico$tipo %in% c("pontos", "linha", "linha_pontos")
  ajustar_parte <- function(ck, parte, faixa) {
    ck$.interno <- list(forcar_x = inf$ax_x$limites)      # as duas partes compartilham o mesmo eixo X
    if (sem_ligar) ck$.interno$recortar_y <- faixa
    ck$eixo_y$mostrar_titulo <- FALSE
    if (parte == "superior") {
      ck$caixa$margens_cm <- c(m[1], m[2], esp, m[4])
      ck$eixo_x$mostrar_rotulos <- FALSE; ck$eixo_x$mostrar_titulo <- FALSE
    } else {
      ck$caixa$margens_cm <- c(esp, m[2], m[3], m[4])
      ck$legenda$mostrar <- FALSE; ck$titulos$titulo <- NULL; ck$titulos$subtitulo <- NULL
      ck$anotacoes$letra <- NULL
    }
    ck
  }
  gs <- .plotar_um(dados, ajustar_parte(superior, "superior", c(Q$ate, lim[2])))
  gi <- .plotar_um(dados, ajustar_parte(inferior, "inferior", c(lim[1], Q$de)))
  if (isTRUE(Q$marcas)) {
    marca <- function(y) {
      gp <- gpar(col = cfg$caixa$cor, lwd = .lw(cfg$caixa$espessura_pt) * ggplot2::.pt)
      dx <- unit(Q$marca_largura_pt, "pt"); dy <- unit(Q$marca_altura_pt, "pt")
      gTree(children = gList(
        segmentsGrob(unit(0, "npc") - dx, unit(y, "npc") - dy, unit(0, "npc") + dx, unit(y, "npc") + dy, gp = gp),
        segmentsGrob(unit(1, "npc") - dx, unit(y, "npc") - dy, unit(1, "npc") + dx, unit(y, "npc") + dy, gp = gp)))
    }
    gs <- gs + annotation_custom(marca(0), -Inf, Inf, -Inf, Inf)
    gi <- gi + annotation_custom(marca(1), -Inf, Inf, -Inf, Inf)
  }
  pr <- Q$proporcao_superior
  pw <- patchwork::wrap_plots(gs, gi, ncol = 1, heights = c(pr, 1 - pr))
  tit <- inf$titulo_y
  if (isTRUE(cfg$eixo_y$mostrar_titulo) && !identical(tit, ""))
    pw <- patchwork::wrap_plots(.rotulo_lateral(tit, cfg, TRUE), pw, nrow = 1,
                                widths = grid::unit(c(1.6, 1), c("lines", "null")))
  pw
}
