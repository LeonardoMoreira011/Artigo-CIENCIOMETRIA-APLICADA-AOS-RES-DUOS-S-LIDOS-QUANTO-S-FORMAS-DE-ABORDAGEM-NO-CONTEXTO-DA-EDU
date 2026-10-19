# =============================================================================
#  PAINEL DE AJUSTES DO GRÁFICO  (edite só este bloco)
# =============================================================================
#  Como usar: preencha ARQUIVO_CSV, mude o que quiser e clique em Source (Ctrl+Shift+S).
#  NULL = "não mexer" (vale o padrão do template). Para voltar ao padrão, escreva NULL.
#  Textos entre aspas; números sem aspas e com PONTO decimal; TRUE/FALSE em maiúsculas.
#  Categorias:  1 ARQUIVO E TIPO | 2 ESCALA | 3 TICKS | 4 NÚMEROS E TÍTULOS | 5 GRADE |
#               6 QUEBRA DO EIXO Y | 7 CORES E LINHAS | 8 FONTE | 9 LEGENDA E MOLDURA | 10 EXPORTAÇÃO
#  Quer um ajuste que não está aqui? Use o cfg direto (ajuda("eixo_x"), ajuda("grade")...).
# =============================================================================

# ---- 1. ARQUIVO E TIPO DE GRÁFICO -----------------------------------------------------------
ARQUIVO_CSV <- ""        # caminho do CSV. EX.: "C:/pasta/dados.csv". Vazio = só carrega o template.
tipo_grafico <- NULL     # "pontos" | "linha" | "linha_pontos" | "area" | "barras" | "pizza" | "boxplot"...
coluna_x     <- NULL     # coluna do eixo X: número ou "nome". EX.: 1  |  "Years"
colunas_y    <- NULL     # colunas Y. NULL = todas as outras numéricas. EX.: c(2, 3)  |  c("WORLD", "LATAM")

# ---- 2. ESCALA (limites, tipo e folga) -------------------------------------------------------
x_inicio    <- NULL      # início do eixo X. EX.: 2015   (em datas: "01/01/2024")
x_fim       <- NULL      # fim do eixo X.    EX.: 2026
x_folga_pct <- NULL      # espaço extra nas pontas, em % do eixo. Evita o 1º/último ponto cortado. EX.: 4
x_escala    <- NULL      # "linear" | "log10" | "ln" | "log2" | "reciproco" | "raiz"
x_inverter  <- NULL      # TRUE = maior valor à esquerda
y_inicio    <- NULL      # EX.: 0
y_fim       <- NULL      # EX.: 700000
y_folga_pct <- NULL      # EX.: 3
y_escala    <- NULL      # EX.: "log10"
y_inverter  <- NULL
recortar_nos_limites <- NULL   # FALSE = pontos nas pontas aparecem INTEIROS (não são cortados pela moldura)

# ---- 3. TICKS (os traços do eixo e o intervalo entre eles) -------------------------------------
x_intervalo      <- NULL   # distância entre ticks. EX.: 1 (todos os anos) | 5 | "1 mes" (datas) | "6 horas"
x_primeiro_tick  <- NULL   # onde começa a contar o intervalo. EX.: 2015
x_ticks_manuais  <- NULL   # posições escolhidas à mão (ignora x_intervalo). EX.: c(2015, 2020, 2026)
x_ticks_menores  <- NULL   # nº de ticks menores entre dois maiores. 0 = SEM ticks menores. EX.: 0
x_ticks_direcao  <- NULL   # "dentro" | "fora" | "ambos" | "nenhum"
x_ticks_menores_direcao <- NULL
x_ticks_comprimento_pt  <- NULL          # EX.: 6
x_ticks_menores_comprimento_pt <- NULL   # EX.: 3
y_intervalo      <- NULL   # EX.: 100000
y_primeiro_tick  <- NULL
y_ticks_manuais  <- NULL   # EX.: c(0, 1000, 5000, 10000)
y_ticks_menores  <- NULL   # EX.: 0
y_ticks_direcao  <- NULL
y_ticks_menores_direcao <- NULL
y_ticks_comprimento_pt  <- NULL
y_ticks_menores_comprimento_pt <- NULL
ticks_espelhados <- NULL   # TRUE = repete os ticks no topo e à direita (moldura fechada)

# ---- 4. NÚMEROS E TÍTULOS ---------------------------------------------------------------------
x_titulo         <- NULL   # EX.: "Anos"   (expoente: "Área (m^{2})"; índice: "CO_{2}")
y_titulo         <- NULL   # EX.: "Receita (US$ ×10^{3})"
titulo_grafico   <- NULL   # título no topo da figura. EX.: "Evolução 2015-2026"
titulo_grafico_negrito <- NULL   # TRUE | FALSE
eixos_titulo_negrito   <- NULL   # TRUE = títulos dos eixos X e Y em negrito
x_dividir_por    <- NULL   # divide os números do eixo. EX.: 1000 (100000 vira 100; avise no título)
y_dividir_por    <- NULL
x_casas_decimais <- NULL   # EX.: 0   (NULL = automático)
y_casas_decimais <- NULL
x_notacao        <- NULL   # "normal" | "milhar" | "cientifica" | "potencia10" | "percentual"
y_notacao        <- NULL
x_rotacao_numeros <- NULL  # graus. EX.: 45
y_rotacao_numeros <- NULL
x_mostrar_numeros <- NULL  # FALSE = esconde os números do eixo
y_mostrar_numeros <- NULL

