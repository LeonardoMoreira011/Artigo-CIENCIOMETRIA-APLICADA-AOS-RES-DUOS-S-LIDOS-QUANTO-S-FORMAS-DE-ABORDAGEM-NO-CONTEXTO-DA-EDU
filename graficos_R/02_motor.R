# =============================================================================
#  02_motor.R  —  MOTOR DE GRÁFICOS (não precisa editar)
# =============================================================================
#  Funções para o usuário:
#    ler_csv(arquivo)            lê o CSV (ponto decimal garantido)
#    colunas(dados)              lista as colunas lidas
#    plotar(dados, cfg)          monta o gráfico (ou painéis) a partir do cfg
#    visualizar(g, cfg)          prévia FIEL ao arquivo final (tamanho/fontes)
#    salvar(g, cfg)              exporta nos formatos de cfg$exportacao
#    exportar_lote(pasta, cfg)   mesmo estilo para todos os CSVs de uma pasta
#    salvar_estilo(cfg, nome)    guarda o visual em estilos/<nome>.R
#    carregar_estilo(nome, cfg)  aplica um estilo salvo
#    resetar_cfg()               volta tudo ao padrão do 01_config.R
#    ajuda(), galeria(), mostrar_paletas(), listar_fontes()  (04_catalogo.R)
# =============================================================================

options(OutDec = ".", scipen = 6)

local({
  falta <- c("ggplot2", "scales", "patchwork")[
    !vapply(c("ggplot2", "scales", "patchwork"), requireNamespace, logical(1), quietly = TRUE)]
  if (length(falta))
    stop("Pacotes ausentes: ", paste(falta, collapse = ", "),
         ". Rode primeiro o arquivo 00_instalar_pacotes.R", call. = FALSE)
  if (utils::packageVersion("ggplot2") < "3.5.0")
    stop("ggplot2 ", utils::packageVersion("ggplot2"), " é antigo. É preciso >= 3.5.0. ",
         "Rode 00_instalar_pacotes.R para atualizar.", call. = FALSE)
  if (utils::packageVersion("scales") < "1.3.0")
    stop("scales ", utils::packageVersion("scales"), " é antigo. É preciso >= 1.3.0.", call. = FALSE)
  if (utils::packageVersion("patchwork") < "1.2.0")
    stop("patchwork ", utils::packageVersion("patchwork"), " é antigo. É preciso >= 1.2.0.", call. = FALSE)
})

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
})

`%||%` <- function(a, b) if (is.null(a)) b else a
.tem <- function(p) requireNamespace(p, quietly = TRUE)
.R42 <- getRversion() >= "4.2.0"

# Pasta do projeto e cópia de referência do cfg (para detectar erros de digitação)
.motor_pasta <- getwd()
.cfg_ref <- local({
  arq <- file.path(.motor_pasta, "01_config.R")
  if (file.exists(arq)) { e <- new.env(); sys.source(arq, envir = e); e$cfg } else NULL
})

# ---- Conversões de unidade (tudo do usuário em pt) --------------------------
# ggplot: linewidth em "mm" de ggplot; texto/símbolo em mm; stroke próprio.
.lw <- function(pt) pt * 96 / 72 / ggplot2::.pt          # espessura de linha
.tx <- function(pt) pt / ggplot2::.pt                    # texto e símbolos
.st <- function(pt) pt * 96 / 72 * 2 / ggplot2::.stroke  # borda de símbolo

.aviso <- function(...) warning(paste0(...), call. = FALSE, immediate. = TRUE)
.erro  <- function(...) stop(paste0(...), call. = FALSE)

# ---- Cores ------------------------------------------------------------------
.cor <- function(x, onde = "cor") {
  if (is.null(x)) return(NULL)
  if (length(x) == 3 && is.numeric(x)) return(grDevices::rgb(x[1], x[2], x[3], maxColorValue = 255))
  if (length(x) == 1 && is.na(x)) return(NA_character_)
  if (identical(x, "transparente")) return("transparent")
  ok <- tryCatch({ grDevices::col2rgb(x); TRUE }, error = function(e) FALSE)
  if (!ok) .erro("Cor inválida em ", onde, ": '", x, "'. Use nome (\"red\"), \"#RRGGBB\" ou c(R,G,B).")
  x
}
.alfa <- function(cor, a) {
  if (is.null(cor) || (length(cor) == 1 && is.na(cor))) return(cor)
  if (is.null(a) || a >= 1) return(cor)
  scales::alpha(cor, a)
}
.cor_media <- function(c1, c2) grDevices::colorRampPalette(c(c1, c2))(3)[2]
.luminancia <- function(cor) {
  v <- grDevices::col2rgb(cor) / 255
  sum(c(0.299, 0.587, 0.114) * v)
}

.PALETAS <- list(
  classico  = c("#000000", "#D62728", "#1F4E9E", "#2CA02C", "#8E44AD", "#FF7F0E",
                "#17BECF", "#8C564B", "#E377C2", "#7F7F7F"),
  okabe_ito = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9",
                "#000000", "#F0E442"),
  tableau   = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F", "#EDC948",
                "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC")
)

.paleta <- function(nome, n, cfg_cores = NULL) {
  n <- max(n, 1)
  base <- if (nome %in% names(.PALETAS)) {
    .PALETAS[[nome]]
  } else if (nome %in% c("viridis", "magma", "plasma", "cividis", "inferno")) {
    if (!.tem("viridisLite")) .erro("Paleta '", nome, "' precisa do pacote viridisLite.")
    fun <- getExportedValue("viridisLite", nome)
    return(fun(n, end = if (nome == "viridis" || nome == "cividis") 0.92 else 0.88))
  } else if (nome == "cinza") {
    return(grDevices::grey.colors(n, start = 0, end = 0.75))
  } else if (startsWith(nome, "brewer_")) {
    if (!.tem("RColorBrewer")) .erro("Paletas brewer_ precisam do pacote RColorBrewer.")
    pal <- sub("^brewer_", "", nome)
    info <- RColorBrewer::brewer.pal.info
    if (!pal %in% rownames(info))
      .erro("Paleta ColorBrewer '", pal, "' não existe. Opções: ",
            paste(rownames(info), collapse = ", "))
    RColorBrewer::brewer.pal(info[pal, "maxcolors"], pal)
  } else if (nome == "personalizada") {
    vapply(cfg_cores$personalizada, .cor, character(1), onde = "cores$personalizada")
  } else {
    .erro("Paleta '", nome, "' desconhecida. Opções: classico, okabe_ito, tableau, viridis, ",
          "magma, plasma, cividis, cinza, brewer_<nome>, personalizada. Veja mostrar_paletas().")
  }
  if (n <= length(base)) base[seq_len(n)] else grDevices::colorRampPalette(base)(n)
}

# Gradiente de 2 cores (padrão grid). grupo = TRUE: relativo ao conjunto inteiro.
.gradiente <- function(c1, c2, direcao, grupo = FALSE) {
  cores <- c(c1, c2)
  if (grepl("invertido", direcao)) cores <- rev(cores)
  dir <- sub("_invertido", "", direcao)
  args <- list(colours = cores)
  if (.R42) args$group <- grupo
  if (dir == "radial") {
    args$colours <- rev(args$colours)   # centro = cor2 (clara), borda = cor da série
    args <- c(args, list(cx1 = 0.5, cy1 = 0.5, r1 = 0, cx2 = 0.5, cy2 = 0.5, r2 = 0.5))
    return(do.call(grid::radialGradient, args))
  }
  xy <- switch(dir,
               vertical   = c(0.5, 0, 0.5, 1),
               horizontal = c(0, 0.5, 1, 0.5),
               diagonal   = c(0, 0, 1, 1),
               .erro("gradiente_direcao '", direcao, "' inválida."))
  args <- c(args, list(x1 = xy[1], y1 = xy[2], x2 = xy[3], y2 = xy[4]))
  do.call(grid::linearGradient, args)
}

# ---- Texto com sobrescrito ^{ } e subscrito _{ } -----------------------------
.tem_formatacao <- function(s) is.character(s) && length(s) == 1 && grepl("[\\^_]\\{", s)

# Converte "Área (m^{2})" em string plotmath: "Área (m"*""^"2"*")"
.plotmath <- function(s) {
  if (!.tem_formatacao(s)) return(deparse(s))
  partes <- character(0)
  resto <- s
  while (nchar(resto) > 0) {
    m <- regexpr("[\\^_]\\{[^}]*\\}", resto)
    if (m == -1) { partes <- c(partes, deparse(resto)); break }
    if (m > 1) partes <- c(partes, deparse(substr(resto, 1, m - 1)))
    tok <- regmatches(resto, m)
    conteudo <- substr(tok, 3, nchar(tok) - 1)
    partes <- c(partes, if (substr(tok, 1, 1) == "^")
      paste0('""^', deparse(conteudo)) else paste0('""[', deparse(conteudo), "]"))
    resto <- substr(resto, m + attr(m, "match.length"), nchar(resto))
  }
  paste(partes, collapse = "*")
}
.texto <- function(s) {
  if (is.null(s)) return(NULL)
  if (.tem_formatacao(s)) parse(text = .plotmath(s))[[1]] else s
}
.rotulos_legenda <- function(x) {
  if (any(vapply(x, .tem_formatacao, logical(1))))
    parse(text = vapply(x, .plotmath, character(1)))
  else x
}

# ---- Mescla de listas (para painéis e estilos) -------------------------------
.mesclar <- function(base, novo) {
  if (!is.list(novo) || is.null(names(novo))) return(novo)
  for (nm in names(novo)) {
    if (is.list(base[[nm]]) && !is.null(names(base[[nm]])) && is.list(novo[[nm]]) &&
        !is.null(names(novo[[nm]])) && !nm %in% c("series")) {
      base[[nm]] <- .mesclar(base[[nm]], novo[[nm]])
    } else if (nm == "series" && is.list(novo[[nm]])) {
      for (s in names(novo[[nm]]))
        base$series[[s]] <- utils::modifyList(base$series[[s]] %||% list(), novo[[nm]][[s]])
    } else {
      base[nm] <- list(novo[[nm]])
    }
  }
  base
}

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

# =============================================================================
#  VALIDAÇÃO DO cfg
# =============================================================================
.OPCOES <- list(
  "grafico$tipo" = c("pontos", "linha", "linha_pontos", "area", "area_empilhada", "barras",
                     "pizza", "histograma", "densidade", "ecdf", "boxplot"),
  "cores$preenchimento" = c("solido", "gradiente"),
  "cores$gradiente_direcao" = c("vertical", "vertical_invertido", "horizontal",
                                "horizontal_invertido", "diagonal", "radial"),
  "linhas$ligacao" = c("reta", "spline", "degrau_hv", "degrau_vh", "degrau_meio"),
  "linhas$preencher_area" = c("nenhum", "ate_zero", "ate_base", "proxima_serie"),
  "linhas$linhas_queda" = c("nenhuma", "vertical", "horizontal", "ambas"),
  "linhas$erro_lado" = c("ambos", "superior", "inferior"),
  "linhas$rotulos_dados" = c("nenhum", "y", "x", "xy", "serie"),
  "barras$arranjo" = c("agrupado", "empilhado", "empilhado_100"),
  "barras$orientacao" = c("vertical", "horizontal"),
  "barras$rotulos_posicao" = c("fora", "dentro", "centro"),
  "pizza$sentido" = c("horario", "anti_horario"),
  "pizza$rotulos_posicao" = c("fora", "dentro", "borda"),
  "distribuicao$medida" = c("contagem", "frequencia", "percentual", "densidade"),
  "boxplot$variacao" = c("box", "box_pontos", "meio_box", "violino", "violino_box", "media_erro"),
  "boxplot$orientacao" = c("vertical", "horizontal"),
  "boxplot$bigode" = c("tukey", "percentis", "min_max", "desvio_padrao", "erro_padrao", "ic95"),
  "boxplot$bigode_lado" = c("ambos", "superior", "inferior"),
  "boxplot$pontos_disposicao" = c("jitter", "coluna", "enxame"),
  "boxplot$media_erro_tipo" = c("desvio_padrao", "erro_padrao", "ic95"),
  "boxplot$media_erro_estilo" = c("barra", "ponto"),
  "eixo_y2$modo" = c("independente", "transformado"),
  "legenda$posicao" = c("dentro", "direita", "esquerda", "topo", "base"),
  "titulos$alinhamento" = c("esquerda", "centro", "direita"),
  "paineis$direcao" = c("vertical", "horizontal"),
  "paineis$rotulos_eixo_comum" = c("ultimo", "todos"),
  "paineis$formato_letra" = c("(a)", "a)", "a", "(A)", "A", "(i)"),
  "exportacao$unidade" = c("cm", "mm", "in")
)
.OPCOES_EIXO <- list(
  escala = c("linear", "log10", "ln", "log2", "reciproco", "raiz"),
  ticks_modo = c("auto", "incremento", "quantidade", "min_max", "manual"),
  direcao_maiores = c("dentro", "fora", "ambos", "nenhum"),
  direcao_menores = c("dentro", "fora", "ambos", "nenhum"),
  notacao = c("normal", "milhar", "cientifica", "cientifica_E", "potencia10", "percentual")
)

.checar_opcao <- function(valor, opcoes, onde) {
  if (is.null(valor)) return(invisible())
  if (!is.character(valor) || length(valor) != 1 || !valor %in% opcoes) {
    sug <- opcoes[utils::adist(as.character(valor)[1], opcoes, ignore.case = TRUE) <= 3]
    .erro("cfg$", onde, " = '", paste(valor, collapse = ","), "' não é válido.",
          if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "",
          "\n  OPÇÕES: ", paste0('"', opcoes, '"', collapse = " | "))
  }
}

.checar_nomes <- function(cfg) {
  ref <- .cfg_ref
  if (is.null(ref)) return(invisible())
  livres <- c("series", "referencias", "interno")
  for (bl in names(cfg)) {
    if (bl %in% c(".interno")) next
    if (!bl %in% names(ref)) {
      sug <- names(ref)[utils::adist(bl, names(ref)) <= 3]
      .aviso("Bloco cfg$", bl, " não existe e será ignorado.",
             if (length(sug)) paste0(" Você quis dizer cfg$", sug[1], "?") else "")
      next
    }
    if (bl %in% livres || !is.list(cfg[[bl]]) || is.null(names(cfg[[bl]]))) next
    desconhecidos <- setdiff(names(cfg[[bl]]), c(names(ref[[bl]]), ".ocultar_extremo"))
    for (p in desconhecidos) {
      sug <- names(ref[[bl]])[utils::adist(p, names(ref[[bl]])) <= 3]
      .aviso("Parâmetro cfg$", bl, "$", p, " não existe e será ignorado.",
             if (length(sug)) paste0(" Você quis dizer cfg$", bl, "$", sug[1], "?") else "")
    }
  }
}

