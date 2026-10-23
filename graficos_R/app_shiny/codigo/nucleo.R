# =============================================================================
#  app_shiny/codigo/nucleo.R — da tela para o gráfico (sem Shiny: dá para testar à parte)
# =============================================================================
#  valores da tela  ->  variáveis do painel_de_ajustes.R  ->  aplicar_painel()  ->  plotar()
# =============================================================================

`%||%` <- function(a, b) if (is.null(a)) b else a

# Texto com cores (códigos #RRGGBB, #RGB, RRGGBB ou nomes do R, separados por vírgula, espaço ou linha) -> vetor de #RRGGBB.
ler_cores_texto <- function(txt) {
  p <- strsplit(trimws(paste(txt, collapse = " ")), "[[:space:],;]+")[[1]]; p <- p[nzchar(p)]
  p <- ifelse(grepl("^[0-9A-Fa-f]{3}$|^[0-9A-Fa-f]{6}$", p), paste0("#", p), p)
  ok <- vapply(p, function(x) tryCatch({ grDevices::col2rgb(x); TRUE }, error = function(e) FALSE), NA)
  if (!any(ok)) return(character(0))
  m <- grDevices::col2rgb(p[ok])
  toupper(grDevices::rgb(m[1, ], m[2, ], m[3, ], maxColorValue = 255))
}

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
    sel = , tri = , selbusca = { o <- unname(unlist(campo$opcoes)); if (!is.null(d) && length(d) == 1 && as.character(d) %in% o) as.character(d) else o[1] },
    cor = "", arquivo = "",
    chkgrupo = as.character(d),
    vec = "", area = "", selmulti = character(0), colx = "", colsy = character(0), colsy2 = character(0), NULL)
}

# Converte o que está na tela no valor do painel. NULL = "não mexer" (vale o padrão do template).
# Limites de um campo numérico. O que o campo declara (min, max) vale também no servidor: o navegador deixa digitar qualquer número, e um
# valor absurdo (10 milhões de traços menores, tamanho de letra negativo) travava o R ou o enchia de memória. Sem máximo declarado:
# 500 pt para tamanhos em pt, 300 cm para tamanhos em cm, 1e9 para o resto (coordenadas e valores dos dados).
limites_do_campo <- function(campo) {
  mn <- if (is.null(campo$min) || is.na(campo$min)) NA_real_ else campo$min
  mx <- if (is.null(campo$max) || is.na(campo$max)) NA_real_ else campo$max
  if (is.na(mx)) mx <- if (grepl("_pt$", campo$id)) 500 else if (grepl("_cm$", campo$id)) 300 else 1e9
  c(mn, mx)
}
# Põe v dentro dos limites. 'reg' (um ambiente com $m) anota o que foi limitado, para o app avisar.
limitar_numero <- function(campo, v, reg = NULL) {
  lim <- limites_do_campo(campo); novo <- v
  if (!is.na(lim[1]) && novo < lim[1]) novo <- lim[1]
  if (novo > lim[2]) novo <- lim[2]
  if (!isTRUE(novo == v) && !is.null(reg))
    reg$m[[campo$id]] <- sprintf("O campo \"%s\" ficou em %s: ele só aceita %s.", campo$rotulo, format(novo, scientific = FALSE, trim = TRUE),
                                 if (is.na(lim[1])) paste0("até ", format(lim[2], scientific = FALSE, trim = TRUE)) else paste0("de ", format(lim[1], trim = TRUE), " a ", format(lim[2], scientific = FALSE, trim = TRUE)))
  novo
}

