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
  ok <- tryCatch(suppressWarnings(isTRUE(expr)),
                 error = function(e) { message("   erro: ", conditionMessage(e)); FALSE })
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
avisos_de <- function(expr) {
  w <- character(0)
  withCallingHandlers(tryCatch(force(expr), error = function(e) NULL),
                      warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  w
}
monta <- function(g) { if (inherits(g,
                                    "patchwork")) { f <- tempfile(fileext = ".png"); ragg::agg_png(f); print(g); dev.off(); TRUE } else { ggplot2::ggplot_build(g); TRUE } }
camada <- function(g,
                   col) { b <- ggplot2::ggplot_build(g); for (d in b$data) if (all(col %in% names(d))) return(d); NULL }

op <- utils::modifyList(cfg$dados, list(relatorio = FALSE))
tmp <- tempfile("testes_"); dir.create(tmp)
c0 <- cfg; c0$exportacao$pasta <- tmp; c0$exportacao$dpi <- 72; c0$exportacao$formatos <- "png"

cat("\n--- Leitura de CSV ---\n")
arq <- file.path(tmp, "sujo.csv")
writeLines(iconv(c("Amostra;Valor;Concentração", "A;1.234,5;1", "B;2,75;2", "C;n.d.;3", "D;-3,1;4"), "UTF-8", "latin1"),
           arq, useBytes = TRUE)
s <- ler_csv(arq, op)
teste("vírgula decimal + milhar com ponto (1.234,5 -> 1234.5)",
      isTRUE(all.equal(s$Valor[c(1, 2, 4)], c(1234.5, 2.75, -3.1))))
teste("texto 'n.d.' em coluna numérica vira NA", is.na(s$Valor[3]) && is.numeric(s$Valor))
teste("acentos de CSV latin1 preservados", "Concentração" %in% names(s))
arq2 <- file.path(tmp, "virgula.csv"); writeLines(c("x,y", "1,1.5", "2,2.5"), arq2)
teste("separador vírgula com ponto decimal não vira milhar", identical(ler_csv(arq2, op)$y, c(1.5, 2.5)))
arq3 <- file.path(tmp, "excel.csv"); writeLines(c("sep=;", "a;b", "1;2,5"), arq3)
teste("linha 'sep=;' do Excel é reconhecida", identical(ler_csv(arq3, op)$b, 2.5))

cat("\n--- Eixos ---\n")
ax <- .calc_eixo(utils::modifyList(cfg$eixo_y, list(inicio = 0, fim = 1.2)), c(0, 1.2))
teste("tick no limite exato não é descartado (1.2 em 0..1.2)", any(ax$maiores == 1.2))
ax <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(ticks_modo = "incremento", incremento = 10, inicio = 0, fim = 60,
                                                    n_menores = 1)), c(0, 60))
teste("incremento 10 gera 0,10,...,60 e menores em 5,15,...",
      identical(ax$maiores, seq(0, 60, 10)) && all(seq(5, 55, 10) %in% ax$menores))
ax <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(escala = "log10", n_menores = 8)), c(1, 1000))
teste("log10: décadas 1..1000 e menores 2..9", identical(ax$maiores, c(1, 10, 100, 1000)) && all(2:9 %in% ax$menores))
ax <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(escala = "reciproco", inicio = 5, fim = 60)), c(5, 60))
teste("recíproca: ticks redondos", all(ax$maiores == round(ax$maiores)))
f <- .formatador(list(casas_decimais = 2)); teste("casas_decimais = 2 com ponto",
                                                  identical(f(c(1, 2.5)), c("1.00", "2.50")))
f <- .formatador(list(notacao = "milhar")); teste("notação milhar usa vírgula só como milhar",
                                                  identical(f(1234567.5), "1,234,567.5"))
teste("texto com ^{ } vira expressão", is.call(.texto("m^{2}")) || is.expression(.texto("m^{2}")))

cat("\n--- Validação ---\n")
d <- ler_csv("dados/ensaio_temperatura.csv", op)
teste("tipo inválido sugere o certo", da_erro(plotar(d, utils::modifyList(c0, list(grafico = list(tipo = "pizzza")))),
                                              "pizza"))
teste("coluna inexistente sugere a parecida", da_erro(plotar(d,
                                                             utils::modifyList(c0, list(grafico = list(coluna_x = "tempo (min)")))), "Tempo (min)"))
