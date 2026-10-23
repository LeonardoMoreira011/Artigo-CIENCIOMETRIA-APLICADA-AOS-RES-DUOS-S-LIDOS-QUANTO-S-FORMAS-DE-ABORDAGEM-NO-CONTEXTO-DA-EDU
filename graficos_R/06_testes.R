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
      ys_parte(attr(gb, "partes")[[1]])[1] >= sug$ate && ys_parte(attr(gb, "partes")[[2]])[2] <= sug$de)
teste("quebra: as duas partes compartilham o mesmo eixo X", identical(lim_x(attr(gb, "partes")[[1]]),
                                                                      lim_x(attr(gb, "partes")[[2]])))
cq$quebra$ligar_atraves <- TRUE; gb <- plotar(gq, cq)
teste("quebra com ligar_atraves = TRUE (padrão) mantém todos os pontos nas duas partes",
      ys_parte(attr(gb, "partes")[[1]])[1] < sug$de && ys_parte(attr(gb, "partes")[[2]])[2] > sug$ate)

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
dp <- data.frame(T = c(10, 20, 30, 40), Media = c(1, 2.5, 3, 5), DP = c(0.3, 0.5, 0.2, 0.8), Media2 = c(2, 3, 4, 4.5), DP2 = c(0.1, 0.2, 0.3, 0.4))
pee <- list2env(list(tipo_grafico = "pontos", coluna_x = 1, erro_por_serie = c(Media = "DP", Media2 = "DP2"), erro_lado = "superior", erro_espessura_pt = 2))
ce <- suppressMessages(aplicar_painel(c0, pee, dados = dp))
ge <- suppressWarnings(plotar(dp, ce))
camadas_erro <- Filter(function(l) inherits(l$geom, "GeomErrorbar"), ge$layers)
teste("painel: erro_por_serie liga a barra de erro (coluna de erro não vira série) e erro_lado/espessura chegam ao cfg",
      identical(ce$series$Media$coluna_erro, "DP") && identical(ce$linhas$erro_lado, "superior") && ce$linhas$erro_espessura_pt == 2 &&
      length(camadas_erro) == 1 && nrow(camadas_erro[[1]]$data) == 8 && identical(sort(unique(as.character(camadas_erro[[1]]$data$serie))), c("Media", "Media2")))
teste("painel: erro_por_serie sem nomes dá erro claro", da_erro(aplicar_painel(c0, list2env(list(erro_por_serie = "DP"))), "nomes"))
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
teste("quebra sem ligar pontos: a legenda da parte de cima mostra TODAS as séries (chave petróleo (2ª cor da paleta) da LATAM)",
      any(grepl("^#2F6670", renderiza(attr(plotar(an, cq2), "partes")[[1]]))))
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
        extras <- c("ARQUIVO_CSV", "ajustes", "marcas_estatisticas", "caixas_estatisticas", "formas", "imagens", "cores_personalizadas", "cores_gradiente", "cores_por_serie", "erro_por_serie", "quebra_ativar",
                    "x_intervalo",
                    "y_intervalo", "x_ticks_manuais", "y_ticks_manuais", "eixos_titulo_negrito", "rotulos_dados_tamanho_pt",
                    "y2_series", "y2_titulo", "y2_inicio", "y2_fim", "y2_intervalo", "y2_ticks_manuais", "y2_ticks_menores",
                    "y2_cor", "y2_cor_eixo", "y2_dividir_por", "y2_casas_decimais", "y2_notacao", "y2_prefixo", "y2_sufixo",
                    "y2_fator", "y2_deslocamento", "linha_espessura_por_serie", "simbolo_tamanho_por_serie",
                    "simbolo_borda_por_serie", "y2_igual_y1", "y2_legenda_sufixo", "legenda_canto", "fonte_pasta", "simbolo_forma_por_serie", "legenda_nomes", "idioma")
        all(v %in% c(names(.PAINEL_MAPA), extras)) })
teste("painel: cores_por_serie sem nomes dá erro claro",
      da_erro(aplicar_painel(c0, list2env(list(cores_por_serie = c("#000000", "#FF0000")))), "nomes"))

cat("\n--- Quebra de eixo contínua ---\n")
qd <- data.frame(x = 1:20, y = c(seq(10, 100, length.out = 10), seq(5000, 5900, length.out = 10)))
cqc <- c0; cqc$grafico <- utils::modifyList(cqc$grafico, list(tipo = "linha", coluna_x = 1, colunas_y = "y"))
cqc$legenda$mostrar <- FALSE; cqc$eixo_y$mostrar_titulo <- FALSE; cqc$caixa$ticks_espelhados <- FALSE
cqc$eixo_x$n_menores <- 0; cqc$eixo_y$n_menores <- 0
cqc$quebra <- utils::modifyList(cqc$quebra, list(ativo = TRUE, de = 1000, ate = 4800, proporcao_superior = 0.5))
linhas_cheias <- function(g) {                       # quantas linhas horizontais atravessam a figura (grupos de linhas de pixels)
  px <- renderiza(g); esc <- grDevices::col2rgb(px)[1, ] < 200
  fr <- rowSums(matrix(esc, nrow = nrow(px)) ) / ncol(px)
  cheias <- fr > 0.45
  sum(cheias & !c(FALSE, head(cheias, -1)))
}
cqs <- cqc; cqs$quebra$estilo <- "separado"; cqn <- cqc; cqn$quebra$estilo <- "continuo"
teste("quebra estilo 'continuo' monta o gráfico e imprime sem erro",
      inherits(plotar(qd, cqn), "gg") && is.matrix(renderiza(plotar(qd, cqn))))
teste("quebra contínua: NÃO há linha horizontal entre as duas partes (só topo e base); separada tem as linhas do meio",
      linhas_cheias(plotar(qd, cqn)) == 2 && linhas_cheias(plotar(qd, cqs)) >= 3)
teste("quebra estilo inválido dá erro claro com as opções",
      da_erro(plotar(qd, utils::modifyList(cqn, list(quebra = list(estilo = "colado")))), "continuo"))
cqd <- cqn; cqd$legenda <- utils::modifyList(cqd$legenda, list(mostrar = TRUE, posicao = "direita"))
teste("quebra contínua com legenda fora (direita) também monta e imprime", is.matrix(renderiza(plotar(qd, cqd))))
cqt <- cqn; cqt$exportacao$fundo_transparente <- TRUE
teste("quebra contínua respeita fundo transparente (canto da figura transparente)",
      grDevices::col2rgb({ cap <- ragg::agg_capture(width = 300, height = 220, res = 72, background = "transparent")
                           suppressWarnings(print(.fundo_transparente(plotar(qd, cqt)))); r <- cap()
                           invisible(grDevices::dev.off()); r[1, 1] },
                         alpha = TRUE)[4] == 0)

cat("\n--- Grossura separada de linhas e pontos pelo painel ---\n")
pgr <- list2env(list(tipo_grafico = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "BRAZIL"),
                     linha_espessura_pt = 1, simbolo_tamanho_pt = 4, simbolo_borda_pt = 0.5,
                     linha_espessura_por_serie = c(BRAZIL = 3), simbolo_tamanho_por_serie = c(BRAZIL = 10),
                     simbolo_borda_por_serie = c(BRAZIL = 2)))
cgr <- suppressMessages(aplicar_painel(c0, pgr))
teste("painel: linha, ponto e contorno do ponto são gerais e por série (a série vence o geral)",
      cgr$serie_padrao$linha_espessura_pt == 1 && cgr$serie_padrao$tamanho_simbolo_pt == 4 &&
      cgr$serie_padrao$espessura_borda_pt == 0.5 && cgr$series$BRAZIL$linha_espessura_pt == 3 &&
      cgr$series$BRAZIL$tamanho_simbolo_pt == 10 && cgr$series$BRAZIL$espessura_borda_pt == 2 &&
      is.null(cgr$series$WORLD))
ggr <- suppressWarnings(plotar(an, cgr))
dl <- camada(ggr, "linewidth"); dp <- camada(ggr, "stroke")
teste("painel: no gráfico a linha e o ponto engrossam de forma independente (BRAZIL > WORLD nos dois)",
      !is.null(dl) && !is.null(dp) && length(unique(dl$linewidth)) == 2 && length(unique(dp$size)) == 2 &&
      length(unique(dp$stroke)) == 2 && max(dl$linewidth) / min(dl$linewidth) > 2.9 &&
      max(dp$size) / min(dp$size) > 2.4)
cgr2 <- cgr; cgr2$serie_padrao$linha_espessura_pt <- 4
ggr2 <- suppressWarnings(plotar(an, cgr2)); dp2 <- camada(ggr2, "stroke")
teste("painel: mudar só a linha não mexe no ponto",
      identical(sort(unique(dp2$size)),
                sort(unique(dp$size))) && max(camada(ggr2, "linewidth")$linewidth) > max(dl$linewidth) * 0.99)
teste("painel: *_por_serie sem nome ou não numérico dá erro claro",
      da_erro(aplicar_painel(c0, list2env(list(linha_espessura_por_serie = c(1, 2)))), "nome da série") &&
      da_erro(aplicar_painel(c0, list2env(list(simbolo_tamanho_por_serie = c(BRAZIL = "grande")))), "nome da série"))

cat("\n--- Quebra de eixo com eixo Y da direita (Y2) ---\n")
aq <- data.frame(Years = 2015:2026, WORLD = c(460, 466, 492, 512, 520, 500, 545, 548, 590, 610, 645, 690) * 1000,
                 BRAZIL = c(10, 11, 12, 13, 15, 16, 17, 18, 19, 21, 22, 23) * 1000,
                 POP = c(1, 1.2, 1.5, 1.6, 2, 2.2, 6, 6.5, 7, 7.4, 7.9, 8.1) * 1000)
pq <- list2env(list(tipo_grafico = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "BRAZIL", "POP"),
                    y2_series = "POP", y2_titulo = "Pop (10^{3})", y2_dividir_por = 1000, y_dividir_por = 1000,
                    quebra_ativar = TRUE, quebra_de = 80000, quebra_ate = 440000, quebra_y2_de = 2500,
                    quebra_y2_ate = 5500, quebra_y_intervalo_inferior = 20000, quebra_y_intervalo_superior = 100000,
                    quebra_y2_intervalo_inferior = 1000, quebra_y2_intervalo_superior = 1000))
cq2 <- suppressMessages(aplicar_painel(c0, pq, dados = aq))
teste("painel: quebra do Y2 e intervalos por parte chegam ao cfg$quebra",
      cq2$quebra$y2_de == 2500 && cq2$quebra$y2_ate == 5500 && cq2$quebra$incremento_inferior == 20000 &&
      cq2$quebra$incremento_superior == 1e5 && cq2$quebra$y2_incremento_inferior == 1000 &&
      cq2$quebra$y2_incremento_superior == 1000)
for (est in c("separado", "continuo")) {
  ce <- cq2; ce$quebra$estilo <- est
  teste(paste0("quebra + Y2 (", est, "): monta e desenha sem erro nem aviso"),
        { g <- plotar(aq, ce); length(avisos_de(imprime(g))) == 0 })
}
teste("quebra + Y2: mudar y2_de muda o desenho (o eixo da direita tem quebra própria)",
      { cb <- cq2; cb$quebra$y2_de <- 1500; !identical(renderiza(plotar(aq, cq2)), renderiza(plotar(aq, cb))) })
