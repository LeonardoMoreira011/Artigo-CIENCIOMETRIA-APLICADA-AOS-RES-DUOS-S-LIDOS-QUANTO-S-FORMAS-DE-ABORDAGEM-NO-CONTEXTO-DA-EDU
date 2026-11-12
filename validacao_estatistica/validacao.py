# -*- coding: utf-8 -*-
"""Validação estatística do Cinabro — parte Python (scipy/statsmodels: implementação independente do R).
Compara três fontes para cada caso: Cinabro, R puro (stats) e Python. Escreve relatorio.md e comparacao.csv.
Uso (depois de Rscript validacao.R):   pip install scipy statsmodels pandas   &&   python3 validacao.py
"""
import json, os, sys, csv, itertools
sys.path.insert(0, os.environ.get('PYLIB', '/tmp/claude-0/pylib'))
import numpy as np, pandas as pd
from scipy import stats, optimize
import statsmodels.api as sm
from statsmodels.stats.multitest import multipletests
import scipy, statsmodels

AQUI = os.path.dirname(os.path.abspath(__file__))
R = json.load(open(os.path.join(AQUI, 'resultados_r.json'), encoding='utf-8'))
D = lambda n: pd.read_csv(os.path.join(AQUI, 'dados', n))
TOL_DET, TOL_NLS = 1e-6, 1e-4          # tolerância relativa: cálculos diretos / ajustes não lineares (algoritmos iterativos)

# ---------- referências em Python ----------
def py_ols(X, y, nome_param):
    m = sm.OLS(y, X).fit(); n = len(y); k = X.shape[1]; ci = m.conf_int(0.05)
    rss = float(np.sum(m.resid ** 2)); llf = m.llf
    return {'ajustes': {'r2': m.rsquared, 'r2_aj': m.rsquared_adj, 'rmse': float(np.sqrt(np.mean(m.resid ** 2))),
                        'aic': -2 * llf + 2 * (k + 1), 'bic': -2 * llf + np.log(n) * (k + 1), 'p': float(m.f_pvalue)},   # AIC/BIC como no R: contam também a variância (k + 1)
            'parametros': [{'termo': nome_param[i], 'estimativa': m.params[i], 'ep': m.bse[i], 't': m.tvalues[i], 'p': m.pvalues[i], 'ic_inf': ci[i][0], 'ic_sup': ci[i][1]} for i in range(k)]}
def py_nls(f, x, y, p0, nomes):
    p, cov = optimize.curve_fit(f, x, y, p0=p0, maxfev=20000); n = len(y); k = len(p); se = np.sqrt(np.diag(cov)); res = y - f(x, *p); rss = float(np.sum(res ** 2)); tss = float(np.sum((y - y.mean()) ** 2))
    tq = stats.t.ppf(0.975, n - k); ll = -n / 2 * (np.log(2 * np.pi) + 1 - np.log(n) + np.log(rss))
    return {'ajustes': {'r2': 1 - rss / tss, 'rmse': float(np.sqrt(rss / n)), 'aic': -2 * ll + 2 * (k + 1), 'bic': -2 * ll + np.log(n) * (k + 1)},
            'parametros': [{'termo': nomes[i], 'estimativa': p[i], 'ep': se[i], 't': p[i] / se[i], 'p': 2 * stats.t.sf(abs(p[i] / se[i]), n - k), 'ic_inf': p[i] - tq * se[i], 'ic_sup': p[i] + tq * se[i]} for i in range(k)]}
