# =============================================================================
#  app_shiny/R/nucleo.R — da tela para o gráfico (sem Shiny: dá para testar à parte)
# =============================================================================
#  valores da tela  ->  variáveis do painel_de_ajustes.R  ->  aplicar_painel()  ->  plotar()
# =============================================================================

MARCA_CORES <- c("#1B3A8C", "#0E9F4B", "#0B6E78", "#8CC63F", "#0F4C81", "#2FB5A0", "#5B7DB1", "#6BBF59")
`%||%` <- function(a, b) if (is.null(a)) b else a

# Valor inicial (padrão) de um campo: o do template, ou o 'padrao' da especificação.
padrao_do_campo <- function(campo, cfg0) {
  if (!is.null(campo$padrao)) return(campo$padrao)
  alvo <- .PAINEL_MAPA[[campo$id]]
  v <- if (!is.null(alvo)) cfg0[[alvo[1]]][[alvo[2]]] else NULL
  if (identical(campo$id, "tipo_grafico")) v <- cfg0$grafico$tipo
  if (identical(campo$id, "legenda_mostrar")) return("auto")
  if (identical(campo$id, "simbolo_variar")) v <- cfg0$cores$incrementar_simbolo
  v
}

# Valor que a tela mostra no começo.
valor_inicial <- function(campo, cfg0) {
  d <- padrao_do_campo(campo, cfg0)
  switch(campo$tipo,
    num = , int = if (is.numeric(d) && length(d) == 1) d else NA_real_,
    txt = if (is.character(d) && length(d) == 1) d else "",
    chk = isTRUE(d),
    sel = , tri = { o <- unname(campo$opcoes); if (!is.null(d) && length(d) == 1 && as.character(d) %in% o) as.character(d) else o[1] },
    cor = "",
    vec = "", selmulti = character(0), colx = "", colsy = character(0), colsy2 = character(0), NULL)
}

# Converte o que está na tela no valor do painel. NULL = "não mexer" (vale o padrão do template).
ler_valor <- function(campo, v, cfg0) {
  d <- padrao_do_campo(campo, cfg0)
  iguais <- function(a, b) !is.null(a) && !is.null(b) && isTRUE(all.equal(a, b))
  out <- switch(campo$tipo,
    num = , int = { if (is.null(v) || length(v) != 1 || is.na(v)) NULL else if (campo$tipo == "int") as.integer(round(v)) else as.numeric(v) },
    txt = { v <- trimws(v %||% ""); if (!nzchar(v)) NULL else if (grepl("^-?[0-9.]+$", v)) as.numeric(v) else v },
    chk = if (is.null(v)) NULL else isTRUE(v),
    sel = { v <- as.character(v %||% ""); ini <- valor_inicial(campo, cfg0)    # igual ao que a tela mostrava no começo = padrão
            if (!nzchar(v) || iguais(v, as.character(ini))) NULL else v },
    tri = switch(as.character(v %||% "auto"), sim = TRUE, nao = FALSE, NULL),
    cor = { v <- as.character(v %||% ""); if (!nzchar(v)) NULL else v },
    vec = { p <- strsplit(gsub(",", ".", trimws(v %||% "")), "[;[:space:]]+")[[1]]; p <- p[nzchar(p)]
            n <- suppressWarnings(as.numeric(p)); if (!length(n) || anyNA(n)) NULL else n },
    selmulti = if (length(v)) as.character(v) else NULL,
    colx = { v <- as.character(v %||% ""); if (!nzchar(v)) NULL else v },
    colsy = , colsy2 = if (length(v)) as.character(v) else NULL,
    NULL)
  if (is.null(out)) return(NULL)
  if (campo$tipo == "chk") {                      # caixa marcada: só vira variável se mudou o padrão (ou, sem padrão, se TRUE)
    if (!is.null(.PAINEL_MAPA[[campo$id]])) { if (iguais(out, isTRUE(d))) return(NULL) }
    else if (!isTRUE(out)) return(NULL)
  }
  if (campo$tipo %in% c("num", "int") && iguais(as.numeric(out), if (is.numeric(d)) as.numeric(d) else NULL)) return(NULL)
  out
}

