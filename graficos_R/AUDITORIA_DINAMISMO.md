# Pente fino: o que é dinâmico e editável (gráficos 3D, mapas, radar)

Revisão feita campo a campo nos blocos de 3D, mapa de cor, mapa de calor, mapas e radar. Critério: "menos é mais" — só entra o que o usuário realmente ajusta.

## O que foi feito nesta rodada
| Tema | Antes | Agora |
|---|---|---|
| **Paletas do gradiente (eixo Z)** | 8 opções escolhidas pelo desenvolvedor | **32 paletas** do catálogo único, com busca e amostra de cor; valem também para as séries |
| Paletas e compatibilidade | nomes curtos (`petroleo`, `azul`...) | continuam valendo (viram `petroleo_degrade`, `azul_degrade`...); projetos antigos abrem iguais |
| **Divergentes** (RdBu, BrBG, PiYG, RdYlBu, RdYlGn, Cinabro) | exigiam o "Centro" manual | o centro cai em **zero** sozinho quando os dados passam por zero (o campo Centro manda se preenchido) |
| **Barra de cores** | só a posição | também **altura** e **largura** (bloco "mais opções") |
| **Giro 3D** | arrastar, Girar, vistas | + botões **Perspectiva** e **Grade** e leitura do ângulo ao vivo |
| Eixos 3D de lado/de cima | números empilhados | só ficam os números que cabem; eixo Y vai para o lado oposto ao Z em vista de frente/trás |

## Já era dinâmico (verificado)
Ângulo, altura do olhar, profundidade do eixo Y, perspectiva, altura do eixo Z, caixa, grade (mostrar e grossura), arestas, traços, estilo de cada eixo (cor, grossura, fonte, tamanho), suavização, sombreado, linhas de nível, faixas de cor, limites e intervalo da barra, cores próprias, inverter. No radar: anéis, escala, grade, opacidade, pontos, legenda.

## Ideias avaliadas e deixadas de fora (por ora)
- **Eixo Z logarítmico**: raro nos casos de uso atuais; fácil de acrescentar se aparecer pedido.
- **Cor única nas barras 3D** (sem gradiente): já dá com "As suas cores" (duas cores iguais); um botão próprio só aumentaria o número de campos.
- **Aplicar a mesma paleta a todas as abas** de uma vez: o bloco *Congelar* já mantém o estilo entre abas.
- **Controles deslizantes** para os ângulos: o arraste e as vistas prontas resolvem melhor; os campos numéricos ficam para valores exatos.

## Onde olhar no código
`R/02_cores_texto.R` (catálogo, grupos, divergentes), `R/25_tipo_mapas.R` (`.base_gradiente`, `.escala_z`), `app_shiny/codigo/espec.R` (`opcoes_gradientes`), `app_shiny/www/app.js` (barra de giro), testes em `06_testes.R` e `app_shiny/testes_app.R`.
