# Auditoria do Cinabro — o que temos, o que custa e o que cortar

Princípio: **menos é mais — o simples, objetivo e bem feito.** Nada foi cortado ainda; este documento só mede e propõe. Cada corte precisa da sua aprovação.

## 0. O que foi medido e o que NÃO foi

| | |
|---|---|
| **Medido (sandbox Linux, 4 núcleos, R 4.4.3, ggplot2 4.0.3 / 3.5.2)** | tempo de cada etapa do gráfico, montagem da tela, navegador (Chromium com CPU 4× mais lenta), memória em sessão longa, escala de dados, figuras anexadas, arquivos CSV estranhos, 2.027 valores hostis nos campos |
| **Seu PC (diagnóstico de 23/10, seção 2.6)** | ambiente e tempos de gráficos pequenos medidos. **Ainda falta o `app.log` de uso real** e o tamanho típico dos seus CSVs |
| **Não dá para medir** | *quais recursos o time usa*. O registro de uso grava tempos e erros, mas não grava quais campos são mexidos. Sem isso, "uso" na tabela da seção 5 é julgamento meu, não dado |

## 1. Veredito em uma tela

1. **O navegador não é o problema.** Tela com 5.362 elementos, 481 painéis condicionais, 695 campos: o navegador gasta 0,2–0,5 s de script ao abrir e ~20 ms por campo alterado (90 ms com CPU 4× mais lenta); memória do navegador 8 MB.
2. **O gargalo é o R, que faz uma coisa de cada vez.** Enquanto ele monta um gráfico, nada mais responde. Quem mexe em vários campos seguidos enfileira trabalho. É exatamente o sintoma "trava e não carrega os demais comandos".
3. **Cada atualização monta o gráfico 4 vezes** (montar + desenhar + medir legenda + medir títulos) quando bastaria 1. Com poucos pontos são ~1,2 s; com **50 mil pontos (comum em dados de sensor) são ~30 s por clique**; com 200 mil, 76 s.
4. **A causa mais provável da "tela cinza"** é o R ter terminado, não o navegador travar. O app manda o R fechar 6 s depois que a aba desconecta (suspensão do PC, aba "dormindo" do Edge/Chrome, antivírus). Além disso, **um campo numérico com valor absurdo (um zero a mais em "ticks menores") faz o R consumir > 8 GB** e o Windows congelar (seção 3).
5. **A interface é maior do que o objetivo.** 14 painéis, 646 campos (446 só nos cartões de ajuste/forma/figura, que quase ninguém abre), 66 paletas, 74 fontes, 3 idiomas, 5 formas de abrir o programa. O gráfico ocupa ~55% da altura da janela; o resto é moldura.
6. **O que está bom:** 17 tipos de CSV defeituoso não derrubam a sessão; memória e arquivos temporários estáveis em 60 atualizações seguidas; 226 testes do motor + 73 do app passam.

## 2. Números medidos

### 2.1 Quanto custa uma atualização do gráfico (13 pontos × 5 séries)
| Etapa | Tempo | Observação |
|---|---|---|
| montar o gráfico (`plotar`) | 0,35 s | 1 construção do ggplot |
| desenhar o PNG da prévia | 0,30 s | **reconstrói** o gráfico |
| medir a legenda (para arrastar) | 0,25 s | **reconstrói** o gráfico |
| medir os títulos (para clicar) | 0,24 s | **reconstrói** o gráfico |
| **total** | **~1,15 s** | 82% do tempo é `ggplot_gtable` repetido 4× |
| `montar_variaveis` (646 campos) | 9 ms | não é problema |
| primeiro gráfico num R recém-aberto | +2,4 s | frio (fontes, pacotes); no navegador: 7,8 s da escolha do exemplo até a prévia |

### 2.2 Escala (mesma máquina)
| Dados | montar | desenhar | medir | **total por clique** |
|---|---|---|---|---|
| 500 pts × 3 séries | 0,5 | 0,4 | 0,7 | 1,6 s |
| 5.000 pts × 3 | 1,2 | 1,1 | 1,7 | 4,0 s |
| **50.000 pts × 3** | 8,3 | 8,6 | 13,6 | **30 s** |
| **200.000 pts × 2** | 17,9 | 22,6 | 35,6 | **76 s** |
| 1.000 pts × 20 séries | 2,7 | 1,5 | 2,2 | 6,4 s |
| 1.000 pts × 40 séries | 3,9 | 2,4 | 3,8 | 10 s |
| 100 colunas no CSV | — | — | — | 7,3 s |

