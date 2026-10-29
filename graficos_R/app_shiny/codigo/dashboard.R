# =============================================================================
#  app_shiny/codigo/dashboard.R — Dashboard: reúne os gráficos das abas numa folha que se edita e sai em PDF
# =============================================================================
#  O R desenha cada gráfico (SVG vetorial ou PNG), calcula os números-chave e os destaques e entrega tudo a uma página HTML autônoma
#  (www/dashboard/): é nela que se arruma a folha (mover, esticar, alinhar...) e de onde sai o PDF (navegador do Windows em modo invisível).
# =============================================================================

.DASH_WWW <- normalizePath(file.path(if (dir.exists("www/dashboard")) "www" else file.path("app_shiny", "www"), "dashboard"), winslash = "/", mustWork = FALSE)
DASH_DIR <- file.path(tempdir(), "cinabro_dashboard")                  # as páginas montadas nesta sessão (servidas em /painel/)
dir.create(DASH_DIR, showWarnings = FALSE, recursive = TRUE)

.dash_b64 <- function(arq) gsub("[\r\n]", "", jsonlite::base64_enc(readBin(arq, "raw", file.size(arq))))      # (o base64 do jsonlite vem com quebras de linha; dentro de url() elas estragam o CSS)

# ---- texto em português ----------------------------------------------------------------------------------------------------------
.dash_num <- function(x, casas = 0) if (length(x) != 1 || !is.finite(x)) "NA" else format(round(x, casas), big.mark = ".", decimal.mark = ",", nsmall = casas, scientific = FALSE, trim = TRUE)
.dash_casas <- function(x) if (all(abs(x - round(x)) < 1e-9, na.rm = TRUE)) 0 else if (all(abs(x) >= 100, na.rm = TRUE)) 1 else 2
.dash_pct <- function(frac, casas = 1) paste0(.dash_num(frac * 100, casas), "%")
.dash_p <- function(p) if (length(p) != 1 || is.na(p)) "p = NA" else if (p < 0.001) "p < 0,001" else paste0("p = ", formatC(p, format = "f", digits = 3, decimal.mark = ","))
.dash_esc <- function(x) { x <- as.character(x); x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE); gsub(">", "&gt;", x, fixed = TRUE) }
.dash_b <- function(x) paste0("<b>", .dash_esc(x), "</b>")
.dash_x <- function(v) if (inherits(v, c("Date", "POSIXct"))) format(v, "%d/%m/%Y") else if (is.numeric(v)) .dash_num(v, .dash_casas(v)) else as.character(v)

# ---- números-chave e destaques (só de contas que o programa já faz) -----------------------------------------------------------
.dash_vazio <- function() list(frases = character(0), kpi = NULL, resumo = NULL)

.dest_ordenacao <- function(info, cfg) {
  R <- info$ordenacao; if (is.null(R)) return(.dash_vazio())
  ch <- R$ch; ev <- R$prop_total; eix <- R$eixos_total; ac <- sum(ev[ch]); fr <- character(0)
  fr <- c(fr, paste0(.dash_b(eix[ch[1]]), " e ", .dash_b(eix[ch[2]]), " explicam ", .dash_b(.dash_pct(ac)), " da ", if (R$tipo == "pca") "variação" else "inércia total", "."))
  V <- R$vars; ex <- R$eixos[1]
  if (!is.null(V) && nrow(V) >= 2) { top <- rownames(V)[order(abs(V[, 1]), decreasing = TRUE)][1:2]
    fr <- c(fr, paste0("As variáveis que mais pesam no eixo ", .dash_esc(ex), ": ", .dash_b(top[1]), " e ", .dash_b(top[2]), ".")) }
  A <- R$amb
  if (!is.null(A) && nrow(A) >= 1) fr <- c(fr, paste0(.dash_b(rownames(A)[which.max(abs(A[, 1]))]), " é a variável ambiental mais ligada ao eixo ", .dash_esc(ex), "."))
  if (identical(R$tipo, "cca") && is.finite(R$restrita)) {
    rng <- .guardar_rng(); on.exit(rng(), add = TRUE)
    set.seed(cfg$multivariada$semente %||% 123)
    a <- tryCatch(suppressWarnings(vegan::anova.cca(R$ord, permutations = as.integer(cfg$multivariada$permutacoes %||% 999))), error = function(e) NULL)
    p <- if (!is.null(a)) a$`Pr(>F)`[1] else NA_real_
    fr <- c(fr, paste0("As variáveis ambientais explicam ", .dash_b(.dash_pct(R$restrita)), " da inércia", if (!is.na(p)) paste0(" (teste de permutação, ", .dash_p(p), ")"), "."))
  }
  lc <- tryCatch(.linhas_resumo_ordenacao(R, cfg), error = function(e) NULL)
  list(frases = fr, kpi = list(valor = .dash_pct(ac), rotulo = paste(eix[ch], collapse = " + ")), resumo = if (!is.null(lc)) lc$linhas)
}

