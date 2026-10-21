# =============================================================================
#  03_executar.R — SEU ROTEIRO DE TRABALHO
# =============================================================================
#  1. Abra o projeto pelo arquivo graficos_R.Rproj (assim as pastas funcionam).
#  2. Coloque seu CSV na pasta dados/.
#  3. Rode este arquivo linha a linha (Ctrl+Enter) e vá ajustando o cfg.
#  Dicas: ajuda()  |  ajuda("eixo_x")  |  ajuda("tipos")  |  galeria()
# =============================================================================

source("01_config.R", encoding = "UTF-8")   # cria o cfg com os padrões
source("02_motor.R",  encoding = "UTF-8")   # carrega as funções (e o catálogo)

# ---- 1. Ler os dados ---------------------------------------------------------
dados <- ler_csv("dados/ensaio_temperatura.csv")   # <- troque pelo seu arquivo
colunas(dados)                                     # números e nomes das colunas

# ---- 2. (Opcional) aplicar um estilo salvo -------------------------------------
# listar_estilos()
# cfg <- carregar_estilo("padrao_cientifico", cfg)

# ---- 3. O que plotar -------------------------------------------------------------
cfg$grafico$tipo      <- "linha_pontos"          # ajuda("tipos")
cfg$grafico$coluna_x  <- "Tempo (min)"
cfg$grafico$colunas_y <- c("Amostra A", "Amostra B", "Amostra C")

# ---- 4. Eixos -------------------------------------------------------------------
cfg$eixo_x$titulo <- "Tempo (min)"
cfg$eixo_x$inicio <- 0;  cfg$eixo_x$fim <- 60
cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 10
cfg$eixo_x$n_menores <- 1

cfg$eixo_y$titulo <- "Temperatura (°C)"
# cfg$eixo_y$inicio <- 0; cfg$eixo_y$fim <- 100
# cfg$eixo_y$escala <- "log10"

# ---- 5. Séries (cores, símbolos, legenda, barras de erro) --------------------
cfg$cores$paleta <- "cinabro"
cfg$series[["Amostra A"]] <- list(coluna_erro = "Desvio A", nome_legenda = "Amostra A (± DP)")
# cfg$series[["Amostra B"]] <- list(cor = "#D62728", simbolo = 22)
# cfg$series[["Amostra C"]] <- list(mostrar_na_legenda = FALSE)

# ---- 6. Caixa, ticks e legenda -----------------------------------------------------
cfg$caixa$fechada <- TRUE                # moldura nos 4 lados
cfg$caixa$ticks_espelhados <- TRUE       # ticks também no topo e à direita
cfg$eixo_x$direcao_maiores <- "dentro";  cfg$eixo_y$direcao_maiores <- "dentro"
cfg$legenda$posicao <- "dentro"          # "direita", "topo", "base", ...
cfg$legenda$dentro_x <- 0.04; cfg$legenda$dentro_y <- 0.96
# cfg$legenda$mostrar <- FALSE           # apaga a legenda

# ---- 7. Gerar, conferir e salvar ----------------------------------------------------
g <- plotar(dados, cfg)
visualizar(g)          # prévia no Viewer com o tamanho/fontes REAIS do arquivo final

cfg$exportacao$largura <- 12; cfg$exportacao$altura <- 9   # cm
cfg$exportacao$formatos <- c("png", "pdf")                 # "tiff", "svg", "emf", "jpeg"
cfg$exportacao$nome_arquivo <- "minha_figura"
salvar(g, cfg)

# ---- 8. (Opcional) guardar este visual para reutilizar ----------------------------
# salvar_estilo(cfg, "meu_estilo")
# Depois, em qualquer gráfico:  cfg <- carregar_estilo("meu_estilo", cfg)

# ---- 9. (Opcional) aplicar o mesmo cfg a todos os CSVs de dados/ -------------------
# exportar_lote("dados", cfg)

# Para recomeçar do zero:  resetar_cfg()
# Exemplos de TODOS os tipos (painéis, quebra de eixo, eixo Y2, pizza, box...):
#   abra 05_exemplos.R