Construir **uma** vez o ggplot de 50 mil pontos custa 7,3 s; com a prévia reduzida a ≤ 1.500 pontos (preservando picos), 0,34 s. O arquivo exportado continuaria com todos os pontos.

### 2.3 Tela e navegador
| Item | Valor |
|---|---|
| Montar a tela no servidor (**a cada aba/recarga**, bloqueia o R) | 1,8 s (0,6 construir + 1,1 renderizar + traduzir) |
| HTML da página | 512 KB, 5.572 tags, 695 campos (410 deles nos blocos 13 e 14), 481 painéis condicionais, 134 listas |
| Navegador (CPU normal / 4× mais lenta) | abre em 2,4 / 3,0 s; script 0,2 / 0,5 s; heap 8 MB |
| Trocar de aba de gráfico | 646 atualizações de campo, 642 mensagens, **~10 s** no total (+ uma "trava" fixa de 1,8 s que é um chute de tempo) |
| Altura útil do gráfico | ~510 px de 900 (57%); em notebook de 768 px, ~49% |

### 2.4 Figuras anexadas
Um PNG de 4,3 MP (13 MB): fica **138 MB em memória para sempre** (a cache nunca esvazia; cada novo envio soma mais 138 MB: 4 envios = 553 MB) e a conversão para desenhar leva **4 s a cada atualização**, usando 278 MB temporários.

### 2.5 Sessão longa
60 atualizações seguidas: memória 123 → 124 MB, 1 arquivo temporário, 1 dispositivo gráfico. **Sem vazamento** (o vazamento de PNGs da prévia foi corrigido antes desta auditoria).

### 2.6 Medido no seu PC (diagnóstico de 23/10/2026)
| Item | Seu PC (R 4.6.1, Win 10, 8 núcleos, 15,7 GB) | Sandbox |
|---|---|---|
| Pacotes | ggplot2 4.0.3, ragg 1.5.2, systemfonts 1.3.2, shiny 1.14.0, todos únicos e atuais | — |
| Carregar o motor | 0,15 s | — |
| Linha com pontos (dados de exemplo) | 0,53 s | ~1,15 s* |
| Barras | 0,43 s | — |
| Dois eixos Y + quebra | 0,91 s | — |
| Ajuste + caixa de estatística + forma | 0,74 s | — |
| Montar variáveis de 646 campos | 14,8 ms | 9 ms |
| Memória do processo em 25 usos | 414 → 417 MB (estável) | estável |
| Arquivos temporários | +1 por uso (0,04 MB cada) | — |

\* o sandbox media sob carga simultânea; o seu PC é **tão rápido quanto** ele, ou melhor. **A máquina não é o problema.**
Os arquivos temporários crescem porque o próprio script de diagnóstico não apaga as prévias que desenha; o app apaga (corrigido e testado antes da auditoria).
**Limite deste teste:** usa só os 4 cenários de exemplo (poucos pontos). Com os seus CSVs reais o custo de montar 4 vezes (seção 2.2) é o que aparece.

## 3. Robustez (o que derruba ou congela)

**Confirmado (reproduzido):**

* **O limite dos campos é só enfeite do navegador.** `x_ticks_menores` tem `max = 20`, mas digitar 10.000.000 faz o navegador enviar 10.000.000 ao R (verificado no navegador). O R passa de **8 GB** de memória nesse cálculo e, no sandbox, foi encerrado pelo sistema (exit 137). No Windows isso vira disco lento e tela congelada. O mesmo ocorre em `quebra_y2_ticks_menores_inferior` e provavelmente nos campos irmãos. Dos 298 campos numéricos, **204 não têm limite máximo nenhum**.
* **CSVs defeituosos**: 17 casos (vazio, só cabeçalho, uma coluna, tudo texto, nomes repetidos, BOM, Latin-1, coluna só de NA, datas, 100 colunas, arquivo binário, Inf/1e300, xlsx renomeado...) → **0 erros que derrubam a sessão**; os problemas viram aviso na tela (algumas mensagens ainda mostram nomes de código).
* **Sessão longa**: sem vazamento (seção 2.5).

