# =============================================================================
#  meu_grafico_exemplo.R — SEUS AJUSTES PRONTOS (quebra no Y, ÷1000, cores, fonte, negrito)
# =============================================================================
#  Como usar: deixe este arquivo na MESMA pasta do graficos_R_completo.R, abra no RStudio,
#  troque o nome do CSV na linha marcada e clique em Source (Ctrl+Shift+S).
#  Cada bloco abaixo é um dos pedidos; apague ou comente (#) o que não quiser.
# =============================================================================

source("graficos_R_completo.R", encoding = "UTF-8")    # carrega o template (ajuste o caminho se preciso)

# ---- 0. Seus dados ----------------------------------------------------------------
dados <- ler_csv("meu_arquivo.csv")        # <<< TROQUE pelo seu arquivo (ex.: "C:/pasta/dados.csv")
colunas(dados)                             # mostra o número e o nome de cada coluna

cfg$grafico$tipo      <- "linha_pontos"    # ou "pontos", "linha", "barras"...
cfg$grafico$coluna_x  <- 1                 # coluna do eixo X (número ou "nome")
cfg$grafico$colunas_y <- NULL              # NULL = todas as outras colunas numéricas; ou c(2, 3)

# ---- 1. QUEBRA NO EIXO Y (intervalo grande entre os dados) -----------------------------
sug <- sugerir_quebra(dados, cfg)          # acha o maior vazio entre os valores e imprime a sugestão
cfg$quebra$ativo <- TRUE
cfg$quebra$de    <- sug$de                 # início do trecho omitido  (ou digite: 5000)
cfg$quebra$ate   <- sug$ate                # fim do trecho omitido     (ou digite: 80000)
cfg$quebra$espaco_pt      <- 14            # espaço entre as duas partes (evita números sobrepostos)
cfg$quebra$ligar_atraves  <- FALSE         # não liga os pontos através da quebra
cfg$quebra$proporcao_superior <- 0.5       # altura da parte de cima (0 a 1); ajuste conforme seus dados

# ---- 2. NÚMEROS DO EIXO Y ÷ 1000 (100000 aparece como 100) e "×10^3" no título --------
cfg$eixo_y$fator_divisao <- 1000
cfg$eixo_y$titulo <- "Intensidade (×10^{3} u.a.)"      # ^{3} vira expoente; troque o texto
cfg$eixo_x$titulo <- "Tempo (h)"

# ---- 3. CORES (no lugar das cores padrão tipo Origin) ------------------------------
# a) uma paleta pronta: "okabe_ito", "tableau", "viridis", "cinza", "brewer_Set1", ...  (veja mostrar_paletas())
# cfg$cores$paleta <- "okabe_ito"
# b) suas próprias cores, na ordem das colunas Y:
cfg$cores$paleta <- "personalizada"
cfg$cores$personalizada <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A")
# c) a cor de UMA coluna (use o nome exato da coluna):
# cfg$series[["Amostra A"]] <- list(cor = "#C00000")

# ---- 4. FONTE e NEGRITO ------------------------------------------------------------
cfg$texto$fonte <- "Arial"                 # "Times New Roman", "Calibri"... (veja listar_fontes())
cfg$texto$tamanho_base_pt <- 12
cfg$eixo_y$negrito_titulo  <- TRUE         # título do eixo Y em negrito
cfg$eixo_x$negrito_titulo  <- TRUE         # título do eixo X em negrito
cfg$titulos$titulo <- NULL                 # título do gráfico (ex.: "Resultado"); NULL = sem título
cfg$titulos$negrito_titulo <- TRUE         # título do gráfico em negrito

# ---- 5. Ver e salvar -------------------------------------------------------------------
cfg$exportacao$formatos <- c("png", "pdf"); cfg$exportacao$dpi <- 600
cfg$exportacao$nome_arquivo <- "meu_grafico"
g <- plotar(dados, cfg)
visualizar(g)                              # prévia com o tamanho e a fonte reais
salvar(g, cfg)                             # grava na pasta saida/
