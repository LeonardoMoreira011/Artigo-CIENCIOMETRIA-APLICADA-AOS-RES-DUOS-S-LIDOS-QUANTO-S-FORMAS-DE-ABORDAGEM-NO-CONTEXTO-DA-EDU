# =============================================================================
#  R/18_painel.R — PAINEL DE AJUSTES: variáveis simples (escala, ticks, grade, quebra, cores...)
# =============================================================================
#  O painel (arquivo painel_de_ajustes.R ou PARTE 3 do script único) define variáveis como
#  x_intervalo <- 1 ou grade_tipo <- "dashed". aplicar_painel() copia as que não são NULL para o
#  cfg. NULL = "não mexer" (vale o padrão do template).
# =============================================================================

# Variável do painel -> c(bloco do cfg, parâmetro). Valor copiado como está.
.PAINEL_MAPA <- list(
  # tipo e colunas
  tipo_grafico = c("grafico", "tipo"), coluna_x = c("grafico", "coluna_x"), colunas_y = c("grafico", "colunas_y"),
  # escala
  x_inicio = c("eixo_x", "inicio"), x_fim = c("eixo_x", "fim"), x_folga_pct = c("eixo_x", "margem_percentual"),
  x_escala = c("eixo_x", "escala"), x_inverter = c("eixo_x", "inverter"),
  y_inicio = c("eixo_y", "inicio"), y_fim = c("eixo_y", "fim"), y_folga_pct = c("eixo_y", "margem_percentual"),
  y_escala = c("eixo_y", "escala"), y_inverter = c("eixo_y", "inverter"),
  recortar_nos_limites = c("caixa", "recortar"),
  # ticks
  x_primeiro_tick = c("eixo_x", "primeiro_tick"), x_ticks_menores = c("eixo_x", "n_menores"),
  x_ticks_direcao = c("eixo_x", "direcao_maiores"), x_ticks_menores_direcao = c("eixo_x", "direcao_menores"),
  x_ticks_comprimento_pt = c("eixo_x", "comprimento_maiores_pt"),
  x_ticks_menores_comprimento_pt = c("eixo_x", "comprimento_menores_pt"),
  y_primeiro_tick = c("eixo_y", "primeiro_tick"), y_ticks_menores = c("eixo_y", "n_menores"),
  y_ticks_direcao = c("eixo_y", "direcao_maiores"), y_ticks_menores_direcao = c("eixo_y", "direcao_menores"),
  y_ticks_comprimento_pt = c("eixo_y", "comprimento_maiores_pt"),
  y_ticks_menores_comprimento_pt = c("eixo_y", "comprimento_menores_pt"),
  ticks_espelhados = c("caixa", "ticks_espelhados"),
  x_ticks_espessura_pt = c("eixo_x", "espessura_ticks_pt"), y_ticks_espessura_pt = c("eixo_y", "espessura_ticks_pt"),
  x_ticks_cor = c("eixo_x", "cor_ticks"), y_ticks_cor = c("eixo_y", "cor_ticks"),
  x_linha_espessura_pt = c("eixo_x", "espessura_linha_pt"), y_linha_espessura_pt = c("eixo_y", "espessura_linha_pt"),
  moldura_espessura_pt = c("caixa", "espessura_pt"), moldura_cor = c("caixa", "cor"),
  # números e títulos
  x_titulo = c("eixo_x", "titulo"), y_titulo = c("eixo_y", "titulo"), titulo_grafico = c("titulos", "titulo"),
  titulo_grafico_negrito = c("titulos", "negrito_titulo"),
  x_dividir_por = c("eixo_x", "fator_divisao"), y_dividir_por = c("eixo_y", "fator_divisao"),
  x_casas_decimais = c("eixo_x", "casas_decimais"), y_casas_decimais = c("eixo_y", "casas_decimais"),
  x_notacao = c("eixo_x", "notacao"), y_notacao = c("eixo_y", "notacao"),
  x_rotacao_numeros = c("eixo_x", "rotacao_rotulos"), y_rotacao_numeros = c("eixo_y", "rotacao_rotulos"),
  x_mostrar_numeros = c("eixo_x", "mostrar_rotulos"), y_mostrar_numeros = c("eixo_y", "mostrar_rotulos"),
  # grade
  grade_x = c("grade", "maior_x"), grade_y = c("grade", "maior_y"), grade_cor = c("grade", "cor_maior"),
  grade_tipo = c("grade", "tipo_maior"), grade_espessura_pt = c("grade", "espessura_maior_pt"),
  grade_opacidade = c("grade", "opacidade_maior"),
  grade_menor_x = c("grade", "menor_x"), grade_menor_y = c("grade", "menor_y"),
  grade_menor_cor = c("grade", "cor_menor"), grade_menor_tipo = c("grade", "tipo_menor"),
  grade_menor_espessura_pt = c("grade", "espessura_menor_pt"), grade_menor_opacidade = c("grade", "opacidade_menor"),
  # quebra
  quebra_de = c("quebra", "de"), quebra_ate = c("quebra", "ate"), quebra_espaco_pt = c("quebra", "espaco_pt"),
  quebra_ligar_pontos = c("quebra", "ligar_atraves"), quebra_proporcao_superior = c("quebra", "proporcao_superior"),
  # cores, linhas e símbolos
  cores_paleta = c("cores", "paleta"), cores_gradiente_cor2 = c("cores", "gradiente_cor2"),
  linha_espessura_pt = c("serie_padrao",
                         "linha_espessura_pt"), simbolo_tamanho_pt = c("serie_padrao", "tamanho_simbolo_pt"),
  # texto
  fonte = c("texto", "fonte"), tamanho_texto_pt = c("texto", "tamanho_base_pt"), cor_texto = c("texto", "cor"),
  titulo_grafico_tamanho_pt = c("titulos", "tamanho_titulo_pt"),
  x_titulo_tamanho_pt = c("eixo_x", "tamanho_titulo_pt"), y_titulo_tamanho_pt = c("eixo_y", "tamanho_titulo_pt"),
  x_numeros_tamanho_pt = c("eixo_x", "tamanho_rotulos_pt"), y_numeros_tamanho_pt = c("eixo_y", "tamanho_rotulos_pt"),
  legenda_texto_tamanho_pt = c("legenda",
                               "tamanho_texto_pt"), legenda_titulo_tamanho_pt = c("legenda", "tamanho_titulo_pt"),
  # legenda e moldura
  legenda_mostrar = c("legenda", "mostrar"), legenda_posicao = c("legenda", "posicao"),
  legenda_x = c("legenda", "dentro_x"), legenda_y = c("legenda", "dentro_y"), legenda_titulo = c("legenda", "titulo"),
  caixa_fechada = c("caixa", "fechada"),
  # exportação
  largura_cm = c("exportacao", "largura"), altura_cm = c("exportacao", "altura"), dpi = c("exportacao", "dpi"),
  formatos = c("exportacao", "formatos"), nome_arquivo = c("exportacao", "nome_arquivo"),
  pasta_saida = c("exportacao", "pasta")
)

