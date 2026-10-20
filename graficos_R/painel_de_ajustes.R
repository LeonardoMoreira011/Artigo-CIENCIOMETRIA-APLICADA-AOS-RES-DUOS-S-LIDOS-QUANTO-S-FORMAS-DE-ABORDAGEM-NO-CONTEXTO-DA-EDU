# =============================================================================
#  PAINEL DE AJUSTES DO GRÁFICO  (edite só este bloco)
# =============================================================================
#  Como usar: preencha ARQUIVO_CSV, mude o que quiser e clique em Source (Ctrl+Shift+S).
#  NULL = "não mexer" (vale o padrão do template). Para voltar ao padrão, escreva NULL.
#  Textos entre aspas; números sem aspas e com PONTO decimal; TRUE/FALSE em maiúsculas.
#  Categorias:  1 ARQUIVO E TIPO | 2 INTERVALOS | 3 ESCALA | 4 NÚMEROS E TÍTULOS | 5 GRADE |
#               6 QUEBRA DO EIXO Y | 7 EIXO Y DA DIREITA | 8 CORES E LINHAS | 9 FONTE | 10 MOLDURA |
#               11 LEGENDA (posição, fundo, borda, sombra) | 12 EXPORTAÇÃO
#  Quer um ajuste que não está aqui? Use o cfg direto (ajuda("eixo_x"), ajuda("grade")...).
# =============================================================================

# ---- 1. ARQUIVO E TIPO DE GRÁFICO -----------------------------------------------------------
ARQUIVO_CSV <- ""        # caminho do CSV. EX.: "C:/pasta/dados.csv". Vazio = só carrega o template.
tipo_grafico <- NULL     # "pontos" | "linha" | "linha_pontos" | "area" | "barras" | "pizza" | "boxplot"...
coluna_x     <- NULL     # coluna do eixo X: número ou "nome". EX.: 1  |  "Years"
colunas_y    <- NULL     # colunas Y. NULL = todas as outras numéricas. EX.: c(2, 3)  |  c("WORLD", "LATAM")

# ---- 2. INTERVALOS DOS EIXOS (início, fim, passo e grossura dos traços) -------------------------
#  Eixo X
x_inicio    <- NULL      # começo do eixo X.  EX.: 2015
x_fim       <- NULL      # fim do eixo X.     EX.: 2026
x_intervalo <- NULL      # distância entre os traços: 1 = de 1 em 1 | 2 = de 2 em 2 | 5 | "1 mes" (datas)
x_primeiro_tick <- NULL  # de onde começa a contar. EX.: 2016 (com x_intervalo 2: 2016, 2018, 2020...)
x_ticks_manuais <- NULL  # posições escolhidas à mão (ignora x_intervalo). EX.: c(2015, 2020, 2026)
x_ticks_menores <- NULL  # traços pequenos entre dois grandes. 0 = SEM traços pequenos. EX.: 0
x_ticks_espessura_pt <- NULL   # GROSSURA dos traços do eixo X, em pt. EX.: 1.5   (vale para grandes e pequenos)
x_ticks_comprimento_pt <- NULL # comprimento dos traços grandes, em pt. EX.: 6
x_ticks_menores_comprimento_pt <- NULL   # comprimento dos traços pequenos. EX.: 3
x_ticks_direcao <- NULL  # "dentro" | "fora" | "ambos" (cruzando o eixo) | "nenhum"
x_ticks_menores_direcao <- NULL
x_ticks_cor     <- NULL  # EX.: "black"
x_linha_espessura_pt <- NULL   # grossura da linha do eixo X (quando a moldura não é fechada). EX.: 1.5
#  Eixo Y
y_inicio    <- NULL      # EX.: 0
y_fim       <- NULL      # EX.: 700000
y_intervalo <- NULL      # EX.: 100000 (de 100000 em 100000)
y_primeiro_tick <- NULL
y_ticks_manuais <- NULL  # EX.: c(0, 1000, 5000, 10000)
y_ticks_menores <- NULL  # EX.: 0
y_ticks_espessura_pt <- NULL   # grossura dos traços do eixo Y. EX.: 1.5
y_ticks_comprimento_pt <- NULL
y_ticks_menores_comprimento_pt <- NULL
y_ticks_direcao <- NULL
y_ticks_menores_direcao <- NULL
y_ticks_cor     <- NULL
y_linha_espessura_pt <- NULL
#  Moldura (a caixa em volta do gráfico)
ticks_espelhados     <- NULL   # TRUE = repete os traços no topo e à direita (moldura fechada)
moldura_espessura_pt <- NULL   # grossura da moldura, em pt. EX.: 1.5
moldura_cor          <- NULL   # EX.: "black"
#  (a grossura das linhas da GRADE está no bloco 5)

