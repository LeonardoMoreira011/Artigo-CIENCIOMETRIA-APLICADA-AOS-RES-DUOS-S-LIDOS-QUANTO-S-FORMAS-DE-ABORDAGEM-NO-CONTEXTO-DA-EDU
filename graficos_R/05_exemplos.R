# =============================================================================
#  05_exemplos.R — UM EXEMPLO DE CADA TIPO / RECURSO
# =============================================================================
#  Rode tudo (Ctrl+Shift+S) para gerar a pasta saida/exemplos/ com ~30 figuras.
#  Cada bloco é independente: copie para o 03_executar.R o que quiser reaproveitar.
#  Antes de cada exemplo, novo_cfg() volta tudo ao padrão do 01_config.R.
# =============================================================================

source("01_config.R", encoding = "UTF-8")
source("02_motor.R", encoding = "UTF-8")

novo_cfg <- function(nome) {
  source("01_config.R", encoding = "UTF-8", local = TRUE)
  cfg$dados$relatorio <- FALSE
  cfg$exportacao$pasta <- "saida/exemplos"
  cfg$exportacao$formatos <- "png"
  cfg$exportacao$dpi <- 200
  cfg$exportacao$nome_arquivo <- nome
  cfg
}
gerar <- function(dados, cfg) { g <- plotar(dados, cfg); salvar(g, cfg); invisible(g) }

temp  <- ler_csv("dados/ensaio_temperatura.csv")
calib <- ler_csv("dados/calibracao_excel_ptbr.csv")
mat   <- ler_csv("dados/resistencia_materiais.csv")
liga  <- ler_csv("dados/composicao_liga.csv")
rep_  <- ler_csv("dados/replicatas.csv")
repL  <- ler_csv("dados/replicatas_formato_longo.csv")
multi <- ler_csv("dados/multissinal.csv")
freq  <- ler_csv("dados/resposta_frequencia.csv")

# --- 01 Linha + pontos, caixa fechada, ticks para dentro (padrão) -----------
cfg <- novo_cfg("01_linha_pontos_padrao")
cfg$grafico$colunas_y <- c("Amostra A", "Amostra B", "Amostra C")
cfg$eixo_y$titulo <- "Temperatura (°C)"
gerar(temp, cfg)

# --- 02 Eixos definidos à mão + barras de erro + legenda com moldura --------
cfg <- novo_cfg("02_eixos_manuais_erros")
cfg$grafico$colunas_y <- c("Amostra A", "Amostra B")
cfg$series[["Amostra A"]] <- list(coluna_erro = "Desvio A", nome_legenda = "Amostra A (± DP)")
cfg$series[["Amostra B"]] <- list(coluna_erro = "Desvio B", simbolo = 22, preenchimento_simbolo = "branco")
cfg$eixo_x$inicio <- 0; cfg$eixo_x$fim <- 60
cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 10; cfg$eixo_x$n_menores <- 1
cfg$eixo_y$inicio <- 10; cfg$eixo_y$fim <- 90
cfg$eixo_y$ticks_modo <- "incremento"; cfg$eixo_y$incremento <- 20; cfg$eixo_y$n_menores <- 3
cfg$eixo_y$titulo <- "Temperatura (°C)"
cfg$legenda$moldura <- TRUE; cfg$legenda$fundo <- "white"
cfg$legenda$dentro_x <- 0.96; cfg$legenda$dentro_y <- 0.06
gerar(temp, cfg)

# --- 03 Ticks para fora, sem caixa (estilo "eixos abertos"), grade -----------
cfg <- novo_cfg("03_eixos_abertos_grade")
cfg$grafico$colunas_y <- c("Amostra A", "Amostra B", "Amostra C")
cfg$caixa$fechada <- FALSE
for (ax in c("eixo_x", "eixo_y")) { cfg[[ax]]$direcao_maiores <- "fora"; cfg[[ax]]$direcao_menores <- "fora" }
cfg$grade$maior_y <- TRUE; cfg$grade$menor_y <- TRUE
cfg$grafico$tipo <- "linha"
cfg$linhas$ligacao <- "spline"
cfg$cores$paleta <- "okabe_ito"
cfg$serie_padrao$linha_espessura_pt <- 2
cfg$legenda$posicao <- "direita"
gerar(temp, cfg)