.validar <- function(cfg) {
  .checar_nomes(cfg)
  for (k in names(.OPCOES)) {
    p <- strsplit(k, "$", fixed = TRUE)[[1]]
    .checar_opcao(cfg[[p[1]]][[p[2]]], .OPCOES[[k]], k)
  }
  for (ax in c("eixo_x", "eixo_y")) {
    e <- cfg[[ax]]
    for (k in names(.OPCOES_EIXO)) .checar_opcao(e[[k]], .OPCOES_EIXO[[k]], paste0(ax, "$", k))
    if (!is.null(e$inicio) && !is.null(e$fim)) {
      if (!is.numeric(e$inicio) || !is.numeric(e$fim))
        .erro("cfg$", ax, "$inicio e $fim devem ser números (use ponto decimal: 2.5).")
      if (e$inicio >= e$fim)
        .erro("cfg$", ax, "$inicio (", e$inicio, ") deve ser menor que cfg$", ax, "$fim (", e$fim,
              "). Para inverter o eixo use cfg$", ax, "$inverter <- TRUE.")
    }
    if (identical(e$ticks_modo, "incremento") && is.null(e$incremento))
      .erro("cfg$", ax, "$ticks_modo = \"incremento\" exige cfg$", ax, "$incremento (ex.: 10).")
    if (!is.null(e$incremento) && (!is.numeric(e$incremento) || e$incremento <= 0))
      .erro("cfg$", ax, "$incremento deve ser um número > 0.")
    if (identical(e$ticks_modo, "quantidade") && is.null(e$quantidade))
      .erro("cfg$", ax, "$ticks_modo = \"quantidade\" exige cfg$", ax, "$quantidade (ex.: 5).")
    if (identical(e$ticks_modo, "manual") && is.null(e$ticks_manuais))
      .erro("cfg$", ax, "$ticks_modo = \"manual\" exige cfg$", ax, "$ticks_manuais (ex.: c(0, 5, 10)).")
    if (!is.null(e$rotulos_manuais) && length(e$rotulos_manuais) != length(e$ticks_manuais))
      .erro("cfg$", ax, "$rotulos_manuais tem ", length(e$rotulos_manuais),
            " textos mas ticks_manuais tem ", length(e$ticks_manuais), " posições.")
  }
  if (isTRUE(cfg$eixo_y2$ativo)) {
    for (k in c("ticks_modo", "notacao")) .checar_opcao(cfg$eixo_y2[[k]], .OPCOES_EIXO[[k]], paste0("eixo_y2$", k))
  }
  if (cfg$legenda$posicao == "dentro") {
    if (any(c(cfg$legenda$dentro_x, cfg$legenda$dentro_y) < 0 | c(cfg$legenda$dentro_x, cfg$legenda$dentro_y) > 1))
      .erro("cfg$legenda$dentro_x e dentro_y devem estar entre 0 e 1.")
  }
  if (!is.null(cfg$pizza$raio_furo) && (cfg$pizza$raio_furo < 0 || cfg$pizza$raio_furo > 0.9))
    .erro("cfg$pizza$raio_furo deve estar entre 0 e 0.9.")
  if (!identical(cfg$legenda$mostrar, "auto") && !is.logical(cfg$legenda$mostrar))
    .erro("cfg$legenda$mostrar deve ser \"auto\", TRUE ou FALSE.")
  invisible(TRUE)
}

# =============================================================================
#  ESTILO DAS SÉRIES
# =============================================================================
.CHAVES_SERIE <- c("cor", "cor2", "simbolo", "tamanho_simbolo_pt", "espessura_borda_pt",
                   "preenchimento_simbolo", "linha_espessura_pt", "linha_tipo", "opacidade",
                   "opacidade_preenchimento", "nome_legenda", "mostrar_na_legenda", "eixo",
                   "coluna_erro", "coluna_erro_inferior", "coluna_erro_superior", "coluna_erro_x")
.SIMBOLOS_INC <- c(21, 22, 24, 23, 25, 1, 0, 2, 5, 6, 3, 4, 8)
.LINHAS_INC <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")

.estilos <- function(cfg, itens, grupo_gradiente = FALSE, inverter_grad = FALSE) {
  n <- length(itens)
  cores <- .paleta(cfg$cores$paleta, n, cfg$cores)
  if (!isTRUE(cfg$.interno$em_painel)) for (s in setdiff(names(cfg$series), itens))
    .aviso("cfg$series[[\"", s, "\"]] não corresponde a nenhuma série/categoria deste gráfico. ",
           "Disponíveis: ", paste0("'", itens, "'", collapse = ", "))
  out <- lapply(seq_len(n), function(i) {
    it <- itens[i]
    s <- cfg$series[[it]] %||% list()
    ruins <- setdiff(names(s), .CHAVES_SERIE)
    for (r in ruins) {
      sug <- .CHAVES_SERIE[utils::adist(r, .CHAVES_SERIE) <= 3]
      .aviso("cfg$series[[\"", it, "\"]]$", r, " não existe.",
             if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "")
    }
    p <- cfg$serie_padrao
    cor <- .cor(s$cor %||% cores[i], paste0("series '", it, "'"))
    cor2 <- .cor(s$cor2 %||% cfg$cores$gradiente_cor2, paste0("series '", it, "' cor2"))
    simb <- s$simbolo %||% (if (isTRUE(cfg$cores$incrementar_simbolo))
      .SIMBOLOS_INC[(i - 1) %% length(.SIMBOLOS_INC) + 1] else p$simbolo)
    lt <- s$linha_tipo %||% (if (isTRUE(cfg$cores$incrementar_tipo_linha))
      .LINHAS_INC[(i - 1) %% length(.LINHAS_INC) + 1] else p$linha_tipo)
    ps <- s$preenchimento_simbolo %||% p$preenchimento_simbolo
    fill_simb <- switch(ps, serie = cor, branco = "white", vazio = NA_character_,
                        .cor(ps, paste0("preenchimento_simbolo de '", it, "'")))
    op <- s$opacidade %||% p$opacidade
    opf <- s$opacidade_preenchimento %||% p$opacidade_preenchimento
    preench <- if (identical(cfg$cores$preenchimento, "gradiente")) {
      dir <- cfg$cores$gradiente_direcao
      if (inverter_grad) dir <- switch(sub("_invertido", "", dir),
                                       vertical = sub("vertical", "horizontal", dir),
                                       horizontal = sub("horizontal", "vertical", dir), dir)
      .gradiente(.alfa(cor, opf), .alfa(cor2, opf), dir, grupo_gradiente)
    } else .alfa(cor, opf)
    list(item = it,
         rotulo = s$nome_legenda %||% it,
         legenda = s$mostrar_na_legenda %||% TRUE,
         cor = cor, cor2 = cor2,
         cor_solida = .alfa(cor, opf),
         preench = preench,
         simbolo = simb,
         tam = s$tamanho_simbolo_pt %||% p$tamanho_simbolo_pt,
         borda = s$espessura_borda_pt %||% p$espessura_borda_pt,
         fill_simb = fill_simb,
         lw = s$linha_espessura_pt %||% p$linha_espessura_pt,
         lt = lt, op = op, opf = opf,
         eixo = s$eixo %||% "y1",
         erro = s$coluna_erro, erro_inf = s$coluna_erro_inferior,
         erro_sup = s$coluna_erro_superior, erro_x = s$coluna_erro_x)
  })
  stats::setNames(out, itens)
}

# Escalas manuais "fundidas" numa só legenda
.escalas_legenda <- function(est, aes_usadas, cfg) {
  itens <- names(est)
  quebras <- itens[vapply(est, function(e) isTRUE(e$legenda), logical(1))]
  if (isTRUE(cfg$legenda$inverter_ordem)) quebras <- rev(quebras)
  rotulos <- .rotulos_legenda(vapply(est[quebras], function(e) as.character(e$rotulo), ""))
  nome <- if (is.null(cfg$legenda$titulo)) NULL else .texto(cfg$legenda$titulo)
  guia <- guide_legend(ncol = cfg$legenda$n_colunas, byrow = TRUE)
  valores <- list(
    colour    = function() stats::setNames(vapply(est, function(e) e$cor, ""), itens),
    fill      = function() stats::setNames(lapply(est, function(e) e$preench), itens),
    fill_simb = function() stats::setNames(vapply(est, function(e) e$fill_simb, ""), itens),
    shape     = function() stats::setNames(vapply(est, function(e) e$simbolo, 0), itens),
    size      = function() stats::setNames(vapply(est, function(e) .tx(e$tam), 0), itens),
    stroke    = function() stats::setNames(vapply(est, function(e) .st(e$borda), 0), itens),
    linetype  = function() stats::setNames(vapply(est, function(e) as.character(e$lt), ""), itens),
    linewidth = function() stats::setNames(vapply(est, function(e) .lw(e$lw), 0), itens),
    alpha     = function() stats::setNames(vapply(est, function(e) e$op, 0), itens)
  )
  radial <- identical(cfg$cores$preenchimento, "gradiente") && grepl("radial", cfg$cores$gradiente_direcao)
  lapply(aes_usadas, function(a) {
    v <- valores[[a]]()
    if (a == "fill" && radial && length(quebras))
      guia <- guide_legend(ncol = cfg$legenda$n_colunas, byrow = TRUE,
                           override.aes = list(fill = unname(vapply(est[quebras], function(e) e$cor_solida, ""))))
    estetica <- if (a == "fill_simb") "fill" else a
    if (estetica == "fill" && !is.list(v)) v <- as.list(v)
    if (length(quebras) == 0)
      return(scale_discrete_manual(aesthetics = estetica, values = v, guide = "none"))
    scale_discrete_manual(aesthetics = estetica, values = v, breaks = quebras,
                          labels = rotulos, name = nome, guide = guia, drop = FALSE,
                          na.value = NA)
  })
}

# =============================================================================
#  EIXOS: limites, ticks maiores/menores, rótulos
# =============================================================================
.base_log <- function(escala) switch(escala, log10 = 10, ln = exp(1), log2 = 2, NA)

.transformacao <- function(escala, inverter) {
  t <- switch(escala,
              linear = scales::transform_identity(),
              log10 = scales::transform_log10(),
              ln = scales::transform_log(),
              log2 = scales::transform_log(2),
              reciproco = scales::transform_reciprocal(),
              raiz = scales::transform_sqrt())
  if (isTRUE(inverter)) t <- scales::transform_compose(t, scales::transform_reverse())
  t
}

.limites_auto <- function(faixa, escala) {
  faixa <- faixa[is.finite(faixa)]
  if (!length(faixa)) return(c(0, 1))
  r <- range(faixa)
  b <- .base_log(escala)
  if (!is.na(b)) {
    r <- r[r > 0]
    if (!length(r)) .erro("Escala logarítmica precisa de valores > 0.")
    r <- range(r)
    lo <- b^floor(log(r[1], b) + 1e-9); hi <- b^ceiling(log(r[2], b) - 1e-9)
    if (lo == hi) { lo <- lo / b; hi <- hi * b }
    return(c(lo, hi))
  }
  if (diff(r) == 0) r <- r + c(-1, 1) * max(abs(r[1]) * 0.1, 1)
  p <- pretty(r, n = 5)
  lim <- range(p)
  if (escala %in% c("raiz") && lim[1] < 0) lim[1] <- 0
  lim
}

.fmt_num <- function(v, casas = NULL, milhar = FALSE) {
  if (!length(v)) return(character(0))
  if (!is.null(casas)) {
    s <- formatC(v, format = "f", digits = casas, big.mark = if (milhar) "," else "",
                 decimal.mark = ".")
  } else {
    fin <- v[is.finite(v)]
    dig <- 0
    if (length(fin)) {
      for (d in 0:10) if (all(abs(round(fin, d) - fin) < 1e-9 * pmax(1, abs(fin)))) { dig <- d; break } else dig <- d
    }
    s <- formatC(v, format = "f", digits = dig, big.mark = if (milhar) "," else "",
                 decimal.mark = ".")
  }
  s[s %in% c("-0", sub("^", "-", formatC(0, format = "f", digits = casas %||% 0)))] <-
    formatC(0, format = "f", digits = casas %||% 0)
  s
}

.formatador <- function(e) {
  casas <- e$casas_decimais
  fator <- e$fator_divisao %||% 1
  pre <- e$prefixo %||% ""; suf <- e$sufixo %||% ""
  notacao <- e$notacao %||% "normal"
  function(x) {
    if (!length(x)) return(character(0))
    na <- is.na(x)
    v <- x / fator
    out <- switch(notacao,
      normal = .fmt_num(v, casas),
      milhar = .fmt_num(v, casas, milhar = TRUE),
      percentual = paste0(.fmt_num(v * 100, casas), "%"),
      cientifica_E = {
        s <- formatC(v, format = "E", digits = casas %||% 1)
        s <- sub("E\\+?(-?)0*([0-9])", "E\\1\\2", s)
        s[v == 0] <- "0"
        if (is.null(casas)) s <- sub("\\.?0+E", "E", s)
        s
      },
      cientifica = , potencia10 = {
        ex <- ifelse(v == 0, 0, floor(log10(abs(v)) + 1e-9))
        m <- v / 10^ex
        expr <- vapply(seq_along(v), function(i) {
          if (is.na(v[i])) return('""')
          if (v[i] == 0) return('"0"')
          mi <- if (is.null(casas)) .fmt_num(round(m[i], 3)) else .fmt_num(m[i], casas)
          if (notacao == "potencia10" && abs(m[i] - round(m[i])) < 1e-9 && round(m[i]) %in% c(1, -1))
            return(paste0(if (m[i] < 0) "-" else "", "10^", ex[i]))
          paste0('"', mi, '"%*%10^', ex[i])
        }, "")
        if (nzchar(pre) || nzchar(suf))
          expr <- paste0(deparse(pre), "*", expr, "*", deparse(suf))
        out <- parse(text = expr)
        return(out)
      }
    )
    out <- paste0(pre, out, suf)
    out[na] <- ""
    out
  }
}