ler_valor <- function(campo, v, cfg0, reg = NULL) {
  d <- padrao_do_campo(campo, cfg0)
  iguais <- function(a, b) !is.null(a) && !is.null(b) && isTRUE(all.equal(a, b))
  out <- switch(campo$tipo,
    num = , int = { if (is.null(v) || length(v) != 1 || is.na(v)) NULL else { v <- limitar_numero(campo, as.numeric(v), reg); if (campo$tipo == "int") as.integer(round(v)) else v } },
    txt = { v <- trimws(v %||% ""); if (!nzchar(v)) NULL else if (grepl("^-?[0-9.]+$", v)) as.numeric(v) else v },
    area = { v <- trimws(v %||% ""); if (!nzchar(v)) NULL else v },
    chk = if (is.null(v)) NULL else isTRUE(v),
    sel = , selbusca = { v <- as.character(v %||% ""); ini <- valor_inicial(campo, cfg0)    # igual ao que a tela mostrava no começo = padrão
            if (!nzchar(v) || iguais(v, as.character(ini))) NULL else v },
    tri = switch(as.character(v %||% "auto"), sim = TRUE, nao = FALSE, NULL),
    cor = { v <- as.character(v %||% ""); if (!nzchar(v)) NULL else v },
    vec = { p <- strsplit(gsub(",", ".", trimws(v %||% "")), "[;[:space:]]+")[[1]]; p <- p[nzchar(p)]
            n <- suppressWarnings(as.numeric(p)); if (!length(n) || anyNA(n)) NULL else n },
    selmulti = , chkgrupo = if (length(v)) as.character(v) else NULL,
    colx = { v <- as.character(v %||% ""); if (!nzchar(v)) NULL else v },
    colsy = , colsy2 = if (length(v)) as.character(v) else NULL,
    NULL)
  if (is.null(out)) return(NULL)
  if (campo$tipo == "chk") {                      # caixa marcada: só vira variável se mudou o padrão (ou, sem padrão, se TRUE)
    if (!is.null(.PAINEL_MAPA[[campo$id]])) { if (iguais(out, isTRUE(d))) return(NULL) }
    else if (!isTRUE(out)) return(NULL)
  }
  if (campo$tipo == "chkgrupo" && iguais(sort(out), sort(as.character(d)))) return(NULL)
  if (campo$tipo %in% c("num", "int") && iguais(as.numeric(out), if (is.numeric(d)) as.numeric(d) else NULL)) return(NULL)
  out
}

# ---- cartões dos blocos 13 e 14 (ajustes, marcas, caixas de estatística, formas): da tela para a lista do painel ----------------
# Valor de um campo de cartão. NULL = "não mexer" (vale o padrão do motor).
ler_valor_slot <- function(campo, v, reg = NULL) {
  d <- campo$padrao
  switch(campo$tipo,
    num = , int = { if (is.null(v) || length(v) != 1 || is.na(v)) NULL else { v <- limitar_numero(campo, as.numeric(v), reg)
                    if (!is.null(d) && isTRUE(all.equal(v, as.numeric(d)))) NULL else if (campo$tipo == "int") as.integer(round(v)) else v } },
    txt = , area = { v <- trimws(v %||% ""); if (!nzchar(v)) NULL else v },
    sel = { v <- as.character(v %||% ""); if (!nzchar(v) || (!is.null(d) && identical(v, as.character(d)))) NULL else v },
    cor = { v <- as.character(v %||% ""); if (!nzchar(v)) NULL else v },
    chk = { if (is.null(v)) NULL else if (isTRUE(v) != isTRUE(d)) isTRUE(v) else NULL },
    vec = { p <- strsplit(gsub(",", ".", trimws(v %||% "")), "[;[:space:]]+")[[1]]; p <- p[nzchar(p)]
            n <- suppressWarnings(as.numeric(p)); if (!length(n) || anyNA(n)) NULL else n },
    selmulti = if (length(v)) as.character(v) else NULL,
    arquivo = if (is.character(v) && length(v) == 1 && nzchar(v)) v else NULL,
    NULL)
}
# "a=5, b=0.1" -> c(a = 5, b = 0.1)
ler_inicio <- function(txt) {
  p <- trimws(strsplit(txt, "[,;[:space:]]+(?=[A-Za-z])", perl = TRUE)[[1]]); p <- p[nzchar(p)]
  m <- Filter(length, regmatches(p, regexec("^([A-Za-z][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(-?[0-9.]+([eE][-+]?[0-9]+)?)$", p)))
  if (!length(m)) return(NULL)
  stats::setNames(as.numeric(vapply(m, `[`, "", 3)), vapply(m, `[`, "", 2))
}
IDS_SLOT <- local({ ids <- names(ESPEC_CAMPOS); ids[vapply(ESPEC_CAMPOS, function(c) !is.null(c$chave), NA)] })
montar_slots <- function(v, reg = NULL) {
  out <- list()
  for (g in names(SLOTS)) {
    itens <- list(); pref <- SLOTS[[g]]$pref
    for (k in seq_len(SLOTS[[g]]$n)) {
      if (!isTRUE(v[[paste0(pref, k, "_ativo")]])) next
      it <- list()
      for (c in SLOT_CAMPOS[[g]][[k]]) {
        if (c$chave == "ativo") next
        val <- ler_valor_slot(c, v[[c$id]], reg)
        if (!is.null(val)) it[[c$chave]] <- val
      }
      if (!is.null(it$inicio)) { ini <- ler_inicio(it$inicio); it$inicio <- NULL; if (!is.null(ini)) it$inicio <- ini }
      if (!is.null(it$parametros)) { pa <- ler_inicio(it$parametros); it$parametros <- NULL; if (!is.null(pa)) it$parametros <- pa }
      if (isTRUE(it$sem_fundo)) it$fundo <- NA
      it$sem_fundo <- NULL
      if (identical(it$serie, "todas")) it$serie <- NULL
      if (!is.null(it$tipo) && identical(it$tipo, "poligono")) { it$x <- NULL; it$y <- NULL; it$largura <- NULL; it$altura <- NULL; it$ancora <- NULL }
      # cartão ligado mas ainda incompleto (figura sem arquivo, fórmula sem fórmula): espera ser preenchido, sem dar erro
      if (g == "imagens" && is.null(it$arquivo)) next
      if (g == "ajustes" && identical(it$tipo, "formula") && is.null(it$formula)) next
      if (g == "ajustes" && identical(it$tipo, "externa") && is.null(it$formula) && is.null(it$pontos)) next
      it$cartao <- k                                    # número do cartão no app: liga a caixa móvel ao cartão e as caixas de estatística aos ajustes
      itens[[length(itens) + 1]] <- it
    }
    if (length(itens)) out[[g]] <- itens
  }
  out
}
SLOT_CAMPOS <- lapply(names(SLOTS), function(g) lapply(seq_len(SLOTS[[g]]$n), function(k) Filter(function(c) !is.null(c$chave) && startsWith(c$id, paste0(SLOTS[[g]]$pref, k, "_")), ESPEC_CAMPOS)))
names(SLOT_CAMPOS) <- names(SLOTS)

