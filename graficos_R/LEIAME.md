# Cinabro — laboratório de gráficos científicos em R

Este template em R e o app no navegador formam o **Cinabro**. Cinábrio é o pigmento vermelho de pintores e alquimistas. O logo ainda está em definição.

Entrada: arquivos **CSV**. Saída: figuras **PNG, TIFF, JPEG, PDF, SVG ou EMF** com controle fino de eixos, ticks, moldura, cores, legendas e painéis.
Testado em R 4.3/4.4 com **ggplot2 4.0.3** e **ggplot2 3.5.2** (Linux). **Não foi testado em Windows:** rode `07_verificar_windows.R` uma vez (seção 8).

> **Prefere um arquivo só?** Use `graficos_R_completo.R` (tudo junto: instalador, configuração, motor, ajuda, estilos e exemplos). Abra-o no RStudio, clique em *Source* e rode `demonstracao()`. É gerado a partir desta pasta por `python3 ferramentas/gerar_script_unico.py`.

## Aplicativo no navegador (sem editar script)

Para quem não quer mexer em código: abra o **Cinabro** (laboratório de gráficos) no navegador, carregue o CSV e ajuste tudo com cliques.

- **Como abrir:** dois cliques em **`abrir_app.bat`** (Windows), ou no RStudio abra `abrir_app.R` e rode (ou `shiny::runApp("app_shiny")`). Na primeira vez ele instala o pacote *shiny*. O `.bat` procura o R sozinho (PATH, registro do Windows, `Program Files`, `AppData\Local\Programs\R`); se não achar, pergunta o caminho do `Rscript.exe` uma vez e guarda em `caminho_do_R.txt`.
- **O que tem:** os mesmos 12 blocos do `painel_de_ajustes.R` (dados, intervalos, escala, números e títulos, grade, quebra do eixo, eixo Y direito, cores/linhas/símbolos série por série, fonte, moldura e tamanho fixo da caixa, legenda, exportação), cada um com explicação e dicas, prévia que se atualiza sozinha, avisos em português, e botões para baixar **PNG, TIFF, JPEG, SVG e PDF**.
- **Repetir depois:** *Salvar configuração* (arquivo .json) e *Carregar configuração*; *Código equivalente* mostra as linhas do painel e baixa um script `.R` pronto — a ponte entre o app e o script.
- **Para o time:** basta compartilhar a pasta `graficos_R` inteira (o app usa o motor da pasta de cima e a fonte de `fontes/`).
- **Testes do app:** `Rscript app_shiny/testes_app.R` (49 testes).

## Refinos de aparência (atualização)

- **Negrito:** `negrito_geral <- TRUE` deixa TUDO em negrito (títulos, números, legenda, rótulos de dados); também por texto: `x_numeros_negrito`, `y_numeros_negrito`, `legenda_negrito`, `legenda_titulo_negrito`, `eixos_titulo_negrito`, `titulo_grafico_negrito`.
- **Caixa do gráfico fixa por padrão (10 × 7,5 cm):** mudar a distância dos números, os títulos ou a legenda move esses textos, não o gráfico; a página do arquivo se ajusta. `painel_fixo <- FALSE` volta à página de `largura_cm × altura_cm`; tamanho próprio: `painel_largura_cm` / `painel_altura_cm`.
- **Grossura única:** `moldura_espessura_pt` agora vale também para os traços e as linhas dos eixos (cada eixo ainda pode ter a sua com `x_/y_ticks_espessura_pt`).
- **Rotação dos títulos dos eixos:** `x_rotacao_titulo`, `y_rotacao_titulo` (0 = horizontal; padrão do Y = 90) e `y2_rotacao_titulo`.
- **Quebra de eixo:** as barras `//` ficaram curtas (2,5 × 3 pt) para não encostar nos números; `quebra_marca_largura_pt`, `quebra_marca_altura_pt`, `quebra_marcas`.
- **Grade:** nos traços grandes (`grade_x`, `grade_y`) e nos pequenos (`grade_menor_x`, `grade_menor_y`), cada grupo com tipo, cor, grossura e opacidade; a menor precisa de traços pequenos (`x_ticks_menores` ≥ 1).
- **Fontes:** o app lista **todas as fontes do computador (systemfonts)**, com busca, e aceita uma fonte de arquivo `.ttf`/`.otf`. No script: `listar_fontes()` e `fonte <- "Nome da fonte"`.

## Idioma: só português (BR)

- O app e o motor falam **só português do Brasil**. O seletor de idioma saiu do cabeçalho e `idioma <- "en"` no painel avisa e usa o português.
- O **inglês e o espanhol não foram apagados**: dicionários, mensagens do motor e READMEs estão guardados em **`idiomas_arquivados/`** (veja o `LEIA-ME.md` de lá). **Para reativar, peça.**
- Todo texto novo é escrito só em português.

## Paletas e licenças

Só entram paletas de trabalhos com licença livre; os créditos e avisos estão em **`NOTICE.md`**. Foram retiradas paletas associadas a programas, revistas e marcas, e a paleta padrão agora é a `cinabro` (original, com as cores ordenadas para serem bem distintas, também para daltonismo). Nomes antigos continuam valendo (`"classico"` = `"cinabro"`).

## Novo layout: o gráfico em primeiro lugar