teste("inicio >= fim dá erro claro", da_erro(plotar(d,
                                                    utils::modifyList(c0,
                                                                      list(eixo_y = list(inicio = 10, fim = 0)))), "inverter"))
c1 <- c0; c1$eixo_x$incremeto <- 5
teste("parâmetro digitado errado gera aviso com sugestão", da_aviso(plotar(d, c1), "incremento"))
teste("cor inválida dá erro", da_erro(plotar(d, utils::modifyList(c0,
                                                                  list(series = list(`Amostra A` = list(cor = "vermelho"))))), "Cor inválida"))

cat("\n--- Todos os tipos montam ---\n")
mat <- ler_csv("dados/resistencia_materiais.csv", op); liga <- ler_csv("dados/composicao_liga.csv", op)
rp <- ler_csv("dados/replicatas.csv", op); m <- ler_csv("dados/multissinal.csv", op)
for (tp in c("pontos", "linha", "linha_pontos", "area", "area_empilhada"))
  teste(paste("tipo", tp), monta(plotar(d, utils::modifyList(c0,
                                                             list(grafico = list(tipo = tp, colunas_y = c("Amostra A", "Amostra B")))))))
for (arr in c("agrupado", "empilhado", "empilhado_100")) for (ori in c("vertical", "horizontal"))
  teste(paste("barras", arr, ori), monta(plotar(mat,
                                                utils::modifyList(c0,
                                                                  list(grafico = list(tipo = "barras", colunas_y = c("Ensaio 1", "Ensaio 2")), barras = list(arranjo = arr, orientacao = ori))))))
teste("pizza / rosca", monta(plotar(liga, utils::modifyList(c0, list(grafico = list(tipo = "pizza"),
                                                                     pizza = list(raio_furo = 0.5, explodir = "Cromo"))))))
for (tp in c("histograma", "densidade", "ecdf")) teste(paste("tipo", tp),
                                                       monta(plotar(rp,
                                                                    utils::modifyList(c0, list(grafico = list(tipo = tp))))))
for (v in c("box", "box_pontos", "meio_box", "violino", "violino_box", "media_erro"))
  teste(paste("boxplot", v), monta(plotar(rp, utils::modifyList(c0,
                                                                list(grafico = list(tipo = "boxplot"),
                                                                     boxplot = list(variacao = v, entalhe = v == "box"))))))

cat("\n--- Regressões já corrigidas ---\n")
b <- data.frame(Cat = c("A", "B", "C"), V1 = c(10, NA, 30), V2 = c(5, 6, 7), E1 = c(1, 2, 3), check.names = FALSE)
c1 <- c0; c1$grafico$tipo <- "barras"; c1$grafico$colunas_y <- c("V1",
                                                                 "V2"); c1$barras$rotulos_valor <- TRUE; c1$barras$rotulos_casas <- 0
c1$series[["V1"]] <- list(coluna_erro = "E1")
g <- plotar(b, c1)
rot <- camada(g, "label"); err <- camada(g, c("ymin", "ymax", "width"))
teste("barras com NA: rótulo de cada barra = seu valor", identical(as.numeric(rot$label), rot$y))
teste("barras com NA: erro da barra C usa o erro da linha C (27 a 33)", any(err$ymin == 27 & err$ymax == 33))
c1 <- c0; c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "pontos", coluna_x = "Tensão (V)",
                                                           colunas_y = "Corrente (mA)"))
c1$eixo_x$escala <- "log10"; c1$cores$mapear_coluna <- "Temperatura (°C)"
teste("mapa de cor + escala log com linhas descartadas", monta(plotar(m, c1)))
c1 <- c0; c1$paineis$ativo <- TRUE; c1$grafico$coluna_x <- "Tempo (s)"; c1$series[["Tensão (V)"]] <- list(cor = "navy")
c1$paineis$lista <- list(list(grafico = list(colunas_y = "Tensão (V)")),
                         list(grafico = list(colunas_y = "Corrente (mA)")))
teste("painéis com cfg$series global não geram aviso falso", !da_aviso(plotar(m, c1), "não corresponde"))
teste("painéis montam", monta(plotar(m, c1)))
c1 <- c0; c1$quebra <- list(ativo = TRUE, de = 450, ate = 800, proporcao_superior = 0.35, espaco_pt = 4, marcas = TRUE)
c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "barras",
                                                 colunas_y = "Ensaio 1")); c1$eixo_y$inicio <- 0; c1$eixo_y$fim <- 1000