.dest_calor <- function(dados, cfg) {
  M <- .matriz_mapa_calor(dados, cfg); Z <- M$Z; if (!any(is.finite(Z))) return(.dash_vazio())
  i <- which(Z == max(Z, na.rm = TRUE), arr.ind = TRUE)[1, ]; j <- which(Z == min(Z, na.rm = TRUE), arr.ind = TRUE)[1, ]
  v <- function(z) .dash_num(z, .dash_casas(c(Z[is.finite(Z)])))
  fr <- c(paste0("O maior valor está em ", .dash_b(paste(rownames(Z)[i[1]], "×", colnames(Z)[i[2]])), " (", v(Z[i[1], i[2]]), ")."),
          paste0("O menor valor está em ", .dash_b(paste(rownames(Z)[j[1]], "×", colnames(Z)[j[2]])), " (", v(Z[j[1], j[2]]), ")."))
  mc <- colMeans(Z, na.rm = TRUE); if (length(mc) >= 2) fr <- c(fr, paste0("A maior média por coluna é a de ", .dash_b(names(mc)[which.max(mc)]), " (", v(max(mc)), ")."))
  list(frases = fr, kpi = list(valor = v(Z[i[1], i[2]]), rotulo = "maior valor"), resumo = NULL)
}

# categorias com valor (barras, pizza, mapas): quem lidera, quanto do total, as três maiores
.dest_categorias <- function(dados, cfg, mapa = FALSE) {
  xc <- .coluna(dados, cfg$grafico$coluna_x %||% 1, "x"); ys <- .colunas_y(dados, cfg, excluir = xc)
  cat <- as.character(dados[[xc]]); val <- if (length(ys) == 1) dados[[ys]] else rowSums(dados[ys], na.rm = TRUE)
  ok <- !is.na(cat) & !is.na(val); cat <- cat[ok]; val <- val[ok]; if (!length(val)) return(.dash_vazio())
  agg <- sort(tapply(val, cat, sum), decreasing = TRUE); tot <- sum(agg); casas <- .dash_casas(agg); n <- length(agg)
  positivo <- all(agg >= 0) && tot > 0
  fr <- paste0(.dash_b(names(agg)[1]), " tem o maior valor (", .dash_num(agg[[1]], casas), if (positivo) paste0("; ", .dash_pct(agg[[1]] / tot, 0), " do total"), if (length(ys) > 1) paste0("; soma de ", length(ys), " séries"), ").")
  if (n >= 5 && positivo) fr <- c(fr, paste0("As três maiores somam ", .dash_b(.dash_pct(sum(agg[1:3]) / tot, 0)), " do total."))
  if (n >= 2) fr <- c(fr, paste0(.dash_b(names(agg)[n]), " tem o menor valor (", .dash_num(agg[[n]], casas), ")."))
  kpi <- if (positivo && n >= 2) list(valor = .dash_pct(agg[[1]] / tot, 0), rotulo = paste0(names(agg)[1], " (maior parcela)")) else list(valor = .dash_num(agg[[1]], casas), rotulo = paste0(names(agg)[1], " (maior valor)"))
  list(frases = fr, kpi = kpi, resumo = NULL)
}

