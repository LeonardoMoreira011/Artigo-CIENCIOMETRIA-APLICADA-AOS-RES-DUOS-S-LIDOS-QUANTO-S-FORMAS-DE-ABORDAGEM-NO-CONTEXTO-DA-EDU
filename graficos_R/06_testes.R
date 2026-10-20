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
      any(grepl("^#D62728", renderiza(attr(plotar(an, cq2), "partes")[[1]]))))
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
                    "y_intervalo", "x_ticks_manuais", "y_ticks_manuais", "eixos_titulo_negrito", "rotulos_dados_tamanho_pt",
                    "y2_series", "y2_titulo", "y2_inicio", "y2_fim", "y2_intervalo", "y2_ticks_manuais", "y2_ticks_menores",
                    "y2_cor", "y2_cor_eixo", "y2_dividir_por", "y2_casas_decimais", "y2_notacao", "y2_prefixo", "y2_sufixo",
                    "y2_fator", "y2_deslocamento", "linha_espessura_por_serie", "simbolo_tamanho_por_serie",
                    "simbolo_borda_por_serie", "y2_igual_y1", "y2_legenda_sufixo", "legenda_canto", "fonte_pasta", "simbolo_forma_por_serie", "legenda_nomes")
        all(v %in% c(names(.PAINEL_MAPA), extras)) })
teste("painel: cores_por_serie sem nomes dá erro claro",
      da_erro(aplicar_painel(c0, list2env(list(cores_por_serie = c("#000000", "#FF0000")))), "nomes"))

cat("\n--- Quebra de eixo contínua (estilo Origin) ---\n")
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
teste("quebra + Y2: y2_de >= y2_ate e trecho fora do eixo dão erro claro",
      { cb <- cq2; cb$quebra$y2_de <- 6000; cb$quebra$y2_ate <- 5000
        cf <- cq2; cf$quebra$y2_de <- 100000; cf$quebra$y2_ate <- 200000
        da_erro(plotar(aq, cb), "y2_de < y2_ate") && da_erro(plotar(aq, cf), "dentro do eixo") })
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
        cq2 <- cq; cq2$eixo_y$rotacao_titulo <- 0; cq2$eixo_y2$rotacao_titulo <- 0
        medidas(cq, aqq)$larg < medidas(cq2, aqq)$larg - 0.5 })
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
