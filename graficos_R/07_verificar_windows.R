# =============================================================================
#  07_verificar_windows.R — CONFERÊNCIA RÁPIDA DE FONTES E EXPORTAÇÃO NO SEU COMPUTADOR
# =============================================================================
#  Este template foi desenvolvido e testado em Linux. Rode este arquivo no Windows
#  (Ctrl+Shift+S, com o projeto aberto pelo graficos_R.Rproj) para conferir o que
#  só o seu computador pode mostrar: fontes Arial e Times New Roman, PDF, PNG,
#  gradiente e a prévia do RStudio. Leva menos de 1 minuto.
#
#  Ao final aparece uma tabela OK / ATENÇÃO. Os arquivos gerados ficam em
#  saida/verificacao/ — ABRA os 3 arquivos e confira com os olhos (passo 2 abaixo).
# =============================================================================

source("01_config.R", encoding = "UTF-8")
source("02_motor.R",  encoding = "UTF-8")

resultado <- data.frame(item = character(), situacao = character(), detalhe = character())
registrar <- function(item, ok, detalhe = "") {
  resultado[nrow(resultado) + 1, ] <<- list(item, if (ok) "OK" else "ATENÇÃO", detalhe)
}

# ---- 1. Pacotes e versões -------------------------------------------------------
registrar("R >= 4.2", getRversion() >= "4.2.0", as.character(getRversion()))
registrar("ggplot2 >= 3.5.0", packageVersion("ggplot2") >= "3.5.0", as.character(packageVersion("ggplot2")))
registrar("ragg >= 1.5.0 (gradiente radial correto)",
          requireNamespace("ragg", quietly = TRUE) && packageVersion("ragg") >= "1.5.0",
          if (requireNamespace("ragg", quietly = TRUE)) as.character(packageVersion("ragg")) else "não instalado")
registrar("Cairo disponível (PDF com fontes embutidas)", isTRUE(capabilities("cairo")))

# ---- 2. Fontes: o nome tem de existir no sistema -----------------------------------
fontes <- if (requireNamespace("systemfonts",
                               quietly = TRUE)) unique(systemfonts::system_fonts()$family) else character(0)
for (f in c("Arial", "Times New Roman")) {
  registrar(paste0("Fonte '", f, "' encontrada"), tolower(f) %in% tolower(fontes),
            if (length(fontes)) "systemfonts" else "instale systemfonts para checar")
}

# ---- 3. Gera 3 arquivos com Arial e Times New Roman, PNG e PDF, com gradiente -------
dir.create("saida/verificacao", showWarnings = FALSE, recursive = TRUE)
dados <- ler_csv("dados/ensaio_temperatura.csv", list(relatorio = FALSE))
fazer <- function(fonte, nome) {
  cfg$dados$relatorio <- FALSE
  cfg$grafico$tipo <- "barras"; cfg$grafico$coluna_x <- 1
  cfg$grafico$colunas_y <- c("Amostra A", "Amostra B")
  dados <- dados[1:6, ]; dados[[1]] <- as.character(dados[[1]])
  cfg$cores$preenchimento <- "gradiente"; cfg$cores$gradiente_direcao <- "vertical"
  cfg$texto$fonte <- fonte; cfg$titulos$titulo <- paste("Fonte:", fonte, " — acentuação: ção ã é ü Ω µ")
  cfg$exportacao$pasta <- "saida/verificacao"; cfg$exportacao$nome_arquivo <- nome
  cfg$exportacao$formatos <- c("png", "pdf"); cfg$exportacao$dpi <- 150
  cfg$exportacao$sobrescrever <- TRUE
  salvar(plotar(dados, cfg), cfg)
}
for (par in list(c("Arial", "arial"), c("Times New Roman", "times"))) {
  r <- tryCatch({ fazer(par[1], par[2]); TRUE },
                error = function(e) { message("   erro: ", conditionMessage(e)); FALSE })
  registrar(paste0("Gerou PNG e PDF com ", par[1]), r)
}

# ---- 4. Resultado ----------------------------------------------------------------------
cat("\n==== RESULTADO ====\n"); print(resultado, row.names = FALSE)
cat("\nAgora confira com os olhos (passo 2):\n",
    " a) Abra saida/verificacao/arial.pdf e times.pdf: a fonte do título deve ser Arial / Times,\n",
    "    com acentos e símbolos (ção, ã, é, ü, Ω, µ) corretos, e as barras com degradê.\n",
    " b) Abra os PNG: devem ser iguais aos PDF.\n",
    " c) Rode  g <- plotar(dados, cfg); visualizar(g)  e compare com o PNG: o Viewer do RStudio\n",
    "    deve mostrar a mesma fonte e o degradê.\n",
    " d) Se aba Plots (não o Viewer) mostrar degradê errado: Tools > Global Options > General >\n",
    "    Graphics > Backend = AGG.\n", sep = "")
if (any(resultado$situacao == "ATENÇÃO"))
  cat("\nHá itens em ATENÇÃO. Fonte não encontrada = o template usa a fonte 'sans' no lugar (com aviso).\n",
      "Use listar_fontes() para ver os nomes exatos instalados e ajuste cfg$texto$fonte.\n", sep = "")
