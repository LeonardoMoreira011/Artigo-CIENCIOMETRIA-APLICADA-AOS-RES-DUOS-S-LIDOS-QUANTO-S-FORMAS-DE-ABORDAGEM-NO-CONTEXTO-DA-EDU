# =============================================================================
#  Dados FICTÍCIOS para a demonstração do Cinabro — tema: ativos de personal care
#  Tudo aqui é inventado (gerado por fórmulas, com semente fixa): serve só para mostrar a ferramenta.
#  Rode:  Rscript dados_ficticios.R   (grava os CSV na pasta dados/, no formato brasileiro: ; e vírgula decimal)
# =============================================================================
set.seed(2025)
aqui <- if (file.exists("dados_ficticios.R")) "." else "demo_personal_care"
dir.create(file.path(aqui, "dados"), showWarnings = FALSE)
grava <- function(df, nome) {
  df[] <- lapply(df, function(v) if (is.numeric(v)) v else as.character(v))
  write.table(df, file.path(aqui, "dados", nome), sep = ";", dec = ",", row.names = FALSE, quote = FALSE, fileEncoding = "UTF-8")
}
r2 <- function(x, n = 1) round(x, n)

# 1) Interesse de busca por ativo (índice 0-100), por trimestre — "por que agora?"
tri <- seq(as.Date("2021-01-01"), by = "3 months", length.out = 20); k <- seq_along(tri)
rui <- function(n, s = 2.2) rnorm(n, 0, s)
d1 <- data.frame(Data = format(tri, "%d/%m/%Y"),
  Niacinamida = r2(pmin(100, 38 + 42 * plogis((k - 6) / 2) + rui(20))),
  `Ácido hialurônico` = r2(52 + 4 * sin(k / 3) + rui(20, 1.6)),
  Retinol = r2(62 + 3 * sin(k / 2.5) + rui(20, 1.8)),
  Bakuchiol = r2(pmax(2, 4 + 84 * plogis((k - 13) / 2.6) + rui(20))),
  Peptídeos = r2(pmax(2, 14 + 58 * plogis((k - 11) / 3.2) + rui(20))), check.names = FALSE)
grava(d1, "01_interesse_busca_ativos.csv")

# 2) Eficácia clínica: redução de rugas (%) após 8 semanas, média e desvio (n = 30 voluntárias por ativo)
d2 <- data.frame(Ativo = c("Retinol", "Bakuchiol", "Vitamina C", "Niacinamida", "Peptídeo de cobre", "Ác. hialurônico", "Ceramidas", "Pantenol"),
                 `Redução de rugas (%)` = c(31.2, 26.4, 23.8, 21.9, 18.3, 14.1, 11.6, 8.2),
                 `Desvio padrão` = c(3.9, 3.1, 3.4, 2.6, 2.9, 2.2, 1.9, 1.5), check.names = FALSE)
grava(d2, "02_eficacia_clinica_ativos.csv")

# 3) Dose-resposta: ganho de hidratação (%) por concentração do ativo — saturação (platô)
conc <- c(0, 0.5, 1, 2, 3, 4, 5, 6, 8, 10)
mm <- function(emax, ec50, x) emax * x / (ec50 + x)
d3 <- data.frame(`Concentração (%)` = conc,
  Niacinamida = r2(mm(38, 1.8, conc) + rnorm(10, 0, 0.9)),
  Pantenol = r2(mm(31, 3.2, conc) + rnorm(10, 0, 0.9)),
  `Ác. hialurônico` = r2(mm(46, 0.9, conc) + rnorm(10, 0, 0.9)), check.names = FALSE)
d3[1, -1] <- 0
grava(d3, "03_dose_resposta_hidratacao.csv")

# 4) Estabilidade acelerada (40 °C): teor remanescente de retinol (%) — livre x encapsulado x com antioxidante
sem <- c(0, 1, 2, 4, 6, 8, 10, 12)
d4 <- data.frame(`Tempo (semanas)` = sem,
  `Retinol livre` = r2(100 * exp(-0.125 * sem) + rnorm(8, 0, 1.1)),
  `Retinol + antioxidante` = r2(100 * exp(-0.052 * sem) + rnorm(8, 0, 1.0)),
  `Retinol encapsulado` = r2(100 * exp(-0.019 * sem) + rnorm(8, 0, 0.8)), check.names = FALSE)