teste("quebra de eixo monta", monta(plotar(mat, c1)))
c1 <- c0; c1$eixo_y2 <- utils::modifyList(c1$eixo_y2, list(ativo = TRUE, modo = "transformado", fator = 1.8,
                                                           deslocamento = 32))
teste("eixo Y2 transformado monta", monta(plotar(d, c1)))

cat("\n--- Revisão profissional: cada teste abaixo FALHAVA antes da correção ---\n")
# ---- Leitura de CSV
arq <- file.path(tmp, "campos.csv")
writeLines(c("x;y", "1;2", "3;4", "5;6", "7;8", "9;10", "11;12;99", "13;14"), arq)
r <- suppressWarnings(ler_csv(arq, op))
teste("CSV: linha com campo a mais não cria linha fantasma nem embaralha dados",
      nrow(r) == 7 && identical(r$x, c(1, 3, 5, 7, 9, 11, 13)))
teste("CSV: campo a mais gera aviso com o nº da linha", da_aviso(ler_csv(arq, op), "linha 7"))
arq <- file.path(tmp, "curta.csv"); writeLines(c("a;b;c", "1;2;3", "4;5", "7;8;9"), arq)
teste("CSV: linha com campo a menos gera aviso", da_aviso(ler_csv(arq, op), "menos campos"))
u16 <- file.path(tmp, "u16.csv")
writeBin(c(as.raw(c(0xFF, 0xFE)), iconv("Concentração\tValor\r\n1\t2,5\r\n", "UTF-8", "UTF-16LE", toRaw = TRUE)[[1]]),
         u16)
r <- ler_csv(u16, op)
teste("CSV: UTF-16LE com BOM (Texto Unicode do Excel), com acento",
      identical(names(r), c("Concentração", "Valor")) && r$Valor == 2.5)
u16 <- file.path(tmp, "u16be.csv")
writeBin(iconv("Tempo;Valor\n1;3,5\n", "UTF-8", "UTF-16BE", toRaw = TRUE)[[1]], u16)
r <- ler_csv(u16, op)
teste("CSV: UTF-16BE sem BOM é detectado", identical(names(r), c("Tempo", "Valor")) && r$Valor == 3.5)
teste("CSV: aviso de valor não numérico cita a linha real do arquivo",
      { arq2 <- file.path(tmp, "n.csv"); writeLines(c("a;b", "1;2", "", "3;oi", "4;5", "6;7", "8;9"), arq2)
        any(grepl("linha 4", attr(ler_csv(arq2, op), "avisos"), fixed = TRUE)) })

# ---- Colunas por número
c1 <- c0; c1$grafico$tipo <- "linha_pontos"; c1$grafico$coluna_x <- 1
c1$series[["Amostra A"]] <- list(coluna_erro = 5)
sers <- function(g) unique(unlist(lapply(g$layers,
                                         function(l) if (!is.null(l$data$serie)) as.character(unique(l$data$serie)))))
teste("coluna_erro dada por NÚMERO não aparece como série extra", !"Desvio A" %in% sers(plotar(d, c1)))
c1 <- c0; c1$grafico$tipo <- "pontos"; c1$grafico$coluna_x <- 1; c1$cores$mapear_coluna <- 5
teste("mapear_coluna dada por NÚMERO não aparece como série", !"Desvio A" %in% sers(plotar(d, c1)))

# ---- Caminho do projeto
cod <- file.path(tmp, "outro_cwd.R"); proj <- normalizePath(getwd(), winslash = "/")
writeLines(c(sprintf('source("%s/01_config.R", encoding = "UTF-8")', proj),
             sprintf('suppressMessages(source("%s/02_motor.R", encoding = "UTF-8"))', proj),
             sprintf('cat("RESULTADO:", exists("ajuda"), !is.null(.cfg_ref), identical(.motor_pasta, "%s"), length(listar_estilos()) > 0)', proj)), cod)
owd <- setwd(tempdir())
saida <- suppressWarnings(system2(file.path(R.home("bin"), "Rscript"), shQuote(cod), stdout = TRUE, stderr = FALSE))
setwd(owd)
teste("source() com caminho completo, de outra pasta de trabalho, acha config, ajuda e estilos",
      any(grepl("RESULTADO: TRUE TRUE TRUE TRUE", saida, fixed = TRUE)))