P = {}
c = D('cars.csv'); x, y = c.x.values.astype(float), c.y.values.astype(float)
P['linear'] = py_ols(sm.add_constant(x), y, ['a', 'b'])
P['poly2'] = py_ols(np.vander(x, 3, increasing=True), y, ['a0', 'a1', 'a2'])
P['poly3'] = py_ols(np.vander(x, 4, increasing=True), y, ['a0', 'a1', 'a2', 'a3'])
P['log'] = py_ols(sm.add_constant(np.log(x)), y, ['a', 'b'])
pu = D('puromycin_tratado.csv'); P['michaelis'] = py_nls(lambda x, a, b: a * x / (b + x), pu.x.values, pu.y.values, [200, 0.1], ['a', 'b'])
ex = D('decaimento_exponencial.csv'); P['exponencial'] = py_nls(lambda x, a, b: a * np.exp(b * x), ex.x.values, ex.y.values, [90, -0.1], ['a', 'b'])
po = D('lei_de_potencia.csv'); P['potencia'] = py_nls(lambda x, a, b: a * x ** b, po.x.values, po.y.values, [1, 1], ['a', 'b'])
sl = D('sleep.csv'); a1, a2 = sl.y[sl.grupo == 1].values, sl.y[sl.grupo == 2].values
t = stats.ttest_ind(a1, a2, equal_var=False); P['ttest'] = [{'estatistica': t.statistic, 'p': t.pvalue, 'gl': t.df}]
mw = stats.mannwhitneyu(a1, a2, method='asymptotic', use_continuity=True); P['wilcoxon'] = [{'estatistica': mw.statistic, 'p': mw.pvalue}]
F = np.var(a1, ddof=1) / np.var(a2, ddof=1); pF = 2 * min(stats.f.cdf(F, len(a1) - 1, len(a2) - 1), stats.f.sf(F, len(a1) - 1, len(a2) - 1)); P['var_test'] = [{'estatistica': F, 'p': pF}]
pg = D('plantgrowth.csv'); ordem = ['ctrl', 'trt1', 'trt2']; G = [pg.y[pg.grupo == g].values for g in ordem]
fo = stats.f_oneway(*G); P['anova'] = [{'estatistica': fo.statistic, 'p': fo.pvalue}]
kr = stats.kruskal(*G); P['kruskal'] = [{'estatistica': kr.statistic, 'p': kr.pvalue}]
ba = stats.bartlett(*G); P['bartlett'] = [{'estatistica': ba.statistic, 'p': ba.pvalue}]
P['shapiro'] = [{'estatistica': stats.shapiro(g).statistic, 'p': stats.shapiro(g).pvalue} for g in G]
tk = stats.tukey_hsd(*G); pares = [(0, 1), (0, 2), (1, 2)]
P['tukey'] = [{'estatistica': np.mean(G[j]) - np.mean(G[i]), 'p': tk.pvalue[i, j]} for i, j in pares]
raw = [stats.mannwhitneyu(G[i], G[j], method='asymptotic', use_continuity=True).pvalue for i, j in pares]; hol = multipletests(raw, method='holm')[1]
P['pares_wilcoxon'] = [{'p': hol[k]} for k in range(3)]
pr = stats.pearsonr(c.x, c.y); P['pearson'] = [{'estatistica': pr.statistic, 'p': pr.pvalue}]
sp = stats.spearmanr(c.x, c.y); P['spearman'] = [{'estatistica': sp.statistic, 'p': sp.pvalue}]

# ---------- comparação ----------
NOMES = {'linear': 'Regressão linear (cars)', 'poly2': 'Polinomial grau 2 (cars)', 'poly3': 'Polinomial grau 3 (cars)', 'log': 'Logarítmico (cars)',
         'michaelis': 'Michaelis-Menten (Puromycin)', 'exponencial': 'Exponencial (decaimento)', 'potencia': 'Potência', 'ttest': 'Teste t de Welch (sleep)',
         'wilcoxon': 'Wilcoxon (sleep)', 'var_test': 'Teste F de variâncias (sleep)', 'anova': 'ANOVA (PlantGrowth)', 'kruskal': 'Kruskal-Wallis', 'bartlett': 'Bartlett',
         'shapiro': 'Shapiro-Wilk (3 grupos)', 'tukey': 'Tukey HSD (3 pares)', 'pares_wilcoxon': 'Wilcoxon por pares, Holm (3 pares)', 'pearson': 'Correlação de Pearson', 'spearman': 'Correlação de Spearman'}