d4[1, -1] <- 100
grava(d4, "04_estabilidade_retinol_40C.csv")

# 5) Janela ótima da formulação: eficácia (%) em função do pH (linhas) e da concentração do ativo (colunas)
ph <- seq(4, 7, by = 0.5); cc <- seq(0.5, 6, by = 0.5)
ef <- outer(ph, cc, function(p, c) 8 + 78 * exp(-((p - 5.5) / 0.85)^2 - ((c - 3.5) / 1.7)^2) - 24 * plogis((c - 5) / 0.35) * plogis((4.9 - p) / 0.25))
ef[] <- r2(pmax(2, ef + matrix(rnorm(length(ef), 0, 0.5), nrow(ef))))
d5 <- data.frame(pH = ph, ef, check.names = FALSE); names(d5)[-1] <- format(cc, decimal.mark = ",", trim = TRUE)
grava(d5, "05_janela_otima_ph_concentracao.csv")

# 6) Penetração na pele: concentração do ativo (µg/cm²) por profundidade (µm), em vários tempos (cada coluna = um tempo, em horas)
z <- seq(0, 200, by = 10); tt <- c(1, 2, 4, 8, 12, 24)
pen <- sapply(tt, function(t) 62 * (1 - exp(-t / 5)) * exp(-z / (14 + 11 * sqrt(t))) + 0.4)
pen <- r2(pen + matrix(rnorm(length(pen), 0, 0.25), nrow(pen)), 2); pen[pen < 0] <- 0
d6 <- data.frame(`Profundidade (µm)` = z, pen, check.names = FALSE); names(d6)[-1] <- as.character(tt)
grava(d6, "06_penetracao_na_pele.csv")

# 7) Comparação dos protótipos (notas 0-10 de painel sensorial, instrumental e clínico)
d7 <- data.frame(Formulação = c("A · Clássica", "B · Encapsulada", "C · Bakuchiol + peptídeos"),
  Hidratação = c(7.2, 8.1, 8.6), Absorção = c(6.5, 8.4, 8.0), Toque = c(6.8, 8.0, 8.9), Estabilidade = c(5.2, 9.1, 8.3),
  `Eficácia clínica` = c(7.6, 8.5, 9.2), `Custo-benefício` = c(8.8, 6.1, 7.4), check.names = FALSE)
grava(d7, "07_comparacao_prototipos.csv")

# 8) Benefícios por ativo (nota 0-10 da literatura interna): onde cada ativo brilha
ben <- c("Hidratação", "Antirrugas", "Uniformização do tom", "Controle de oleosidade", "Barreira cutânea", "Efeito calmante")
at <- c("Retinol", "Bakuchiol", "Vitamina C", "Niacinamida", "Peptídeo de cobre", "Ác. hialurônico", "Ceramidas", "Pantenol")
M <- rbind(c(3, 9.5, 7, 4, 2, 1), c(4, 8.5, 6.5, 6, 5, 7.5), c(3, 7.5, 9.5, 3, 3, 2), c(6, 6.5, 8, 9, 7.5, 6),
           c(5, 7, 5, 2, 4, 5.5), c(9.5, 4.5, 2, 1, 6, 4), c(8, 3.5, 2, 2, 9.5, 5.5), c(8.5, 2.5, 1, 2, 7, 8.5))
d8 <- data.frame(Ativo = at, M, check.names = FALSE); names(d8)[-1] <- ben
grava(d8, "08_beneficios_por_ativo.csv")

# 9) Potencial de mercado por estado (índice 0-100): onde lançar primeiro
uf <- c("SP", "RJ", "MG", "RS", "PR", "SC", "BA", "PE", "CE", "GO", "DF", "ES", "PA", "AM", "MT", "MS", "RN", "PB", "AL", "SE", "PI", "MA", "TO", "RO", "AC", "AP", "RR")
base <- c(100, 78, 70, 58, 62, 55, 46, 40, 36, 44, 52, 38, 26, 22, 30, 28, 24, 21, 18, 17, 15, 17, 14, 13, 8, 7, 6)
d9 <- data.frame(UF = uf, `Potencial de mercado` = r2(pmin(100, base * runif(27, 0.97, 1.03))), check.names = FALSE)
grava(d9, "09_potencial_mercado_estados.csv")
cat("CSV gravados em", file.path(aqui, "dados"), "\n")