#' Calcula escala de um eixo. faixa = valores dos dados; categorias = rótulos
.calc_eixo <- function(e, faixa, categorias = NULL, forcar = NULL) {
  escala <- if (!is.null(categorias)) "linear" else e$escala %||% "linear"
  b <- .base_log(escala)
  if ((!is.na(b) || escala == "reciproco") && is.null(forcar)) {
    ruins <- sum(is.finite(faixa) & faixa <= 0)
    if (ruins && !is.na(b)) .aviso("Escala ", escala, ": ", ruins, " valor(es) <= 0 não podem ser desenhados e serão omitidos.")
    if (escala == "reciproco" && any(faixa == 0, na.rm = TRUE)) .aviso("Escala recíproca: valores iguais a 0 (1/0 = infinito) serão omitidos.")
  }
  auto <- if (!is.null(categorias)) c(0.5, length(categorias) + 0.5) else .limites_auto(faixa, escala)
  if (!is.null(forcar)) auto <- forcar
  lo <- e$inicio %||% auto[1]; hi <- e$fim %||% auto[2]
  if (lo >= hi) {
    if (is.null(e$inicio)) lo <- hi - abs(hi) * 0.1 - 1 else hi <- lo + abs(lo) * 0.1 + 1
  }
  if (!is.na(b) && lo <= 0)
    .erro("Escala logarítmica: o início do eixo deve ser > 0 (atual: ", lo, ").")
  if (escala == "reciproco" && lo <= 0 && hi >= 0)
    .erro("Escala recíproca não pode incluir o zero (", lo, " a ", hi, ").")
  if (escala == "raiz" && lo < 0) .erro("Escala raiz: o início do eixo deve ser >= 0.")
  lim <- c(lo, hi)
  tol <- 1e-9 * max(abs(lim))

  modo <- e$ticks_modo %||% "auto"
  if (!is.null(categorias) && modo == "auto") {
    maiores <- seq_along(categorias)
  } else if (modo == "auto") {
    maiores <- if (!is.na(b)) {
      ex <- seq(ceiling(log(lo, b) - 1e-9), floor(log(hi, b) + 1e-9))
      if (length(ex) > 8) ex <- ex[ex %% ceiling(length(ex) / 6) == 0]
      if (length(ex) < 2) scales::breaks_log(5, base = b)(lim) else b^ex
    } else if (escala == "reciproco") {
      dec <- 10^(floor(log10(min(abs(lim)))):ceiling(log10(max(abs(lim)))))
      cand <- sort(unique(c(lo, hi, sign(hi) * as.vector(outer(c(1, 1.5, 2, 2.5, 3, 4, 5, 6, 8), dec)))))
      cand <- cand[cand >= lo & cand <= hi & cand != 0]
      alvo <- 1 / seq(1 / hi, 1 / lo, length.out = 6)
      unique(vapply(alvo, function(a) cand[which.min(abs(1 / cand - 1 / a))], 0))
    } else pretty(lim, n = 5)
  } else if (modo == "incremento") {
    if (!is.na(b)) {
      ex0 <- if (!is.null(e$primeiro_tick)) log(e$primeiro_tick, b) else ceiling(log(lo, b) - 1e-9)
      maiores <- b^seq(ex0, log(hi, b) + 1e-9, by = e$incremento)
    } else {
      ini <- e$primeiro_tick %||% lo
      n <- floor((hi - ini) / e$incremento + 1e-9)
      if (n > 1000) .erro("incremento muito pequeno: geraria ", n, " ticks.")
      maiores <- round(ini + (0:max(n, 0)) * e$incremento, 12)
    }
  } else if (modo == "quantidade") {
    maiores <- if (!is.na(b)) exp(seq(log(lo), log(hi), length.out = e$quantidade))
               else seq(lo, hi, length.out = e$quantidade)
  } else if (modo == "min_max") {
    maiores <- lim
  } else {
    maiores <- e$ticks_manuais
  }
  .ajustar <- function(v) {
    v <- signif(v, 12)
    v[abs(v - lo) <= tol] <- lo; v[abs(v - hi) <= tol] <- hi
    v
  }
  maiores <- .ajustar(maiores)
  if (modo != "manual") maiores <- maiores[maiores >= lo - tol & maiores <= hi + tol]

  # ticks menores
  nm <- if (!is.null(categorias)) 0 else e$n_menores %||% 0
  menores <- NULL
  mm <- sort(unique(maiores))
  if (nm > 0 && length(mm) >= 2) {
    entre <- function(a, z) a + (seq_len(nm)) * (z - a) / (nm + 1)
    menores <- unlist(lapply(seq_len(length(mm) - 1), function(i) entre(mm[i], mm[i + 1])))
    if (!is.na(b) || escala == "reciproco") {
      r1 <- mm[2] / mm[1]; r2 <- mm[length(mm)] / mm[length(mm) - 1]
      ext <- c(entre(mm[1] / r1, mm[1]), entre(mm[length(mm)], mm[length(mm)] * r2))
    } else {
      d1 <- mm[2] - mm[1]; d2 <- mm[length(mm)] - mm[length(mm) - 1]
      ext <- c(unlist(lapply(1:20, function(k) entre(mm[1] - k * d1, mm[1] - (k - 1) * d1))),
               unlist(lapply(1:20, function(k) entre(mm[length(mm)] + (k - 1) * d2, mm[length(mm)] + k * d2))))
    }
    menores <- .ajustar(c(menores, ext))
    menores <- menores[menores >= lo - tol & menores <= hi + tol]
  }

  rotulos <- if (!is.null(e$rotulos_manuais)) as.character(e$rotulos_manuais)
             else if (!is.null(categorias) && modo == "auto") categorias
             else .formatador(e)
  # painéis colados: esconde o número que encosta no painel vizinho
  ocultar <- e$.ocultar_extremo
  if (!is.null(ocultar) && is.function(rotulos)) {
    f0 <- rotulos; alvo <- if (identical(ocultar, "max")) hi else lo
    rotulos <- function(x) {
      r <- f0(x); sel <- !is.na(x) & abs(x - alvo) <= tol
      if (is.expression(r)) { r <- as.list(r); r[sel] <- list(""); return(as.expression(r)) }
      r[sel] <- ""; r
    }
  }
  list(limites = lim, maiores = maiores, menores = menores %||% numeric(0),
       rotulos = rotulos, trans = .transformacao(escala, e$inverter),
       mult = (e$margem_percentual %||% 0) / 100, cfg = e, escala = escala,
       categorias = categorias)
}

# posição (0-1 no painel) de valores num eixo calculado
.npc <- function(v, ax) {
  tl <- sort(ax$trans$transform(ax$limites))
  r <- tl + c(-1, 1) * diff(tl) * ax$mult
  (ax$trans$transform(v) - r[1]) / diff(r)
}

# =============================================================================
#  TEMA (aparência: caixa, ticks, rótulos, grade, legenda)
# =============================================================================
.comp_tick <- function(direcao, comp) {
  switch(direcao %||% "dentro", dentro = -comp, fora = comp, ambos = comp, nenhum = 0)
}

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
               face = if (isTRUE(e$negrito_rotulos)) "bold" else "plain",
               angle = ang, hjust = just$h, vjust = just$v, margin = m)
}

.elem_titulo <- function(e, cfg, lado, cor_forcada = NULL) {
  if (!isTRUE(e$mostrar_titulo %||% TRUE)) return(element_blank())
  d <- e$distancia_titulo_pt %||% 4
  m <- switch(lado, bottom = margin(t = d), top = margin(b = d),
              left = margin(r = d), right = margin(l = d))
  face <- if (isTRUE(e$negrito_titulo) && isTRUE(e$italico_titulo)) "bold.italic"
          else if (isTRUE(e$negrito_titulo)) "bold" else if (isTRUE(e$italico_titulo)) "italic" else "plain"
  element_text(size = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt,
               colour = cor_forcada %||% e$cor_titulo %||% cfg$texto$cor, face = face,
               angle = switch(lado, left = 90, right = -90, 0), margin = m)
}

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
  gl <- function(on, cor, esp, tipo) if (isTRUE(on)) element_line(colour = cor, linewidth = .lw(esp), linetype = tipo) else element_blank()
  t <- t + theme(
    panel.grid.major.x = gl(lados$grade_x_maior, gr$cor_maior, gr$espessura_maior_pt, gr$tipo_maior),
    panel.grid.major.y = gl(lados$grade_y_maior, gr$cor_maior, gr$espessura_maior_pt, gr$tipo_maior),
    panel.grid.minor.x = gl(lados$grade_x_menor, gr$cor_menor, gr$espessura_menor_pt, gr$tipo_menor),
    panel.grid.minor.y = gl(lados$grade_y_menor, gr$cor_menor, gr$espessura_menor_pt, gr$tipo_menor))
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
      t <- t + theme(panel.border = element_blank(),
        axis.line.x.bottom = if (isTRUE(eh$mostrar_linha)) element_line(colour = eh$cor_linha, linewidth = .lw(eh$espessura_linha_pt), lineend = "square") else element_blank(),
        axis.line.y.left  = if (isTRUE(ev$mostrar_linha)) element_line(colour = ev$cor_linha, linewidth = .lw(ev$espessura_linha_pt), lineend = "square") else element_blank(),
        axis.line.y.right = if (isTRUE(ev$mostrar_linha) && "right" %in% lados$ver) element_line(colour = cor_y2 %||% ev$cor_linha, linewidth = .lw(ev$espessura_linha_pt)) else element_blank(),
        axis.line.x.top = if (isTRUE(eh$mostrar_linha) && "top" %in% lados$hor) element_line(colour = eh$cor_linha, linewidth = .lw(eh$espessura_linha_pt)) else element_blank())
    }
    # ticks
    tk <- function(e, cor = NULL) element_line(colour = cor %||% e$cor_ticks, linewidth = .lw(e$espessura_ticks_pt))
    for (lado in c("bottom", "top", "left", "right")) {
      e <- if (lado %in% c("bottom", "top")) eh else ev
      xy <- if (lado %in% c("bottom", "top")) "x" else "y"
      cor_l <- if (lado == lados$lado_y2) cor_y2 else NULL
      el <- list()
      el[[paste0("axis.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.ticks.length.", xy, ".", lado)]] <- unit(.comp_tick(e$direcao_maiores, e$comprimento_maiores_pt), "pt")
      el[[paste0("axis.minor.ticks.", xy, ".", lado)]] <- tk(e, cor_l)
      el[[paste0("axis.minor.ticks.length.", xy, ".", lado)]] <- unit(.comp_tick(e$direcao_menores, e$comprimento_menores_pt), "pt")
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
                                      face = if (isTRUE(ti$negrito_titulo)) "bold" else "plain"),
            plot.subtitle = element_text(hjust = hj, size = ti$tamanho_subtitulo_pt %||% tx$tamanho_base_pt),
            plot.title.position = "panel")
}

.tema_legenda <- function(cfg, fonte) {
  lg <- cfg$legenda; tx <- cfg$texto
  pos <- switch(lg$posicao, dentro = "inside", direita = "right", esquerda = "left",
                topo = "top", base = "bottom")
  fundo <- if (identical(lg$fundo, "transparente")) NA else .cor(lg$fundo)
  t <- theme(
    legend.position = pos,
    legend.background = element_rect(fill = fundo, colour = if (isTRUE(lg$moldura)) .cor(lg$cor_moldura) else NA,
                                     linewidth = .lw(lg$espessura_moldura_pt)),
    legend.key = element_rect(fill = NA, colour = NA),
    legend.key.size = unit(lg$tamanho_chave_pt, "pt"),
    legend.key.spacing.y = unit(lg$espacamento_pt, "pt"),
    legend.text = element_text(size = lg$tamanho_texto_pt %||% tx$tamanho_base_pt),
    legend.title = if (is.null(lg$titulo)) element_blank() else
      element_text(size = lg$tamanho_titulo_pt %||% tx$tamanho_base_pt),
    legend.margin = margin(4, 6, 4, 6))
  if (pos == "inside") {
    anc <- if (identical(lg$ancora, "auto")) c(lg$dentro_x, lg$dentro_y) else lg$ancora
    t <- t + theme(legend.position.inside = c(lg$dentro_x, lg$dentro_y),
                   legend.justification.inside = anc)
  }
  if (pos %in% c("top", "bottom")) t <- t + theme(legend.direction = "horizontal")
  t
}

.fontes_cache <- new.env()
.fonte <- function(f) {
  if (is.null(f) || f %in% c("sans", "serif", "mono", "")) return(f %||% "sans")
  if (!is.null(.fontes_cache[[f]])) return(.fontes_cache[[f]])
  ok <- TRUE
  if (.tem("systemfonts")) {
    fams <- unique(systemfonts::system_fonts()$family)
    ok <- tolower(f) %in% tolower(fams)
  }
  res <- if (ok) f else {
    .aviso("Fonte '", f, "' não encontrada no sistema; usando 'sans'. Veja listar_fontes().")
    "sans"
  }
  .fontes_cache[[f]] <- res
  res
}