teste("quebra + Y2: sem y2_de/y2_ate o Y2 acompanha a posição do trecho omitido do Y1",
      { cs <- cq2; cs$quebra$y2_de <- NULL; cs$quebra$y2_ate <- NULL
        inherits(suppressWarnings(plotar(aq, cs)),
                 "gg") && isTRUE(attr(suppressWarnings(plotar(aq, cs)), "quebra_gtable")) })
teste("quebra + Y2: a divisa do Y2 derivada do Y1 cai em números redondos (sem 0.373714286 no eixo)",
      { cs <- cq2; cs$quebra$y2_de <- NULL; cs$quebra$y2_ate <- NULL; cs$quebra$de <- 83000; cs$quebra$ate <- 437000
        pt <- attr(suppressWarnings(plotar(aq, cs)), "partes")
        l1 <- attr(pt[[2]], "info")$y2$ax$limites; l2 <- attr(pt[[1]], "info")$y2$ax$limites
        signif(l1[2], 2) == l1[2] && signif(l2[1], 2) == l2[1] && l1[2] < l2[1] })
teste("quebra + Y2: y2_de >= y2_ate ou trecho fora do eixo direito (ex.: valores do Y1 digitados no Y2) viram AVISO e usam a posição do eixo esquerdo",
      { cb <- cq2; cb$quebra$y2_de <- 6000; cb$quebra$y2_ate <- 5000
        cf <- cq2; cf$quebra$y2_de <- 100000; cf$quebra$y2_ate <- 2500000
        ok_b <- da_aviso(g1 <- plotar(aq, cb), "não cabe no eixo direito"); ok_f <- da_aviso(g2 <- plotar(aq, cf), "valores DESTE eixo")
        ok_b && ok_f && isTRUE(attr(suppressWarnings(plotar(aq, cf)), "quebra_gtable")) &&
        identical(renderiza(suppressWarnings(plotar(aq, cf))), renderiza(suppressWarnings({ cs <- cq2; cs$quebra$y2_de <- NULL; cs$quebra$y2_ate <- NULL; plotar(aq, cs) }))) })
cr <- cq2; cr$quebra$ativo <- FALSE
cr$.interno <- list(recortar_y = c(0, 80000), recortar_y2 = c(500, 2500))
gr <- suppressWarnings(plotar(aq, cr))
dr <- camada(gr, "stroke")
teste("quebra + Y2 sem ligar: cada série só mostra os pontos da faixa da sua parte (Y1 e Y2 com faixas próprias)",
      { b <- ggplot2::ggplot_build(gr)$data
        sum(vapply(b, function(d) if ("stroke" %in% names(d)) nrow(d) else 0L, 1L)) == 18 })   # BRAZIL 12 + POP 6
cl <- suppressMessages(aplicar_painel(c0, list2env(list(y2_series = "POP", y2_legenda_sufixo = " (eixo dir.)",
                                                        y2_igual_y1 = TRUE, y_titulo = "Valor (10^{3})"))))
teste("painel Y2: y2_igual_y1 copia título e cor do Y1; sufixo na legenda única só nas séries do Y2",
      cl$eixo_y2$titulo == "Valor (10^{3})" && cl$eixo_y2$cor_eixo == "black" &&
      cl$series$POP$nome_legenda == "POP (eixo dir.)")
teste("painel Y2: aplicar o painel várias vezes no mesmo cfg não repete o sufixo da legenda",
      { pr <- list2env(list(y2_series = "POP", y2_legenda_sufixo = " (eixo dir.)"))
        c1 <- suppressMessages(aplicar_painel(c0, pr)); c2 <- suppressMessages(aplicar_painel(c1, pr))
        c3 <- suppressMessages(aplicar_painel(c2, pr))
        c3$series$POP$nome_legenda == "POP (eixo dir.)" && identical(c2$series, c3$series) })
cl$grafico <- utils::modifyList(cl$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "POP")))
gl <- suppressWarnings(plotar(aq, cl))
teste("painel Y2: a legenda é uma só, com as séries dos dois eixos",
      identical(as.character(unlist(ggplot2::get_guide_data(ggplot2::ggplot_build(gl), "colour")$.label)),
                c("WORLD", "POP (eixo dir.)")))

cat("\n--- Fonte registrada a partir de arquivos .ttf ---\n")
ttf <- systemfonts::system_fonts()$path; ttf <- ttf[grepl("\\.ttf$", ttf, ignore.case = TRUE) & file.exists(ttf)][1]
pf <- file.path(tmp, "fonte_teste"); dir.create(pf)
file.copy(ttf, file.path(pf, c("FonteTeste-Regular.ttf", "FonteTeste-Bold.ttf", "FonteTeste-Italic.ttf",
                               "FonteTesteCondensed-Regular.ttf")))
teste("fonte: sem registrar, a fonte é desconhecida e cai em 'sans' com aviso",
      da_aviso(.fonte("Fonte Teste"), "não encontrada"))
teste("fonte: registrar_fonte() acha os .ttf da pasta (a família 'Condensed' não entra) e passa a valer sem aviso",
      { suppressMessages(registrar_fonte("Fonte Teste", pf))
        r <- systemfonts::registry_fonts(); r <- r[r$family == "Fonte Teste", ]
        length(avisos_de(.fonte("Fonte Teste"))) == 0 && identical(.fonte("Fonte Teste"), "Fonte Teste") &&
        "Fonte Teste" %in% .familias_fontes() && nrow(r) >= 1 && !any(grepl("Condensed", r$path)) })
teste("fonte: o painel (fonte + fonte_pasta) registra e o gráfico desenha sem aviso de fonte",
      { pfn <- list2env(list(fonte = "Fonte Teste", fonte_pasta = pf))
        cf <- suppressMessages(aplicar_painel(c0, pfn))
        cf$grafico <- utils::modifyList(cf$grafico, list(tipo = "linha_pontos", coluna_x = 1,
                                                         colunas_y = c("WORLD", "BRAZIL")))
        cf$texto$fonte == "Fonte Teste" && !any(grepl("fonte", avisos_de(imprime(plotar(aq, cf))),
                                                      ignore.case = TRUE)) })
teste("fonte: pasta inexistente ou sem o Regular dão erro claro; fonte_pasta sem fonte também",
      da_erro(registrar_fonte("Fonte Teste", file.path(tmp, "nao_existe")), "não existe") &&
      da_erro(registrar_fonte("Outra", pf), "Regular") &&
      da_erro(aplicar_painel(c0, list2env(list(fonte_pasta = pf))), "precisa de 'fonte'"))

cat("\n--- Símbolos (formas, esfera), legenda que cabe, distâncias e tamanho fixo da caixa ---\n")
teste("símbolos: o nome vira o código do R e um nome inválido dá erro claro",
      .simbolo_codigo("quadrado") == 22 && .simbolo_codigo(24) == 24 && .simbolo_codigo("esfera") == .COD_ESFERA &&
      da_erro(.simbolo_codigo("hexagono"), "quadrado"))
ss <- c0; ss$grafico <- utils::modifyList(ss$grafico, list(tipo = "linha_pontos", coluna_x = 1,
                                                           colunas_y = c("WORLD", "BRAZIL", "POP")))
ps1 <- suppressMessages(aplicar_painel(ss, list2env(list(simbolo_forma = "quadrado"))))
teste("painel símbolos: simbolo_forma = 'quadrado' deixa TODAS as séries quadradas (desliga a troca de formas)",
      !ps1$cores$incrementar_simbolo && all(vapply(.estilos(ps1, c("WORLD", "BRAZIL", "POP")), function(e) e$simbolo,
                                                   0) == 22))
ps2 <- suppressMessages(aplicar_painel(ss, list2env(list(simbolos_ordem = c("quadrado", "circulo")))))
teste("painel símbolos: simbolos_ordem se repete na ordem pedida",
      identical(unname(vapply(.estilos(ps2, c("WORLD", "BRAZIL", "POP")), function(e) e$simbolo, 0)), c(22, 21, 22)))
ps3 <- suppressMessages(aplicar_painel(ss,
                                       list2env(list(simbolo_forma_por_serie = c(WORLD = "esfera", POP = "quadrado"),
                                                         simbolo_tamanho_pt = 9))))
teste("painel símbolos: forma por série (esfera / quadrado) e nome inválido",
      ps3$series$WORLD$simbolo == "esfera" && ps3$series$POP$simbolo == "quadrado" &&
      da_erro(aplicar_painel(ss, list2env(list(simbolo_forma_por_serie = c(WORLD = "hexagono")))), "hexagono") &&
      da_erro(aplicar_painel(ss, list2env(list(simbolo_forma = "hexagono"))), "hexagono"))
gs3 <- suppressWarnings(plotar(aq, ps3))
teste("esfera: vira uma camada própria (GeomEsfera), imprime sem aviso e a legenda tem a esfera",
      any(vapply(gs3$layers, function(l) inherits(l$geom, "GeomEsfera"), NA)) && length(avisos_de(imprime(gs3))) == 0 &&
      !identical(renderiza(gs3), renderiza(suppressWarnings(plotar(aq, ps1)))))
ps4 <- ps3; ps4$series$POP <- NULL; ps4$series$BRAZIL <- list(simbolo = "esfera"); ps4$series$WORLD <- list(simbolo = "esfera")
ps4$grafico$colunas_y <- c("WORLD", "BRAZIL")
teste("esfera: todas as séries esfera também imprime sem aviso (sem camada de pontos comuns)",
      length(avisos_de(imprime(plotar(aq, ps4)))) == 0)
teste("esfera: o brilho muda de lado com esfera_luz",
      !identical(renderiza(plotar(aq, utils::modifyList(ps4, list(serie_padrao = list(esfera_luz = c(0.5, 0.6)))))),
                 renderiza(plotar(aq, ps4))))
# legenda: escala, distância e caber na caixa
cle <- ss; cle$grafico$colunas_y <- c("WORLD",
                                      "BRAZIL"); cle$legenda <- utils::modifyList(cle$legenda, list(n_colunas = 2, tamanho_texto_pt = 40))
cle$exportacao$largura <- 9; cle$exportacao$altura <- 7; cle$caixa$painel_fixo <- FALSE   # página fixa: a medida vem da página
m_leg <- function(c1) { r <- suppressMessages(.medir_legenda(plotar(aq, c1), .tamanho_pagina_in(c1))); r }
cle_n <- cle; cle_n$legenda$ajustar_caixa <- FALSE
msgs_de <- function(expr) {                       # mensagens (message()) emitidas ao avaliar expr
  m <- character(0)
  withCallingHandlers(force(expr), message = function(x) { m <<- c(m,
                                                                   conditionMessage(x)); invokeRestart("muffleMessage") })
  m
}
teste("legenda: sem ajuste ela passa da caixa; com ajuste (padrão) cabe, e dá uma mensagem avisando",
      { mn <- m_leg(cle_n); mj <- m_leg(cle)
        mn$legenda[1] > mn$painel[1] && mj$legenda[1] <= mj$painel[1] * 0.99 && mj$legenda[2] <= mj$painel[2] &&
        any(grepl("Legenda reduzida", msgs_de(plotar(aq, cle)))) })
