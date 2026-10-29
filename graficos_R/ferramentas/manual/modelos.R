# Modelos de planilha (CSV) do manual: gera a pasta modelos_csv/ (dados ALEATÓRIOS, só para mostrar o formato), os gráficos de cada modelo
# (manual/img/m*.png) e o apêndice do manual (entre os marcadores APENDICE-INICIO/FIM de manual/manual.html).
# uso (na pasta graficos_R):  Rscript ferramentas/manual/modelos.R      (depois: node ferramentas/manual/gerar_pdf.js)
suppressMessages({ source("01_config.R", encoding = "UTF-8"); source("02_motor.R", encoding = "UTF-8") })
set.seed(2024)
pasta <- "modelos_csv"; dir.create(pasta, showWarnings = FALSE); saida <- file.path("manual", "img")
r1 <- function(x, n = 1) round(x, n)
# os CSVs saem como o Excel brasileiro salva: Latin-1, ponto e vírgula, vírgula decimal (o Cinabro lê sem configurar nada)
gravar <- function(df, nome) { utils::write.table(df, file.path(pasta, nome), sep = ";", dec = ",", row.names = FALSE, quote = FALSE, na = "", fileEncoding = "latin1"); invisible(df) }
novo <- function(nome, larg = 11, alt = 7.6) { c <- cfg; c$exportacao$pasta <- saida; c$exportacao$nome_arquivo <- nome; c$exportacao$formatos <- "png"
  c$exportacao$largura <- larg; c$exportacao$altura <- alt; c$exportacao$dpi <- 200; c }
lê <- function(a) suppressMessages(ler_csv(file.path(pasta, a)))
gerar <- function(c, d) { g <- suppressWarnings(plotar(d, c)); suppressMessages(suppressWarnings(salvar(g, c))) }
eixos <- function(c, x, y) { c$eixo_x$titulo <- x; c$eixo_y$titulo <- y; c }
modelos <- list()
add <- function(id, titulo, quando, arq, marcar, nota = NULL) modelos[[length(modelos) + 1]] <<- list(id = id, titulo = titulo, quando = quando, arq = arq, marcar = marcar, nota = nota)

# ---- 1. séries em X (linhas, pontos, áreas) -------------------------------------------------------------------------------------------
t <- seq(0, 60, 10)
gravar(data.frame(`Tempo (min)` = t, `Amostra A` = r1(20 + 55 * (1 - exp(-t / 25)) + rnorm(7, 0, 1.2)), `Amostra B` = r1(19 + 42 * (1 - exp(-t / 30)) + rnorm(7, 0, 1.2)),
                  `Amostra C` = r1(20 + 24 * (1 - exp(-t / 35)) + rnorm(7, 0, 1.2)), check.names = FALSE), "modelo_01_series_xy.csv")
c <- eixos(novo("m01_series_xy"), "Tempo (min)", "Temperatura (°C)"); c$grafico$tipo <- "linha_pontos"; c$legenda$posicao <- "topo"; gerar(c, lê("modelo_01_series_xy.csv"))
add("m01", "Séries ao longo de X (linhas, pontos, áreas)", "Medidas em função do tempo, da concentração, da distância... Cada coluna depois do X vira <b>uma série</b> (uma cor, um símbolo).",
    "modelo_01_series_xy.csv", c("<b>Tipo de gráfico:</b> Linha com pontos (ou Só linha, Só pontos, Área).", "<b>Coluna do eixo X:</b> Tempo (min).", "<b>Colunas do eixo Y:</b> deixe vazio (usa todas) ou escolha só as que quer."),
    "Para ajustar uma curva (linear, exponencial...), use <i>Só pontos</i> e o botão <i>Ajuste de curva</i> da faixa de ferramentas.")

