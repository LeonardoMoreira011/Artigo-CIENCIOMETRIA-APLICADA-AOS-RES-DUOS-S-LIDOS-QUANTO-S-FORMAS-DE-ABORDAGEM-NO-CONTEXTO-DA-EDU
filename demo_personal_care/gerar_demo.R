# =============================================================================
#  Demonstração do Cinabro — ativos de personal care (dados fictícios)
#  Gera: imagens/ (um PNG por gráfico), projetos/ (.cinabro: abre no app com dados e configuração), dashboard (HTML final + editável)
#  Rode a partir desta pasta:  Rscript gerar_demo.R [pt|en|es]
# =============================================================================
suppressPackageStartupMessages(library(shiny)); options(cinabro.sem_log = TRUE, cinabro.sem_sessao = TRUE)
aqui <- normalizePath(if (file.exists("gerar_demo.R")) "." else "demo_personal_care", winslash = "/")
raiz <- normalizePath(file.path(aqui, "..", "graficos_R"), winslash = "/")          # a pasta do Cinabro (a que vai no ZIP)
setwd(raiz); source("01_config.R", encoding = "UTF-8"); suppressMessages(source("02_motor.R", encoding = "UTF-8")); CFG0 <- .completar_cfg(cfg)
assign("raiz", raiz, envir = globalenv()); assign("CFG0", CFG0, envir = globalenv())
setwd("app_shiny"); for (a in c("idiomas.R", "espec.R", "nucleo.R", "ui_blocos.R", "dashboard.R", "servidor.R")) source(file.path("codigo", a), encoding = "UTF-8")
carregar_dicionarios("idiomas")
idm <- { a <- commandArgs(TRUE); if (length(a)) a[1] else "pt" }
op <- utils::modifyList(CFG0$dados, list(relatorio = FALSE))

# a tabela de séries do app (aqui só para ligar a coluna de erro de uma série)
ser <- function(nome, erro = "") data.frame(nome = nome, cor = "", forma = "", tamanho = NA_real_, linha = NA_real_, borda = NA_real_, legenda = nome, erro = erro, stringsAsFactors = FALSE)
TAM <- list(largura_cm = 18, altura_cm = 11)       # mesmo tamanho em todos: o dashboard fica alinhado
# ---- os gráficos: cada um com os campos do app (os mesmos nomes da tela) ---------------------------------------------------------------
G <- list(
  list(id = "01_tendencia", nome = "1. Por que agora?", csv = "01_interesse_busca_ativos.csv",
       v = list(tipo_grafico = "linha", coluna_x = "Data", titulo_grafico = "O mercado já pede bakuchiol e peptídeos",
                x_titulo = "Trimestre", y_titulo = "Interesse de busca (índice 0–100)", y_inicio = 0, y_fim = 100, y_intervalo = 20, linha_espessura_pt = 1.6,
                legenda_posicao = "base", legenda_n_linhas = 2)),
  list(id = "02_eficacia", nome = "2. Quem entrega resultado?", csv = "02_eficacia_clinica_ativos.csv",
       v = list(tipo_grafico = "barras", coluna_x = "Ativo", colunas_y = "Redução de rugas (%)", colunas_erro = "Desvio padrão",
                titulo_grafico = "Retinol lidera; bakuchiol chega perto", legenda_mostrar = "nao", y_titulo = "Redução de rugas em 8 semanas (%)", y_inicio = 0, y_fim = 40, y_intervalo = 10,
                x_rotacao_numeros = 30), s = ser("Redução de rugas (%)", "Desvio padrão")),
  list(id = "03_dose", nome = "3. Quanto basta?", csv = "03_dose_resposta_hidratacao.csv",
       v = list(tipo_grafico = "pontos", titulo_grafico = "Mais não é melhor: a hidratação satura",
                x_titulo = "Concentração do ativo (%)", y_titulo = "Ganho de hidratação (%)", x_inicio = 0, x_fim = 10, x_intervalo = 2, y_inicio = 0, y_fim = 50, y_intervalo = 10,
                aj1_ativo = TRUE, aj1_tipo = "formula", aj1_formula = "a*x/(b+x)", aj1_serie = "todas", aj1_espessura_pt = 1.2, legenda_posicao = "dentro", legenda_canto = "inf_dir")),
  list(id = "04_estabilidade", nome = "4. Aguenta o prazo de validade?", csv = "04_estabilidade_retinol_40C.csv",
       v = list(tipo_grafico = "pontos", titulo_grafico = "Encapsular multiplica a vida útil do retinol",
                x_titulo = "Tempo a 40 °C (semanas)", y_titulo = "Retinol remanescente (%)", x_inicio = 0, x_fim = 12, x_intervalo = 2, y_inicio = 0, y_fim = 100, y_intervalo = 20,
                aj1_ativo = TRUE, aj1_tipo = "exponencial", aj1_serie = "todas", aj1_espessura_pt = 1.2, legenda_posicao = "dentro", legenda_canto = "inf_esq")),
  list(id = "05_janela", nome = "5. Onde está a janela ótima?", csv = "05_janela_otima_ph_concentracao.csv",
       v = list(tipo_grafico = "superficie_3d", titulo_grafico = "", x_titulo = "Concentração do ativo (%)", y_titulo = "pH", tri_z_titulo = "Eficácia (%)",
                tri_azimute = 38, tri_elevacao = 28, tri_suavizar = 4, calor_titulo_barra = "Eficácia (%)")),
  list(id = "06_penetracao", nome = "6. Chega onde precisa?", csv = "06_penetracao_na_pele.csv",
       v = list(tipo_grafico = "linhas_3d", titulo_grafico = "", x_titulo = "Profundidade na pele (µm)", y_titulo = "Tempo (h)", tri_z_titulo = "Ativo (µg/cm²)",
                tri_azimute = 32, tri_elevacao = 22, calor_titulo_barra = "µg/cm²")),
  list(id = "07_prototipos", nome = "7. Qual protótipo vence?", csv = "07_comparacao_prototipos.csv",
       v = list(tipo_grafico = "radar", titulo_grafico = "O protótipo C equilibra tudo", radar_min = 0, radar_max = 10, radar_legenda_posicao = "base", legenda_n_linhas = 2, radar_rotulos_aneis = FALSE)),
  list(id = "08_beneficios", nome = "8. Onde cada ativo brilha", csv = "08_beneficios_por_ativo.csv",
       v = list(tipo_grafico = "mapa_calor", coluna_x = "Ativo", titulo_grafico = "Cada ativo tem a sua vocação", calor_esquema = "cinabro", calor_valores = TRUE, calor_casas = 1,
                calor_titulo_barra = "Nota (0–10)", x_rotacao_numeros = 30, x_titulo = " ", y_titulo = " ")),
  list(id = "09_mercado", nome = "9. Onde lançar primeiro?", csv = "09_potencial_mercado_estados.csv",
       v = list(tipo_grafico = "mapa_brasil", coluna_x = "UF", colunas_y = "Potencial de mercado", titulo_grafico = "Sudeste e Sul abrem o caminho", calor_titulo_barra = "Índice")))

