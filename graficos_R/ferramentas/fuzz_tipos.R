# =============================================================================
#  ferramentas/fuzz_tipos.R — varredura dos campos da tela nos tipos novos (PCA, CA, CCA, mapas, mapa de calor, boxplot, barras, pizza)
# =============================================================================
#  Para cada tipo de gráfico, troca UM campo da tela por vez por um valor alternativo e confere que o gráfico sai ou que o erro é um aviso em
#  português (nunca uma mensagem em inglês do ggplot2). Mostra só as ocorrências; as de validação esperadas (escala log com valores negativos,
#  quebra de eixo em tipo que não tem eixo, eixo da ordenação que não existe...) aparecem com a mensagem do próprio Cinabro.
#  uso (na pasta graficos_R):  Rscript ferramentas/fuzz_tipos.R         (cerca de 1 hora; em partes: SHARD=0..3 NSHARD=4 Rscript ferramentas/fuzz_tipos.R)
# =============================================================================
aqui <- "app_shiny"; setwd(aqui)
suppressPackageStartupMessages(library(shiny)); raiz <- normalizePath("..", winslash="/")
source(file.path(raiz,"01_config.R"), encoding="UTF-8"); suppressMessages(source(file.path(raiz,"02_motor.R"), encoding="UTF-8"))
CFG0 <- .completar_cfg(cfg)
for (a in c("idiomas.R","espec.R","nucleo.R","ui_blocos.R","dashboard.R","servidor.R")) source(file.path("codigo",a), encoding="UTF-8")
op <- utils::modifyList(CFG0$dados, list(relatorio=FALSE))
v0 <- lapply(ESPEC_CAMPOS, valor_inicial, cfg0=CFG0)
alt <- function(c) {
  d <- v0[[c$id]]
  switch(c$tipo,
    num=, int = { lo <- if (is.na(c$min)) NA else c$min; hi <- if (is.na(c$max)) NA else c$max
        v <- if (!is.na(lo) && !is.na(hi)) (lo+hi)/2 else if (!is.na(lo)) lo + 2 else 3
        if (!is.na(d) && isTRUE(all.equal(v, d))) v + 1 else v },
    txt = if (grepl("intervalo", c$id)) "2" else "abc",
    vec = "2016, 2020",
    sel=, tri=, selbusca = { o <- unname(unlist(c$opcoes)); o <- o[o != "" & o != d]; o },
    chkgrupo = list(c("png"), c("tiff","svg")),
    chk = !isTRUE(d),
    cor = "#FF0000",
    selmulti = c("quadrado","triangulo"),
    colx = "Ano", colsy = names(dados)[2:3], colsy2 = names(dados)[5], NULL)
}
base <- function(c) {   # estado em volta do campo
  v <- v0
  if (grepl("^y2_", c$id)) v$y2_series <- names(dados)[5]
  if (grepl("^quebra_", c$id) && c$id != "quebra_ativar") { v$quebra_ativar <- TRUE }
  if (c$id %in% c("legenda_x","legenda_y","legenda_canto","legenda_distancia_pt","legenda_x_dados","legenda_y_dados")) v$legenda_posicao <- "dentro"
  if (c$id == "simbolo_forma") v$simbolo_modo <- "igual"
  if (c$id == "simbolos_ordem") v$simbolo_modo <- "variar"
  if (grepl("^quebra_y2", c$id)) v$y2_series <- names(dados)[5]
  v
}
falhas <- character(0); n <- 0
CASOS <- list(
  list(tp="pca", arq="ordenacao_amostras_variaveis_ambientais.csv", extra=list(coluna_grupo="Local", multi_variaveis=c("Aquila","Boreus","Caelum","Draco","Eridanus"), multi_ambientais=c("pH","Salinidade"))),
  list(tp="cca", arq="ordenacao_amostras_variaveis_ambientais.csv", extra=list(coluna_grupo="Local", multi_variaveis=c("Aquila","Boreus","Caelum","Draco","Eridanus"), multi_ambientais=c("pH","Salinidade"))),
  list(tp="ca", arq="ordenacao_amostras_variaveis_ambientais.csv", extra=list(coluna_grupo="Local", multi_variaveis=c("Aquila","Boreus","Caelum","Draco","Eridanus"))),
  list(tp="mapa_calor", arq="mapa_de_calor.csv", extra=list()), list(tp="mapa_mundo", arq="mapa_mundo_vendas.csv", extra=list()), list(tp="mapa_brasil", arq="mapa_brasil_estados.csv", extra=list()),
  list(tp="boxplot", arq="replicatas.csv", extra=list()), list(tp="barras", arq="resistencia_materiais.csv", extra=list()), list(tp="pizza", arq="composicao_liga.csv", extra=list()))
falhas <- character(0); n <- 0; t0 <- Sys.time()
SH <- as.integer(Sys.getenv("SHARD","0")); NS <- as.integer(Sys.getenv("NSHARD","1"))
for (cs in CASOS[seq_along(CASOS) %% NS == SH]) {
  dados <- suppressWarnings(ler_csv(file.path(raiz, "dados", cs[["arq"]]), op))
  base <- function(c) { v <- v0; v$tipo_grafico <- cs[["tp"]]; v$multi_permutacoes <- 19; for (k in names(cs[["extra"]])) v[[k]] <- cs[["extra"]][[k]]; v }
  for (id in names(ESPEC_CAMPOS)) {
    c <- ESPEC_CAMPOS[[id]]; if (c$tipo %in% c("colx", "colsy", "colsy2", "selmulti", "arquivo")) next
    vals <- alt(c); if (!is.list(vals)) vals <- as.list(vals)
    for (val in vals) {
      v <- base(c); v[[id]] <- val; n <- n + 1; rot <- paste0(cs[["tp"]], ": ", id, "=", paste(val, collapse = "/"))
      vars <- tryCatch(montar_variaveis(v, CFG0, NULL), error = function(e) { falhas <<- c(falhas, paste0(rot, " [montar] ", conditionMessage(e))); NULL })
      if (is.null(vars)) next
      r <- suppressWarnings(construir_grafico(dados, vars, CFG0, preview = FALSE))
      if (!is.null(r$erro)) falhas <- c(falhas, paste0(rot, " -> ", substr(r$erro, 1, 160)))
      else tryCatch(desenhar_previa(r$g, r$cfg, dpi = 40), error = function(e) falhas <<- c(falhas, paste0(rot, " [desenhar] ", conditionMessage(e))))
    }
  }
  cat(cs[["tp"]], "ok;", n, "casos;", length(falhas), "ocorrências;", round(as.numeric(Sys.time() - t0, units = "secs")), "s\n"); if (length(falhas)) writeLines(paste0("  ! ", substr(falhas, 1, 260))); falhas <- character(0)
}
cat("\n", n, "casos;", length(falhas), "ocorrências\n"); writeLines(substr(falhas, 1, 300))
