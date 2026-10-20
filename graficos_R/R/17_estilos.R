# =============================================================================
#  R/17_estilos.R — estilos salvos, reset do cfg e lista de fontes
# =============================================================================

# =============================================================================
#  ESTILOS (presets) E RESET
# =============================================================================
.BLOCOS_ESTILO <- c("cores", "serie_padrao", "linhas", "barras", "pizza", "distribuicao", "boxplot",
                    "eixo_x", "eixo_y", "eixo_y2", "caixa", "grade", "legenda", "titulos", "texto", "exportacao")

# Grava os blocos de aparência do cfg em estilos/<nome>.R (sem títulos nem limites dos dados).
salvar_estilo <- function(cfg, nome, pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  if (!dir.exists(pasta)) dir.create(pasta)
  est <- cfg[.BLOCOS_ESTILO]
  # não guarda o que é específico de um conjunto de dados
  for (ax in c("eixo_x", "eixo_y", "eixo_y2")) est[[ax]][c("titulo", "inicio", "fim", "ticks_manuais",
                                                           "rotulos_manuais")] <- NULL
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

# Entra: nome do estilo e cfg. Sai: o cfg com o estilo aplicado por cima.
carregar_estilo <- function(nome, cfg = get("cfg", envir = globalenv()), pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  arq <- if (file.exists(nome)) nome else file.path(pasta, paste0(nome, ".R"))
  if (!file.exists(arq)) {
    disp <- sub("\\.R$", "", list.files(pasta, pattern = "\\.R$"))
    .erro("Estilo '", nome, "' não encontrado. Disponíveis: ", paste(disp, collapse = ", "))
  }
  est <- eval(parse(arq, encoding = "UTF-8"))
  .mesclar(cfg, est)
}

# Nomes dos estilos disponíveis na pasta de estilos.
listar_estilos <- function(pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  sub("\\.R$", "", list.files(pasta, pattern = "\\.R$"))
}

# Recarrega o 01_config.R e substitui o cfg do console pelo padrão.
resetar_cfg <- function() {
  e <- new.env(); sys.source(file.path(.motor_pasta, "01_config.R"), envir = e)
  assign("cfg", e$cfg, envir = globalenv())
  message("cfg voltou ao padrão de 01_config.R")
  invisible(e$cfg)
}

# Imprime os nomes de fonte instalados (pelo systemfonts) para usar em cfg$texto$fonte.
listar_fontes <- function() {
  if (!.tem("systemfonts")) {
    message("Instale 'systemfonts' (vem com ragg) para listar as fontes.")
    return(invisible())
  }
  f <- sort(unique(.familias_fontes()))
  print(f)
  invisible(f)
}

# Famílias que o R enxerga: as instaladas no sistema e as registradas por registrar_fonte().
.familias_fontes <- function() {
  c(systemfonts::system_fonts()$family, systemfonts::registry_fonts()$family)
}

# Usa uma fonte que está num arquivo .ttf/.otf, SEM instalá-la no Windows (vale só nesta sessão do R).
# Serve quando a fonte instalada não aparece em listar_fontes().
# Entra: nome (como vai em cfg$texto$fonte) e pasta (com os arquivos, ex.: "Barlow-Regular.ttf",
#   "Barlow-Bold.ttf", "Barlow-Italic.ttf", "Barlow-BoldItalic.ttf") ou arquivos (vetor com nomes
#   regular, bold, italic, bolditalic). Só o regular é obrigatório. Sai (invisível): o nome registrado.
registrar_fonte <- function(nome, pasta = NULL, arquivos = NULL) {
  if (!.tem("systemfonts")) .erro("registrar_fonte() precisa do pacote systemfonts (vem com ragg).")
  if (!is.character(nome) || length(nome) != 1 || !nzchar(nome)) .erro("registrar_fonte(nome): informe o nome da fonte, ex.: \"Barlow\".")
  if (is.null(arquivos)) {
    if (is.null(pasta) || !dir.exists(pasta)) .erro("registrar_fonte: a pasta '", pasta %||% "", "' não existe. ",
                                                    "Use o caminho da pasta com os .ttf, ex.: \"C:/Users/voce/Downloads/Barlow\".")
    todos <- list.files(pasta, pattern = "\\.(ttf|otf)$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
    base <- gsub("[ _]", "", nome)
    estilo <- sub("\\.(ttf|otf)$", "", basename(todos), ignore.case = TRUE)
    ok <- grepl(paste0("^", base, "-"), estilo, ignore.case = TRUE)   # "Barlow-Bold" sim; "BarlowCondensed-Bold" não
    estilo <- tolower(sub("^[^-]*-", "", estilo[ok])); todos <- todos[ok]
    achar <- function(e) { i <- which(estilo == e); if (length(i)) todos[i[1]] else NA_character_ }
    arquivos <- c(regular = achar("regular"), bold = achar("bold"), italic = achar("italic"),
                  bolditalic = achar("bolditalic"))
  }
  arquivos <- unlist(arquivos)
  if (is.null(names(arquivos))) names(arquivos) <- c("regular", "bold", "italic", "bolditalic")[seq_along(arquivos)]
  reg <- arquivos[["regular"]]
  if (is.null(reg) || is.na(reg) || !file.exists(reg))
    .erro("registrar_fonte: não achei o arquivo \"", nome, "-Regular.ttf\" em '", pasta %||% "", "'.\n",
          "  Arquivos .ttf/.otf encontrados lá: ",
          paste(utils::head(basename(list.files(pasta %||% ".", pattern = "\\.(ttf|otf)$", recursive = TRUE, ignore.case = TRUE)), 8),
                collapse = ", "),
          "\n  Use os arquivos estáticos (Barlow-Regular.ttf...), não o arquivo de fonte variável (com colchetes no nome).")
  pega <- function(k) { v <- arquivos[k]; if (length(v) && !is.na(v) && file.exists(v)) unname(v) else reg }
  bo <- pega("bold"); it <- pega("italic")
  bi <- { v <- arquivos["bolditalic"]; if (length(v) && !is.na(v) && file.exists(v)) unname(v) else bo }
  systemfonts::register_font(name = nome, plain = reg, bold = bo, italic = it, bolditalic = bi)
  .fontes_cache[[nome]] <- NULL                       # esquece um "não encontrada" anterior
  message("Fonte '", nome, "' registrada (", sum(!is.na(arquivos) & file.exists(arquivos)), " arquivo(s)). ",
          "Use cfg$texto$fonte <- \"", nome, "\".")
  invisible(nome)
}