- **Gráfico grande e painéis sob demanda.** No lugar da lista de 14 blocos, há um **trilho de ícones** à esquerda (um ícone por assunto: dados, intervalos, escala, números, grade, quebra, eixo direito, cores, fonte, moldura, legenda, análises, formas, exportação). Cada ícone abre **um painel de cada vez**; clique de novo para fechar e dar mais espaço ao gráfico. **Maximizar** (Esc volta) esconde o trilho e o painel. O gráfico é desenhado na largura do palco, então não fica pequeno.
- **Faixa de ferramentas acima do gráfico.** Um clique liga o primeiro cartão livre: **Ajuste de curva** (linear, exponencial, potência, logarítmico, polinomial, suavizado, fórmula livre), **Média ± DP**, **Caixa de estatística**, **Texto**, **Forma** e **Figura**; o painel correspondente abre já no cartão novo para você estilizar. **Tabelas e testes** abre os resultados em números. Os botões de baixar ficam na mesma faixa.
- **Edição dentro do gráfico.** Passe o mouse sobre o **título** ou sobre o **nome de um eixo**: aparece uma zona clicável; clique e abre uma caixinha com o texto, o negrito e o tamanho. (Mover e redimensionar a legenda com o mouse continua como antes.)
- **Ainda não:** arrastar com o mouse as caixas de estatística, as formas e as figuras (por enquanto, posição e tamanho nos painéis).
- Os campos, as regras e o código gerado são os mesmos; só mudou a forma de chegar neles. Cartões incompletos (figura sem arquivo, fórmula sem fórmula) esperam ser preenchidos, sem dar erro.

## Auditoria de desempenho (diagnóstico e registro de uso)

- **Diagnóstico**: abra `ferramentas/diagnostico_cinabro.R` no RStudio e rode (Source). Ele confere versões do R e dos pacotes, mede o tempo de cada gráfico e o crescimento de memória, e grava `diagnostico_cinabro_resultado.txt` na mesma pasta. Antes: R 4.5 ou mais novo, reiniciar o RStudio e rodar `00_instalar_pacotes.R`.
- **Registro de uso**: o aplicativo anota em `%LOCALAPPDATA%\Cinabro\log\app.log` (Windows) quando abre/fecha, quanto cada gráfico demora, memória, arquivos temporários e erros. Não grava seus dados nem o conteúdo do gráfico. Se a tela ficar cinza, envie o final desse arquivo.
- A prévia antiga é apagada ao desenhar a nova (antes ficava acumulando na pasta temporária).
- **Fase 1 da auditoria (feita):**
  - **Limites nos campos:** o servidor passa a aplicar o mínimo e o máximo de cada campo (o navegador deixa digitar qualquer número; 10 milhões de "traços menores" enchia o R de memória e letra de tamanho negativo travava por 15 s). O valor é corrigido e um aviso diz qual campo ficou em qual valor. Sem máximo declarado: 500 pt (tamanhos em pt), 300 cm (tamanhos em cm), 1e9 (demais).
  - **Prévia reduzida:** acima de 5 mil linhas, a prévia (só ela) desenha uma amostra que guarda picos e vales, e um aviso "Prévia simplificada: N de M linhas" aparece sob o gráfico. Os arquivos baixados e as tabelas de estatística usam **todas** as linhas. Não reduz com ajuste, média ± DP ou caixa de estatística ligados, nem em barras/boxplot/histograma. Medido: 50 mil linhas de ~30 s para ~1,4 s por atualização; 200 mil, de 76 s para ~1,1 s.
  - **Um gráfico só por atualização** (desenho e medidas da legenda, dos títulos e das caixas usam o mesmo): 13 pontos, de ~1,15 s para ~0,75 s.
  - **Tela montada uma vez** ao abrir o programa (antes, ~1,8 s com o R parado a cada aba ou recarga; agora a página sai em ~3 ms) e **aquecimento**: um gráfico pequeno é desenhado ao abrir, para o primeiro gráfico de verdade sair rápido.
  - **O R não fecha mais por uma queda curta:** espera 10 minutos sem nenhuma aba aberta (antes, 6 s). Botão **Sair** no cabeçalho encerra na hora. Endereço `http://127.0.0.1:8421`.
  - **Figuras leves:** uma figura de 4 megapixels ocupa ~17 MB (antes 138 MB), é lida em 0,1 s e desenhada sem conversão (antes 4 s a cada atualização); a memória guarda no máximo 3 figuras.
  - **Registro de uso:** o `app.log` agora anota os nomes dos campos em uso (não os valores) em cada gráfico, para sabermos o que a equipe realmente usa.
- **Fase 2 da auditoria (feita): menos blocos, menos tela.**
  - **7 painéis em vez de 14 blocos** (os blocos viraram *seções*; os textos mais antigos deste LEIAME ainda falam em "bloco N"): **1 Dados** (bloco 1) · **2 Eixos, escala e grade** (blocos 2 a 7: intervalos, escala, números e títulos, grade, quebra do eixo Y, eixo Y da direita) · **3 Cores, linhas e símbolos** (bloco 8) · **4 Fonte e tamanhos de texto** (bloco 9) · **5 Legenda** (bloco 11) · **6 Análises e anotações** (blocos 13 e 14) · **7 Tamanho e exportação** (blocos 10 e 12).
  - **Seções recolhidas:** em cada painel só a seção principal começa aberta; o **eixo Y da direita** e a **quebra do eixo** ficam recolhidos e ganham o selo **"ligado"** quando estão em uso. Cada seção tem o seu "Congelar".
  - **Cartões sob demanda:** os 19 cartões (ajustes, traços, caixas de estatística, formas e figuras) não são mais montados com a tela; cada um nasce quando você o adiciona pela faixa de ferramentas (ou quando uma configuração ou aba guardada precisa dele). A tela caiu de 695 para 232 campos e de 512 KB para 175 KB; os 481 painéis condicionais viraram 21.
  - **Cabeçalho de ~52 px** (era 112): o gráfico ganha ~60 px de altura.
  - **Retirados:** "Mostrar outra aba ao lado" e "Copiar modelo / Colar modelo..." (o **Salvar/Carregar configuração** faz o mesmo e continua).
  - **Fontes:** a lista continua com todas as fontes do computador, com busca (não precisou de lista curta). **Paletas:** 12 (escolha sua).
  - **Corrigido:** um erro no JavaScript (botão Sair) fazia o resto do script não rodar (trilho, caixas móveis, edição no gráfico) na versão da Fase 1. Agora há um teste que confere o JS e roteiros no navegador em `ferramentas/teste_navegador/`.