cle2 <- cle; cle2$legenda$tamanho_texto_pt <- 9
teste("legenda: escala maior/menor aumenta/diminui o tamanho; legenda pequena não é mexida pelo ajuste",
      { a <- m_leg(cle2)$legenda; cb <- cle2; cb$legenda$escala <- 0.5; b <- m_leg(cb)$legenda
        cc <- cle2; cc$legenda$escala <- 1.4; c <- m_leg(cc)$legenda
        b[1] < a[1] && c[1] > a[1] && !any(grepl("Legenda reduzida", msgs_de(plotar(aq, cle2)))) })
cld <- cle2; cld$legenda <- utils::modifyList(cld$legenda, list(dentro_x = 1, dentro_y = 0, distancia_pt = c(20, 10)))
teste("legenda: distancia_pt vira margem para dentro a partir do canto (inferior direito: direita e baixo)",
      { mg <- .tema_legenda(cld,
                            "sans")$legend.box.margin; all(as.numeric(mg)[c(2, 3)] > 0) && all(as.numeric(mg)[c(1, 4)] == 0) &&
        da_erro(plotar(aq, utils::modifyList(cld, list(legenda = list(distancia_pt = -3)))), "distancia_pt") &&
        da_erro(plotar(aq, utils::modifyList(cld, list(legenda = list(escala = 0)))), "escala") })
# painel: novas variáveis chegam ao cfg
pn <- suppressMessages(aplicar_painel(c0, list2env(list(legenda_escala = 0.8, legenda_distancia_pt = 8,
                                                        legenda_canto = "sup_dir",
                                                         painel_largura_cm = 9, painel_altura_cm = 6, ajustar_pagina = FALSE,
                                                         x_distancia_titulo_pt = 9, y_distancia_titulo_pt = 7,
                                                         y2_distancia_titulo_pt = 12, y_distancia_numeros_pt = 5))))
teste("painel: escala/distância da legenda, tamanho fixo da caixa e distâncias dos títulos chegam ao cfg",
      pn$legenda$escala == 0.8 && pn$legenda$distancia_pt == 8 && pn$legenda$dentro_x == 1 && pn$legenda$dentro_y == 1 &&
      pn$caixa$painel_largura_cm == 9 && pn$caixa$painel_altura_cm == 6 && !pn$exportacao$ajustar_pagina &&
      pn$eixo_x$distancia_titulo_pt == 9 && pn$eixo_y$distancia_titulo_pt == 7 && pn$eixo_y2$distancia_titulo_pt == 12 &&
      pn$eixo_y$distancia_rotulos_pt == 5)
# tamanho fixo da caixa
cfx <- c0; cfx$grafico <- utils::modifyList(cfx$grafico, list(tipo = "linha_pontos", coluna_x = 1,
                                                              colunas_y = c("WORLD", "POP")))
cfx$caixa$painel_largura_cm <- 8; cfx$caixa$painel_altura_cm <- 6
cfy <- cfx; cfy$series$POP <- list(eixo = "y2"); cfy$eixo_y2$ativo <- TRUE; cfy$eixo_y2$titulo <- "Pop (10^{3})"
medidas <- function(c1, dd = aq) {
  pr <- .preparar_saida(suppressWarnings(plotar(dd, c1)), c1); gt <- pr$grob
  pan <- gt$layout[gt$layout$name == "panel", ]
  pdf(NULL); on.exit(dev.off())
  list(pw = sum(grid::convertWidth(gt$widths[pan$l[1]:pan$r[1]], "cm", valueOnly = TRUE)),
       ph = sum(grid::convertHeight(gt$heights[sort(unique(pan$t))], "cm", valueOnly = TRUE)),
       larg = pr$larg * 2.54, alt = pr$alt * 2.54)
}
mx <- medidas(cfx); my <- medidas(cfy)
teste("caixa de tamanho fixo: a caixa tem exatamente 8 x 6 cm com ou sem Y2; só a página muda",
      abs(mx$pw - 8) < 1e-6 && abs(mx$ph - 6) < 1e-6 && abs(my$pw - 8) < 1e-6 && abs(my$ph - 6) < 1e-6 &&
      my$larg > mx$larg + 0.3 && mx$larg > 8 && mx$alt > 6)
aqq <- data.frame(Years = 2015:2026, WORLD = c(10, 30, 20, 50, 40, 60, 300, 310, 320, 330, 340, 350),
                  POP = c(1, 1.2, 1.5, 1.6, 2, 2.2, 6, 6.5, 7, 7.4, 7.9, 8.1))
cfq <- cfy; cfq$quebra <- utils::modifyList(cfq$quebra, list(ativo = TRUE, de = 80, ate = 280,
                                                             proporcao_superior = 0.4))
cfq$quebra$y2_de <- 2.5; cfq$quebra$y2_ate <- 5.5; cfq$eixo_y2$fator_divisao <- 1
for (est in c("continuo", "separado")) {
  cq9 <- cfq; cq9$quebra$estilo <- est; mq <- medidas(cq9, aqq)
  teste(paste0("caixa de tamanho fixo também vale na quebra de eixo (", est, "): 8 x 6 cm"),
        abs(mq$pw - 8) < 1e-6 && abs(mq$ph - 6) < 1e-6)
}
teste("caixa de tamanho fixo: salvar() grava a página do tamanho calculado (PNG)",
      { cs <- cfy; cs$exportacao$pasta <- tmp; cs$exportacao$dpi <- 100; cs$exportacao$nome_arquivo <- "fixo"
        suppressMessages(salvar(suppressWarnings(plotar(aq, cs)), cs))
        cap <- readBin(file.path(tmp, "fixo.png"), "raw", 24)
        w <- sum(as.integer(cap[17:20]) * 256^(3:0)); h <- sum(as.integer(cap[21:24]) * 256^(3:0))
        abs(w - my$larg / 2.54 * 100) <= 1 && abs(h - my$alt / 2.54 * 100) <= 1 })
cfp <- cfx; cfp$exportacao$ajustar_pagina <- FALSE; cfp$exportacao$largura <- 6; cfp$exportacao$altura <- 5
teste("caixa de tamanho fixo com página fixa pequena demais avisa que não cabe",
      da_aviso(.preparar_saida(suppressWarnings(plotar(aq, cfp)), cfp), "não cabe"))
teste("caixa de tamanho fixo: valor inválido dá erro claro",
      da_erro(plotar(aq, utils::modifyList(cfx, list(caixa = list(painel_largura_cm = -2)))), "painel_largura_cm"))
# distância do título lateral na quebra
cqd1 <- cfq; cqd1$quebra$estilo <- "continuo"; cqd1$eixo_y$titulo <- "Intensidade"
cqd1$eixo_y2$distancia_titulo_pt <- 4; cqd2 <- cqd1; cqd2$eixo_y$distancia_titulo_pt <- 24
teste("distância do título do Y na quebra: aumentar de 4 para 24 pt alarga a figura em 20 pt",
      abs((medidas(cqd2, aqq)$larg - medidas(cqd1, aqq)$larg) * 72 / 2.54 - 20) < 1)
# intervalo pequeno demais não amontoa os números
ci <- c0; ci$grafico <- utils::modifyList(ci$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD")))
ci$eixo_y$ticks_modo <- "incremento"; ci$eixo_y$incremento <- 5000
teste("intervalo que geraria centenas de traços avisa e usa um intervalo razoável (números não se amontoam)",
      da_aviso(plotar(aq, ci), "gera") && length(attr(suppressWarnings(plotar(aq, ci)), "info")$ax_y$maiores) <= 12)

cat("\n--- Refinos: negrito geral, grossura única, rotação dos títulos, quebra menor, caixa fixa padrão, grade menor ---\n")
dn <- c0; dn$grafico <- utils::modifyList(dn$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "BRAZIL")))
dn$legenda$mostrar <- TRUE; dn$legenda$titulo <- "Séries"
tx_face <- function(g) { t <- ggplot2::ggplot_build(g)$plot$theme; t }
pn1 <- suppressMessages(aplicar_painel(dn, list2env(list(negrito_geral = TRUE))))
gn1 <- suppressWarnings(plotar(aq, pn1)); gn0 <- suppressWarnings(plotar(aq, dn))
teste("negrito_geral: títulos, números, legenda e título da legenda ficam em negrito (e mudam o desenho)",
      { th <- gn1$theme; faces <- c(th$axis.text.x.bottom$face, th$axis.title.x.bottom$face, th$axis.text.y.left$face,
                                    th$legend.text$face, th$legend.title$face)
        all(faces == "bold") && !identical(renderiza(gn1), renderiza(gn0)) })
pn2 <- suppressMessages(aplicar_painel(dn, list2env(list(legenda_negrito = TRUE, y_numeros_negrito = TRUE))))
gn2 <- suppressWarnings(plotar(aq, pn2))
teste("negrito por texto: só a legenda e os números do Y ficam em negrito; o resto não",
      gn2$theme$legend.text$face == "bold" && gn2$theme$axis.text.y.left$face == "bold" &&
      gn2$theme$axis.text.x.bottom$face == "plain" && gn2$theme$legend.title$face == "plain")
# grossura única
pm <- suppressMessages(aplicar_painel(dn, list2env(list(moldura_espessura_pt = 2.5))))
gm <- suppressWarnings(plotar(aq, pm))
teste("moldura mais grossa padroniza traços e linha dos eixos (mesma grossura, sem precisar repetir)",
      all(abs(c(gm$theme$axis.ticks.x.bottom$linewidth, gm$theme$axis.ticks.y.left$linewidth,
                gm$theme$axis.minor.ticks.x.bottom$linewidth, gm$theme$panel.border$linewidth) - .lw(2.5)) < 1e-9))
pm2 <- suppressMessages(aplicar_painel(dn, list2env(list(moldura_espessura_pt = 2.5, x_ticks_espessura_pt = 0.5))))
gm2 <- suppressWarnings(plotar(aq, pm2))
teste("a grossura dada ao eixo vale mais que a da moldura",
      abs(gm2$theme$axis.ticks.x.bottom$linewidth - .lw(0.5)) < 1e-9 && abs(gm2$theme$axis.ticks.y.left$linewidth - .lw(2.5)) < 1e-9)
# rotação dos títulos
pr9 <- suppressMessages(aplicar_painel(dn, list2env(list(y_rotacao_titulo = 0, x_rotacao_titulo = 20))))
gr9 <- suppressWarnings(plotar(aq, pr9))
teste("rotação dos títulos dos eixos: Y na horizontal (0) e X inclinado (20); sem pedir, Y = 90",
      gr9$theme$axis.title.y.left$angle == 0 && gr9$theme$axis.title.x.bottom$angle == 20 &&
      suppressWarnings(plotar(aq, dn))$theme$axis.title.y.left$angle == 90)