# Ticks "ambos" (cruzando o eixo): parte interna desenhada como anotação
.ticks_internos <- function(axh, axv, lados) {
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
      gp <- gpar(col = e$cor_ticks, lwd = .lw(e$espessura_ticks_pt) * ggplot2::.pt, lineend = "butt")
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
  annotation_custom(do.call(gTree, list(children = do.call(gList, segs))),
                    xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
}

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

.colunas_y <- function(dados, cfg, excluir = NULL, so_numericas = TRUE) {
  g <- cfg$grafico
  ys <- if (is.null(g$colunas_y)) {
    setdiff(names(dados)[vapply(dados, is.numeric, logical(1))], excluir)
  } else vapply(g$colunas_y, function(r) .coluna(dados, r, "cfg$grafico$colunas_y"), "")
  # tira colunas usadas como erro
  usadas_erro <- unlist(lapply(cfg$series, function(s) c(s$coluna_erro, s$coluna_erro_inferior,
                                                         s$coluna_erro_superior, s$coluna_erro_x)))
  if (is.null(g$colunas_y)) ys <- setdiff(ys, usadas_erro)
  if (!is.null(cfg$cores$mapear_coluna) && is.null(g$colunas_y)) ys <- setdiff(ys, cfg$cores$mapear_coluna)
  if (!length(ys)) .erro("Nenhuma coluna Y numérica encontrada. Defina cfg$grafico$colunas_y.")
  if (so_numericas) for (y in ys) if (!is.numeric(dados[[y]]))
    .erro("A coluna '", y, "' não é numérica (veja o relatório de leitura). ",
          "Se o arquivo usa vírgula decimal, defina cfg$dados$decimal_virgula <- TRUE.")
  if (!is.null(g$ordem_itens)) ys <- c(intersect(g$ordem_itens, ys), setdiff(ys, g$ordem_itens))
  ys
}

# ---- Pontos / linhas / áreas --------------------------------------------------
.construir_xy <- function(dados, cfg) {
  tipo <- cfg$grafico$tipo; L <- cfg$linhas
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  cats <- NULL
  if (!is.numeric(dados[[xcol]])) {
    cats <- unique(as.character(dados[[xcol]][!is.na(dados[[xcol]])]))
    dados[[xcol]] <- match(as.character(dados[[xcol]]), cats)
  }
  est <- .estilos(cfg, ycols)
  mc <- if (!is.null(cfg$cores$mapear_coluna)) .coluna(dados, cfg$cores$mapear_coluna, "cfg$cores$mapear_coluna") else NULL
  if (!is.null(mc) && !is.numeric(dados[[mc]])) .erro("cfg$cores$mapear_coluna: a coluna '", mc, "' precisa ser numérica.")
  d <- .serie_longa(dados, xcol, ycols, est, mc)
  invalido <- function(v, esc) if (!is.na(.base_log(esc %||% "linear"))) !is.na(v) & v <= 0
                               else if (identical(esc, "reciproco")) !is.na(v) & v == 0 else rep(FALSE, length(v))
  if (is.null(cats)) d$x[invalido(d$x, cfg$eixo_x$escala)] <- NA
  d$y[invalido(d$y, cfg$eixo_y$escala)] <- NA
  d <- d[!is.na(d$x), ]
  d$serie <- factor(d$serie, levels = ycols)

  usa_y2 <- isTRUE(cfg$eixo_y2$ativo) && identical(cfg$eixo_y2$modo, "independente")
  ser_y2 <- if (usa_y2) ycols[vapply(est, function(e) identical(e$eixo, "y2"), logical(1))] else character(0)
  if (usa_y2 && !length(ser_y2))
    .erro("eixo_y2 ativo no modo \"independente\", mas nenhuma série tem eixo = \"y2\".\n",
          "  Ex.: cfg$series[[\"", ycols[length(ycols)], "\"]] <- list(eixo = \"y2\")")

  com_pontos <- tipo %in% c("pontos", "linha_pontos")
  com_linha <- tipo %in% c("linha", "linha_pontos", "area", "area_empilhada")
  preench <- L$preencher_area
  if (tipo == "area" && preench == "nenhum") preench <- "ate_zero"

  # empilhamento
  if (tipo == "area_empilhada") {
    if (usa_y2) .erro("area_empilhada não combina com eixo_y2.")
    larga <- stats::reshape(d[, c("x", "y", "serie")], idvar = "x", timevar = "serie", direction = "wide")
    larga <- larga[order(larga$x), ]
    acum <- 0
    pilha <- list()
    for (s in ycols) {
      v <- larga[[paste0("y.", s)]]; v[is.na(v)] <- 0
      pilha[[s]] <- data.frame(x = larga$x, ymin = acum, y = acum + v, serie = s)
      acum <- acum + v
    }
    d <- do.call(rbind, pilha); d$serie <- factor(d$serie, levels = ycols)
    d$e_inf <- d$e_sup <- d$e_x <- NA_real_
  }

  # faixa de dados para Y1 e Y2
  d1 <- d[!d$serie %in% ser_y2, ]
  faixa_y <- c(d1$y, d1$y - d1$e_inf, d1$y + d1$e_sup, if (tipo == "area_empilhada") 0,
               if (preench == "ate_zero") 0)
  faixa_x <- c(d$x, d$x - d$e_x, d$x + d$e_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  ax_x <- .calc_eixo(cfg$eixo_x, faixa_x, categorias = cats, forcar = cfg$.interno$forcar_x)

  y2 <- NULL
  if (usa_y2) {
    if (ax_y$escala != "linear") .erro("eixo_y2 \"independente\" exige eixo_y linear.")
    d2 <- d[d$serie %in% ser_y2, ]
    e2 <- utils::modifyList(cfg$eixo_y, cfg$eixo_y2[intersect(names(cfg$eixo_y2), names(cfg$eixo_y))])
    e2$escala <- "linear"; e2$inverter <- FALSE
    ax2 <- .calc_eixo(e2, c(d2$y, d2$y - d2$e_inf, d2$y + d2$e_sup))
    l1 <- ax_y$limites; l2 <- ax2$limites
    para1 <- function(v) l1[1] + (v - l2[1]) * diff(l1) / diff(l2)
    para2 <- function(v) l2[1] + (v - l1[1]) * diff(l2) / diff(l1)
    sel <- d$serie %in% ser_y2
    d$y[sel] <- para1(d$y[sel])
    d$e_inf[sel] <- d$e_inf[sel] * diff(l1) / diff(l2)
    d$e_sup[sel] <- d$e_sup[sel] * diff(l1) / diff(l2)
    y2 <- list(ax = ax2, para2 = para2, para1 = para1,
               titulo = cfg$eixo_y2$titulo %||% paste(ser_y2, collapse = ", "),
               cor = if (identical(cfg$eixo_y2$cor_eixo, "serie")) est[[ser_y2[1]]]$cor else cfg$eixo_y2$cor_eixo)
  }

  cam <- list()
  mapa <- !is.null(cfg$cores$mapear_coluna) && com_pontos
  # áreas
  if (preench != "nenhum" || tipo == "area_empilhada") {
    base_y <- if (preench == "ate_base") { if (isTRUE(cfg$eixo_y$inverter)) ax_y$limites[2] else ax_y$limites[1] } else 0
    for (i in seq_along(ycols)) {
      s <- ycols[i]; ds <- d[d$serie == s, ]; ds <- ds[order(ds$x), ]
      if (!nrow(ds)) next
      if (tipo == "area_empilhada") {
        rib <- data.frame(x = ds$x, ymin = ds$ymin, ymax = ds$y)
      } else if (preench == "proxima_serie") {
        if (i == length(ycols)) next
        prox <- d[d$serie == ycols[i + 1], ]
        yb <- stats::approx(prox$x, prox$y, xout = ds$x, rule = 2)$y
        rib <- data.frame(x = ds$x, ymin = pmin(ds$y, yb), ymax = pmax(ds$y, yb))
      } else rib <- data.frame(x = ds$x, ymin = base_y, ymax = ds$y)
      e <- est[[s]]
      a_area <- if (tipo == "area_empilhada") e$opf else L$opacidade_area
      fill <- if (identical(cfg$cores$preenchimento, "gradiente"))
        .gradiente(.alfa(e$cor, a_area), .alfa(e$cor2, a_area), cfg$cores$gradiente_direcao, FALSE)
        else .alfa(e$cor, a_area)
      cam[[length(cam) + 1]] <- geom_ribbon(data = rib, aes(x = x, ymin = ymin, ymax = ymax),
                                            fill = fill, colour = NA, inherit.aes = FALSE)
    }
  }
  # linhas de queda
  if (L$linhas_queda != "nenhuma") {
    bx <- if (isTRUE(cfg$eixo_x$inverter)) ax_x$limites[2] else ax_x$limites[1]
    by <- if (isTRUE(cfg$eixo_y$inverter)) ax_y$limites[2] else ax_y$limites[1]
    if (L$linhas_queda %in% c("vertical", "ambas"))
      cam[[length(cam) + 1]] <- geom_segment(data = d, aes(x = x, xend = x, y = y, yend = by, colour = serie),
        linetype = L$linhas_queda_tipo, linewidth = .lw(L$linhas_queda_espessura_pt), show.legend = FALSE)
    if (L$linhas_queda %in% c("horizontal", "ambas"))
      cam[[length(cam) + 1]] <- geom_segment(data = d, aes(x = x, xend = bx, y = y, yend = y, colour = serie),
        linetype = L$linhas_queda_tipo, linewidth = .lw(L$linhas_queda_espessura_pt), show.legend = FALSE)
  }
  # barras de erro
  de <- d[!is.na(d$e_inf) | !is.na(d$e_sup), ]
  if (nrow(de)) {
    larg <- if (ax_x$escala == "linear") L$erro_chapeu_percentual / 100 * diff(ax_x$limites) else 0
    de$ymin <- if (L$erro_lado == "superior") de$y else de$y - de$e_inf
    de$ymax <- if (L$erro_lado == "inferior") de$y else de$y + de$e_sup
    cam[[length(cam) + 1]] <- geom_errorbar(data = de, aes(x = x, ymin = ymin, ymax = ymax, colour = serie),
      width = larg, linewidth = .lw(L$erro_espessura_pt), show.legend = FALSE, inherit.aes = FALSE)
  }
  dx <- d[!is.na(d$e_x), ]
  if (nrow(dx)) {
    alt <- if (ax_y$escala == "linear") L$erro_chapeu_percentual / 100 * diff(ax_y$limites) else 0
    cam[[length(cam) + 1]] <- geom_errorbar(data = dx, aes(y = y, xmin = x - e_x, xmax = x + e_x, colour = serie),
      width = alt, orientation = "y", linewidth = .lw(L$erro_espessura_pt), show.legend = FALSE, inherit.aes = FALSE)
  }
  aes_leg <- character(0)
  # linhas
  if (com_linha) {
    if (mapa) {
      for (s in ycols) cam[[length(cam) + 1]] <- .camada_linha(d[d$serie == s, ], L$ligacao, mapeado = FALSE, e = est[[s]])
    } else {
      cam[[length(cam) + 1]] <- .camada_linha(d, L$ligacao, mapeado = TRUE)
      aes_leg <- c(aes_leg, "colour", "linetype", "linewidth", "alpha")
    }
  }
  # pontos
  if (com_pontos) {
    if (mapa) {
      cam[[length(cam) + 1]] <- geom_point(data = d, aes(x = x, y = y, colour = mapa, fill = mapa,
                                                         shape = serie, size = serie, stroke = serie))
      aes_leg <- unique(c(aes_leg, "shape", "size", "stroke"))
    } else {
      cam[[length(cam) + 1]] <- geom_point(data = d, aes(x = x, y = y, colour = serie, fill = serie,
                                                         shape = serie, size = serie, stroke = serie, alpha = serie))
      aes_leg <- unique(c(aes_leg, "colour", "fill_simb", "shape", "size", "stroke", "alpha"))
    }
  }
  # rótulos de dados
  if (L$rotulos_dados != "nenhum") {
    dd <- d
    if (usa_y2) { sel <- dd$serie %in% ser_y2; dd$yv <- dd$y; dd$yv[sel] <- y2$para2(dd$y[sel]) } else dd$yv <- dd$y
    xv <- if (!is.null(cats)) cats[dd$x] else .fmt_num(dd$x, L$rotulos_casas)
    dd$rot <- switch(L$rotulos_dados,
                     y = .fmt_num(dd$yv, L$rotulos_casas), x = xv,
                     xy = paste0("(", xv, ", ", .fmt_num(dd$yv, L$rotulos_casas), ")"),
                     serie = as.character(dd$serie))
    k <- L$rotulos_deslocamento_pt / L$rotulos_tamanho_pt
    cam[[length(cam) + 1]] <- geom_text(data = dd, aes(x = x, y = y, label = rot, colour = serie),
      size = .tx(L$rotulos_tamanho_pt), vjust = if (k >= 0) -k else 1 - k, show.legend = FALSE,
      family = .fonte(cfg$texto$fonte))
  }
  if (!"colour" %in% aes_leg && !mapa && (com_linha || nrow(de) || L$linhas_queda != "nenhuma" || L$rotulos_dados != "nenhum"))
    aes_leg <- c(aes_leg, "colour")
  escalas <- .escalas_legenda(est, aes_leg, cfg)
  if (mapa) escalas <- c(escalas, .escala_mapa(cfg, dados))
  if (!com_pontos && !com_linha) escalas <- c(escalas, list(guides(fill = "none")))

  titulo_y <- cfg$eixo_y$titulo %||% (if (length(setdiff(ycols, ser_y2)) == 1) setdiff(ycols, ser_y2) else "Y")
  list(camadas = c(cam, escalas),
       info = list(ax_x = ax_x, ax_y = ax_y, y2 = y2, flip = FALSE,
                   titulo_x = cfg$eixo_x$titulo %||% xcol, titulo_y = titulo_y,
                   legenda_auto = TRUE, faixa_x = faixa_x, faixa_y = faixa_y))
}

.camada_linha <- function(d, ligacao, mapeado, e = NULL) {
  d <- d[!is.na(d$y), ]
  if (ligacao == "spline") {
    niveis <- levels(d$serie)
    partes <- lapply(split(d, d$serie, drop = TRUE), function(s) {
      nm <- as.character(s$serie[1])
      s <- stats::aggregate(y ~ x, data = s, FUN = mean)
      if (nrow(s) < 3) return(data.frame(x = s$x, y = s$y, serie = nm))
      sp <- stats::spline(s$x, s$y, n = max(200, 10 * nrow(s)), method = "fmm")
      data.frame(x = sp$x, y = sp$y, serie = nm)
    })
    d <- do.call(rbind, partes)
    d$serie <- factor(d$serie, levels = niveis)
  }
  geo <- switch(ligacao, reta = geom_path, spline = geom_path,
                degrau_hv = function(...) geom_step(..., direction = "hv"),
                degrau_vh = function(...) geom_step(..., direction = "vh"),
                degrau_meio = function(...) geom_step(..., direction = "mid"))
  if (mapeado) {
    geo(data = d, aes(x = x, y = y, colour = serie, linetype = serie, linewidth = serie,
                      alpha = serie, group = serie), lineend = "round", linejoin = "round")
  } else {
    geo(data = d, aes(x = x, y = y), colour = .alfa(e$cor, e$op), linetype = e$lt,
        linewidth = .lw(e$lw), lineend = "round", linejoin = "round")
  }
}

.escala_mapa <- function(cfg, dados) {
  c0 <- cfg$cores
  tit <- c0$mapa_titulo %||% c0$mapear_coluna
  guia <- guide_colourbar(title = if (identical(tit, "")) NULL else .texto(tit))
  cores <- vapply(c0$mapa_cores, .cor, "", onde = "cores$mapa_cores")
  if (length(cores) >= 3) {
    mc <- dados[[c0$mapear_coluna]]
    meio <- c0$mapa_ponto_medio %||% mean(range(mc, na.rm = TRUE))
    sc <- scale_colour_gradient2(low = cores[1], mid = cores[2], high = cores[3], midpoint = meio,
                                 limits = c0$mapa_limites, aesthetics = c("colour", "fill"),
                                 guide = guia, labels = .formatador(list()))
  } else {
    sc <- scale_colour_gradient(low = cores[1], high = cores[2], limits = c0$mapa_limites,
                                aesthetics = c("colour", "fill"), guide = guia,
                                labels = .formatador(list()))
  }
  list(sc)
}

# ---- Barras ---------------------------------------------------------------------
.construir_barras <- function(dados, cfg) {
  B <- cfg$barras
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  flip <- B$orientacao == "horizontal"
  est <- .estilos(cfg, ycols, inverter_grad = flip)
  numerico <- is.numeric(dados[[xcol]])
  dados <- dados[!is.na(dados[[xcol]]), , drop = FALSE]
  if (numerico) {
    xs <- dados[[xcol]]; cats <- NULL
    passo <- if (length(unique(xs)) > 1) min(diff(sort(unique(xs)))) else 1
  } else {
    cats <- unique(as.character(dados[[xcol]]))
    if (!is.null(cfg$grafico$ordem_itens) && all(cfg$grafico$ordem_itens %in% cats) && !any(cfg$grafico$ordem_itens %in% ycols))
      cats <- c(cfg$grafico$ordem_itens, setdiff(cats, cfg$grafico$ordem_itens))
    xs <- match(as.character(dados[[xcol]]), cats); passo <- 1
  }
  n <- length(ycols); W <- B$largura * passo
  base <- B$linha_base %||% 0
  erro_de <- function(yc) {
    e <- est[[yc]]
    col <- function(ref) if (is.null(ref)) rep(0, nrow(dados)) else {
      v <- dados[[.coluna(dados, ref, paste0("cfg$series[[\"", yc, "\"]] coluna de erro"))]]; v[is.na(v)] <- 0; v }
    tem <- !is.null(e$erro) || !is.null(e$erro_inf) || !is.null(e$erro_sup)
    list(tem = tem, inf = col(e$erro_inf %||% e$erro), sup = col(e$erro_sup %||% e$erro))
  }
  ret <- list()
  if (B$arranjo == "agrupado") {
    sob <- B$sobreposicao %||% 0
    w <- W / (1 + (n - 1) * (1 - sob))
    for (i in seq_len(n)) {
      v <- dados[[ycols[i]]]
      x0 <- xs - W / 2 + (i - 1) * w * (1 - sob)
      er <- erro_de(ycols[i])
      ret[[i]] <- data.frame(xmin = x0, xmax = x0 + w, ymin = base, ymax = v, serie = ycols[i],
                             xc = x0 + w / 2, topo = v, valor = v, tem_erro = er$tem,
                             e_inf = er$inf, e_sup = er$sup, row.names = NULL)
    }
  } else {
    m <- sapply(ycols, function(y) { v <- dados[[y]]; v[is.na(v)] <- 0; v })
    if (is.null(dim(m))) m <- matrix(m, nrow = 1, dimnames = list(NULL, ycols))
    if (B$arranjo == "empilhado_100") {
      tot <- rowSums(abs(m)); tot[tot == 0] <- 1
      m <- m / tot * 100
      base <- 0
    }
    pos <- rep(base, nrow(m)); neg <- rep(base, nrow(m))
    for (i in seq_len(n)) {
      v <- m[, i]
      y0 <- ifelse(v >= 0, pos, neg); y1 <- y0 + v
      pos <- ifelse(v >= 0, y1, pos); neg <- ifelse(v < 0, y1, neg)
      er <- erro_de(ycols[i])
      ret[[i]] <- data.frame(xmin = xs - W / 2, xmax = xs + W / 2, ymin = y0, ymax = y1,
                             serie = ycols[i], xc = xs, topo = y1, valor = v, tem_erro = er$tem,
                             e_inf = er$inf, e_sup = er$sup, row.names = NULL)
    }
  }
  r <- do.call(rbind, ret); r <- r[!is.na(r$ymax), ]
  r$serie <- factor(r$serie, levels = ycols)

  contorno_serie <- identical(B$contorno_cor, "serie")
  cam <- list(if (contorno_serie)
    geom_rect(data = r, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = serie, colour = serie),
              linewidth = .lw(B$contorno_espessura_pt), linetype = B$contorno_tipo)
  else
    geom_rect(data = r, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = serie),
              colour = if (is.na(B$contorno_cor)) NA else .cor(B$contorno_cor),
              linewidth = .lw(B$contorno_espessura_pt), linetype = B$contorno_tipo))
  # erros (linha a linha, já alinhados com cada barra)
  faixa_err <- numeric(0)
  erros <- r[r$tem_erro & B$arranjo != "empilhado_100", ]
  if (nrow(erros)) {
    erros$ymin <- erros$topo - erros$e_inf; erros$ymax <- erros$topo + erros$e_sup
    cam[[length(cam) + 1]] <- geom_errorbar(data = erros, aes(x = xc, ymin = ymin, ymax = ymax),
      width = (erros$xmax[1] - erros$xmin[1]) * B$erro_chapeu, linewidth = .lw(B$erro_espessura_pt),
      colour = cfg$texto$cor, inherit.aes = FALSE)
    faixa_err <- c(erros$ymin, erros$ymax)
  }
  # rótulos
  if (isTRUE(B$rotulos_valor)) {
    rr <- r
    rr$rot <- if (B$arranjo == "empilhado_100") paste0(.fmt_num(rr$valor, B$rotulos_casas), "%") else .fmt_num(rr$valor, B$rotulos_casas)
    pos <- B$rotulos_posicao
    rr$yl <- if (pos == "centro") (rr$ymin + rr$ymax) / 2 else rr$ymax
    neg <- rr$ymax < rr$ymin
    j <- switch(pos, fora = ifelse(neg, 1.3, -0.3), dentro = ifelse(neg, -0.3, 1.3), centro = 0.5)
    cam[[length(cam) + 1]] <- if (flip)
      geom_text(data = rr, aes(x = xc, y = yl, label = rot), hjust = j, size = .tx(B$rotulos_tamanho_pt),
                colour = .cor(B$rotulos_cor), family = .fonte(cfg$texto$fonte))
    else geom_text(data = rr, aes(x = xc, y = yl, label = rot), vjust = j, size = .tx(B$rotulos_tamanho_pt),
                   colour = .cor(B$rotulos_cor), family = .fonte(cfg$texto$fonte))
  }
  aes_leg <- c("fill", if (contorno_serie) "colour")
  faixa_y <- c(r$ymin, r$ymax, base, faixa_err)
  if (isTRUE(B$rotulos_valor) && B$rotulos_posicao == "fora") faixa_y <- c(faixa_y, max(faixa_y) + 0.08 * diff(range(faixa_y)))
  ax_x <- .calc_eixo(cfg$eixo_x, c(r$xmin, r$xmax), categorias = cats, forcar = cfg$.interno$forcar_x)
  if (numerico && is.null(cfg$eixo_x$inicio) && is.null(cfg$.interno$forcar_x)) {
    ax_x <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(inicio = min(r$xmin) - (1 - B$largura) * passo / 2,
                                                         fim = max(r$xmax) + (1 - B$largura) * passo / 2)), c(r$xmin, r$xmax))
  }
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  tit_y <- cfg$eixo_y$titulo %||% (if (B$arranjo == "empilhado_100") "Percentual (%)" else if (n == 1) ycols else "Valor")
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = flip, titulo_x = cfg$eixo_x$titulo %||% xcol,
                   titulo_y = tit_y, legenda_auto = TRUE, faixa_x = c(r$xmin, r$xmax), faixa_y = faixa_y))
}