## Caixas que se movem, caixa de estatística separada e curva externa

- **Tudo se move com o mouse.** Figuras anexadas, textos, formas (retângulo, elipse, triângulo, polígono...), caixas de estatística e a legenda aparecem com uma moldura sobre a prévia: **arraste** para mudar de lugar, **puxe o quadradinho vermelho do canto** para mudar o tamanho (nas figuras mantém a proporção; nos textos e nas caixas de estatística muda o tamanho da letra; nas formas muda largura e altura; no polígono estica os vértices) e **clique** para editar na hora (conteúdo, tamanho, negrito, cor). "Todas as opções" abre o cartão completo. Os valores caem nos campos do cartão (posição X/Y, largura, tamanho do texto), então o que você arrastou também vai para o código e para a configuração salva. Liga e desliga em **Mover legenda e caixas com o mouse**.
- **Limites:** só para caixas em "fração da caixa do gráfico" (as em "unidades dos eixos" acompanham os dados e não têm moldura) e em gráficos sem quebra de eixo. Figura girada: a moldura mostra a caixa sem girar.
- **Regra dos números:** ao pôr um **ajuste de curva** (faixa de ferramentas) o programa liga também uma **caixa de estatística** só dele (equação e R²); ao pôr **Média ± DP**, uma caixa com n, média e desvio. Os valores não ficam colados na linha (o campo "Escrever o valor ao lado de cada traço" começa desligado). Cada caixa tem o seu cartão (itens, casas decimais, tamanho, negrito, cor, fundo, borda, sombra) e começa pequena, no canto de baixo à direita.
- **Curva externa** (Ajuste de curva > Curva externa; `tipo = "externa"` no script): desenha por cima dos dados uma curva que você já tem, **sem ajustar nada**: cole os **pontos X,Y** (duas colunas do Excel/Origin) ou escreva a **fórmula** com os **valores dos parâmetros**. R², RMSE e n comparam a curva com a série escolhida; uma caixa de estatística pode mostrar isso (`itens = c("equacao", "r2", "rmse")`).
- **Detalhe técnico:** cada item de cartão leva o número do cartão (`cartao`) para ligar a moldura ao cartão e a caixa de estatística ao ajuste (campo "Quais ajustes entram" usa o número do cartão); o código equivalente não mostra esse número. Corrigido de passagem: "barras de erro em cada X" (replicatas) falhava fora do conjunto de testes.

## Nova identidade visual (logo e cores)

- **Cores:** `#B3262E` (vermelho-cinábrio), `#F5EBDD` (creme), `#20242B` (tinta), `#C96A4A` (terracota) e `#2F6670` (azul-petróleo). O **creme é o fundo da página**; o **branco fica só na caixa do gráfico**. Os cartões usam um creme mais claro derivado do fundo. A paleta de gráficos `identidade` traz as mesmas cores (sem o creme).
- **Logo:** o emblema (anel, curva de ajuste e pontos) foi **vetorizado** (`identidade/emblema.svg`, fundo transparente, só as 5 cores) e aparece no cabeçalho do app, no ícone da aba e no atalho do Windows (`icone.ico`). **Letreiro:** o nome "CINABRO" em *Titan One* (contorno, sombra terracota e sombra suave) e a frase em latim em *Kaushan Script* (letra de pincel), com fio e pontos nas cores da paleta, no cabeçalho do app; versões em PNG transparente em `identidade/` (fontes livres SIL OFL, em `fontes/Letreiro/`; veja `NOTICE.md`). Detalhes e origem do desenho em `identidade/LEIAME.md`.

## Terceira rodada: ajustes, estatísticas, formas, congelar blocos e abas

