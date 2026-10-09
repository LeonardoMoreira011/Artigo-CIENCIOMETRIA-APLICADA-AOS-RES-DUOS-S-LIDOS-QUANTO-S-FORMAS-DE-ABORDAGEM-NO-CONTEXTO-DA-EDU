# Template de gráficos científicos em R — alternativa ao Origin

Entrada: arquivos **CSV**. Saída: figuras **PNG, TIFF, JPEG, PDF, SVG ou EMF** com controle fino de eixos, ticks, moldura, cores, legendas e painéis.
Testado em R 4.3 com **ggplot2 4.0.3** e **ggplot2 3.5.2**.

## 1. Primeira vez (5 minutos)

1. Descompacte a pasta `graficos_R` onde quiser (ex.: `Documentos`).
2. Dê dois cliques em **`graficos_R.Rproj`** (abre o RStudio já na pasta certa).
3. Abra `00_instalar_pacotes.R` e rode tudo (**Ctrl+Shift+S**). No fim deve aparecer "Tudo pronto".
   - Sem permissão de administrador? O script instala na sua pasta pessoal automaticamente.
   - Erro de download? Veja as instruções de proxy no topo do arquivo, ou peça à TI liberação de `https://cloud.r-project.org`.
4. **Recomendado:** *Tools > Global Options > General > Graphics > Backend = "AGG"*. Assim a aba Plots mostra fontes e gradientes iguais ao arquivo final.
5. Rode `05_exemplos.R` (Ctrl+Shift+S): gera 30 figuras de exemplo em `saida/exemplos/`.
6. No console: `galeria()` gera `saida/galeria_referencia.pdf` com símbolos, tipos de linha, paletas, ticks, gradientes e um exemplo de cada tipo.

## 2. Uso diário

Abra `03_executar.R`, troque o nome do CSV e rode linha a linha (**Ctrl+Enter**):

```r
source("01_config.R"); source("02_motor.R")
dados <- ler_csv("dados/meu_arquivo.csv")    # relatório de leitura no console
cfg$grafico$tipo <- "linha_pontos"
cfg$eixo_x$inicio <- 0; cfg$eixo_x$fim <- 100
cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 20
g <- plotar(dados, cfg)
visualizar(g)        # prévia com o tamanho e as fontes reais do arquivo final
salvar(g, cfg)       # grava em saida/ nos formatos de cfg$exportacao$formatos
```

**Ajuda dentro do R:** `ajuda()` lista os blocos; `ajuda("eixo_x")` mostra cada parâmetro com as OPÇÕES e um exemplo de comando; `ajuda("tipos")` resume os tipos de gráfico. Apelidos funcionam: `ajuda("y2")`, `ajuda("violino")`, `ajuda("legenda")`.

**Errou um nome?** O template avisa e sugere: *"Parâmetro cfg$eixo_x$incremeto não existe. Você quis dizer cfg$eixo_x$incremento?"*.

## 3. Números: sempre ponto decimal

- A leitura detecta sozinha separador (`,` `;` tab `|`), codificação (UTF-8 ou latin1/Excel) e **vírgula decimal**, e converte tudo para ponto: `1.234,5` → `1234.5`.
- Valores como `n.d.` numa coluna numérica viram vazio (NA) e o relatório avisa a linha.
- Todos os rótulos dos gráficos saem com ponto decimal. Para forçar: `cfg$dados$decimal_virgula <- TRUE` (ou `FALSE`).

## 4. O que eu quero mudar → qual parâmetro

| Quero… | Comando |
|---|---|
| Trocar o tipo de gráfico | `cfg$grafico$tipo <- "boxplot"` (ver `ajuda("tipos")`) |
| Escolher as colunas | `cfg$grafico$coluna_x <- "Tempo"`; `cfg$grafico$colunas_y <- c("A","B")` |
| Limites do eixo | `cfg$eixo_y$inicio <- 0; cfg$eixo_y$fim <- 50` |
| Intervalo entre ticks | `cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 10` |
| Ticks menores | `cfg$eixo_x$n_menores <- 4` (log10: use 8) |
| Ticks para dentro / fora / cruzando | `cfg$eixo_x$direcao_maiores <- "dentro"` (`"fora"`, `"ambos"`, `"nenhum"`) |
| Comprimento e espessura dos ticks | `comprimento_maiores_pt`, `comprimento_menores_pt`, `espessura_ticks_pt` |
| Caixa fechada com ticks nos 4 lados | `cfg$caixa$fechada <- TRUE; cfg$caixa$ticks_espelhados <- TRUE` |
| Espessura da moldura | `cfg$caixa$espessura_pt <- 1.5` |
| Escala log / invertida | `cfg$eixo_x$escala <- "log10"`; `cfg$eixo_x$inverter <- TRUE` |
| Formato dos números | `cfg$eixo_y$casas_decimais <- 2`; `notacao <- "cientifica"`, `"potencia10"`… |
| Texto no lugar dos números | `ticks_modo <- "manual"; ticks_manuais <- c(0,5,10); rotulos_manuais <- c("a","b","c")` |
| Sobrescrito / subscrito | `cfg$eixo_x$titulo <- "Área (m^{2})"` ; `"CO_{2} (ppm)"` |
| Cor de uma série | `cfg$series[["Amostra A"]] <- list(cor = "#D62728")` |
| Paleta automática | `cfg$cores$paleta <- "okabe_ito"` (veja `mostrar_paletas()`) |
| Gradiente de 2 cores | `cfg$cores$preenchimento <- "gradiente"; cfg$cores$gradiente_cor2 <- "white"` |
| Gradiente por série | `cfg$series[["A"]] <- list(cor = "navy", cor2 = "skyblue")` |
| Espessura / tipo da linha | `cfg$serie_padrao$linha_espessura_pt <- 2; linha_tipo <- "dashed"` |
| Símbolo e tamanho | `cfg$series[["A"]] <- list(simbolo = 22, tamanho_simbolo_pt = 8)` |
| Barras de erro | `cfg$series[["A"]] <- list(coluna_erro = "Desvio A")` |
| Mover a legenda | `cfg$legenda$posicao <- "dentro"; dentro_x <- 0.95; dentro_y <- 0.05` |
| Apagar a legenda | `cfg$legenda$mostrar <- FALSE` |
| Apagar um item da legenda | `cfg$series[["B"]] <- list(mostrar_na_legenda = FALSE)` |
| Renomear item da legenda | `cfg$series[["B"]] <- list(nome_legenda = "Amostra B (25 °C)")` |
| Moldura na legenda | `cfg$legenda$moldura <- TRUE; cfg$legenda$fundo <- "white"` |
| Grade | `cfg$grade$maior_y <- TRUE` |
| Linha de referência | `cfg$referencias <- list(list(eixo = "y", valor = 0, tipo = "dashed"))` |
| Texto / seta / faixa | `cfg$anotacoes$textos`, `$setas`, `$faixas` (ver `ajuda("anotacoes")`) |
| Eixo Y à direita | `cfg$eixo_y2$ativo <- TRUE` + `cfg$series[["B"]] <- list(eixo = "y2")` |
| Gráficos empilhados com X fixo | `cfg$paineis$ativo <- TRUE` + `cfg$paineis$lista` (ver exemplos 25 e 26) |
| Quebra no eixo Y | `cfg$quebra$ativo <- TRUE; de <- 20; ate <- 80` |
| Fonte | `cfg$texto$fonte <- "Arial"; cfg$texto$tamanho_base_pt <- 10` |
| Tamanho e formato do arquivo | `cfg$exportacao$largura <- 8.5; altura <- 6; formatos <- c("tiff","pdf"); dpi <- 600` |
| Reaproveitar o visual | `salvar_estilo(cfg, "meu")` e depois `cfg <- carregar_estilo("meu", cfg)` |
| Mesmo gráfico para vários CSVs | `exportar_lote("dados", cfg)` |
| Voltar tudo ao padrão | `resetar_cfg()` |