# ---- 2. dois eixos Y -------------------------------------------------------------------------------------------------------------------------
h <- seq(0, 24, 2)
gravar(data.frame(`Hora do dia (h)` = h, `Temperatura (°C)` = r1(22 + 6 * sin((h - 8) / 24 * 2 * pi) + rnorm(13, 0, 0.3)), `Umidade (%)` = r1(62 - 14 * sin((h - 8) / 24 * 2 * pi) + rnorm(13, 0, 1)), check.names = FALSE), "modelo_02_dois_eixos.csv")
c <- eixos(novo("m02_dois_eixos"), "Hora do dia (h)", "Temperatura (°C)"); c$grafico$tipo <- "linha_pontos"; c$eixo_y2$ativo <- TRUE; c$eixo_y2$titulo <- "Umidade (%)"
c$series[["Umidade (%)"]] <- list(eixo = "y2", cor = "#2F6670"); c$legenda$posicao <- "topo"; gerar(c, lê("modelo_02_dois_eixos.csv"))
add("m02", "Duas grandezas no mesmo gráfico (dois eixos Y)", "Séries com unidades diferentes (°C e %, mg e mL). A planilha é igual à anterior: uma coluna por série.",
    "modelo_02_dois_eixos.csv", c("<b>Tipo de gráfico:</b> Linha com pontos.", "<b>Coluna do eixo X:</b> Hora do dia (h).", "No painel <b>Eixos</b>, abra <b>Eixo Y da direita</b>, ligue-o e escolha <b>Umidade (%)</b> em <i>Séries no eixo direito</i>."))

# ---- 3. série temporal (datas) -----------------------------------------------------------------------------------------------------------------
dt <- seq(as.POSIXct("2024-03-01 00:00", tz = "UTC"), by = "6 hours", length.out = 40)
gravar(data.frame(`Data e hora` = format(dt, "%d/%m/%Y %H:%M"), `Nível (m)` = r1(2.4 + 0.5 * sin(seq(0, 7, length.out = 40)) + rnorm(40, 0, 0.05), 2), `Vazão (L/s)` = r1(180 + 40 * sin(seq(0, 7, length.out = 40)) + rnorm(40, 0, 4), 0), check.names = FALSE), "modelo_03_serie_temporal.csv")
c <- eixos(novo("m03_serie_temporal"), "Data", "Nível (m)"); c$grafico$tipo <- "linha"; c$grafico$colunas_y <- "Nível (m)"; c$legenda$mostrar <- FALSE; gerar(c, lê("modelo_03_serie_temporal.csv"))
add("m03", "Série temporal (datas e horas)", "Registros de sensores, coletas, dias. A coluna de datas vira um <b>eixo de tempo</b> sozinha.",
    "modelo_03_serie_temporal.csv", c("<b>Coluna do eixo X:</b> Data e hora (escreva como <code>01/03/2024 06:00</code>: dia/mês/ano, hora opcional).", "<b>Colunas do eixo Y:</b> as séries que quer ver."),
    "Os intervalos entre as datas não precisam ser iguais.")

# ---- 4. barras com erro (média e desvio padrão) --------------------------------------------------------------------------------------------------
tr <- c("Controle", "Tratamento A", "Tratamento B", "Tratamento C")
mu <- cbind(c(10, 10.5, 9.8, 10.2), c(12, 15, 18, 14), c(13, 21, 26, 17))
gravar(data.frame(Tratamento = tr, `Dia 1` = r1(mu[, 1]), `Dia 7` = r1(mu[, 2]), `Dia 14` = r1(mu[, 3]), `DP Dia 1` = r1(runif(4, .4, .9)), `DP Dia 7` = r1(runif(4, .6, 1.4)), `DP Dia 14` = r1(runif(4, .8, 2)), check.names = FALSE), "modelo_04_barras_erro.csv")
c <- eixos(novo("m04_barras_erro"), "Tratamento", "Massa seca (g)"); c$grafico$tipo <- "barras"; c$grafico$colunas_y <- c("Dia 1", "Dia 7", "Dia 14")
c$series[["Dia 1"]] <- list(coluna_erro = "DP Dia 1"); c$series[["Dia 7"]] <- list(coluna_erro = "DP Dia 7"); c$series[["Dia 14"]] <- list(coluna_erro = "DP Dia 14"); c$legenda$posicao <- "topo"; gerar(c, lê("modelo_04_barras_erro.csv"))
add("m04", "Barras agrupadas com barras de erro", "Comparar categorias (tratamentos, materiais) em vários momentos. A <b>média</b> de cada série fica numa coluna e o <b>desvio padrão</b> em outra, na mesma ordem.",
    "modelo_04_barras_erro.csv", c("<b>Tipo de gráfico:</b> Barras.", "<b>Coluna do eixo X (ou dos nomes):</b> Tratamento.", "<b>Colunas do eixo Y:</b> Dia 1, Dia 7, Dia 14.", "<b>Colunas de erro:</b> DP Dia 1, DP Dia 7, DP Dia 14 (a 1ª vale para a 1ª série, a 2ª para a 2ª...)."))

