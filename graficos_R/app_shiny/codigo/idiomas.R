# =============================================================================
#  app_shiny/codigo/idiomas.R — o app em português (BR), inglês e espanhol
# =============================================================================
#  Todos os textos do app são escritos em português. Para outro idioma, cada texto é procurado no dicionário
#  app_shiny/idiomas/en.json (ou es.json): {"texto em português": "translation"}. Texto sem tradução aparece em português.
#  Para acrescentar um texto novo: escreva em português no código e acrescente a linha nos dois .json.
#  O idioma vem do endereço (?idioma=en) e é escolhido no seletor do cabeçalho.
# =============================================================================

IDIOMAS <- c("Português (BR)" = "pt", "English" = "en", "Español" = "es")

.i18n <- new.env()
.i18n$idioma <- "pt"          # idioma do que está sendo montado agora (a tela)
.i18n$dic <- list()

carregar_dicionarios <- function(pasta) {
  for (i in setdiff(unname(IDIOMAS), "pt")) {
    arq <- file.path(pasta, paste0(i, ".json"))
    if (file.exists(arq)) .i18n$dic[[i]] <- unlist(jsonlite::fromJSON(arq, simplifyVector = TRUE))
  }
  invisible(names(.i18n$dic))
}

# Traduz um texto (ou vários). Sem tradução, devolve o próprio texto.
tr <- function(x, idioma = .i18n$idioma) {
  if (is.null(x) || !is.character(x) || !length(x) || identical(idioma, "pt") || inherits(x, "html")) return(x)
  d <- .i18n$dic[[idioma]]; if (is.null(d)) return(x)
  r <- unname(d[x]); ifelse(is.na(r), x, r)
}
# Texto com valores no meio: o molde (com %s, %d, %.1f) é traduzido e depois preenchido.
trf <- function(molde, ..., idioma = .i18n$idioma) sprintf(tr(molde, idioma), ...)

# Traduz os NOMES de uma lista de opções (o que aparece na tela; os valores não mudam). Vale para listas com grupos.
tr_nomes <- function(x, idioma = .i18n$idioma) {
  if (identical(idioma, "pt") || is.null(x)) return(x)
  if (is.list(x)) { y <- lapply(x, tr_nomes, idioma = idioma); names(y) <- tr(names(x), idioma); return(y) }
  if (!is.null(names(x))) names(x) <- tr(names(x), idioma)
  x
}

# Traduz uma árvore de HTML (a tela montada em português): textos e alguns atributos (placeholder, title, alt, label...).
.ATRIBUTOS_TRADUZIDOS <- c("placeholder", "title", "alt", "label", "aria-label", "data-copiado", "data-placeholder", "data-sair")
traduzir_html <- function(x, idioma = .i18n$idioma) {
  if (identical(idioma, "pt") || is.null(x)) return(x)
  if (is.character(x)) return(if (inherits(x, "html") || length(x) != 1) x else tr(x, idioma))
  if (inherits(x, "shiny.tag")) {
    a <- x$attribs
    for (n in intersect(names(a), .ATRIBUTOS_TRADUZIDOS)) if (is.character(a[[n]]) && length(a[[n]]) == 1) a[[n]] <- tr(a[[n]], idioma)
    x$attribs <- a
    x$children <- lapply(x$children, traduzir_html, idioma = idioma)
    return(x)
  }
  if (is.list(x)) { at <- attributes(x); y <- lapply(x, traduzir_html, idioma = idioma); attributes(y) <- at; return(y) }
  x
}

# Idioma pedido na página: ?idioma=en | es | pt  (padrão: pt)
idioma_do_pedido <- function(request) {
  q <- tryCatch(shiny::parseQueryString(request$QUERY_STRING %||% ""), error = function(e) list())
  i <- q[["idioma"]] %||% "pt"
  if (i %in% unname(IDIOMAS)) i else "pt"
}

# Roda uma expressão com o idioma do motor (mensagens e títulos automáticos do gráfico) no idioma da tela.
com_idioma <- function(idioma, expr) {
  ant <- options(cinabro.idioma = idioma); on.exit(options(ant), add = TRUE)
  force(expr)
}