- **Bloco 13 — Ajustes e estatísticas** (gráficos de pontos, linhas e áreas com X numérico). Quatro cartões de **curva de ajuste**: linear (com opção de passar pela origem), exponencial, potência, logarítmico, polinomial (grau 1 a 8), suavizado (*loess*) e **fórmula livre** (`a*exp(-b*x) + c`, `a/(1 + exp(-k*(x - x0)))`...; só funções matemáticas são aceitas — nada de comandos do R). Cada curva tem cor, tipo de linha (contínua, tracejada...), grossura, opacidade, trecho desenhado e **faixa do intervalo de confiança**. Três cartões de **traços de média/mediana com desvio padrão, erro padrão, IC 95% ou mínimo–máximo** (linhas atravessando o gráfico, área pintada, valores escritos; ou barras de erro em cada X com replicatas), com cor, grossura e tipo de cada traço. Três **caixas de estatística** livres como a legenda: escolha o que escrever (n, média, mediana, DP, EP, soma, mín., máx., variância, CV, quartis, IC 95%; equação, R², R² ajustado, RMSE, AIC, BIC, valor de p do modelo, parâmetros ± erro, valores de p; correlações de Pearson/Spearman/Kendall, Shapiro-Wilk, teste t, Wilcoxon, teste F, ANOVA, Kruskal-Wallis, Tukey, Bartlett, Fligner-Killeen), com fundo, borda (reta ou **arredondada**), tipo e grossura da borda, **sombra**, posição, tamanho e cor do texto. Os cálculos usam o R base (`lm`, `nls`, `loess`, `aov`, `TukeyHSD`...) e **todos** os dados, também os do eixo Y2 e os que a quebra de eixo esconde. Há ainda o botão **Calcular as tabelas** (resumo, ajustes, parâmetros e testes) e **Baixar em CSV**. No script: `estatisticas(dados, cfg)` devolve as mesmas tabelas.
- **Bloco 14 — Caixas de texto e polígonos:** seis cartões de forma: caixa de texto, retângulo, retângulo arredondado, elipse, triângulo, losango, hexágono, estrela e **polígono livre** (vértices `x,y; x,y; ...`), com texto (aceita `m^{2}` e `H_{2}O`), cor e opacidade do preenchimento, cor, grossura e tipo da borda, cantos arredondados, sombra, giro e camada (na frente ou atrás dos dados). A posição e o tamanho valem em **fração da caixa do gráfico** (0 a 1) ou nas **unidades dos eixos** (a forma acompanha os dados).
- **Figuras anexadas (bloco 14, cartões "Figura"):** campo para **enviar um PNG ou JPEG** (logotipo, esquema, foto da amostra) e colocá-lo sobre o gráfico: posição e tamanho em fração da caixa ou em unidades dos eixos, altura vazia = mantém a proporção, ponto de ancoragem, opacidade, giro, contorno e camada (na frente ou atrás dos dados); PNG com fundo transparente funciona. Precisa dos pacotes `png` e `jpeg` (o `00_instalar_pacotes.R` instala). A figura fica só na sessão do app: **não vai no modelo copiado nem na configuração salva** (anexe de novo ao reabrir); cada aba guarda as suas, e o código equivalente cita o nome do arquivo enviado (ponha-o ao lado do script). No script: `imagens <- list(list(arquivo = "logo.png", x = 0.98, y = 0.98, ancora = "sup_dir", largura = 0.15))`.
- **No script (`painel_de_ajustes.R`)**: as variáveis `ajustes`, `marcas_estatisticas`, `caixas_estatisticas`, `formas` e `imagens` (listas de itens; veja as opções em `01_config.R`). O exemplo 32 de `05_exemplos.R` usa tudo junto.
- **Congelar:** cada bloco tem um tic **Congelar** no cabeçalho. Um bloco congelado não volta ao padrão em **Restaurar tudo**, não muda ao aplicar um modelo colado e **passa para as abas novas** — assim, para fazer outro gráfico com a mesma fonte, moldura e cores, congele esses blocos e crie uma aba nova.
- **Levar as configurações de um gráfico para outro:** **Salvar configuração** e **Carregar configuração** (também guardam as seções congeladas). Os botões "Copiar modelo" e "Colar modelo..." e a opção "Mostrar outra aba ao lado" foram retirados na Fase 2 da auditoria (faziam o mesmo que salvar/carregar e dobravam o custo de cada atualização).
- **Barras de erro (média ± desvio padrão):** no painel **Dados**, escolha o tipo "Pontos" (ou linha), deixe a coluna da **média** em Y e coloque a coluna do **desvio padrão** em **"Colunas de erro (± desvio padrão)"**. A 1ª coluna de erro vale para a 1ª série, a 2ª para a 2ª, e assim por diante; a coluna de erro **não** é desenhada como série. Aparecem então o lado (dois lados, só para cima, só para baixo), a grossura e a largura do chapéu. O eixo cresce sozinho para caber a barra. No script: `erro_por_serie <- c("Media" = "DP")` (mais `erro_lado`, `erro_espessura_pt`, `erro_chapeu_pct`); erros diferentes para cima e para baixo e erro em X só pelo `cfg$series[[...]]` (`coluna_erro_inferior`, `coluna_erro_superior`, `coluna_erro_x`).
- **Abas:** no alto, uma aba por gráfico, cada uma com os seus dados e as suas configurações; **+ Nova aba** (só com os blocos congelados), **Duplicar**, **Renomear** e **×** para fechar. Atenção: você **edita um gráfico por vez** — para editar o outro, clique na aba dele (a troca guarda e devolve tudo). **Troca refeita:** a aba nova só recebe os campos que *diferem* da anterior (antes eram os 646, ~10 s; agora cerca de 1 s para abrir a aba e ~3 s para voltar a um gráfico já com a prévia desenhada).

## Segunda rodada de ajustes (app e motor)

- **Listas de colunas (Y e Y2):** a lista suspensa não é mais cortada pelo bloco; tem **"Selecionar todas"** e **"Limpar"**, e a coluna do eixo X não aparece como série.
- **Tipo de arquivo (bloco 12):** marque PNG, TIFF, JPEG, SVG, PDF (e EMF, se o pacote *devEMF* estiver instalado): o cartão *Baixar* mostra um botão para cada tipo marcado. Novo: `fundo_transparente <- TRUE`.
- **Legenda:** `legenda_direcao` ("vertical" = um embaixo do outro, "horizontal" = lado a lado numa linha), `legenda_n_colunas` e novo `legenda_n_linhas` (ex.: horizontal em 2 linhas).
- **Paletas (12):** a padrão **`cinabro`** (as cores da marca — vermelho, petróleo, tinta, terracota — e variações delas; as 4 primeiras são as mais diferentes entre si), seis **degradês** (`brewer_Reds`, `brewer_Purples`, `brewer_YlGnBu`, `brewer_YlOrRd`, `cmo_algae`, `crameri_oslo`), dois **divergentes** (`brewer_RdYlGn`, do vermelho-escuro ao verde, e `brewer_Spectral`) e três **contínuas** (`magma`, `inferno`, `turbo`). Só entram paletas de trabalhos com licença livre (créditos em `NOTICE.md`). **Nomes que saíram da lista** (`okabe_ito`, `marca`, `tol_*`, `brewer_Set1`, `viridis`...) ainda funcionam: o motor usa a paleta mantida mais parecida e avisa. **Criar a minha paleta:** no app, cole códigos de cor, edite os quadradinhos, inverta a ordem e **guarde com um nome** (fica no navegador e vai junto na configuração salva). No script: `cores_personalizadas <- c("#...", "#...")`.
- **Eixo Y direito (Y2) completo:** as mesmas opções do Y1 — traços (direção, comprimento, grossura, cor, primeiro traço), linha do eixo, números (tamanho, negrito, giro, mostrar), título (tamanho, negrito, itálico, giro) e folga. Vazio = igual ao eixo esquerdo (`y2_ticks_direcao`, `y2_numeros_tamanho_pt`, `y2_titulo_negrito`...).
- **Quebra do eixo Y completa:** botão **"Achar o maior vazio nos meus dados"**; traços pequenos e intervalo **de cada parte** (`quebra_y_ticks_menores_inferior`/`_superior`, e `quebra_y2_...` para o eixo direito); as opções do eixo direito aparecem sozinhas quando há séries no Y2.

