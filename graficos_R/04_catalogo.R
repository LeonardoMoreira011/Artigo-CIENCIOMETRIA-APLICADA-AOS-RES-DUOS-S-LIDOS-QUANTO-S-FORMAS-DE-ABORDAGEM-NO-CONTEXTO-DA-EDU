# =============================================================================
#  04_catalogo.R — "LEGENDA DE POSSIBILIDADES"
# =============================================================================
#  ajuda()                 lista os blocos do cfg e para que servem
#  ajuda("eixo_x")         mostra TODOS os parâmetros do bloco, com OPÇÕES e EX.
#  ajuda("tipos")          resumo dos tipos de gráfico e o que cada um usa
#  mostrar_paletas()       desenha as paletas disponíveis
#  galeria()               gera saida/galeria_referencia.pdf (símbolos, linhas,
#                          paletas, ticks, gradientes e um exemplo de cada tipo)
#  O texto de ajuda é lido diretamente do 01_config.R: o que você vê aqui é
#  exatamente o que está documentado lá.
# =============================================================================

.APELIDOS <- c(x = "eixo_x", y = "eixo_y", y2 = "eixo_y2", eixo = "eixo_x", eixos = "eixo_x",
               pontos = "linhas", linha = "linhas", linha_pontos = "linhas", area = "linhas",
               erro = "linhas", erros = "linhas", histograma = "distribuicao", densidade = "distribuicao",
               ecdf = "distribuicao", violino = "boxplot", box = "boxplot", rosca = "pizza",
               cor = "cores", gradiente = "cores", paleta = "cores", serie = "series",
               simbolo = "serie_padrao", simbolos = "serie_padrao", moldura = "caixa", ticks = "eixo_x",
               fonte = "texto", painel = "paineis", empilhar = "paineis", exportar = "exportacao",
               salvar = "exportacao", grid = "grade", titulo = "titulos", referencia = "referencias",
               tempo = "eixo_x", data = "eixo_x", datas = "eixo_x", ordenar_x = "linhas",
               pca = "multivariada", ca = "multivariada", cca = "multivariada", ordenacao = "multivariada", biplot = "multivariada",
               mapa_mundo = "mapa", mapa_brasil = "mapa", mundo = "mapa", brasil = "mapa", heatmap = "mapa_calor", calor = "mapa_calor")