# ---- 5. pizza ----------------------------------------------------------------------------------------------------------------------------------------
gravar(data.frame(Componente = c("Plástico", "Papel", "Vidro", "Metal", "Orgânico", "Outros"), `Massa (kg)` = c(120, 95, 40, 28, 210, 35), check.names = FALSE), "modelo_05_pizza.csv")
c <- novo("m05_pizza", 8.5, 7.2); c$grafico$tipo <- "pizza"; gerar(c, lê("modelo_05_pizza.csv"))
add("m05", "Pizza ou rosca (composição de um todo)", "Poucas categorias (até uns 7) que somam um todo. Os valores viram porcentagens.",
    "modelo_05_pizza.csv", c("<b>Tipo de gráfico:</b> Pizza / rosca.", "<b>Coluna do eixo X (ou dos nomes):</b> Componente.", "<b>Colunas do eixo Y:</b> Massa (kg)."))

# ---- 6. boxplot: uma coluna por grupo ----------------------------------------------------------------------------------------------------------------
gravar(data.frame(Controle = r1(rnorm(8, 50, 4)), `Dose 1` = r1(rnorm(8, 55, 4)), `Dose 2` = r1(rnorm(8, 62, 5)), `Dose 3` = r1(rnorm(8, 70, 6)), check.names = FALSE), "modelo_06_boxplot_colunas.csv")
c <- eixos(novo("m06_boxplot_colunas"), "Tratamento", "Resposta (u.a.)"); c$grafico$tipo <- "boxplot"; c$grafico$coluna_x <- NULL; gerar(c, lê("modelo_06_boxplot_colunas.csv"))
add("m06", "Replicatas por grupo (uma coluna por grupo)", "Várias medidas de cada tratamento: <b>cada coluna é um grupo</b> e cada linha, uma medida. É o jeito mais rápido de digitar.",
    "modelo_06_boxplot_colunas.csv", c("<b>Tipo de gráfico:</b> Boxplot (caixas).", "<b>Coluna do eixo X:</b> deixe vazio. <b>Colunas do eixo Y:</b> deixe vazio (usa todas) ou escolha os grupos.", "<b>Coluna dos grupos:</b> vazia."),
    "Grupos com número diferente de medidas? Deixe as células vazias: tudo bem.")

# ---- 7. boxplot / histograma: formato longo ---------------------------------------------------------------------------------------------------------
g7 <- rep(c("Controle", "Dose 1", "Dose 2"), each = 8)
gravar(data.frame(Tratamento = g7, Local = rep(c("Campo", "Estufa"), 12), `Resposta (u.a.)` = r1(rnorm(24, rep(c(50, 58, 66), each = 8), 4)), check.names = FALSE), "modelo_07_formato_longo.csv")
c <- eixos(novo("m07_formato_longo"), "Tratamento", "Resposta (u.a.)"); c$grafico$tipo <- "boxplot"; c$grafico$coluna_x <- NULL; c$grafico$colunas_y <- "Resposta (u.a.)"; c$grafico$coluna_grupo <- "Tratamento"; gerar(c, lê("modelo_07_formato_longo.csv"))
add("m07", "Formato longo: uma coluna de grupo e uma de valor", "Quando há muitos grupos ou mais de um fator (tratamento, local, tempo...). Cada linha é <b>uma medida</b>, com o grupo escrito ao lado. Serve para boxplot, histograma e densidade.",
    "modelo_07_formato_longo.csv", c("<b>Tipo de gráfico:</b> Boxplot (ou Histograma, Curva de densidade).", "<b>Colunas do eixo Y:</b> Resposta (u.a.).", "<b>Coluna dos grupos:</b> Tratamento (ou Local, para outra divisão: troque e compare)."),
    "Cada coluna de texto (Tratamento, Local) pode ser a divisão do gráfico; para ver as duas, use duas abas.")

