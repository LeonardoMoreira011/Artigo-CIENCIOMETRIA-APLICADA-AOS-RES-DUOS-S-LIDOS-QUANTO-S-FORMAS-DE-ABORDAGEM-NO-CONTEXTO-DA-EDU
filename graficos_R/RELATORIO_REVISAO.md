# Relatório da revisão profissional — graficos_R

Revisão feita em duas passadas (entender/medir, depois criticar) **antes** de alterar qualquer linha, seguindo o prompt de revisão.
Ambiente de teste: Linux, **R 4.4.3 + ggplot2 4.0.3** e **R 4.3.3 + ggplot2 3.5.2** (ragg 1.5.x, scales 1.4.0, patchwork 1.3.2).
**Windows: não foi testado** (ver "Pendências").

## 1. Resultado em uma tela

| Critério de aceite | Antes | Depois |
|---|---|---|
| `06_testes.R` (ggplot2 4.0.3) | 48 PASSOU / 0 FALHOU | **82 PASSOU / 0 FALHOU** |
| `06_testes.R` (ggplot2 3.5.2) | 48 PASSOU / 0 FALHOU | **82 PASSOU / 0 FALHOU** |
| `05_exemplos.R` | 30 figuras, 1 aviso (fonte Arial ausente no sandbox) | **31 figuras**, o mesmo único aviso |
| `galeria()` | PDF gerado | PDF gerado nas duas versões |
| Figuras dos 30 exemplos originais vs. antes | — | **27 pixel-idênticas** (4.0.3) / 27 (3.5.2); as 3 que mudaram são as correções esperadas: `07` (ticks menores do Y2), `13` e `14` (rótulos de pizza que se sobrepunham) |
| Testes novos que **falham no código antigo** | — | Dos 32 testes escritos primeiro, 23 falham na cópia do código original (o script aborta no primeiro teste de datas, pois o código antigo não tem esse argumento); mais 2 testes de renderização foram acrescentados depois, ao achar o bug do Y2 no ggplot2 3.5 (R12/R18) |

A divisão do `02_motor.R` em módulos foi feita **primeiro e sozinha**, de forma mecânica (conteúdo das funções idêntico, verificado por diff), e validada com 48/48 testes e 30 figuras pixel-idênticas nas duas versões, antes de qualquer correção. Cada etapa tem seu commit no git.

## 2. Achados

Severidade: **crítico** = resultado errado silencioso; **alto** = trava ou perda de trabalho; **médio** = manutenção/UX; **baixo** = estilo.
"S#" = sondagem executada na passada 2 (a evidência foi reproduzida no código original antes de corrigir).