# ---- Pizza ----------------------------------------------------------------------
.construir_pizza <- function(dados, cfg) {
  P <- cfg$pizza
  xcol <- .coluna(dados, cfg$grafico$coluna_x, "cfg$grafico$coluna_x")
  ycol <- .colunas_y(dados, cfg, excluir = xcol)[1]
  cat_ <- as.character(dados[[xcol]]); val <- dados[[ycol]]
  ok <- !is.na(cat_) & !is.na(val)
  if (any(val[ok] < 0)) .aviso("Pizza: valores negativos em '", ycol, "' foram ignorados.")
  ok <- ok & val > 0
  cat_ <- cat_[ok]; val <- val[ok]
  if (anyDuplicated(cat_)) { ag <- tapply(val, factor(cat_, levels = unique(cat_)), sum); cat_ <- names(ag); val <- as.numeric(ag) }
  if (!is.null(cfg$grafico$ordem_itens)) {
    o <- c(intersect(cfg$grafico$ordem_itens, cat_), setdiff(cat_, cfg$grafico$ordem_itens))
    val <- val[match(o, cat_)]; cat_ <- o
  }
  pct <- val / sum(val) * 100
  if ((P$agrupar_abaixo %||% 0) > 0 && any(pct < P$agrupar_abaixo)) {
    peq <- pct < P$agrupar_abaixo
    cat_ <- c(cat_[!peq], P$nome_agrupado); val <- c(val[!peq], sum(val[peq]))
    pct <- val / sum(val) * 100
  }
  est <- .estilos(cfg, cat_, grupo_gradiente = TRUE)
  dir <- if (P$sentido == "horario") 1 else -1
  fr <- cumsum(c(0, val)) / sum(val)
  a0 <- P$angulo_inicial + dir * fr[-length(fr)] * P$angulo_total
  a1 <- P$angulo_inicial + dir * fr[-1] * P$angulo_total
  r0 <- P$raio_furo
  polys <- list(); rot <- list()
  for (i in seq_along(cat_)) {
    am <- (a0[i] + a1[i]) / 2 * pi / 180
    desl <- if (cat_[i] %in% P$explodir) P$deslocamento_explosao / 100 else 0
    cx <- desl * sin(am); cy <- desl * cos(am)
    ang <- seq(a0[i], a1[i], length.out = max(3, ceiling(abs(a1[i] - a0[i])) + 1)) * pi / 180
    px <- c(sin(ang), if (r0 > 0) r0 * sin(rev(ang)) else 0)
    py <- c(cos(ang), if (r0 > 0) r0 * cos(rev(ang)) else 0)
    polys[[i]] <- data.frame(x = px + cx, y = py + cy, serie = cat_[i])
    partes <- c(categoria = cat_[i], valor = .fmt_num(val[i], P$rotulos_casas),
                percentual = paste0(.fmt_num(pct[i], P$rotulos_casas), "%"))
    texto <- paste(partes[intersect(P$rotulos, names(partes))], collapse = P$rotulos_separador)
    rr <- switch(P$rotulos_posicao, dentro = if (r0 > 0) (1 + r0) / 2 else 0.62,
                 borda = 1.08, fora = P$rotulos_distancia)
    lado <- sin(am)
    hj <- if (P$rotulos_posicao == "dentro") 0.5 else if (abs(lado) < 0.15) 0.5 else if (lado > 0) 0 else 1
    corr <- if (identical(P$rotulos_cor, "auto")) {
      if (P$rotulos_posicao == "dentro") (if (.luminancia(est[[i]]$cor) < 0.5) "white" else "black") else cfg$texto$cor
    } else .cor(P$rotulos_cor)
    if (nzchar(texto) && pct[i] >= (P$ocultar_rotulo_abaixo %||% 0))
      rot[[length(rot) + 1]] <- data.frame(x = cx + rr * sin(am), y = cy + rr * cos(am), rot = texto,
        hj = hj, cor = corr, gx0 = cx + 1.0 * sin(am), gy0 = cy + 1.0 * cos(am),
        gx1 = cx + (rr - 0.07) * sin(am), gy1 = cy + (rr - 0.07) * cos(am))
  }
  pl <- do.call(rbind, polys); pl$serie <- factor(pl$serie, levels = cat_)
  cam <- list(geom_polygon(data = pl, aes(x = x, y = y, group = serie, fill = serie),
                           colour = if (is.na(P$contorno_cor)) NA else .cor(P$contorno_cor),
                           linewidth = .lw(P$contorno_espessura_pt)))
  lim <- 1 + max(c(0, P$deslocamento_explosao / 100 * (length(P$explodir) > 0)))
  if (length(rot)) {
    rd <- do.call(rbind, rot)
    if (P$rotulos_posicao == "fora" && isTRUE(P$linha_guia))
      cam[[length(cam) + 1]] <- geom_segment(data = rd, aes(x = gx0, y = gy0, xend = gx1, yend = gy1),
                                             colour = cfg$texto$cor, linewidth = .lw(0.6))
    cam[[length(cam) + 1]] <- geom_text(data = rd, aes(x = x, y = y, label = rot), hjust = rd$hj,
      colour = rd$cor, size = .tx(P$rotulos_tamanho_pt), lineheight = 0.95, family = .fonte(cfg$texto$fonte))
    if (P$rotulos_posicao != "dentro") lim <- max(lim, max(abs(c(rd$x, rd$y))) + 0.15)
  }
  leg <- !("categoria" %in% P$rotulos)
  list(camadas = c(cam, .escalas_legenda(est, "fill", cfg)),
       info = list(pizza = TRUE, lim = lim, legenda_auto = leg))
}

# ---- Distribuições ----------------------------------------------------------------
.amostras <- function(dados, cfg) {
  gcol <- cfg$grafico$coluna_grupo
  if (!is.null(gcol)) {
    gcol <- .coluna(dados, gcol, "cfg$grafico$coluna_grupo")
    vcol <- .colunas_y(dados, cfg, excluir = gcol)[1]
    g <- as.character(dados[[gcol]])
    itens <- unique(g[!is.na(g)])
    if (!is.null(cfg$grafico$ordem_itens)) itens <- c(intersect(cfg$grafico$ordem_itens, itens), setdiff(itens, cfg$grafico$ordem_itens))
    am <- lapply(itens, function(i) { v <- dados[[vcol]][g %in% i]; v[!is.na(v)] })
    return(list(am = stats::setNames(am, itens), nome_valor = vcol, nome_grupo = gcol))
  }
  ycols <- .colunas_y(dados, cfg, excluir = NULL)
  am <- lapply(ycols, function(y) { v <- dados[[y]]; v[!is.na(v)] })
  list(am = stats::setNames(am, ycols), nome_valor = if (length(ycols) == 1) ycols else "Valor", nome_grupo = NULL)
}