# ---- 8. histograma -------------------------------------------------------------------------------------------------------------------------------------
gravar(data.frame(`Diâmetro (mm)` = r1(c(rnorm(60, 12, 1.6), rnorm(60, 15.5, 1.9))), Lote = rep(c("Lote 1", "Lote 2"), each = 60), check.names = FALSE), "modelo_08_histograma.csv")
c <- eixos(novo("m08_histograma"), "Diâmetro (mm)", "Frequência"); c$grafico$tipo <- "histograma"; c$grafico$coluna_x <- NULL; c$grafico$colunas_y <- "Diâmetro (mm)"; c$grafico$coluna_grupo <- "Lote"; c$legenda$posicao <- "topo"; gerar(c, lê("modelo_08_histograma.csv"))
add("m08", "Distribuição dos valores (histograma, densidade)", "Muitas medidas de uma mesma grandeza, com ou sem divisão em grupos (lotes, locais).",
    "modelo_08_histograma.csv", c("<b>Tipo de gráfico:</b> Histograma (ou Curva de densidade, Distribuição acumulada).", "<b>Colunas do eixo Y:</b> Diâmetro (mm).", "<b>Coluna dos grupos:</b> Lote (vazio = um grupo só)."))

# ---- 9. mapa de calor (matriz) e 10. longo ---------------------------------------------------------------------------------------------------------------
cond <- c("Controle", "Dose 1", "Dose 2", "Dose 3", "Dose 4")
M <- sapply(seq_along(cond), function(j) r1(pmax(rnorm(8, 5 + 2 * (j - 1) * runif(8, -.3, 1.2), 1.2), 0.2)))
gravar(data.frame(Gene = sprintf("Gene %02d", 1:8), setNames(as.data.frame(M), cond), check.names = FALSE), "modelo_09_mapa_calor.csv")
c <- novo("m09_mapa_calor", 10, 7.6); c$grafico$tipo <- "mapa_calor"; c$grafico$coluna_x <- 1; c$mapa_calor$valores_nas_celulas <- TRUE; gerar(c, lê("modelo_09_mapa_calor.csv"))
add("m09", "Mapa de calor: matriz de linhas × colunas", "Uma tabela de valores (genes × doses, amostras × variáveis, meses × locais) pintada por um gradiente de cor.",
    "modelo_09_mapa_calor.csv", c("<b>Tipo de gráfico:</b> Mapa de calor.", "<b>Coluna do eixo X (ou dos nomes):</b> Gene (os nomes das linhas).", "<b>Colunas do eixo Y:</b> deixe vazio (todas as outras viram as colunas do mapa)."),
    "Em <i>Mais opções</i> do mapa de calor: normalizar por linha, agrupar por semelhança, escrever o valor em cada célula.")
lg <- expand.grid(Local = c("Ponto 1", "Ponto 2", "Ponto 3", "Ponto 4", "Ponto 5"), Mes = c("Jan", "Abr", "Jul", "Out"), stringsAsFactors = FALSE)
gravar(data.frame(Local = lg$Local, Mes = lg$Mes, `Chuva (mm)` = r1(runif(nrow(lg), 10, 220), 0), check.names = FALSE), "modelo_10_mapa_calor_longo.csv")
c <- novo("m10_mapa_calor_longo", 8.5, 6.5); c$grafico$tipo <- "mapa_calor"; c$grafico$coluna_x <- "Local"; c$grafico$coluna_grupo <- "Mes"; c$grafico$colunas_y <- "Chuva (mm)"; c$mapa_calor$formato <- "longo"; c$mapa_calor$valores_nas_celulas <- TRUE; gerar(c, lê("modelo_10_mapa_calor_longo.csv"))
add("m10", "Mapa de calor: formato longo (três colunas)", "Quando os dados já estão assim (um registro por linha: onde, quando, quanto). O Cinabro monta a matriz sozinho.",
    "modelo_10_mapa_calor_longo.csv", c("<b>Tipo de gráfico:</b> Mapa de calor; <b>Formato da tabela:</b> Longo (linha, coluna, valor).", "<b>Coluna do eixo X:</b> Local. <b>Coluna dos grupos:</b> Mes (vira as colunas do mapa).", "<b>Colunas do eixo Y:</b> Chuva (mm) (o valor)."))

