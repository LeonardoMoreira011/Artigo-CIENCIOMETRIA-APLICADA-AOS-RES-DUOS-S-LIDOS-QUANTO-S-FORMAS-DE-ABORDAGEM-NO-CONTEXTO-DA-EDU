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

# Detecta UTF-16 pelo BOM (FF FE / FE FF) ou por bytes nulos alternados (texto ASCII em UTF-16).
# Entra: bytes do arquivo e cfg$dados$codificacao. Sai: "UTF-16LE", "UTF-16BE" ou NULL.
.detectar_utf16 <- function(bytes, cod = "auto") {
  cod <- toupper(cod)
  if (cod %in% c("UTF-16LE", "UTF-16BE")) return(cod)
  if (!cod %in% c("AUTO", "UTF-16") || length(bytes) < 2) return(NULL)
  b <- as.integer(bytes)
  if (b[1] == 255L && b[2] == 254L) return("UTF-16LE")
  if (b[1] == 254L && b[2] == 255L) return("UTF-16BE")
  a <- b[seq_len(min(length(b), 4000))]
  nulos_impar <- mean(a[c(TRUE, FALSE)] == 0L)   # bytes nº 1, 3, 5...
  nulos_par   <- mean(a[c(FALSE, TRUE)] == 0L)   # bytes nº 2, 4, 6...
  if (nulos_par > 0.3 && nulos_impar < 0.05) return("UTF-16LE")
  if (nulos_impar > 0.3 && nulos_par < 0.05) return("UTF-16BE")
  if (cod == "UTF-16") "UTF-16LE" else NULL
}

# Converte os bytes de um arquivo UTF-16 em texto UTF-8 (descarta o BOM).
.decodificar_utf16 <- function(bytes, cod16, arquivo) {
  b <- as.integer(bytes)
  if (length(b) >= 2 && ((b[1] == 255L && b[2] == 254L) || (b[1] == 254L && b[2] == 255L))) bytes <- bytes[-(1:2)]
  if (length(bytes) %% 2 == 1) bytes <- bytes[-length(bytes)]
  txt <- iconv(list(bytes), from = cod16, to = "UTF-8")
  if (length(txt) != 1 || is.na(txt))
    .erro("Não consegui decodificar '", arquivo, "' como ", cod16,
          ". Salve como CSV UTF-8 ou defina cfg$dados$codificacao.")
  txt
}

# Lê as linhas (já separadas) como tabela de TEXTO sem embaralhar linhas com mais ou menos
# campos que o cabeçalho (read.table com fill = TRUE empurraria os campos extras para uma
# linha nova). Devolve list(tab, n_cab = nº de campos do cabeçalho, curtas = linhas de dados
# com campos faltando).
.ler_tabela <- function(linhas, sep, cabecalho, arquivo) {
  erro_leitura <- function(e) .erro("Não consegui ler '", arquivo, "' com separador '",
                                    if (sep == "\t") "\\t" else sep, "': ", conditionMessage(e),
                                    "\n  Tente definir cfg$dados$separador manualmente.")
  con <- textConnection(linhas); on.exit(close(con))
  nc <- tryCatch(utils::count.fields(con, sep = sep, quote = "\"", comment.char = "",
                                     blank.lines.skip = FALSE),
                 error = function(e) rep(NA_integer_, length(linhas)))
  nmax <- suppressWarnings(max(nc, na.rm = TRUE))
  ler <- function(...) tryCatch(
    utils::read.table(text = linhas, sep = sep, colClasses = "character", check.names = FALSE,
                      quote = "\"", na.strings = character(0), strip.white = TRUE,
                      comment.char = "", fill = TRUE, blank.lines.skip = TRUE,
                      encoding = "UTF-8", ...),
    error = erro_leitura)
  if (!is.finite(nmax)) {  # contagem impossível (aspas abertas): leitura comum do R
    tab <- ler(header = cabecalho)
    return(list(tab = tab, n_cab = ncol(tab), curtas = integer(0)))
  }
  tab <- ler(header = FALSE, col.names = paste0("V", seq_len(nmax)))
  if (cabecalho) {
    nomes <- as.character(unlist(tab[1, ], use.names = FALSE))
    nomes[is.na(nomes)] <- ""
    tab <- tab[-1, , drop = FALSE]
    names(tab) <- nomes
    rownames(tab) <- NULL
    n_cab <- if (is.na(nc[1])) nmax else nc[1]
    curtas <- which(nc[-1] < n_cab)
  } else {
    n_cab <- nmax
    curtas <- which(nc < nmax)
  }
  list(tab = tab, n_cab = n_cab, curtas = curtas)
}