teste("rotação do título do Y também na quebra de eixo e no Y2 (largura da figura muda)",
      { cq <- c0; cq$grafico <- utils::modifyList(cq$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "POP")))
        cq$series$POP <- list(eixo = "y2"); cq$eixo_y2$ativo <- TRUE; cq$eixo_y2$titulo <- "Populacao"; cq$eixo_y$titulo <- "Intensidade do sinal"
        cq$quebra <- list(ativo = TRUE, de = 80, ate = 280, estilo = "continuo", y2_de = 2.5, y2_ate = 5.5, proporcao_superior = 0.4)
        cq2r <- cq; cq2r$eixo_y$rotacao_titulo <- 0; cq2r$eixo_y2$rotacao_titulo <- 0
        medidas(cq, aqq)$larg < medidas(cq2r, aqq)$larg - 0.5 })
# marcas da quebra menores por padrão
teste("a barra // da quebra é curta por padrão (2.5 x 3 pt) e configurável pelo painel",
      c0$quebra$marca_largura_pt == 2.5 && c0$quebra$marca_altura_pt == 3 &&
      suppressMessages(aplicar_painel(c0, list2env(list(quebra_marca_largura_pt = 4, quebra_marcas = FALSE))))$quebra$marca_largura_pt == 4)
# caixa fixa por padrão
mp1 <- medidas(c0 |> (function(x) { x$grafico <- utils::modifyList(x$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = "WORLD")); x })(), aq)
teste("caixa fixa por padrão: 10 x 7.5 cm sem pedir nada",
      abs(mp1$pw - 10) < 1e-6 && abs(mp1$ph - 7.5) < 1e-6)
cdist <- c0; cdist$grafico <- utils::modifyList(cdist$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = "WORLD"))
cdist2 <- cdist; cdist2$eixo_y$distancia_rotulos_pt <- 20; cdist2$eixo_x$distancia_rotulos_pt <- 20
m_a <- medidas(cdist, aq); m_b <- medidas(cdist2, aq)
teste("mudar a distância dos números ao eixo move os números; a caixa continua 10 x 7.5 e a página cresce",
      abs(m_b$pw - 10) < 1e-6 && abs(m_b$ph - 7.5) < 1e-6 && m_b$larg > m_a$larg + 0.4 && m_b$alt > m_a$alt + 0.4)
cdist3 <- cdist; cdist3$caixa$painel_fixo <- FALSE
teste("painel_fixo = FALSE volta à página de largura x altura (a caixa ocupa o que sobra)",
      { pr <- .preparar_saida(suppressWarnings(plotar(aq, cdist3)), cdist3); is.null(pr$grob) && abs(pr$larg * 2.54 - 12) < 1e-6 })
teste("pizza e painéis empilhados não ganham caixa fixa por padrão",
      is.null(.painel_cm(utils::modifyList(c0, list(grafico = list(tipo = "pizza"))))) &&
      is.null(.painel_cm(utils::modifyList(c0, list(paineis = list(ativo = TRUE))))))
# grade nos traços grandes e nos pequenos
cg <- cdist; cg$eixo_x$n_menores <- 1; cg$eixo_y$n_menores <- 1
cg$grade <- utils::modifyList(cg$grade, list(maior_x = FALSE, maior_y = FALSE, menor_x = FALSE, menor_y = FALSE))
gg0 <- renderiza(suppressWarnings(plotar(aq, cg)))
cgM <- cg; cgM$grade$maior_x <- TRUE; cgm <- cg; cgm$grade$menor_x <- TRUE
cgM$grade$cor_maior <- "#FF0000"; cgm$grade$cor_menor <- "#0000FF"; cgM$grade$opacidade_maior <- 1; cgm$grade$opacidade_menor <- 1
cgM$grade$espessura_maior_pt <- 3; cgm$grade$espessura_menor_pt <- 3
ggM <- renderiza(suppressWarnings(plotar(aq, cgM))); ggm <- renderiza(suppressWarnings(plotar(aq, cgm)))
tem_cor <- function(img, canal) { m <- grDevices::col2rgb(unique(as.vector(img))); o <- setdiff(1:3, canal)
                                  any(m[canal, ] > 200 & m[o[1], ] < 90 & m[o[2], ] < 90) }
teste("grade pode ser ligada nos traços grandes e nos pequenos, cada uma com a sua cor",
      tem_cor(ggM, 1) && !tem_cor(ggM, 3) && tem_cor(ggm, 3) && !tem_cor(ggm, 1) && !tem_cor(gg0, 1) && !tem_cor(gg0, 3))

cat("\n--- Legenda: largura manual, espaço símbolo-texto e símbolos que seguem a escala ---\n")
clw <- cle2; clw$legenda$ajustar_caixa <- FALSE
wid <- function(c1) m_leg(c1)$legenda[1]
w0 <- wid(clw)
cg1 <- clw; cg1$legenda$espaco_chave_texto_pt <- 0; cg2 <- clw; cg2$legenda$espaco_chave_texto_pt <- 30
teste("espaço entre símbolo e texto: menor deixa a legenda mais estreita, maior alarga",
      wid(cg1) < w0 && wid(cg2) > w0 && wid(cg2) - wid(cg1) > 25)
cw1 <- clw; cw1$legenda$largura_chave_pt <- 6; cw2 <- clw; cw2$legenda$largura_chave_pt <- 40
teste("largura do espaço do símbolo muda a largura da legenda", wid(cw1) < w0 && wid(cw2) > w0)
for (alvo in c(60, 130)) {
  cm1 <- clw; cm1$legenda$largura_pt <- alvo
  teste(paste0("largura manual da legenda = ", alvo, " pt (a caixa fica com essa largura)"), abs(wid(cm1) - alvo) < 1.5)
}
teste("largura manual maior que a caixa avisa; sem pedir largura nada avisa",
      da_aviso(plotar(aq, utils::modifyList(clw, list(legenda = list(largura_pt = 5000)))), "maior que a caixa") &&
      !any(grepl("maior que a caixa", avisas <- avisos_de(plotar(aq, clw)))))
teste("largura manual inválida dá erro claro", da_erro(plotar(aq, utils::modifyList(clw, list(legenda = list(largura_pt = -3)))), "largura_pt"))
# chaves seguem a escala
env_t <- new.env(); env_t$v <- 0.5; visto <- NULL
chave_t <- .key_escala(function(data, params, size) { visto <<- data; grid::nullGrob() }, list(.interno = list(esc_leg = env_t)))
chave_t(data.frame(size = 4, stroke = 1, linewidth = 2), list(), 10)
teste("a chave da legenda escala símbolo, contorno e linha pela escala da caixa (0.5 -> metade)",
      visto$size == 2 && visto$stroke == 0.5 && visto$linewidth == 1)
cs <- clw; cs$legenda$escala <- 0.5
teste("legenda com escala 0.5 monta e o painel usa só as chaves escaladas (imprime sem aviso)", length(avisos_de(imprime(plotar(aq, cs)))) == 0)
pw <- suppressMessages(aplicar_painel(c0, list2env(list(legenda_largura_pt = 120, legenda_espaco_texto_pt = 2, legenda_largura_chave_pt = 12))))
teste("painel: largura da legenda, espaço símbolo-texto e largura do símbolo chegam ao cfg",
      pw$legenda$largura_pt == 120 && pw$legenda$espaco_chave_texto_pt == 2 && pw$legenda$largura_chave_pt == 12)

cat("\n--- Legenda: posição por coordenadas e geometria para arrastar ---\n")
cco <- clw; cco$grafico <- utils::modifyList(cco$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "BRAZIL")))
cco$eixo_x$inicio <- 2015; cco$eixo_x$fim <- 2026; cco$eixo_x$margem_percentual <- 0; cco$eixo_y$inicio <- 0; cco$eixo_y$fim <- 800000
cco$eixo_y$margem_percentual <- 0; cco$legenda <- utils::modifyList(cco$legenda, list(x_dados = 2020, y_dados = 400000, titulo = NULL))
icoo <- attr(suppressWarnings(plotar(aq, cco)), "info")
cc2 <- .legenda_por_coordenadas(cco, icoo)$legenda
teste("legenda por coordenadas: (x=2020, y=400000) vira fração do painel e o canto superior esquerdo é a âncora",
      abs(cc2$dentro_x - (2020 - 2015) / 11) < 1e-9 && abs(cc2$dentro_y - 0.5) < 1e-9 && identical(cc2$ancora, c(0, 1)))
teste("legenda por coordenadas fora do eixo avisa e vai para a borda; eixo de categorias dá erro claro",
      da_aviso(plotar(aq, utils::modifyList(cco, list(legenda = list(x_dados = 2100)))), "fora do eixo") &&
      da_erro(plotar(data.frame(Cat = c("a", "b"), V = 1:2), { cb <- c0; cb$grafico <- utils::modifyList(cb$grafico, list(tipo = "barras", coluna_x = 1,
              colunas_y = "V")); cb$legenda <- utils::modifyList(cb$legenda, list(mostrar = TRUE, x_dados = 1)); cb }), "categorias"))
# geometria prevista x desenho real (legenda com moldura vermelha)
cgeo <- cco; cgeo$legenda <- utils::modifyList(cgeo$legenda, list(x_dados = NULL, y_dados = NULL, dentro_x = 0.3, dentro_y = 0.6, ancora = "auto",
                      fundo = "white", moldura = TRUE, cor_moldura = "#FF0000", espessura_moldura_pt = 2, mostrar = TRUE))
cgeo$caixa$painel_fixo <- TRUE; cgeo$exportacao$dpi <- 72
ggeo <- suppressWarnings(plotar(aq, cgeo)); geo <- .geometria_legenda(ggeo, cgeo)
teste("geometria da legenda: devolve página, painel e legenda dentro do painel",
      !is.null(geo) && all(geo$legenda[1:2] >= geo$painel[1:2] - 1e-6) &&
      geo$legenda[1] + geo$legenda[3] <= geo$painel[1] + geo$painel[3] + 1e-6 && geo$legenda[2] + geo$legenda[4] <= geo$painel[2] + geo$painel[4] + 1e-6)
teste("geometria da legenda confere com o desenho real (moldura vermelha dentro de 4 px)",
      { pr <- .preparar_saida(ggeo, cgeo); W <- round(pr$larg * 72); H <- round(pr$alt * 72)
        cap <- ragg::agg_capture(width = pr$larg, height = pr$alt, units = "in", res = 72); .desenhar(pr, ggeo); img <- cap(); invisible(grDevices::dev.off())
        m <- grDevices::col2rgb(as.vector(img)); verm <- matrix(m[1, ] > 245 & m[2, ] < 25 & m[3, ] < 25, nrow = nrow(img))
        ys <- which(rowSums(verm) > 0); xs <- which(colSums(verm) > 0)
        esperado <- geo$legenda * c(W, H, W, H)
        abs(min(xs) - esperado[1]) < 4 && abs(max(xs) - (esperado[1] + esperado[3])) < 4 &&
        abs(min(ys) - esperado[2]) < 4 && abs(max(ys) - (esperado[2] + esperado[4])) < 4 })
teste("sem legenda dentro (legenda fora ou oculta) não há geometria",
      is.null(.geometria_legenda(ggeo, utils::modifyList(cgeo, list(legenda = list(posicao = "direita"))))) &&
      is.null(.geometria_legenda(ggeo, utils::modifyList(cgeo, list(legenda = list(mostrar = FALSE))))))