def achata(caso, bloco):
    """devolve {rótulo: valor} de um bloco (Cinabro, R ou Python) de um caso"""
    out = {}
    if isinstance(bloco, dict) and 'ajustes' in bloco:
        for k, v in bloco['ajustes'].items(): out['ajuste.' + k] = v
        for q in bloco['parametros']:
            for k in ('estimativa', 'ep', 't', 'p', 'ic_inf', 'ic_sup'): out['%s.%s' % (q['termo'], k)] = q[k]
    else:
        lst = bloco if isinstance(bloco, list) else [bloco]
        for i, q in enumerate(lst):
            for k, v in q.items():
                if k in ('estatistica', 'p', 'gl') and v is not None and not isinstance(v, str): out['%d.%s' % (i + 1, k)] = v
                elif k == 'gl' and isinstance(v, str):
                    try: out['%d.gl' % (i + 1)] = float(v)
                    except Exception: pass
    return out
def rel(a, b):
    if a is None or b is None or (isinstance(a, float) and np.isnan(a)) or (isinstance(b, float) and np.isnan(b)): return None
    return abs(a - b) / max(abs(a), abs(b), 1e-300) if max(abs(a), abs(b)) > 1e-12 else abs(a - b)
linhas = []; resumo = []
for caso in NOMES:
    cin, rr, py = achata(caso, R[caso]['cinabro']), achata(caso, R[caso]['r']), achata(caso, P[caso])
    tol = TOL_NLS if caso in ('michaelis', 'exponencial', 'potencia') else TOL_DET
    # Tukey: o sinal e a ordem dos pares podem variar entre programas; compara só o que existe nas três fontes
    chaves = [k for k in py if k in cin]; nok = 0; nlin = 0; maxd = 0.0
    for k in chaves:
        tol_k = tol
        if k.endswith('.gl'): tol_k = 1e-3                                     # o Cinabro mostra os graus de liberdade com 2 casas (17,78), não é erro de cálculo
        elif caso in ('michaelis', 'exponencial', 'potencia') and k.endswith('.p'): tol_k = 1e-3   # o p de um parâmetro amplifica diferenças mínimas do erro padrão (p ~ 1e-5)
        d_cr, d_cp = rel(cin[k], rr.get(k)), rel(cin[k], py[k])
        ok = (d_cr is None or d_cr <= tol_k) and (d_cp is None or d_cp <= tol_k) and (d_cp is not None)
        # p muito pequeno (< 1e-10): a diferença relativa é ruído numérico; basta concordar na ordem de grandeza
        if not ok and d_cp is not None and cin[k] is not None and abs(cin[k]) < 1e-10 and abs(py[k]) < 1e-10: ok = True
        nlin += 1; nok += ok; maxd = max(maxd, d_cp or 0)
        linhas.append({'caso': NOMES[caso], 'quantidade': k, 'cinabro': cin[k], 'r_puro': rr.get(k), 'python': py[k], 'dif_rel_cinabro_python': d_cp, 'dif_rel_cinabro_r': d_cr, 'tolerancia': tol_k, 'ok': 'sim' if ok else 'NÃO'})
    resumo.append((NOMES[caso], nlin, nok, maxd, tol))