# ---- Exportação
g <- plotar(d,
            c0) + ggplot2::labs(title = "TIT") + ggplot2::theme(plot.title = ggplot2::element_text(colour = "#FF0000", size = 30))
cap <- ragg::agg_capture(width = 300, height = 220, res = 72, background = "transparent")
print(.fundo_transparente(g)); px <- cap(); invisible(grDevices::dev.off())
teste("fundo transparente: canto transparente E o + theme() do usuário preservado",
      grDevices::col2rgb(px[1, 1], alpha = TRUE)[4] == 0 && any(grepl("^#FF0000", px)))
c1 <- c0; c1$exportacao$fundo_transparente <- TRUE; c1$exportacao$nome_arquivo <- "transp"
teste("salvar() com fundo transparente grava o arquivo", { f <- salvar(g, c1); file.exists(f) && file.size(f) > 500 })

# ---- Boxplot
dl <- data.frame(g = c("A", "A", "A", "B"), v = c(1, 2, 3, 5))
c1 <- c0; c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "boxplot", coluna_grupo = "g", colunas_y = "v"))
c1$boxplot$variacao <- "violino"
teste("violino com grupo de 1 valor não trava: avisa em português", da_aviso(plotar(dl, c1), "Violino"))
set.seed(1); u1 <- runif(1); set.seed(1)
invisible(plotar(rp, utils::modifyList(c0, list(grafico = list(tipo = "boxplot"),
                                                boxplot = list(variacao = "box_pontos")))))
u2 <- runif(1)
teste("boxplot não altera a semente do gerador aleatório do usuário", u1 == u2)

# ---- Eixos e linhas
ax <- .calc_eixo(utils::modifyList(cfg$eixo_y, list(escala = "log10", ticks_modo = "incremento", incremento = 1,
                                                    inicio = 1e-10, fim = 1)), c(1e-10, 1))
teste("log10 com 11 décadas: ticks 1e-10 ... 1 sem duplicar nem perder o 1e-9",
      length(ax$maiores) == 11 && !anyDuplicated(ax$maiores) && any(ax$maiores == 1e-9))
dd <- data.frame(t = 1:5, a = c(0, 1, 2, 3, 4))
c1 <- c0; c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "pontos", coluna_x = "t",
                                                           colunas_y = "a")); c1$eixo_y$escala <- "log10"
teste("escala log: ponto com valor <= 0 gera aviso de omissão", da_aviso(plotar(dd, c1), "omitido"))
c2 <- c1; c2$paineis$ativo <- TRUE
c2$paineis$lista <- list(list(grafico = list(colunas_y = "a")), list(grafico = list(colunas_y = "a")))
teste("painéis: o aviso de omissão sai uma vez por painel (sem repetir na passada prévia)",
      sum(grepl("omitido", avisos_de(plotar(dd, c2)))) == 2)
dd <- data.frame(x = c(1, 3, 2, 4), y = c(1, 3, 2, 4))
c1 <- c0; c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "linha", coluna_x = "x"))
teste("linha segue a ordem do CSV por padrão", identical(camada(plotar(dd, c1), c("x", "y"))$x, c(1, 3, 2, 4)))
c1$linhas$ordenar_x <- TRUE
teste("linhas$ordenar_x = TRUE liga da esquerda para a direita",
      identical(camada(plotar(dd, c1), c("x", "y"))$x, c(1, 2, 3, 4)))
ax <- .calc_eixo(utils::modifyList(cfg$eixo_y, list(ticks_modo = "manual", ticks_manuais = c(0, 5, 10),
                                                    rotulos_manuais = c("a", "b", "c"), .ocultar_extremo = "max")), c(0, 10))
teste("ocultar_rotulo_encostado também vale para rotulos_manuais", identical(ax$rotulos, c("a", "b", "")))
c1 <- c0; c1$referencias <- list(list(eixo = "y", valor = 30, cor_linha = "red"))
teste("referencias: chave digitada errado gera aviso", da_aviso(plotar(d, c1), "cor_linha"))
c1 <- c0; c1$anotacoes$textos <- list(list(x = 1, y = 1, texto = "a", tamanho_ptt = 9))
teste("anotacoes$textos: chave digitada errado gera aviso", da_aviso(plotar(d, c1), "tamanho_ptt"))