pcd <- suppressMessages(aplicar_painel(c0, list2env(list(legenda_x_dados = 2020, legenda_y_dados = 5e5))))
teste("painel: legenda_x_dados e legenda_y_dados chegam ao cfg", pcd$legenda$x_dados == 2020 && pcd$legenda$y_dados == 5e5)

cat("\n--- Legenda: posição, fundo, borda e sombra ---\n")
pl <- list2env(list(tipo_grafico = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "BRAZIL"),
                    legenda_canto = "inf_dir", legenda_fundo = "#EEEEEE", legenda_fundo_opacidade = 0.8,
                    legenda_borda_cor = "#1F4E9E", legenda_borda_espessura_pt = 1.5, legenda_borda_tipo = "dashed",
                    legenda_sombra_cor = "grey30", legenda_sombra_deslocamento_pt = c(4, 3)))
cl2 <- suppressMessages(aplicar_painel(c0, pl))
teste("painel legenda: canto vira posição + âncora; só dar cor/tipo liga a borda e a sombra",
      cl2$legenda$posicao == "dentro" && identical(cl2$legenda$ancora, c(1, 0)) && cl2$legenda$dentro_x == 0.97 &&
      cl2$legenda$dentro_y == 0.03 && isTRUE(cl2$legenda$moldura) && isTRUE(cl2$legenda$sombra) &&
      cl2$legenda$fundo == "#EEEEEE" && cl2$legenda$fundo_opacidade == 0.8 && cl2$legenda$tipo_moldura == "dashed" &&
      cl2$legenda$cor_moldura == "#1F4E9E" && identical(cl2$legenda$sombra_deslocamento_pt, c(4, 3)))
teste("painel legenda: legenda_x/legenda_y explícitos vencem o canto; borda FALSE explícita é respeitada",
      { c3 <- suppressMessages(aplicar_painel(c0, list2env(list(legenda_canto = "sup_esq", legenda_x = 0.5,
                                                                  legenda_borda = FALSE, legenda_borda_cor = "red"))))
        c3$legenda$dentro_x == 0.5 && c3$legenda$dentro_y == 0.97 && !c3$legenda$moldura })
cl2$grafico <- utils::modifyList(cl2$grafico, list(tipo = "linha_pontos", coluna_x = 1,
                                                   colunas_y = c("WORLD", "BRAZIL")))
tl <- .tema_legenda(cl2, "sans")
teste("legenda com sombra: o retângulo da legenda é o element_sombra; sem sombra é o element_rect comum",
      inherits(tl$legend.background, "element_sombra") &&
      !inherits(.tema_legenda(utils::modifyList(cl2, list(legenda = list(sombra = FALSE))), "sans")$legend.background,
                "element_sombra"))
r0 <- renderiza(plotar(aq, utils::modifyList(cl2, list(legenda = list(sombra = FALSE, moldura = FALSE)))))
r1 <- renderiza(plotar(aq, cl2))
teste("legenda: sombra e borda mudam o desenho; a sombra não gera aviso",
      !identical(r0, r1) && !any(grepl("rect|element|grob", avisos_de(imprime(plotar(aq, cl2))), ignore.case = TRUE)))
teste("legenda: direção horizontal e posição fora (alinhar) mudam o desenho sem erro",
      { ch <- utils::modifyList(cl2, list(legenda = list(direcao = "horizontal", posicao = "topo",
                                                         alinhar = "esquerda")))
        cv <- utils::modifyList(cl2, list(legenda = list(direcao = "vertical", posicao = "topo", alinhar = "direita")))
        !identical(renderiza(plotar(aq, ch)), renderiza(plotar(aq, cv))) })
teste("legenda: opacidade fora de 0-1 e alinhar incompatível com a posição dão erro claro",
      da_erro(plotar(aq, utils::modifyList(cl2, list(legenda = list(fundo_opacidade = 2)))), "entre 0 e 1") &&
      da_erro(plotar(aq, utils::modifyList(cl2, list(legenda = list(posicao = "direita", alinhar = "esquerda")))),
              "não serve"))

cat("\n--- Y2 ligado fora do painel: y2_* não podem ser ignorados em silêncio ---\n")
cm <- c0; cm$series$POP <- list(eixo = "y2"); cm$eixo_y2$ativo <- TRUE        # Y2 ligado "na mão", sem y2_series
cm1 <- suppressMessages(aplicar_painel(cm, list2env(list(y2_intervalo = 2000, y2_ticks_menores = 0,
                                                         y2_cor = "#C00000"))))
teste("painel Y2: com o Y2 ligado fora do painel (sem y2_series), y2_intervalo e y2_cor valem para as séries do Y2",
      cm1$eixo_y2$ticks_modo == "incremento" && cm1$eixo_y2$incremento == 2000 && cm1$eixo_y2$n_menores == 0 &&
      cm1$series$POP$cor == "#C00000" && cm1$eixo_y2$cor_eixo == "#C00000")
teste("painel Y2: y2_intervalo com o Y2 desligado avisa que foi ignorado (não some em silêncio)",
      da_aviso(aplicar_painel(c0, list2env(list(y2_intervalo = 2000))), "Y2) não está ativo"))
cm$grafico <- utils::modifyList(cm$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "POP")))
teste("painel Y2: o intervalo do Y2 chega aos ticks do eixo direito",
      identical(attr(plotar(aq, suppressMessages(aplicar_painel(cm, list2env(list(y2_intervalo = 2000,
                y2_inicio = 0, y2_fim = 10000))))), "info")$y2$ax$maiores, seq(0, 10000, 2000)))

cat("\n--- Eixo Y da direita (Y2) pelo painel ---\n")
p2 <- list2env(list(y2_series = "LATAM", y2_titulo = "Pop (milhões)", y2_inicio = 0, y2_fim = 100000,
                    y2_intervalo = 20000,
                    y2_ticks_menores = 0, y2_cor = "#C00000", y2_dividir_por = 1, y_dividir_por = 1000))
cy2 <- suppressMessages(aplicar_painel(c0, p2))
cy2$grafico <- utils::modifyList(cy2$grafico, list(tipo = "linha_pontos", coluna_x = 1,
                                                   colunas_y = c("WORLD", "LATAM")))
teste("painel Y2: séries, título, limites, intervalo e cor chegam ao cfg e ligam o eixo direito",
      isTRUE(cy2$eixo_y2$ativo) && cy2$series$LATAM$eixo == "y2" && cy2$eixo_y2$titulo == "Pop (milhões)" &&
      cy2$eixo_y2$inicio == 0 && cy2$eixo_y2$fim == 100000 && cy2$eixo_y2$ticks_modo == "incremento" &&
      cy2$eixo_y2$incremento == 20000 && cy2$eixo_y2$cor_eixo == "#C00000" && cy2$series$LATAM$cor == "#C00000")
gy2 <- plotar(an, cy2); iy2 <- attr(gy2, "info")
teste("painel Y2: o eixo direito tem os ticks pedidos (0, 20000, ..., 100000) e o X continua o mesmo",
      identical(iy2$y2$ax$maiores, seq(0, 100000, 20000)) && length(iy2$y2$ax$menores) == 0 &&
      identical(iy2$ax_x$limites, attr(plotar(an, utils::modifyList(cy2, list(eixo_y2 = list(ativo = FALSE),
                                                                              series = list()))), "info")$ax_x$limites))
teste("painel Y2: divisor próprio (Y esquerdo ÷1000 mostra 460; Y2 com y2_dividir_por = 1 mostra 20000)",
      identical(iy2$ax_y$rotulos(460000), "460") && identical(iy2$y2$ax$rotulos(20000), "20000"))
cy3 <- cy2; cy3$eixo_y2$fator_divisao <- NULL
teste("Y2 sem divisor próprio herda o do eixo Y (comportamento anterior preservado)",
      identical(attr(plotar(an, cy3), "info")$y2$ax$rotulos(20000), "20"))
p3 <- list2env(list(y2_fator = 1.8, y2_deslocamento = 32, y2_titulo = "°F"))
cy4 <- suppressMessages(aplicar_painel(c0,
                                       p3)); cy4$grafico <- utils::modifyList(cy4$grafico, list(tipo = "linha", coluna_x = 1, colunas_y = "BRAZIL"))
teste("painel Y2: só fator e deslocamento = mesmo dado em outra unidade (modo transformado: 0 -> 32)",
      cy4$eixo_y2$modo == "transformado" && attr(plotar(an, cy4), "info")$y2$para2(0) == 32)

cat("\n--- Um CSV só com Y1 e Y2 (células vazias) ---\n")
vz <- an; vz$LATAM[c(4, 5)] <- NA; vz$BRAZIL[c(2, 9)] <- NA
cvz <- c0; cvz$grafico <- utils::modifyList(cvz$grafico, list(tipo = "linha_pontos", coluna_x = 1))
cvz$series[["BRAZIL"]] <- list(eixo = "y2"); cvz$eixo_y2$ativo <- TRUE
imprime2 <- function(g) { ragg::agg_capture(width = 400, height = 300,
                                            res = 72); print(g); invisible(grDevices::dev.off()) }
teste("CSV único com células vazias (Y1 e Y2): imprime sem aviso do ggplot2 ('Removed rows...')",
      !any(grepl("Removed", avisos_de(imprime2(plotar(vz, cvz))))))

cat("\n--- Segunda rodada: Y2 completo, legenda horizontal, paletas, quebra por partes ---\n")
y2p <- list2env(list(y2_series = "POP", y2_ticks_direcao = "fora", y2_ticks_menores_direcao = "ambos", y2_ticks_comprimento_pt = 9,
                     y2_numeros_tamanho_pt = 13, y2_numeros_negrito = TRUE, y2_rotacao_numeros = 30, y2_titulo_tamanho_pt = 15,
                     y2_titulo_negrito = TRUE, y2_titulo_italico = TRUE, y2_ticks_cor = "red", y2_ticks_espessura_pt = 2,
                     y2_primeiro_tick = 0, y2_folga_pct = 8, y2_linha_espessura_pt = 3, y2_mostrar_numeros = TRUE))
cy2n <- suppressMessages(aplicar_painel(c0, y2p, dados = aq))
cy2n$grafico <- utils::modifyList(cy2n$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "POP")))
teste("painel Y2: as opções de aparência chegam ao cfg$eixo_y2", cy2n$eixo_y2$direcao_maiores == "fora" &&
      cy2n$eixo_y2$direcao_menores == "ambos" && cy2n$eixo_y2$comprimento_maiores_pt == 9 && cy2n$eixo_y2$tamanho_rotulos_pt == 13 &&
      isTRUE(cy2n$eixo_y2$negrito_rotulos) && cy2n$eixo_y2$rotacao_rotulos == 30 && cy2n$eixo_y2$tamanho_titulo_pt == 15 &&
      isTRUE(cy2n$eixo_y2$negrito_titulo) && isTRUE(cy2n$eixo_y2$italico_titulo) && cy2n$eixo_y2$cor_ticks == "red" &&
      cy2n$eixo_y2$espessura_ticks_pt == 2 && cy2n$eixo_y2$primeiro_tick == 0 && cy2n$eixo_y2$margem_percentual == 8)