# ---- 3. ESCALA (tipo, inversão e folga nas pontas) ------------------------------------------------
x_folga_pct <- NULL      # espaço extra nas pontas, em % do eixo. Evita o 1º/último ponto cortado. EX.: 4
x_escala    <- NULL      # "linear" | "log10" | "ln" | "log2" | "reciproco" | "raiz"
x_inverter  <- NULL      # TRUE = maior valor à esquerda
y_folga_pct <- NULL      # EX.: 3
y_escala    <- NULL      # EX.: "log10"
y_inverter  <- NULL
recortar_nos_limites <- NULL   # FALSE = pontos nas pontas aparecem INTEIROS (não são cortados pela moldura)

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
#  Distâncias (pt): quanto afastar o título dos números e os números do eixo
x_distancia_titulo_pt  <- NULL   # título do X até os números. EX.: 6
y_distancia_titulo_pt  <- NULL   # título do Y até os números (com quebra de eixo vale também). EX.: 6
x_distancia_numeros_pt <- NULL   # números do X até o eixo. EX.: 3
y_distancia_numeros_pt <- NULL

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
quebra_estilo    <- NULL   # "separado" (dois gráficos com espaço) | "continuo" (uma moldura só, estilo Origin)
quebra_de        <- NULL   # início do trecho omitido. EX.: 5000
quebra_ate       <- NULL   # fim do trecho omitido.    EX.: 80000
quebra_espaco_pt <- NULL   # espaço entre as duas partes (aumente se os números se sobrepuserem). EX.: 14
quebra_y2_de     <- NULL   # trecho omitido do eixo DIREITO (valores do Y2). NULL = acompanha o do esquerdo. EX.: 2000
quebra_y2_ate    <- NULL   # EX.: 6000
quebra_y_intervalo_inferior <- NULL   # intervalo entre os traços da parte de baixo do eixo esquerdo. EX.: 20
quebra_y_intervalo_superior <- NULL   # ... e da parte de cima (começa no quebra_ate). EX.: 100
quebra_y2_intervalo_inferior <- NULL  # o mesmo para o eixo direito (baixo)
quebra_y2_intervalo_superior <- NULL  # ... (cima)
quebra_ligar_pontos      <- NULL   # FALSE = não liga os pontos através da quebra
quebra_proporcao_superior <- NULL  # altura da parte de cima, de 0 a 1. EX.: 0.5

# ---- 7. EIXO Y DA DIREITA (Y2): outras variáveis com escala, cor e intervalos próprios ---------------
#  O eixo X continua o mesmo. As colunas listadas em y2_series saem do eixo esquerdo e vão para o direito.
y2_series  <- NULL        # colunas no eixo direito. EX.: "Temperatura"  |  c("Temperatura", "Umidade")
y2_titulo  <- NULL        # título do eixo direito. EX.: "Temperatura (°C)"
y2_inicio  <- NULL        # começo do eixo direito. EX.: 0
y2_fim     <- NULL        # fim do eixo direito.    EX.: 40
y2_intervalo <- NULL      # distância entre os traços. EX.: 5 (de 5 em 5)
y2_ticks_manuais <- NULL  # posições à mão (ignora y2_intervalo). EX.: c(0, 10, 25, 40)
y2_ticks_menores <- NULL  # traços pequenos entre dois grandes. 0 = nenhum
y2_cor       <- NULL      # UMA cor para as séries do Y2 E para o eixo (números, título, traços). EX.: "#C00000"
y2_cor_eixo  <- NULL      # só a cor do eixo ("serie" = cor da 1ª série do Y2 | uma cor). Ignorado se y2_cor existir
y2_dividir_por <- NULL    # divide os números do eixo direito. EX.: 1000 (NULL = igual ao do eixo esquerdo)
                          #   Avise a unidade no título. EX.: y2_titulo <- "Pop. (×10^{3})"
y2_igual_y1   <- NULL     # TRUE = números, título e traços do Y2 iguais aos do Y1 (preto, mesmo título se y2_titulo
                          #   estiver vazio). A legenda das séries já é uma só para os dois eixos.
y2_legenda_sufixo <- NULL # texto somado ao nome das séries do Y2 na legenda única. EX.: " (eixo dir.)"
y2_casas_decimais <- NULL # EX.: 1
y2_notacao   <- NULL      # "normal" | "milhar" | "cientifica" | "potencia10" | "percentual"
y2_prefixo   <- NULL      # EX.: "US$ "
y2_sufixo    <- NULL      # EX.: " %"
y2_fator     <- NULL      # SEM séries novas: mostra o MESMO dado em outra unidade (y2 = fator × y + deslocamento).
y2_deslocamento <- NULL   #   EX. de °C para °F:  y2_fator <- 1.8;  y2_deslocamento <- 32
y2_distancia_titulo_pt  <- NULL   # título do Y2 até os números. EX.: 6
y2_distancia_numeros_pt <- NULL   # números do Y2 até o eixo. EX.: 3
#  As cores de cada série (esquerda ou direita) também podem vir de cores_por_serie (bloco 8).

