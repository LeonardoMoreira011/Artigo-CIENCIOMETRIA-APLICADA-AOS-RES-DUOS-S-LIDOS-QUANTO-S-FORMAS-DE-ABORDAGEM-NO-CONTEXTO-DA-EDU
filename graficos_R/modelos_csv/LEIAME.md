# Modelos de planilha (CSV)

Arquivos de exemplo, com dados **inventados**, para mostrar como montar a planilha de cada tipo de gráfico. Abra no Excel, troque pelos seus números, salve como CSV e carregue no Cinabro (Dados > Escolher arquivo).
O **Apêndice do `Manual_Cinabro.pdf`** explica cada um: a planilha, o que marcar no programa e o gráfico que sai.

| Arquivo | Gráfico |
|---|---|
| `modelo_01_series_xy.csv` | Linhas, pontos, áreas: uma coluna por série |
| `modelo_02_dois_eixos.csv` | Duas grandezas (eixo Y da direita) |
| `modelo_03_serie_temporal.csv` | Datas e horas no eixo X |
| `modelo_04_barras_erro.csv` | Barras agrupadas com barras de erro (média e desvio padrão) |
| `modelo_05_pizza.csv` | Pizza / rosca |
| `modelo_06_boxplot_colunas.csv` | Boxplot: uma coluna por grupo (replicatas) |
| `modelo_07_formato_longo.csv` | Boxplot, histograma: coluna de grupo + coluna de valor |
| `modelo_08_histograma.csv` | Histograma e densidade, com grupos |
| `modelo_09_mapa_calor.csv` | Mapa de calor: matriz de linhas x colunas |
| `modelo_10_mapa_calor_longo.csv` | Mapa de calor: três colunas (linha, coluna, valor) |
| `modelo_11_pca.csv` | PCA: amostras nas linhas, variáveis e ambientais nas colunas |
| `modelo_12_cca.csv` | CCA e CA: abundâncias + variáveis ambientais |
| `modelo_13_mapa_mundo.csv` | Mapa-múndi (país em inglês) |
| `modelo_14_mapa_brasil.csv` | Mapa do Brasil (sigla do estado) |
| `modelo_15a_ANTES_tabela_cruzada.csv` / `modelo_15b_DEPOIS_pca.csv` | Como transformar a tabela "de lado" do Excel na planilha certa |

Regras: uma só linha de títulos; uma linha = uma observação; colunas numéricas só com números (célula vazia onde faltar); unidade no título da coluna; sem totais no meio.
(Os arquivos são salvos como o Excel brasileiro faz: ponto e vírgula, vírgula decimal. O Cinabro lê também vírgula como separador e ponto decimal.)
Para refazer tudo (dados, gráficos do manual): `Rscript ferramentas/manual/modelos.R`.