## Atalho com ícone, sem janela de comando, e endereço bonito

- **Atalho com ícone:** um `.bat` não pode ter ícone no Windows; o jeito é um **atalho**. **Extraia o ZIP inteiro** (não rode de dentro do ZIP) e dê dois cliques em **`Criar_atalho_na_area_de_trabalho.bat`** (uma vez). Ele usa um VBScript (`criar_atalho.vbs`, sem PowerShell); se o computador bloquear, tenta o PowerShell e, por último, deixa um `Cinabro.cmd` na área de trabalho (sem ícone). O atalho "Cinabro" aparece na área de trabalho e no menu Iniciar, com o ícone do projeto (`app_shiny/www/icone.ico`, provisório). Pode fixar na barra de tarefas pelo menu de contexto do atalho.
- **Sem janela de comando:** o atalho abre o app por `iniciar_gerador_oculto.vbs` (R escondido). O R **fecha sozinho** 10 minutos depois que a última aba do navegador se fecha (e também se o navegador nunca chegar a conectar, após 3 minutos); recarregar a página, suspender o computador ou uma queda curta não encerram. O botão **Sair** (canto superior direito) encerra na hora. Com o `abrir_app.bat` a janela preta também fecha sozinha ao terminar (só pede uma tecla se o R terminar com erro). A primeira vez (ou se o R não for achado) abre o `abrir_app.bat` com janela, que instala o que falta.
- **Endereço:** `http://127.0.0.1:8421` (porta fixa; se estiver ocupada o app escolhe outra e mostra o endereço). Antes era `cinabro.localhost`, que podia falhar com proxy da empresa ou IPv6.
- **No R:** `source("app_shiny/iniciar.R"); iniciar_gerador()` (com `encerrar_ao_fechar = TRUE` o R fecha junto com a aba). A prévia do `visualizar()` agora grava `previa_do_grafico.html` (nome fixo, não números aleatórios).

## Legenda como caixa ajustável

- `legenda_largura_pt` — largura da caixa da legenda, em pt (como esticar uma caixa solta): o conteúdo escala até a caixa ter essa largura e os **símbolos, esferas e linhas acompanham a escala**.
- `legenda_espaco_texto_pt` — espaço entre o símbolo e o nome (menor = mais compacta); `legenda_largura_chave_pt` — largura do espaço do símbolo; `legenda_escala` — escala geral (agora também escala os símbolos).

## Posição da legenda: arrastar, X/Y ou coordenada do eixo

- **No app:** na prévia aparece uma **caixa tracejada verde sobre a legenda** — **arraste** para mudar a posição e puxe a **alça da direita** para mudar a largura. Os campos (bloco 11) são atualizados sozinhos. Desligue em "Arrastar a legenda" se atrapalhar.
- **Campos:** posição horizontal e vertical de 0 a 1 (`legenda_x`, `legenda_y`) ou, no lugar, a **coordenada do eixo**: `legenda_x_dados <- 2016; legenda_y_dados <- 600000` (o canto superior esquerdo da legenda fica nesse ponto; avisa se estiver fora do eixo). Não serve para eixos de categorias.
- **Com quebra de eixo:** vale a parte de cima (onde a legenda mora).

## Fonte oficial: Barlow

A **Barlow** (Barlow, Barlow Condensed e Barlow Semi Condensed; licença SIL OFL, `fontes/Barlow/OFL.txt`) é a fonte padrão. Os arquivos estão em **`fontes/Barlow/`** e são carregados sozinhos — não precisa instalar nada no Windows para PNG, TIFF, JPEG e SVG. O `graficos_R_completo.R` traz uma cópia embutida. **PDF e EMF** usam as fontes *instaladas* no Windows: para a Barlow sair no PDF, abra os `.ttf` de `fontes/Barlow` e clique em *Instalar*.

## 1. Primeira vez (5 minutos)

1. Descompacte a pasta `graficos_R` onde quiser (ex.: `Documentos`).
2. Dê dois cliques em **`graficos_R.Rproj`** (abre o RStudio já na pasta certa).
3. Abra `00_instalar_pacotes.R` e rode tudo (**Ctrl+Shift+S**). No fim deve aparecer "Tudo pronto".
   - Sem permissão de administrador? O script instala na sua pasta pessoal automaticamente.
   - Erro de download? Veja as instruções de proxy no topo do arquivo, ou peça à TI liberação de `https://cloud.r-project.org`.
4. **Recomendado:** *Tools > Global Options > General > Graphics > Backend = "AGG"*. Assim a aba Plots mostra fontes e gradientes iguais ao arquivo final.
5. Rode `05_exemplos.R` (Ctrl+Shift+S): gera 32 figuras de exemplo em `saida/exemplos/`.
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