# --- 04 Ticks cruzando o eixo ("ambos"), rótulos espelhados ----------------
cfg <- novo_cfg("04_ticks_ambos_espelhados")
cfg$grafico$tipo <- "pontos"
for (ax in c("eixo_x", "eixo_y")) { cfg[[ax]]$direcao_maiores <- "ambos"; cfg[[ax]]$n_menores <- 4 }
cfg$caixa$rotulos_espelhados <- TRUE
cfg$caixa$espessura_pt <- 1.5
cfg$texto$fonte <- "serif"
cfg$legenda$mostrar <- FALSE
gerar(calib, cfg)

# --- 05 CSV do Excel (; e vírgula) + título com sobrescrito/subscrito --------
cfg <- novo_cfg("05_csv_excel_ptbr_formatacao")
cfg$grafico$tipo <- "linha_pontos"
cfg$eixo_x$titulo <- "C_{Fe} (mg L^{-1})"
cfg$eixo_y$titulo <- "Absorbância (u.a.)"
cfg$eixo_y$casas_decimais <- 1
cfg$referencias <- list(list(eixo = "y", valor = 1, cor = "red", rotulo = "limite superior"))
cfg$anotacoes$textos <- list(list(x = 10.5, y = 0.35, texto = "R^{2} = 0.999", alinhamento = "esquerda"))
gerar(calib, cfg)

# --- 06 Escala log10 nos dois eixos, ticks menores 2..9, notação 10^n -------
cfg <- novo_cfg("06_log_log")
cfg$grafico$tipo <- "linha"
cfg$grafico$colunas_y <- "Impedância"
for (ax in c("eixo_x", "eixo_y")) { cfg[[ax]]$escala <- "log10"; cfg[[ax]]$n_menores <- 8; cfg[[ax]]$notacao <- "potencia10" }
cfg$eixo_y$titulo <- "|Z| (Ω)"
gerar(freq, cfg)

# --- 07 Eixo Y secundário independente ---------------------------------------
cfg <- novo_cfg("07_eixo_y2")
cfg$grafico$colunas_y <- c("Amplitude", "Impedância")
cfg$grafico$tipo <- "linha_pontos"
cfg$eixo_x$escala <- "log10"; cfg$eixo_x$n_menores <- 8; cfg$eixo_x$notacao <- "potencia10"
cfg$eixo_y$titulo <- "Amplitude (V/V)"; cfg$eixo_y$inicio <- 0; cfg$eixo_y$fim <- 1.2
cfg$eixo_y2$ativo <- TRUE
cfg$eixo_y2$titulo <- "Impedância (Ω)"
cfg$eixo_y2$inicio <- 0; cfg$eixo_y2$fim <- 120000; cfg$eixo_y2$incremento <- 20000; cfg$eixo_y2$ticks_modo <- "incremento"
cfg$eixo_y2$notacao <- "normal"
cfg$series[["Impedância"]] <- list(eixo = "y2", cor = "#D62728")
cfg$series[["Amplitude"]] <- list(cor = "#1F4E9E")
cfg$legenda$posicao <- "topo"
gerar(freq, cfg)

# --- 08 Área preenchida com gradiente ---------------------------------------
cfg <- novo_cfg("08_area_gradiente")
cfg$grafico$tipo <- "area"
cfg$grafico$colunas_y <- "Amostra A"
cfg$series[["Amostra A"]] <- list(cor = "#1F4E9E")
cfg$cores$preenchimento <- "gradiente"
cfg$cores$gradiente_cor2 <- "white"
cfg$linhas$opacidade_area <- 0.9
cfg$eixo_y$inicio <- 0
gerar(temp, cfg)

# --- 09 Áreas empilhadas ---------------------------------------------------------
cfg <- novo_cfg("09_area_empilhada")
cfg$grafico$tipo <- "area_empilhada"
cfg$grafico$colunas_y <- c("Amostra A", "Amostra B", "Amostra C")
cfg$cores$paleta <- "viridis"
cfg$serie_padrao$opacidade_preenchimento <- 0.85
cfg$eixo_y$titulo <- "Soma acumulada"
gerar(temp, cfg)