# Todas as variáveis do painel a partir dos valores da tela.
#   v: lista id -> valor (a tela); series: data.frame com uma linha por série (nome, cor, forma, tamanho, linha, borda, legenda)
montar_variaveis <- function(v, cfg0, series = NULL) {
  vars <- list(); reg <- new.env(); reg$m <- list()           # reg: campos cujo número foi limitado (vira aviso)
  for (id in names(ESPEC_CAMPOS)) {
    campo <- ESPEC_CAMPOS[[id]]
    if (id %in% c("simbolo_modo", "legenda_sombra_dx", "legenda_sombra_dy", "colunas_erro") || id %in% IDS_SLOT) next
    val <- ler_valor(campo, v[[id]], cfg0, reg)
    if (!is.null(val)) vars[[id]] <- val
  }
  vars <- c(vars, montar_slots(v, reg))                   # ajustes, marcas, caixas de estatística e formas
  # a coluna de erro nunca é série: sai da lista de colunas Y (se a lista ficar vazia, vale "todas as outras", que já descarta as de erro)
  if (length(vars$colunas_y) && length(v$colunas_erro)) { vars$colunas_y <- setdiff(vars$colunas_y, v$colunas_erro); if (!length(vars$colunas_y)) vars$colunas_y <- NULL }
  # paleta própria (a do editor ou uma guardada) = cores personalizadas
  pal <- vars$cores_paleta
  if (identical(pal, "propria") || (is.character(pal) && startsWith(pal, "salva:"))) {
    cores <- if (identical(pal, "propria")) ler_cores_texto(v$.paleta_propria) else v$.paletas_salvas[[sub("^salva:", "", pal)]]
    vars$cores_paleta <- NULL
    if (length(cores)) vars$cores_personalizadas <- as.character(cores)
  }
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
    ep <- if ("erro" %in% names(series)) por("erro", "txt"); if (!is.null(ep)) vars$erro_por_serie <- ep
    np <- por("legenda", "txt"); if (!is.null(np)) { np <- np[names(np) != unname(np)]; if (length(np)) vars$legenda_nomes <- np }
  }
  if (length(reg$m)) attr(vars, "limitados") <- reg$m
  vars
}