| ID | Sev. | Onde | Problema | Evidência | Decisão |
|---|---|---|---|---|---|
| R01 | crítico | `ler_csv` | Linha com **mais campos** que o cabeçalho (depois da 5ª linha) cria uma linha fantasma e **fabrica dado** (`99 NA`), sem aviso. Causa: `read.table(fill = TRUE)` decide o nº de colunas pelas 5 primeiras linhas | S1: 8 linhas em vez de 7 | **Corrigido.** Conta campos com `count.fields`, lê tudo como texto sem enrolar linhas, avisa linhas com campos a mais e a menos (sempre, mesmo com `relatorio = FALSE`) |
| R02 | crítico | `.colunas_y` | `coluna_erro`, `coluna_erro_*` e `mapear_coluna` dados por **número** não eram excluídos das séries: a coluna de erro aparecia como série extra | S7: "Desvio A" plotado como série | **Corrigido** |
| R03 | alto | carregador (`.motor_pasta <- getwd()`) | `source()` com caminho completo a partir de outra pasta: `.cfg_ref` nulo (sem checar nomes digitados errado), `ajuda()` **inexistente**, `resetar_cfg()` falha | S9 | **Corrigido.** Acha a própria pasta pelo `ofile` do `source()`; `estilos/`, `dados/` e `saida/` relativos passam a ser achados dentro do projeto |
| R04 | alto | `salvar()` | Fundo transparente refazia o gráfico a partir do `cfg` e **descartava** `+ theme()` / `+ labs()` do usuário (o título vermelho sumia) | S10 (imagem) | **Corrigido** (transparência por tema, sem refazer; vale para patchwork). No fallback de formato sem gradiente o gráfico ainda é refeito, agora **com aviso explícito** do que se perde |
| R05 | alto | `.construir_boxplot` | Violino com um grupo de n = 1 trava com erro em inglês (`need at least 2 points...`) | S6 | **Corrigido** (aviso em português; o violino daquele grupo não é desenhado) |
| R06 | médio | `.construir_xy` | Pontos com x/y ≤ 0 em escala log eram omitidos **sem aviso** (o aviso que existia era código inalcançável) | S16 | **Corrigido** |
| R07 | médio | `.construir_boxplot` | `set.seed()` alterava o gerador aleatório global do usuário | S5 | **Corrigido** (estado salvo e restaurado) |
| R08 | médio | `ler_csv` | UTF-16 ("Texto Unicode" do Excel) não detectado: BOM `ÿþ` no nome da 1ª coluna e acentos corrompidos | S2 | **Corrigido** (LE/BE, com e sem BOM) |
| R09 | médio | leitura/eixos | Datas viravam texto (eixo categórico, espaçamento igual) | S4 | **Implementado** (item 15, ver changelog) |
| R10 | médio | `.plotar_paineis` | Cada construtor rodava 2× por painel (4 chamadas para 2 painéis). Nota: ao contrário do que o prompt supunha, `.validar()` roda 1× por painel + 1 global, não 2× | S17 | **Parcial.** Duas passadas são necessárias (a faixa comum só se conhece depois da 1ª), mas a prévia agora **não monta o gráfico** (`so_info`) e **não repete avisos**. Efeitos colaterais (semente, avisos) eliminados por R06/R07 |
| R11 | médio | `.calc_eixo` | `ocultar_rotulo_encostado` ignorava `rotulos_manuais` | leitura + teste | **Corrigido** |
| R12 | médio | `.plotar_um` | Eixo Y2 sem ticks menores no lado direito | imagem | **Corrigido** (desenho próprio, pois `sec_axis` não tem como). *Bug encontrado no meio:* o `annotation_custom` lê limites em espaços diferentes no ggplot2 3.5 e 4.0, e com X em log os ticks sumiam no 3.5 (ver R18); coberto por teste de **renderização** |
| R13 | médio | `.construir_pizza` | Rótulos "fora" de fatias pequenas vizinhas se sobrepõem | imagem | **Corrigido** (`rotulos_afastar`; só move os que colidem) |
| R14 | baixo | `.calc_eixo` | Tolerância absoluta de 1e-9·max gruda ticks em eixo log de ≥ 10 décadas (tick duplicado em 1e-10, o 1e-9 some) | S8 | **Corrigido** (tolerância relativa em log) |
| R15 | baixo | `.construir_xy` | Linha segue a ordem do CSV (como o Origin), sem opção de ordenar | S18 | **Implementado** `linhas$ordenar_x` (padrão `FALSE`) |
| R16 | médio | validação | Chave digitada errado dentro de `referencias` e `anotacoes$textos/setas/faixas` era ignorada em silêncio | teste | **Corrigido** (aviso com sugestão) |
| R17 | baixo | barras/pizza | `grafico$ordem_itens` com categoria inexistente e `pizza$explodir` inexistente: ignorados em silêncio | leitura | **Corrigido** (aviso) |
| R18 | médio | `.ticks_internos` (+ novo) | `annotation_custom(-Inf, Inf)` em escala log gera `NaN` + aviso no ggplot2 4.0; no 3.5 as bordas finitas quebram o desenho | exemplo 07 | **Corrigido**, dependente da versão (`.borda_painel`) |
| R19 | alto | `plotar` | Script que **substitui um bloco inteiro** (`cfg$quebra <- list(...)`) ou estilo salvo antes de um parâmetro existir ficaria sem os parâmetros novos (o próprio teste antigo de quebra pegou isso) | teste | **Corrigido** (`.completar_cfg`: completa com os padrões do `01_config.R`) |
| R20 | baixo | `.plotar_paineis` | `mostrar_rotulos`/`mostrar_titulo` por painel: o aviso dizia que valiam, mas eram descartados | leitura | **Corrigido** |
| R21 | médio | vários | Números mágicos no motor (raios e linha guia da pizza, enxame, espessuras de borda, "n =", margens da legenda, marcas da quebra, rug) | leitura | **Corrigido:** 17 parâmetros de ajuste fino no `01_config.R`, cada um com descrição, `OPÇÕES:` e `EX.:`; `ajuda()` os mostra |
| R22 | baixo | `.plotar_quebra` | `get()`/`assign()` num laço | leitura | **Corrigido** (função `ajustar_parte`) |
| R23 | baixo | código | Código morto: `(!vertical && FALSE)`, `if (A \|\| B) { if (A) ...}`, `ev_y2` | leitura | **Corrigido** |
| R24 | médio | `.construir_xy` (≈ 220 linhas), `.construir_boxplot` (≈ 160) | Funções longas | leitura | **Adiado, com motivo.** Só extraí auxiliares seguros (linhas de eixo no tema, `.afastar_rotulos_pizza`, `.ler_tabela`, etc.). Dividir os dois construtores gigantes sem mudar o comportamento exigiria mais risco do que ganho para quem só edita o `cfg`; a rede de segurança (pixel-diff) existe para quem quiser fazer depois |
| R25 | médio | estrutura | `02_motor.R` com 2121 linhas | — | **Feito.** 17 módulos em `R/`; `02_motor.R` virou carregador. Um único `source("02_motor.R")` |
| R26 | médio | Windows | Sem teste em Windows | — | **Não testável aqui.** Entregues `07_verificar_windows.R` e o roteiro (LEIAME §8) |
| R27 | baixo | `01_base.R` | `options(OutDec = ".", scipen = 6)` globais afetam a sessão do usuário | leitura | **Rejeitado/documentado.** É o que garante ponto decimal sempre (requisito do projeto) |
| R28 | baixo | estilo | Linhas > 120 colunas, funções sem comentário | contagem | **Corrigido** em `R/`, `01–05` e `07`: 0 linhas > 120. **60 comentários** "entra/sai" inseridos. Sobram 14 linhas > 120 só em `06_testes.R` (chamadas aninhadas) |

