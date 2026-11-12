# Validação estatística do Cinabro

Compara, para os mesmos dados, **três fontes**: o **Cinabro**, o **R puro** (funções `stats`, sem o Cinabro) e o **Python** (scipy 1.18.1 e statsmodels 0.15.0 — implementações independentes do R).

**Resultado: 170 de 170 grandezas concordam dentro da tolerância** (18 casos).

Tolerância: diferença relativa ≤ 1e-6 nos cálculos diretos (regressões por mínimos quadrados e testes) e ≤ 1e-4 nos ajustes não lineares (métodos iterativos, que param em critérios diferentes).

## Resumo por caso

| Caso | Grandezas comparadas | Concordam | Maior diferença relativa (Cinabro × Python) |
|---|---|---|---|
| Regressão linear (cars) | 18 | 18 | 1.36594e-14 |
| Polinomial grau 2 (cars) | 24 | 24 | 2.81372e-14 |
| Polinomial grau 3 (cars) | 30 | 30 | 1.79696e-13 |
| Logarítmico (cars) | 18 | 18 | 4.48805e-15 |
| Michaelis-Menten (Puromycin) | 16 | 16 | 0.000181731 |
| Exponencial (decaimento) | 16 | 16 | 3.16987e-06 |
| Potência | 16 | 16 | 1.60769e-05 |
| Teste t de Welch (sleep) | 3 | 3 | 0.00019834 |
| Wilcoxon (sleep) | 2 | 2 | 2.00177e-16 |
| Teste F de variâncias (sleep) | 2 | 2 | 4.48442e-16 |
| ANOVA (PlantGrowth) | 2 | 2 | 1.09966e-15 |
| Kruskal-Wallis | 2 | 2 | 1.88314e-15 |
| Bartlett | 2 | 2 | 1.23419e-15 |
| Shapiro-Wilk (3 grupos) | 6 | 6 | 4.72224e-15 |
| Tukey HSD (3 pares) | 6 | 6 | 3.36833e-12 |
| Wilcoxon por pares, Holm (3 pares) | 3 | 3 | 1.73412e-15 |
| Correlação de Pearson | 2 | 2 | 1.50461e-14 |
| Correlação de Spearman | 2 | 2 | 5.34817e-16 |

## Dados usados

- `cars` (R): 50 pares velocidade × distância de frenagem — regressões. Valores publicados: distância = −17,5791 + 3,9324·velocidade; R² = 0,6511.
- `Puromycin` (tratado, R; Bates & Watts, 1988): ajuste de Michaelis-Menten; valores publicados Vm ≈ 212,7 e K ≈ 0,06412.
- `sleep` e `PlantGrowth` (R): testes t/Wilcoxon/F e ANOVA/Tukey/Kruskal/Bartlett/Shapiro.
- Exponencial e potência: dados sintéticos com semente fixa (`dados/`).

## Como ler as diferenças que existem entre programas

- **AIC/BIC:** cada programa usa constantes diferentes. Aqui o Python foi ajustado à convenção do R (contar também a variância, k+1), que é a do Cinabro.
- **Wilcoxon / Mann-Whitney:** comparado com a aproximação normal e correção de continuidade (`exact = FALSE` no Cinabro). Programas que usam o teste exato em amostras pequenas dão outro p.
- **Teste t:** o Cinabro usa Welch (padrão do R). Programas que usam Student dão outro p.
- **Tukey:** o sinal da diferença depende da ordem dos grupos; a comparação usa a mesma ordem (grupo seguinte − anterior).
- **Graus de liberdade do teste t:** o Cinabro os mostra com 2 casas (17,78); a tolerância é 1e-3 só para essa grandeza.
- **p dos parâmetros em ajuste não linear:** quando o p é muito pequeno (≈ 1e-5), uma diferença mínima no erro padrão vira diferença relativa maior; a tolerância é 1e-3 só para esses p.
- **p muito pequeno (< 1e-10):** a diferença relativa é ruído numérico e é aceita se os dois forem desse tamanho.

## O que esta validação NÃO cobre

- Programas comerciais (SPSS, GraphPad Prism, Origin, Minitab): não foram executados aqui. Para esses, compare manualmente com os mesmos dados em `dados/` e confira as opções acima.
- Valores certificados do NIST (StRD) para regressão não linear: o servidor do NIST não estava acessível neste ambiente; o caso Puromycin cobre a literatura clássica.
- Ajustes ponderados, loess, correlação de Kendall, testes de Fligner e medidas repetidas.
- Qualquer caso com dados diferentes destes: o resultado vale para estes conjuntos, não é uma prova geral.

## Como repetir

```
Rscript validacao.R
pip install scipy statsmodels pandas
python3 validacao.py
```

Os números linha a linha estão em `comparacao.csv`.
