# Estilo "apresentacao" — slides 16:9, fontes grandes, cores vivas.
# Carregue com: cfg <- carregar_estilo("apresentacao", cfg)
list(
  texto = list(fonte = "sans", tamanho_base_pt = 16),
  cores = list(paleta = "okabe_ito", incrementar_simbolo = FALSE),
  serie_padrao = list(simbolo = 21, tamanho_simbolo_pt = 9, espessura_borda_pt = 1.2,
                      linha_espessura_pt = 3, preenchimento_simbolo = "serie"),
  caixa = list(fechada = FALSE, ticks_espelhados = FALSE, margens_cm = c(0.5, 0.8, 0.5, 0.5)),
  eixo_x = list(direcao_maiores = "fora", direcao_menores = "nenhum", n_menores = 0,
                comprimento_maiores_pt = 6, espessura_ticks_pt = 1.5, espessura_linha_pt = 1.5,
                cor_rotulos = "grey25", cor_linha = "grey25", cor_ticks = "grey25"),
  eixo_y = list(direcao_maiores = "fora", direcao_menores = "nenhum", n_menores = 0,
                comprimento_maiores_pt = 6, espessura_ticks_pt = 1.5, espessura_linha_pt = 1.5,
                cor_rotulos = "grey25", cor_linha = "grey25", cor_ticks = "grey25"),
  grade = list(maior_y = TRUE, cor_maior = "grey88", espessura_maior_pt = 0.8),
  barras = list(contorno_cor = NA, largura = 0.75),
  legenda = list(posicao = "topo", tamanho_chave_pt = 18),
  exportacao = list(largura = 24, altura = 13.5, unidade = "cm", dpi = 200, formatos = c("png"))
)