# --- 10 Barras agrupadas sólidas com erro e rótulos ---------------------------
cfg <- novo_cfg("10_barras_agrupadas")
cfg$grafico$tipo <- "barras"
cfg$grafico$colunas_y <- c("Ensaio 1", "Ensaio 2", "Ensaio 3")
cfg$series[["Ensaio 1"]] <- list(coluna_erro = "Erro 1")
cfg$cores$paleta <- "tableau"
cfg$eixo_y$titulo <- "Resistência (MPa)"
cfg$eixo_y$inicio <- 0; cfg$eixo_y$fim <- 1000
cfg$eixo_y$ticks_modo <- "incremento"; cfg$eixo_y$incremento <- 200
cfg$eixo_x$titulo <- ""
cfg$legenda$posicao <- "topo"
gerar(mat, cfg)

# --- 11 Barras com GRADIENTE de duas cores ------------------------------------
cfg <- novo_cfg("11_barras_gradiente")
cfg$grafico$tipo <- "barras"
cfg$grafico$colunas_y <- c("Ensaio 1", "Ensaio 2")
cfg$cores$preenchimento <- "gradiente"
cfg$series[["Ensaio 1"]] <- list(cor = "#1F4E9E", cor2 = "#BBD7F5")
cfg$series[["Ensaio 2"]] <- list(cor = "#B2182B", cor2 = "#FFD8A8")
cfg$barras$largura <- 0.7; cfg$barras$sobreposicao <- 0.2
cfg$barras$rotulos_valor <- TRUE; cfg$barras$rotulos_casas <- 0
cfg$eixo_y$inicio <- 0; cfg$eixo_y$titulo <- "Resistência (MPa)"; cfg$eixo_x$titulo <- ""
gerar(mat, cfg)

# --- 12 Barras horizontais empilhadas 100% -----------------------------------
cfg <- novo_cfg("12_barras_horizontais_100")
cfg$grafico$tipo <- "barras"
cfg$grafico$colunas_y <- c("Ensaio 1", "Ensaio 2", "Ensaio 3")
cfg$barras$orientacao <- "horizontal"
cfg$barras$arranjo <- "empilhado_100"
cfg$barras$rotulos_valor <- TRUE; cfg$barras$rotulos_posicao <- "centro"; cfg$barras$rotulos_cor <- "white"
cfg$barras$rotulos_casas <- 0
cfg$cores$paleta <- "okabe_ito"
cfg$eixo_y$ticks_modo <- "incremento"; cfg$eixo_y$incremento <- 25; cfg$eixo_y$sufixo <- "%"
cfg$eixo_x$titulo <- ""
cfg$legenda$posicao <- "base"
cfg$exportacao$altura <- 8
gerar(mat, cfg)

# --- 13 Pizza com fatia destacada -----------------------------------------
cfg <- novo_cfg("13_pizza")
cfg$grafico$tipo <- "pizza"
cfg$pizza$explodir <- "Cromo"
cfg$pizza$agrupar_abaixo <- 1
cfg$cores$paleta <- "tableau"
cfg$exportacao$largura <- 14; cfg$exportacao$altura <- 11
gerar(liga, cfg)

# --- 14 Rosca com gradiente radial e legenda -----------------------------
cfg <- novo_cfg("14_rosca_gradiente")
cfg$grafico$tipo <- "pizza"
cfg$pizza$raio_furo <- 0.55
cfg$pizza$rotulos <- "percentual"
cfg$pizza$rotulos_posicao <- "fora"
cfg$pizza$ocultar_rotulo_abaixo <- 1
cfg$cores$paleta <- "brewer_Set2"
cfg$cores$preenchimento <- "gradiente"; cfg$cores$gradiente_direcao <- "radial"; cfg$cores$gradiente_cor2 <- "white"
cfg$legenda$posicao <- "direita"
cfg$titulos$titulo <- "Composição da liga (% massa)"
cfg$exportacao$largura <- 15; cfg$exportacao$altura <- 10
gerar(liga, cfg)

# --- 15 Histograma com curva normal ---------------------------------------
cfg <- novo_cfg("15_histograma_normal")
cfg$grafico$tipo <- "histograma"
cfg$grafico$colunas_y <- "Controle"
cfg$distribuicao$largura_classe <- 2.5
cfg$distribuicao$curva_normal <- TRUE
cfg$distribuicao$curva_densidade <- TRUE
cfg$distribuicao$marcas_rug <- TRUE
cfg$series[["Controle"]] <- list(cor = "#4E79A7")
cfg$legenda$mostrar <- FALSE
gerar(rep_, cfg)