**Varredura de valores hostis (concluída): 2.027 casos** (negativo, zero, 0,0001, 10.000.000, NA, texto vazio/de 3.000 caracteres/com aspas, cores inválidas), em todos os 646 campos, com limite de 4,5 GB de memória por processo (sem esse limite o R simplesmente continua alocando).

| Resultado | Casos |
|---|---|
| Erros que escapam e derrubariam a sessão (fora de `tryCatch`) | **0** |
| **Estouro de memória com 10.000.000** (pede 1,5 GB de uma vez; sem limite, passa de 8 GB) | **9 campos**: `x_ticks_menores`, `y_ticks_menores`, `y2_ticks_menores`, `quebra_y_ticks_menores_superior/inferior`, `quebra_y2_ticks_menores_superior/inferior`, `legenda_n_linhas`, `legenda_n_colunas` |
| Lentos sem estourar memória | tamanho de fonte **negativo** (`-5`) em títulos/números dos eixos: **14 a 19 s** (`y_titulo_tamanho_pt`, `y2_numeros_tamanho_pt`, `y2_titulo_tamanho_pt`); `ticks menores` inferior da quebra = 10 milhões: 15 s; `legenda_largura_pt` = 10 milhões: 2,8 s |
| Tempo típico por caso | mediana 0,8 s, p95 1,2 s |
| Avisos | `formatC: 'digits' reduced to 324` quando as casas decimais ficam enormes |

Leitura: o programa trata bem texto e dado ruim, mas **não valida número**. Um zero a mais digitado, ou um "-" na frente do tamanho da fonte, trava o R por segundos ou o derruba por memória. A correção é pequena e central: **o servidor aplicar o `min`/`max` que cada campo já declara** (e declarar máximo nos 204 campos que não têm), em vez de confiar no navegador.

## 4. Hipóteses para "tela cinza e lenta", por probabilidade

| # | Hipótese | Evidência | Como confirmar no seu PC |
|---|---|---|---|
| 1 | **R encerrado pelo próprio atalho** 6 s após a aba desconectar (PC suspenso, aba dormindo, antivírus) | código (`servidor.R`, `iniciar.R`); o cinza do Shiny aparece quando a sessão acaba | `app.log`: "sessão fechada" sem você ter fechado a aba; depois a janela do R some |
| 2 | ~~Ambiente velho/misturado~~ (R 4.2.1, `shiny` ausente, ggplot2 duplicado, ragg 1.2.2) | **RESOLVIDO**: o diagnóstico de 23/10 mostra R 4.6.1 e todos os pacotes atuais e únicos | nada a fazer |
| 3 | **Dados grandes**: 30–76 s por clique, fila de cliques atrás | seção 2.2 | `app.log`: tempos "montar/total" altos; quantas linhas tem o seu CSV típico? |
| 4 | **Valor numérico absurdo** num campo (9 campos estouram memória; fonte negativa trava 14–19 s) | seção 3 | `app.log` termina sem "sessão fechada"; memória do R alta no Gerenciador de Tarefas |
| 5 | **Figura grande anexada**: 4 s por clique + centenas de MB | seção 2.4 | PNG/JPEG de vários MP no bloco 14 |
| 6 | Falha nativa do ragg/systemfonts antigos | plausível com ragg 1.2.2; não reproduzido | janela do R fecha sozinha, sem mensagem |
| 7 | Erro não tratado num observador (mata a sessão) | **não encontrado** nos testes hostis | `app.log`: "ERRO não tratado" |

## 5. Auditoria por recurso (manter · esconder · reduzir · cortar)

Critério: valor para o time × custo (tempo, tela, manutenção). "Uso" = julgamento meu; ver seção 0.