# ---- Eixo Y2 (ticks menores) e pizza
cA <- c0; cA$grafico$colunas_y <- c("Amostra A", "Amostra B")
cA$eixo_y2 <- utils::modifyList(cA$eixo_y2, list(ativo = TRUE,
                                                 n_menores = 1)); cA$series[["Amostra B"]] <- list(eixo = "y2")
cB <- cA; cB$eixo_y2$n_menores <- 0
teste("eixo Y2 independente desenha ticks menores no lado direito",
      length(plotar(d, cA)$layers) > length(plotar(d, cB)$layers))
renderiza <- function(g) {                       # imagem (matriz de cores) do gráfico, 400 x 300 px
  cap <- ragg::agg_capture(width = 400, height = 300, res = 72)
  suppressWarnings(print(g)); r <- cap(); invisible(grDevices::dev.off()); r
}
fr <- ler_csv("dados/resposta_frequencia.csv", op)
cL <- c0; cL$grafico <- utils::modifyList(cL$grafico, list(coluna_x = 1, colunas_y = c("Amplitude", "Impedância")))
cL$eixo_x$escala <- "log10"; cL$eixo_x$n_menores <- 8; cL$caixa$fechada <- TRUE
cL$eixo_y2 <- utils::modifyList(cL$eixo_y2, list(ativo = TRUE,
                                                 n_menores = 1)); cL$series[["Impedância"]] <- list(eixo = "y2")
cM <- cL; cM$eixo_y2$n_menores <- 0
teste("Y2 + X em log: os ticks menores do Y2 aparecem na imagem (ggplot2 3.5 e 4.0)",
      !identical(renderiza(plotar(fr, cL)), renderiza(plotar(fr, cM))))
cL$eixo_y$direcao_maiores <- "ambos"
imprime <- function(g) { ragg::agg_capture(width = 400, height = 300,
                                           res = 72); print(g); invisible(grDevices::dev.off()) }
teste("Y2 + X em log + ticks 'ambos': imprimir não gera aviso de NaN",
      !any(grepl("NaN", avisos_de(imprime(plotar(fr, cL))))))
pz <- data.frame(Cat = c("Ferro", "Carbono", "Cromo", "Niquel", "Silicio", "Manganes", "Vanadio", "Molibdenio"),
                 v = c(70, 12, 6, 5, 3, 2.2, 1.2, 0.6))
c1 <- c0; c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "pizza", coluna_x = 1, colunas_y = "v"))
c1$pizza$rotulos_posicao <- "fora"; c1$pizza$rotulos <- c("categoria", "percentual"); c1$pizza$rotulos_separador <- "\n"
folga <- function(cf) { rd <- camada(plotar(pz, cf), "label"); min(diff(sort(rd$y[rd$x < 0]))) }
c2 <- c1; c2$pizza$rotulos_afastar <- FALSE
teste("pizza: rótulos de fatias pequenas vizinhas não se sobrepõem (rotulos_afastar)",
      folga(c1) > 0.15 && folga(c2) < 0.1)

# ---- Datas
sd <- ler_csv("dados/serie_temporal.csv", op)
teste("datas: ler_csv reconhece a coluna como data", colunas(sd)$tipo[1] == "data")
teste("datas: dd/mm/aaaa e aaaa-mm-dd viram Date (1 dia = 1 unidade)",
      { a <- .detectar_tempo(c("15/03/2024", "16/03/2024")); b <- .detectar_tempo(c("2024-03-15", "2024-03-16"))
        a$classe == "Date" && diff(a$num) == 1 && identical(a$num, b$num) })
teste("datas: texto que não é data continua categoria", is.null(.detectar_tempo(c("A", "B", "31/02/2024"))))
c1 <- c0; c1$grafico <- utils::modifyList(c1$grafico, list(tipo = "linha_pontos", coluna_x = 1,
                                                           colunas_y = "Temperatura (°C)"))
xs <- camada(plotar(sd, c1), c("x", "y"))$x
teste("datas: posição no eixo proporcional ao tempo (7,5 dias = 648000 s)",
      isTRUE(all.equal(xs[1], 1709251200)) && isTRUE(all.equal(diff(xs)[1], 648000)))
c1$eixo_x$tempo <- FALSE
teste("datas: eixo_x$tempo = FALSE mantém o comportamento antigo (categorias 1..n)",
      identical(camada(plotar(sd, c1), c("x", "y"))$x, as.numeric(1:12)))