# ---- 8. CORES, LINHAS E SÍMBOLOS ----------------------------------------------------------------
cores_paleta        <- NULL   # "classico" (padrão tipo Origin) | "okabe_ito" | "tableau" | "viridis" | "cinza" |
                              # "brewer_Set1"... (veja mostrar_paletas())
cores_personalizadas <- NULL  # suas cores, na ordem das colunas Y. EX.: c("#000000", "#D62728", "#1F4E9E")
cores_por_serie     <- NULL   # a cor de séries específicas (nome exato da coluna).
                              # EX.: c("WORLD" = "#000000", "LATAM" = "#C00000", "BRAZIL" = "#1F4E9E")
cores_gradiente     <- NULL   # TRUE = barras/áreas com degradê
cores_gradiente_cor2 <- NULL  # cor final do degradê. EX.: "white"
#  Grossuras SEPARADAS (todas em pt; valem para todas as séries):
linha_espessura_pt  <- NULL   # grossura das LINHAS. EX.: 2.5
simbolo_tamanho_pt  <- NULL   # tamanho dos PONTOS (símbolos). EX.: 8
simbolo_borda_pt    <- NULL   # grossura do CONTORNO dos pontos. EX.: 1.2
#  Só de algumas séries (nome exato da coluna; as demais seguem o valor geral acima):
linha_espessura_por_serie <- NULL   # EX.: c("WORLD" = 1, "BRAZIL" = 3.5)
simbolo_tamanho_por_serie <- NULL   # EX.: c("BRAZIL" = 10)
simbolo_borda_por_serie   <- NULL   # EX.: c("BRAZIL" = 1.5)
#  Só linhas, só pontos ou os dois: o "tipo" do bloco 1 ("linha" | "pontos" | "linha_pontos").
#  Formas dos pontos:
simbolo_forma  <- NULL   # UMA forma para todas as séries: "circulo" | "quadrado" | "losango" | "triangulo" |
                         #   "triangulo_invertido" | "estrela" | "cruz" | "x" | "circulo_vazio" | "quadrado_vazio" | "esfera"
                         #   (ou o número do R, 0 a 25). Preencher isto desliga a troca automática de formas.
simbolo_variar <- NULL   # TRUE = cada série com uma forma diferente | FALSE = todas iguais (simbolo_forma, padrão círculo)
simbolos_ordem <- NULL   # com variar: quais formas, em ordem. EX.: c("quadrado", "circulo", "triangulo")
simbolo_forma_por_serie <- NULL  # forma de séries específicas. EX.: c("WORLD" = "esfera", "BRAZIL" = "quadrado")
simbolo_preenchimento <- NULL    # "serie" (cheio) | "branco" | "vazio" | uma cor
esfera_luz     <- NULL   # de onde vem a luz na "esfera", c(x, y) de -1 a 1. EX.: c(-0.4, 0.5) (brilho em cima, à esquerda)

# ---- 9. FONTE -----------------------------------------------------------------------------------
fonte            <- NULL   # EX.: "Arial" | "Times New Roman" | "Calibri"  (nomes instalados: listar_fontes())
fonte_pasta      <- NULL   # pasta com os .ttf da fonte, para usá-la SEM instalar no Windows (quando listar_fontes() não a
                           #   mostra). EX.: "C:/Users/voce/Downloads/Barlow"  com  fonte <- "Barlow"
tamanho_texto_pt <- NULL   # tamanho BASE de todo o texto (os itens abaixo, se preenchidos, têm prioridade). EX.: 12
cor_texto        <- NULL   # EX.: "black"
#  Tamanhos separados, em pt (NULL = usa o tamanho base):
titulo_grafico_tamanho_pt <- NULL   # título no topo da figura. EX.: 16
x_titulo_tamanho_pt  <- NULL        # título do eixo X (ex.: "Years"). EX.: 14
y_titulo_tamanho_pt  <- NULL        # título do eixo Y (ex.: "Dolar"). EX.: 14
x_numeros_tamanho_pt <- NULL        # números do eixo X (os anos). EX.: 10
y_numeros_tamanho_pt <- NULL        # números do eixo Y. EX.: 10
legenda_texto_tamanho_pt  <- NULL   # nomes na legenda (WORLD, LATAM...). EX.: 10
legenda_titulo_tamanho_pt <- NULL   # título da legenda. EX.: 11
rotulos_dados_tamanho_pt  <- NULL   # texto escrito junto dos pontos/barras (rótulos de dados). EX.: 8