# ---- 5. GRADE (linhas de fundo) ---------------------------------------------------------------
grade_x          <- NULL   # TRUE = linhas verticais nos ticks maiores do X
grade_y          <- NULL   # TRUE = linhas horizontais nos ticks maiores do Y
grade_cor        <- NULL   # EX.: "grey60" | "#1F4E9E"
grade_tipo       <- NULL   # "solid" | "dashed" (tracejada) | "dotted" (pontilhada) | "dotdash" | "longdash"
grade_espessura_pt <- NULL # EX.: 0.5
grade_opacidade  <- NULL   # 0 (invisível) a 1 (cor cheia). EX.: 0.4
grade_menor_x    <- NULL   # grade dos ticks MENORES (normalmente FALSE)
grade_menor_y    <- NULL
grade_menor_cor  <- NULL
grade_menor_tipo <- NULL
grade_menor_espessura_pt <- NULL
grade_menor_opacidade    <- NULL

# ---- 6. QUEBRA DO EIXO Y (intervalo grande entre os dados) -------------------------------------
quebra_ativar    <- NULL   # TRUE liga. Sem quebra_de/quebra_ate, o script ACHA o maior vazio entre os dados
quebra_de        <- NULL   # início do trecho omitido. EX.: 5000
quebra_ate       <- NULL   # fim do trecho omitido.    EX.: 80000
quebra_espaco_pt <- NULL   # espaço entre as duas partes (aumente se os números se sobrepuserem). EX.: 14
quebra_ligar_pontos      <- NULL   # FALSE = não liga os pontos através da quebra
quebra_proporcao_superior <- NULL  # altura da parte de cima, de 0 a 1. EX.: 0.5

# ---- 7. CORES, LINHAS E SÍMBOLOS ----------------------------------------------------------------
cores_paleta        <- NULL   # "classico" (padrão tipo Origin) | "okabe_ito" | "tableau" | "viridis" | "cinza" |
                              # "brewer_Set1"... (veja mostrar_paletas())
cores_personalizadas <- NULL  # suas cores, na ordem das colunas Y. EX.: c("#000000", "#D62728", "#1F4E9E")
cores_por_serie     <- NULL   # a cor de séries específicas (nome exato da coluna).
                              # EX.: c("WORLD" = "#000000", "LATAM" = "#C00000", "BRAZIL" = "#1F4E9E")
cores_gradiente     <- NULL   # TRUE = barras/áreas com degradê
cores_gradiente_cor2 <- NULL  # cor final do degradê. EX.: "white"
linha_espessura_pt  <- NULL   # EX.: 2
simbolo_tamanho_pt  <- NULL   # EX.: 7

# ---- 8. FONTE -----------------------------------------------------------------------------------
fonte            <- NULL   # EX.: "Arial" | "Times New Roman" | "Calibri"  (nomes instalados: listar_fontes())
tamanho_texto_pt <- NULL   # tamanho base do texto. EX.: 12
cor_texto        <- NULL   # EX.: "black"

# ---- 9. LEGENDA E MOLDURA ---------------------------------------------------------------------------
legenda_mostrar  <- NULL   # FALSE = sem legenda
legenda_posicao  <- NULL   # "dentro" | "direita" | "esquerda" | "topo" | "base"
legenda_x        <- NULL   # com "dentro": posição de 0 a 1. EX.: 0.04
legenda_y        <- NULL   # EX.: 0.96
legenda_titulo   <- NULL   # EX.: "Região"
caixa_fechada    <- NULL   # TRUE = moldura nos 4 lados | FALSE = só eixos esquerdo e inferior

# ---- 10. EXPORTAÇÃO ------------------------------------------------------------------------------------
largura_cm   <- NULL       # EX.: 14
altura_cm    <- NULL       # EX.: 10
dpi          <- NULL       # EX.: 600
formatos     <- NULL       # EX.: c("png", "pdf")   (também "tiff", "svg", "jpeg", "emf")
nome_arquivo <- NULL       # EX.: "minha_figura"
pasta_saida  <- NULL       # EX.: "C:/pasta/figuras"  (padrão: pasta saida/)

# =============================================================================
#  EXECUÇÃO (não precisa editar)
# =============================================================================
if (nzchar(ARQUIVO_CSV)) {
  dados <- ler_csv(ARQUIVO_CSV)
  cfg <- aplicar_painel(cfg, dados = dados)
  g <- plotar(dados, cfg)
  visualizar(g)
  salvar(g, cfg)
} else {
  cfg <- aplicar_painel(cfg)
  message("Preencha ARQUIVO_CSV no painel e rode de novo (Source) para gerar o gráfico.")
}