gy2 <- suppressWarnings(plotar(aq, cy2n)); thy2 <- gy2$theme
teste("Y2 completo: números, título, traços e cor do lado direito seguem o eixo_y2 (e o lado esquerdo não muda)",
      thy2$axis.text.y.right$size == 13 && thy2$axis.text.y.right$face == "bold" && thy2$axis.text.y.right$angle == 30 &&
      thy2$axis.title.y.right$size == 15 && thy2$axis.title.y.right$face == "bold.italic" &&
      as.numeric(thy2$axis.ticks.length.y.right) > 0 && thy2$axis.ticks.y.right$colour == "red" &&
      thy2$axis.text.y.left$face == "plain" && as.numeric(thy2$axis.ticks.length.y.left) < 0)
teste("Y2 completo: monta e imprime sem aviso", length(avisos_de(imprime(gy2))) == 0)
cy2h <- suppressMessages(aplicar_painel(c0, list2env(list(y2_series = "POP", y_numeros_tamanho_pt = 11, y_ticks_direcao = "fora")), dados = aq))
cy2h$grafico <- utils::modifyList(cy2h$grafico, list(tipo = "linha_pontos", coluna_x = 1, colunas_y = c("WORLD", "POP")))
thh <- suppressWarnings(plotar(aq, cy2h))$theme
teste("Y2 sem opções próprias herda tamanho e direção dos traços do eixo Y",
      thh$axis.text.y.right$size == 11 && as.numeric(thh$axis.ticks.length.y.right) > 0)
cy2o <- cy2n; cy2o$eixo_y2$mostrar_rotulos <- FALSE
teste("Y2 com mostrar_rotulos = FALSE esconde só os números do eixo direito",
      inherits(suppressWarnings(plotar(aq, cy2o))$theme$axis.text.y.right, "element_blank"))
cy2a <- cy2n; cy2a$eixo_y2$direcao_maiores <- "ambos"; cy2a$eixo_y2$direcao_menores <- "dentro"
teste("Y2 com traços 'ambos' e menores desenha a anotação dos traços do lado direito", {
  g1 <- suppressWarnings(plotar(aq, cy2a)); length(g1$layers) > length(suppressWarnings(plotar(aq, c0))$layers) })
cq3 <- suppressMessages(aplicar_painel(c0, pq, dados = aq)); cq3$quebra$estilo <- "continuo"; cq3$eixo_y2$cor_ticks <- "blue"; cq3$eixo_y2$tamanho_titulo_pt <- 13
teste("quebra + Y2 com aparência própria do Y2 monta e imprime sem aviso", length(avisos_de(imprime(plotar(aq, cq3)))) == 0)

teste("painel Y2: série marcada para o eixo direito entra no gráfico mesmo fora de colunas_y",
      { cc <- suppressMessages(aplicar_painel(c0, list2env(list(colunas_y = c("WORLD", "BRAZIL"), y2_series = "POP")), dados = aq))
        identical(cc$grafico$colunas_y, c("WORLD", "BRAZIL", "POP")) && inherits(suppressWarnings(plotar(aq, utils::modifyList(cc, list(grafico = list(coluna_x = 1))))), "gg") })

cat("--- legenda: orientação, linhas e colunas ---\n")
cgl <- c0; cgl$legenda$direcao <- "horizontal"
cgn <- c0; cgn$legenda$n_colunas <- 2; cgn$legenda$n_linhas <- 1
teste("legenda: horizontal = uma linha; colunas e linhas dados valem; os dois ao mesmo tempo que não cabem aumentam as linhas", {
  pr <- function(cf, n) .guia_legenda(cf, n)$params
  pr(cgl, 4)$nrow == 1 && is.null(pr(c0, 4)$nrow) && pr(cgn, 6)$ncol == 2 && pr(cgn, 6)$nrow == 3 })
cgh <- c0; cgh$legenda$direcao <- "horizontal"; cgh$legenda$n_linhas <- 2; cgh$legenda$ajustar_caixa <- FALSE
cgv <- c0; cgv$legenda$direcao <- "vertical"; cgv$legenda$ajustar_caixa <- FALSE
teste("legenda horizontal em 2 linhas é mais larga e mais baixa que a vertical", {
  gx <- list(grafico = list(tipo = "linha_pontos", coluna_x = 1))
  mh <- .medir_legenda(plotar(aq, utils::modifyList(cgh, gx)), c(6, 5))$legenda
  mv <- .medir_legenda(plotar(aq, utils::modifyList(cgv, gx)), c(6, 5))$legenda
  mh[1] > mv[1] && mh[2] < mv[2] })
pl <- list2env(list(legenda_direcao = "horizontal", legenda_n_linhas = 2, fundo_transparente = TRUE))
cpl <- suppressMessages(aplicar_painel(c0, pl))
teste("painel: legenda_n_linhas e fundo_transparente chegam ao cfg", cpl$legenda$n_linhas == 2 && isTRUE(cpl$exportacao$fundo_transparente))

cat("--- paletas ---\n")
ids_pal <- unlist(.PALETAS_GRUPOS, use.names = FALSE)
teste("paletas: a lista da tela tem 12 paletas e todas existem e entregam n cores válidas (n = 1, 3 e 12)",
      length(ids_pal) == 12 && all(vapply(ids_pal, function(i) all(vapply(c(1, 3, 12), function(n) {
        x <- .paleta(i, n, c0$cores); length(x) == n && !anyNA(x) && is.matrix(grDevices::col2rgb(x)) }, NA)), NA)))
teste("paletas: a padrão 'cinabro' começa pelas 4 cores da marca (vermelho, petróleo, tinta, terracota), tem 10 cores e o painel a aceita",
      identical(.paleta("cinabro", 4, c0$cores), c("#B3262E", "#2F6670", "#20242B", "#C96A4A")) && length(.paleta("cinabro", 10, c0$cores)) == 10 &&
      !anyDuplicated(.paleta("cinabro", 10, c0$cores)) && c0$cores$paleta == "cinabro" &&
      suppressMessages(aplicar_painel(c0, list2env(list(cores_paleta = "brewer_YlOrRd"))))$cores$paleta == "brewer_YlOrRd")
teste("paletas: os degradês vão do claro ao escuro e a 'cinabro' (categórica) fica na ordem da lista", {
  a <- .paleta("brewer_Reds", 5, c0$cores); l <- function(x) sum(grDevices::col2rgb(x)) / 3
  l(a[1]) > l(a[5]) && identical(.paleta("cinabro", 3, c0$cores), c("#B3262E", "#2F6670", "#20242B")) })
teste("paletas retiradas (okabe_ito, marca, tol_*, brewer_Set*, viridis, tableau...) ainda funcionam com um aviso e a paleta mantida mais parecida; 'classico' vale como 'cinabro' sem aviso",
      da_aviso(.paleta("okabe_ito", 3, c0$cores), "foi retirada") && identical(suppressWarnings(.paleta("okabe_ito", 3, c0$cores)), .paleta("cinabro", 3, c0$cores)) &&
      identical(suppressWarnings(.paleta("brewer_Blues", 4, c0$cores)), .paleta("brewer_YlGnBu", 4, c0$cores)) &&
      identical(suppressWarnings(.paleta("viridis", 4, c0$cores)), .paleta("brewer_YlGnBu", 4, c0$cores)) &&
      all(unname(.PALETAS_ANTIGAS) %in% c(ids_pal)) && length(avisos_de(.paleta("classico", 3, c0$cores))) == 0 &&
      identical(.paleta("classico", 4, c0$cores), .paleta("cinabro", 4, c0$cores)))
teste("paleta desconhecida dá erro com a lista de opções", da_erro(.paleta("nao_existe", 3, c0$cores), "Opções:"))
teste("paletas: mostrar_paletas() desenha todas sem erro", { g <- .grafico_paletas(6); inherits(g, "gg") && monta(g) })

cat("--- curva externa, caixas móveis e a regra dos números fora da linha ---\n")
teste("curva externa: pontos colados do Excel (tab/espaço, vírgula decimal), 'x,y; x,y', matriz e vetor viram a mesma matriz ordenada por X",
      identical(.ler_pontos("0\t1,5\n2\t3,5\n1\t2"), matrix(c(0, 1, 2, 1.5, 2, 3.5), ncol = 2)) &&
      identical(.ler_pontos("0,1; 1,2; 2,4"), matrix(c(0, 1, 2, 1, 2, 4), ncol = 2)) &&
      identical(.ler_pontos(matrix(c(2, 1, 4, 2), ncol = 2)), matrix(c(1, 2, 2, 4), ncol = 2)) && is.null(.ler_pontos("a b")) && is.null(.ler_pontos("1 2")))
xx <- 1:12; yy <- 3 * xx + 2 + c(0.5, -0.4, 0.3, -0.2, 0.1, 0, -0.1, 0.2, -0.3, 0.4, -0.5, 0.2)
f1 <- .ajustar(xx, yy, list(tipo = "externa", formula = "3*x + 2"))
teste("curva externa: fórmula pronta (sem letras) não ajusta nada e compara com os dados (R² alto, n = 12, sem parâmetros)",
      f1$ok && f1$n == 12 && is.null(f1$par) && f1$npar == 0 && f1$r2 > 0.99 && abs(f1$pred(2) - 8) < 1e-9 && identical(f1$eq, "y = 3*x + 2"))
f2 <- .ajustar(xx, yy, list(tipo = "externa", formula = "a*x + b", parametros = c(a = 3, b = 2)))
teste("curva externa: fórmula com letras e valores prontos (parametros); a equação sai com os valores no lugar das letras",
      f2$ok && abs(f2$pred(10) - 32) < 1e-9 && grepl("3\\*x \\+ 2", f2$eq) && abs(f2$r2 - f1$r2) < 1e-12)
teste("curva externa: faltou o valor de um parâmetro, ou não deu nem pontos nem fórmula = falha avisada (sem erro que derruba)",
      !.ajustar(xx, yy, list(tipo = "externa", formula = "a*x + b", parametros = c(a = 3)))$ok && !.ajustar(xx, yy, list(tipo = "externa"))$ok)
f3 <- .ajustar(xx, yy, list(tipo = "externa", pontos = "1 5\n6 20\n12 38"))
teste("curva externa: por pontos liga os pontos, fica NA fora do intervalo deles, guarda a faixa de X e dá R² contra os dados",
      f3$ok && is.na(f3$pred(0)) && is.na(f3$pred(13)) && abs(f3$pred(3.5) - 12.5) < 1e-9 && identical(f3$xrange, c(1, 12)) && is.finite(f3$r2) &&
      .ajustar(xx, yy, list(tipo = "externa", pontos = "1 5\n3 9\n6 20\n9 29\n12 38", interpolacao = "suave"))$ok)
