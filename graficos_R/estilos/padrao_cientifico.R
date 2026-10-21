# Estilo "padrao_cientifico" — moldura completa, ticks maiores e menores para
# dentro nos 4 lados, linhas de 1.5 pt (visual clássico de software científico).
# Carregue com: cfg <- carregar_estilo("padrao_cientifico", cfg)
list(
  texto = list(fonte = "Arial", tamanho_base_pt = 12),
  cores = list(paleta = "cinabro", incrementar_simbolo = TRUE),
  serie_padrao = list(tamanho_simbolo_pt = 7, espessura_borda_pt = 1, linha_espessura_pt = 1.5),
  caixa = list(fechada = TRUE, espessura_pt = 1.5, ticks_espelhados = TRUE, rotulos_espelhados = FALSE),
  eixo_x = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 6,
                comprimento_menores_pt = 3.5, espessura_ticks_pt = 1.5, n_menores = 1,
                distancia_rotulos_pt = 5),
  eixo_y = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 6,
                comprimento_menores_pt = 3.5, espessura_ticks_pt = 1.5, n_menores = 1,
                distancia_rotulos_pt = 5),
  legenda = list(posicao = "dentro", moldura = FALSE, fundo = "transparente"),
  exportacao = list(largura = 12, altura = 9, unidade = "cm", dpi = 600)
)