# ---- 11. PCA -----------------------------------------------------------------------------------------------------------------------------------------------
grp <- rep(c("Controle", "Tratamento 1", "Tratamento 2"), each = 6); t1 <- as.integer(grp == "Tratamento 1"); t2 <- as.integer(grp == "Tratamento 2")
pv <- function(base, e1, e2, dp) r1(rnorm(18, base + e1 * t1 + e2 * t2, dp), 2)
gravar(data.frame(Amostra = paste0(rep(c("C", "T1", "T2"), each = 6), 1:6), Grupo = grp, `Clorofila a` = pv(2.4, -0.7, -0.2, 0.35), Carotenoides = pv(0.9, 0.1, 0.35, 0.14), Proteínas = pv(14, 0.5, 4, 1.6),
                  Açúcares = pv(6, 2.6, -0.5, 0.9), Fenóis = pv(3.1, 0.9, 0.2, 0.55), Prolina = pv(0.5, 0.2, 0.9, 0.2), `Temperatura (°C)` = r1(rnorm(18, 24 + t1 - t2, 1.4)), `Umidade (%)` = r1(rnorm(18, 70 - 5 * t1 + 3 * t2, 4), 0), check.names = FALSE), "modelo_11_pca.csv")
c <- novo("m11_pca", 11, 7.6); c$grafico$tipo <- "pca"; c$grafico$coluna_x <- "Amostra"; c$grafico$coluna_grupo <- "Grupo"; c$multivariada$variaveis <- c("Clorofila a", "Carotenoides", "Proteínas", "Açúcares", "Fenóis", "Prolina")
c$multivariada$ambientais <- c("Temperatura (°C)", "Umidade (%)"); c$multivariada$transformacao <- "padronizar"; c$multivariada$elipses <- "dados"; gerar(c, lê("modelo_11_pca.csv"))
add("m11", "PCA: amostras nas linhas, variáveis nas colunas", "Comparar o perfil de várias amostras em muitas variáveis. <b>Cada linha é uma amostra</b>; as colunas são o nome, o grupo (opcional), as variáveis e, se tiver, as variáveis ambientais, <b>tudo na mesma planilha</b>.",
    "modelo_11_pca.csv", c("<b>Tipo de gráfico:</b> PCA.", "<b>Coluna do eixo X (ou dos nomes):</b> Amostra. <b>Coluna dos grupos:</b> Grupo (cor e elipse de cada grupo).",
    "<b>Variáveis:</b> as seis medidas (Clorofila a... Prolina). <b>Variáveis ambientais:</b> Temperatura e Umidade (aparecem como setas vermelhas; podem ficar vazias).", "<b>Transformação:</b> Padronizar (recomendado quando as variáveis têm unidades ou escalas diferentes)."),
    "Pelo menos 4 amostras. Com poucas amostras por grupo (3 ou menos) a elipse não é desenhada.")