dir.create(file.path(aqui, "imagens"), FALSE); dir.create(file.path(aqui, "projetos"), FALSE)
abas <- list()
for (g in G) {
  arq <- file.path(aqui, "dados", g$csv); g$v <- utils::modifyList(TAM, g$v); d <- ler_csv(arq, op)
  r <- construir_grafico(d, montar_variaveis(g$v, CFG0, g$s), CFG0, preview = FALSE, idioma = idm)
  if (!is.null(r$erro)) { cat("ERRO em", g$id, ":", r$erro, "\n"); next }
  if (length(r$avisos)) cat("  aviso", g$id, ":", substr(paste(r$avisos, collapse = " | "), 1, 160), "\n")
  cf <- r$cfg; cf$exportacao$pasta <- file.path(aqui, "imagens"); cf$exportacao$formatos <- "png"; cf$exportacao$dpi <- 200
  tryCatch(suppressMessages(salvar(r$g, cf, nome = paste0(g$id, "_", idm))), error = function(e) cat("  falha ao salvar", g$id, conditionMessage(e), "\n"))
  pj <- montar_projeto(list(versao = 2, dados = g$csv, valores = g$v, series = g$s, congelados = character(0), salvo_em = format(Sys.time(), "%d/%m/%Y %H:%M"), arquivo_dados = g$csv), arq)
  writeLines(projeto_json(pj), file.path(aqui, "projetos", paste0(g$id, ".cinabro")), useBytes = TRUE)
  abas[[length(abas) + 1]] <- list(nome = g$nome, dados = d, valores = g$v, series = g$s)
  cat("ok", g$id, "\n")
}
# ---- dashboard: todas as abas numa folha ------------------------------------------------------------------------------------------------
tit <- c(pt = "Ativos de personal care: do ativo ao protótipo vencedor", en = "Personal care actives: from active to winning prototype", es = "Activos de cuidado personal: del activo al prototipo ganador")[[idm]]
sub <- c(pt = "Projeto Aurora (dados ilustrativos) · time de Personal Care", en = "Project Aurora (illustrative data) · Personal Care team", es = "Proyecto Aurora (datos ilustrativos) · equipo de Cuidado Personal")[[idm]]
dr <- dash_construir(abas, list(idioma = idm, formato = "a4h", destaques = TRUE, titulo = tit, subtitulo = sub, rodape = "Cinabro"))
# números-chave e frases da história (calculados dos próprios dados): trocam os destaques automáticos, que o editor do dashboard também permite reescrever
if (idm == "pt" && length(dr$graficos) == length(abas)) {
  n1 <- function(x, c = 1) format(round(x, c), nsmall = c, decimal.mark = ",", trim = TRUE)
  D <- lapply(abas, `[[`, "dados"); b <- function(x) paste0("<b>", x, "</b>")
  d1 <- D[[1]]; d2 <- D[[2]]; d3 <- D[[3]]; d4 <- D[[4]]; d5 <- D[[5]]; d7 <- D[[7]]; d9 <- D[[9]]
  bk <- d1$Bakuchiol; pe <- d1$Peptídeos; re <- d1$Retinol
  fim4 <- as.list(d4[nrow(d4), ])
  z5 <- as.matrix(d5[-1]); w <- which(z5 == max(z5), arr.ind = TRUE)
  mm_pct <- function(c, ec50) 100 * c / (ec50 + c)
  H <- list(
    list(kpi = list(valor = paste0(round(tail(bk, 1) / bk[1]), "×"), rotulo = "interesse por bakuchiol em 5 anos"),
         frases = list(paste0(b("Bakuchiol"), " saiu de ", n1(bk[1], 0), " para ", n1(tail(bk, 1), 0), " no índice de busca e já encosta na niacinamida."),
                       paste0(b("Peptídeos"), " também decolaram: de ", n1(pe[1], 0), " para ", n1(tail(pe, 1), 0), "."),
                       paste0(b("Retinol"), " segue estável (~", n1(mean(re), 0), "): é a referência, não a novidade."))),
    list(kpi = list(valor = paste0(n1(d2[[2]][1]), "%"), rotulo = "menos rugas com retinol em 8 semanas"),
         frases = list(paste0(b("Retinol"), " lidera (", n1(d2[[2]][1]), "%), mas o ", b("bakuchiol"), " entrega ", n1(100 * d2[[2]][2] / d2[[2]][1], 0), "% disso."),
                       "Bakuchiol com menos irritação: a alternativa de maior potencial para pele sensível.")),
    list(kpi = list(valor = "≈ 4%", rotulo = "de ativo já dá ~70% do ganho máximo"),
         frases = list(paste0("Com 4% de niacinamida o ganho chega a ", n1(mm_pct(4, 1.8), 0), "% do máximo; dobrar a dose para 8% soma só mais ", n1(mm_pct(8, 1.8) - mm_pct(4, 1.8), 0), " pontos."),
                       "O ácido hialurônico satura mais cedo: cada ativo tem a sua dose econômica.")),
    list(kpi = list(valor = paste0(n1(fim4[["Retinol encapsulado"]], 0), "%"), rotulo = "do retinol encapsulado resiste a 12 semanas"),
         frases = list(paste0("Livre, o retinol cai para ", n1(fim4[["Retinol livre"]], 0), "% em 12 semanas a 40 °C; encapsulado, mantém ", n1(fim4[["Retinol encapsulado"]], 0), "%."),
                       "Com antioxidante já ajuda, mas só a encapsulação garante o prazo de validade.")),
    list(kpi = list(valor = paste0(n1(max(z5), 0), "%"), rotulo = paste0("eficácia máxima (pH ", n1(d5[[1]][w[1, 1]]), "; ", names(d5)[-1][w[1, 2]], "%)")),
         frases = list(paste0("O pico está em ", b(paste0("pH ", n1(d5[[1]][w[1, 1]]))), " e ", b(paste0(names(d5)[-1][w[1, 2]], "% de ativo")), "."), "Fora da janela a eficácia despenca: o pH é tão importante quanto a dose.")),
    list(kpi = list(valor = "24 h", rotulo = "para o ativo chegar à derme"),
         frases = list("A concentração cai rápido com a profundidade, mas o ativo continua chegando por horas.", "A encapsulação prolonga a liberação: menos picos, menos irritação.")),
    list(kpi = list(valor = "C", rotulo = "protótipo mais equilibrado"),
         frases = list("A fórmula C lidera em eficácia, toque e hidratação.", "A B ganha em estabilidade; a A, em custo-benefício.")),
    list(kpi = list(valor = "Retinol", rotulo = "mais forte em antirrugas"),
         frases = list("O mapa de calor mostra a vocação de cada ativo: ninguém é bom em tudo.", "Combinar ativos complementares cobre mais benefícios.")),
    list(kpi = list(valor = "SP", rotulo = "maior potencial de mercado"),
         frases = list(paste0("São Paulo concentra o maior índice (", n1(max(d9[[2]]), 0), "); Sudeste e Sul formam a primeira onda de lançamento."))))
  for (i in seq_along(H)) { dr$graficos[[i]]$kpi <- H[[i]]$kpi; dr$graficos[[i]]$frases <- H[[i]]$frases }
}
cat(length(dr$graficos), "gráficos no dashboard; avisos:", dr$avisos, "\n")
writeLines(dash_html(dr$estado, .dash_json(dr$graficos), "ver"), file.path(aqui, paste0("dashboard_", idm, ".html")), useBytes = TRUE)
writeLines(dash_html(dr$estado, .dash_json(dr$graficos), "editar"), file.path(aqui, paste0("dashboard_", idm, "_editavel.html")), useBytes = TRUE)
# versão para imprimir (o app faz o PDF pelo botão "Baixar PDF"; aqui sai a página de impressão para quem quiser o PDF por fora: node dashboard_para_pdf.js)
writeLines(dash_html(dr$estado, .dash_json(dr$graficos), "pdf"), file.path(aqui, paste0("dashboard_", idm, "_impressao.html")), useBytes = TRUE)
cat("pronto\n")
