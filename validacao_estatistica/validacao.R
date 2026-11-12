# =============================================================================
#  Validação estatística do Cinabro — parte R
#  Roda os mesmos casos no Cinabro e no R "puro" (stats) e grava dados/ e resultados_r.json.
#  Depois rode:  python3 validacao.py   (compara com scipy/statsmodels e escreve relatorio.md)
#  Uso (a partir desta pasta):  Rscript validacao.R
# =============================================================================
suppressPackageStartupMessages(library(jsonlite))
aqui <- normalizePath(if (file.exists("validacao.R")) "." else "validacao_estatistica", winslash = "/")
raiz <- normalizePath(file.path(aqui, "..", "graficos_R"), winslash = "/")
old <- setwd(raiz); source("01_config.R", encoding = "UTF-8"); suppressMessages(source("02_motor.R", encoding = "UTF-8")); setwd(old)
c0 <- .completar_cfg(cfg); dir.create(file.path(aqui, "dados"), FALSE)
grava <- function(df, nome) utils::write.csv(df, file.path(aqui, "dados", nome), row.names = FALSE, fileEncoding = "UTF-8")
R <- list()
cinabro_ajuste <- function(d, aj, ...) {
  cc <- c0; cc$grafico$tipo <- "pontos"; cc$grafico$coluna_x <- "x"; cc$grafico$colunas_y <- "y"; cc$series <- list(); cc$ajustes <- list(c(list(serie = "y"), aj, list(...)))
  suppressMessages(suppressWarnings(estatisticas(d, cc)))
}
sai_ajuste <- function(r) list(ajustes = as.list(r$ajustes[1, c("r2", "r2_aj", "rmse", "aic", "bic", "p")]), parametros = lapply(seq_len(nrow(r$parametros)), function(i) as.list(r$parametros[i, c("termo", "estimativa", "ep", "t", "p", "ic_inf", "ic_sup")])))
nativo_lm <- function(m) { s <- summary(m); ci <- confint(m)
  list(ajustes = list(r2 = s$r.squared, r2_aj = s$adj.r.squared, rmse = sqrt(mean(residuals(m)^2)), aic = AIC(m), bic = BIC(m), p = pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE)),
       parametros = lapply(seq_len(nrow(s$coefficients)), function(i) list(termo = rownames(s$coefficients)[i], estimativa = s$coefficients[i, 1], ep = s$coefficients[i, 2], t = s$coefficients[i, 3], p = s$coefficients[i, 4], ic_inf = ci[i, 1], ic_sup = ci[i, 2]))) }
nativo_nls <- function(m, y) { s <- summary(m); ci <- stats::qt(0.975, df.residual(m)); res <- residuals(m); rss <- sum(res^2); tss <- sum((y - mean(y))^2)
  list(ajustes = list(r2 = 1 - rss / tss, rmse = sqrt(mean(res^2)), aic = AIC(m), bic = BIC(m)),
       parametros = lapply(seq_len(nrow(s$coefficients)), function(i) list(termo = rownames(s$coefficients)[i], estimativa = s$coefficients[i, 1], ep = s$coefficients[i, 2], t = s$coefficients[i, 3], p = s$coefficients[i, 4],
                                                                          ic_inf = s$coefficients[i, 1] - ci * s$coefficients[i, 2], ic_sup = s$coefficients[i, 1] + ci * s$coefficients[i, 2]))) }

# ---- A) regressão linear e polinomial: cars (distância de frenagem × velocidade) ---------------------------------------------------------
cars2 <- data.frame(x = cars$speed, y = cars$dist); grava(cars2, "cars.csv")
R$linear <- list(cinabro = sai_ajuste(cinabro_ajuste(cars2, list(tipo = "linear"))), r = nativo_lm(lm(y ~ x, cars2)))
R$poly2 <- list(cinabro = sai_ajuste(cinabro_ajuste(cars2, list(tipo = "polinomial", grau = 2))), r = nativo_lm(lm(y ~ poly(x, 2, raw = TRUE), cars2)))
R$poly3 <- list(cinabro = sai_ajuste(cinabro_ajuste(cars2, list(tipo = "polinomial", grau = 3))), r = nativo_lm(lm(y ~ poly(x, 3, raw = TRUE), cars2)))
R$log <- list(cinabro = sai_ajuste(cinabro_ajuste(cars2, list(tipo = "logaritmico"))), r = nativo_lm(lm(y ~ log(x), cars2)))