with open(os.path.join(AQUI, 'comparacao.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, fieldnames=list(linhas[0].keys())); w.writeheader(); w.writerows(linhas)
tot, totok = sum(r[1] for r in resumo), sum(r[2] for r in resumo)
def fmt(v): return '—' if v is None else ('%.6g' % v)
md = ['# Validação estatística do Cinabro', '',
      'Compara, para os mesmos dados, **três fontes**: o **Cinabro**, o **R puro** (funções `stats`, sem o Cinabro) e o **Python** (scipy %s e statsmodels %s — implementações independentes do R).' % (scipy.__version__, statsmodels.__version__), '',
      '**Resultado: %d de %d grandezas concordam dentro da tolerância** (%d casos).' % (totok, tot, len(resumo)), '',
      'Tolerância: diferença relativa ≤ 1e-6 nos cálculos diretos (regressões por mínimos quadrados e testes) e ≤ 1e-4 nos ajustes não lineares (métodos iterativos, que param em critérios diferentes).', '',
      '## Resumo por caso', '', '| Caso | Grandezas comparadas | Concordam | Maior diferença relativa (Cinabro × Python) |', '|---|---|---|---|']
for n, nl, nk, mx, tol in resumo: md.append('| %s | %d | %d | %s |' % (n, nl, nk, fmt(mx)))
md += ['', '## Dados usados', '',
       '- `cars` (R): 50 pares velocidade × distância de frenagem — regressões. Valores publicados: distância = −17,5791 + 3,9324·velocidade; R² = 0,6511.',
       '- `Puromycin` (tratado, R; Bates & Watts, 1988): ajuste de Michaelis-Menten; valores publicados Vm ≈ 212,7 e K ≈ 0,06412.',
       '- `sleep` e `PlantGrowth` (R): testes t/Wilcoxon/F e ANOVA/Tukey/Kruskal/Bartlett/Shapiro.',
       '- Exponencial e potência: dados sintéticos com semente fixa (`dados/`).', '',
       '## Como ler as diferenças que existem entre programas', '',
       '- **AIC/BIC:** cada programa usa constantes diferentes. Aqui o Python foi ajustado à convenção do R (contar também a variância, k+1), que é a do Cinabro.',
       '- **Wilcoxon / Mann-Whitney:** comparado com a aproximação normal e correção de continuidade (`exact = FALSE` no Cinabro). Programas que usam o teste exato em amostras pequenas dão outro p.',
       '- **Teste t:** o Cinabro usa Welch (padrão do R). Programas que usam Student dão outro p.',
       '- **Tukey:** o sinal da diferença depende da ordem dos grupos; a comparação usa a mesma ordem (grupo seguinte − anterior).',
       '- **Graus de liberdade do teste t:** o Cinabro os mostra com 2 casas (17,78); a tolerância é 1e-3 só para essa grandeza.',
       '- **p dos parâmetros em ajuste não linear:** quando o p é muito pequeno (≈ 1e-5), uma diferença mínima no erro padrão vira diferença relativa maior; a tolerância é 1e-3 só para esses p.',
       '- **p muito pequeno (< 1e-10):** a diferença relativa é ruído numérico e é aceita se os dois forem desse tamanho.', '',
       '## O que esta validação NÃO cobre', '',
       '- Programas comerciais (SPSS, GraphPad Prism, Origin, Minitab): não foram executados aqui. Para esses, compare manualmente com os mesmos dados em `dados/` e confira as opções acima.',
       '- Valores certificados do NIST (StRD) para regressão não linear: o servidor do NIST não estava acessível neste ambiente; o caso Puromycin cobre a literatura clássica.',
       '- Ajustes ponderados, loess, correlação de Kendall, testes de Fligner e medidas repetidas.',
       '- Qualquer caso com dados diferentes destes: o resultado vale para estes conjuntos, não é uma prova geral.', '',
       '## Como repetir', '', '```', 'Rscript validacao.R', 'pip install scipy statsmodels pandas', 'python3 validacao.py', '```', '',
       'Os números linha a linha estão em `comparacao.csv`.']
open(os.path.join(AQUI, 'relatorio.md'), 'w', encoding='utf-8').write('\n'.join(md) + '\n')
print('%d de %d grandezas concordam; casos com divergência:' % (totok, tot))
for r in linhas:
    if r['ok'] != 'sim': print('  ', r['caso'], r['quantidade'], r['cinabro'], r['r_puro'], r['python'], r['dif_rel_cinabro_python'])