# --- 16 Histogramas sobrepostos em percentual -----------------------------
cfg <- novo_cfg("16_histogramas_sobrepostos")
cfg$grafico$tipo <- "histograma"
cfg$grafico$colunas_y <- c("Controle", "Dose 2")
cfg$distribuicao$largura_classe <- 5
cfg$distribuicao$medida <- "percentual"
cfg$cores$paleta <- "okabe_ito"
gerar(rep_, cfg)

# --- 17 Densidade e ECDF ------------------------------------------------------
cfg <- novo_cfg("17_densidade")
cfg$grafico$tipo <- "densidade"
cfg$cores$paleta <- "viridis"
gerar(rep_, cfg)
cfg <- novo_cfg("18_ecdf")
cfg$grafico$tipo <- "ecdf"
cfg$cores$paleta <- "brewer_Dark2"
cfg$eixo_y$casas_decimais <- 1
gerar(rep_, cfg)

# --- 19 Boxplot padrão (Tukey, média, outliers) ------------------------------
cfg <- novo_cfg("19_boxplot")
cfg$grafico$tipo <- "boxplot"
cfg$cores$paleta <- "tableau"
cfg$serie_padrao$opacidade_preenchimento <- 0.8
cfg$eixo_y$titulo <- "Resposta (u.a.)"
gerar(rep_, cfg)

# --- 20 Box + pontos (enxame), bigodes 5–95%, entalhe -----------------------
cfg <- novo_cfg("20_box_pontos_entalhe")
cfg$grafico$tipo <- "boxplot"
cfg$boxplot$variacao <- "box_pontos"
cfg$boxplot$bigode <- "percentis"; cfg$boxplot$bigode_percentis <- c(5, 95)
cfg$boxplot$entalhe <- TRUE
cfg$boxplot$mostrar_n <- TRUE
cfg$cores$paleta <- "okabe_ito"; cfg$serie_padrao$opacidade_preenchimento <- 0.35
gerar(rep_, cfg)

# --- 21 Meio box + dados ao lado ---------------------------------------------
cfg <- novo_cfg("21_meio_box")
cfg$grafico$tipo <- "boxplot"
cfg$boxplot$variacao <- "meio_box"
cfg$boxplot$largura <- 0.7
cfg$cores$paleta <- "brewer_Set1"
gerar(rep_, cfg)

# --- 22 Violino + box, gradiente --------------------------------------------
cfg <- novo_cfg("22_violino_box_gradiente")
cfg$grafico$tipo <- "boxplot"
cfg$boxplot$variacao <- "violino_box"
cfg$cores$preenchimento <- "gradiente"; cfg$cores$gradiente_cor2 <- "white"
cfg$cores$paleta <- "brewer_Set2"
gerar(rep_, cfg)

# --- 23 Média ± erro padrão (barras), formato longo (coluna de grupo) -------
cfg <- novo_cfg("23_media_erro_formato_longo")
cfg$grafico$tipo <- "boxplot"
cfg$grafico$coluna_grupo <- "Tratamento"
cfg$boxplot$variacao <- "media_erro"
cfg$boxplot$media_erro_tipo <- "erro_padrao"
cfg$boxplot$media <- FALSE
cfg$cores$paleta <- "cinza"
cfg$eixo_y$inicio <- 0
gerar(repL, cfg)

# --- 24 Boxplot horizontal ------------------------------------------------------
cfg <- novo_cfg("24_boxplot_horizontal")
cfg$grafico$tipo <- "boxplot"
cfg$boxplot$orientacao <- "horizontal"
cfg$boxplot$variacao <- "box_pontos"; cfg$boxplot$pontos_disposicao <- "jitter"
cfg$cores$paleta <- "tableau"
gerar(rep_, cfg)

# --- 25 PAINÉIS empilhados com X comum (3 painéis) ---------------------------
cfg <- novo_cfg("25_paineis_x_comum")
cfg$paineis$ativo <- TRUE
cfg$paineis$lista <- list(
  list(grafico = list(colunas_y = "Tensão (V)", tipo = "linha"),
       series = list("Tensão (V)" = list(cor = "#1F4E9E")),
       eixo_y = list(inicio = -2, fim = 2, ticks_modo = "incremento", incremento = 1),
       referencias = list(list(eixo = "y", valor = 0, cor = "grey50", tipo = "dotted"))),
  list(grafico = list(colunas_y = "Corrente (mA)", tipo = "pontos"),
       serie_padrao = list(tamanho_simbolo_pt = 3),
       series = list("Corrente (mA)" = list(cor = "#D62728"))),
  list(grafico = list(colunas_y = "Temperatura (°C)", tipo = "area"),
       series = list("Temperatura (°C)" = list(cor = "#2CA02C")),
       eixo_y = list(inicio = 20))
)
cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 2
cfg$legenda$mostrar <- FALSE
cfg$exportacao$altura <- 14
gerar(multi, cfg)

