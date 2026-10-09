# Estilo "publicacao_classico" — artigo científico, 1 coluna (8.5 cm), P&B.
# Carregue com: cfg <- carregar_estilo("publicacao_classico", cfg)
# Edite à vontade: só o que estiver aqui é alterado no cfg.
list(
  texto = list(fonte = "Arial", tamanho_base_pt = 9),
  cores = list(paleta = "cinza", incrementar_simbolo = TRUE, incrementar_tipo_linha = TRUE),
  serie_padrao = list(tamanho_simbolo_pt = 5, espessura_borda_pt = 0.7, linha_espessura_pt = 1,
                      preenchimento_simbolo = "branco"),
  caixa = list(fechada = TRUE, espessura_pt = 0.8, ticks_espelhados = TRUE, rotulos_espelhados = FALSE,
               margens_cm = c(0.2, 0.3, 0.2, 0.2)),
  eixo_x = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 4,
                comprimento_menores_pt = 2, espessura_ticks_pt = 0.8, n_menores = 1),
  eixo_y = list(direcao_maiores = "dentro", direcao_menores = "dentro", comprimento_maiores_pt = 4,
                comprimento_menores_pt = 2, espessura_ticks_pt = 0.8, n_menores = 1),
  grade = list(maior_x = FALSE, maior_y = FALSE, menor_x = FALSE, menor_y = FALSE),
  legenda = list(posicao = "dentro", moldura = FALSE, fundo = "transparente", tamanho_chave_pt = 12),
  exportacao = list(largura = 8.5, altura = 6.5, unidade = "cm", dpi = 600, formatos = c("pdf", "tiff"))
)
