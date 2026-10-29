# Gráficos de exemplo do manual (feitos pelo próprio motor, com os CSVs da pasta dados/).
# uso (na pasta graficos_R):  Rscript ferramentas/manual/galeria.R
suppressMessages({ source("01_config.R", encoding = "UTF-8"); source("02_motor.R", encoding = "UTF-8") })
saida <- file.path("manual", "img"); dir.create(saida, showWarnings = FALSE, recursive = TRUE)
base <- cfg
novo <- function(nome, larg = 12, alt = 8.2) { c <- base; c$exportacao$pasta <- saida; c$exportacao$nome_arquivo <- nome; c$exportacao$formatos <- "png"
  c$exportacao$largura <- larg; c$exportacao$altura <- alt; c$exportacao$dpi <- 220; c }
lê <- function(a) suppressMessages(ler_csv(file.path("dados", a)))
gerar <- function(cfg_, dados) { g <- suppressWarnings(plotar(dados, cfg_)); suppressMessages(suppressWarnings(salvar(g, cfg_))) }
eixos <- function(c, x, y) { c$eixo_x$titulo <- x; c$eixo_y$titulo <- y; c }

d <- lê("ensaio_temperatura.csv")
c <- eixos(novo("g01_linha_pontos"), "Tempo (min)", "Temperatura (°C)"); c$grafico$tipo <- "linha_pontos"; c$grafico$colunas_y <- c("Amostra A", "Amostra B", "Amostra C")
c$legenda$posicao <- "dentro"; c$legenda$dentro_x <- 0.04; c$legenda$dentro_y <- 0.96; c$legenda$ancora <- c(0, 1); gerar(c, d)

d <- lê("calibracao_excel_ptbr.csv")
c <- eixos(novo("g02_pontos_ajuste"), "Concentração (mg/L)", "Absorbância"); c$grafico$tipo <- "pontos"
c$ajustes <- list(list(tipo = "linear")); c$caixas_estatisticas <- list(list(itens = c("equacao", "r2")))
c$legenda$posicao <- "topo"; gerar(c, d)

d <- lê("serie_temporal.csv")
c <- eixos(novo("g03_data_y2"), "Data", "Temperatura (°C)"); c$grafico$tipo <- "linha_pontos"
c$eixo_y2$ativo <- TRUE; c$eixo_y2$titulo <- "Umidade (%)"; c$series[["Umidade (%)"]] <- list(eixo = "y2", cor = "#2F6670")
c$legenda$posicao <- "topo"; gerar(c, d)

d <- lê("resposta_frequencia.csv")
c <- eixos(novo("g04_escala_log"), "Frequência (Hz)", "Amplitude"); c$grafico$tipo <- "linha"; c$grafico$colunas_y <- "Amplitude"
c$eixo_x$escala <- "log10"; c$eixo_x$n_menores <- 8; c$eixo_x$notacao <- "potencia10"; c$legenda$mostrar <- FALSE; gerar(c, d)

d <- lê("ensaio_temperatura.csv")
c <- eixos(novo("g05_area_empilhada"), "Tempo (min)", "Total (°C)"); c$grafico$tipo <- "area_empilhada"; c$grafico$colunas_y <- c("Amostra A", "Amostra B", "Amostra C"); gerar(c, d)

d <- lê("resistencia_materiais.csv")
c <- eixos(novo("g06_barras"), "Material", "Resistência (MPa)"); c$grafico$tipo <- "barras"; c$grafico$colunas_y <- c("Ensaio 1", "Ensaio 2", "Ensaio 3")
c$series[["Ensaio 1"]] <- list(coluna_erro = "Erro 1"); gerar(c, d)

d <- lê("composicao_liga.csv")
c <- novo("g07_pizza", 10, 8.2); c$grafico$tipo <- "pizza"; c$pizza$angulo_inicial <- 160; gerar(c, d)

d <- lê("replicatas.csv")
c <- eixos(novo("g08_histograma"), "Concentração (mg/L)", "Frequência"); c$grafico$tipo <- "histograma"; c$grafico$colunas_y <- c("Controle", "Dose 2"); gerar(c, d)
c <- eixos(novo("g09_boxplot"), "Grupo", "Concentração (mg/L)"); c$grafico$tipo <- "boxplot"; c$legenda$mostrar <- FALSE; gerar(c, d)
c <- eixos(novo("g10_violino"), "Grupo", "Concentração (mg/L)"); c$grafico$tipo <- "boxplot"; c$boxplot$variacao <- "violino_box"; c$legenda$mostrar <- FALSE; gerar(c, d)