# ---- 12. CCA -------------------------------------------------------------------------------------------------------------------------------------------------
est <- rep(c("Seca", "Chuva"), each = 8); e <- as.integer(est == "Chuva")
sp <- sapply(c(8, 5, 12, 3, 9, 2, 6, 4), function(m) rpois(16, m * (1 + e * runif(1, -.6, 1.2))))
colnames(sp) <- paste("Espécie", LETTERS[1:8])
gravar(data.frame(Ponto = paste0("P", 1:16), Estação = est, as.data.frame(sp, check.names = FALSE), pH = r1(rnorm(16, 6.5 + .5 * e, .3), 1), `Temperatura (°C)` = r1(rnorm(16, 22 - 3 * e, 1.2)), `Salinidade (g/L)` = r1(rnorm(16, 8 - 3 * e, 1)), check.names = FALSE), "modelo_12_cca.csv")
c <- novo("m12_cca", 11, 7.6); c$grafico$tipo <- "cca"; c$grafico$coluna_x <- "Ponto"; c$grafico$coluna_grupo <- "Estação"; c$multivariada$variaveis <- colnames(sp); c$multivariada$ambientais <- c("pH", "Temperatura (°C)", "Salinidade (g/L)"); c$multivariada$elipses <- "nenhuma"; gerar(c, lê("modelo_12_cca.csv"))
add("m12", "CCA e CA: contagens, abundâncias e variáveis ambientais", "Espécies (ou classes) por ponto de coleta, mais as variáveis do ambiente <b>na mesma planilha</b>. No bloco Dados você diz o que é matriz e o que é ambiental.",
    "modelo_12_cca.csv", c("<b>Tipo de gráfico:</b> CCA (ou CA, sem as ambientais).", "<b>Coluna do eixo X:</b> Ponto. <b>Coluna dos grupos:</b> Estação.", "<b>Variáveis:</b> as oito espécies. <b>Variáveis ambientais:</b> pH, Temperatura, Salinidade (o CCA exige as ambientais)."),
    "CA e CCA exigem valores <b>maiores ou iguais a zero</b> (contagens, abundâncias). Valores negativos? Use o PCA.")

# ---- 13. mapa-múndi e 14. Brasil -----------------------------------------------------------------------------------------------------------------------------
pais <- c("United States of America", "Canada", "Brazil", "Argentina", "Germany", "France", "United Kingdom", "Spain", "China", "India", "Japan", "Australia", "South Africa", "Mexico")
gravar(data.frame(Country = pais, `Vendas (mil)` = round(runif(length(pais), 40, 900), 0), check.names = FALSE), "modelo_13_mapa_mundo.csv")
c <- novo("m13_mapa_mundo", 11, 6.4); c$grafico$tipo <- "mapa_mundo"; c$grafico$coluna_x <- 1; gerar(c, lê("modelo_13_mapa_mundo.csv"))
add("m13", "Mapa-múndi por país ou por região comercial", "Um valor por país (vendas, casos, produção). Os países <b>sem linha</b> na planilha ficam cinza.",
    "modelo_13_mapa_mundo.csv", c("<b>Tipo de gráfico:</b> Mapa-múndi.", "<b>Coluna do eixo X (ou dos nomes):</b> Country (o país <b>em inglês</b>; também vale <i>USA</i>, <i>UK</i> e o código de 3 letras).", "<b>Colunas do eixo Y:</b> Vendas (mil). Em <i>Pintar por</i> escolha País ou Região (Asia Pacific, LATAM, Brazil, North America, Western Europe, Other)."),
    "Países repetidos são somados (ou a média, ou o máximo: <i>Valores repetidos</i>).")
uf <- c("AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG","PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO")
gravar(data.frame(UF = uf, `Resíduos (t)` = round(runif(27, 150, 5200), 0), check.names = FALSE), "modelo_14_mapa_brasil.csv")
c <- novo("m14_mapa_brasil", 8.5, 8.2); c$grafico$tipo <- "mapa_brasil"; c$grafico$coluna_x <- 1; gerar(c, lê("modelo_14_mapa_brasil.csv"))
add("m14", "Mapa do Brasil por estado ou por região", "Um valor por estado. Vale a <b>sigla</b> (SP) ou o <b>nome</b> (São Paulo; o acento não importa).",
    "modelo_14_mapa_brasil.csv", c("<b>Tipo de gráfico:</b> Mapa do Brasil.", "<b>Coluna do eixo X:</b> UF. <b>Colunas do eixo Y:</b> Resíduos (t).", "<b>Pintar por:</b> Estado, ou Região (IBGE) para somar por região."))

# ---- 15. antes e depois: tabela cruzada -> uma linha por amostra ---------------------------------------------------------------------------------------------
antes <- c(";Dia 1;;;Dia 7;;", ";Controle;Trat. A;Trat. B;Controle;Trat. A;Trat. B",
           "Clorofila;1;1,12;0,95;1;1,31;0,82", "Carotenoides;1;0,97;1,08;1;1,15;1,22", "Prolina;1;1,25;1,4;1;1,9;2,3")
