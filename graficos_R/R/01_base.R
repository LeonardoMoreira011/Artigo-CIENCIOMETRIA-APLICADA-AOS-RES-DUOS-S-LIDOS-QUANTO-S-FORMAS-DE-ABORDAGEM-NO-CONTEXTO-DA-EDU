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
.tem <- function(p) requireNamespace(p, quietly = TRUE)
.R42 <- getRversion() >= "4.2.0"

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
.tx <- function(pt) pt / ggplot2::.pt                    # texto e símbolos
.st <- function(pt) pt * 96 / 72 * 2 / ggplot2::.stroke  # borda de símbolo

.aviso <- function(...) warning(paste0(...), call. = FALSE, immediate. = TRUE)
.erro  <- function(...) stop(paste0(...), call. = FALSE)