tp <- list(classe = "POSIXct", formato = "%d/%m/%Y %H:%M")
tz <- .detectar_tempo(sd$`Data e hora`)$num
ax <- .calc_eixo(utils::modifyList(cfg$eixo_x, list(ticks_modo = "incremento", incremento = "1 mes",
                                                    inicio = "01/03/2024", fim = "01/06/2024")),
                 tz, tempo = tp)
teste("datas: ticks mensais com rótulo mm/aaaa", identical(ax$rotulos(ax$maiores),
                                                           c("03/2024", "04/2024", "05/2024", "06/2024")))
ax <- .calc_eixo(cfg$eixo_x, .detectar_tempo(c("15/03/2024 08:00", "15/03/2024 17:45"))$num, tempo = tp)
teste("datas: intervalo de horas gera ticks de hora cheia e rótulo HH:MM",
      identical(ax$rotulos(ax$maiores[1:2]), c("08:00", "09:00")))
teste("datas: inicio depois do fim dá erro claro",
      da_erro(.calc_eixo(utils::modifyList(cfg$eixo_x, list(inicio = "01/06/2024", fim = "01/03/2024")), c(1, 2),
                         tempo = tp), "anterior"))
teste("datas: passo de tempo inválido dá erro claro", da_erro(plotar(sd,
                                                                     utils::modifyList(c1, list(eixo_x = list(tempo = "auto", ticks_modo = "incremento", incremento = "foo")))), "incremento"))

cat("\n--- Pedidos do usuário: quebra de eixo, ÷1000, negrito ---\n")
teste("título com expoente (10^{3}) respeita o negrito (plotmath ignora a face do tema)",
      identical(as.character(.texto("Int. (×10^{3})", TRUE)[[1]]), "bold") && !is.call(.texto("Int.", TRUE)) &&
      !identical(as.character(.texto("Int. (×10^{3})", FALSE)[[1]]), "bold"))
gq <- data.frame(t = 1:10, A = c(120, 180, 250, 310, 95000, 98000, 99500, 100000, 97000, 99000),
                 B = c(80, 140, 200, 260, 88000, 91000, 94000, 96000, 95000, 98000))
cq <- c0; cq$grafico <- utils::modifyList(cq$grafico, list(tipo = "linha_pontos", coluna_x = 1,
                                                           colunas_y = c("A", "B")))
cq$eixo_y$titulo <- "I (×10^{3})"; cq$eixo_y$negrito_titulo <- TRUE; cq$eixo_y$fator_divisao <- 1000
teste("eixo Y com expoente e negrito: o título sai em bold()",
      identical(as.character(plotar(gq, cq)$labels$y[[1]]), "bold"))
sug <- NULL; saida <- utils::capture.output(sug <- sugerir_quebra(gq, cq))
teste("sugerir_quebra acha o maior vazio entre os dados e imprime as linhas prontas",
      sug$de > 310 && sug$ate < 88000 && sug$de < sug$ate && any(grepl("cfg$quebra$de", saida, fixed = TRUE)))
cq$quebra <- utils::modifyList(cq$quebra, list(ativo = TRUE, de = sug$de, ate = sug$ate, ligar_atraves = FALSE))
cq$eixo_y$mostrar_titulo <- FALSE
gb <- plotar(gq, cq)
ys_parte <- function(p) range(unlist(lapply(p$layers, function(l) if (!is.null(l$data$y)) l$data$y)), na.rm = TRUE)
lim_x <- function(p) ggplot2::ggplot_build(p)$layout$panel_scales_x[[1]]$get_limits()
teste("quebra com ligar_atraves = FALSE: cada parte mostra só os seus pontos",
      ys_parte(gb[[1]])[1] >= sug$ate && ys_parte(gb[[2]])[2] <= sug$de)
teste("quebra: as duas partes compartilham o mesmo eixo X", identical(lim_x(gb[[1]]), lim_x(gb[[2]])))
cq$quebra$ligar_atraves <- TRUE; gb <- plotar(gq, cq)
teste("quebra com ligar_atraves = TRUE (padrão) mantém todos os pontos nas duas partes",
      ys_parte(gb[[1]])[1] < sug$de && ys_parte(gb[[2]])[2] > sug$ate)