.construir_distribuicao <- function(dados, cfg) {
  D <- cfg$distribuicao; tipo <- cfg$grafico$tipo
  A <- .amostras(dados, cfg); am <- A$am; itens <- names(am)
  vazio <- vapply(am, length, 0) < 2
  if (any(vazio)) .erro("Distribuição: a(s) série(s) ", paste(itens[vazio], collapse = ", "), " tem(têm) menos de 2 valores.")
  est <- .estilos(cfg, itens)
  multi <- length(itens) > 1
  todos <- unlist(am)
  cam <- list(); faixa_y <- 0; aes_leg <- character(0); tit_y <- NULL
  escalar <- function(dens, n, w) switch(D$medida, contagem = dens * n * w, frequencia = dens * w,
                                         percentual = dens * w * 100, densidade = dens)
  if (tipo == "histograma") {
    if (!is.null(D$largura_classe)) {
      w <- D$largura_classe
      ini <- D$inicio_classe %||% (floor(min(todos) / w) * w)
      quebras <- seq(ini, max(todos) + w, by = w)
      quebras <- quebras[seq_len(max(2, which(quebras > max(todos))[1]))]
    } else if (!is.null(D$n_classes)) {
      ini <- D$inicio_classe %||% min(todos)
      quebras <- seq(ini, max(todos), length.out = D$n_classes + 1)
    } else {
      quebras <- graphics::hist(todos, plot = FALSE)$breaks
      if (!is.null(D$inicio_classe)) { w <- diff(quebras)[1]; quebras <- seq(D$inicio_classe, max(todos) + w, by = w) }
    }
    if (min(todos) < min(quebras)) .erro("distribuicao$inicio_classe (", min(quebras), ") é maior que o menor dado (", min(todos), ").")
    ret <- do.call(rbind, lapply(itens, function(i) {
      h <- graphics::hist(am[[i]], breaks = quebras, plot = FALSE, right = FALSE, include.lowest = TRUE)
      n <- length(am[[i]]); w <- diff(quebras)
      y <- switch(D$medida, contagem = h$counts, frequencia = h$counts / n,
                  percentual = h$counts / n * 100, densidade = h$counts / (n * w))
      data.frame(xmin = quebras[-length(quebras)], xmax = quebras[-1], ymin = 0, ymax = y, serie = i)
    }))
    ret$serie <- factor(ret$serie, levels = itens)
    if (multi && all(vapply(est, function(e) e$opf >= 1, TRUE))) {
      cfg2 <- cfg; cfg2$serie_padrao$opacidade_preenchimento <- D$opacidade_multiplas %||% 0.55
      est <- .estilos(cfg2, itens)
    }
    cam[[1]] <- geom_rect(data = ret, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = serie),
                          colour = if (is.na(D$contorno_cor)) NA else .cor(D$contorno_cor),
                          linewidth = .lw(D$contorno_espessura_pt))
    aes_leg <- "fill"; faixa_y <- c(0, ret$ymax); faixa_x <- range(quebras)
    tit_y <- switch(D$medida, contagem = "Contagem", frequencia = "Frequência relativa",
                    percentual = "Frequência (%)", densidade = "Densidade")
    curvas <- list()
    for (i in itens) {
      x <- am[[i]]; n <- length(x); w <- diff(quebras)[1]
      grade <- seq(min(quebras), max(quebras), length.out = 300)
      if (isTRUE(D$curva_densidade)) {
        dd <- stats::density(x, adjust = D$ajuste_banda, from = min(grade), to = max(grade), n = 300)
        curvas[[length(curvas) + 1]] <- data.frame(x = dd$x, y = escalar(dd$y, n, w), serie = i, tipo = "dens")
      }
      if (isTRUE(D$curva_normal)) {
        curvas[[length(curvas) + 1]] <- data.frame(x = grade, y = escalar(stats::dnorm(grade, mean(x), stats::sd(x)), n, w),
                                                   serie = i, tipo = "normal")
      }
    }
    if (length(curvas)) {
      cv <- do.call(rbind, curvas); cv$serie <- factor(cv$serie, levels = itens)
      cam[[length(cam) + 1]] <- geom_line(data = cv, aes(x = x, y = y, colour = serie, group = interaction(serie, tipo),
                                                        linetype = tipo), linewidth = .lw(D$espessura_curva_pt), show.legend = FALSE)
      cam[[length(cam) + 1]] <- scale_linetype_manual(values = c(dens = "solid", normal = "dashed"), guide = "none")
      aes_leg <- c(aes_leg, "colour"); faixa_y <- c(faixa_y, cv$y)
    }
  } else if (tipo == "densidade") {
    dd <- do.call(rbind, lapply(itens, function(i) {
      d <- stats::density(am[[i]], adjust = D$ajuste_banda)
      data.frame(x = d$x, y = d$y, serie = i)
    }))
    dd$serie <- factor(dd$serie, levels = itens)
    if (isTRUE(D$preencher_densidade)) {
      for (i in itens) {
        e <- est[[i]]; s <- dd[dd$serie == i, ]
        fill <- if (identical(cfg$cores$preenchimento, "gradiente"))
          .gradiente(.alfa(e$cor, D$opacidade_area), .alfa(e$cor2, D$opacidade_area), cfg$cores$gradiente_direcao)
          else .alfa(e$cor, D$opacidade_area)
        cam[[length(cam) + 1]] <- geom_ribbon(data = s, aes(x = x, ymin = 0, ymax = y), fill = fill, colour = NA)
      }
    }
    cam[[length(cam) + 1]] <- geom_line(data = dd, aes(x = x, y = y, colour = serie, linetype = serie, linewidth = serie, alpha = serie))
    aes_leg <- c("colour", "linetype", "linewidth", "alpha")
    faixa_y <- c(0, dd$y); faixa_x <- range(dd$x); tit_y <- "Densidade"
  } else {
    ec <- do.call(rbind, lapply(itens, function(i) {
      x <- sort(am[[i]]); n <- length(x)
      data.frame(x = c(x[1], x), y = c(0, seq_len(n) / n), serie = i)
    }))
    ec$serie <- factor(ec$serie, levels = itens)
    cam[[1]] <- geom_step(data = ec, aes(x = x, y = y, colour = serie, linetype = serie, linewidth = serie, alpha = serie),
                          direction = "hv")
    aes_leg <- c("colour", "linetype", "linewidth", "alpha")
    faixa_y <- c(0, 1); faixa_x <- range(ec$x); tit_y <- "Probabilidade acumulada"
  }
  if (isTRUE(D$marcas_rug)) {
    escura <- vapply(itens, function(i) grDevices::colorRampPalette(c(est[[i]]$cor, "black"))(3)[2], "")
    rg <- data.frame(x = todos, cor = rep(escura, vapply(am, length, 0)))
    cam[[length(cam) + 1]] <- geom_rug(data = rg, aes(x = x), colour = rg$cor, sides = "b",
                                       length = unit(5, "pt"), linewidth = .lw(0.6), inherit.aes = FALSE)
  }
  ax_x <- .calc_eixo(cfg$eixo_x, faixa_x, forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa_y, forcar = cfg$.interno$forcar_y)
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = FALSE,
                   titulo_x = cfg$eixo_x$titulo %||% A$nome_valor, titulo_y = cfg$eixo_y$titulo %||% tit_y,
                   legenda_auto = TRUE, faixa_x = faixa_x, faixa_y = faixa_y))
}

# ---- Boxplot e variações ------------------------------------------------------------
.enxame <- function(y, centro, largura, faixa_y, tam_rel = 0.025) {
  n <- length(y); if (!n) return(numeric(0))
  h <- max(diff(faixa_y) * tam_rel, 1e-12)
  bin <- floor((y - min(y)) / h)
  off <- numeric(n)
  for (b in unique(bin)) {
    idx <- which(bin == b); k <- length(idx)
    passo <- min(largura / max(k, 1), largura / 6)
    pos <- c(0, as.vector(rbind(seq_len(k), -seq_len(k))))[seq_len(k)]
    off[idx[order(y[idx])]] <- pos * passo
  }
  off <- pmax(pmin(off, largura / 2), -largura / 2)
  centro + off
}

.construir_boxplot <- function(dados, cfg) {
  X <- cfg$boxplot; var <- X$variacao
  A <- .amostras(dados, cfg); am <- A$am; itens <- names(am)
  if (any(vapply(am, length, 0) == 0)) .erro("Boxplot: série(s) sem dados: ", paste(itens[vapply(am, length, 0) == 0], collapse = ", "))
  flip <- identical(X$orientacao, "horizontal")
  est <- .estilos(cfg, itens, inverter_grad = flip)
  k <- length(itens); w <- X$largura
  contorno <- function(i) if (identical(X$contorno_cor, "serie")) est[[i]]$cor else .cor(X$contorno_cor)
  polys <- list(); segs <- list(); pts_media <- list(); pts_out <- list(); pts_dados <- list(); txt_n <- list()
  faixa <- range(unlist(am))
  set.seed(X$semente %||% 123)
  erro_media <- function(x, tipo) {
    n <- length(x); s <- stats::sd(x); if (is.na(s)) s <- 0
    switch(tipo, desvio_padrao = s, erro_padrao = s / sqrt(n),
           ic95 = if (n > 1) stats::qt(0.975, n - 1) * s / sqrt(n) else 0)
  }
  for (j in seq_len(k)) {
    it <- itens[j]; x <- am[[it]]; p <- j; cc <- contorno(it)
    q <- stats::quantile(x, c(X$caixa_percentis[1], 50, X$caixa_percentis[2]) / 100, names = FALSE, type = 7)
    md <- mean(x)
    wl <- switch(X$bigode,
      tukey = { iqr <- q[3] - q[1]; c(min(x[x >= q[1] - X$bigode_coef * iqr]), max(x[x <= q[3] + X$bigode_coef * iqr])) },
      percentis = stats::quantile(x, X$bigode_percentis / 100, names = FALSE, type = 7),
      min_max = range(x),
      desvio_padrao = , erro_padrao = , ic95 = md + c(-1, 1) * erro_media(x, X$bigode))
    out <- if (X$bigode %in% c("tukey", "percentis")) x[x < wl[1] | x > wl[2]] else numeric(0)
    if (var == "media_erro") {
      er <- erro_media(x, X$media_erro_tipo)
      if (X$media_erro_estilo == "barra")
        polys[[length(polys) + 1]] <- data.frame(x = p + c(-w, w, w, -w) / 2, y = c(0, 0, md, md), item = it)
      segs[[length(segs) + 1]] <- data.frame(x = p, xend = p, y = md - er, yend = md + er, cor = cc, lw = X$contorno_espessura_pt)
      segs[[length(segs) + 1]] <- data.frame(x = p - w * X$bigode_chapeu / 2, xend = p + w * X$bigode_chapeu / 2,
                                             y = c(md - er, md + er), yend = c(md - er, md + er), cor = cc, lw = X$contorno_espessura_pt)
      if (X$media_erro_estilo == "ponto")
        pts_media[[length(pts_media) + 1]] <- data.frame(x = p, y = md, fill = est[[it]]$cor, tam = X$media_tamanho_pt * 1.4, item = it)
      faixa <- range(c(faixa, 0, md + er, md - er))
      if (isTRUE(X$mostrar_n)) txt_n[[length(txt_n) + 1]] <- data.frame(x = p, y = md + er, rot = paste0("n = ", length(x)))
      next
    }
    # caixa (ou violino)
    xb0 <- p - w / 2; xb1 <- p + w / 2
    if (var == "meio_box") { xb0 <- p; xb1 <- p + w / 2 }
    if (var == "violino_box") { xb0 <- p - w * 0.12; xb1 <- p + w * 0.12 }
    if (var %in% c("violino", "violino_box")) {
      dd <- stats::density(x, adjust = X$violino_ajuste_banda, cut = if (isTRUE(X$violino_cortar)) 0 else 3)
      lv <- dd$y / max(dd$y) * X$violino_largura / 2
      polys[[length(polys) + 1]] <- data.frame(x = c(p - lv, rev(p + lv)), y = c(dd$x, rev(dd$x)), item = it)
      faixa <- range(c(faixa, dd$x))
    }
    if (var != "violino") {
      if (isTRUE(X$entalhe)) {
        nt <- 1.58 * (q[3] - q[1]) / sqrt(length(x)); ind <- (xb1 - xb0) * 0.25
        bx <- data.frame(x = c(xb0, xb0, xb0 + ind, xb0, xb0, xb1, xb1, xb1 - ind, xb1, xb1),
                         y = c(q[1], q[2] - nt, q[2], q[2] + nt, q[3], q[3], q[2] + nt, q[2], q[2] - nt, q[1]))
        mx <- c(xb0 + ind, xb1 - ind)
      } else {
        bx <- data.frame(x = c(xb0, xb1, xb1, xb0), y = c(q[1], q[1], q[3], q[3])); mx <- c(xb0, xb1)
      }
      bx$item <- if (var == "violino_box") paste0(".branco.", it) else it
      polys[[length(polys) + 1]] <- bx
      xm <- (xb0 + xb1) / 2; cap <- (xb1 - xb0) * X$bigode_chapeu / 2
      if (X$bigode_lado %in% c("ambos", "inferior"))
        segs[[length(segs) + 1]] <- data.frame(x = c(xm, xm - cap), xend = c(xm, xm + cap), y = c(q[1], wl[1]),
                                               yend = c(wl[1], wl[1]), cor = cc, lw = X$contorno_espessura_pt)
      if (X$bigode_lado %in% c("ambos", "superior"))
        segs[[length(segs) + 1]] <- data.frame(x = c(xm, xm - cap), xend = c(xm, xm + cap), y = c(q[3], wl[2]),
                                               yend = c(wl[2], wl[2]), cor = cc, lw = X$contorno_espessura_pt)
      if (isTRUE(X$mediana))
        segs[[length(segs) + 1]] <- data.frame(x = mx[1], xend = mx[2], y = q[2], yend = q[2], cor = cc, lw = X$mediana_espessura_pt)
      if (isTRUE(X$outliers) && length(out))
        pts_out[[length(pts_out) + 1]] <- data.frame(x = xm, y = out, cor = cc)
      faixa <- range(c(faixa, wl))
    }
    if (isTRUE(X$media)) pts_media[[length(pts_media) + 1]] <- data.frame(x = if (var == "meio_box") (xb0 + xb1) / 2 else p, y = md,
                                                                          fill = .cor(X$media_preenchimento), tam = X$media_tamanho_pt, item = it)
    if (var %in% c("box_pontos", "meio_box")) {
      centro <- if (var == "meio_box") p - w / 4 else p
      larg <- if (var == "meio_box") min(X$pontos_largura, w / 2 * 0.9) else X$pontos_largura
      xs <- switch(X$pontos_disposicao, coluna = rep(centro, length(x)),
                   jitter = centro + stats::runif(length(x), -larg / 2, larg / 2),
                   enxame = .enxame(x, centro, larg, range(unlist(am))))
      pts_dados[[length(pts_dados) + 1]] <- data.frame(x = xs, y = x, fill = .alfa(est[[it]]$cor, X$pontos_opacidade))
    }
    if (isTRUE(X$mostrar_n)) txt_n[[length(txt_n) + 1]] <- data.frame(x = p, y = max(wl[2], q[3], max(x)), rot = paste0("n = ", length(x)))
  }
  cam <- list()
  if (length(polys)) {
    pl <- do.call(rbind, polys)
    brancos <- grepl("^\\.branco\\.", pl$item)
    if (any(!brancos)) {
      pp <- pl[!brancos, ]; pp$item <- factor(pp$item, levels = itens)
      cam[[length(cam) + 1]] <- geom_polygon(data = pp, aes(x = x, y = y, group = item, fill = item),
        colour = if (identical(X$contorno_cor, "serie")) NA else .cor(X$contorno_cor),
        linewidth = .lw(X$contorno_espessura_pt))
      if (identical(X$contorno_cor, "serie"))
        for (it in levels(droplevels(pp$item)))
          cam[[length(cam) + 1]] <- geom_polygon(data = pp[pp$item == it, ], aes(x = x, y = y, group = item),
            fill = NA, colour = est[[it]]$cor, linewidth = .lw(X$contorno_espessura_pt), show.legend = FALSE)
    }
    if (any(brancos)) {
      pb <- pl[brancos, ]
      cam[[length(cam) + 1]] <- geom_polygon(data = pb, aes(x = x, y = y, group = item), fill = "white",
        colour = .cor(if (identical(X$contorno_cor, "serie")) "black" else X$contorno_cor), linewidth = .lw(X$contorno_espessura_pt))
    }
  }
  if (length(pts_dados)) {
    pd <- do.call(rbind, pts_dados)
    cam[[length(cam) + 1]] <- geom_point(data = pd, aes(x = x, y = y), shape = X$pontos_simbolo, fill = pd$fill,
      colour = if (X$pontos_simbolo >= 21) scales::alpha("black", 0.8) else pd$fill,
      size = .tx(X$pontos_tamanho_pt), stroke = .st(0.4))
  }
  if (length(segs)) {
    sg <- do.call(rbind, segs)
    cam[[length(cam) + 1]] <- geom_segment(data = sg, aes(x = x, xend = xend, y = y, yend = yend),
      colour = sg$cor, linewidth = .lw(sg$lw), lineend = "butt")
  }
  if (length(pts_out)) {
    po <- do.call(rbind, pts_out)
    cam[[length(cam) + 1]] <- geom_point(data = po, aes(x = x, y = y), shape = X$outliers_simbolo,
      colour = po$cor, size = .tx(X$outliers_tamanho_pt), stroke = .st(0.8))
  }
  if (length(pts_media)) {
    pm <- do.call(rbind, pts_media)
    cam[[length(cam) + 1]] <- geom_point(data = pm, aes(x = x, y = y), shape = X$media_simbolo, fill = pm$fill,
      colour = .cor(if (identical(X$contorno_cor, "serie")) "black" else X$contorno_cor), size = .tx(pm$tam), stroke = .st(0.9))
  }
  if (length(txt_n)) {
    tn <- do.call(rbind, txt_n); faixa <- range(c(faixa, tn$y + 0.06 * diff(faixa)))
    cam[[length(cam) + 1]] <- if (flip) geom_text(data = tn, aes(x = x, y = y, label = rot), hjust = -0.2,
                                                   size = .tx(cfg$texto$tamanho_base_pt * 0.8), family = .fonte(cfg$texto$fonte))
      else geom_text(data = tn, aes(x = x, y = y, label = rot), vjust = -0.6,
                     size = .tx(cfg$texto$tamanho_base_pt * 0.8), family = .fonte(cfg$texto$fonte))
  }
  ax_x <- .calc_eixo(cfg$eixo_x, c(0.5, k + 0.5), categorias = itens, forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, faixa, forcar = cfg$.interno$forcar_y)
  aes_leg <- if (length(polys) && any(!grepl("^\\.branco\\.", do.call(rbind, polys)$item))) "fill" else character(0)
  list(camadas = c(cam, .escalas_legenda(est, aes_leg, cfg)),
       info = list(ax_x = ax_x, ax_y = ax_y, flip = flip, titulo_x = cfg$eixo_x$titulo %||% (A$nome_grupo %||% ""),
                   titulo_y = cfg$eixo_y$titulo %||% A$nome_valor, legenda_auto = FALSE,
                   faixa_x = c(0.5, k + 0.5), faixa_y = faixa))
}

