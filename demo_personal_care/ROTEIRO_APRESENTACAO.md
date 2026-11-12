# Cinabro — roteiro da apresentação (≈ 12 min)
**Tema:** ativos de personal care — *"Projeto Aurora: do ativo ao protótipo vencedor"*
**Aviso:** todos os dados são **fictícios** (gerados por fórmulas) e servem só para mostrar a ferramenta. Diga isso logo no início; o título do dashboard já traz "dados ilustrativos".

## A ideia da história
Uma equipe de Personal Care precisa decidir **qual ativo e qual formulação levar ao mercado** num sérum antissinais. Cada gráfico responde a uma pergunta da decisão, e juntos viram um dashboard de uma página. Para a plateia o recado é: *da planilha à decisão, sem sair da ferramenta*.

## Preparação (10 min antes)
1. Abra o Cinabro (`abrir_app.bat`) e deixe na aba **Gráfico 1**.
2. Tenha a pasta `projetos/` à mão: **Abrir projeto** carrega dados + configuração de uma vez.
3. Deixe aberto, em outra janela, `dashboard_pt.html` (plano B se algo falhar) e `imagens/`.
4. Teste o giro do 3D uma vez (ato 5) para o computador "esquentar".

## Os 9 atos

| # | Pergunta de negócio | Projeto (.cinabro) | O que dizer | O que mostrar no Cinabro |
|---|---|---|---|---|
| 0 | Abertura | — | "Vou mostrar como uma planilha vira uma decisão de formulação, em 12 minutos. Dados fictícios." | Tela inicial; passe o olho pelos 7 blocos à esquerda. |
| 1 | **Por que agora?** | `01_tendencia` | "O interesse por **bakuchiol** foi de 6 a 81 em 5 anos e os **peptídeos** decolaram. Niacinamida já é mainstream; retinol é a referência." | Linhas com data no eixo X. Mostre que a 1ª coluna virou data sozinha. |
| 2 | **Quem entrega resultado?** | `02_eficacia` | "Retinol lidera (31%), mas o **bakuchiol entrega 85% disso**, com menos irritação. As barras de erro são o desvio das 30 voluntárias." | Barras com barras de erro (coluna de desvio ligada a uma série). |
| 3 | **Quanto basta?** | `03_dose` | "Mais não é melhor: com 4% a niacinamida já dá ~70% do ganho máximo. Dobrar a dose compra só 13 pontos." | **Ajuste de curva** (fórmula a·x/(b+x)): abra *Ajuste de curva* e mostre a equação e o R² numa caixa de estatística. |
| 4 | **Aguenta o prazo de validade?** | `04_estabilidade` | "Livre, o retinol cai para 22% em 12 semanas a 40 °C. **Encapsulado, mantém 79%.**" | Três ajustes exponenciais numa só ação (série = todas). |
| 5 | **Onde está a janela ótima?** | `05_janela` | "Eficácia em função de pH e concentração. O pico está em **pH 5,5 e 3,5%**; fora dessa janela despenca." | ⭐ **Momento uau:** *arraste o gráfico* para girar; clique **⟲ Girar**; mostre **Topo** (mapa de calor visto de cima) e **Frente**. Depois mude *Perspectiva* e *Profundidade* nos campos. Troque para **Mapa de cor** (gradiente contínuo, sem quadradinhos). |
| 6 | **O ativo chega onde precisa?** | `06_penetracao` | "Concentração por profundidade, em 6 tempos: o ativo continua chegando por horas." | Linhas 3D (cascata): cada coluna da planilha é um tempo. Gire de novo, rápido. |
| 7 | **Qual protótipo vence?** | `07_prototipos` | "A fórmula **C** (bakuchiol + peptídeos) é a mais equilibrada; a B ganha em estabilidade e a A em custo." | Radar: troque a posição da legenda, o formato da grade (círculo/polígono). |
| 8 | **Onde cada ativo brilha?** | `08_beneficios` | "Ninguém é bom em tudo: o mapa de calor mostra a vocação de cada ativo." | Mapa de calor com os valores nas células. |
| 9 | **Onde lançar primeiro?** | `09_mercado` | "Sudeste e Sul abrem o caminho." | Mapa do Brasil colorido por estado. |
| ✔ | **Fechamento** | `dashboard_pt.html` | "Tudo isso numa página, pronta para o comitê." | Veja abaixo. |

## O fechamento: dashboard (2 min)
- No app, com os gráficos em abas, clique **Dashboard** → escolha as abas → o editor abre em tela cheia. Mostre: **mover blocos**, **editar o texto dos destaques**, **identidade (cores/logo da empresa)** e **PDF**.
- Se faltar tempo ou algo falhar: abra `dashboard_pt.html` (já pronto, com os números-chave da história) ou mostre `dashboard_pt.pdf` (2 páginas A4).

## Três "uau" para não esquecer
1. **Girar o 3D com o mouse** (ato 5) — rotação circular, vistas prontas e giro contínuo.
2. **Trocar o idioma** (seletor no topo: Português → English → Español): a tela e o gráfico continuam onde estavam. Faça isso depois do ato 5; ótimo para equipes globais.
3. **Tudo é editável sem programar**: clique no título do gráfico para editar; arraste a legenda; mude cores, escalas e intervalos nos blocos à esquerda.

## Perguntas que podem aparecer
- **"Meus dados vêm do Excel."** Salve como CSV (separador `;` e vírgula decimal funcionam). Os modelos de planilha estão na pasta `modelos_csv/`.
- **"Posso colocar o logo e as cores da empresa?"** Sim, no editor do dashboard (identidade institucional) e na paleta dos gráficos.
- **"Roda sem internet?"** Sim, tudo local; os dados não saem do computador.
- **"Exporta para o Word/PowerPoint?"** PNG, PDF, SVG e EMF (vetorial, editável no Office).
- **"É confiável estatisticamente?"** O ajuste de curva mostra equação, R², RMSE, AIC/BIC; há ANOVA/Tukey etc. em *Tabelas e testes*.

## Se algo der errado (plano B)
- Pasta `imagens/`: um PNG de alta resolução por gráfico.
- `dashboard_pt.html` / `dashboard_pt.pdf`: a página final pronta.
- Cada `.cinabro` abre o gráfico já configurado: se um ajuste "estranhar", abra o projeto de novo.

## Observação sobre as afirmações
Frases como "bakuchiol com menos irritação" refletem o que se discute na literatura, mas **os números do exemplo não são de estudo real**. Se a plateia perguntar, diga que são ilustrativos e que a ferramenta serve para os dados reais da equipe.
