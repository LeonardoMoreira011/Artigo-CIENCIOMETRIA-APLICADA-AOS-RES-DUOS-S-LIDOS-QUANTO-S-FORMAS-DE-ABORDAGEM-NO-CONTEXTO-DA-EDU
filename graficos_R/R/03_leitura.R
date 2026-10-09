# =============================================================================
#  R/03_leitura.R — leitura de CSV e referência a colunas
# =============================================================================

# =============================================================================
#  LEITURA DE CSV
# =============================================================================
.contar_fora_aspas <- function(linha, sep) {
  sem <- gsub('"[^"]*"', "", linha)
  lengths(regmatches(sem, gregexpr(sep, sem, fixed = TRUE)))
}

.detectar_separador <- function(linhas) {
  amostra <- utils::head(linhas[nzchar(trimws(linhas))], 30)
  for (sep in c(";", "\t", ",", "|")) {
    n <- vapply(amostra, .contar_fora_aspas, integer(1), sep = sep, USE.NAMES = FALSE)
    if (all(n > 0) && length(unique(n)) == 1) return(sep)
  }
  for (sep in c(";", "\t", ",", "|")) {
    n <- vapply(amostra, .contar_fora_aspas, integer(1), sep = sep, USE.NAMES = FALSE)
    if (mean(n > 0) > 0.8) return(sep)
  }
  ","
}

