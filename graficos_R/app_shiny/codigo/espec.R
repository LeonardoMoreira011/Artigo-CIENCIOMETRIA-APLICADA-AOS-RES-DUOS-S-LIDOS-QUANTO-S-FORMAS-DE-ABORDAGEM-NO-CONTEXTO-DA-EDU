# =============================================================================
#  app_shiny/codigo/espec.R — ESPECIFICAÇÃO DOS CAMPOS DO APP (blocos, textos, tipos)
# =============================================================================
#  Cada campo do app é uma variável do painel_de_ajustes.R (mesmo nome). O app monta as variáveis e chama
#  aplicar_painel(), então tudo o que o painel faz o app faz, igual. Para acrescentar um ajuste novo: escreva
#  um campo() no bloco certo. Tipos: num | int | txt | sel | selbusca | selmulti | chk | tri | cor | vec | colx | colsy | colsy2 | chkgrupo.
# =============================================================================

campo <- function(id, tipo, rotulo, ajuda = NULL, opcoes = NULL, min = NA, max = NA, passo = NA,
                  padrao = NULL, mais = FALSE, se = NULL, largura = 6, chave = NULL) {
  list(id = id, tipo = tipo, rotulo = rotulo, ajuda = ajuda, opcoes = opcoes, min = min, max = max, passo = passo,
       padrao = padrao, mais = mais, se = se, largura = largura, chave = chave)
}
bloco <- function(id, titulo, resumo, dica = NULL, campos = list(), grupos = NULL) {
  list(id = id, titulo = titulo, resumo = resumo, dica = dica, campos = campos, grupos = grupos)
}

.LINHAS <- c("Contínua" = "solid", "Tracejada" = "dashed", "Pontilhada" = "dotted", "Traço-ponto" = "dotdash",
             "Traço longo" = "longdash", "Traço duplo" = "twodash")
.DIRECAO <- c("Para dentro" = "dentro", "Para fora" = "fora", "Dos dois lados" = "ambos", "Sem traços" = "nenhum")
.NOTACAO <- c("Normal (1000)" = "normal", "Com milhar (1,000)" = "milhar", "Científica (1×10³)" = "cientifica",
              "Potência de 10 (10³)" = "potencia10", "Percentual (15%)" = "percentual")
.ESCALAS <- c("Linear (padrão)" = "linear", "Logarítmica base 10" = "log10", "Logarítmica natural (ln)" = "ln",
              "Logarítmica base 2" = "log2", "Recíproca (1/x)" = "reciproco", "Raiz quadrada" = "raiz")
.FORMAS <- c("Círculo" = "circulo", "Quadrado" = "quadrado", "Losango" = "losango", "Triângulo" = "triangulo",
             "Triângulo invertido" = "triangulo_invertido", "Estrela" = "estrela", "Cruz" = "cruz", "X" = "x",
             "Círculo vazio" = "circulo_vazio", "Quadrado vazio" = "quadrado_vazio",
             "Esfera (bolinha 3D)" = "esfera")
.TIPOS <- c("Linha com pontos" = "linha_pontos", "Só linha" = "linha", "Só pontos (dispersão)" = "pontos",
            "Área" = "area", "Área empilhada" = "area_empilhada", "Barras" = "barras", "Pizza / rosca" = "pizza",
            "Histograma" = "histograma", "Curva de densidade" = "densidade", "Distribuição acumulada" = "ecdf",
            "Boxplot (caixas)" = "boxplot")
# Fontes: as oficiais (Barlow), as genéricas e TODAS as que o systemfonts enxerga neste computador (e as adicionadas pelo app).
opcoes_fontes <- function() {
  oficiais <- c("Barlow (oficial)" = "Barlow", "Barlow Condensed" = "Barlow Condensed", "Barlow Semi Condensed" = "Barlow Semi Condensed")
  genericas <- c("Sans (Arial/Helvetica)" = "sans", "Serifada" = "serif", "Monoespaçada" = "mono")
  inst <- tryCatch({ .registrar_fontes_oficiais(); sort(unique(.familias_fontes())) }, error = function(e) character(0))
  inst <- setdiff(inst, c(unname(oficiais), unname(genericas)))
  out <- list("Fonte oficial" = oficiais, "Genéricas" = genericas)
  if (length(inst)) out[["Instaladas no computador (systemfonts)"]] <- stats::setNames(inst, inst)
  out
}
.FONTES <- opcoes_fontes()
# Paletas da tela: as do motor (agrupadas) + "Minhas paletas" (a que está sendo criada e as guardadas).
opcoes_paletas <- function(guardadas = character(0)) {
  minhas <- c("★ A que estou criando (veja abaixo)" = "propria", if (length(guardadas)) stats::setNames(paste0("salva:", guardadas), paste0("★ ", guardadas)))
  c(.PALETAS_GRUPOS, list("Minhas paletas" = minhas))
}
.FORMATOS <- c("PNG (imagem)" = "png", "TIFF (revistas)" = "tiff", "JPEG (foto)" = "jpeg", "SVG (editável)" = "svg", "PDF (vetorial)" = "pdf",
                if (requireNamespace("devEMF", quietly = TRUE)) c("EMF (Word/PowerPoint)" = "emf"))
.CANTOS <- c("(posição manual)" = "", "Em cima, à esquerda" = "sup_esq", "Em cima, no centro" = "sup_centro",
             "Em cima, à direita" = "sup_dir", "No meio, à esquerda" = "centro_esq", "No centro" = "centro",
             "No meio, à direita" = "centro_dir", "Embaixo, à esquerda" = "inf_esq", "Embaixo, no centro" = "inf_centro",
             "Embaixo, à direita" = "inf_dir")

# Campos de um eixo (X ou Y): início, fim, intervalo, traços...
.campos_intervalo <- function(p, nome) {
  P <- toupper(p)
  list(
    campo(paste0(p, "_inicio"), "num", paste0("Eixo ", P, " começa em"), "Deixe vazio para o automático."),
    campo(paste0(p, "_fim"), "num", paste0("Eixo ", P, " termina em"), "Deixe vazio para o automático."),
    campo(paste0(p, "_intervalo"), "txt", "Distância entre os traços",
          "1 = de 1 em 1; 2 = de 2 em 2; 0.5; em datas: \"1 mes\", \"2 semanas\". Vazio = automático."),
    campo(paste0(p, "_primeiro_tick"), "num", "Primeiro traço em", "De onde começa a contar (ex.: 2016 com intervalo 2)."),
    campo(paste0(p, "_ticks_menores"), "int", "Traços pequenos entre dois grandes",
          "0 = sem traços pequenos. 1 = um traço no meio.", min = 0, max = 20),
    campo(paste0(p, "_ticks_manuais"), "vec", "Traços em posições escolhidas",
          "Separe por vírgula: 2015, 2020, 2026. Ignora a distância acima.", largura = 12),
    campo(paste0(p, "_ticks_direcao"), "sel", "Traços grandes", "Para onde apontam.", opcoes = .DIRECAO, mais = TRUE),
    campo(paste0(p, "_ticks_menores_direcao"), "sel", "Traços pequenos", NULL, opcoes = .DIRECAO, mais = TRUE),
    campo(paste0(p, "_ticks_comprimento_pt"), "num", "Comprimento do traço grande (pt)", NULL, min = 0, passo = 0.5, mais = TRUE),
    campo(paste0(p, "_ticks_menores_comprimento_pt"), "num", "Comprimento do traço pequeno (pt)", NULL, min = 0, passo = 0.5, mais = TRUE),
    campo(paste0(p, "_ticks_espessura_pt"), "num", "Grossura dos traços (pt)", "Vazio = igual à da moldura.", min = 0, passo = 0.25, mais = TRUE),
    campo(paste0(p, "_ticks_cor"), "cor", "Cor dos traços", NULL, mais = TRUE),
    campo(paste0(p, "_linha_espessura_pt"), "num", "Grossura da linha do eixo (pt)",
          "Vazio = igual à da moldura. Só aparece quando a moldura NÃO é fechada.", min = 0, passo = 0.25, mais = TRUE)
  )
}
.campos_numeros <- function(p) {
  P <- toupper(p)
  list(
    campo(paste0(p, "_titulo"), "txt", paste0("Título do eixo ", P),
          "Expoente: m^{2}  Índice: CO_{2}  Exemplo: Área (m^{2})", largura = 12),
    campo(paste0(p, "_dividir_por"), "num", "Dividir os números por", "1000 mostra 100 no lugar de 100000 (avise no título: ×10^{3})."),
    campo(paste0(p, "_casas_decimais"), "int", "Casas decimais", "Vazio = automático.", min = 0, max = 10),
    campo(paste0(p, "_notacao"), "sel", "Formato dos números", NULL, opcoes = .NOTACAO),
    campo(paste0(p, "_rotacao_numeros"), "num", "Girar os números (graus)", "45 deixa os anos inclinados.", min = -90, max = 90),
    campo(paste0(p, "_mostrar_numeros"), "chk", "Mostrar os números do eixo"),
    campo(paste0(p, "_numeros_negrito"), "chk", "Números do eixo em negrito"),
    campo(paste0(p, "_rotacao_titulo"), "num", "Girar o título do eixo (graus)",
          if (p == "y") "Vazio = 90 (lendo de baixo para cima). 0 deixa o título na horizontal." else "Vazio = 0 (horizontal).",
          min = -180, max = 180, passo = 15),
    campo(paste0(p, "_distancia_titulo_pt"), "num", "Distância título ↔ números (pt)", "Afasta ou aproxima o título.", min = 0, passo = 1, mais = TRUE),
    campo(paste0(p, "_distancia_numeros_pt"), "num", "Distância números ↔ eixo (pt)", NULL, min = 0, passo = 1, mais = TRUE)
  )
}
.campos_escala <- function(p) {
  P <- toupper(p)
  list(
    campo(paste0(p, "_escala"), "sel", paste0("Escala do eixo ", P), "Logarítmica serve para dados que variam muitas ordens de grandeza.", opcoes = .ESCALAS),
    campo(paste0(p, "_folga_pct"), "num", "Folga nas pontas (%)", "Espaço extra além do primeiro e do último valor. 4 evita que os pontos das pontas sejam cortados.", min = 0, max = 50, passo = 1),
    campo(paste0(p, "_inverter"), "chk", "Inverter o eixo", "Os valores crescem no sentido contrário.")
  )
}

