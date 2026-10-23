# =============================================================================
#  R/01_base.R — opções, checagem de pacotes, utilitários e conversões de unidade
# =============================================================================
# (parte do motor carregado por 02_motor.R; não precisa editar)

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
# TRUE se o pacote p está instalado (pacotes opcionais ficam desativados sem erro).
.tem <- function(p) requireNamespace(p, quietly = TRUE)
.R42 <- getRversion() >= "4.2.0"
.GG4 <- utils::packageVersion("ggplot2") >= "4.0.0"

# Cópia de referência do cfg (para detectar nomes digitados errado)
.cfg_ref <- local({
  arq <- file.path(.motor_pasta, "01_config.R")
  if (file.exists(arq)) { e <- new.env(); sys.source(arq, envir = e); e$cfg } else {
    warning("Não achei 01_config.R em '", .motor_pasta, "': a checagem de nomes digitados errado, ",
            "ajuda() e resetar_cfg() ficam desativados.", call. = FALSE, immediate. = TRUE)
    NULL
  }
})

# ---- Conversões de unidade (tudo do usuário em pt) --------------------------
# ggplot: linewidth em "mm" de ggplot; texto/símbolo em mm; stroke próprio.
.lw <- function(pt) pt * 96 / 72 / ggplot2::.pt          # espessura de linha
# Tamanho de texto/símbolo: pt do usuário -> unidade interna do ggplot2.
.tx <- function(pt) pt / ggplot2::.pt                    # texto e símbolos
# Espessura da borda de símbolo: pt do usuário -> unidade 'stroke' do ggplot2.
.st <- function(pt) pt * 96 / 72 * 2 / ggplot2::.stroke  # borda de símbolo

# Pasta/arquivo relativo (ex.: "estilos", "dados/x.csv"): se não existe a partir da pasta de trabalho
# mas existe dentro da pasta do projeto, usa o do projeto (funciona mesmo com setwd() em outro lugar).
.eh_absoluto <- function(p) grepl("^([A-Za-z]:|/|\\\\|~)", p)
# Entra: caminho de pasta. Sai: o mesmo caminho, ou a pasta de mesmo nome dentro do projeto se só ela existir.
.pasta_proj <- function(p) {
  if (.eh_absoluto(p) || dir.exists(p)) return(p)
  alt <- file.path(.motor_pasta, p)
  if (dir.exists(alt)) alt else p
}
# Entra: caminho de arquivo. Sai: o mesmo caminho, ou o arquivo dentro do projeto se só ele existir.
.arquivo_proj <- function(a) {
  if (.eh_absoluto(a) || file.exists(a)) return(a)
  alt <- file.path(.motor_pasta, a)
  if (file.exists(alt)) alt else a
}

# Emite um aviso (warning) em português, sem mostrar a chamada interna.
# Idioma das mensagens e dos textos que o motor escreve sozinho: SÓ PORTUGUÊS (o inglês e o espanhol estão arquivados em idiomas_arquivados/;
# para reativar, peça). As mensagens ficam escritas em português e o resto da máquina de tradução (.traduzir_msg, .rot, .re) continua aqui, desligada.
# Versão que lia o idioma (guardada para reativar):
#   .idioma <- function() { i <- getOption("cinabro.idioma", "pt"); if (i %in% c("pt", "en", "es")) i else "pt" }
.idioma <- function() "pt"
.traduzir_msg <- function(msg) {
  i <- .idioma()
  if (i == "pt" || !exists(".TRAD_MOTOR", inherits = TRUE)) return(msg)
  d <- .TRAD_MOTOR[[i]]; if (is.null(d) || !length(d)) return(msg)
  chaves <- names(d)[order(-nchar(names(d)))]                       # as mais longas primeiro; uma passada só (não retraduz o que já traduziu)
  pad <- paste(gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", chaves), collapse = "|")
  m <- gregexpr(pad, msg, perl = TRUE)
  if (m[[1]][1] != -1) regmatches(msg, m) <- list(unname(d[regmatches(msg, m)[[1]]]))
  msg
}
# Texto padrão que aparece dentro do gráfico (títulos de eixo automáticos), no idioma escolhido.
.rot <- function(x) {
  i <- .idioma(); if (i == "pt" || !exists(".ROTULOS_IDIOMA", inherits = TRUE)) return(x)
  r <- .ROTULOS_IDIOMA[[i]][x]; ifelse(is.na(r), x, r)
}
.aviso <- function(...) warning(.traduzir_msg(paste0(...)), call. = FALSE, immediate. = TRUE)
.erro  <- function(...) stop(.traduzir_msg(paste0(...)), call. = FALSE)