# grupos (boxplot): maior mediana e, com 2 ou mais grupos, o teste de Kruskal-Wallis
.dest_grupos <- function(dados, cfg) {
  A <- .amostras(dados, cfg)$am; A <- A[vapply(A, length, 0) >= 2]; if (length(A) < 1) return(.dash_vazio())
  med <- vapply(A, stats::median, 0); casas <- .dash_casas(unlist(A)); k <- which.max(med)
  fr <- paste0(.dash_b(names(A)[k]), " tem a maior mediana (", .dash_num(med[[k]], casas), ").")
  kpi <- NULL
  if (length(A) >= 2) {
    kw <- tryCatch(stats::kruskal.test(unname(A)), error = function(e) NULL)
    if (!is.null(kw)) { p <- kw$p.value
      fr <- c(paste0("Os grupos ", if (p < 0.05) .dash_b("diferem") else .dash_b("não diferem"), " (Kruskal-Wallis, ", .dash_p(p), ")."), fr)
      kpi <- list(valor = .dash_p(p), rotulo = "Kruskal-Wallis") }
  }
  list(frases = fr, kpi = kpi, resumo = NULL)
}

.dest_distribuicao <- function(dados, cfg) {
  A <- .amostras(dados, cfg)$am; v <- unlist(A); v <- v[is.finite(v)]; if (length(v) < 2) return(.dash_vazio())
  ca <- .dash_casas(v)
  fr <- paste0(.dash_b(paste0("n = ", length(v))), " observações; média ", .dash_b(.dash_num(mean(v), ca + 1)), " ± ", .dash_num(stats::sd(v), ca + 1), " (DP).")
  list(frases = fr, kpi = list(valor = .dash_num(length(v)), rotulo = "observações"), resumo = NULL)
}

# séries (linhas, pontos, áreas): variação do primeiro ao último ponto, máximo; em pontos, a correlação entre X e Y
.dest_series <- function(dados, cfg) {
  xc <- .coluna(dados, cfg$grafico$coluna_x %||% 1, "x"); ys <- .colunas_y(dados, cfg, excluir = xc); x <- dados[[xc]]
  fr <- character(0); kpi <- NULL
  for (y in utils::head(ys, 3)) {
    v <- dados[[y]]; ok <- !is.na(v) & !is.na(x); if (sum(ok) < 3) next
    o <- order(x[ok]); xv <- x[ok][o]; vv <- v[ok][o]
    if (identical(cfg$grafico$tipo, "pontos") && is.numeric(x)) {
      r <- stats::cor(xv, vv); if (!is.finite(r)) next
      fr <- c(fr, paste0("Entre ", .dash_b(xc), " e ", .dash_b(y), ": ", .dash_b(paste0("r = ", .dash_num(r, 2))), " (n = ", length(vv), ")."))
      if (is.null(kpi)) kpi <- list(valor = paste0("r = ", .dash_num(r, 2)), rotulo = paste(y, "×", xc))
      next
    }
    a <- vv[1]; b <- vv[length(vv)]; ca <- .dash_casas(vv)
    if (a != 0) { pct <- (b - a) / abs(a)
      verbo <- if (abs(pct) < 0.005) "ficou estável" else if (pct > 0) "subiu" else "caiu"
      fr <- c(fr, paste0(.dash_b(y), " ", if (abs(pct) < 0.005) verbo else paste0(verbo, " ", .dash_b(.dash_pct(abs(pct)))), " entre ", .dash_esc(.dash_x(xv[1])), " e ", .dash_esc(.dash_x(xv[length(xv)])),
                         " (de ", .dash_num(a, ca), " para ", .dash_num(b, ca), ")."))
      if (is.null(kpi)) kpi <- list(valor = paste0(if (pct > 0) "+" else if (pct < 0) "−" else "", .dash_pct(abs(pct), if (abs(pct) >= 1) 0 else 1)), rotulo = paste(y, "· variação"))
    } else fr <- c(fr, paste0(.dash_b(y), " foi de ", .dash_num(a, ca), " para ", .dash_num(b, ca), " entre ", .dash_esc(.dash_x(xv[1])), " e ", .dash_esc(.dash_x(xv[length(xv)])), "."))
    if (length(fr) == 1) { im <- which.max(vv); fr <- c(fr, paste0("O máximo de ", .dash_b(y), " é ", .dash_b(.dash_num(vv[im], ca)), ", em ", .dash_esc(.dash_x(xv[im])), ".")) }
  }
  list(frases = fr, kpi = kpi, resumo = NULL)
}