.SE_Y2 <- "input.y2_series && input.y2_series.length"
.SE_QUEBRA <- "input.quebra_ativar"
.SE_QUEBRA_Y2 <- "input.quebra_ativar && input.y2_series && input.y2_series.length"

# Eixo da direita (Y2): as mesmas opções do eixo Y.
.campos_intervalo_y2 <- function() {
  list(
    campo("y2_inicio", "num", "Eixo direito começa em", "Deixe vazio para o automático."),
    campo("y2_fim", "num", "Eixo direito termina em", "Deixe vazio para o automático."),
    campo("y2_intervalo", "num", "Distância entre os traços", "5 = de 5 em 5. Vazio = automático."),
    campo("y2_primeiro_tick", "num", "Primeiro traço em", "De onde começa a contar."),
    campo("y2_ticks_menores", "int", "Traços pequenos entre dois grandes", "0 = sem traços pequenos.", min = 0, max = 20),
    campo("y2_ticks_manuais", "vec", "Traços em posições escolhidas", "Separe por vírgula: 0, 10, 25, 40. Ignora a distância.", largura = 12),
    campo("y2_ticks_direcao", "sel", "Traços grandes", "Para onde apontam. Vazio = como o eixo esquerdo.", opcoes = c("(como o esquerdo)" = "", .DIRECAO), padrao = "", mais = TRUE),
    campo("y2_ticks_menores_direcao", "sel", "Traços pequenos", NULL, opcoes = c("(como o esquerdo)" = "", .DIRECAO), padrao = "", mais = TRUE),
    campo("y2_ticks_comprimento_pt", "num", "Comprimento do traço grande (pt)", "Vazio = como o eixo esquerdo.", min = 0, passo = 0.5, mais = TRUE),
    campo("y2_ticks_menores_comprimento_pt", "num", "Comprimento do traço pequeno (pt)", NULL, min = 0, passo = 0.5, mais = TRUE),
    campo("y2_ticks_espessura_pt", "num", "Grossura dos traços (pt)", "Vazio = como o eixo esquerdo (a da moldura).", min = 0, passo = 0.25, mais = TRUE),
    campo("y2_ticks_cor", "cor", "Cor dos traços", "Vazio = a cor do eixo direito.", mais = TRUE),
    campo("y2_linha_espessura_pt", "num", "Grossura da linha do eixo (pt)", "Só aparece quando a moldura NÃO é fechada.", min = 0, passo = 0.25, mais = TRUE)
  )
}
.campos_numeros_y2 <- function() {
  list(
    campo("y2_titulo", "txt", "Título do eixo direito", "Expoente: m^{2}  Índice: CO_{2}", largura = 12),
    campo("y2_dividir_por", "num", "Dividir os números por", "1000 mostra 100 em vez de 100000 (avise no título)."),
    campo("y2_casas_decimais", "int", "Casas decimais", "Vazio = automático.", min = 0, max = 10),
    campo("y2_notacao", "sel", "Formato dos números", NULL, opcoes = .NOTACAO),
    campo("y2_rotacao_numeros", "num", "Girar os números (graus)", "45 deixa os números inclinados.", min = -90, max = 90),
    campo("y2_mostrar_numeros", "chk", "Mostrar os números do eixo", NULL, padrao = TRUE),
    campo("y2_numeros_negrito", "chk", "Números do eixo em negrito"),
    campo("y2_numeros_tamanho_pt", "num", "Tamanho dos números (pt)", "Vazio = como o eixo esquerdo.", min = 4, passo = 1),
    campo("y2_rotacao_titulo", "num", "Girar o título do eixo (graus)", "Vazio = -90 (lendo de cima para baixo).", min = -180, max = 180, passo = 15),
    campo("y2_titulo_tamanho_pt", "num", "Tamanho do título (pt)", "Vazio = como o eixo esquerdo.", min = 4, passo = 1),
    campo("y2_titulo_negrito", "chk", "Título em negrito"),
    campo("y2_titulo_italico", "chk", "Título em itálico"),
    campo("y2_prefixo", "txt", "Texto antes do número", "Ex.: US$ ", mais = TRUE),
    campo("y2_sufixo", "txt", "Texto depois do número", "Ex.: %", mais = TRUE),
    campo("y2_distancia_titulo_pt", "num", "Distância título ↔ números (pt)", NULL, min = 0, mais = TRUE),
    campo("y2_distancia_numeros_pt", "num", "Distância números ↔ eixo (pt)", NULL, min = 0, mais = TRUE)
  )
}


# ---- Blocos 13 e 14: cada item (um ajuste, uma caixa, uma forma...) é um "cartão" com a sua caixa "Usar". ---------------------------
#  Os campos de um cartão não são variáveis soltas do painel: o app junta os cartões ligados numa LISTA (ajustes, marcas_estatisticas,
#  caixas_estatisticas, formas), igual ao painel_de_ajustes.R. O cartão k+1 só aparece quando o k está ligado.
.SERIES_TODAS <- c("Todas as séries" = "todas")
.ITENS_ESTAT <- list(
  "Resumo dos números" = c("n (quantidade)" = "n", "Média" = "media", "Mediana" = "mediana", "Desvio padrão" = "dp", "Erro padrão" = "ep", "Soma" = "soma",
                           "Mínimo" = "minimo", "Máximo" = "maximo", "Amplitude" = "amplitude", "Variância" = "variancia", "Coeficiente de variação" = "cv",
                           "1º quartil" = "q1", "3º quartil" = "q3", "Intervalo de confiança 95% da média" = "ic95"),
  "Do ajuste de curva" = c("Equação" = "equacao", "R²" = "r2", "R² ajustado" = "r2_aj", "RMSE (erro médio)" = "rmse", "AIC" = "aic", "BIC" = "bic",
                           "Valor de p do modelo (F)" = "p_modelo", "Parâmetros ± erro" = "parametros", "Valor de p de cada parâmetro" = "p_parametros",
                           "Normalidade dos resíduos (Shapiro)" = "shapiro_residuos"),
  "Testes estatísticos" = c("Correlação de Pearson (X × Y)" = "pearson", "Correlação de Spearman (X × Y)" = "spearman", "Correlação de Kendall (X × Y)" = "kendall",
                            "Normalidade (Shapiro-Wilk)" = "shapiro", "Teste t entre duas séries (Welch)" = "ttest", "Wilcoxon entre duas séries" = "wilcoxon",
                            "Teste F de variâncias (duas séries)" = "var_test", "ANOVA de um fator (séries)" = "anova", "Kruskal-Wallis (séries)" = "kruskal",
                            "Tukey (comparações duas a duas)" = "tukey", "Bartlett (variâncias iguais)" = "bartlett", "Fligner-Killeen (variâncias iguais)" = "fligner"))