#' Lê um CSV e devolve um data.frame com números em ponto decimal.
ler_csv <- function(arquivo, opcoes = NULL) {
  op <- opcoes %||% (if (exists("cfg", envir = globalenv())) get("cfg", envir = globalenv())$dados) %||%
    .cfg_ref$dados
  arquivo <- .arquivo_proj(arquivo)
  if (!file.exists(arquivo))
    .erro("Arquivo não encontrado: '", arquivo, "'.\n  Pasta atual: ", getwd(),
          "\n  Dica: abra o projeto pelo arquivo graficos_R.Rproj ou use o caminho completo.")
  tam <- file.info(arquivo)$size
  if (is.na(tam) || tam == 0) .erro("O arquivo '", arquivo, "' está vazio.")
  bytes <- readBin(arquivo, "raw", tam)
  cod <- op$codificacao %||% "auto"
  utf16 <- .detectar_utf16(bytes, cod)
  if (!is.null(utf16)) {
    txt <- .decodificar_utf16(bytes, utf16, arquivo)
    cod <- utf16
  } else {
    if (length(bytes) >= 3 && all(bytes[1:3] == as.raw(c(0xEF, 0xBB, 0xBF)))) bytes <- bytes[-(1:3)]
    bytes <- bytes[bytes != as.raw(0)]
    txt <- rawToChar(bytes)
    if (cod == "auto") cod <- if (validUTF8(txt)) "UTF-8" else "latin1"
    if (toupper(cod) != "UTF-8") {
      conv <- iconv(txt, if (cod == "latin1") "CP1252" else cod, "UTF-8")
      if (is.na(conv)) conv <- iconv(txt, "latin1", "UTF-8")
      txt <- conv
    }
  }
  Encoding(txt) <- "UTF-8"

  linhas <- strsplit(txt, "\r\n|\n|\r")[[1]]
  numeros <- seq_along(linhas)          # nº da linha no arquivo, para as mensagens
  pular <- op$pular_linhas %||% 0
  if (pular > 0) {
    fora <- seq_len(min(pular, length(linhas)))
    linhas <- linhas[-fora]; numeros <- numeros[-fora]
  }
  sep <- op$separador %||% "auto"
  if (length(linhas) && grepl('^"?sep=.', linhas[1])) {
    if (sep == "auto") sep <- substr(sub('^"?sep=', "", linhas[1]), 1, 1)
    linhas <- linhas[-1]; numeros <- numeros[-1]
  }
  cheias <- nzchar(trimws(linhas))
  linhas <- linhas[cheias]; numeros <- numeros[cheias]
  if (!length(linhas)) .erro("Nenhuma linha com dados em '", arquivo, "'.")
  if (sep == "auto") sep <- .detectar_separador(linhas)

  cabecalho <- isTRUE(op$cabecalho %||% TRUE)
  lida <- .ler_tabela(linhas, sep, cabecalho, arquivo)
  tab <- lida$tab
  estrutura <- character(0)
  nomes <- trimws(names(tab))
  nomes[!nzchar(nomes)] <- paste0("V", which(!nzchar(nomes)))
  names(tab) <- make.unique(nomes, sep = "_")
  # campos a mais que o cabeçalho (com conteúdo) ou a menos: avisa em vez de embaralhar
  desloc <- as.integer(cabecalho)
  linhas_arq <- function(i) paste(utils::head(numeros[i + desloc], 3), collapse = ", ")
  for (j in seq_len(max(0, ncol(tab) - lida$n_cab)) + lida$n_cab) {
    cheio <- which(nzchar(trimws(tab[[j]])))
    if (length(cheio))
      estrutura <- c(estrutura, sprintf(
        "%d linha(s) tem(têm) mais campos que o cabeçalho (linha %s do arquivo): os campos extras foram para a coluna '%s'. Confira o separador e as aspas.",
        length(cheio), linhas_arq(cheio), names(tab)[j]))
  }
  if (length(lida$curtas))
    estrutura <- c(estrutura, sprintf(
      "%d linha(s) tem(têm) menos campos que o cabeçalho (linha %s do arquivo): completada(s) com vazio (NA).",
      length(lida$curtas), linhas_arq(lida$curtas)))
  for (a in estrutura) .aviso("Leitura de '", basename(arquivo), "': ", a)
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

  avisos <- character(0)   # conversões numéricas: aparecem no relatório de leitura
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
        nm, length(ruins), linhas_arq(ruins),
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
                  if (is.numeric(v)) "numérica" else if (!is.null(.detectar_tempo(v))) "data" else "texto",
                  sum(is.na(v)),
                  if (is.numeric(v) && any(!is.na(v)))
                    sprintf("(%s a %s)", format(min(v, na.rm = TRUE)), format(max(v, na.rm = TRUE)))
                  else if (!is.numeric(v)) sprintf("ex.: %s", paste(utils::head(unique(v[!is.na(v)]), 3), collapse = ", "))
                  else ""))
    }
    if (length(avisos)) for (a in avisos) cat("  AVISO:", a, "\n")
    cat("\n")
  }
  if (length(c(estrutura, avisos))) attr(dados, "avisos") <- c(estrutura, avisos)
  dados
}

#' Lista as colunas de um data.frame lido
colunas <- function(dados) {
  data.frame(n = seq_along(dados), coluna = names(dados),
             tipo = vapply(dados, function(v)
               if (is.numeric(v)) "numérica" else if (!is.null(.detectar_tempo(v))) "data" else "texto", ""),
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