dce <- data.frame(t = xx, A = yy, B = yy * 0.5)
cce <- c0; cce$grafico <- utils::modifyList(cce$grafico, list(tipo = "pontos", coluna_x = 1, colunas_y = c("A", "B")))
cce$ajustes <- list(list(tipo = "externa", pontos = "1 5\n6 20\n12 38", cartao = 2), list(tipo = "linear", serie = "B", cartao = 4))
cce$caixas_estatisticas <- list(list(itens = c("equacao", "r2"), ajustes = 4, cartao = 3), list(itens = c("equacao", "r2"), ajustes = 2, cartao = 1))
gce <- plotar(dce, cce); ice <- attr(gce, "info"); fce <- .calcular_ajustes(cce, ice)
teste("curva externa: com serie 'todas' desenha UMA curva só (na 1ª série) e a caixa de estatística escolhe o ajuste pelo NÚMERO DO CARTÃO",
      length(fce) == 2 && identical(vapply(fce, function(f) f$serie, ""), c("A", "B")) &&
      any(grepl("^y = ", .linhas_caixa(cce$caixas_estatisticas[[1]], cce, ice, fce)$linhas)) && !any(grepl("Curva externa", .linhas_caixa(cce$caixas_estatisticas[[1]], cce, ice, fce)$linhas)) &&
      any(grepl("Curva externa", .linhas_caixa(cce$caixas_estatisticas[[2]], cce, ice, fce)$linhas)))
teste("curva externa e a chave 'cartao' são aceitas sem aviso e o gráfico monta e imprime", length(avisos_de(monta(plotar(dce, cce)))) == 0)
gm <- function(rot) { cm <- c0; cm$grafico <- utils::modifyList(cm$grafico, list(tipo = "pontos", coluna_x = 1, colunas_y = "A"))
                      cm$marcas_estatisticas <- list(list(serie = "A", rotulo = rot)); length(plotar(dce, cm)$layers) }
teste("números fora da linha: 'Média ± DP' não escreve o valor ao lado dos traços por padrão (só se rotulo = TRUE)", gm(NULL) == gm(FALSE) && gm(TRUE) > gm(NULL))
png_g <- tempfile(fileext = ".png"); png::writePNG(array(0.5, c(30, 60, 3)), png_g)
cgm <- c0; cgm$grafico <- utils::modifyList(cgm$grafico, list(tipo = "pontos", coluna_x = 1, colunas_y = "A"))
cgm$caixas_estatisticas <- list(list(itens = c("media", "dp"), cartao = 2, tamanho_pt = 9))
cgm$formas <- list(list(tipo = "texto", texto = "Nota", x = 0.4, y = 0.8, cartao = 1),
                   list(tipo = "retangulo", x = 0.5, y = 0.5, largura = 0.2, altura = 0.1, ancora = "sup_esq", cartao = 3),
                   list(tipo = "poligono", vertices = "0.6,0.2; 0.8,0.2; 0.7,0.4", cartao = 4),
                   list(tipo = "retangulo", unidade = "dados", x = 5, y = 20, largura = 2, altura = 5, cartao = 5))
cgm$imagens <- list(list(arquivo = png_g, x = 0.2, y = 0.3, largura = 0.25, cartao = 2))
ggm <- suppressWarnings(plotar(dce, cgm)); gcx <- .geometria_caixas(ggm, cgm)
ids_g <- vapply(gcx$itens, function(i) i$id, "")
teste("caixas móveis: cada caixa em fração do gráfico aparece com id = prefixo + número do cartão (cx2, fm1, fm3, fm4, im2); a em unidades dos eixos fica de fora",
      identical(sort(ids_g), c("cx2", "fm1", "fm3", "fm4", "im2")))
teste("caixas móveis: os retângulos (em fração da página) estão dentro da página, o painel também, e a figura mantém a proporção 2:1",
      all(vapply(gcx$itens, function(i) all(i$rect >= 0) && i$rect[1] + i$rect[3] <= 1 && i$rect[2] + i$rect[4] <= 1, NA)) && gcx$painel[3] > 0.3 &&
      { im <- gcx$itens[[which(ids_g == "im2")]]; pp <- .preparar_saida(ggm, cgm); abs((im$rect[3] * pp$larg) / (im$rect[4] * pp$alt) - 2) < 0.02 })
teste("caixas móveis: tipo, ancora e 'auto' (esticar muda a letra) vêm certos; o polígono traz os vértices; texto e figura são 'auto', retângulo com tamanho não",
      { g1 <- function(id) gcx$itens[[which(ids_g == id)]]
        g1("cx2")$tipo == "estatistica" && g1("cx2")$auto && g1("cx2")$tam == 9 && g1("fm1")$tipo == "texto" && g1("fm1")$auto && !g1("fm3")$auto &&
        g1("fm3")$jx == 0 && g1("fm3")$jy == 1 && length(g1("fm4")$vert) == 3 && g1("im2")$tipo == "figura" && g1("im2")$auto })
teste("caixas móveis: x e y da caixa de texto batem com o desenho (a âncora da caixa fica em x,y do painel)",
      { t1 <- gcx$itens[[which(ids_g == "fm3")]]; pn <- gcx$painel
        abs((t1$rect[1] - pn[1]) / pn[3] - 0.5) < 0.005 && abs((pn[2] + pn[4] - t1$rect[2]) / pn[4] - 0.5) < 0.005 })
cq <- cgm; cq$quebra <- utils::modifyList(cq$quebra, list(ativo = TRUE, de = 14, ate = 30))
teste("caixas móveis: sem caixas, ou com quebra de eixo, devolve NULL (o app só não desenha as molduras)",
      is.null(.geometria_caixas(suppressWarnings(plotar(dce, c0)), c0)) && is.null(.geometria_caixas(suppressWarnings(plotar(dce, cq)), cq)))

cat("--- quebra: traços pequenos por parte ---\n")
cqm <- suppressMessages(aplicar_painel(c0, pq, dados = aq)); cqm$eixo_y2$ativo <- FALSE; cqm$series[["POP"]] <- NULL; cqm$grafico$colunas_y <- c("WORLD", "BRAZIL")
cqm$quebra$y2_de <- NULL; cqm$quebra$y2_ate <- NULL; cqm$quebra$y2_incremento_inferior <- NULL; cqm$quebra$y2_incremento_superior <- NULL
cqm$eixo_y$n_menores <- 1; cqm$quebra$n_menores_inferior <- 4; cqm$quebra$n_menores_superior <- 0
ptm <- attr(suppressWarnings(plotar(aq, cqm)), "partes")
nmen <- function(g) length(attr(g, "info")$ax_y$menores)
teste("quebra: n_menores_inferior / n_menores_superior mudam os traços pequenos de cada parte (e vazio herda o eixo)", {
  cqn <- cqm; cqn$quebra$n_menores_inferior <- NULL; cqn$quebra$n_menores_superior <- NULL
  pn <- attr(suppressWarnings(plotar(aq, cqn)), "partes")
  nmen(ptm[[2]]) > nmen(pn[[2]]) && nmen(ptm[[1]]) == 0 && nmen(pn[[1]]) > 0 })
teste("painel: traços pequenos por parte da quebra (e do Y2) chegam ao cfg$quebra", {
  cp <- suppressMessages(aplicar_painel(c0, list2env(list(quebra_y_ticks_menores_inferior = 3, quebra_y_ticks_menores_superior = 1,
        quebra_y2_ticks_menores_inferior = 2, quebra_y2_ticks_menores_superior = 0))))
  cp$quebra$n_menores_inferior == 3 && cp$quebra$n_menores_superior == 1 && cp$quebra$y2_n_menores_inferior == 2 &&
  cp$quebra$y2_n_menores_superior == 0 })
teste("sugerir_quebra ignora as séries do eixo direito (têm outra escala)", {
  ss <- suppressMessages(aplicar_painel(c0, list2env(list(y2_series = "POP"))))
  ss$grafico <- utils::modifyList(ss$grafico, list(coluna_x = 1))
  dd <- aq; dd$POP <- dd$POP * 1000                       # o eixo direito tem o maior vazio, mas não conta
  r <- NULL; utils::capture.output(r <- sugerir_quebra(dd, ss)); r$de < 100000 && r$ate > 300000 })

cat("\n--- Exportação e estilos ---\n")
c1 <- c0; c1$exportacao$formatos <- c("png", "pdf", "svg", "tiff"); c1$exportacao$nome_arquivo <- "t"
arqs <- salvar(plotar(d, c1), c1)
teste("png/pdf/svg/tiff gravados e não vazios", all(file.exists(arqs)) && all(file.size(arqs) > 1000))
teste("nenhum dispositivo gráfico ficou aberto", is.null(grDevices::dev.list()))
c1 <- c0; c1$texto$tamanho_base_pt <- 14
salvar_estilo(c1, "tmp_teste", pasta = tmp)
teste("todos os estilos embutidos e da pasta estilos/ carregam e a paleta de cada um existe (sem aviso de paleta retirada)",
      all(vapply(listar_estilos(), function(e) { ce <- carregar_estilo(e, c0); length(avisos_de(.paleta(ce$cores$paleta, 3, ce$cores))) == 0 }, NA)))
teste("estilo: salvar e carregar de volta", carregar_estilo("tmp_teste", c0, pasta = tmp)$texto$tamanho_base_pt == 14)

cat("\n--- Ajustes, estatísticas, caixas e formas ---\n")
set.seed(3); xa <- seq(1, 50, length.out = 30)
da <- data.frame(x = xa, A = 2 * xa^0.8 + rnorm(30), B = 500000 + 40000 * log(xa) + rnorm(30, 0, 2e4), C = 10 + 3 * sin(xa / 5) + rnorm(30, 0, 0.4))
ca <- c0; ca$grafico$coluna_x <- "x"; ca$series <- list()
com <- function(...) { x <- ca; a <- list(...); for (n in names(a)) x[[n]] <- a[[n]]; x }
teste("ajuste linear: R², EP e média iguais aos do R (lm, sd)", {
  cv <- com(ajustes = list(list(tipo = "linear")), grafico = utils::modifyList(ca$grafico, list(colunas_y = "A")))
  r <- estatisticas(da, cv); abs(r$ajustes$r2 - summary(lm(A ~ x, da))$r.squared) < 1e-9 && abs(r$descritiva$ep - sd(da$A) / sqrt(30)) < 1e-9 })
teste("ajuste potência e fórmula livre iguais ao nls do R", {
  nl <- nls(A ~ a * x^b, da, start = list(a = 1, b = 1)); g0 <- utils::modifyList(ca$grafico, list(colunas_y = "A"))
  r1 <- estatisticas(da, com(ajustes = list(list(tipo = "potencia")), grafico = g0)); r2 <- estatisticas(da, com(ajustes = list(list(tipo = "formula", formula = "a*x^b")), grafico = g0))
  abs(r1$parametros$estimativa[2] - coef(nl)[2]) < 1e-4 && abs(r2$parametros$estimativa[2] - coef(nl)[2]) < 1e-4 })
teste("ajustes exponencial, logarítmico, polinomial e loess convergem", {
  r <- estatisticas(da, com(ajustes = list(list(serie = "A", tipo = "exponencial"), list(serie = "B", tipo = "logaritmico"), list(serie = "C", tipo = "polinomial", grau = 3), list(serie = "C", tipo = "loess"))))
  nrow(r$ajustes) == 4 && all(r$ajustes$r2 > 0.2) })
teste("fórmula com função não permitida (system) é recusada; fórmula mal escrita e tipo inválido dão erro claro", {
  da_erro(plotar(da, com(ajustes = list(list(tipo = "formula", formula = "system('ls') + a*x")))), "não é permitido") &&
  da_erro(plotar(da, com(ajustes = list(list(tipo = "formula", formula = "a*x^2+")))), "não entendi") &&
  da_erro(plotar(da, com(ajustes = list(list(tipo = "parabola")))), "não é válido") })