### 2.1 Painel de ajustes (jeito mais fácil)

Em vez de escrever `cfg$eixo_x$...`, abra **`painel_de_ajustes.R`** (no script único, é a PARTE 3), preencha `ARQUIVO_CSV` e mude só o que quiser. `NULL` = padrão. Dê *Source* e o gráfico é gerado e salvo. Categorias: arquivo e tipo, **escala**, **ticks**, números e títulos, **grade**, **quebra do eixo Y**, **cores**, fonte, legenda e moldura, exportação. Exemplos:

```r
x_inicio <- 2015; x_fim <- 2026; x_folga_pct <- 4     # escala: limites e folga nas pontas
recortar_nos_limites <- FALSE                         # pontos das pontas aparecem inteiros
x_intervalo <- 1                                      # ticks: todos os anos
x_ticks_menores <- 0; y_ticks_menores <- 0            # sem ticks menores
grade_x <- TRUE; grade_y <- TRUE                      # grade nos ticks maiores
grade_tipo <- "dashed"; grade_cor <- "#1F4E9E"; grade_opacidade <- 0.35
quebra_ativar <- TRUE                                 # acha sozinho o maior vazio entre os dados
cores_por_serie <- c("WORLD" = "#000000", "BRAZIL" = "#1F4E9E")
```

**Ajuda dentro do R:** `ajuda()` lista os blocos; `ajuda("eixo_x")` mostra cada parâmetro com as OPÇÕES e um exemplo de comando; `ajuda("tipos")` resume os tipos de gráfico. Apelidos funcionam: `ajuda("y2")`, `ajuda("violino")`, `ajuda("legenda")`.

**Errou um nome?** O template avisa e sugere: *"Parâmetro cfg$eixo_x$incremeto não existe. Você quis dizer cfg$eixo_x$incremento?"*.

## 3. Números: sempre ponto decimal

- A leitura detecta sozinha separador (`,` `;` tab `|`), codificação (UTF-8, latin1/Excel ou UTF-16 = "Texto Unicode" do Excel) e **vírgula decimal**, e converte tudo para ponto: `1.234,5` → `1234.5`.
- Valores como `n.d.` numa coluna numérica viram vazio (NA) e o relatório avisa a linha **do arquivo**.
- Linha com **mais ou menos campos** que o cabeçalho gera um aviso (antes, dados podiam ser embaralhados em silêncio).
- Colunas de **datas** (`2024-03-15`, `15/03/2024`, `15/03/2024 14:30`) aparecem como "data" no relatório e viram eixo de tempo (seção 3.1).
- Todos os rótulos dos gráficos saem com ponto decimal. Para forçar: `cfg$dados$decimal_virgula <- TRUE` (ou `FALSE`).

### 3.1 Eixo de datas e horas

Se a coluna X de um gráfico de pontos/linhas/áreas for uma data, o eixo passa a ser **proporcional ao tempo** (um intervalo de 1 mês ocupa o dobro de 15 dias), com ticks "redondos" (dias, semanas, meses, anos, horas). Veja o exemplo 31.