# ---- 10. MOLDURA DO GRÁFICO ---------------------------------------------------------------------------
caixa_fechada    <- NULL   # TRUE = moldura nos 4 lados | FALSE = só eixos esquerdo e inferior
painel_largura_cm <- NULL  # TAMANHO FIXO da caixa do gráfico (dentro dos eixos), em cm, igual em todos os gráficos.
painel_altura_cm  <- NULL  #   EX.: 9 e 6.5. Números, títulos e legenda ficam fora; a página se ajusta para caber tudo.

# ---- 11. LEGENDA: POSIÇÃO, FUNDO, BORDA E SOMBRA -------------------------------------------------------
legenda_mostrar  <- NULL   # FALSE = sem legenda
legenda_titulo   <- NULL   # título da legenda. EX.: "Região"
legenda_nomes    <- NULL   # como cada série aparece escrita na legenda. EX.: c("WORLD RSP" = "Mundo (RSP)")
#  Posição
legenda_posicao  <- NULL   # "dentro" (sobre o gráfico) | "direita" | "esquerda" | "topo" | "base" (fora do gráfico)
legenda_canto    <- NULL   # atalho para "dentro": "sup_esq" | "sup_centro" | "sup_dir" | "centro_esq" | "centro" |
                           #   "centro_dir" | "inf_esq" | "inf_centro" | "inf_dir". EX.: "sup_dir"
legenda_x        <- NULL   # posição fina com "dentro", de 0 (esquerda) a 1 (direita). EX.: 0.04
legenda_y        <- NULL   # de 0 (embaixo) a 1 (em cima). EX.: 0.96
legenda_ancora   <- NULL   # qual ponto da caixa fica em (x, y): c(0, 1) = canto sup. esq. | c(1, 1) = sup. dir. ...
legenda_alinhar  <- NULL   # com a legenda FORA: onde ela fica ao longo do lado.
legenda_escala   <- NULL   # aumenta (> 1) ou diminui (< 1) a legenda toda. EX.: 0.8
legenda_distancia_pt <- NULL  # com "dentro": distância até a borda da caixa, em pt. EX.: 8  |  c(10, 6). Use com legenda_canto
legenda_ajustar_caixa <- NULL # TRUE (padrão) = se a legenda for maior que a caixa, é reduzida até caber | FALSE = como pedido
                           #   direita/esquerda: "topo" | "centro" | "base"; topo/base: "esquerda" | "centro" | "direita"
#  Disposição dos itens
legenda_direcao  <- NULL   # "vertical" (um embaixo do outro) | "horizontal" (lado a lado)
legenda_n_colunas <- NULL  # número de colunas. EX.: 2
legenda_inverter_ordem <- NULL  # TRUE = inverte a ordem dos itens
legenda_tamanho_chave_pt <- NULL   # tamanho do quadradinho/linha de cada item. EX.: 18
legenda_espacamento_pt   <- NULL   # espaço entre os itens. EX.: 4
legenda_margem_interna_pt <- NULL  # folga dentro da caixa: c(cima, direita, baixo, esquerda). EX.: c(6, 8, 6, 8)
#  Fundo
legenda_fundo    <- NULL   # cor de fundo da caixa. EX.: "white" | "#F2F2F2" | "transparente"
legenda_fundo_opacidade <- NULL    # 0 (invisível) a 1 (sólido). EX.: 0.8
#  Borda (basta preencher cor, espessura ou tipo para a borda aparecer)
legenda_borda    <- NULL   # TRUE = borda na caixa | FALSE = sem borda
legenda_borda_cor <- NULL  # EX.: "black"
legenda_borda_espessura_pt <- NULL  # EX.: 1
legenda_borda_tipo <- NULL # "solid" | "dashed" | "dotted" | "dotdash" | "longdash" | "twodash"
#  Sombra (basta preencher cor, opacidade ou deslocamento para a sombra aparecer)
legenda_sombra   <- NULL   # TRUE = sombra atrás da caixa (com fundo "transparente" a caixa fica branca)
legenda_sombra_cor <- NULL # EX.: "black" | "grey30"
legenda_sombra_opacidade <- NULL    # 0 a 1. EX.: 0.35
legenda_sombra_deslocamento_pt <- NULL  # c(para a direita, para baixo) em pt. EX.: c(3, 3)  |  c(5, 2)

# ---- 12. EXPORTAÇÃO ------------------------------------------------------------------------------------
largura_cm   <- NULL       # EX.: 14   (com painel_largura_cm preenchido a página se ajusta sozinha e estes valores não valem)
altura_cm    <- NULL       # EX.: 10
ajustar_pagina <- NULL     # com caixa de tamanho fixo: TRUE (padrão) = a página cresce/encolhe para caber tudo |
                           #   FALSE = página sempre largura_cm x altura_cm (a caixa fica centralizada)
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