**Lista de verificação do prompt:** 1 → R03; 2 → R04; 3 → R10; 4 → R15; 5 → R08; 6 → R11; 7 → R12; 8 → R13; 9 → R01, R02, R17, R20 (os "desalinhamentos silenciosos" extras); 10 → R25; 11 → R21; 12 → R22; 13 → R24 (parcial); 14 → R28; 15 → R09; 16 → R26.

## 3. Changelog (para quem usa)

**Novo**
- **Eixo de datas e horas.** Coluna X como `15/03/2024`, `2024-03-15` ou `15/03/2024 14:30` vira eixo de tempo, com ticks automáticos redondos (dias, semanas, meses, anos, horas), rótulos só numéricos (não dependem do idioma do Windows), `incremento = "1 mes"`/`"2 semanas"`/`"6 horas"`, `inicio`/`fim` em texto de data. Vale para pontos, linhas e áreas. Exemplo 31 e `dados/serie_temporal.csv`.
- `linhas$ordenar_x` para ligar os pontos da esquerda para a direita.
- Pizza: rótulos que se sobreporiam são afastados sozinhos.
- Eixo Y2: ticks menores no lado direito.
- CSV em UTF-16. Aviso quando uma linha tem campos a mais/menos. Mensagens com o **número real da linha do arquivo**.
- 21 parâmetros novos no `01_config.R` (ajuste fino, datas e `ordenar_x`; ver LEIAME §4).
- `07_verificar_windows.R`. 34 testes automáticos a mais (82 no total).
- Pasta `R/` com o código do motor dividido por assunto.

**Corrigido**
- Dados embaralhados por linha com campos a mais no CSV.
- Coluna de erro dada por número aparecendo como série.
- `ajuda()` e `resetar_cfg()` quebrados quando o `source()` vinha de outra pasta.
- Título/tema adicionados com `+` sumindo no arquivo com fundo transparente.
- Violino com um grupo de 1 valor travando.
- Boxplot mexendo na semente do `set.seed` do usuário.
- Pontos ≤ 0 em escala log sumindo sem aviso.
- Ticks errados em eixo log de 10 ou mais décadas.
- Avisos agora aparecem para chaves erradas em `referencias`/`anotacoes`, categorias inexistentes em `explodir`/`ordem_itens`.

**Mudou de comportamento (único caso intencional)**: uma coluna X de texto que parece data agora vira eixo de tempo (antes, categorias com espaçamento igual). Para voltar ao antigo: `cfg$eixo_x$tempo <- FALSE`. E rótulos de pizza que se sobrepunham agora são afastados (`cfg$pizza$rotulos_afastar <- FALSE` desliga).

**Compatibilidade**: nenhum nome de parâmetro ou função pública mudou ou sumiu; `estilos/` e `05_exemplos.R` funcionam sem edição; sem dependências novas.

## 4. Pendências honestas

1. **Windows não foi testado.** Rode `07_verificar_windows.R` e `06_testes.R` (esperado: `0 FALHOU`) e **abra os PDFs/PNGs** para conferir fonte, acentos e gradiente. Itens que só o Windows mostra: `Arial` e `Times New Roman` no `cairo_pdf` e no ragg; o Viewer do RStudio em `visualizar()`; o backend gráfico da aba Plots.
2. **EMF não foi testado** (o pacote `devEMF` não existe no repositório conda-forge usado para montar o ambiente). O teste de exportação cobre png, pdf, svg e tiff.
3. A fonte `Arial` não existe no sandbox: o único aviso dos exemplos ("usando 'sans'") é esperado aqui. A inspeção visual foi feita com a fonte de reserva.
4. O ambiente de teste usou R 4.3.3 (ggplot2 3.5.2) e R 4.4.3 (ggplot2 4.0.3). O `00_instalar_pacotes.R` não foi alterado nem testado de novo (o CRAN estava bloqueado no sandbox).
5. Datas: fuso sempre UTC; dia antes do mês por padrão (`formato_data` para outro formato); só em pontos/linhas/áreas. Em barras, pizza e boxplot a data continua sendo texto.
6. R24 (dividir `.construir_xy` e `.construir_boxplot`) ficou para depois, como explicado.