.AJUSTES_OPC <- c("Linear (reta)" = "linear", "Exponencial (y = a·e^(bx))" = "exponencial", "Potência (y = a·x^b)" = "potencia", "Logarítmico (y = a + b·ln x)" = "logaritmico",
                  "Polinomial (grau 2, 3...)" = "polinomial", "Suavizado (loess)" = "loess", "Fórmula livre (a sua)" = "formula",
                  "Curva externa (pontos X,Y ou equação com valores prontos)" = "externa")
.CANTOS9 <- c("Em cima, à esquerda" = "sup_esq", "Em cima, no centro" = "sup_centro", "Em cima, à direita" = "sup_dir", "No meio, à esquerda" = "centro_esq",
              "No centro" = "centro", "No meio, à direita" = "centro_dir", "Embaixo, à esquerda" = "inf_esq", "Embaixo, no centro" = "inf_centro", "Embaixo, à direita" = "inf_dir")
.TIPOS_FORMA <- c("Caixa de texto" = "texto", "Retângulo" = "retangulo", "Retângulo de cantos arredondados" = "retangulo_arredondado", "Elipse / círculo" = "elipse",
                  "Triângulo" = "triangulo", "Losango" = "losango", "Hexágono" = "hexagono", "Estrela" = "estrela", "Polígono livre (vértices)" = "poligono")

# Cartão k de um tipo de item. 'fn' devolve a lista de campos; os ids são <prefixo><k>_<chave>.
.cartao <- function(pref, k, titulo, defs, usar) {
  id <- function(chave) paste0(pref, k, "_", chave)
  ativo <- paste0("input.", id("ativo"))
  cs <- function(chave, tipo, rotulo, ajuda = NULL, ..., se = NULL) {       # {chave} dentro de 'se' vira input.<prefixo><k>_<chave>
    cond <- if (is.null(se)) ativo else paste0(ativo, " && (", gsub("\\{(\\w+)\\}", paste0("input.", pref, k, "_\\1"), se), ")")
    campo(id(chave), tipo, rotulo, ajuda, ..., se = cond, chave = chave)
  }
  list(titulo = titulo, se = if (k > 1) paste0("input.", pref, k - 1, "_ativo") else NULL, ativo = id("ativo"),
       campos = c(list(campo(id("ativo"), "chk", usar, NULL, largura = 12, chave = "ativo")), defs(cs)))
}
.campos_ajuste <- function(cs) list(
  cs("serie", "sel", "Série", "Qual série recebe a curva (ou uma curva para cada série).", opcoes = .SERIES_TODAS, padrao = "todas"),
  cs("tipo", "sel", "Tipo de ajuste", "A equação e o R² aparecem numa caixa de estatística, que você move e edita à parte. Curva externa = uma curva que você já tem (de outro programa ou de um artigo): é só desenhada por cima dos dados, sem ajustar.", opcoes = .AJUSTES_OPC, padrao = "linear"),
  cs("formula", "txt", "Fórmula (use x e letras para os parâmetros)", "Ex.: a*exp(-b*x) + c   |   a/(1 + exp(-k*(x - x0)))   |   a*sin(b*x) + c. Funções: exp, log, log10, sqrt, sin, cos, tan, abs, ^ ... Na curva externa pode ser uma conta pronta, sem letras: 2.5*exp(-0.3*x) + 1.", se = "{tipo} == 'formula' || {tipo} == 'externa'", largura = 12),
  cs("parametros", "txt", "Valores dos parâmetros (curva externa)", "Ex.: a=2.5, b=0.3. Cada letra da fórmula precisa de um valor. Se a fórmula não tem letras, deixe vazio.", se = "{tipo} == 'externa'", largura = 12),
  cs("pontos", "area", "Pontos X,Y da curva externa (opcional)", "Cole duas colunas do Excel/Origin (X e Y, um ponto por linha; vírgula decimal vale) ou escreva 0,10; 5,18; 10,25. Se preencher, vale no lugar da fórmula.", se = "{tipo} == 'externa'", largura = 12),
  cs("interpolacao", "sel", "Ligar os pontos", NULL, opcoes = c("Com retas" = "linear", "Com curva lisa" = "suave"), padrao = "linear", se = "{tipo} == 'externa'"),
  cs("inicio", "txt", "Valores iniciais (opcional)", "Ex.: a=5, b=0.1, c=0. Vazio = o programa tenta vários sozinho.", se = "{tipo} == 'formula'", largura = 12),
  cs("grau", "int", "Grau do polinômio", "2 = parábola, 3 = cúbica...", min = 1, max = 8, padrao = 2, se = "{tipo} == 'polinomial'"),
  cs("suavizacao", "num", "Suavização (0.2 a 1)", "Maior = curva mais lisa.", min = 0.1, max = 1, passo = 0.05, padrao = 0.75, se = "{tipo} == 'loess'"),
  cs("intercepto_zero", "chk", "Passar pela origem (y = 0 quando x = 0)", NULL, se = "{tipo} == 'linear'", largura = 12),
  cs("cor", "cor", "Cor da curva", "Vazio = a cor da série."),
  cs("tipo_linha", "sel", "Tipo de linha", NULL, opcoes = .LINHAS, padrao = "dashed"),
  cs("espessura_pt", "num", "Grossura da linha (pt)", NULL, min = 0, passo = 0.25, padrao = 1.2),
  cs("banda", "chk", "Faixa do intervalo de confiança da curva", NULL, se = "{tipo} != 'externa'", largura = 12),
  cs("banda_nivel", "num", "Nível da faixa (0 a 1)", "0.95 = 95%.", min = 0.5, max = 0.999, passo = 0.01, padrao = 0.95, se = "{banda}"),
  cs("banda_opacidade", "num", "Opacidade da faixa", NULL, min = 0, max = 1, passo = 0.05, padrao = 0.18, se = "{banda}"),
  cs("estender", "chk", "Estender a curva até as bordas do eixo X", "Desmarcado: só no trecho dos dados.", largura = 12, mais = TRUE),
  cs("de", "num", "Desenhar a partir de X =", NULL, mais = TRUE),
  cs("ate", "num", "Desenhar até X =", NULL, mais = TRUE),
  cs("opacidade", "num", "Opacidade da linha", NULL, min = 0, max = 1, passo = 0.05, padrao = 1, mais = TRUE),
  cs("nome", "txt", "Nome do ajuste nas caixas", "Vazio = o nome do tipo.", mais = TRUE),
  cs("casas", "int", "Casas decimais da equação", "Vazio = 4 algarismos significativos.", min = 0, max = 10, mais = TRUE))