ajuda <- function(bloco = NULL) {
  arq <- file.path(.motor_pasta, "01_config.R")
  L <- readLines(arq, encoding = "UTF-8", warn = FALSE)
  ini <- grep("^cfg\\$[a-z_0-9]+ <- ", L)
  nomes <- sub("^cfg\\$([a-z_0-9]+) <- .*", "\\1", L[ini])
  tracos <- grep("^# -{20,}", L)
  cab <- function(i) { t <- tracos[tracos < ini[i]]; if (length(t) >= 2) t[length(t) - 1] else ini[i] }
  if (is.null(bloco)) {
    cat("\nBLOCOS DO cfg (use ajuda(\"nome\") para ver os parâmetros):\n\n")
    for (i in seq_along(ini)) {
      t <- tracos[tracos < ini[i]]
      tit <- if (length(t)) sub("^#\\s*", "", L[t[length(t)] - 1]) else nomes[i]
      cat(sprintf("  %-14s %s\n", nomes[i], sub("^[A-Z_0-9]+\\s*[—-]\\s*", "", tit)))
    }
    cat("\nOutros:  ajuda(\"tipos\")   mostrar_paletas()   galeria()   listar_fontes()   listar_estilos()\n\n")
    return(invisible(nomes))
  }
  if (identical(bloco, "tipos")) {
    cat('
TIPOS DE GRÁFICO  (cfg$grafico$tipo)            colunas usadas / bloco de opções
  "pontos"          dispersão                    coluna_x + colunas_y    -> ajuda("linhas")
  "linha"           só linhas                    coluna_x + colunas_y    -> ajuda("linhas")
  "linha_pontos"    linha com símbolos           coluna_x + colunas_y    -> ajuda("linhas")
  "area"            linha com área preenchida    coluna_x + colunas_y    -> ajuda("linhas")
  "area_empilhada"  áreas somadas                coluna_x + colunas_y    -> ajuda("linhas")
  "barras"          colunas/barras               coluna_x (categorias) + colunas_y -> ajuda("barras")
  "pizza"           pizza / rosca                coluna_x (categorias) + 1 coluna_y -> ajuda("pizza")
  "histograma"      histograma (+curvas)         colunas_y ou coluna_grupo -> ajuda("distribuicao")
  "densidade"       curva de densidade           colunas_y ou coluna_grupo -> ajuda("distribuicao")
  "ecdf"            distribuição acumulada       colunas_y ou coluna_grupo -> ajuda("distribuicao")
  "boxplot"         box, violino, meio box, média±erro  colunas_y ou coluna_grupo -> ajuda("boxplot")
  "mapa_calor"      mapa de calor (eixo Z em cores) coluna_x (linhas) + colunas numéricas -> ajuda("mapa_calor")
  "pca" | "ca" | "cca"  ordenações (biplot)      coluna_x (amostras) + multivariada$variaveis/ambientais -> ajuda("multivariada")
  "mapa_mundo"      mapa-múndi (países, regiões comerciais) coluna_x (país em inglês) + colunas_y[1] -> ajuda("mapa")
  "mapa_brasil"     mapa do Brasil (estados, regiões) coluna_x (sigla ou nome) + colunas_y[1] -> ajuda("mapa")

RECURSOS QUE VALEM PARA TODOS (exceto pizza, mapas e mapa de calor, que não têm eixos numéricos): eixo_x, eixo_y, eixo_y2, caixa, grade,
  legenda, titulos, texto, referencias, anotacoes, quebra, paineis, exportacao.
')
    return(invisible())
  }
  b <- if (bloco %in% nomes) bloco else .APELIDOS[bloco]
  if (is.na(b) || !b %in% nomes) {
    sug <- nomes[utils::adist(bloco, nomes) <= 3]
    stop("Bloco '", bloco, "' não existe.", if (length(sug)) paste0(" Você quis dizer '", sug[1], "'?") else "",
         " Use ajuda() para ver a lista.", call. = FALSE)
  }
  i <- match(b, nomes)
  fim <- if (i < length(ini)) cab(i + 1) - 1 else length(L)
  trecho <- L[cab(i):fim]
  while (length(trecho) && !nzchar(trimws(trecho[length(trecho)]))) trecho <- trecho[-length(trecho)]
  cat("\n", paste(trecho, collapse = "\n"), "\n\n", sep = "")
  if (exists("cfg", envir = globalenv())) {
    atual <- get("cfg", envir = globalenv())[[b]]
    cat("# VALORES ATUAIS em cfg$", b, ":\n", sep = "")
    utils::str(atual, give.attr = FALSE, no.list = TRUE, comp.str = "  $ ")
  }
  invisible(trecho)
}

.grafico_paletas <- function(n = 8) {
  nomes <- c(unlist(.PALETAS_GRUPOS, use.names = FALSE), "personalizada")
  cfg0 <- if (exists("cfg", envir = globalenv())) get("cfg", envir = globalenv())$cores else .cfg_ref$cores
  d <- do.call(rbind, lapply(nomes, function(p) {
    cores <- tryCatch(.paleta(p, n, cfg0), error = function(e) rep("grey90", n))
    data.frame(paleta = p, i = seq_len(n), cor = cores)
  }))
  d$paleta <- factor(d$paleta, levels = rev(nomes))
  g <- ggplot(d, aes(i, paleta)) + geom_tile(aes(fill = I(cor)), colour = "white", linewidth = 0.8) +
    geom_text(aes(label = i), size = 2.6, colour = "white") +
    scale_x_continuous(breaks = NULL, expand = c(0, 0)) +
    labs(x = NULL, y = NULL, title = "Paletas  (cfg$cores$paleta <- \"nome\")") +
    theme_minimal(11) + theme(panel.grid = element_blank(), axis.text.y = element_text(face = "bold", size = 8))
  g
}

mostrar_paletas <- function(n = 8) {
  g <- .grafico_paletas(n)
  print(g)
  invisible(g)
}

galeria <- function(arquivo = "saida/galeria_referencia.pdf") {
  if (!dir.exists(dirname(arquivo))) dir.create(dirname(arquivo), recursive = TRUE)
  cfg0 <- .cfg_ref
  pag <- list()
  # 1. símbolos
  s <- data.frame(s = 0:25, x = (0:25) %% 9, y = -((0:25) %/% 9))
  pag[[1]] <- ggplot(s, aes(x, y)) +
    geom_point(aes(shape = I(s)), size = 6, fill = "#4E79A7", colour = "black", stroke = 1) +
    geom_text(aes(label = s), vjust = 2.6, size = 3.5) +
    scale_y_continuous(expand = expansion(add = 0.7)) + scale_x_continuous(expand = expansion(add = 0.6)) +
    labs(title = "Símbolos  —  cfg$serie_padrao$simbolo  ou  cfg$series[[\"nome\"]]$simbolo",
         subtitle = paste("0–14: só contorno | 15–20: sólidos (cor da série) |",
                          "21–25: contorno + preenchimento (preenchimento_simbolo)")) +
    theme_void(12) + theme(plot.margin = margin(20, 20, 20, 20))
  # 2. tipos de linha
  lt <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash", "44", "13", "1343", "73", "2262")
  ld <- data.frame(t = factor(lt, levels = rev(lt)), x = 0, xend = 1)
  pag[[2]] <- ggplot(ld, aes(x = x, xend = xend, y = t, yend = t)) +
    geom_segment(aes(linetype = I(as.character(t))), linewidth = .lw(2)) +
    scale_x_continuous(limits = c(-0.05, 1.05)) +
    labs(title = "Tipos de linha  —  cfg$serie_padrao$linha_tipo",
         subtitle = "Códigos hexadecimais: pares (traço, espaço). Ex.: \"44\", \"1343\"", x = NULL, y = NULL) +
    theme_minimal(12) + theme(panel.grid = element_blank(), axis.text.x = element_blank(),
                              axis.text.y = element_text(face = "bold",
                                                         size = 12), plot.margin = margin(20, 20, 20, 20))
  # 3. paletas
  pag[[3]] <- .grafico_paletas() + theme(plot.margin = margin(20, 20, 20, 20))
  # dados sintéticos para exemplos
  set.seed(1)
  xy <- data.frame(X = 1:10, `Série 1` = cumsum(stats::runif(10, 0, 3)), `Série 2` = cumsum(stats::runif(10, 0, 2)),
                   check.names = FALSE)
  cat_ <- data.frame(Categoria = c("A", "B", "C", "D"), `Grupo 1` = c(5, 8, 3, 6), `Grupo 2` = c(4, 6, 5, 7),
                     check.names = FALSE)
  am <- data.frame(G1 = stats::rnorm(40, 10, 2), G2 = stats::rnorm(40, 13, 2.5), G3 = stats::rnorm(40, 12, 1.5))
  mini <- function(d, mod, tit) {
    c1 <- .mesclar(cfg0, mod); c1$texto$tamanho_base_pt <- 8; c1$legenda$tamanho_chave_pt <- 9
    c1$titulos$titulo <- tit; c1$titulos$tamanho_titulo_pt <- 9
    .plotar_um(d, c1)
  }
  # 4. ticks e gradientes
  tk <- lapply(c("dentro", "fora", "ambos", "nenhum"), function(dd)
    mini(xy, list(grafico = list(tipo = "linha"), legenda = list(mostrar = FALSE),
                  eixo_x = list(direcao_maiores = dd, direcao_menores = dd, n_menores = 1),
                  eixo_y = list(direcao_maiores = dd, direcao_menores = dd, n_menores = 1)),
         paste0("direcao_maiores = \"", dd, "\"")))
  gr <- lapply(c("vertical", "vertical_invertido", "horizontal", "horizontal_invertido", "diagonal", "radial"),
               function(dd)
    mini(cat_, list(grafico = list(tipo = "barras", colunas_y = "Grupo 1"), legenda = list(mostrar = FALSE),
                    cores = list(preenchimento = "gradiente", gradiente_direcao = dd, gradiente_cor2 = "white"),
                    series = list(`Grupo 1` = list(cor = "#1F4E9E"))),
         paste0("gradiente_direcao = \"", dd, "\"")))
  pag[[4]] <- patchwork::wrap_plots(c(tk, gr), ncol = 4) +
    patchwork::plot_annotation(title = "Direção dos ticks (eixo_x/eixo_y) e direção do gradiente (cores)")
  # 5. tipos
  tipos <- list(
    mini(xy, list(grafico = list(tipo = "pontos")), "tipo = \"pontos\""),
    mini(xy, list(grafico = list(tipo = "linha")), "\"linha\""),
    mini(xy, list(grafico = list(tipo = "linha_pontos")), "\"linha_pontos\""),
    mini(xy, list(grafico = list(tipo = "area"), legenda = list(mostrar = FALSE)), "\"area\""),
    mini(xy, list(grafico = list(tipo = "area_empilhada"), cores = list(paleta = "cinabro")), "\"area_empilhada\""),
    mini(xy, list(grafico = list(tipo = "linha"), linhas = list(ligacao = "degrau_hv")),
         "linhas$ligacao = \"degrau_hv\""),
    mini(cat_, list(grafico = list(tipo = "barras"), cores = list(paleta = "cinabro")), "\"barras\" agrupado"),
    mini(cat_, list(grafico = list(tipo = "barras"), barras = list(arranjo = "empilhado"),
                    cores = list(paleta = "cinabro")), "barras empilhado"),
    mini(cat_, list(grafico = list(tipo = "barras"), barras = list(orientacao = "horizontal"),
                    cores = list(paleta = "cinabro")), "barras horizontal"),
    mini(cat_, list(grafico = list(tipo = "pizza", colunas_y = "Grupo 1"), cores = list(paleta = "cinabro"),
                    pizza = list(explodir = "B", rotulos_tamanho_pt = 7)), "\"pizza\""),
    mini(cat_, list(grafico = list(tipo = "pizza", colunas_y = "Grupo 1"), cores = list(paleta = "cinabro"),
                    pizza = list(raio_furo = 0.5, rotulos_tamanho_pt = 7)), "pizza raio_furo = 0.5"),
    mini(am, list(grafico = list(tipo = "histograma", colunas_y = "G1"), distribuicao = list(curva_normal = TRUE),
                  legenda = list(mostrar = FALSE)), "\"histograma\""),
    mini(am, list(grafico = list(tipo = "densidade"), cores = list(paleta = "magma")), "\"densidade\""),
    mini(am, list(grafico = list(tipo = "ecdf"), cores = list(paleta = "cinabro")), "\"ecdf\""),
    mini(am, list(grafico = list(tipo = "boxplot"), cores = list(paleta = "cinabro")), "boxplot \"box\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "box_pontos"),
                  cores = list(paleta = "cinabro")), "\"box_pontos\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "meio_box"),
                  cores = list(paleta = "cinabro")), "\"meio_box\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "violino_box"),
                  cores = list(paleta = "cinabro")), "\"violino_box\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "violino"),
                  cores = list(paleta = "cinabro")), "\"violino\""),
    mini(am, list(grafico = list(tipo = "boxplot"), boxplot = list(variacao = "media_erro"),
                  cores = list(paleta = "cinabro")), "\"media_erro\"")
  )
  pag[[5]] <- patchwork::wrap_plots(lapply(tipos, function(g) patchwork::wrap_elements(full = g)), ncol = 4) +
    patchwork::plot_annotation(
      title = "Tipos e variações (cfg$grafico$tipo, cfg$boxplot$variacao, cfg$barras$arranjo ...)")
  dev <- if (capabilities("cairo")) grDevices::cairo_pdf else grDevices::pdf
  dev(arquivo, width = 11.7, height = 8.3, onefile = TRUE)
  for (p in pag) print(p)
  grDevices::dev.off()
  message("Galeria salva em ", arquivo)
  invisible(arquivo)
}