# Prévia mais leve para dados com muitas linhas. Acima de LIMITE_PREVIA_LINHAS linhas, a PRÉVIA desenha só uma amostra que guarda os picos e
# os vales (em cada trecho de linhas vizinhas fica a linha do mínimo e a do máximo de cada coluna numérica; em "só pontos", uma amostra
# espaçada mais as linhas dos extremos). Na auditoria, 50 mil linhas levavam ~30 s por atualização; com a amostra, cerca de 1 s. Os arquivos
# baixados (PNG, PDF...) e as tabelas de estatística usam SEMPRE todas as linhas. Não reduz quando há ajuste, média ± DP ou caixa de
# estatística (os números precisam sair dos dados completos) nem fora dos gráficos de linha, área e pontos.
LIMITE_PREVIA_LINHAS <- 5000
ALVO_PREVIA_LINHAS <- 3000
reduzir_previa <- function(dados, cfg, limite = LIMITE_PREVIA_LINHAS, alvo = ALVO_PREVIA_LINHAS) {
  n <- nrow(dados)
  if (is.null(n) || n <= limite || !(cfg$grafico$tipo %in% c("linha_pontos", "linha", "pontos", "area", "area_empilhada"))) return(NULL)
  ativo <- function(l) any(vapply(l %||% list(), function(it) !isFALSE(it$ativo), NA))
  if (ativo(cfg$ajustes) || ativo(cfg$marcas_estatisticas) || ativo(cfg$caixas_estatisticas)) return(NULL)
  cols <- Filter(function(v) is.numeric(v) || inherits(v, c("Date", "POSIXct")), as.list(dados))
  if (!length(cols)) return(NULL)
  extremos <- unique(unlist(lapply(cols, function(v) { v <- as.numeric(v); ok <- which(is.finite(v)); if (length(ok)) c(ok[which.min(v[ok])], ok[which.max(v[ok])]) })))
  if (identical(cfg$grafico$tipo, "pontos")) {
    idx <- unique(c(round(seq(1, n, length.out = alvo)), extremos))
  } else {
    nb <- max(100L, floor(alvo / (2 * length(cols) + 1))); bin <- ceiling(seq_len(n) / n * nb)
    idx <- c(1L, n, extremos)
    for (v in cols) {
      v <- as.numeric(v); ok <- which(is.finite(v)); if (!length(ok)) next
      oo <- ok[order(bin[ok], v[ok])]; b <- bin[oo]
      idx <- c(idx, oo[!duplicated(b)], oo[!duplicated(b, fromLast = TRUE)])
    }
  }
  idx <- sort(unique(as.integer(idx)))
  if (length(idx) >= 0.9 * n) return(NULL)
  extras <- attributes(dados)[setdiff(names(attributes(dados)), c("names", "row.names", "class"))]
  d2 <- dados[idx, , drop = FALSE]; rownames(d2) <- NULL
  for (a in names(extras)) attr(d2, a) <- extras[[a]]
  list(dados = d2, de = n, para = length(idx))
}

# Aplica as variáveis ao cfg base e monta o gráfico. Sai: list(g, cfg, aplicado, avisos) ou list(erro = "...").
construir_grafico <- function(dados, vars, cfg0, preview = TRUE, idioma = "pt") {
  avisos <- as.character(unlist(attr(vars, "limitados"))); aplicado <- character(0)
  env <- list2env(vars, parent = emptyenv())
  res <- tryCatch(withCallingHandlers(com_idioma(idioma, {
    cfg <- aplicar_painel(cfg0, painel = env, dados = dados)
    if (preview) cfg$exportacao$formatos <- "png"
    red <- if (preview) reduzir_previa(dados, cfg)
    g <- plotar(if (is.null(red)) dados else red$dados, cfg)
    list(g = g, cfg = cfg, decimado = if (!is.null(red)) c(de = red$de, para = red$para))
  }), warning = function(w) { avisos <<- c(avisos, conditionMessage(w)); invokeRestart("muffleWarning") },
     message = function(m) {
       t <- conditionMessage(m)
       if (grepl("^Painel de ajustes aplicado", t)) aplicado <<- trimws(strsplit(sub("^Painel de ajustes aplicado: ", "", t), ",")[[1]])
       else if (grepl("^(Legenda reduzida|Legend reduced|Leyenda reducida)", t)) avisos <<- c(avisos, trimws(t))
       invokeRestart("muffleMessage") }),
    error = function(e) list(erro = conditionMessage(e)))
  res$avisos <- unique(avisos); res$aplicado <- aplicado
  res
}

# Desenha o gráfico numa imagem PNG para a prévia. Sai: list(arquivo, larg_px, alt_px).
desenhar_previa <- function(g, cfg, dpi = 130, arq = tempfile("previa_", fileext = ".png"), alvo_px = NULL, prep = NULL) {
  prep <- prep %||% .preparar_saida(g, cfg)
  if (!is.null(alvo_px) && is.finite(alvo_px) && alvo_px > 200) dpi <- min(max(alvo_px / prep$larg, 96), 300, 2400 / prep$larg)   # o gráfico ocupa a largura do palco
  .abrir_dispositivo("png", arq, prep$larg, prep$alt, dpi, "white", usar_ragg = .ragg_ok(cfg))
  disp <- grDevices::dev.cur()
  tryCatch(.desenhar(prep, g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
  list(arquivo = arq, larg_px = round(prep$larg * dpi), alt_px = round(prep$alt * dpi), dpi = dpi)
}

# Texto do código do painel (para colar no painel_de_ajustes.R ou usar como script).
gerar_codigo <- function(vars, arquivo_csv = NULL, script_completo = FALSE) {
  vars <- lapply(vars, function(x) if (is.list(x) && length(x) && all(vapply(x, is.list, NA))) lapply(x, function(it) it[setdiff(names(it), "cartao")]) else x)   # o número do cartão é do app
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