# =============================================================================
#  MONTAGEM FINAL (eixos + tema + anotações)
# =============================================================================
.escala_continua <- function(ax, xy, sec, posicao = NULL) {
  f <- if (xy == "x") scale_x_continuous else scale_y_continuous
  args <- list(limits = ax$limites, breaks = ax$maiores, minor_breaks = ax$menores,
               labels = ax$rotulos, transform = ax$trans, expand = expansion(mult = ax$mult),
               oob = scales::oob_keep)
  if (!is.null(sec)) args$sec.axis <- sec
  if (!is.null(posicao)) args$position <- posicao
  do.call(f, args)
}

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
      label = if (pm) .plotmath(t$texto) else t$texto, parse = pm,
      hjust = switch(t$alinhamento %||% "centro", esquerda = 0, centro = 0.5, direita = 1),
      colour = .cor(t$cor %||% cfg$texto$cor), size = .tx(t$tamanho_pt %||% cfg$texto$tamanho_base_pt),
      fontface = if (isTRUE(t$negrito)) "bold" else "plain", family = fonte)
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

.plotar_um <- function(dados, cfg) {
  tipo <- cfg$grafico$tipo
  res <- switch(tipo,
    pontos = , linha = , linha_pontos = , area = , area_empilhada = .construir_xy(dados, cfg),
    barras = .construir_barras(dados, cfg),
    pizza = .construir_pizza(dados, cfg),
    histograma = , densidade = , ecdf = .construir_distribuicao(dados, cfg),
    boxplot = .construir_boxplot(dados, cfg))
  info <- res$info
  extra <- .camadas_extra(cfg, info)
  g <- ggplot() + extra$antes + res$camadas + extra$depois
  mostrar_leg <- if (identical(cfg$legenda$mostrar, "auto")) info$legenda_auto else isTRUE(cfg$legenda$mostrar)

  if (isTRUE(info$pizza)) {
    g <- g + coord_fixed(xlim = c(-info$lim, info$lim), ylim = c(-info$lim, info$lim), expand = FALSE, clip = "off") +
      .tema(cfg, cfg$eixo_x, cfg$eixo_y, list(hor = "bottom", ver = "left", lado_y2 = ""), sem_eixos = TRUE) +
      labs(title = .texto(cfg$titulos$titulo), subtitle = .texto(cfg$titulos$subtitulo))
    if (!mostrar_leg) g <- g + theme(legend.position = "none")
    attr(g, "info") <- info
    return(g)
  }

  if (is.null(info$y2) && isTRUE(cfg$eixo_y2$ativo) && identical(cfg$eixo_y2$modo, "transformado")) {
    if (isTRUE(info$flip)) .erro("eixo_y2 \"transformado\" não é suportado em barras/caixas horizontais.")
    if (info$ax_y$escala != "linear") .erro("eixo_y2 \"transformado\" exige eixo_y linear.")
    fa <- cfg$eixo_y2$fator %||% 1; de <- cfg$eixo_y2$deslocamento %||% 0
    if (fa == 0) .erro("cfg$eixo_y2$fator não pode ser 0.")
    e2 <- utils::modifyList(cfg$eixo_y, cfg$eixo_y2[intersect(names(cfg$eixo_y2), names(cfg$eixo_y))])
    e2$escala <- "linear"; e2$inverter <- FALSE
    l2 <- sort(fa * info$ax_y$limites + de)
    e2$inicio <- e2$inicio %||% l2[1]; e2$fim <- e2$fim %||% l2[2]
    if (e2$inicio != l2[1] || e2$fim != l2[2]) {
      .aviso("eixo_y2 \"transformado\": os limites seguem o eixo_y (", l2[1], " a ", l2[2], "); inicio/fim do y2 ignorados.")
      e2$inicio <- l2[1]; e2$fim <- l2[2]
    }
    ax2 <- .calc_eixo(e2, l2)
    cor2 <- if (is.null(cfg$eixo_y2$cor_eixo) || identical(cfg$eixo_y2$cor_eixo, "serie")) NULL else cfg$eixo_y2$cor_eixo
    info$y2 <- list(ax = ax2, para2 = function(v) fa * v + de, titulo = cfg$eixo_y2$titulo %||% "",
                    cor = cor2 %||% cfg$texto$cor)
  }
  cx <- cfg$caixa; it <- cfg$.interno %||% list()
  espelhar <- isTRUE(cx$fechada) && isTRUE(cx$ticks_espelhados)
  sec_dup <- function(ax) if (espelhar) dup_axis(name = NULL, labels = if (isTRUE(cx$rotulos_espelhados)) derive() else NULL) else NULL
  y_dir <- isTRUE(it$y_direita) && is.null(info$y2)
  x_topo <- isTRUE(it$x_topo)
  # secundários
  sec_x <- sec_dup(info$ax_x)
  sec_y <- if (!is.null(info$y2)) {
    a2 <- info$y2$ax
    sec_axis(transform = info$y2$para2, name = .texto(info$y2$titulo), breaks = a2$maiores, labels = a2$rotulos)
  } else sec_dup(info$ax_y)
  g <- g + .escala_continua(info$ax_x, "x", sec_x, if (x_topo) "top") +
    .escala_continua(info$ax_y, "y", sec_y, if (y_dir) "right")
  gm <- list(x = guide_axis(minor.ticks = length(info$ax_x$menores) > 0),
             y = guide_axis(minor.ticks = length(info$ax_y$menores) > 0))
  if (!is.null(sec_x)) gm$x.sec <- guide_axis(minor.ticks = length(info$ax_x$menores) > 0)
  if (!is.null(sec_y)) gm$y.sec <- guide_axis(minor.ticks = is.null(info$y2) && length(info$ax_y$menores) > 0)
  g <- g + do.call(guides, gm)
  g <- g + labs(x = .texto(info$titulo_x), y = .texto(info$titulo_y),
                title = .texto(cfg$titulos$titulo), subtitle = .texto(cfg$titulos$subtitulo))
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
  ev_y2 <- ev
  g <- g + .tema(cfg, eh, ev, lados, cor_y2 = if (!is.null(info$y2)) .cor(info$y2$cor) else NULL)
  if (!is.null(info$y2)) {
    # estilo de rótulos do y2: casas/notação próprias já nos rótulos; mostra sempre
    g <- g + theme(axis.text.y.right = .elem_rotulo(utils::modifyList(ev, list(mostrar_rotulos = TRUE)), cfg, "right", .cor(info$y2$cor)),
                   axis.title.y.right = .elem_titulo(utils::modifyList(ev, list(mostrar_titulo = TRUE)), cfg, "right", .cor(info$y2$cor)))
  }
  if (y_dir && espelhar) {
    g <- g + theme(axis.text.y.left = element_blank(), axis.title.y.left = element_blank(),
                   axis.text.y.right = .elem_rotulo(ev, cfg, "right"), axis.title.y.right = .elem_titulo(ev, cfg, "right"))
  }
  ti <- .ticks_internos(axh, axv, lados)
  if (!is.null(ti)) g <- g + ti
  if (!mostrar_leg) g <- g + theme(legend.position = "none")
  attr(g, "info") <- info
  g
}

# =============================================================================
#  PLOTAR (ponto de entrada) — simples, painéis ou quebra de eixo
# =============================================================================
plotar <- function(dados, cfg = get("cfg", envir = globalenv())) {
  if (missing(dados) || !is.data.frame(dados)) .erro("plotar(dados, cfg): 'dados' deve ser o resultado de ler_csv().")
  .validar(cfg)
  g <- if (isTRUE(cfg$paineis$ativo)) .plotar_paineis(dados, cfg)
       else if (isTRUE(cfg$quebra$ativo)) .plotar_quebra(dados, cfg)
       else .plotar_um(dados, cfg)
  attr(g, "dados") <- dados
  attr(g, "cfg") <- cfg
  g
}

.formatar_letra <- function(i, formato) {
  l <- letters[i]; L <- LETTERS[i]
  rom <- tolower(as.character(utils::as.roman(i)))
  switch(formato, "(a)" = paste0("(", l, ")"), "a)" = paste0(l, ")"), "a" = l,
         "(A)" = paste0("(", L, ")"), "A" = L, "(i)" = paste0("(", rom, ")"))
}

.rotulo_lateral <- function(texto, cfg, vertical = TRUE) {
  e <- if (vertical) cfg$eixo_y else cfg$eixo_x
  face <- if (isTRUE(e$negrito_titulo)) "bold" else "plain"
  patchwork::wrap_elements(full = textGrob(.texto(texto), rot = if (vertical) 90 else 0,
    gp = gpar(fontsize = e$tamanho_titulo_pt %||% cfg$texto$tamanho_base_pt, fontface = face,
              fontfamily = .fonte(cfg$texto$fonte), col = e$cor_titulo %||% cfg$texto$cor)))
}