| Recurso | Tamanho hoje | Veredito | Por quê |
|---|---|---|---|
| Dados (CSV/exemplos, resumo, escolher colunas) | 7 campos | **Manter** | É a entrada |
| Tipo de gráfico (11 tipos) | 1 campo | **Manter** | núcleo |
| Eixos: intervalos, escala/log, números, títulos | 27 + 8 + 24 campos, 3 painéis | **Manter, fundir em 1 painel "Eixos"** | mesma tarefa em 3 lugares |
| Cores, linhas e símbolos | 15 campos | **Manter** | núcleo |
| Fonte e tamanhos | 15 campos (+74 fontes) | **Manter; lista curta** (Barlow + as seguras) | 74 fontes é ruído |
| Legenda (posição, arrastar) | 33 campos | **Manter o essencial; sombra/borda/colunas em "avançado"** | arrastar é o que se usa |
| Moldura/tamanho + Exportação | 5 + 7 campos | **Manter, fundir em "Exportar"** | mesma tarefa |
| Eixo Y2 | 36 campos | **Esconder atrás de "+ eixo Y direito"** | só quem tem 2 escalas |
| Quebra do eixo Y | 21 campos | **Esconder atrás de "+ quebrar eixo"** | caso específico |
| Grade | 11 campos | **Fundir em Eixos** | |
| Ajustes e estatística (bloco 13) | **214 campos**, 4+3+3 cartões fixos | **Manter o recurso; cartões sob demanda ("+ ajuste")** | 214 campos montados para ninguém ver |
| Caixas de texto/polígonos (bloco 14) | **196 campos**, 6+3 cartões fixos | **Manter o recurso; cartões sob demanda** | idem |
| Figuras anexadas | 3 cartões | **Manter, corrigindo memória** (≤ 1.200 px, cache limitada) | hoje custa 4 s e 138 MB por figura |
| Paletas | 66 | **Reduzir para ~12** (as 5 do Cinabro + 2 sequenciais + 2 divergentes + 3 daltônico-seguras) | quem precisa de mais cria a própria |
| Abas de gráficos | troca de ~10 s, 646 mensagens, truque de 1,8 s | **Decidir** (ver seção 7) | caro e frágil nesse desenho |
| "Mostrar outra aba ao lado" | 1 gráfico extra renderizado | **Cortar** | dobra o custo; em tela pequena não cabe |
| Congelar blocos + copiar/colar modelo + salvar/carregar configuração | 3 mecanismos para "reaproveitar ajustes" | **Manter só salvar/carregar + Estilos prontos**; congelar só se ficarem abas | redundância |
| Idiomas EN/ES | 950 + 950 linhas JSON + 505 linhas no motor + READMEs | **Congelar** (manter, sem evoluir) ou cortar | toda frase nova custa 3 textos |
| Código equivalente (texto, copiar, baixar .R) | 3 controles | **Manter, dentro de Exportar** | reprodutibilidade |
| Faixa de ferramentas (Ajuste, Média±DP, Caixa, Tabelas, Texto, Forma, Figura) | 7 botões | **Manter** | é o atalho dos cartões |
| Edição no gráfico (clicar título/eixo) | 2 medições extras por atualização | **Manter**, mas medindo com a *mesma* construção do desenho | custo some com a correção 1 |
| Cabeçalho com letreiro (112 px) | | **Reduzir para ~52 px** | come 12% da altura |
| Endereço `cinabro.localhost:8421` | | **Cortar** → `127.0.0.1` | enfeite que pode falhar com proxy/IPv6 |
| `painel_de_ajustes.R` (script editável) | 312 linhas + teste de cobertura | **Decidir** | 3ª interface paralela |
| `graficos_R_completo.R` (arquivo único) | 748 KB, 10.644 linhas, **versionado** | **Gerar no empacotamento, não versionar** | duplicata de `R/` |

## 6. Dívida do repositório e da entrega

* 5 formas de abrir: `abrir_app.bat`, `abrir_app.R`, atalho `.bat`, `.ps1`, `.vbs` (+ `iniciar_gerador_oculto.vbs`, `painel_de_ajustes.R`, `03_executar.R`). **Deve ser 1** (instalador + atalho).
* `Rplots.pdf` perdido na raiz; `saida/exemplos/` (32 PNGs, 1,8 MB) e `galeria_referencia.pdf` são saída de teste, não produto.
* `RELATORIO_REVISAO.md` está velho (diz 82 testes; hoje são 226 + 73). `LEIAME.md` (280 linhas) tem duas seções "7" e mistura histórico de versões com instruções.
* O `abrir_app.bat` só instala pacote se **faltar**; não confere versão (foi assim que o seu R ficou com ragg 1.2.2 e ggplot2 duplicado). O instalador com versões fixas resolve.
* Cada opção nova toca ~6 lugares (config, painel, validação, espec, 2 JSON de idioma, motor-tradução, testes). É por isso que o projeto cresce mais rápido do que se mantém.
* Erros mostram nomes de código ao usuário ("Defina cfg$grafico$colunas_y").
* Peso na tela: Font Awesome (253 KB) só para 2 ícones, fonte Kaushan (206 KB) só para a frase, emblema SVG 92 KB. Local não pesa; some quando o instalador embutir, mas é lixo.