.dash_destaques <- function(dados, cfg, g) {
  tp <- cfg$grafico$tipo
  r <- tryCatch(switch(tp,
    pca = , ca = , cca = .dest_ordenacao(attr(g, "info"), cfg),
    mapa_calor = .dest_calor(dados, cfg),
    mapa_mundo = , mapa_brasil = , barras = , pizza = .dest_categorias(dados, cfg),
    boxplot = .dest_grupos(dados, cfg),
    histograma = , densidade = , ecdf = .dest_distribuicao(dados, cfg),
    .dest_series(dados, cfg)), error = function(e) .dash_vazio())
  r$frases <- utils::head(r$frases, 4); r
}

# ---- imagem de cada gráfico ------------------------------------------------------------------------------------------------------
# SVG vetorial para ser inserido na página (os ids são renomeados por gráfico: dois SVG na mesma página não podem repetir id)
.dash_svg_limpo <- function(txt, k) {
  txt <- sub("^<\\?xml[^>]*\\?>\\s*", "", txt)
  txt <- sub(" width='[^']*pt' height='[^']*pt'", "", txt)
  ids <- unique(regmatches(txt, gregexpr("(?<= id=')[^']+(?=')", txt, perl = TRUE))[[1]])
  for (i in ids) {
    novo <- paste0("c", k, "-", i)
    txt <- gsub(paste0(" id='", i, "'"), paste0(" id='", novo, "'"), txt, fixed = TRUE)
    txt <- gsub(paste0("url(#", i, ")"), paste0("url(#", novo, ")"), txt, fixed = TRUE)
    txt <- gsub(paste0("href='#", i, "'"), paste0("href='#", novo, "'"), txt, fixed = TRUE)
  }
  txt
}
# TRUE se o gráfico tem pontos demais para ir como SVG (pontos e linhas com pontos pesam mais do que linhas).
.dash_pesado <- function(dados, cfg) {
  ny <- max(1, sum(vapply(dados, is.numeric, NA)) - 1); n <- nrow(dados) * ny
  n > if (cfg$grafico$tipo %in% c("pontos", "linha_pontos")) 30000 else 150000
}
# Entra: r (de construir_grafico). Sai: list(tipo = "svg" | "png", conteudo, larg, alt) (polegadas).
.dash_imagem <- function(r, vetorial = TRUE, k = 1, dpi = 200) {
  cfg <- r$cfg; g <- r$g
  prep <- .preparar_saida(g, cfg); larg <- prep$larg; alt <- prep$alt
  if (isTRUE(vetorial) && !.usa_gradiente(cfg)) {
    svg <- tryCatch({
      arq <- tempfile(fileext = ".svg"); on.exit(unlink(arq), add = TRUE)
      .abrir_dispositivo("svg", arq, larg, alt, 96, "white"); disp <- grDevices::dev.cur()
      tryCatch(.desenhar(prep, g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
      txt <- paste(readLines(arq, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
      if (nchar(txt) > 8e6) NULL else txt                         # gráfico enorme (dezenas de milhares de pontos): vai como imagem leve
    }, error = function(e) NULL)
    if (!is.null(svg)) return(list(tipo = "svg", conteudo = .dash_svg_limpo(svg, k), larg = larg, alt = alt))
  }
  dpi <- min(dpi, 2600 / larg)
  arq <- tempfile(fileext = ".png"); on.exit(unlink(arq), add = TRUE)
  .abrir_dispositivo("png", arq, larg, alt, dpi, "white", usar_ragg = .ragg_ok(cfg)); disp <- grDevices::dev.cur()
  tryCatch(.desenhar(prep, g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
  list(tipo = "png", conteudo = paste0("data:image/png;base64,", .dash_b64(arq)), larg = larg, alt = alt)
}

# ---- montar o conteúdo ---------------------------------------------------------------------------------------------------------------
# abas: lista de list(nome, dados, valores, series). opcoes: titulo, subtitulo, rodape, formato ("a4h"|"a4v"), qualidade ("vetorial"|"leve"), destaques (TRUE/FALSE).
# Sai: list(estado = <layout e textos>, graficos = <imagens e destaques de cada aba>, avisos = <o que ficou de fora e por quê>).
dash_construir <- function(abas, opcoes = list(), progresso = function(i, n, nome) NULL) {
  vetorial <- !identical(opcoes$qualidade, "leve"); com_dest <- !isFALSE(opcoes$destaques)
  gs <- list(); avisos <- character(0)
  for (i in seq_along(abas)) {
    a <- abas[[i]]; nome <- a$nome %||% paste("Gráfico", i); progresso(i, length(abas), nome)
    if (is.null(a$dados)) { avisos <- c(avisos, sprintf("\"%s\": sem dados; ficou de fora.", nome)); next }
    r <- tryCatch(construir_grafico(a$dados, montar_variaveis(a$valores, CFG0, a$series), CFG0, preview = FALSE), error = function(e) list(erro = conditionMessage(e)))
    if (!is.null(r$erro)) { avisos <- c(avisos, sprintf("\"%s\": %s", nome, substr(r$erro, 1, 160))); next }
    k <- length(gs) + 1
    pesado <- .dash_pesado(a$dados, r$cfg)                                  # milhares de pontos: SVG pesaria e levaria mais de 15 s; vai como imagem
    if (vetorial && pesado) avisos <- c(avisos, sprintf("\"%s\": tem muitos pontos e entrou como imagem (leve), não como vetor.", nome))
    im <- tryCatch(.dash_imagem(r, vetorial && !pesado, k), error = function(e) { avisos <<- c(avisos, sprintf("\"%s\": não consegui desenhar (%s).", nome, substr(conditionMessage(e), 1, 120))); NULL })
    if (is.null(im)) next
    d <- if (com_dest) .dash_destaques(a$dados, r$cfg, r$g) else .dash_vazio()
    gs[[k]] <- list(id = paste0("g", k), nome = nome, tipo = r$cfg$grafico$tipo, formato = im$tipo, conteudo = im$conteudo, ar = round(im$larg / im$alt, 4),
                    frases = as.list(d$frases), kpi = d$kpi, resumo = as.list(d$resumo))
  }
  list(estado = list(versao = 1, id = as.character(as.integer(Sys.time())), titulo = opcoes$titulo %||% "Painel de acompanhamento",
                     subtitulo = opcoes$subtitulo %||% paste0("atualizado em ", format(Sys.Date(), "%d/%m/%Y")),
                     rodape = opcoes$rodape %||% "Cinabro", formato = opcoes$formato %||% "a4h", paginas = list(), identidade = list(modo = "cinabro")),
       graficos = unname(gs), avisos = avisos)
}

# ---- a página HTML ---------------------------------------------------------------------------------------------------------------------------
.dash_inserir <- function(txt, marca, valor) { i <- regexpr(marca, txt, fixed = TRUE); if (i < 0) return(txt); paste0(substr(txt, 1, i - 1), valor, substr(txt, i + attr(i, "match.length"), nchar(txt))) }
.dash_ler <- function(arq) paste(readLines(file.path(.DASH_WWW, arq), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
.dash_cache <- new.env()
.dash_fontes_css <- function() {                      # a Barlow (4 estilos) dentro da página: o PDF e o HTML saem com a mesma letra em qualquer computador
  if (!is.null(.dash_cache$fontes)) return(.dash_cache$fontes)
  f <- c("Regular" = "normal normal", "Bold" = "bold normal", "Italic" = "normal italic", "BoldItalic" = "bold italic")
  css <- vapply(names(f), function(n) { arq <- file.path(raiz, "fontes", "Barlow", paste0("Barlow-", n, ".ttf"))
    if (!file.exists(arq)) return("")
    p <- strsplit(f[[n]], " ")[[1]]
    sprintf("@font-face{font-family:'Barlow';font-weight:%s;font-style:%s;src:url(data:font/ttf;base64,%s) format('truetype');}", p[1], p[2], .dash_b64(arq))
  }, "")
  .dash_cache$fontes <- paste(css, collapse = "\n"); .dash_cache$fontes
}
# estado e graficos: lista do R OU texto JSON (o que o editor devolve). modo: "editar" (editor, dentro do app) | "pdf" (para imprimir: sem barras) | "ver" (arquivo final)
.dash_json <- function(x) {
  j <- if (is.character(x) && length(x) == 1) x else as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))
  gsub("</", "<\\/", j, fixed = TRUE)
}
dash_html <- function(estado, graficos, modo = "editar") {
  tit <- if (is.list(estado)) estado$titulo else tryCatch(jsonlite::fromJSON(estado, simplifyVector = FALSE)$titulo, error = function(e) NULL)
  h <- .dash_ler("modelo.html")
  h <- .dash_inserir(h, "@@MODO@@", modo)
  h <- .dash_inserir(h, "@@TITULO@@", .dash_esc(tit %||% "Dashboard"))
  h <- .dash_inserir(h, "@@FONTES@@", .dash_fontes_css())
  h <- .dash_inserir(h, "@@CSS@@", .dash_ler("editor.css"))
  h <- .dash_inserir(h, "@@JS@@", .dash_ler("editor.js"))
  h <- .dash_inserir(h, "@@ESTADO@@", .dash_json(estado))
  .dash_inserir(h, "@@GRAFICOS@@", .dash_json(graficos))        # (por último: é o texto maior)
}

# Nome de arquivo seguro: sem acento (o iconv do Windows troca por "?"), sem espaço nem símbolo.
nome_de_arquivo <- function(x, padrao = "dashboard") {
  x <- chartr("áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ", "aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN", as.character(x)[1])
  x <- gsub("^_+|_+$", "", gsub("[^A-Za-z0-9_.-]+", "_", x))
  if (is.na(x) || !nzchar(x)) padrao else substr(x, 1, 80)
}

# ---- PDF pelo navegador que já está no computador (Edge ou Chrome, em modo invisível) ------------------------------------------------------------
.dash_navegador <- function() {
  env <- Sys.getenv("CINABRO_NAVEGADOR"); if (nzchar(env) && file.exists(env)) return(env)
  if (.Platform$OS.type == "windows") {
    pf <- c(Sys.getenv("ProgramFiles(x86)"), Sys.getenv("ProgramFiles"), Sys.getenv("LOCALAPPDATA")); pf <- pf[nzchar(pf)]
    cand <- c(file.path(pf, "Microsoft", "Edge", "Application", "msedge.exe"), file.path(pf, "Google", "Chrome", "Application", "chrome.exe"))
  } else cand <- c(Sys.which(c("google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "microsoft-edge", "msedge")),
                   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge")
  cand <- cand[nzchar(cand) & file.exists(cand)]
  if (length(cand)) cand[1] else NA_character_
}
.dash_url_arquivo <- function(p) { p <- normalizePath(p, winslash = "/", mustWork = FALSE); utils::URLencode(if (grepl("^[A-Za-z]:", p)) paste0("file:///", p) else paste0("file://", p)) }
# Sai: TRUE se o PDF foi gerado.
dash_gerar_pdf <- function(html_arq, pdf_arq, espera = 120) {
  exe <- .dash_navegador(); if (is.na(exe)) return(FALSE)
  perfil <- tempfile("perfil_nav_"); dir.create(perfil, showWarnings = FALSE); on.exit(unlink(perfil, recursive = TRUE), add = TRUE)
  if (file.exists(pdf_arq)) unlink(pdf_arq)
  q <- function(x) shQuote(x, type = if (.Platform$OS.type == "windows") "cmd" else "sh")
  args <- c("--headless", "--disable-gpu", "--hide-scrollbars", "--no-first-run", "--disable-extensions", "--disable-sync", "--no-default-browser-check",
            if (.Platform$OS.type != "windows") "--no-sandbox", q(paste0("--user-data-dir=", perfil)), "--no-pdf-header-footer", "--print-to-pdf-no-header",
            "--virtual-time-budget=8000", q(paste0("--print-to-pdf=", normalizePath(pdf_arq, winslash = "/", mustWork = FALSE))), q(.dash_url_arquivo(html_arq)))
  tryCatch(suppressWarnings(system2(exe, args, stdout = FALSE, stderr = FALSE, wait = TRUE, timeout = espera)), error = function(e) NULL)
  file.exists(pdf_arq) && isTRUE(file.size(pdf_arq) > 1000)
}