cat("\n--- Painel de ajustes e grade ---\n")
pe <- list2env(list(x_intervalo = 1, x_ticks_menores = 0, y_ticks_menores = 0, x_inicio = 2015, x_fim = 2026,
                    x_folga_pct = 4, grade_x = TRUE, grade_y = TRUE, grade_tipo = "dashed", grade_cor = "#1F4E9E",
                    grade_opacidade = 0.35, recortar_nos_limites = FALSE, fonte = "serif", eixos_titulo_negrito = TRUE,
                    cores_por_serie = c(WORLD = "#000000", BRAZIL = "#1F4E9E"), y_dividir_por = 1000,
                    quebra_ativar = TRUE, quebra_ligar_pontos = FALSE, tipo_grafico = "linha_pontos", coluna_x = 1))
an <- data.frame(Years = 2015:2026, WORLD = c(460, 466, 492, 512, 520, 500, 545, 548, 590, 610, 645, 690) * 1000,
                 LATAM = c(65, 62, 70, 66, 64, 55, 57, 63, 72, 76, 80, 85) * 1000,
                 BRAZIL = c(25, 23, 30, 26, 24, 14, 12, 17, 28, 31, 33, 35) * 1000)
cp <- suppressMessages(aplicar_painel(c0, pe, dados = suppressMessages(an)))
teste("painel: x_intervalo = 1 vira ticks_modo incremento; ticks menores 0; limites; folga",
      cp$eixo_x$ticks_modo == "incremento" && cp$eixo_x$incremento == 1 && cp$eixo_x$n_menores == 0 &&
      cp$eixo_x$inicio == 2015 && cp$eixo_x$fim == 2026 && cp$eixo_x$margem_percentual == 4)
teste("painel: grade tracejada com cor e transparência; sem recorte; fonte; negrito nos dois eixos",
      cp$grade$tipo_maior == "dashed" && cp$grade$opacidade_maior == 0.35 && cp$grade$maior_x && !cp$caixa$recortar &&
      cp$texto$fonte == "serif" && cp$eixo_x$negrito_titulo && cp$eixo_y$negrito_titulo)
teste("painel: cores_por_serie cria cfg$series e quebra_ativar acha de/ate sozinho",
      cp$series$WORLD$cor == "#000000" && cp$series$BRAZIL$cor == "#1F4E9E" && isTRUE(cp$quebra$ativo) &&
      cp$quebra$de > 85000 && cp$quebra$ate > cp$quebra$de && cp$quebra$ate < 460000 && !cp$quebra$ligar_atraves)
teste("painel: tudo NULL não muda nada (o cfg sai igual ao padrão)",
      identical(suppressMessages(aplicar_painel(c0, list2env(list()))), .completar_cfg(c0)))
cg <- c0; cg$grafico <- utils::modifyList(cg$grafico, list(tipo = "linha_pontos", coluna_x = 1))
cg$grade <- utils::modifyList(cg$grade, list(maior_x = TRUE, cor_maior = "#1F4E9E", opacidade_maior = 0.35,
                                             tipo_maior = "dashed"))
col <- plotar(an, cg)$theme$panel.grid.major.x$colour
teste("grade: opacidade_maior vira transparência real na cor (#RRGGBBAA com AA < FF)",
      grepl("^#[0-9A-Fa-f]{8}$", col) && toupper(substr(col, 8, 9)) != "FF")
cg$grade$opacidade_maior <- 1
teste("grade: opacidade 1 mantém a cor cheia (comportamento antigo)",
      !grepl("^#[0-9A-Fa-f]{8}$", plotar(an, cg)$theme$panel.grid.major.x$colour) ||
      toupper(substr(plotar(an, cg)$theme$panel.grid.major.x$colour, 8, 9)) == "FF")
cx <- cp; cx$grafico$colunas_y <- c("WORLD", "BRAZIL"); cx$quebra$ativo <- FALSE; cx$eixo_y$fator_divisao <- 1000
ax <- plotar(an, cx); inf <- attr(ax, "info")
teste("anos: ticks em todos os anos de 2015 a 2026, sem ticks menores",
      identical(inf$ax_x$maiores, as.numeric(2015:2026)) && length(inf$ax_x$menores) == 0)