## 5. Correspondência com o Origin

| No Origin | Aqui |
|---|---|
| Plot Details › Symbol / Line / Pattern | `cfg$serie_padrao` (todas) e `cfg$series[["nome"]]` (uma) |
| Plot Details › Pattern › Gradient Fill (Two Colors) | `cfg$cores$preenchimento = "gradiente"`, `gradiente_cor2`, `gradiente_direcao` |
| Increment (cor/símbolo automáticos) | `cfg$cores$paleta`, `incrementar_simbolo`, `incrementar_tipo_linha` |
| Axis › Scale (From, To, Type, Increment, Minor Ticks, First Tick) | `cfg$eixo_x$inicio`, `fim`, `escala`, `incremento`, `n_menores`, `primeiro_tick` |
| Axis › Line and Ticks (In/Out/In&Out, Length, Thickness) | `direcao_maiores`, `direcao_menores`, `comprimento_*_pt`, `espessura_ticks_pt` |
| Axis › Tick Labels (Decimal Places, Divide by, Prefix/Suffix, Rotation) | `casas_decimais`, `fator_divisao`, `prefixo`, `sufixo`, `rotacao_rotulos` |
| Axis › Title, Grid Lines, Reference Lines, Breaks | `titulo`, `cfg$grade`, `cfg$referencias`, `cfg$quebra` |
| Layer frame (caixa fechada) | `cfg$caixa` |
| Double-Y | `cfg$eixo_y2` |
| Stack Panels / Merge Graph | `cfg$paineis` |
| Box Chart (Box, Whisker, Percentile, Outliers, Notch, Half box, Violin) | `cfg$boxplot` |
| Pie (Explode, Doughnut, Start Azimuth, Labels, Combine small wedges) | `cfg$pizza` |
| Histogram (Bin size, Normal/Kernel curve) | `cfg$distribuicao` |
| Theme / Graph template | `salvar_estilo()` / `carregar_estilo()` em `estilos/` |
| Export Graphs (size, DPI, format) | `cfg$exportacao` |

## 6. Arquivos

| Arquivo | Para quê |
|---|---|
| `00_instalar_pacotes.R` | instala/atualiza pacotes (uma vez) |
| `01_config.R` | **todos** os parâmetros, cada um com descrição, OPÇÕES e EX. |
| `02_motor.R` | o motor (não precisa editar) |
| `03_executar.R` | seu roteiro de trabalho |
| `04_catalogo.R` | `ajuda()`, `galeria()`, `mostrar_paletas()` |
| `05_exemplos.R` | 30 exemplos prontos (um de cada tipo/recurso) |
| `06_testes.R` | 48 testes automáticos — rode depois de qualquer alteração no motor |
| `estilos/` | estilos salvos: `publicacao_classico`, `apresentacao`, `padrao_cientifico` |
| `dados/` | CSVs de exemplo (inclui um CSV de Excel em português com `;` e vírgula) |

## 7. Limitações conhecidas

- Gradientes exigem R ≥ 4.2 e não existem em EMF (o arquivo EMF sai com cor sólida, com aviso).
- No Windows, a aba Plots do RStudio só mostra gradientes com o backend **AGG** (passo 1.4). `visualizar()` e `salvar()` sempre funcionam.
- Eixo Y2 é linear. Quebra de eixo só no Y.
- Sem gráficos 3D, mapas de contorno ou rótulos nos ticks menores.
- Interface com botões (Shiny) não incluída: é a "Fase 2" opcional descrita no prompt.