# Entra: cfg, o ambiente onde estão as variáveis do painel (padrão: o console/global) e, opcional, os
# dados (para a quebra automática). Sai: o cfg com os ajustes do painel; imprime o que foi aplicado.
aplicar_painel <- function(cfg, painel = globalenv(), dados = NULL) {
  cfg <- .completar_cfg(cfg)
  pega <- function(nome) get0(nome, envir = painel, inherits = FALSE)
  aplicados <- character(0)
  marca <- function(nome) aplicados <<- c(aplicados, nome)

  for (nome in names(.PAINEL_MAPA)) {
    v <- pega(nome)
    if (is.null(v)) next
    alvo <- .PAINEL_MAPA[[nome]]
    if (nome == "recortar_nos_limites") v <- isTRUE(v)
    cfg[[alvo[1]]][[alvo[2]]] <- v
    marca(nome)
  }
  # intervalo entre ticks maiores / ticks em posições escolhidas
  for (ax in c("x", "y")) {
    e <- paste0("eixo_", ax)
    iv <- pega(paste0(ax, "_intervalo")); tm <- pega(paste0(ax, "_ticks_manuais"))
    if (!is.null(iv)) { cfg[[e]]$ticks_modo <- "incremento"; cfg[[e]]$incremento <- iv; marca(paste0(ax, "_intervalo")) }
    if (!is.null(tm)) { cfg[[e]]$ticks_modo <- "manual"; cfg[[e]]$ticks_manuais <- tm; marca(paste0(ax, "_ticks_manuais")) }
  }
  rd <- pega("rotulos_dados_tamanho_pt")   # texto escrito junto dos pontos/barras (rótulos de dados)
  if (!is.null(rd)) { cfg$linhas$rotulos_tamanho_pt <- rd; cfg$barras$rotulos_tamanho_pt <- rd; marca("rotulos_dados_tamanho_pt") }
  neg <- pega("eixos_titulo_negrito")
  if (!is.null(neg)) { cfg$eixo_x$negrito_titulo <- isTRUE(neg); cfg$eixo_y$negrito_titulo <- isTRUE(neg); marca("eixos_titulo_negrito") }
  # cores: gradiente, paleta personalizada (vence a paleta nomeada) e cor de séries específicas
  if (isTRUE(pega("cores_gradiente"))) { cfg$cores$preenchimento <- "gradiente"; marca("cores_gradiente") }
  pers <- pega("cores_personalizadas")
  if (!is.null(pers)) { cfg$cores$paleta <- "personalizada"; cfg$cores$personalizada <- pers; marca("cores_personalizadas") }
  por_serie <- pega("cores_por_serie")
  if (!is.null(por_serie)) {
    if (is.null(names(por_serie)) || any(!nzchar(names(por_serie))))
      .erro("cores_por_serie precisa de nomes: c(\"WORLD\" = \"#000000\", \"BRAZIL\" = \"#1F4E9E\").")
    for (nm in names(por_serie))
      cfg$series[[nm]] <- utils::modifyList(cfg$series[[nm]] %||% list(), list(cor = por_serie[[nm]]))
    marca("cores_por_serie")
  }
  # quebra: ligada por quebra_ativar; sem de/ate, procura o maior vazio entre os dados
  qa <- pega("quebra_ativar")
  if (!is.null(qa)) {
    cfg$quebra$ativo <- isTRUE(qa); marca("quebra_ativar")
    if (isTRUE(qa) && (is.null(cfg$quebra$de) || is.null(cfg$quebra$ate)) && !is.null(dados)) {
      s <- sugerir_quebra(dados, cfg)
      cfg$quebra$de <- s$de; cfg$quebra$ate <- s$ate
    }
  }
  if (length(aplicados)) message("Painel de ajustes aplicado: ", paste(aplicados, collapse = ", "))
  else message("Painel de ajustes: nenhum ajuste ativo (tudo NULL = padrão do template).")
  cfg
}