```r
cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- "1 mes"    # "2 semanas", "6 horas", "1 ano"...
cfg$eixo_x$inicio <- "01/01/2024"; cfg$eixo_x$fim <- "31/12/2024"
cfg$eixo_x$formato_rotulo_data <- "%d/%m/%Y"      # como as datas aparecem nos ticks
cfg$eixo_x$formato_data <- "%m/%d/%Y"             # só se o CSV for mês/dia/ano (o padrão é dia/mês/ano)
cfg$eixo_x$tempo <- FALSE                         # trata a coluna como categorias de texto (comportamento antigo)
```

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
| Mostrar 100 em vez de 100000 (÷ 1000) | `cfg$eixo_y$fator_divisao <- 1000` e no título `cfg$eixo_y$titulo <- "Intensidade (×10^{3} u.a.)"` |
| Título em negrito (eixos / título do gráfico) | `cfg$eixo_y$negrito_titulo <- TRUE`; `cfg$eixo_x$negrito_titulo <- TRUE`; `cfg$titulos$negrito_titulo <- TRUE` (funciona também com expoente) |
| Texto no lugar dos números | `ticks_modo <- "manual"; ticks_manuais <- c(0,5,10); rotulos_manuais <- c("a","b","c")` |
| Sobrescrito / subscrito | `cfg$eixo_x$titulo <- "Área (m^{2})"` ; `"CO_{2} (ppm)"` |
| Cor de uma série | `cfg$series[["Amostra A"]] <- list(cor = "#D62728")` |
| Paleta automática | `cfg$cores$paleta <- "brewer_YlOrRd"` (veja `mostrar_paletas()`) |
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
| Fundo, borda e sombra da legenda | `cfg$legenda$fundo <- "white"; cfg$legenda$fundo_opacidade <- 0.8; cfg$legenda$sombra <- TRUE` (no painel: bloco 11, `legenda_canto`, `legenda_sombra_*`) |
| Legenda dentro da caixa, maior/menor, distância da borda | `cfg$legenda$escala <- 0.8; cfg$legenda$distancia_pt <- 8` (a legenda "dentro" que passa da caixa é reduzida sozinha; `ajustar_caixa <- FALSE` desliga). Painel: `legenda_escala`, `legenda_canto`, `legenda_distancia_pt` |
| Gráfico em tamanho padrão | `cfg$caixa$painel_largura_cm <- 9; cfg$caixa$painel_altura_cm <- 6.5` — a caixa tem sempre esse tamanho e a página se ajusta ao conteúdo (`exportacao$ajustar_pagina`) |
| Distância entre título e números dos eixos | `cfg$eixo_y$distancia_titulo_pt <- 8` (também `eixo_x`, `eixo_y2`; no painel `y_distancia_titulo_pt`...) |
| Todos os pontos quadrados / formas à escolha | `cfg$cores$incrementar_simbolo <- FALSE; cfg$serie_padrao$simbolo <- "quadrado"` ou `cfg$cores$simbolos_ordem <- c("quadrado", "circulo")`. Painel: `simbolo_forma <- "quadrado"` |
| Bolinha 3D (esfera) | `cfg$series[["A"]] <- list(simbolo = "esfera")`; luz em `cfg$serie_padrao$esfera_luz`. Painel: `simbolo_forma_por_serie <- c("A" = "esfera")` |
| Grade | `cfg$grade$maior_y <- TRUE` |
| Grade com tipo, cor e transparência | `cfg$grade$maior_x <- TRUE; tipo_maior <- "dashed"; cor_maior <- "#1F4E9E"; opacidade_maior <- 0.4` |
| Linha de referência | `cfg$referencias <- list(list(eixo = "y", valor = 0, tipo = "dashed"))` |
| Texto / seta / faixa | `cfg$anotacoes$textos`, `$setas`, `$faixas` (ver `ajuda("anotacoes")`) |
| Eixo Y à direita pelo painel (bloco 7) | `y2_series <- "Temperatura"; y2_inicio <- 0; y2_fim <- 40; y2_intervalo <- 5; y2_cor <- "#C00000"; y2_titulo <- "Temperatura (°C)"` |
| Eixo Y à direita | `cfg$eixo_y2$ativo <- TRUE` + `cfg$series[["B"]] <- list(eixo = "y2")` (com ticks menores: `cfg$eixo_y2$n_menores`) |
| Eixo X como datas / horas | automático; `cfg$eixo_x$incremento <- "1 mes"`, `inicio <- "01/01/2024"`, `formato_rotulo_data <- "%d/%m/%Y"` (seção 3.1) |
| Ligar os pontos da esquerda para a direita | `cfg$linhas$ordenar_x <- TRUE` (padrão: segue a ordem das linhas do CSV) |
| Rótulos da pizza sobrepostos | já são afastados sozinhos; para desligar: `cfg$pizza$rotulos_afastar <- FALSE` |
| Ajuste fino da pizza (raio dos rótulos, linha guia) | `cfg$pizza$rotulos_raio_dentro`, `rotulos_raio_borda`, `linha_guia_espessura_pt`, `linha_guia_recuo`, `rotulos_margem` |
| Pontos do boxplot (enxame), bordas, tamanho do "n =" | `cfg$boxplot$enxame_resolucao`, `pontos_borda_pt`, `outliers_borda_pt`, `media_borda_pt`, `n_tamanho_pt` |
| Folga interna da legenda | `cfg$legenda$margem_interna_pt <- c(4, 6, 4, 6)` |
| Tamanho dos traços "//" da quebra de eixo | `cfg$quebra$marca_largura_pt`, `marca_altura_pt` |
| Tamanho dos tracinhos do rug | `cfg$distribuicao$rug_comprimento_pt`, `rug_espessura_pt` |
| Gráficos empilhados com X fixo | `cfg$paineis$ativo <- TRUE` + `cfg$paineis$lista` (ver exemplos 25 e 26) |
| Quebra no eixo Y | `cfg$quebra$ativo <- TRUE; de <- 20; ate <- 80`; estilo contínuo (uma moldura só, com `//` nas bordas): `cfg$quebra$estilo <- "continuo"` (padrão: `"separado"`) — não sabe qual trecho? `sugerir_quebra(dados)` acha o maior vazio e imprime as linhas prontas. Não ligar os pontos através da quebra: `cfg$quebra$ligar_atraves <- FALSE`; números das bordas se sobrepondo: `cfg$quebra$espaco_pt <- 14` |
| Fonte | `cfg$texto$fonte <- "Arial"; cfg$texto$tamanho_base_pt <- 10` |
| Tamanho e formato do arquivo | `cfg$exportacao$largura <- 8.5; altura <- 6; formatos <- c("tiff","pdf"); dpi <- 600` |
| Reaproveitar o visual | `salvar_estilo(cfg, "meu")` e depois `cfg <- carregar_estilo("meu", cfg)` |
| Mesmo gráfico para vários CSVs | `exportar_lote("dados", cfg)` |
| Voltar tudo ao padrão | `resetar_cfg()` |

## 5. Onde achar cada recurso

| Recurso | Aqui |
|---|---|
| Símbolo, linha e preenchimento | `cfg$serie_padrao` (todas as séries) e `cfg$series[["nome"]]` (uma) |
| Preenchimento em degradê de 2 cores | `cfg$cores$preenchimento = "gradiente"`, `gradiente_cor2`, `gradiente_direcao` |
| Cor e símbolo automáticos por série | `cfg$cores$paleta`, `incrementar_simbolo`, `incrementar_tipo_linha` |
| Escala do eixo (início, fim, tipo, intervalo, traços pequenos, primeiro traço) | `cfg$eixo_x$inicio`, `fim`, `escala`, `incremento`, `n_menores`, `primeiro_tick` |
| Linha e traços do eixo (para dentro/fora/ambos, comprimento, grossura) | `direcao_maiores`, `direcao_menores`, `comprimento_*_pt`, `espessura_ticks_pt` |
| Números do eixo (casas decimais, dividir por, prefixo/sufixo, rotação) | `casas_decimais`, `fator_divisao`, `prefixo`, `sufixo`, `rotacao_rotulos` |
| Título, grade, linhas de referência, quebra do eixo | `titulo`, `cfg$grade`, `cfg$referencias`, `cfg$quebra` |
| Moldura fechada | `cfg$caixa` |
| Dois eixos Y | `cfg$eixo_y2` |
| Gráficos empilhados / combinados | `cfg$paineis` |
| Boxplot (caixa, bigodes, percentis, outliers, entalhe, meia caixa, violino) | `cfg$boxplot` |
| Pizza (destacar fatia, rosca, ângulo inicial, rótulos, agrupar fatias pequenas) | `cfg$pizza` |
| Histograma (largura da barra, curva normal/kernel) | `cfg$distribuicao` |
| Estilo salvo / modelo | `salvar_estilo()` / `carregar_estilo()` em `estilos/` |
| Exportação (tamanho, DPI, formato) | `cfg$exportacao` |

