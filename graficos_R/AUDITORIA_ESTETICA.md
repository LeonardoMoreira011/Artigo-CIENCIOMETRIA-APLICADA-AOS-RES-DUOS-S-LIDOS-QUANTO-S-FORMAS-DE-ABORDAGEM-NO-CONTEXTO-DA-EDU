# Auditoria estética dos novos gráficos (mapa de calor, PCA, CA, CCA, mapas)

Feita olhando as figuras como três pessoas: **analista de dados** (dá para ler e interpretar sem erro?), **designer** (hierarquia, ritmo, contraste, espaço) e **revisor de periódico** (tem algo que não precisa estar ali?). Cada achado virou uma correção.

## O que a primeira versão errava e o que mudou

| # | Achado | Critério | Correção |
|---|---|---|---|
| 1 | **Eixos com escalas diferentes** no biplot (1 unidade no X ≠ 1 unidade no Y): os ângulos entre setas e as distâncias entre amostras ficavam deformados. | Interpretação correta | `escala_igual` (padrão): os limites dos dois eixos seguem a proporção da caixa, então 1 unidade ocupa o mesmo comprimento nos dois eixos. |
| 2 | **Nomes sobre setas, pontos e uns sobre os outros** ("Draco" + "pH", "Eridanus" + "Salinidade"); nomes de variáveis e de ambientais não se enxergavam entre si. | Legibilidade | Posicionador próprio: cada nome escolhe, em volta do seu ponto/seta (de preferência para fora da origem), o lugar que não cobre pontos, corpo das setas, pontas e outros nomes, sempre dentro do painel. Nomes que precisam sair ganham um **fio** até o ponto. |
| 3 | **Posição dos nomes não editável.** | Controle do autor | **Arraste o nome no gráfico**: a posição vai para o campo "Posição dos nomes que você moveu" (e para o código/projeto). Duplo clique devolve à posição automática. Vale no PCA/CA/CCA e nos nomes dos mapas. |
| 4 | Pontos das **variáveis (CA/CCA) com o mesmo triângulo** de um dos grupos: o leitor confunde espécie com amostra. | Distinção | Variáveis em **cruz** (editável: símbolo, tamanho, cor); amostras seguem a forma e a cor de cada grupo. |
| 5 | Setas **por cima** dos pontos. | Hierarquia | Ordem das camadas: elipses → linhas de zero → setas → pontos → nomes. |
| 6 | **Legenda sem título**: o leitor não sabe o que "A, B, C" significam. | Informação necessária | O título da legenda é o nome da coluna dos grupos (editável). |
| 7 | Legenda **dentro** do gráfico cobrindo pontos. | Legibilidade | Fora do gráfico por padrão (`legenda_posicao`); "Dentro do gráfico" continua possível e arrastável. |
| 8 | Números dos eixos **no canto se encostando** (−3 do X sobre −3 do Y). | Limpeza | Os limites seguem os dados + folga (não arredondam para um número do eixo); nenhum traço fica no canto. |
| 9 | **Elipses cortadas** pela moldura. | Fidelidade | As elipses entram no cálculo dos limites. |
| 10 | Muitas variáveis (30) viravam uma **nuvem de nomes**. | Eficiência | Só as 20 que mais pesam no plano mostram nome (`max_variaveis`, editável); fio quando preciso. |
| 11 | **Mapa de calor com traços de eixo** dentro das células e uma legenda "dentro" cobrindo o gráfico. | Tinta sem informação | Sem traços por padrão (só os nomes); barra de cores à direita, com o nome do valor; topo da escala menos "preto" (`#7E1B22`). |
| 12 | **Mapas com faixas brancas** enormes em cima e embaixo, e nomes de região em cima uns dos outros (LATAM/Brazil). | Espaço | A caixa do mapa tem a **proporção do mapa**; nomes e valores usam o mesmo posicionador (no local se couber, ao lado com fio se não), cor automática pelo contraste do fundo, e podem ser arrastados. |
| 13 | **Barra de cores e texto da legenda maiores que os eixos.** | Hierarquia | Barra mais fina; tamanho do texto continua pelo bloco Fonte. |

## Resumo estatístico

A caixa de resumo (abrangência dos dois eixos, inércia restrita, testes) escolhe sozinha o retângulo que **não toca** pontos, corpo das setas nem nomes (mede o texto real); se o gráfico estiver cheio demais, o resumo pode ir para uma linha sob a figura.

## Tudo é editável

- **Texto:** fonte, tamanho, negrito, itálico e cor de cada tipo de nome (amostras, variáveis, ambientais e nomes do mapa); número nas células do mapa de calor.
- **Símbolos:** forma, cor, tamanho, contorno e nome na legenda de cada **grupo** (tabela de grupos, aba Cores); símbolo e tamanho das variáveis.
- **Setas e elipses:** grossura, tamanho e tipo da ponta, cor, preenchimento leve da elipse.
- **Posição:** de cada nome (arrastando), da legenda (arrastando, com "Dentro do gráfico") e da barra de cores.
- **Cores do gradiente:** esquema pronto ou as suas cores, limites, centro, inversão.

## O que ainda depende de julgamento

- A cor do **fundo dos mapas** é branca e os locais sem dado ficam em cinza claro; se o mapa for impresso em escala de cinza, vale usar o esquema "petróleo".
- Em PCA com muitas amostras sobrepostas, **transparência** dos pontos ajuda: ajuste a "opacidade" na tabela de grupos.
- Nomes de região/país muito próximos podem continuar pedindo um ajuste manual (arrastar); o posicionador resolve os casos comuns, não todos.