#' Lê um CSV e devolve um data.frame com números em ponto decimal.
ler_csv <- function(arquivo, opcoes = NULL) {
  op <- opcoes %||% (if (exists("cfg", envir = globalenv())) get("cfg", envir = globalenv())$dados) %||%
    .cfg_ref$dados
  if (!file.exists(arquivo))
    .erro("Arquivo não encontrado: '", arquivo, "'.\n  Pasta atual: ", getwd(),
          "\n  Dica: abra o projeto pelo arquivo graficos_R.Rproj ou use o caminho completo.")
  tam <- file.info(arquivo)$size
  if (is.na(tam) || tam == 0) .erro("O arquivo '", arquivo, "' está vazio.")
  bytes <- readBin(arquivo, "raw", tam)
  if (length(bytes) >= 3 && all(bytes[1:3] == as.raw(c(0xEF, 0xBB, 0xBF)))) bytes <- bytes[-(1:3)]
  bytes <- bytes[bytes != as.raw(0)]
  txt <- rawToChar(bytes)

  cod <- op$codificacao %||% "auto"
  if (cod == "auto") cod <- if (validUTF8(txt)) "UTF-8" else "latin1"
  if (toupper(cod) != "UTF-8") {
    conv <- iconv(txt, if (cod == "latin1") "CP1252" else cod, "UTF-8")
    if (is.na(conv)) conv <- iconv(txt, "latin1", "UTF-8")
    txt <- conv
  }
  Encoding(txt) <- "UTF-8"

  linhas <- strsplit(txt, "\r\n|\n|\r")[[1]]
  pular <- op$pular_linhas %||% 0
  if (pular > 0) linhas <- linhas[-seq_len(min(pular, length(linhas)))]
  sep <- op$separador %||% "auto"
  if (length(linhas) && grepl('^"?sep=.', linhas[1])) {
    if (sep == "auto") sep <- substr(sub('^"?sep=', "", linhas[1]), 1, 1)
    linhas <- linhas[-1]
  }
  linhas <- linhas[nzchar(trimws(linhas))]
  if (!length(linhas)) .erro("Nenhuma linha com dados em '", arquivo, "'.")
  if (sep == "auto") sep <- .detectar_separador(linhas)

  tab <- tryCatch(
    utils::read.table(text = linhas, sep = sep, header = isTRUE(op$cabecalho %||% TRUE),
                      colClasses = "character", check.names = FALSE, quote = "\"",
                      na.strings = character(0), strip.white = TRUE, comment.char = "",
                      fill = TRUE, blank.lines.skip = TRUE, encoding = "UTF-8"),
    error = function(e) .erro("Não consegui ler '", arquivo, "' com separador '",
                              if (sep == "\t") "\\t" else sep, "': ", conditionMessage(e),
                              "\n  Tente definir cfg$dados$separador manualmente."))
  nomes <- trimws(names(tab))
  nomes[!nzchar(nomes)] <- paste0("V", which(!nzchar(nomes)))
  names(tab) <- make.unique(nomes, sep = "_")
  # remove colunas totalmente vazias no fim (separador sobrando)
  vazias <- vapply(tab, function(v) all(!nzchar(trimws(v))), logical(1))
  if (any(vazias)) tab <- tab[, !vazias, drop = FALSE]

  na_txt <- op$valores_ausentes %||% c("", "NA")
  limpas <- lapply(tab, function(v) { v <- trimws(v); v[v %in% na_txt] <- NA; v })

  # Decide se a vírgula é decimal
  padrao_virg  <- "^[-+]?([0-9]{1,3}(\\.[0-9]{3})+|[0-9]*),[0-9]+([eE][-+]?[0-9]+)?$"
  padrao_ponto <- "^[-+]?[0-9]*\\.[0-9]+([eE][-+]?[0-9]+)?$"
  todos <- unlist(limpas, use.names = FALSE)
  todos <- todos[!is.na(todos)]
  dv <- op$decimal_virgula %||% "auto"
  if (identical(dv, "auto")) {
    dv <- sep != "," && sum(grepl(padrao_virg, todos)) > sum(grepl(padrao_ponto, todos))
  }

  avisos <- character(0)
  conv <- lapply(names(limpas), function(nm) {
    v <- limpas[[nm]]
    v2 <- v
    if (isTRUE(dv)) {
      milhar <- !is.na(v2) & grepl("^[-+]?[0-9]{1,3}(\\.[0-9]{3})+(,[0-9]+)?$", v2)
      v2[milhar] <- gsub(".", "", v2[milhar], fixed = TRUE)
      v2 <- sub(",", ".", v2, fixed = TRUE)
    }
    num <- suppressWarnings(as.numeric(v2))
    ok <- sum(!is.na(num)); tot <- sum(!is.na(v))
    if (tot > 0 && ok == tot) return(num)
    if (tot > 0 && ok / tot >= 0.5) {
      ruins <- which(!is.na(v) & is.na(num))
      avisos <<- c(avisos, sprintf(
        "Coluna '%s': %d valor(es) não numérico(s) virou(aram) NA. Ex.: linha %s = '%s'",
        nm, length(ruins), paste(utils::head(ruins, 3) + 1, collapse = ", "),
        paste(utils::head(v[ruins], 3), collapse = "', '")))
      return(num)
    }
    v
  })
  dados <- as.data.frame(stats::setNames(conv, names(limpas)), check.names = FALSE,
                         stringsAsFactors = FALSE)

  attr(dados, "arquivo") <- arquivo
  if (isTRUE(op$relatorio %||% TRUE)) {
    cat("\n=== Leitura de", basename(arquivo), "===\n")
    cat(sprintf("Codificação: %s | Separador: '%s' | Decimal no arquivo: %s -> convertido para ponto\n",
                cod, if (sep == "\t") "\\t" else sep, if (isTRUE(dv)) "vírgula" else "ponto"))
    cat(sprintf("%d linhas x %d colunas\n", nrow(dados), ncol(dados)))
    for (i in seq_along(dados)) {
      v <- dados[[i]]
      cat(sprintf("  [%d] %-28s %-9s NAs: %-4d %s\n", i, paste0("'", names(dados)[i], "'"),
                  if (is.numeric(v)) "numérica" else "texto", sum(is.na(v)),
                  if (is.numeric(v) && any(!is.na(v)))
                    sprintf("(%s a %s)", format(min(v, na.rm = TRUE)), format(max(v, na.rm = TRUE)))
                  else if (!is.numeric(v)) sprintf("ex.: %s", paste(utils::head(unique(v[!is.na(v)]), 3), collapse = ", "))
                  else ""))
    }
    if (length(avisos)) for (a in avisos) cat("  AVISO:", a, "\n")
    cat("\n")
  }
  if (length(avisos)) attr(dados, "avisos") <- avisos
  dados
}

#' Lista as colunas de um data.frame lido
colunas <- function(dados) {
  data.frame(n = seq_along(dados), coluna = names(dados),
             tipo = vapply(dados, function(v) if (is.numeric(v)) "numérica" else "texto", ""),
             row.names = NULL)
}

.coluna <- function(dados, ref, onde) {
  if (is.null(ref)) return(NULL)
  if (is.numeric(ref)) {
    if (ref < 1 || ref > ncol(dados))
      .erro(onde, ": coluna número ", ref, " não existe (o arquivo tem ", ncol(dados), " colunas).")
    return(names(dados)[ref])
  }
  if (!ref %in% names(dados)) {
    sug <- names(dados)[utils::adist(ref, names(dados), ignore.case = TRUE) <= max(2, nchar(ref) %/% 4)]
    .erro(onde, ": coluna '", ref, "' não encontrada.",
          if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "",
          "\n  Colunas disponíveis: ", paste0("'", names(dados), "'", collapse = ", "))
  }
  ref
}
