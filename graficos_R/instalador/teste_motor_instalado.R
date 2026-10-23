# Teste de fumaça da cópia INSTALADA: carrega o motor, desenha um gráfico com a Barlow e salva PNG, PDF e SVG.
# uso: Rscript teste_motor_instalado.R <pasta graficos_R instalada> <pasta de saída>
args <- commandArgs(TRUE); setwd(args[1]); saida <- args[2]; dir.create(saida, showWarnings = FALSE, recursive = TRUE)
cat("R", as.character(getRversion()), "| .libPaths:\n"); print(.libPaths())
source("01_config.R", encoding = "UTF-8"); suppressMessages(source("02_motor.R", encoding = "UTF-8"))
dados <- ler_csv("dados/ensaio_temperatura.csv")
cfg$grafico$tipo <- "linha_pontos"; cfg$eixo_x$titulo <- "Tempo (min)"; cfg$eixo_y$titulo <- "Temperatura (°C)"
cfg$exportacao$pasta <- saida; cfg$exportacao$nome_arquivo <- "fumaca"; cfg$exportacao$formatos <- c("png", "pdf", "svg")
g <- plotar(dados, cfg); salvar(g, cfg)
arq <- file.path(saida, c("fumaca.png", "fumaca.pdf", "fumaca.svg"))
tam <- file.size(arq); print(setNames(tam, basename(arq)))
fam <- unique(systemfonts::registry_fonts()$family); cat("Barlow registrada:", "Barlow" %in% fam, "\n")
if (any(is.na(tam)) || any(tam < 2000)) stop("Algum arquivo não foi gerado direito.")
cat("MOTOR_OK\n")