## 6. Arquivos

| Arquivo | Para quê |
|---|---|
| `00_instalar_pacotes.R` | instala/atualiza pacotes (uma vez) |
| `01_config.R` | **todos** os parâmetros, cada um com descrição, OPÇÕES e EX. |
| `02_motor.R` | carregador do motor (não precisa editar). Você continua dando um único `source("02_motor.R")` |
| `R/` | o código do motor, um assunto por arquivo (leitura, eixos, tema, um arquivo por tipo de gráfico, exportação...). **Mantenha a pasta junto do `02_motor.R`** |
| `03_executar.R` | seu roteiro de trabalho |
| `04_catalogo.R` | `ajuda()`, `galeria()`, `mostrar_paletas()` |
| `R/21_ajustes.R`, `R/22_formas.R`, `R/23_imagens.R` | ajustes de curva, estatísticas e testes; caixas de estatística, textos, polígonos e figuras anexadas |
| `05_exemplos.R` | 32 exemplos prontos (um de cada tipo/recurso) |
| `06_testes.R` | 208 testes automáticos — rode depois de qualquer alteração no motor |
| `painel_de_ajustes.R` | **o painel**: variáveis simples por categoria (escala, ticks, grade, quebra, cores...). Veja a seção 2.1 |
| `07_verificar_windows.R` | confere fontes Arial/Times, PDF e gradiente no seu computador (seção 8) |
| `estilos/` | estilos salvos: `publicacao_classico`, `apresentacao`, `padrao_cientifico` |
| `dados/` | CSVs de exemplo (inclui um CSV de Excel em português com `;` e vírgula) |

## 7. Limitações conhecidas

- Gradientes exigem R ≥ 4.2 e não existem em EMF (o arquivo EMF sai com cor sólida, com aviso).
- No Windows, a aba Plots do RStudio só mostra gradientes com o backend **AGG** (passo 1.4). `visualizar()` e `salvar()` sempre funcionam.
- Eixo Y2 é linear. Quebra de eixo só no Y (não existe quebra do eixo X). O eixo de datas vale para pontos, linhas e áreas (em barras, pizza e boxplot a data continua sendo texto).
- Com datas, o fuso é sempre UTC (sem horário de verão) e o dia vem antes do mês, salvo `formato_data`.
- Sem gráficos 3D, mapas de contorno ou rótulos nos ticks menores.
- Interface com botões (Shiny) não incluída: é a "Fase 2" opcional descrita no prompt.

## 7. Mudou algo no seu `cfg`? Compatibilidade

Todos os nomes de parâmetros e funções da versão anterior continuam valendo. Parâmetros novos têm valor padrão que mantém o comportamento antigo (exceções: colunas de datas agora viram eixo de tempo — desligue com `cfg$eixo_x$tempo <- FALSE` — e rótulos de pizza que se sobrepunham agora são afastados). Se você substituir um bloco inteiro (`cfg$quebra <- list(...)`) ou usar um estilo salvo antes desta versão, os parâmetros que faltarem são completados com os padrões do `01_config.R`.

## 8. Verificação no Windows (uma vez, 1 minuto)

O template foi desenvolvido e testado em Linux. No Windows, abra o projeto (`graficos_R.Rproj`) e rode `07_verificar_windows.R` (Ctrl+Shift+S). Ele checa as versões dos pacotes, se as fontes **Arial** e **Times New Roman** existem, gera `saida/verificacao/arial.pdf|png` e `times.pdf|png` com gradiente e acentos, e imprime uma tabela OK/ATENÇÃO. Depois **abra os arquivos e confira com os olhos** (os passos estão no fim da saída). Também rode `06_testes.R`: deve terminar com `0 FALHOU`.

## Instalador do Windows (Cinabro-Setup)
Um único `Cinabro-Setup-<versão>.exe` (~125 MB): instala só para o usuário (sem administrador) um **R 4.5 portátil**, os **pacotes em versões fixas** e o app, com atalhos (menu Iniciar e área de trabalho) e desinstalador. Quem usa não precisa de R, RStudio nem internet. Ele é montado e **testado num Windows de verdade** pelo GitHub Actions (aba *Actions*, fluxo "Instalador do Windows", artefato `Cinabro-Setup-...`): testes do motor (242) e do app (80) com o mesmo R e os mesmos pacotes do instalador, gráfico em PNG/PDF/SVG, app subindo pelo lançador dos atalhos, e instalar, testar e desinstalar em silêncio. Detalhes, avisos (SmartScreen, antivírus, assinatura) e como gerar uma versão numerada (`git tag v0.1.0`): `instalador/LEIAME.md`.

**Atenção:** o nome deste repositório no GitHub é tão longo que, no Windows, o caminho passa do limite de 260 caracteres (o `git` falhou ao baixar o código no teste). O fluxo contorna isso; mas para clonar o repositório no Windows, ou baixar o ZIP do GitHub e extraí-lo, é melhor **renomear o repositório** para algo curto (ex.: `cinabro`) e extrair numa pasta curta (ex.: `C:\cinabro`).