.campos_marca <- function(cs) list(
  cs("serie", "sel", "Série", NULL, opcoes = .SERIES_TODAS, padrao = "todas"),
  cs("modo", "sel", "O que desenhar", "Linhas atravessando o gráfico, ou barras de erro em cada X com replicatas.",
     opcoes = c("Linhas de média e faixa" = "linhas", "Barras de erro em cada X (replicatas)" = "barras_por_x"), padrao = "linhas"),
  cs("eixo", "sel", "Linhas sobre o eixo", "Y: linhas horizontais (valores de Y); X: verticais.", opcoes = c("Y (horizontais)" = "y", "X (verticais)" = "x"), padrao = "y", se = "{modo} == 'linhas'"),
  cs("centro", "sel", "Linha do centro", NULL, opcoes = c("Média" = "media", "Mediana" = "mediana", "Sem linha do centro" = "nenhum"), padrao = "media", se = "{modo} == 'linhas'"),
  cs("faixa", "sel", "Faixa em volta", "Desvio padrão, erro padrão, intervalo de confiança 95% ou do mínimo ao máximo.",
     opcoes = c("Desvio padrão (DP)" = "dp", "Erro padrão (EP)" = "ep", "Intervalo de confiança 95%" = "ic95", "Mínimo e máximo" = "minmax", "Sem faixa" = "nenhuma"), padrao = "dp"),
  cs("multiplo", "num", "Quantos DP / EP", "1 = ±1; 2 = ±2...", min = 0.1, passo = 0.5, padrao = 1),
  cs("cor", "cor", "Cor dos traços", "Vazio = a cor da série."),
  cs("centro_espessura_pt", "num", "Grossura da linha do centro (pt)", NULL, min = 0, passo = 0.25, padrao = 1.2, se = "{modo} == 'linhas'"),
  cs("centro_tipo", "sel", "Tipo da linha do centro", NULL, opcoes = .LINHAS, padrao = "solid", se = "{modo} == 'linhas'"),
  cs("faixa_espessura_pt", "num", "Grossura dos traços da faixa (pt)", NULL, min = 0, passo = 0.25, padrao = 0.8),
  cs("faixa_tipo", "sel", "Tipo dos traços da faixa", NULL, opcoes = .LINHAS, padrao = "dotted"),
  cs("preencher", "chk", "Pintar a área da faixa", NULL, se = "{modo} == 'linhas'", largura = 12),
  cs("preencher_opacidade", "num", "Opacidade da área pintada", NULL, min = 0, max = 1, passo = 0.05, padrao = 0.15, se = "{modo} == 'linhas' && {preencher}"),
  cs("rotulo", "chk", "Escrever o valor ao lado de cada traço", "Desligado: os valores (média, DP...) vão numa caixa de estatística à parte, que você move e edita.", padrao = FALSE, se = "{modo} == 'linhas'", largura = 12),
  cs("rotulo_tamanho_pt", "num", "Tamanho do texto (pt)", NULL, min = 4, padrao = 8, se = "{modo} == 'linhas' && {rotulo}"),
  cs("casas", "int", "Casas decimais", NULL, min = 0, max = 10, se = "{modo} == 'linhas'"),
  cs("opacidade", "num", "Opacidade dos traços", NULL, min = 0, max = 1, passo = 0.05, padrao = 1, mais = TRUE),
  cs("ponto_media", "chk", "Desenhar também a média (ponto)", NULL, se = "{modo} == 'barras_por_x'", largura = 12),
  cs("chapeu_percentual", "num", "Largura da tampa da barra (% do eixo X)", NULL, min = 0, passo = 0.5, padrao = 1.5, se = "{modo} == 'barras_por_x'"))
.campos_caixa <- function(cs) list(
  cs("titulo", "txt", "Título da caixa (opcional)", NULL, largura = 12),
  cs("series", "selmulti", "Séries incluídas", "Vazio = todas as séries do gráfico.", largura = 12),
  cs("itens", "selmulti", "O que escrever na caixa", "Clique para escolher, na ordem em que quer ler. Vazio = n, média e desvio padrão.", opcoes = .ITENS_ESTAT, largura = 12),
  cs("casas", "int", "Casas decimais", "Vazio = 4 algarismos significativos.", min = 0, max = 10),
  cs("x", "num", "Posição horizontal (0 a 1)", "0 = esquerda da caixa do gráfico, 1 = direita.", min = 0, max = 1, passo = 0.01, padrao = 0.03),
  cs("y", "num", "Posição vertical (0 a 1)", "0 = embaixo, 1 = em cima.", min = 0, max = 1, passo = 0.01, padrao = 0.97),
  cs("ancora", "sel", "Qual ponto da caixa fica em (x, y)", NULL, opcoes = .CANTOS9, padrao = "sup_esq"),
  cs("tamanho_pt", "num", "Tamanho do texto (pt)", "Vazio = o tamanho base.", min = 4, passo = 0.5),
  cs("cor_texto", "cor", "Cor do texto"),
  cs("negrito", "chk", "Texto em negrito"),
  cs("alinhamento", "sel", "Alinhamento do texto", NULL, opcoes = c("À esquerda" = "esquerda", "Centralizado" = "centro", "À direita" = "direita"), padrao = "esquerda"),
  cs("colorir_serie", "chk", "Escrever o nome da série na cor dela", NULL, padrao = TRUE, largura = 12),
  cs("fundo", "cor", "Cor de fundo", "Vazio = branco."),
  cs("opacidade_fundo", "num", "Opacidade do fundo (0 a 1)", NULL, min = 0, max = 1, passo = 0.05, padrao = 0.9),
  cs("borda", "chk", "Borda na caixa", NULL, padrao = TRUE, largura = 12),
  cs("borda_cor", "cor", "Cor da borda", NULL, se = "{borda}"),
  cs("borda_pt", "num", "Grossura da borda (pt)", NULL, min = 0, passo = 0.25, padrao = 0.6, se = "{borda}"),
  cs("borda_tipo", "sel", "Tipo da borda", NULL, opcoes = .LINHAS, padrao = "solid", se = "{borda}"),
  cs("cantos", "sel", "Cantos", NULL, opcoes = c("Arredondados" = "arredondado", "Retos" = "reto"), padrao = "arredondado"),
  cs("raio_pt", "num", "Arredondamento dos cantos (pt)", NULL, min = 0, passo = 1, padrao = 5, se = "{cantos} == 'arredondado'"),
  cs("margem_pt", "num", "Folga entre o texto e a borda (pt)", NULL, min = 0, passo = 1, padrao = 5),
  cs("sombra", "chk", "Sombra atrás da caixa", NULL, largura = 12),
  cs("sombra_cor", "cor", "Cor da sombra", NULL, se = "{sombra}"),
  cs("sombra_opacidade", "num", "Opacidade da sombra", NULL, min = 0, max = 1, passo = 0.05, padrao = 0.3, se = "{sombra}"),
  cs("sombra_dx_pt", "num", "Sombra: para a direita (pt)", NULL, passo = 0.5, padrao = 3, se = "{sombra}"),
  cs("sombra_dy_pt", "num", "Sombra: para baixo (pt)", NULL, passo = 0.5, padrao = 3, se = "{sombra}"),
  cs("ajustes", "vec", "Quais ajustes entram (números)", "Ex.: 1, 3 = o 1º e o 3º ajuste do bloco. Vazio = todos.", mais = TRUE))