teste("chave digitada errada em ajustes/caixas/formas avisa; item de caixa inexistente dá erro", {
  da_aviso(plotar(da, com(ajustes = list(list(tipo = "linear", tipo_linhaa = "x")))), "tipo_linhaa") && da_aviso(plotar(da, com(formas = list(list(tipo = "texto", x = .5, y = .5, textoo = "a")))), "textoo") &&
  da_erro(plotar(da, com(caixas_estatisticas = list(list(itens = "foo")))), "não existe") })
teste("o '$' dos itens é exato (borda_tipo sozinho não liga a borda de uma forma sem querer)", {
  f <- .grob_forma(list(tipo = "texto", x = .5, y = .5, texto = "a", borda_tipo = "dashed"), c0); inherits(f$grob, "grob") })
teste("ANOVA, Tukey, Kruskal, Bartlett, Shapiro e correlações entre séries: valores iguais aos do R", {
  g <- list(A = da$A, B = da$B / 1e4, C = da$C); gx <- list(A = da$x, B = da$x, C = da$x)
  a <- .rodar_teste("anova", g); dd <- data.frame(y = unlist(g), grupo = factor(rep(names(g), each = 30)))
  p0 <- summary(aov(y ~ grupo, dd))[[1]][1, "Pr(>F)"]
  tk <- .rodar_teste("tukey", g); pe <- .rodar_teste("pearson", g, x = gx)
  abs(a$p - p0) < 1e-12 && nrow(tk) == 3 && abs(pe$estatistica[1] - cor(da$x, da$A)) < 1e-9 && .rodar_teste("shapiro", g)$p[1] == shapiro.test(da$A)$p.value &&
  abs(.rodar_teste("kruskal", g)$p - kruskal.test(y ~ grupo, dd)$p.value) < 1e-12 && abs(.rodar_teste("bartlett", g)$p - bartlett.test(y ~ grupo, dd)$p.value) < 1e-12 })
teste("desenha ajustes + marcas + caixas + formas juntos (Y2, escala log, quebra de eixo, barras) sem erro nem aviso", {
  cy <- suppressMessages(aplicar_painel(ca, list2env(list(y2_series = "B", x_escala = "log10",
        ajustes = list(list(serie = "A", tipo = "potencia", banda = TRUE, estender = TRUE), list(serie = "B", tipo = "logaritmico", cor = "red"), list(serie = "C", tipo = "formula", formula = "a + b*sin(x/5)", inicio = c(a = 10, b = 3))),
        marcas_estatisticas = list(list(serie = "B", faixa = "ep", preencher = TRUE), list(serie = "A", eixo = "x", faixa = "minmax", centro = "mediana"), list(serie = "A", modo = "barras_por_x", faixa = "dp")),
        caixas_estatisticas = list(list(itens = c("media", "equacao", "r2_aj", "parametros", "spearman", "ttest", "tukey", "anova"), cantos = "reto", sombra = TRUE, series = c("A", "B"))),
        formas = list(list(tipo = "poligono", vertices = "0.6,0.2; 0.9,0.2; 0.75,0.5", borda_tipo = "dashed", sombra = TRUE), list(tipo = "elipse", x = 10, y = 20, largura = 5, altura = 6, unidade = "dados", fundo = NA),
                      list(tipo = "texto", x = 0.5, y = 0.9, texto = "m^{2} e H_{2}O", fundo = "#FFF3CD"))), parent = emptyenv()), dados = da))
  length(avisos_de(g1 <- plotar(da, cy))) == 0 && monta(g1) })
teste("quebra de eixo: ajuste e caixa só na parte de cima (caixa), curva nas duas", {
  dq <- data.frame(x = 1:20, A = c(1:10, 1001:1010) + c(0.3, -0.2)); cq <- com(quebra = utils::modifyList(ca$quebra, list(ativo = TRUE, de = 100, ate = 900)), ajustes = list(list(tipo = "linear")),
        caixas_estatisticas = list(list(itens = c("media", "r2"))), formas = list(list(tipo = "texto", x = .5, y = .5, texto = "m")))
  pt <- attr(suppressWarnings(plotar(dq, cq)), "partes"); length(pt) == 2 && monta(pt[[1]]) && monta(pt[[2]]) })
teste("barras e pizza aceitam formas (e ignoram ajustes) sem erro", {
  cb <- com(ajustes = list(list(tipo = "linear")), formas = list(list(tipo = "retangulo", x = .5, y = .5))); cb$grafico$tipo <- "barras"
  inherits(suppressWarnings(plotar(da[, c("x", "A")], cb)), "gg") })
teste("painel: ajustes, marcas, caixas e formas chegam ao cfg; variável que não é lista dá erro", {
  cp <- suppressMessages(aplicar_painel(c0, list2env(list(ajustes = list(list(tipo = "linear")), formas = list(list(tipo = "texto", x = .1, y = .1, texto = "a"))))))
  length(cp$ajustes) == 1 && length(cp$formas) == 1 && da_erro(aplicar_painel(c0, list2env(list(ajustes = "linear"))), "lista") })
teste("idioma: o motor é só português (options(cinabro.idioma) é ignorado); o inglês e o espanhol estão arquivados e `idioma <- \"en\"` no painel avisa e usa o português", {
  options(cinabro.idioma = "en"); r <- .re("media"); m <- .traduzir_msg("Cor inválida em "); options(cinabro.idioma = "pt")
  r == "Média" && m == "Cor inválida em " && da_aviso(aplicar_painel(c0, list2env(list(idioma = "en"))), "arquivados") &&
    file.exists(file.path("idiomas_arquivados", "motor", "02_traducoes_motor.R")) })

cat("\n--- Zonas clicáveis dos títulos (app) ---\n")
teste(".geometria_zonas acha título, eixo X e eixo Y (frações da página, dentro de 0 a 1); sem título, uma faixa acima do painel", {
  cz <- c0; cz$titulos$titulo <- "Meu título"; gz <- plotar(d, cz); z <- .geometria_zonas(gz, cz)
  cs <- c0; cs$titulos$titulo <- NULL; z2 <- .geometria_zonas(plotar(d, cs), cs)
  all(c("titulo", "xlab", "ylab") %in% names(z)) && all(vapply(z, function(v) length(v) == 4 && all(v >= 0 & v <= 1), NA)) && z$titulo[2] < z$xlab[2] &&
    z$ylab[1] < z$xlab[1] + 0.5 && !is.null(z2$titulo) && z2$titulo[4] > 0 })
cat("\n--- Figuras anexadas (PNG/JPEG) ---\n")
if (.tem("png") && .tem("jpeg")) {
  fig_a <- array(runif(40 * 80 * 4), c(40, 80, 4)); f_png <- file.path(tmp, "fig.png"); f_jpg <- file.path(tmp, "fig.jpg")
  png::writePNG(fig_a, f_png); jpeg::writeJPEG(fig_a[, , 1:3], f_jpg)
  ci <- c0; ci$grafico$coluna_x <- "x"; ci$series <- list()
  dfi <- data.frame(x = 1:10, y = c(2, 4, 3, 6, 8, 7, 9, 12, 11, 14))
  teste("figura PNG e JPEG: lê com transparência, desenha na frente e atrás dos dados, em fração e em unidades dos eixos, sem aviso", {
    ci$imagens <- list(list(arquivo = f_png, x = .97, y = .97, ancora = "sup_dir", largura = .25, borda_cor = "grey30", opacidade = .8),
                       list(arquivo = f_jpg, x = 7, y = 3, unidade = "dados", largura = 3, altura = 3, camada = "atras", angulo = 15),
                       list(arquivo = f_png, x = .05, y = .05, ancora = "inf_esq", largura = .2, altura = .1))
    length(avisos_de(gi <- plotar(dfi, ci))) == 0 && monta(gi) })
  teste("figura: arquivo ausente, formato não aceito e unidades dos dados sem altura dão erro claro; chave errada avisa", {
    cx <- ci; cx$imagens <- list(list(arquivo = file.path(tmp, "nao_existe.png"))); a <- da_erro(plotar(dfi, cx), "não achei a figura")
    writeLines("x", file.path(tmp, "a.gif")); cx$imagens <- list(list(arquivo = file.path(tmp, "a.gif"))); b <- da_erro(plotar(dfi, cx), "PNG ou JPEG")
    cx$imagens <- list(list(arquivo = f_png, unidade = "dados", largura = 2)); d <- da_erro(plotar(dfi, cx), "largura e altura")
    cx$imagens <- list(list(arquivo = f_png, larg = 1)); e <- da_aviso(plotar(dfi, cx), "larg")
    a && b && d && e })
  teste("figura: a proporção é mantida quando só a largura é dada (mesma imagem 2:1 sai com altura = metade da largura)", {
    im <- .ler_imagem(f_png); abs(im$alt / im$larg - 0.5) < 1e-9 && identical(dim(.raster_imagem(im, 0.5)), c(40L, 80L)) })
  teste("figura: fica em formato leve (nativeRaster: 4 bytes por pixel), a cache guarda no máximo 3 figuras e as cores e a opacidade saem certas", {
    fv <- tempfile(fileext = ".png"); png::writePNG(array(c(rep(1, 16), rep(0, 32)), c(4, 4, 3)), fv)          # 4x4 vermelho puro
    im <- .ler_imagem(fv); r1 <- .raster_imagem(im, 1); r5 <- .raster_imagem(im, 0.5)
    b1 <- writeBin(as.integer(unclass(r1)[1]), raw()); b5 <- writeBin(as.integer(unclass(r5)[1]), raw())
    for (k in 1:4) { f2 <- tempfile(fileext = ".png"); png::writePNG(array(runif(12), c(2, 2, 3)), f2); invisible(.ler_imagem(f2)) }
    inherits(im$nat, "nativeRaster") && identical(as.integer(b1), c(255L, 0L, 0L, 255L)) && identical(as.integer(b5), c(255L, 0L, 0L, 128L)) && identical(.raster_imagem(im, 1), im$nat) &&
      length(ls(.cache_imagens)) <= 3 })
  teste("figura: com a quebra de eixo, a figura em fração fica só na parte de cima", {
    dq <- data.frame(x = 1:20, A = c(1:10, 1001:1010)); cq <- ci; cq$grafico$colunas_y <- "A"; cq$quebra <- utils::modifyList(ci$quebra, list(ativo = TRUE, de = 100, ate = 900))
    cq$imagens <- list(list(arquivo = f_png)); pt <- attr(suppressWarnings(plotar(dq, cq)), "partes"); monta(pt[[1]]) && monta(pt[[2]]) })
  teste("painel: a variável imagens chega ao cfg", length(suppressMessages(aplicar_painel(c0, list2env(list(imagens = list(list(arquivo = f_png))))))$imagens) == 1)
} else cat("(png/jpeg não instalados: testes de figuras pulados)\n")

cat(sprintf("\n==== %d PASSOU / %d FALHOU ====\n", .res["passou"], .res["falhou"]))
unlink(tmp, recursive = TRUE)