writeLines(antes, file.path(pasta, "modelo_15a_ANTES_tabela_cruzada.csv"), useBytes = FALSE)
V <- list(Clorofila = c(1,1.12,.95,1,1.31,.82), Carotenoides = c(1,.97,1.08,1,1.15,1.22), Prolina = c(1,1.25,1.4,1,1.9,2.3))
dia <- rep(c("Dia 1", "Dia 7"), each = 3); trt <- rep(c("Controle", "Trat. A", "Trat. B"), 2)
gravar(data.frame(Amostra = paste(trt, dia), Dia = dia, Tratamento = trt, Clorofila = V[[1]], Carotenoides = V[[2]], Prolina = V[[3]], check.names = FALSE), "modelo_15b_DEPOIS_pca.csv")

# ---- o apêndice do manual ---------------------------------------------------------------------------------------------------------------------------------------------
esc <- function(x) gsub(">", "&gt;", gsub("<", "&lt;", gsub("&", "&amp;", x, fixed = TRUE), fixed = TRUE), fixed = TRUE)
ler_txt <- function(arq) { l <- readLines(file.path(pasta, arq), encoding = "latin1", warn = FALSE); iconv(l, "latin1", "UTF-8") }
tabela <- function(arq, n = 6, cls = "csv") { l <- ler_txt(arq); mais <- length(l) > n + 1; l <- utils::head(l, n + 1); p <- strsplit(l, ";", fixed = TRUE)
  larg <- max(lengths(p)); p <- lapply(p, function(z) c(z, rep("", larg - length(z))))
  if (larg > 9) { p <- lapply(p, function(z) c(z[1:8], "…")); larg <- 9 }
  lin <- function(z, tag) paste0("<tr>", paste0("<", tag, ">", esc(z), "</", tag, ">", collapse = ""), "</tr>")
  paste0("<table class=\"", cls, "\">", lin(p[[1]], "th"), paste(vapply(p[-1], lin, "", tag = "td"), collapse = ""), if (mais) paste0("<tr class=\"mais\"><td colspan=\"", larg, "\">… (e assim por diante)</td></tr>"), "</table>") }
bloco <- vapply(seq_along(modelos), function(i) { m <- modelos[[i]]
  paste0("<div class=\"modelo\">\n  <h3>A.", i + 3, " ", m$titulo, "</h3>\n  <p class=\"quando\">", m$quando, " Arquivo: <code>modelos_csv/", m$arq, "</code></p>\n  <div class=\"lado\">\n    <div class=\"texto\">\n      ", tabela(m$arq),
         "\n      <ol class=\"passos\">", paste0("<li>", m$marcar, "</li>", collapse = ""), "</ol>", if (!is.null(m$nota)) paste0("\n      <div class=\"dica\">", m$nota, "</div>"), "\n    </div>\n    <figure><img src=\"img/", m$id, "_", sub("^modelo_[0-9]+_", "", sub("\\.csv$", "", m$arq)), ".png\" alt=\"", esc(m$titulo), "\"><figcaption>O resultado com esta planilha.</figcaption></figure>\n  </div>\n</div>\n") }, "")
miolo <- paste(bloco, collapse = "")
html <- paste(readLines(file.path("manual", "manual.html"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
a <- regexpr("<!-- MODELOS-INICIO -->", html, fixed = TRUE); b <- regexpr("<!-- MODELOS-FIM -->", html, fixed = TRUE)
if (a < 0 || b < 0) stop("faltam os marcadores MODELOS-INICIO / MODELOS-FIM em manual/manual.html")
html <- paste0(substr(html, 1, a + attr(a, "match.length") - 1), "\n", miolo, substr(html, b, nchar(html)))
writeLines(html, file.path("manual", "manual.html"), useBytes = TRUE)
cat("modelos:", length(modelos), "| CSVs em", pasta, "| imagens em", saida, "| manual.html atualizado\n")