.campos_forma <- function(cs) list(
  cs("tipo", "sel", "Forma", NULL, opcoes = .TIPOS_FORMA, padrao = "texto", largura = 12),
  cs("texto", "txt", "Texto", "Aceita expoente e índice: m^{2}, H_{2}O. Para mudar de linha, escreva \\n.", largura = 12),
  cs("unidade", "sel", "Posição e tamanho em", "Fração da caixa do gráfico (0 a 1) ou na unidade dos eixos (para a forma acompanhar os dados).",
     opcoes = c("Fração da caixa do gráfico (0 a 1)" = "fracao", "Unidades dos eixos (dados)" = "dados"), padrao = "fracao", largura = 12),
  cs("x", "num", "Posição X", "Do centro da forma (ou do ponto escolhido abaixo).", padrao = 0.5, passo = 0.05, se = "{tipo} != 'poligono'"),
  cs("y", "num", "Posição Y", NULL, padrao = 0.5, passo = 0.05, se = "{tipo} != 'poligono'"),
  cs("largura", "num", "Largura", "Vazio = a caixa de texto se ajusta ao texto.", min = 0, passo = 0.05, se = "{tipo} != 'poligono'"),
  cs("altura", "num", "Altura", NULL, min = 0, passo = 0.05, se = "{tipo} != 'poligono'"),
  cs("vertices", "txt", "Vértices do polígono", "Pares x,y separados por ponto e vírgula. Ex.: 0.6,0.2; 0.9,0.2; 0.75,0.5 (na unidade escolhida acima).", se = "{tipo} == 'poligono'", largura = 12),
  cs("tamanho_pt", "num", "Tamanho do texto (pt)", "Vazio = o tamanho base.", min = 4, passo = 0.5),
  cs("cor_texto", "cor", "Cor do texto"),
  cs("negrito", "chk", "Negrito"),
  cs("italico", "chk", "Itálico"),
  cs("alinhamento", "sel", "Alinhamento do texto", NULL, opcoes = c("Centralizado" = "centro", "À esquerda" = "esquerda", "À direita" = "direita"), padrao = "centro"),
  cs("angulo", "num", "Girar (graus)", NULL, passo = 5),
  cs("fundo", "cor", "Cor do preenchimento", "Vazio = azul claro (formas) ou sem fundo (caixa de texto)."),
  cs("sem_fundo", "chk", "Sem preenchimento (só o contorno)", NULL, largura = 12),
  cs("opacidade_fundo", "num", "Opacidade do preenchimento", NULL, min = 0, max = 1, passo = 0.05, padrao = 1),
  cs("borda_cor", "cor", "Cor da borda"),
  cs("borda_pt", "num", "Grossura da borda (pt)", NULL, min = 0, passo = 0.25),
  cs("borda_tipo", "sel", "Tipo da borda", NULL, opcoes = c("(padrão)" = "", .LINHAS), padrao = ""),
  cs("raio_pt", "num", "Arredondamento dos cantos (pt)", "Dá cantos arredondados a caixas e retângulos.", min = 0, passo = 1, se = "{tipo} == 'texto' || {tipo} == 'retangulo' || {tipo} == 'retangulo_arredondado'"),
  cs("margem_pt", "num", "Folga entre o texto e a borda (pt)", NULL, min = 0, passo = 1, mais = TRUE),
  cs("sombra", "chk", "Sombra atrás da forma", NULL, largura = 12),
  cs("sombra_cor", "cor", "Cor da sombra", NULL, se = "{sombra}"),
  cs("sombra_opacidade", "num", "Opacidade da sombra", NULL, min = 0, max = 1, passo = 0.05, padrao = 0.3, se = "{sombra}"),
  cs("sombra_dx_pt", "num", "Sombra: para a direita (pt)", NULL, passo = 0.5, padrao = 3, se = "{sombra}"),
  cs("sombra_dy_pt", "num", "Sombra: para baixo (pt)", NULL, passo = 0.5, padrao = 3, se = "{sombra}"),
  cs("camada", "sel", "Camada", "Na frente dos dados ou atrás deles.", opcoes = c("Na frente dos dados" = "frente", "Atrás dos dados" = "atras"), padrao = "frente", mais = TRUE),
  cs("ancora", "sel", "Qual ponto da forma fica em (x, y)", NULL, opcoes = c("No centro" = "centro", .CANTOS9[names(.CANTOS9) != "No centro"]), padrao = "centro", mais = TRUE,
     se = "{tipo} != 'poligono'"))

.campos_imagem <- function(cs) list(
  cs("arquivo", "arquivo", "Arquivo da figura (PNG ou JPEG)", "PNG com fundo transparente funciona bem (logotipo, esquema). A figura fica só nesta sessão: não vai no modelo copiado nem na configuração salva; anexe de novo ao reabrir o app.", largura = 12),
  cs("unidade", "sel", "Posição e tamanho em", "Fração da caixa do gráfico (0 a 1) ou na unidade dos eixos (a figura acompanha os dados).",
     opcoes = c("Fração da caixa do gráfico (0 a 1)" = "fracao", "Unidades dos eixos (dados)" = "dados"), padrao = "fracao", largura = 12),
  cs("x", "num", "Posição X", "Do ponto da figura escolhido abaixo.", padrao = 0.5, passo = 0.05),
  cs("y", "num", "Posição Y", NULL, padrao = 0.5, passo = 0.05),
  cs("largura", "num", "Largura", "Vazio = 0.2 da caixa do gráfico.", min = 0, passo = 0.05),
  cs("altura", "num", "Altura", "Vazio = mantém a proporção da figura. Em unidades dos eixos, largura e altura são obrigatórias.", min = 0, passo = 0.05),
  cs("ancora", "sel", "Qual ponto da figura fica em (x, y)", NULL, opcoes = c("No centro" = "centro", .CANTOS9[names(.CANTOS9) != "No centro"]), padrao = "centro"),
  cs("opacidade", "num", "Opacidade (0 a 1)", NULL, min = 0, max = 1, passo = 0.05, padrao = 1),
  cs("angulo", "num", "Girar (graus)", NULL, passo = 5),
  cs("borda_cor", "cor", "Cor do contorno", "Preencha para pôr um contorno em volta da figura."),
  cs("borda_pt", "num", "Grossura do contorno (pt)", NULL, min = 0, passo = 0.25),
  cs("borda_tipo", "sel", "Tipo do contorno", NULL, opcoes = c("(padrão)" = "", .LINHAS), padrao = ""),
  cs("camada", "sel", "Camada", "Na frente dos dados ou atrás deles.", opcoes = c("Na frente dos dados" = "frente", "Atrás dos dados" = "atras"), padrao = "frente", mais = TRUE))

# Os cartões de cada lista (variável do painel): prefixo, quantidade, nome do item e a função dos campos.
SLOTS <- list(
  ajustes = list(pref = "aj", n = 4, defs = .campos_ajuste, usar = "Usar este ajuste"),
  marcas_estatisticas = list(pref = "mk", n = 3, defs = .campos_marca, usar = "Usar estes traços"),
  caixas_estatisticas = list(pref = "cx", n = 3, defs = .campos_caixa, usar = "Usar esta caixa"),
  formas = list(pref = "fm", n = 6, defs = .campos_forma, usar = "Usar esta forma"),
  imagens = list(pref = "im", n = 3, defs = .campos_imagem, usar = "Usar esta figura"))
.NOMES_CARTAO <- list(
  ajustes = c("Ajuste 1", "Ajuste 2", "Ajuste 3", "Ajuste 4"),
  marcas_estatisticas = c("Traços de média e desvio 1", "Traços de média e desvio 2", "Traços de média e desvio 3"),
  caixas_estatisticas = c("Caixa de estatística 1", "Caixa de estatística 2", "Caixa de estatística 3"),
  formas = c("Forma 1", "Forma 2", "Forma 3", "Forma 4", "Forma 5", "Forma 6"),
  imagens = c("Figura 1", "Figura 2", "Figura 3"))
grupos_slot <- function(g) lapply(seq_len(SLOTS[[g]]$n), function(k) .cartao(SLOTS[[g]]$pref, k, .NOMES_CARTAO[[g]][k], SLOTS[[g]]$defs, SLOTS[[g]]$usar))