# --- 26 Painéis com lados alternados, título único e espaço -----------------
cfg <- novo_cfg("26_paineis_alternados")
cfg$paineis$ativo <- TRUE
cfg$paineis$alternar_lado <- TRUE
cfg$paineis$espaco_pt <- 6
cfg$paineis$titulo_unico <- "Sinais medidos"
cfg$paineis$tamanhos <- c(2, 1, 1)
cfg$paineis$lista <- list(
  list(grafico = list(colunas_y = c("Tensão (V)"), tipo = "linha")),
  list(grafico = list(colunas_y = "Pressão (kPa)", tipo = "linha"), series = list("Pressão (kPa)" = list(cor = "#8E44AD"))),
  list(grafico = list(colunas_y = "Corrente (mA)", tipo = "linha"), series = list("Corrente (mA)" = list(cor = "#FF7F0E")))
)
cfg$paineis$legenda_unica <- TRUE
cfg$legenda$posicao <- "topo"
cfg$exportacao$altura <- 14
gerar(multi, cfg)

# --- 27 Quebra de eixo Y -----------------------------------------------------------
cfg <- novo_cfg("27_quebra_eixo")
cfg$grafico$tipo <- "barras"
cfg$grafico$colunas_y <- "Ensaio 1"
cfg$series[["Ensaio 1"]] <- list(cor = "#4E79A7")
cfg$quebra$ativo <- TRUE; cfg$quebra$de <- 450; cfg$quebra$ate <- 800
cfg$eixo_y$inicio <- 0; cfg$eixo_y$fim <- 1000
cfg$eixo_y$titulo <- "Resistência (MPa)"; cfg$eixo_x$titulo <- ""
cfg$legenda$mostrar <- FALSE
gerar(mat, cfg)

# --- 28 Mapa de cor nos pontos ---------------------------------------------------
cfg <- novo_cfg("28_mapa_de_cor")
cfg$grafico$tipo <- "pontos"
cfg$grafico$coluna_x <- "Tempo (s)"
cfg$grafico$colunas_y <- "Corrente (mA)"
cfg$cores$mapear_coluna <- "Temperatura (°C)"
cfg$cores$mapa_cores <- c("#2166AC", "#F7F7F7", "#B2182B")
cfg$legenda$posicao <- "direita"
cfg$serie_padrao$tamanho_simbolo_pt <- 4
gerar(multi, cfg)

# --- 29 Estilo salvo: publicação clássica ----------------------------------------
cfg <- novo_cfg("29_estilo_publicacao")
cfg <- carregar_estilo("publicacao_classico", cfg)
cfg$exportacao$pasta <- "saida/exemplos"; cfg$exportacao$formatos <- "png"; cfg$exportacao$dpi <- 200
cfg$exportacao$nome_arquivo <- "29_estilo_publicacao"
cfg$legenda$dentro_x <- 0.97; cfg$legenda$dentro_y <- 0.04
cfg$grafico$colunas_y <- c("Amostra A", "Amostra B", "Amostra C")
cfg$eixo_y$titulo <- "Temperatura (°C)"
gerar(temp, cfg)

# --- 30 Estilo salvo: apresentação --------------------------------------------
cfg <- novo_cfg("30_estilo_apresentacao")
cfg <- carregar_estilo("apresentacao", cfg)
cfg$exportacao$pasta <- "saida/exemplos"; cfg$exportacao$formatos <- "png"; cfg$exportacao$dpi <- 200
cfg$exportacao$nome_arquivo <- "30_estilo_apresentacao"
cfg$grafico$tipo <- "barras"
cfg$grafico$colunas_y <- c("Ensaio 1", "Ensaio 2")
cfg$eixo_x$titulo <- ""; cfg$eixo_y$titulo <- "Resistência (MPa)"; cfg$eixo_y$inicio <- 0
gerar(mat, cfg)

message("\nPronto! Veja a pasta saida/exemplos/")