d <- lê("media_e_desvio.csv")
c <- eixos(novo("g11_media_desvio"), "Tempo (h)", "Concentração (mg/L)"); c$grafico$tipo <- "linha_pontos"
c$series[["Média (mg/L)"]] <- list(coluna_erro = "Desvio padrão"); c$legenda$mostrar <- FALSE; gerar(c, d)
c$linhas$erro_cor <- "#20242B"; c$grafico$tipo <- "pontos"; c$exportacao$nome_arquivo <- "g11b_erro_cor_propria"; gerar(c, d)

d <- lê("exemplo_dois_eixos_e_quebra.csv")
c <- novo("g12_quebra", 13, 9); c <- eixos(c, "Ano", "Resíduos (t)"); c$grafico$tipo <- "linha_pontos"; c$grafico$colunas_y <- c("Mundo (RSP)", "America Latina (RSP)", "Brasil (RSP)")
c$quebra$ativo <- TRUE; c$quebra$estilo <- "continuo"; c$quebra$de <- 90000; c$quebra$ate <- 440000; c$legenda$posicao <- "base"; gerar(c, d)

# paletas: as 12 que o Cinabro oferece
pal <- unlist(.PALETAS_GRUPOS); nomes <- unname(pal)
png(file.path(saida, "g13_paletas.png"), width = 1500, height = 80 * length(nomes) + 40, res = 160)
par(mar = c(1, 11, 1, 1), family = "sans"); plot.new(); plot.window(xlim = c(0, 1), ylim = c(length(nomes) + 0.5, 0.5))
for (i in seq_along(nomes)) { cores <- tryCatch(.paleta(nomes[i], 10, base$cores), error = function(e) NULL); if (is.null(cores)) next
  rect(seq(0, 0.9, length.out = 10), i - 0.38, seq(0.1, 1, length.out = 10), i + 0.38, col = cores, border = "white", lwd = 2)
  mtext(nomes[i], side = 2, at = i, las = 1, line = 0.5, cex = 0.8) }
dev.off()
cat("galeria pronta em", saida, "\n")

# ---- mapa de calor, ordenações e mapas
ordenacao <- function(nome, tipo) {
  d <- lê("ordenacao_amostras_variaveis_ambientais.csv")
  c <- novo(nome); c$grafico$tipo <- tipo; c$grafico$coluna_x <- 1; c$grafico$coluna_grupo <- "Local"
  c$multivariada$variaveis <- c("Aquila", "Boreus", "Caelum", "Draco", "Eridanus", "Fornax", "Grus", "Hydra"); c$multivariada$ambientais <- c("pH", "Temperatura", "Salinidade")
  c$multivariada$elipses <- "dados"; if (tipo == "pca") c$multivariada$transformacao <- "padronizar"
  gerar(c, d)
}
ordenacao("g14_pca", "pca"); ordenacao("g15_cca", "cca")
d <- lê("mapa_de_calor.csv"); c <- novo("g16_mapa_calor"); c$grafico$tipo <- "mapa_calor"; c$mapa_calor$valores_nas_celulas <- TRUE; c$mapa_calor$agrupar <- "ambos"; c$mapa_calor$titulo_barra <- "Expressão"; gerar(c, d)
d <- lê("mapa_mundo_vendas.csv"); c <- novo("g17_mapa_mundo", 12, 7); c$grafico$tipo <- "mapa_mundo"; c$mapa$nivel <- "regiao"; c$mapa$rotulos <- "nome_valor"; c$mapa_calor$titulo_barra <- "Vendas"; gerar(c, d)
d <- lê("mapa_brasil_estados.csv"); c <- novo("g18_mapa_brasil", 12, 8.2); c$grafico$tipo <- "mapa_brasil"; c$mapa$rotulos <- "nome_valor"; c$mapa_calor$titulo_barra <- "Resíduos (t)"; gerar(c, d)