cq2 <- c0; cq2$grafico <- utils::modifyList(cq2$grafico, list(tipo = "linha_pontos", coluna_x = 1))
cq2$quebra <- utils::modifyList(cq2$quebra, list(ativo = TRUE, de = 110000, ate = 440000, ligar_atraves = FALSE))
cq2$eixo_y$mostrar_titulo <- FALSE; cq2$legenda$posicao <- "dentro"
teste("quebra sem ligar pontos: a legenda da parte de cima mostra TODAS as séries (chave vermelha da LATAM)",
      any(grepl("^#D62728", renderiza(plotar(an, cq2)[[1]]))))
pg <- list2env(list(x_ticks_espessura_pt = 2.5, y_ticks_espessura_pt = 0.5, x_linha_espessura_pt = 2,
                    moldura_espessura_pt = 3,
                    x_ticks_cor = "red", x_intervalo = 2, x_primeiro_tick = 2016, x_inicio = 2015, x_fim = 2026))
cpg <- suppressMessages(aplicar_painel(c0, pg))
teste("painel: grossura e cor dos traços (ticks), da linha do eixo e da moldura chegam ao cfg",
      cpg$eixo_x$espessura_ticks_pt == 2.5 && cpg$eixo_y$espessura_ticks_pt == 0.5 && cpg$eixo_x$cor_ticks == "red" &&
      cpg$eixo_x$espessura_linha_pt == 2 && cpg$caixa$espessura_pt == 3)
th <- plotar(an, utils::modifyList(cpg, list(grafico = list(tipo = "linha_pontos", coluna_x = 1))))$theme
teste("painel: a grossura dos traços muda de verdade o gráfico (X = 5x a do Y)",
      isTRUE(all.equal(th$axis.ticks.x.bottom$linewidth / th$axis.ticks.y.left$linewidth, 5)))
teste("painel: intervalo de 2 em 2 a partir de 2016 dá 2016, 2018, ..., 2026",
      identical(attr(plotar(an, utils::modifyList(cpg, list(grafico = list(tipo = "linha_pontos", coluna_x = 1)))),
                     "info")$ax_x$maiores,
                as.numeric(seq(2016, 2026, 2))))
pf <- list2env(list(titulo_grafico_tamanho_pt = 18, x_titulo_tamanho_pt = 14, y_titulo_tamanho_pt = 13,
                    x_numeros_tamanho_pt = 9,
                    y_numeros_tamanho_pt = 8, legenda_texto_tamanho_pt = 7, tamanho_texto_pt = 11,
                    titulo_grafico = "T", rotulos_dados_tamanho_pt = 6))
cpf <- suppressMessages(aplicar_painel(c0, pf))
thf <- plotar(an, utils::modifyList(cpf, list(grafico = list(tipo = "linha_pontos", coluna_x = 1))))$theme
teste("painel: tamanhos separados (título do gráfico, títulos e números dos eixos, legenda) chegam ao gráfico",
      thf$plot.title$size == 18 && thf$axis.title.x.bottom$size == 14 && thf$axis.title.y.left$size == 13 &&
      thf$axis.text.x.bottom$size == 9 && thf$axis.text.y.left$size == 8 && thf$legend.text$size == 7 &&
      cpf$linhas$rotulos_tamanho_pt == 6 && cpf$barras$rotulos_tamanho_pt == 6)
teste("painel: painel_de_ajustes.R não tem variável sem destino (toda variável do painel existe no mapa)",
      { arq_painel <- if (file.exists("painel_de_ajustes.R")) "painel_de_ajustes.R" else "graficos_R_completo.R"
        L <- readLines(arq_painel, encoding = "UTF-8")
        L <- L[(grep("PAINEL DE AJUSTES DO GRÁFICO", L)[1]):(grep("EXECUÇÃO \\(não precisa editar\\)", L)[1])]
        v <- sub(" *<- .*", "", grep("^[a-z_A-Z]+ +<- ", L, value = TRUE))
        extras <- c("ARQUIVO_CSV", "cores_personalizadas", "cores_gradiente", "cores_por_serie", "quebra_ativar",
                    "x_intervalo",
                    "y_intervalo", "x_ticks_manuais", "y_ticks_manuais", "eixos_titulo_negrito", "rotulos_dados_tamanho_pt")
        all(v %in% c(names(.PAINEL_MAPA), extras)) })
teste("painel: cores_por_serie sem nomes dá erro claro",
      da_erro(aplicar_painel(c0, list2env(list(cores_por_serie = c("#000000", "#FF0000")))), "nomes"))

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
