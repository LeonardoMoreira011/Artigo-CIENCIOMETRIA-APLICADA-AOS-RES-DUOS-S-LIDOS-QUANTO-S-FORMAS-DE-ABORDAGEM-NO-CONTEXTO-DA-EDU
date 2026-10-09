# =============================================================================
#  06_testes.R — TESTES AUTOMÁTICOS (rode depois de qualquer alteração no motor)
# =============================================================================
#  Ctrl+Shift+S. Ao final mostra "N PASSOU / M FALHOU". Não grava nada no
#  projeto (usa uma pasta temporária). Cada teste documenta um comportamento
#  que já quebrou ou que é crítico.
# =============================================================================

source("01_config.R", encoding = "UTF-8")
source("02_motor.R", encoding = "UTF-8")

.res <- c(passou = 0, falhou = 0)
teste <- function(nome, expr) {
  ok <- tryCatch(suppressWarnings(isTRUE(expr)), error = function(e) { message("   erro: ", conditionMessage(e)); FALSE })
  .res[if (ok) "passou" else "falhou"] <<- .res[if (ok) "passou" else "falhou"] + 1
  cat(sprintf("[%s] %s\n", if (ok) "PASSOU" else "FALHOU", nome))
}
da_erro <- function(expr, padrao) {
  m <- tryCatch({ suppressWarnings(force(expr)); "" }, error = function(e) conditionMessage(e))
  grepl(padrao, m, fixed = TRUE)
}
da_aviso <- function(expr, padrao) {
  w <- character(0)
  withCallingHandlers(tryCatch(force(expr), error = function(e) NULL),
                      warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  any(grepl(padrao, w, fixed = TRUE))
}
monta <- function(g) { if (inherits(g, "patchwork")) { f <- tempfile(fileext = ".png"); ragg::agg_png(f); print(g); dev.off(); TRUE } else { ggplot2::ggplot_build(g); TRUE } }
camada <- function(g, col) { b <- ggplot2::ggplot_build(g); for (d in b$data) if (all(col %in% names(d))) return(d); NULL }

op <- utils::modifyList(cfg$dados, list(relatorio = FALSE))
tmp <- tempfile("testes_"); dir.create(tmp)
c0 <- cfg; c0$exportacao$pasta <- tmp; c0$exportacao$dpi <- 72; c0$exportacao$formatos <- "png"

cat("\n--- Leitura de CSV ---\n")
arq <- file.path(tmp, "sujo.csv")
writeLines(iconv(c("Amostra;Valor;Concentração", "A;1.234,5;1", "B;2,75;2", "C;n.d.;3", "D;-3,1;4"), "UTF-8", "latin1"),
           arq, useBytes = TRUE)
s <- ler_csv(arq, op)
teste("vírgula decimal + milhar com ponto (1.234,5 -> 1234.5)", isTRUE(all.equal(s$Valor[c(1, 2, 4)], c(1234.5, 2.75, -3.1))))
teste("texto 'n.d.' em coluna numérica vira NA", is.na(s$Valor[3]) && is.numeric(s$Valor))
teste("acentos de CSV latin1 preservados", "Concentração" %in% names(s))
arq2 <- file.path(tmp, "virgula.csv"); writeLines(c("x,y", "1,1.5", "2,2.5"), arq2)
teste("separador vírgula com ponto decimal não vira milhar", identical(ler_csv(arq2, op)$y, c(1.5, 2.5)))
arq3 <- file.path(tmp, "excel.csv"); writeLines(c("sep=;", "a;b", "1;2,5"), arq3)
teste("linha 'sep=;' do Excel é reconhecida", identical(ler_csv(arq3, op)$b, 2.5))

cat("\n--- Eixos ---\n")
ax <- .calc_eixo(utils::modifyList(cfg$eixo_y, list(inicio = 0, fim = 1.2)), c(0, 1.2))
teste("tick no limite exato não é descartado (1.2 em 0..1.2)", any(ax$maiores == 1.2))
ax <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(ticks_modo = "incremento", incremento = 10, inicio = 0, fim = 60, n_menores = 1)), c(0, 60))
teste("incremento 10 gera 0,10,...,60 e menores em 5,15,...", identical(ax$maiores, seq(0, 60, 10)) && all(seq(5, 55, 10) %in% ax$menores))
ax <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(escala = "log10", n_menores = 8)), c(1, 1000))
teste("log10: décadas 1..1000 e menores 2..9", identical(ax$maiores, c(1, 10, 100, 1000)) && all(2:9 %in% ax$menores))
ax <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(escala = "reciproco", inicio = 5, fim = 60)), c(5, 60))
teste("recíproca: ticks redondos", all(ax$maiores == round(ax$maiores)))
f <- .formatador(list(casas_decimais = 2)); teste("casas_decimais = 2 com ponto", identical(f(c(1, 2.5)), c("1.00", "2.50")))
f <- .formatador(list(notacao = "milhar")); teste("notação milhar usa vírgula só como milhar", identical(f(1234567.5), "1,234,567.5"))
teste("texto com ^{ } vira expressão", is.call(.texto("m^{2}")) || is.expression(.texto("m^{2}")))