## 7. Plano proposto (nada executado)

Ordem por **ganho ÷ esforço**; as fases 1 e 2 não tiram nenhum recurso.

### Fase 1 — Corrigir (sem perder recurso)
| # | O quê | Ganho medido/estimado | Esforço |
|---|---|---|---|
| 1 | **Um único ggplot por atualização**: desenhar e medir legenda/títulos com o mesmo objeto | −55% em toda atualização (1,15 → ~0,5 s) | pequeno |
| 2 | **Prévia reduzida acima de 5 mil pontos** (mín./máx. por faixa, picos preservados), com aviso "prévia simplificada; o arquivo exportado usa todos os pontos" | 50 mil pts: 30 s → ~1 s; exportação intacta | médio |
| 3 | **Tela montada uma vez por idioma** e reaproveitada | −1,8 s por aba/recarga, e o R não fica bloqueado | pequeno |
| 4 | **Servidor aplica `min`/`max` de cada campo** (e máximo nos 204 que não têm; ticks menores ≤ 20, fonte ≥ 1 pt, colunas/linhas da legenda ≤ 50) | impede os 9 estouros de memória e as travas de 14–19 s | pequeno (a lista de limites já existe no `espec.R`) |
| 5 | **Não fechar o R por desconexão curta**: tolerância de 10 min + botão "Sair" visível; endereço `127.0.0.1` | elimina a hipótese 1 | pequeno |
| 6 | **Figuras**: reduzir para ≤ 1.200 px ao ler, guardar o raster pronto, cache de no máximo 3 | −4 s por atualização, −130 MB por figura | pequeno |
| 7 | **Aquecer o motor** ao abrir o app (um gráfico de 5 pontos antes de liberar a tela) | primeiro gráfico 7,8 → ~3 s | pequeno |
| 8 | **Registrar no log quais campos mudam** (só os nomes) | transforma "uso" em dado em 2 semanas de beta | pequeno |

### Fase 2 — Cortar interface (precisa do seu OK em cada linha)
1. Cartões de ajuste/marca/caixa/forma/figura **sob demanda** (botão "+"): 695 → ~250 campos, HTML 512 → ~180 KB.
2. 14 painéis → **7**: Dados · Eixos · Séries (cores/símbolos) · Texto · Legenda · Análise (ajustes + formas + figuras) · Exportar.
3. Y2 e quebra de eixo só aparecem quando ligados.
4. Paletas 66 → ~12; fontes 74 → lista curta.
5. Cabeçalho 112 → ~52 px.
6. Cortar "outra aba ao lado" e "copiar/colar modelo".

### Fase 3 — Entrega
Instalador Windows (R 4.5 portátil + pacotes com versão fixa + atalho com o ícone + log em `%LOCALAPPDATA%`), `graficos_R_completo.R` gerado no empacotamento, repositório limpo (itens da seção 6), **um** LEIAME de 1 página.

### Decisões que preciso de você
1. Aprova a **Fase 1** inteira? (corrige, não tira nada)
2. **Abas**: (a) manter e refazer a troca sem as 646 mensagens, (b) manter como está, (c) cortar e deixar "Duplicar gráfico" abrindo outra janela do navegador, (d) cortar de vez?
3. **EN/ES**: manter, congelar ou cortar?
4. **Dados do time**: qual o maior CSV típico (linhas)? Define o limite da prévia reduzida.
5. **Fase 2**: aprova os 6 itens, ou quais?
6. Pode me mandar o `diagnostico_cinabro_resultado.txt` e o `app.log` (depois de instalar R ≥ 4.5)? Confronto cada hipótese da seção 4 com o seu PC.