# Todas as variáveis do painel a partir dos valores da tela.
#   v: lista id -> valor (a tela); series: data.frame com uma linha por série (nome, cor, forma, tamanho, linha, borda, legenda)
montar_variaveis <- function(v, cfg0, series = NULL) {
  vars <- list()
  for (id in names(ESPEC_CAMPOS)) {
    campo <- ESPEC_CAMPOS[[id]]
    if (id %in% c("simbolo_modo", "legenda_sombra_dx", "legenda_sombra_dy")) next
    val <- ler_valor(campo, v[[id]], cfg0)
    if (!is.null(val)) vars[[id]] <- val
  }
  # paleta da marca = cores personalizadas
  if (identical(vars$cores_paleta, "marca")) { vars$cores_paleta <- NULL; vars$cores_personalizadas <- MARCA_CORES }
  # formas: todas iguais (sempre manda a forma) ou variando
  if (identical(v$simbolo_modo, "igual")) vars$simbolo_forma <- v$simbolo_forma %||% "circulo"
  else { vars$simbolo_forma <- NULL }
  # luz da esfera: "x,y" -> c(x, y)
  if (!is.null(vars$esfera_luz)) vars$esfera_luz <- as.numeric(strsplit(vars$esfera_luz, ",")[[1]])
  # legenda: alinhar (início/fim) depende do lado; sombra: deslocamento em dois números
  if (!is.null(vars$legenda_alinhar)) {
    lado <- vars$legenda_posicao %||% cfg0$legenda$posicao
    vars$legenda_alinhar <- if (lado %in% c("direita", "esquerda")) c(inicio = "topo", fim = "base")[[vars$legenda_alinhar]]
                            else if (lado %in% c("topo", "base")) c(inicio = "esquerda", fim = "direita")[[vars$legenda_alinhar]] else NULL
  }
  dx <- ler_valor(ESPEC_CAMPOS$legenda_sombra_dx, v$legenda_sombra_dx, cfg0); dy <- ler_valor(ESPEC_CAMPOS$legenda_sombra_dy, v$legenda_sombra_dy, cfg0)
  if (!is.null(dx) || !is.null(dy)) vars$legenda_sombra_deslocamento_pt <- c(dx %||% 3, dy %||% 3)
  # uma opção de borda/sombra dada sem ligar liga sozinha (a aplicar_painel já faz); aqui só limpa o vazio
  # séries: uma entrada por série que tenha algo diferente do padrão
  if (!is.null(series) && nrow(series)) {
    por <- function(col, tipo = "num") {
      x <- series[[col]]; ok <- if (tipo == "num") !is.na(x) else (!is.na(x) & nzchar(x))
      if (!any(ok)) return(NULL); stats::setNames(x[ok], series$nome[ok])
    }
    cp <- por("cor", "txt"); if (!is.null(cp)) vars$cores_por_serie <- cp
    fp <- por("forma", "txt"); if (!is.null(fp)) vars$simbolo_forma_por_serie <- fp
    tp <- por("tamanho"); if (!is.null(tp)) vars$simbolo_tamanho_por_serie <- tp
    lp <- por("linha"); if (!is.null(lp)) vars$linha_espessura_por_serie <- lp
    bp <- por("borda"); if (!is.null(bp)) vars$simbolo_borda_por_serie <- bp
    np <- por("legenda", "txt"); if (!is.null(np)) { np <- np[names(np) != unname(np)]; if (length(np)) vars$legenda_nomes <- np }
  }
  vars
}

# Aplica as variáveis ao cfg base e monta o gráfico. Sai: list(g, cfg, aplicado, avisos) ou list(erro = "...").
construir_grafico <- function(dados, vars, cfg0, preview = TRUE) {
  avisos <- character(0); aplicado <- character(0)
  env <- list2env(vars, parent = emptyenv())
  res <- tryCatch(withCallingHandlers({
    cfg <- aplicar_painel(cfg0, painel = env, dados = dados)
    if (preview) cfg$exportacao$formatos <- "png"
    g <- plotar(dados, cfg)
    list(g = g, cfg = cfg)
  }, warning = function(w) { avisos <<- c(avisos, conditionMessage(w)); invokeRestart("muffleWarning") },
     message = function(m) {
       t <- conditionMessage(m)
       if (grepl("^Painel de ajustes aplicado", t)) aplicado <<- trimws(strsplit(sub("^Painel de ajustes aplicado: ", "", t), ",")[[1]])
       else if (grepl("^Legenda reduzida", t)) avisos <<- c(avisos, trimws(t))
       invokeRestart("muffleMessage") }),
    error = function(e) list(erro = conditionMessage(e)))
  res$avisos <- unique(avisos); res$aplicado <- aplicado
  res
}

# Desenha o gráfico numa imagem PNG para a prévia. Sai: list(arquivo, larg_px, alt_px).
desenhar_previa <- function(g, cfg, dpi = 130, arq = tempfile("previa_", fileext = ".png")) {
  prep <- .preparar_saida(g, cfg)
  .abrir_dispositivo("png", arq, prep$larg, prep$alt, dpi, "white", usar_ragg = .ragg_ok(cfg))
  disp <- grDevices::dev.cur()
  tryCatch(.desenhar(prep, g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
  list(arquivo = arq, larg_px = round(prep$larg * dpi), alt_px = round(prep$alt * dpi))
}

# Texto do código do painel (para colar no painel_de_ajustes.R ou usar como script).
gerar_codigo <- function(vars, arquivo_csv = NULL, script_completo = FALSE) {
  lin <- vapply(names(vars), function(n) {
    x <- vars[[n]]
    txt <- if (!is.null(names(x))) paste0("c(", paste(sprintf("%s = %s", vapply(names(x), function(k) deparse(k), ""),
                                                             vapply(unname(as.list(x)), function(y) paste(deparse(y), collapse = ""), "")), collapse = ", "), ")")
           else paste(deparse(x, width.cutoff = 500), collapse = "")
    sprintf("%-28s <- %s", n, txt)
  }, "")
  corpo <- if (length(lin)) paste(lin, collapse = "\n") else "# (nenhum ajuste: vale o padrão do template)"
  if (!script_completo) return(corpo)
  paste0('# Gráfico gerado pelo app. Rode com Source (Ctrl+Shift+S) ao lado do graficos_R_completo.R\n',
         'source("graficos_R_completo.R", encoding = "UTF-8")\n\n',
         'ARQUIVO_CSV <- ', deparse(arquivo_csv %||% "C:/pasta/dados.csv"), '\n\n', corpo, '\n\n',
         'dados <- ler_csv(ARQUIVO_CSV)\n',
         'cfg   <- aplicar_painel(cfg, dados = dados)\n',
         'g     <- plotar(dados, cfg)\n',
         'visualizar(g)\n',
         'salvar(g, cfg)\n')
}