.plotar_paineis <- function(dados, cfg) {
  P <- cfg$paineis; n <- length(P$lista)
  if (n < 1) .erro("cfg$paineis$ativo = TRUE, mas cfg$paineis$lista está vazia. Veja o exemplo em 01_config.R.")
  vertical <- P$direcao == "vertical"
  comum <- if (vertical) "eixo_x" else "eixo_y"
  cfgs <- lapply(seq_len(n), function(i) {
    p <- P$lista[[i]]
    if (!is.null(p[[comum]]) && length(setdiff(names(p[[comum]]), c("mostrar_rotulos", "mostrar_titulo"))))
      .aviso("Painel ", i, ": ajustes em ", comum, " são ignorados — o ", comum, " é comum a todos os painéis.")
    p[[comum]] <- NULL
    ci <- .mesclar(cfg, p)
    ci$paineis$ativo <- FALSE; ci$quebra$ativo <- FALSE
    ci$.interno <- list(em_painel = TRUE)
    .validar(ci)
    ci
  })
  # 1ª passada: faixa comum
  faixas <- lapply(cfgs, function(ci) {
    g <- .plotar_um(dados, ci); inf <- attr(g, "info")
    if (isTRUE(inf$pizza)) .erro("Pizza não pode ser usada em painéis com eixo comum.")
    if (vertical) inf$faixa_x else inf$faixa_y
  })
  tipos <- vapply(cfgs, function(ci) ci$grafico$tipo, "")
  conhecidos <- c(names(dados), unlist(lapply(names(dados), function(n) if (!is.numeric(dados[[n]])) unique(as.character(dados[[n]])))))
  for (s in setdiff(unique(unlist(lapply(cfgs, function(ci) names(ci$series)))), conhecidos))
    .aviso("cfg$series[[\"", s, "\"]] não corresponde a nenhuma coluna/categoria dos dados.")
  forcar <- if (vertical && all(tipos %in% c("barras", "boxplot")) || (!vertical && FALSE)) NULL else {
    ax <- .calc_eixo(cfg[[comum]], unlist(faixas))
    ax$limites
  }
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
    if (i > 1 || !is.null(cfg$titulos$titulo)) { if (i > 1) { ci$titulos$titulo <- NULL; ci$titulos$subtitulo <- NULL } }
    plots[[i]] <- .plotar_um(dados, ci)
  }
  tam <- P$tamanhos %||% rep(1, n)
  if (length(tam) != n) .erro("cfg$paineis$tamanhos deve ter ", n, " valores (um por painel).")
  pw <- if (vertical) patchwork::wrap_plots(plots, ncol = 1, heights = tam)
        else patchwork::wrap_plots(plots, nrow = 1, widths = tam)
  if (isTRUE(P$legenda_unica)) {
    pos <- switch(cfg$legenda$posicao, dentro = "right", direita = "right", esquerda = "left", topo = "top", base = "bottom")
    pw <- pw + patchwork::plot_layout(guides = "collect") & theme(legend.position = pos)
  }
  if (!is.null(P$titulo_unico)) {
    lab <- .rotulo_lateral(P$titulo_unico, cfg, vertical)
    pw <- if (vertical) patchwork::wrap_plots(lab, pw, nrow = 1, widths = grid::unit(c(1.6, 1), c("lines", "null")))
          else patchwork::wrap_plots(pw, lab, ncol = 1, heights = grid::unit(c(1, 1.6), c("null", "lines")))
  }
  pw
}

.plotar_quebra <- function(dados, cfg) {
  Q <- cfg$quebra
  if (is.null(Q$de) || is.null(Q$ate) || Q$de >= Q$ate) .erro("cfg$quebra: defina de < ate (ex.: de = 20, ate = 80).")
  if (cfg$grafico$tipo == "pizza") .erro("Quebra de eixo não se aplica a pizza.")
  base <- cfg; base$quebra$ativo <- FALSE
  g0 <- .plotar_um(dados, base); inf <- attr(g0, "info")
  lim <- inf$ax_y$limites
  if (Q$de <= lim[1] || Q$ate >= lim[2]) .erro("cfg$quebra: o trecho omitido (", Q$de, " a ", Q$ate,
                                               ") precisa estar dentro do eixo Y (", lim[1], " a ", lim[2], ").")
  inferior <- base; superior <- base
  inferior$eixo_y$inicio <- lim[1]; inferior$eixo_y$fim <- Q$de
  superior$eixo_y$inicio <- Q$ate; superior$eixo_y$fim <- lim[2]
  for (k in c("inferior", "superior")) {
    ck <- get(k)
    ck$eixo_y$mostrar_titulo <- FALSE
    m <- cfg$caixa$margens_cm; esp <- Q$espaco_pt / 2 / 72 * 2.54
    ck$caixa$margens_cm <- if (k == "superior") c(m[1], m[2], esp, m[4]) else c(esp, m[2], m[3], m[4])
    if (k == "superior") { ck$eixo_x$mostrar_rotulos <- FALSE; ck$eixo_x$mostrar_titulo <- FALSE }
    else { ck$legenda$mostrar <- FALSE; ck$titulos$titulo <- NULL; ck$titulos$subtitulo <- NULL; ck$anotacoes$letra <- NULL }
    assign(k, ck)
  }
  gs <- .plotar_um(dados, superior); gi <- .plotar_um(dados, inferior)
  if (isTRUE(Q$marcas)) {
    marca <- function(y) {
      gp <- gpar(col = cfg$caixa$cor, lwd = .lw(cfg$caixa$espessura_pt) * ggplot2::.pt)
      dx <- unit(5, "pt"); dy <- unit(4, "pt")
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

# =============================================================================
#  EXPORTAÇÃO E PRÉVIA
# =============================================================================
.usa_gradiente <- function(cfg) {
  identical(cfg$cores$preenchimento, "gradiente") ||
    (isTRUE(cfg$paineis$ativo) && any(vapply(cfg$paineis$lista, function(p) identical(p$cores$preenchimento, "gradiente"), TRUE)))
}

.ragg_ok <- function(cfg = NULL) {
  if (!.tem("ragg")) return(FALSE)
  # ragg < 1.5 desenha errado gradiente radial (claro -> escuro): usa Cairo nesse caso
  if (!is.null(cfg) && identical(cfg$cores$preenchimento, "gradiente") &&
      grepl("radial", cfg$cores$gradiente_direcao) && utils::packageVersion("ragg") < "1.5.0") return(FALSE)
  TRUE
}

.abrir_dispositivo <- function(formato, arq, larg_in, alt_in, dpi, fundo, usar_ragg = .tem("ragg")) {
  switch(formato,
    png = if (usar_ragg) ragg::agg_png(arq, width = larg_in, height = alt_in, units = "in", res = dpi, background = fundo)
          else grDevices::png(arq, width = larg_in, height = alt_in, units = "in", res = dpi, bg = fundo,
                              type = if (capabilities("cairo")) "cairo" else "windows"),
    tiff = if (usar_ragg) ragg::agg_tiff(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                            background = fundo, compression = "lzw")
           else grDevices::tiff(arq, width = larg_in, height = alt_in, units = "in", res = dpi, bg = fundo,
                                compression = "lzw", type = if (capabilities("cairo")) "cairo" else "windows"),
    jpeg = if (usar_ragg) ragg::agg_jpeg(arq, width = larg_in, height = alt_in, units = "in", res = dpi,
                                            background = if (identical(fundo, "transparent")) "white" else fundo, quality = 95)
           else grDevices::jpeg(arq, width = larg_in, height = alt_in, units = "in", res = dpi, quality = 95,
                                bg = if (identical(fundo, "transparent")) "white" else fundo),
    pdf = if (capabilities("cairo")) grDevices::cairo_pdf(arq, width = larg_in, height = alt_in, bg = fundo)
          else grDevices::pdf(arq, width = larg_in, height = alt_in, bg = fundo, useDingbats = FALSE),
    svg = if (.tem("svglite")) svglite::svglite(arq, width = larg_in, height = alt_in, bg = fundo)
          else grDevices::svg(arq, width = larg_in, height = alt_in, bg = fundo),
    emf = if (.tem("devEMF")) devEMF::emf(arq, width = larg_in, height = alt_in, bg = fundo, emfPlus = TRUE)
          else .erro("Formato emf precisa do pacote devEMF (rode 00_instalar_pacotes.R)."),
    .erro("Formato '", formato, "' desconhecido. OPÇÕES: png, tiff, jpeg, pdf, svg, emf"))
}

.sem_gradiente <- function(cfg) {
  cfg$cores$preenchimento <- "solido"
  if (isTRUE(cfg$paineis$ativo)) cfg$paineis$lista <- lapply(cfg$paineis$lista, function(p) { if (!is.null(p$cores)) p$cores$preenchimento <- "solido"; p })
  cfg
}

#' Exporta o gráfico nos formatos de cfg$exportacao
salvar <- function(g, cfg = attr(g, "cfg") %||% get("cfg", envir = globalenv()), nome = NULL) {
  ex <- cfg$exportacao
  fator <- switch(ex$unidade, cm = 1 / 2.54, mm = 1 / 25.4, `in` = 1)
  larg <- ex$largura * fator; alt <- ex$altura * fator
  if (!dir.exists(ex$pasta)) dir.create(ex$pasta, recursive = TRUE)
  dados <- attr(g, "dados")
  base <- nome %||% ex$nome_arquivo %||% paste0(
    if (!is.null(attr(dados, "arquivo"))) tools::file_path_sans_ext(basename(attr(dados, "arquivo"))) else "grafico",
    "_", cfg$grafico$tipo)
  if (isTRUE(ex$carimbo_data)) base <- paste0(base, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  fundo <- if (isTRUE(ex$fundo_transparente)) "transparent" else "white"
  if (isTRUE(ex$fundo_transparente) && !is.null(dados)) {
    cfg$caixa$fundo_pagina <- "transparente"; cfg$caixa$fundo_painel <- "transparente"
    g <- plotar(dados, cfg)
  }
  saidas <- character(0)
  for (f in tolower(ex$formatos)) {
    ext <- switch(f, jpeg = "jpg", f)
    arq <- file.path(ex$pasta, paste0(base, ".", ext))
    if (!isTRUE(ex$sobrescrever)) { k <- 2; while (file.exists(arq)) { arq <- file.path(ex$pasta, paste0(base, "_", k, ".", ext)); k <- k + 1 } }
    .abrir_dispositivo(f, arq, larg, alt, ex$dpi, fundo, usar_ragg = .ragg_ok(cfg))
    disp <- grDevices::dev.cur()
    tryCatch({
      gg <- g
      if (.usa_gradiente(cfg)) {
        cap <- tryCatch(unlist(grDevices::dev.capabilities()$patterns), error = function(e) character(0))
        if (!"LinearGradient" %in% cap) {
          .aviso("O formato '", f, "' não suporta gradiente; usando cor sólida neste arquivo.")
          if (!is.null(dados)) gg <- plotar(dados, .sem_gradiente(cfg))
        }
      }
      print(gg)
    }, finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
    saidas <- c(saidas, arq)
  }
  message("Salvo: ", paste(saidas, collapse = "\n       "))
  invisible(saidas)
}

#' Prévia fiel (mesmo tamanho e fontes do arquivo final) no Viewer do RStudio
visualizar <- function(g, cfg = attr(g, "cfg") %||% get("cfg", envir = globalenv()), dpi = 150) {
  ex <- cfg$exportacao
  fator <- switch(ex$unidade, cm = 1 / 2.54, mm = 1 / 25.4, `in` = 1)
  arq <- tempfile("previa_", fileext = ".png")
  .abrir_dispositivo("png", arq, ex$largura * fator, ex$altura * fator, dpi, "white", usar_ragg = .ragg_ok(cfg))
  disp <- grDevices::dev.cur()
  tryCatch(print(g), finally = if (disp %in% grDevices::dev.list()) grDevices::dev.off(disp))
  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    html <- tempfile("previa_", fileext = ".html")
    writeLines(sprintf('<html><body style="margin:0;background:#e5e5e5;display:flex;justify-content:center;align-items:flex-start;padding:12px"><img src="%s" style="max-width:100%%;box-shadow:0 1px 6px #888"></body></html>',
                       basename(arq)), html)
    file.copy(arq, file.path(dirname(html), basename(arq)), overwrite = TRUE)
    viewer(html)
  } else {
    print(g)
  }
  invisible(arq)
}

#' Aplica o mesmo cfg a todos os CSVs de uma pasta
exportar_lote <- function(pasta = "dados", cfg = get("cfg", envir = globalenv()), padrao = "\\.csv$") {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE, ignore.case = TRUE)
  if (!length(arqs)) .erro("Nenhum CSV em '", pasta, "'.")
  res <- list()
  for (a in arqs) {
    message("\n>> ", basename(a))
    r <- tryCatch({
      d <- ler_csv(a, cfg$dados); g <- plotar(d, cfg)
      c2 <- cfg; c2$exportacao$nome_arquivo <- NULL
      salvar(g, c2)
    }, error = function(e) { message("   ERRO: ", conditionMessage(e)); NULL })
    res[[basename(a)]] <- r
  }
  invisible(res)
}

# =============================================================================
#  ESTILOS (presets) E RESET
# =============================================================================
.BLOCOS_ESTILO <- c("cores", "serie_padrao", "linhas", "barras", "pizza", "distribuicao", "boxplot",
                    "eixo_x", "eixo_y", "eixo_y2", "caixa", "grade", "legenda", "titulos", "texto", "exportacao")

salvar_estilo <- function(cfg, nome, pasta = "estilos") {
  if (!dir.exists(pasta)) dir.create(pasta)
  est <- cfg[.BLOCOS_ESTILO]
  # não guarda o que é específico de um conjunto de dados
  for (ax in c("eixo_x", "eixo_y", "eixo_y2")) est[[ax]][c("titulo", "inicio", "fim", "ticks_manuais", "rotulos_manuais")] <- NULL
  est$exportacao$nome_arquivo <- NULL
  arq <- file.path(pasta, paste0(nome, ".R"))
  con <- file(arq, "w", encoding = "UTF-8")
  writeLines(c(paste0("# Estilo '", nome, "' salvo em ", format(Sys.time(), "%d/%m/%Y %H:%M")),
               paste0("# Pode ser editado à mão. Carregue com: cfg <- carregar_estilo(\"", nome, "\", cfg)")), con)
  dput(est, con, control = c("keepNA", "keepInteger", "niceNames", "showAttributes"))
  close(con)
  message("Estilo salvo em ", arq)
  invisible(arq)
}

carregar_estilo <- function(nome, cfg = get("cfg", envir = globalenv()), pasta = "estilos") {
  arq <- if (file.exists(nome)) nome else file.path(pasta, paste0(nome, ".R"))
  if (!file.exists(arq)) {
    disp <- sub("\\.R$", "", list.files(pasta, pattern = "\\.R$"))
    .erro("Estilo '", nome, "' não encontrado. Disponíveis: ", paste(disp, collapse = ", "))
  }
  est <- eval(parse(arq, encoding = "UTF-8"))
  .mesclar(cfg, est)
}

listar_estilos <- function(pasta = "estilos") sub("\\.R$", "", list.files(pasta, pattern = "\\.R$"))

resetar_cfg <- function() {
  e <- new.env(); sys.source(file.path(.motor_pasta, "01_config.R"), envir = e)
  assign("cfg", e$cfg, envir = globalenv())
  message("cfg voltou ao padrão de 01_config.R")
  invisible(e$cfg)
}

listar_fontes <- function() {
  if (!.tem("systemfonts")) { message("Instale 'systemfonts' (vem com ragg) para listar as fontes."); return(invisible()) }
  f <- sort(unique(systemfonts::system_fonts()$family))
  print(f)
  invisible(f)
}

if (file.exists(file.path(.motor_pasta, "04_catalogo.R")))
  source(file.path(.motor_pasta, "04_catalogo.R"), encoding = "UTF-8")

message("Motor de gráficos carregado (ggplot2 ", utils::packageVersion("ggplot2"), "). ",
        "Comece por ajuda() ou abra 03_executar.R.")
