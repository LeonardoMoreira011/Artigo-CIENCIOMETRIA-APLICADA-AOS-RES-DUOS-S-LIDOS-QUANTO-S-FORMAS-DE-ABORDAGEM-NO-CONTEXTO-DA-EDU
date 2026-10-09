# =============================================================================
#  R/08_tipos_comum.R — auxiliares comuns aos construtores de gráfico
# =============================================================================

# =============================================================================
#  CONSTRUÇÃO POR TIPO — cada função devolve list(camadas, info)
# =============================================================================
.serie_longa <- function(dados, xcol, ycols, est, mapa_col = NULL) {
  do.call(rbind, lapply(ycols, function(yc) {
    e <- est[[yc]]
    d <- data.frame(x = dados[[xcol]], y = dados[[yc]], serie = yc, stringsAsFactors = FALSE)
    d$mapa <- if (is.null(mapa_col)) NA_real_ else dados[[mapa_col]]
    erro_col <- function(ref, nome) {
      if (is.null(ref)) return(rep(NA_real_, nrow(dados)))
      cc <- .coluna(dados, ref, paste0("cfg$series[[\"", yc, "\"]]$", nome))
      if (!is.numeric(dados[[cc]])) .erro("Coluna de erro '", cc, "' não é numérica.")
      dados[[cc]]
    }
    d$e_inf <- erro_col(e$erro_inf %||% e$erro, "coluna_erro")
    d$e_sup <- erro_col(e$erro_sup %||% e$erro, "coluna_erro")
    d$e_x <- erro_col(e$erro_x, "coluna_erro_x")
    d
  }))
}

# Guarda o gerador de números aleatórios da sessão e devolve a função que o restaura
# (os gráficos com sorteio, como o jitter do boxplot, não podem mexer na semente do usuário).
.guardar_rng <- function() {
  existia <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  antigo <- if (existia) get(".Random.seed", envir = globalenv(), inherits = FALSE)
  function() {
    if (existia) assign(".Random.seed", antigo, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
      rm(".Random.seed", envir = globalenv())
  }
}

.colunas_y <- function(dados, cfg, excluir = NULL, so_numericas = TRUE) {
  g <- cfg$grafico
  ys <- if (is.null(g$colunas_y)) {
    setdiff(names(dados)[vapply(dados, is.numeric, logical(1))], excluir)
  } else vapply(g$colunas_y, function(r) .coluna(dados, r, "cfg$grafico$colunas_y"), "")
  # tira colunas usadas como erro ou como mapa de cor (referidas por nome OU por número)
  nome_da_coluna <- function(r) if (is.numeric(r) && r >= 1 && r <= ncol(dados)) names(dados)[r] else as.character(r)
  refs <- unlist(lapply(cfg$series, function(s) list(s$coluna_erro, s$coluna_erro_inferior,
                                                     s$coluna_erro_superior, s$coluna_erro_x)),
                 recursive = FALSE)     # lista plana: mantém número como número e texto como texto
  usadas_erro <- vapply(Filter(Negate(is.null), refs), nome_da_coluna, "")
  if (is.null(g$colunas_y)) ys <- setdiff(ys, usadas_erro)
  if (!is.null(cfg$cores$mapear_coluna) && is.null(g$colunas_y))
    ys <- setdiff(ys, nome_da_coluna(cfg$cores$mapear_coluna))
  if (!length(ys)) .erro("Nenhuma coluna Y numérica encontrada. Defina cfg$grafico$colunas_y.")
  if (so_numericas) for (y in ys) if (!is.numeric(dados[[y]]))
    .erro("A coluna '", y, "' não é numérica (veja o relatório de leitura). ",
          "Se o arquivo usa vírgula decimal, defina cfg$dados$decimal_virgula <- TRUE.")
  if (!is.null(g$ordem_itens)) ys <- c(intersect(g$ordem_itens, ys), setdiff(ys, g$ordem_itens))
  ys
}
