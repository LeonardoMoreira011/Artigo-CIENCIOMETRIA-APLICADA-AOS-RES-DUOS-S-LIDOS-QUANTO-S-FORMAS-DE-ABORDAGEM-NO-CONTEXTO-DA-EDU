# =============================================================================
#  diagnostico_cinabro.R — MEDE o Cinabro neste computador (não altera nada)
# =============================================================================
#  Como usar:
#   1) Rode a partir da pasta  graficos_R  (a que tem o 01_config.R e a pasta app_shiny); este arquivo está em ferramentas/.
#   2) Abra-o no RStudio (ou no R) e rode tudo: RStudio = Ctrl+Shift+S.
#      No R comum:  setwd("C:/Cinabro/graficos_R");  source("ferramentas/diagnostico_cinabro.R", encoding = "UTF-8")
#   3) Espere uns 2 a 4 minutos. Ao final ele grava  diagnostico_cinabro_resultado.txt  na mesma pasta:
#      mande esse arquivo (é só texto, sem dados seus).
#  O que ele faz: lê a versão do Windows/R/pacotes, conta os campos da tela, mede o tempo de montar o gráfico
#  em alguns cenários e confere se a memória e a pasta temporária crescem a cada uso. Só lê e mede.
# =============================================================================
saida <- "diagnostico_cinabro_resultado.txt"
t_ini <- Sys.time()
if (!file.exists("01_config.R") || !dir.exists("app_shiny")) stop("Rode a partir da pasta graficos_R (a que tem 01_config.R e app_shiny).")
sink(saida, split = TRUE)
res <- tryCatch({
secao <- function(t) cat("\n==== ", t, " ====\n", sep = "")
tenta <- function(nome, expr) tryCatch(expr, error = function(e) { cat("  [erro em ", nome, "] ", conditionMessage(e), "\n", sep = ""); NULL })
mem_proc <- function() {                       # memória do processo R, em MB (NA se não souber)
  tenta("memoria", {
    if (.Platform$OS.type == "windows") {
      s <- suppressWarnings(system2("tasklist", c("/FI", paste0("\"PID eq ", Sys.getpid(), "\""), "/FO", "CSV", "/NH"), stdout = TRUE, stderr = FALSE))
      v <- gsub("[^0-9]", "", strsplit(s[length(s)], "\",\"")[[1]][5]); as.numeric(v) / 1024
    } else { l <- readLines("/proc/self/status"); as.numeric(gsub("[^0-9]", "", l[grepl("^VmRSS", l)])) / 1024 }
  }) %||% NA_real_
}
`%||%` <- function(a, b) if (is.null(a)) b else a
med <- function(x) round(stats::median(x), 2)

secao("1. Ambiente")
cat("Data:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat(R.version.string, "\n")
print(Sys.info()[c("sysname", "release", "version", "machine")])
cat("Processador:", Sys.getenv("PROCESSOR_IDENTIFIER"), "| núcleos:", parallel::detectCores(), "\n")
if (.Platform$OS.type == "windows")
  tenta("ram", { s <- suppressWarnings(system2("wmic", c("computersystem", "get", "TotalPhysicalMemory", "/value"), stdout = TRUE, stderr = FALSE))
                 v <- as.numeric(sub(".*=", "", s[grepl("TotalPhysicalMemory", s)])); cat("RAM instalada: ", round(v / 1024^3, 1), " GB\n", sep = "") })
cat("Pasta do projeto:", getwd(), "\n")
if (grepl("[^ -~]", getwd())) cat("  ATENÇÃO: o caminho tem acento ou caractere especial.\n")
if (grepl(" ", getwd())) cat("  Aviso: o caminho tem espaço.\n")
if (grepl("OneDrive|Dropbox|Google Drive", getwd(), ignore.case = TRUE)) cat("  ATENÇÃO: a pasta está numa pasta sincronizada (OneDrive/Dropbox); isso pode travar a leitura de arquivos.\n")
cat("Pasta temporária:", tempdir(), "\n")
cat("Codificação:", l10n_info()$`UTF-8`, "(UTF-8) | locale:", Sys.getlocale("LC_CTYPE"), "\n")
cat("Pastas de pacotes (.libPaths):\n"); for (l in .libPaths()) cat("  ", l, "\n")
cat("Pacotes (versão instalada | carregada nesta sessão | pasta):\n")
for (p in c("ggplot2", "scales", "patchwork", "ragg", "systemfonts", "shiny", "httpuv", "later", "jsonlite", "png", "jpeg", "svglite", "devEMF", "viridisLite", "sf", "vegan", "ggrepel")) {
  inst <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) "NÃO INSTALADO")
  carr <- if (isNamespaceLoaded(p)) getNamespaceVersion(p) else "-"
  pasta <- tryCatch(dirname(find.package(p)), error = function(e) "")
  cat(sprintf("  %-14s %-14s %-10s %s\n", p, inst, carr, pasta))
}
cat("Mínimos pedidos: ggplot2 >= 3.5.0, ragg >= 1.5.0, systemfonts >= 1.0.0, shiny >= 1.7.0 (R recente: 4.4 ou mais novo)\n")
if (getRversion() < "4.3.0") cat("  AVISO: este R é antigo; pacotes novos podem não ter versão pronta para ele (o instalador do Cinabro leva o seu próprio R).\n")
if (tryCatch(utils::packageVersion("ragg") < "1.5.0", error = function(e) FALSE)) cat("  AVISO: ragg abaixo de 1.5.0 (gradientes radiais com defeito).\n")
if (tryCatch(utils::packageVersion("shiny") < "1.7.0", error = function(e) TRUE)) cat("  AVISO: o shiny não está instalado (ou é antigo): o app não abre sem ele.\n")
conf <- Filter(function(p) isNamespaceLoaded(p) && tryCatch(getNamespaceVersion(p) != utils::packageDescription(p)$Version, error = function(e) FALSE), c("ggplot2", "scales", "patchwork", "ragg", "systemfonts", "shiny"))
if (length(conf)) stop("Nesta sessão do R já estão carregadas versões ANTIGAS destes pacotes: ", paste(conf, collapse = ", "),
                       ". Reinicie o R (RStudio: Session > Restart R, ou Ctrl+Shift+F10) e rode este arquivo de novo.", call. = FALSE)
cat("Memória do processo R agora:", round(mem_proc()), "MB\n")

secao("2. Carregar o motor de gráficos")
tm <- system.time({ source("01_config.R", encoding = "UTF-8"); suppressMessages(source("02_motor.R", encoding = "UTF-8")) })
cat("Tempo para carregar o motor:", round(tm[["elapsed"]], 2), "s\n")
tenta("fonte", cat("Fonte Barlow resolvida como:", .fonte("Barlow"), "\n"))

secao("3. O tamanho da tela (app)")
dir_app <- file.path(getwd(), "app_shiny"); dir_raiz <- getwd()
tem_shiny <- requireNamespace("shiny", quietly = TRUE)
if (tem_shiny) suppressPackageStartupMessages(library(shiny)) else cat("  O pacote shiny não está instalado: as seções 3 a 6 foram puladas. Instale com install.packages(\"shiny\") e rode de novo.\n")
ok_app <- if (!tem_shiny) FALSE else tenta("carregar o app", { old <- setwd(dir_app); tryCatch({ suppressMessages(source("app.R", encoding = "UTF-8", local = FALSE)); TRUE }, finally = setwd(old)) })
if (isTRUE(ok_app)) {
  campos <- ESPEC_CAMPOS
  com_se <- sum(vapply(campos, function(c) !is.null(c$se), NA))
  cat("Blocos:", length(ESPEC), "| campos:", length(campos), "| campos com regra 'mostrar só se':", com_se, "\n")
  tipos <- table(vapply(campos, function(c) c$tipo, ""))
  cat("Campos por tipo: ", paste(names(tipos), tipos, sep = "=", collapse = ", "), "\n", sep = "")
  cat("Campos dos cartões (ajustes, traços, caixas, formas, figuras):", length(IDS_SLOT), "\n")
  cat("Paletas na lista:", length(unlist(.PALETAS_GRUPOS)), "\n")
  html <- tenta("html", as.character(construir_ui("pt")))
  if (!is.null(html)) {
    h <- paste(html, collapse = "")
    cat("Tamanho do HTML da página:", round(nchar(h, type = "bytes") / 1024), "KB\n")
    cat("Entradas na página (shiny-input):", length(gregexpr("shiny-input-container|cor-input|shiny-input-checkbox", h)[[1]]),
        "| painéis condicionais:", length(gregexpr("data-display-if", h, fixed = TRUE)[[1]]), "\n")
  }
}

secao("4. Tempo de montar o gráfico (cada cenário 5 vezes; mediana, em segundos)")
if (isTRUE(ok_app)) {
  op <- utils::modifyList(CFG0$dados, list(relatorio = FALSE))
  d1 <- tenta("csv1", suppressMessages(ler_csv(file.path(dir_raiz, "dados", "ensaio_temperatura.csv"), op)))
  d2 <- tenta("csv2", suppressMessages(ler_csv(file.path(dir_raiz, "dados", "exemplo_dois_eixos_e_quebra.csv"), op)))
  cen <- list(
    "Linha com pontos, padrão" = list(d = d1, v = list()),
    "Barras" = list(d = d1, v = list(tipo_grafico = "barras")),
    "Dois eixos Y + quebra de eixo" = list(d = d2, v = list(y2_series = names(d2)[length(names(d2))], quebra_ativar = TRUE, quebra_de = 100000, quebra_ate = 450000)),
    "Ajuste (fórmula livre) + caixa de estatística + forma" = list(d = d1, v = list(tipo_grafico = "pontos", colunas_y = c("Amostra A", "Amostra B"),
        ajustes = list(list(serie = "Amostra B", tipo = "formula", formula = "a*(1 - exp(-b*x))", banda = TRUE), list(serie = "Amostra A", tipo = "polinomial", grau = 3)),
        caixas_estatisticas = list(list(itens = c("media", "dp", "equacao", "r2", "anova", "tukey"), sombra = TRUE)),
        formas = list(list(tipo = "texto", texto = "teste")))))
  for (nm in names(cen)) {
    x <- cen[[nm]]; if (is.null(x$d)) next
    t_c <- t_d <- numeric(0)
    for (i in 1:5) {
      t_c[i] <- system.time(r <- construir_grafico(x$d, x$v, CFG0))[["elapsed"]]
      if (!is.null(r$erro)) { cat("  [", nm, "] erro: ", r$erro, "\n", sep = ""); break }
      t_d[i] <- system.time(desenhar_previa(r$g, r$cfg, dpi = 130))[["elapsed"]]
    }
    if (length(t_d) == 5) cat(sprintf("  %-55s montar %5.2f s | desenhar %5.2f s | total %5.2f s\n", nm, med(t_c), med(t_d), med(t_c) + med(t_d)))
  }
  cat("  (se 'total' passa de 2 s, cada alteração na tela já parece lenta)\n")
}

secao("5. Custo de ler a tela inteira a cada alteração")
if (isTRUE(ok_app)) {
  v0 <- lapply(ESPEC_CAMPOS, valor_inicial, cfg0 = CFG0)
  t <- system.time(for (i in 1:50) montar_variaveis(v0, CFG0, NULL))[["elapsed"]] / 50
  cat(sprintf("  montar as variáveis a partir de %d campos: %.1f ms por alteração\n", length(v0), t * 1000))
}

secao("6. Uso repetido: a memória e a pasta temporária crescem?")
if (isTRUE(ok_app)) {
  options(gerador_sem_guia = TRUE)
  conta_tmp <- function() { f <- list.files(tempdir(), recursive = TRUE, full.names = TRUE); c(n = length(f), mb = round(sum(file.size(f), na.rm = TRUE) / 1024^2, 1)) }
  linhas <- list()
  tenta("testServer", testServer(servidor, {
    session$setInputs(exemplo = "ensaio_temperatura.csv", auto = FALSE)
    for (i in 1:25) {
      session$setInputs(atualizar = i, dpi = 100 + i %% 3 * 50, tipo_grafico = c("linha_pontos", "pontos", "linha")[i %% 3 + 1])
      if (i %% 5 == 0) { gc(verbose = FALSE); tmp <- conta_tmp(); linhas[[length(linhas) + 1]] <<- c(i = i, mem_r = round(sum(gc()[, 2])), mem_proc = round(mem_proc()), tmp_arquivos = tmp[["n"]], tmp_mb = tmp[["mb"]]) }
    }
  }))
  if (length(linhas)) { m <- do.call(rbind, linhas); print(as.data.frame(m), row.names = FALSE)
    cat("  mem_r = memória usada pelos objetos do R (MB); mem_proc = memória do processo R (MB); tmp = arquivos na pasta temporária.\n")
    cat("  Se mem_proc ou tmp_mb sobem sempre, há acúmulo ao longo do uso.\n") }
}

secao("7. Registro de uso do app (últimas linhas)")
arq_log <- file.path(if (nzchar(Sys.getenv("LOCALAPPDATA"))) Sys.getenv("LOCALAPPDATA") else file.path(Sys.getenv("HOME"), ".local", "share"), "Cinabro", "log", "app.log")
if (file.exists(arq_log)) { l <- readLines(arq_log, warn = FALSE, encoding = "UTF-8"); cat("Arquivo:", arq_log, "(", length(l), "linhas )\n"); cat(tail(l, 80), sep = "\n") } else cat("Ainda não há registro (abra o app e use um pouco; depois rode este diagnóstico de novo).\n")

secao("Fim")
cat("Duração total do diagnóstico:", round(as.numeric(difftime(Sys.time(), t_ini, units = "secs"))), "s\n")
cat("Arquivo gravado:", normalizePath(saida), "\n")
TRUE
}, error = function(e) { cat("\nO diagnóstico parou com erro: ", conditionMessage(e), "\n", sep = ""); FALSE },
finally = sink())
message("\nPronto. Envie o arquivo: ", normalizePath(saida))