# ---- B) ajustes não lineares ---------------------------------------------------------------------------------------------------------------
pur <- subset(Puromycin, state == "treated"); pur2 <- data.frame(x = pur$conc, y = pur$rate); grava(pur2, "puromycin_tratado.csv")     # Bates & Watts (1988): Vm = 212,7; K = 0,06412
R$michaelis <- list(cinabro = sai_ajuste(cinabro_ajuste(pur2, list(tipo = "formula", formula = "a*x/(b+x)"))), r = nativo_nls(nls(y ~ a * x / (b + x), pur2, start = list(a = 200, b = 0.1)), pur2$y))
set.seed(11); xe <- c(0, 1, 2, 4, 6, 8, 10, 12); ye <- 100 * exp(-0.12 * xe) + rnorm(8, 0, 1.2); ex <- data.frame(x = xe, y = ye); grava(ex, "decaimento_exponencial.csv")
R$exponencial <- list(cinabro = sai_ajuste(cinabro_ajuste(ex, list(tipo = "exponencial"))), r = nativo_nls(nls(y ~ a * exp(b * x), ex, start = list(a = 90, b = -0.1)), ex$y))
set.seed(12); xp <- seq(1, 50, length.out = 30); yp <- 2 * xp^0.8 + rnorm(30, 0, 1); po <- data.frame(x = xp, y = yp); grava(po, "lei_de_potencia.csv")
R$potencia <- list(cinabro = sai_ajuste(cinabro_ajuste(po, list(tipo = "potencia"))), r = nativo_nls(nls(y ~ a * x^b, po, start = list(a = 1, b = 1)), po$y))

# ---- C) testes de hipótese ----------------------------------------------------------------------------------------------------------------------
sl <- sleep; grava(data.frame(grupo = sl$group, y = sl$extra), "sleep.csv"); g2 <- list(g1 = sl$extra[sl$group == 1], g2 = sl$extra[sl$group == 2])
pg <- PlantGrowth; grava(data.frame(grupo = as.character(pg$group), y = pg$weight), "plantgrowth.csv"); g3 <- split(pg$weight, pg$group)
linhas <- function(df) lapply(seq_len(nrow(df)), function(i) list(grupos = df$grupos[i], estatistica = df$estatistica[i], p = df$p[i], gl = df$gl[i]))
tc <- function(id, g, ...) linhas(.rodar_teste(id, g, ...))
R$ttest <- list(cinabro = tc("ttest", g2), r = { t <- t.test(g2[[1]], g2[[2]]); list(list(estatistica = unname(t$statistic), p = t$p.value, gl = unname(t$parameter))) })
R$wilcoxon <- list(cinabro = tc("wilcoxon", g2), r = { w <- suppressWarnings(wilcox.test(g2[[1]], g2[[2]], exact = FALSE)); list(list(estatistica = unname(w$statistic), p = w$p.value)) })
R$var_test <- list(cinabro = tc("var_test", g2), r = { v <- var.test(g2[[1]], g2[[2]]); list(list(estatistica = unname(v$statistic), p = v$p.value)) })
dd <- data.frame(y = pg$weight, grupo = pg$group)
R$anova <- list(cinabro = tc("anova", g3), r = { a <- summary(aov(y ~ grupo, dd))[[1]]; list(list(estatistica = a[1, "F value"], p = a[1, "Pr(>F)"])) })
R$kruskal <- list(cinabro = tc("kruskal", g3), r = { k <- kruskal.test(y ~ grupo, dd); list(list(estatistica = unname(k$statistic), p = k$p.value)) })
R$bartlett <- list(cinabro = tc("bartlett", g3), r = { b <- bartlett.test(y ~ grupo, dd); list(list(estatistica = unname(b$statistic), p = b$p.value)) })
R$shapiro <- list(cinabro = tc("shapiro", g3), r = lapply(g3, function(v) { s <- shapiro.test(v); list(estatistica = unname(s$statistic), p = s$p.value) }))
R$tukey <- list(cinabro = tc("tukey", g3), r = { tk <- TukeyHSD(aov(y ~ grupo, dd))$grupo; lapply(seq_len(nrow(tk)), function(i) list(grupos = rownames(tk)[i], estatistica = tk[i, "diff"], p = tk[i, "p adj"])) })
R$pares_wilcoxon <- list(cinabro = tc("pares_wilcoxon", g3), r = { pw <- pairwise.wilcox.test(dd$y, dd$grupo, p.adjust.method = "holm", exact = FALSE)$p.value; ij <- which(!is.na(pw), arr.ind = TRUE)
  lapply(seq_len(nrow(ij)), function(m) list(grupos = paste(colnames(pw)[ij[m, 2]], rownames(pw)[ij[m, 1]], sep = " × "), p = pw[ij[m, 1], ij[m, 2]])) })
gx <- list(y = cars$speed); gy <- list(y = cars$dist)
R$pearson <- list(cinabro = tc("pearson", gy, x = gx), r = { ct <- cor.test(cars$speed, cars$dist); list(list(estatistica = unname(ct$estimate), p = ct$p.value)) })
R$spearman <- list(cinabro = tc("spearman", gy, x = gx), r = { ct <- suppressWarnings(cor.test(cars$speed, cars$dist, method = "spearman", exact = FALSE)); list(list(estatistica = unname(ct$estimate), p = ct$p.value)) })
writeLines(toJSON(R, auto_unbox = TRUE, digits = NA, na = "null"), file.path(aqui, "resultados_r.json")); cat("resultados_r.json gravado:", length(R), "casos\n")
