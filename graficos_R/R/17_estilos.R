# =============================================================================
#  R/17_estilos.R — estilos salvos, reset do cfg e lista de fontes
# =============================================================================

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