ESPEC <- list(
  bloco("dados", "Dados e tipo de gráfico",
        "Escolha o arquivo, o tipo de gráfico e quais colunas entram.",
        "O arquivo é um CSV com uma linha de títulos. A 1ª coluna costuma ser o eixo X e as demais, as séries (eixo Y).",
        list(
          campo("tipo_grafico", "sel", "Tipo de gráfico", "Linha, pontos, barras, pizza...", opcoes = .TIPOS, padrao = "linha_pontos", largura = 12),
          campo("coluna_x", "colx", "Coluna do eixo X", "Vazio = a 1ª coluna."),
          campo("colunas_y", "colsy", "Colunas do eixo Y (séries)", "Vazio = todas as outras colunas numéricas.")
        )),
  bloco("intervalos", "Intervalos dos eixos",
        "Onde cada eixo começa e termina, de quanto em quanto aparecem os traços e como eles são.",
        "Para mostrar todos os anos, coloque 1 em \"Distância entre os traços\" do eixo X. Para tirar os traços pequenos, coloque 0.",
        c(list(campo("moldura_espessura_pt", "num", "Grossura da moldura (pt)",
                     "Os traços e as linhas dos eixos seguem esta grossura (tudo igual). Para um traço diferente, use \"Mais opções\" de cada eixo.",
                     min = 0, passo = 0.25),
               campo("moldura_cor", "cor", "Cor da moldura"),
               campo("ticks_espelhados", "chk", "Repetir os traços nos lados de cima e da direita",
                     "Só vale com a moldura fechada (bloco 10).", largura = 12))),
        grupos = list(list(titulo = "Eixo X (horizontal)", campos = .campos_intervalo("x")),
                      list(titulo = "Eixo Y (vertical)", campos = .campos_intervalo("y")))),
  bloco("escala", "Escala",
        "O tipo de escala de cada eixo e a folga nas pontas.",
        "A folga nas pontas resolve o ponto cortado pela metade na borda do gráfico.",
        list(campo("recortar_nos_limites", "chk", "Cortar o que passar da moldura",
                   "Desligue para os pontos nas pontas aparecerem inteiros, mesmo sobre a moldura.", largura = 12)),
        grupos = list(list(titulo = "Eixo X", campos = .campos_escala("x")),
                      list(titulo = "Eixo Y", campos = .campos_escala("y")))),
  bloco("numeros", "Números e títulos",
        "Os títulos do gráfico e dos eixos e como os números dos eixos aparecem.",
        "Para dividir por mil e escrever ×10³ no título: \"Dividir os números por\" = 1000 e título com 10^{3}.",
        list(campo("titulo_grafico", "txt", "Título do gráfico", NULL, largura = 12),
             campo("titulo_grafico_negrito", "chk", "Título do gráfico em negrito"),
             campo("eixos_titulo_negrito", "chk", "Títulos dos eixos em negrito")),
        grupos = list(list(titulo = "Eixo X", campos = .campos_numeros("x")),
                      list(titulo = "Eixo Y", campos = .campos_numeros("y")))),
  bloco("grade", "Grade (linhas de fundo)",
        "Linhas de fundo nos traços grandes e/ou nos pequenos: tracejadas, coloridas e transparentes, cada grupo com o seu estilo.",
        "A grade dos traços pequenos precisa de traços pequenos: no bloco 2, \"Traços pequenos entre dois grandes\" deve ser 1 ou mais.",
        list(),
        grupos = list(
          list(titulo = "Grade nos traços grandes", campos = list(
            campo("grade_x", "chk", "Grade vertical (nos traços do X)"), campo("grade_y", "chk", "Grade horizontal (nos traços do Y)"),
            campo("grade_tipo", "sel", "Tipo de linha", NULL, opcoes = .LINHAS),
            campo("grade_cor", "cor", "Cor"),
            campo("grade_espessura_pt", "num", "Grossura (pt)", NULL, min = 0, passo = 0.1),
            campo("grade_opacidade", "num", "Opacidade (0 a 1)", "1 = sólida; 0.3 = bem transparente.", min = 0, max = 1, passo = 0.05))),
          list(titulo = "Grade nos traços pequenos", campos = list(
            campo("grade_menor_x", "chk", "Grade vertical (nos traços pequenos do X)"), campo("grade_menor_y", "chk", "Grade horizontal (nos traços pequenos do Y)"),
            campo("grade_menor_tipo", "sel", "Tipo de linha", NULL, opcoes = .LINHAS),
            campo("grade_menor_cor", "cor", "Cor"),
            campo("grade_menor_espessura_pt", "num", "Grossura (pt)", NULL, min = 0, passo = 0.1),
            campo("grade_menor_opacidade", "num", "Opacidade (0 a 1)", NULL, min = 0, max = 1, passo = 0.05))))),
  bloco("quebra", "Quebra do eixo Y",
        "Corta o trecho vazio entre grupos de dados muito distantes.",
        "Ligue a quebra e use o botão \"Achar o maior vazio\" para o app sugerir o trecho a omitir; depois ajuste à mão. Cada parte do eixo pode ter o seu próprio intervalo e traços pequenos. Onde o eixo começa (embaixo) e termina (em cima) é o \"Eixo Y começa/termina em\" do bloco 2; a quebra de eixo só existe no Y.",
        list(campo("quebra_ativar", "chk", "Usar quebra no eixo Y", largura = 12)),
        grupos = list(
          list(titulo = "Onde cortar", se = .SE_QUEBRA, campos = list(
            campo("quebra_estilo", "sel", "Estilo", "Contínuo: uma moldura só com as barras //. Separado: dois gráficos.",
                  opcoes = c("Separado (dois gráficos)" = "separado", "Contínuo (uma moldura só)" = "continuo"), largura = 12),
            campo("quebra_de", "num", "Trecho omitido: de", "Vazio = o app acha o maior vazio."),
            campo("quebra_ate", "num", "Trecho omitido: até"),
            campo("quebra_proporcao_superior", "num", "Altura da parte de cima (0 a 1)", "0.35 = a parte de cima ocupa 35% da altura.", min = 0.1, max = 0.9, passo = 0.05))),
          list(titulo = "Eixo esquerdo: cada parte", se = .SE_QUEBRA, campos = list(
            campo("quebra_y_intervalo_inferior", "num", "Parte de baixo: distância entre os traços", "Os traços começam no início do eixo."),
            campo("quebra_y_intervalo_superior", "num", "Parte de cima: distância entre os traços", "Os traços começam no fim do trecho omitido."),
            campo("quebra_y_ticks_menores_inferior", "int", "Parte de baixo: traços pequenos", "Entre dois traços grandes. 0 = sem.", min = 0, max = 20),
            campo("quebra_y_ticks_menores_superior", "int", "Parte de cima: traços pequenos", NULL, min = 0, max = 20))),
          list(titulo = "Eixo direito (Y2): trecho omitido e cada parte", se = .SE_QUEBRA_Y2, campos = list(
            campo("quebra_y2_de", "num", "Omitido de (valor do eixo DIREITO)", "Use números da escala do eixo direito (não os do esquerdo). Vazio = acompanha a posição do eixo esquerdo."),
            campo("quebra_y2_ate", "num", "Omitido até (valor do eixo DIREITO)"),
            campo("quebra_y2_intervalo_inferior", "num", "Parte de baixo: distância entre os traços"),
            campo("quebra_y2_intervalo_superior", "num", "Parte de cima: distância entre os traços"),
            campo("quebra_y2_ticks_menores_inferior", "int", "Parte de baixo: traços pequenos", NULL, min = 0, max = 20),
            campo("quebra_y2_ticks_menores_superior", "int", "Parte de cima: traços pequenos", NULL, min = 0, max = 20))),
          list(titulo = "Barras \"//\" e espaço", se = .SE_QUEBRA, campos = list(
            campo("quebra_marcas", "chk", "Desenhar as barras \"//\" da quebra", NULL, largura = 12),
            campo("quebra_marca_largura_pt", "num", "Barra: largura (pt)", "Menor = não encosta nos números. Padrão 2.5.", min = 0.5, passo = 0.5),
            campo("quebra_marca_altura_pt", "num", "Barra: altura (pt)", "Padrão 3.", min = 0.5, passo = 0.5),
            campo("quebra_espaco_pt", "num", "Espaço entre as partes (pt)", "Só no estilo separado.", min = 0),
            campo("quebra_ligar_pontos", "chk", "Ligar os pontos através da quebra", "Desligue para cada parte mostrar só os seus pontos.", largura = 12)))
        )),
  bloco("y2", "Eixo Y da direita (Y2)",
        "Coloca outras séries num segundo eixo vertical, com escala, cor e intervalos próprios. O eixo X continua o mesmo.",
        "No mesmo CSV: marque aqui quais colunas ficam à direita. Ex.: população no eixo direito e PIB no esquerdo. As opções são as mesmas do eixo Y da esquerda; o que ficar vazio segue o eixo esquerdo.",
        list(campo("y2_series", "colsy2", "Séries no eixo direito", "Escolha entre as colunas Y.", largura = 12)),
        grupos = list(
          list(titulo = "Cor e legenda", se = .SE_Y2, campos = list(
            campo("y2_cor", "cor", "Cor das séries e do eixo", "Pinta as séries da direita e o eixo (números, título e traços)."),
            campo("y2_cor_eixo", "cor", "Só a cor do eixo", "Pinta só o eixo, sem mudar as séries."),
            campo("y2_igual_y1", "chk", "Eixo direito no mesmo estilo do esquerdo", "Números, título e traços no mesmo estilo (preto).", largura = 12),
            campo("y2_legenda_sufixo", "txt", "Texto somado ao nome na legenda", "Ex.: \" (eixo dir.)\"", largura = 12))),
          list(titulo = "Intervalos e traços do eixo direito", se = .SE_Y2, campos = c(.campos_intervalo_y2(),
            list(campo("y2_folga_pct", "num", "Folga nas pontas (%)", "Espaço extra além do primeiro e do último valor.", min = 0, max = 50, passo = 1, mais = TRUE)))),
          list(titulo = "Números e título do eixo direito", se = .SE_Y2, campos = .campos_numeros_y2()),
          list(titulo = "Só converter a unidade (sem séries novas)", campos = list(
            campo("y2_fator", "num", "Multiplicar por", "Mostra o MESMO dado em outra unidade no eixo direito (y2 = fator × y + deslocamento). Ex.: °C para °F: fator 1.8 e deslocamento 32."),
            campo("y2_deslocamento", "num", "Somar", NULL))))),
  bloco("cores", "Cores, linhas e símbolos",
        "A cor, a forma e a grossura de cada série: tudo junto ou série por série.",
        "Linhas e pontos têm grossuras separadas. Para uma forma só (tudo quadrado), escolha \"Todas iguais\".",
        list(campo("cores_paleta", "selbusca", "Paleta de cores", "A cor automática de cada série. Dá para criar a sua logo abaixo (\"Criar a minha paleta\").",
                   opcoes = opcoes_paletas(), padrao = "cinabro", largura = 12),
             campo("linha_espessura_pt", "num", "Grossura das linhas (pt)", NULL, min = 0, passo = 0.25),
             campo("simbolo_tamanho_pt", "num", "Tamanho dos pontos (pt)", NULL, min = 0, passo = 0.5),
             campo("simbolo_borda_pt", "num", "Grossura do contorno dos pontos (pt)", NULL, min = 0, passo = 0.25),
             campo("simbolo_modo", "sel", "Formas dos pontos", "Cada série com uma forma diferente, ou todas iguais.",
                   opcoes = c("Cada série com uma forma diferente" = "variar", "Todas iguais" = "igual"), padrao = "variar"),
             campo("simbolo_forma", "sel", "Forma", NULL, opcoes = .FORMAS, padrao = "circulo", se = "input.simbolo_modo == 'igual'"),
             campo("simbolos_ordem", "selmulti", "Quais formas usar, na ordem", "Vazio = a sequência padrão.", opcoes = .FORMAS,
                   se = "input.simbolo_modo == 'variar'", largura = 12),
             campo("simbolo_preenchimento", "sel", "Preenchimento dos pontos", NULL,
                   opcoes = c("Da cor da série" = "serie", "Branco" = "branco", "Vazio" = "vazio"), padrao = "serie", mais = TRUE),
             campo("esfera_luz", "sel", "Luz da esfera (3D)", "De onde vem o brilho das esferas.",
                   opcoes = c("Embaixo, à esquerda" = "-0.35,-0.45", "Em cima, à esquerda" = "-0.35,0.45",
                              "Em cima, à direita" = "0.35,0.45", "Embaixo, à direita" = "0.35,-0.45"), padrao = "-0.35,-0.45", mais = TRUE),
             campo("cores_gradiente", "chk", "Degradê em barras e áreas", NULL, mais = TRUE),
             campo("cores_gradiente_cor2", "cor", "Cor final do degradê", NULL, mais = TRUE))),
  bloco("fonte", "Fonte e tamanhos de texto",
        "A fonte de tudo e o tamanho de cada texto.",
        "A Barlow é a fonte oficial e já vem no template. O tamanho base vale para tudo; os tamanhos separados têm prioridade.",
        list(campo("fonte", "selbusca", "Fonte", "Digite para procurar: a lista traz todas as fontes que o systemfonts enxerga neste computador. Dá para adicionar uma fonte de arquivo logo abaixo.",
                   opcoes = .FONTES, padrao = "Barlow", largura = 12),
             campo("negrito_geral", "chk", "Tudo em negrito", "TODOS os nomes e números: títulos, eixos, legenda, textos dos dados.", largura = 12),
             campo("tamanho_texto_pt", "num", "Tamanho base (pt)", "Vale para todo o texto.", min = 4, max = 60, passo = 1),
             campo("cor_texto", "cor", "Cor do texto"),
             campo("titulo_grafico_tamanho_pt", "num", "Título do gráfico (pt)", NULL, min = 4, passo = 1, mais = TRUE),
             campo("x_titulo_tamanho_pt", "num", "Título do eixo X (pt)", NULL, min = 4, passo = 1, mais = TRUE),
             campo("y_titulo_tamanho_pt", "num", "Título do eixo Y (pt)", NULL, min = 4, passo = 1, mais = TRUE),
             campo("x_numeros_tamanho_pt", "num", "Números do eixo X (pt)", NULL, min = 4, passo = 1, mais = TRUE),
             campo("y_numeros_tamanho_pt", "num", "Números do eixo Y (pt)", NULL, min = 4, passo = 1, mais = TRUE),
             campo("legenda_texto_tamanho_pt", "num", "Nomes na legenda (pt)", NULL, min = 4, passo = 1, mais = TRUE),
             campo("legenda_titulo_tamanho_pt", "num", "Título da legenda (pt)", NULL, min = 4, passo = 1, mais = TRUE),
             campo("rotulos_dados_tamanho_pt", "num", "Texto junto dos pontos/barras (pt)", NULL, min = 4, passo = 1, mais = TRUE))),
  bloco("moldura", "Moldura e tamanho do gráfico",
        "A moldura e o tamanho da caixa do gráfico. Com a caixa fixa, todos os gráficos saem com a caixa do mesmo tamanho.",
        "Mexer em números, títulos ou legenda move esses textos, não o gráfico; a página se ajusta.",
        list(campo("caixa_fechada", "chk", "Moldura nos 4 lados", "Desmarcado: só os eixos esquerdo e inferior.", largura = 12),
             campo("painel_fixo", "chk", "Caixa do gráfico de tamanho fixo", "Desmarque para a caixa ocupar o que sobra da página (bloco 12).", largura = 12),
             campo("painel_largura_cm", "num", "Largura da caixa (cm)", "Vazio = 10 cm.", min = 1, passo = 0.5, se = "input.painel_fixo"),
             campo("painel_altura_cm", "num", "Altura da caixa (cm)", "Vazio = 7.5 cm.", min = 1, passo = 0.5, se = "input.painel_fixo"))),
  bloco("legenda", "Legenda: posição, fundo, borda e sombra",
        "Onde a legenda fica, se os itens ficam em pé ou deitados, como ela é e o quanto ela pode crescer sem sair da caixa.",
        "Arraste a caixa tracejada sobre a prévia para mudar a posição, e a alça da direita para mudar a largura. Ou digite a posição (0 a 1) ou a coordenada do eixo.",
        list(),
        grupos = list(
          list(titulo = "Itens: texto e disposição", campos = list(
            campo("legenda_mostrar", "tri", "Mostrar a legenda", NULL, opcoes = c("Automático" = "auto", "Sim" = "sim", "Não" = "nao"), padrao = "auto"),
            campo("legenda_titulo", "txt", "Título da legenda", NULL),
            campo("legenda_negrito", "chk", "Nomes da legenda em negrito"),
            campo("legenda_titulo_negrito", "chk", "Título da legenda em negrito"),
            campo("legenda_direcao", "sel", "Orientação: vertical ou horizontal", "Vertical: um item embaixo do outro. Horizontal: todos lado a lado, numa linha. Dá para trocar a qualquer momento.",
                  opcoes = c("Automática" = "", "Vertical (um embaixo do outro)" = "vertical", "Horizontal (lado a lado)" = "horizontal"), padrao = "", largura = 12),
            campo("legenda_n_colunas", "int", "Número de colunas", "Divide os itens em colunas. Ex.: 6 itens em 2 colunas = 3 linhas.", min = 1, max = 12),
            campo("legenda_n_linhas", "int", "Número de linhas", "Divide os itens em linhas. Ex.: horizontal com 2 linhas.", min = 1, max = 12),
            campo("legenda_inverter_ordem", "chk", "Inverter a ordem dos itens", NULL, mais = TRUE),
            campo("legenda_tamanho_chave_pt", "num", "Tamanho do quadradinho (pt)", NULL, min = 4, mais = TRUE),
            campo("legenda_espacamento_pt", "num", "Espaço entre os itens (pt)", NULL, min = 0, mais = TRUE))),
          list(titulo = "Posição", campos = list(
            campo("legenda_posicao", "sel", "Posição", "Dentro do gráfico ou fora, em um dos lados.",
                  opcoes = c("Dentro do gráfico" = "dentro", "Fora, à direita" = "direita", "Fora, à esquerda" = "esquerda",
                             "Fora, em cima" = "topo", "Fora, embaixo" = "base"), padrao = "dentro"),
            campo("legenda_canto", "sel", "Canto (legenda dentro)", "Atalho para um canto da caixa.", opcoes = .CANTOS, padrao = "",
                  se = "input.legenda_posicao == 'dentro'"),
            campo("legenda_x", "num", "Posição horizontal (0 a 1)", "0 = encostada na esquerda, 1 = na direita. Dá para ARRASTAR a caixa tracejada sobre a prévia.", min = 0, max = 1, passo = 0.01,
                  se = "input.legenda_posicao == 'dentro'"),
            campo("legenda_y", "num", "Posição vertical (0 a 1)", "0 = embaixo, 1 = em cima.", min = 0, max = 1, passo = 0.01, se = "input.legenda_posicao == 'dentro'"),
            campo("legenda_x_dados", "num", "OU: posição X na coordenada do eixo", "Valor do eixo X onde fica o canto superior esquerdo da legenda (ex.: o ano 2016). Vale no lugar da posição acima.",
                  se = "input.legenda_posicao == 'dentro'"),
            campo("legenda_y_dados", "num", "OU: posição Y na coordenada do eixo", "Valor do eixo Y (esquerdo) do mesmo canto (ex.: 600000).", se = "input.legenda_posicao == 'dentro'"),
            campo("legenda_distancia_pt", "num", "Distância da borda (pt)", "Com um canto escolhido: afasta a legenda da moldura.", min = 0, passo = 1,
                  se = "input.legenda_posicao == 'dentro'"),
            campo("legenda_alinhar", "sel", "Alinhamento (legenda fora)", NULL,
                  opcoes = c("Centro" = "", "Topo / esquerda" = "inicio", "Base / direita" = "fim"), padrao = "", mais = TRUE))),
          list(titulo = "Tamanho da caixa", campos = list(
            campo("legenda_largura_pt", "num", "Largura da caixa da legenda (pt)",
                  "Como esticar uma caixa solta: a legenda escala até ter essa largura e os símbolos acompanham. Vazio = automática.", min = 20, passo = 5),
            campo("legenda_escala", "num", "Tamanho da legenda (escala)", "1 = normal; 0.8 = menor; 1.2 = maior. Símbolos e linhas acompanham.", min = 0.2, max = 3, passo = 0.1),
            campo("legenda_espaco_texto_pt", "num", "Espaço entre o símbolo e o nome (pt)", "Menor = legenda mais compacta.", min = 0, passo = 1),
            campo("legenda_largura_chave_pt", "num", "Largura do espaço do símbolo (pt)", NULL, min = 2, passo = 1),
            campo("legenda_ajustar_caixa", "chk", "Reduzir sozinha se passar da caixa", NULL, largura = 12),
            campo("legenda_margem_interna_pt", "vec", "Folga dentro da caixa (pt)", "4 números: em cima, direita, embaixo, esquerda. Ex.: 6, 8, 6, 8", mais = TRUE))),
          list(titulo = "Fundo, borda e sombra", campos = list(
            campo("legenda_fundo", "cor", "Cor de fundo", "Preencha para dar fundo à caixa da legenda."),
            campo("legenda_fundo_opacidade", "num", "Opacidade do fundo (0 a 1)", NULL, min = 0, max = 1, passo = 0.05),
            campo("legenda_borda", "chk", "Borda na caixa da legenda"),
            campo("legenda_borda_cor", "cor", "Cor da borda"),
            campo("legenda_borda_espessura_pt", "num", "Grossura da borda (pt)", NULL, min = 0, passo = 0.25),
            campo("legenda_borda_tipo", "sel", "Tipo da borda", NULL, opcoes = .LINHAS),
            campo("legenda_sombra", "chk", "Sombra atrás da legenda", "Com fundo transparente a caixa fica branca."),
            campo("legenda_sombra_cor", "cor", "Cor da sombra"),
            campo("legenda_sombra_opacidade", "num", "Opacidade da sombra", NULL, min = 0, max = 1, passo = 0.05),
            campo("legenda_sombra_dx", "num", "Sombra: para a direita (pt)", NULL, passo = 0.5),
            campo("legenda_sombra_dy", "num", "Sombra: para baixo (pt)", NULL, passo = 0.5))))),
  bloco("exportacao", "Exportação",
        "O tipo de arquivo, o tamanho e a qualidade. Os botões de baixar ficam ao lado do gráfico.",
        "Para jornais e artigos use 600 dpi. PNG/TIFF/SVG usam a Barlow direto; PDF precisa da fonte instalada no computador.",
        list(campo("formatos", "chkgrupo", "Tipo de arquivo", "Marque um ou mais: aparece um botão de baixar para cada tipo escolhido. PNG/JPEG/TIFF são imagens; SVG, PDF e EMF são vetoriais (editáveis).",
                   opcoes = .FORMATOS, largura = 12),
             campo("fundo_transparente", "chk", "Fundo transparente", "Sem o branco atrás do gráfico (PNG, TIFF, SVG, PDF). O JPEG não tem transparência.", largura = 12),
             campo("dpi", "int", "Resolução (dpi)", "300 = bom para relatório; 600 = publicação. Vale para PNG, TIFF e JPEG.", min = 72, max = 1200, largura = 12),
             campo("ajustar_pagina", "chk", "Ajustar a página ao conteúdo", "Com a caixa de tamanho fixo (bloco 10): a página cresce ou encolhe para caber números, títulos e legenda, sem cortar.",
                   se = "input.painel_fixo", largura = 12),
             campo("largura_cm", "num", "Largura da página (cm)", "Vale quando a caixa NÃO é fixa ou \"Ajustar a página\" está desmarcado.", min = 2, passo = 0.5,
                   se = "!input.painel_fixo || !input.ajustar_pagina"),
             campo("altura_cm", "num", "Altura da página (cm)", NULL, min = 2, passo = 0.5, se = "!input.painel_fixo || !input.ajustar_pagina"),
             campo("nome_arquivo", "txt", "Nome do arquivo", "Sem extensão. Ex.: figura_1", largura = 12))),
  bloco("estatistica", "Ajustes e estatísticas",
        "Curvas de ajuste (linear, exponencial, sua fórmula...), traços de média e desvio e caixas com números e testes.",
        "Funciona com gráficos de pontos, linhas e áreas (eixo X numérico). Os cálculos usam todos os seus dados, até os que a quebra de eixo esconde. Ligue um cartão, escolha a série e o tipo; as caixas de estatística aceitam média, DP, EP, soma, R², equação, valor de p, ANOVA e mais.",
        grupos = c(
          list(list(titulo = "Curvas de ajuste", campos = list())),
          grupos_slot("ajustes"),
          list(list(titulo = "Traços de média, desvio padrão e erro padrão", campos = list())),
          grupos_slot("marcas_estatisticas"),
          list(list(titulo = "Caixas de estatística (como a legenda)", campos = list())),
          grupos_slot("caixas_estatisticas"))),
  bloco("formas", "Caixas de texto e polígonos",
        "Caixas de texto, retângulos, elipses, triângulos, polígonos livres e figuras anexadas (PNG ou JPEG), com borda, cor, sombra e posição à sua escolha.",
        "Em \"Fração da caixa\" a forma ou a figura fica sempre no mesmo lugar do quadro; em \"Unidades dos eixos\" ela acompanha os dados (marca uma região do gráfico). Para anexar uma figura (logotipo, esquema, foto), use os cartões \"Figura\", no fim deste bloco.",
        grupos = c(grupos_slot("formas"), list(list(titulo = "Figuras anexadas (PNG ou JPEG)", campos = list())), grupos_slot("imagens")))
)

ESPEC_CAMPOS <- unlist(lapply(ESPEC, function(b) c(b$campos, unlist(lapply(b$grupos, function(g) g$campos), recursive = FALSE))),
                       recursive = FALSE)
names(ESPEC_CAMPOS) <- vapply(ESPEC_CAMPOS, function(x) x$id, "")