cat("\n--- Validação ---\n")
d <- ler_csv("dados/ensaio_temperatura.csv", op)
teste("tipo inválido sugere o certo", da_erro(plotar(d, utils::modifyList(c0, list(grafico = list(tipo = "pizzza")))), "pizza"))
teste("coluna inexistente sugere a parecida", da_erro(plotar(d, utils::modifyList(c0, list(grafico = list(coluna_x = "tempo (min)")))), "Tempo (min)"))
teste("inicio >= fim dá erro claro", da_erro(plotar(d, utils::modifyList(c0, list(eixo_y = list(inicio = 10, fim = 0)))), "inverter"))
c1 <- c0; c1$eixo_x$incremeto <- 5
teste("parâmetro digitado errado gera aviso com sugestão", da_aviso(plotar(d, c1), "incremento"))
teste("cor inválida dá erro", da_erro(plotar(d, utils::modifyList(c0, list(series = list(`Amostra A` = list(cor = "vermelho"))))), "Cor inválida"))

cat("\n--- Todos os tipos montam ---\n")
mat <- ler_csv("dados/resistencia_materiais.csv", op); liga <- ler_csv("dados/composicao_liga.csv", op)
rp <- ler_csv("dados/replicatas.csv", op); m <- ler_csv("dados/multissinal.csv", op)
for (tp in c("pontos", "linha", "linha_pontos", "area", "area_empilhada"))
  teste(paste("tipo", tp), monta(plotar(d, utils::modifyList(c0, list(grafico = list(tipo = tp, colunas_y = c("Amostra A", "Amostra B")))))))
for (arr in c("agrupado", "empilhado", "empilhado_100")) for (ori in c("vertical", "horizontal"))
  teste(paste("barras", arr, ori), monta(plotar(mat, utils::modifyList(c0, list(grafico = list(tipo = "barras", colunas_y = c("Ensaio 1", "Ensaio 2")), barras = list(arranjo = arr, orientacao = ori))))))
teste("pizza / rosca", monta(plotar(liga, utils::modifyList(c0, list(grafico = list(tipo = "pizza"), pizza = list(raio_furo = 0.5, explodir = "Cromo"))))))
for (tp in c("histograma", "densidade", "ecdf")) teste(paste("tipo", tp), monta(plotar(rp, utils::modifyList(c0, list(grafico = list(tipo = tp))))))
for (v in c("box", "box_pontos", "meio_box", "violino", "violino_box", "media_erro"))
  teste(paste("boxplot", v), monta(plotar(rp, utils::modifyList(c0, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = v, entalhe = v == "box"))))))

cat("\n--- Regressões já corrigidas ---\n")
b <- data.frame(Cat = c("A", "B", "C"), V1 = c(10, NA, 30), V2 = c(5, 6, 7), E1 = c(1, 2, 3), check.names = FALSE)
c1 <- c0; c1$grafico$tipo <- "barras"; c1$grafico$colunas_y <- c("V1", "V2"); c1$barras$rotulos_valor <- TRUE; c1$barras$rotulos_casas <- 0
c1$series[["V1"]] <- list(coluna_erro = "E1")
g <- plotar(b, c1)
rot <- camada(g, "label"); err <- camada(g, c("ymin", "ymax", "width"))
teste("barras com NA: rótulo de cada barra = seu valor", identical(as.numeric(rot$label), rot$y))
teste("barras com NA: erro da barra C usa o erro da linha C (27 a 33)", any(err$ymin == 27 & err$ymax == 33))
c1 <- c0; c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "pontos", coluna_x = "Tensão (V)", colunas_y = "Corrente (mA)"))
c1$eixo_x$escala <- "log10"; c1$cores$mapear_coluna <- "Temperatura (°C)"
teste("mapa de cor + escala log com linhas descartadas", monta(plotar(m, c1)))
c1 <- c0; c1$paineis$ativo <- TRUE; c1$grafico$coluna_x <- "Tempo (s)"; c1$series[["Tensão (V)"]] <- list(cor = "navy")
c1$paineis$lista <- list(list(grafico = list(colunas_y = "Tensão (V)")), list(grafico = list(colunas_y = "Corrente (mA)")))
teste("painéis com cfg$series global não geram aviso falso", !da_aviso(plotar(m, c1), "não corresponde"))
teste("painéis montam", monta(plotar(m, c1)))
c1 <- c0; c1$quebra <- list(ativo = TRUE, de = 450, ate = 800, proporcao_superior = 0.35, espaco_pt = 4, marcas = TRUE)
c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "barras", colunas_y = "Ensaio 1")); c1$eixo_y$inicio <- 0; c1$eixo_y$fim <- 1000
teste("quebra de eixo monta", monta(plotar(mat, c1)))
c1 <- c0; c1$eixo_y2 <- utils::modifyList(c1$eixo_y2, list(ativo = TRUE, modo = "transformado", fator = 1.8, deslocamento = 32))
teste("eixo Y2 transformado monta", monta(plotar(d, c1)))

cat("\n--- Exportação e estilos ---\n")
c1 <- c0; c1$exportacao$formatos <- c("png", "pdf", "svg", "tiff"); c1$exportacao$nome_arquivo <- "t"
arqs <- salvar(plotar(d, c1), c1)
teste("png/pdf/svg/tiff gravados e não vazios", all(file.exists(arqs)) && all(file.size(arqs) > 1000))
teste("nenhum dispositivo gráfico ficou aberto", is.null(grDevices::dev.list()))
c1 <- c0; c1$texto$tamanho_base_pt <- 14
salvar_estilo(c1, "tmp_teste", pasta = tmp)
teste("estilo: salvar e carregar de volta", carregar_estilo("tmp_teste", c0, pasta = tmp)$texto$tamanho_base_pt == 14)

cat(sprintf("\n==== %d PASSOU / %d FALHOU ====\n", .res["passou"], .res["falhou"]))
unlink(tmp, recursive = TRUE)
