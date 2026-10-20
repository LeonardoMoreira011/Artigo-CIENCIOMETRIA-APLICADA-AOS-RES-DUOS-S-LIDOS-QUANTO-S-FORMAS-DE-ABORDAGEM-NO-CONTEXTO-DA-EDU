# =============================================================================
#  app_shiny/testes_app.R — testes do app (sem abrir o navegador).  Rode:  Rscript app_shiny/testes_app.R
# =============================================================================
ok <- 0; falhas <- 0
teste <- function(nome, expr) {
  r <- tryCatch(suppressWarnings(isTRUE(expr)), error = function(e) { message("   erro: ", conditionMessage(e)); FALSE })
  if (r) ok <<- ok + 1 else falhas <<- falhas + 1
  cat(if (r) "[PASSOU] " else "[FALHOU] ", nome, "\n", sep = "")
}
aqui <- normalizePath(if (file.exists("app.R")) "." else if (file.exists("app_shiny/app.R")) "app_shiny" else stop("rode a partir de graficos_R"), winslash = "/")
setwd(aqui)
suppressPackageStartupMessages(library(shiny))
raiz <- normalizePath("..", winslash = "/")
source(file.path(raiz, "01_config.R"), encoding = "UTF-8"); suppressMessages(source(file.path(raiz, "02_motor.R"), encoding = "UTF-8"))
CFG0 <- .completar_cfg(cfg)
for (a in c("espec.R", "nucleo.R", "ui_blocos.R", "servidor.R")) source(file.path("codigo", a), encoding = "UTF-8")

# ---- cobertura: tudo o que o painel tem, o app tem -------------------------------------------------------------------
L <- readLines(file.path(raiz, "painel_de_ajustes.R"), encoding = "UTF-8")
L <- L[(grep("PAINEL DE AJUSTES DO GRÁFICO", L)[1]):(grep("EXECUÇÃO \\(não precisa editar\\)", L)[1])]
vars_painel <- sub(" *<- .*", "", grep("^[a-z_A-Z0-9]+ +<- ", L, value = TRUE))
vars_painel <- setdiff(vars_painel, "ARQUIVO_CSV")
tratadas_a_parte <- c("fonte_pasta",                                    # arquivo da fonte: o app já traz a Barlow
                      "cores_personalizadas", "cores_por_serie", "legenda_nomes", "linha_espessura_por_serie",
                      "simbolo_tamanho_por_serie", "simbolo_borda_por_serie", "simbolo_forma_por_serie",   # tabela de séries
                      "simbolo_variar", "legenda_sombra_deslocamento_pt", "legenda_ancora",
                      "pasta_saida")                                  # a pasta: o navegador é que baixa o arquivo
teste("o app tem um campo para cada variável do painel_de_ajustes.R (as exceções estão listadas e são tratadas à parte)",
      length(setdiff(vars_painel, c(names(ESPEC_CAMPOS), tratadas_a_parte))) == 0)
if (length(setdiff(vars_painel, c(names(ESPEC_CAMPOS), tratadas_a_parte)))) print(setdiff(vars_painel, c(names(ESPEC_CAMPOS), tratadas_a_parte)))
teste("todo campo do app vira uma variável do painel (ou é um dos auxiliares conhecidos)",
      all(names(ESPEC_CAMPOS) %in% c(vars_painel, "simbolo_modo", "legenda_sombra_dx", "legenda_sombra_dy")))
teste("cada bloco do app tem número, título, resumo e pelo menos um campo", all(vapply(ESPEC, function(b)
  nzchar(b$titulo) && nzchar(b$resumo) && (length(b$campos) + length(b$grupos)) > 0, NA)) && length(ESPEC) == 12)

# ---- tela -> variáveis ------------------------------------------------------------------------------------------------
v0 <- lapply(ESPEC_CAMPOS, valor_inicial, cfg0 = CFG0)
teste("com a tela no estado inicial nenhuma variável é enviada (vale o padrão do template)", length(montar_variaveis(v0, CFG0)) == 0)
v1 <- v0; v1$x_intervalo <- "1"; v1$y_dividir_por <- 1000; v1$grade_tipo <- "dotted"; v1$grade_opacidade <- 0.3; v1$grade_x <- TRUE
v1$quebra_ativar <- TRUE; v1$legenda_canto <- "sup_dir"; v1$legenda_distancia_pt <- 8; v1$painel_largura_cm <- 9; v1$simbolo_modo <- "igual"
v1$simbolo_forma <- "quadrado"; v1$cores_paleta <- "marca"; v1$esfera_luz <- "0.35,0.45"; v1$x_ticks_manuais <- "2015, 2020; 2026"
v1$legenda_sombra_dx <- 5; v1$legenda_sombra_dy <- 2; v1$legenda_mostrar <- "nao"; v1$y_titulo <- "Receita (US$ ×10^{3})"
vv <- montar_variaveis(v1, CFG0)
teste("valores alterados viram as variáveis certas, com o tipo certo", identical(vv$x_intervalo, 1) && vv$y_dividir_por == 1000 &&
      identical(vv$grade_tipo, "dotted") && vv$grade_opacidade == 0.3 && isTRUE(vv$grade_x) && isTRUE(vv$quebra_ativar) &&
      vv$legenda_canto == "sup_dir" && vv$painel_largura_cm == 9 && vv$simbolo_forma == "quadrado" &&
      identical(vv$cores_paleta, "marca") && is.null(vv$cores_personalizadas) && identical(vv$esfera_luz, c(0.35, 0.45)) &&
      identical(vv$x_ticks_manuais, c(2015, 2020, 2026)) && identical(vv$legenda_sombra_deslocamento_pt, c(5, 2)) &&
      identical(vv$legenda_mostrar, FALSE) && vv$y_titulo == "Receita (US$ ×10^{3})")
v2 <- v0; v2$simbolo_modo <- "variar"; v2$simbolo_forma <- "estrela"
teste("forma só vale com 'todas iguais'", is.null(montar_variaveis(v2, CFG0)$simbolo_forma))
sr <- data.frame(nome = c("A", "B"), cor = c("#112233", ""), forma = c("esfera", ""), tamanho = c(NA, 9), linha = c(3, NA), borda = c(NA, NA),
                 legenda = c("Série A", "B"), stringsAsFactors = FALSE)
vs <- montar_variaveis(v0, CFG0, sr)
teste("tabela de séries vira variáveis por série (e nome igual ao da coluna não é enviado)",
      identical(vs$cores_por_serie, c(A = "#112233")) && identical(vs$simbolo_forma_por_serie, c(A = "esfera")) &&
      identical(vs$simbolo_tamanho_por_serie, c(B = 9)) && identical(vs$linha_espessura_por_serie, c(A = 3)) &&
      identical(vs$legenda_nomes, c(A = "Série A")) && is.null(vs$simbolo_borda_por_serie))

# ---- segunda rodada: paletas, formatos, campos novos ----------------------------------------------------------------------
teste("ler_cores_texto entende #RRGGBB, #RGB, RRGGBB, nomes do R, vírgulas, espaços e linhas (e ignora o que não é cor)",
      identical(ler_cores_texto("#1b3a8c, 0E9F4B\n#f80 red xyz"), c("#1B3A8C", "#0E9F4B", "#FF8800", "#FF0000")) && length(ler_cores_texto("nada aqui")) == 0)
vp <- v0; vp$cores_paleta <- "propria"; vp$.paleta_propria <- "#112233, #445566"
vpp <- montar_variaveis(vp, CFG0)
vs2 <- v0; vs2$cores_paleta <- "salva:Minha"; vs2$.paletas_salvas <- list(Minha = c("#AA0000", "#00AA00"))
vss <- montar_variaveis(vs2, CFG0)
teste("paleta própria (do editor ou guardada) vira cores_personalizadas; paleta pronta vira cores_paleta",
      identical(vpp$cores_personalizadas, c("#112233", "#445566")) && is.null(vpp$cores_paleta) &&
      identical(vss$cores_personalizadas, c("#AA0000", "#00AA00")) &&
      identical({ vq <- v0; vq$cores_paleta <- "npg"; montar_variaveis(vq, CFG0)$cores_paleta }, "npg"))
teste("a lista de paletas da tela tem todos os grupos do motor + 'Minhas paletas' (com as guardadas)", {
  o <- opcoes_paletas("Minha"); all(names(.PALETAS_GRUPOS) %in% names(o)) && identical(unname(o[["Minhas paletas"]][2]), "salva:Minha") })
vf <- v0; vf$formatos <- c("tiff", "svg"); vf$fundo_transparente <- TRUE
vff <- montar_variaveis(vf, CFG0)
teste("tipo de arquivo (marcados) e fundo transparente viram formatos e fundo_transparente; o padrão não é enviado",
      identical(vff$formatos, c("tiff", "svg")) && isTRUE(vff$fundo_transparente) && is.null(montar_variaveis(v0, CFG0)$formatos))
teste("os 'tipos de arquivo' do app são os que o salvar() grava", all(c("png", "tiff", "jpeg", "svg", "pdf") %in% .FORMATOS))
# cada campo do app, alterado sozinho, vira variável e o painel aplica (sem desenhar: rápido). O desenho de cada um foi
# conferido à parte (389 casos, nenhum erro inesperado).
alt_campo <- function(c, d) switch(c$tipo,
  num = , int = { v <- if (!is.na(c$min) && !is.na(c$max)) (c$min + c$max) / 2 else if (!is.na(c$min)) c$min + 2 else 3
                  if (isTRUE(all.equal(v, d))) v + 1 else v },
  txt = "2", vec = "2016, 2020", sel = , tri = , selbusca = { o <- unname(unlist(c$opcoes)); o[o != "" & o != d][1] },
  chkgrupo = c("svg"), chk = !isTRUE(d), cor = "#FF0000", selmulti = c("quadrado", "triangulo"),
  colx = "Ano", colsy = "Brasil (RSP)", colsy2 = "Brasil (RSP)", NULL)
erros_campos <- character(0)
for (id in names(ESPEC_CAMPOS)) {
  vc <- v0; vc[[id]] <- alt_campo(ESPEC_CAMPOS[[id]], v0[[id]])
  r <- tryCatch({ vars <- montar_variaveis(vc, CFG0); suppressMessages(suppressWarnings(aplicar_painel(CFG0, list2env(vars, parent = emptyenv()), dados = NULL))); "" },
                error = function(e) paste0(id, ": ", conditionMessage(e)))
  if (nzchar(r)) erros_campos <- c(erros_campos, r)
}
if (length(erros_campos)) print(erros_campos)
teste("todos os campos do app, alterados um a um, viram variáveis e o painel aplica sem erro", length(erros_campos) == 0)

# ---- gráfico de verdade -----------------------------------------------------------------------------------------------
d <- ler_csv(file.path(raiz, "dados", "exemplo_dois_eixos_e_quebra.csv"), utils::modifyList(CFG0$dados, list(relatorio = FALSE)))
v3 <- v0; v3$colunas_y <- names(d)[2:5]; v3$y2_series <- names(d)[5]; v3$quebra_ativar <- TRUE; v3$quebra_estilo <- "continuo"
v3$legenda_canto <- "sup_esq"; v3$painel_largura_cm <- 9; v3$painel_altura_cm <- 6; v3$simbolo_modo <- "variar"; v3$y_dividir_por <- 1000
v3$y2_titulo <- "Pop. (milhões)"; v3$y2_igual_y1 <- TRUE
r <- construir_grafico(d, montar_variaveis(v3, CFG0, NULL), CFG0)
teste("construir_grafico monta quebra + Y2 + caixa fixa sem erro", is.null(r$erro) && !is.null(r$g) && "quebra_ativar" %in% r$aplicado)
p <- desenhar_previa(r$g, r$cfg, dpi = 60)
teste("a prévia é um PNG com o tamanho da página calculado", file.exists(p$arquivo) && p$larg_px > 100 && p$alt_px > 100)
r2 <- construir_grafico(d, list(tipo_grafico = "linha_pontos", y2_intervalo = 3), CFG0)
teste("variável de Y2 sem Y2 ativo gera aviso (não some em silêncio)", any(grepl("não está ativo", r2$avisos)))
r3 <- construir_grafico(d, list(quebra_ativar = TRUE, quebra_de = 10, quebra_ate = 5), CFG0)
teste("erro de configuração vira mensagem (não derruba o app)", !is.null(r3$erro) && nzchar(r3$erro))
cod <- gerar_codigo(montar_variaveis(v3, CFG0, NULL), arquivo_csv = "dados.csv", script_completo = TRUE)
teste("código gerado é um script R válido que usa as mesmas variáveis",
      !inherits(try(parse(text = cod), silent = TRUE), "try-error") && grepl("quebra_ativar +<- TRUE", cod) && grepl("ARQUIVO_CSV", cod))
cod2 <- gerar_codigo(montar_variaveis(v1, CFG0, NULL))
env <- new.env(); eval(parse(text = cod2), envir = env)
teste("rodar o código gerado reproduz as mesmas variáveis", identical(as.list(env)[sort(names(as.list(env)))], montar_variaveis(v1, CFG0, NULL)[sort(names(montar_variaveis(v1, CFG0, NULL)))]))
tmp <- tempfile(); dir.create(tmp); cfgx <- r$cfg; cfgx$exportacao$pasta <- tmp; cfgx$exportacao$formatos <- c("png", "svg", "tiff", "jpeg"); cfgx$exportacao$dpi <- 80
arqs <- suppressMessages(suppressWarnings(salvar(r$g, cfgx)))
teste("salvar grava PNG, SVG, TIFF e JPEG a partir do que o app monta", length(arqs) == 4 && all(file.size(arqs) > 800))

# ---- fonte oficial ---------------------------------------------------------------------------------------------------
teste("a lista de fontes do app traz a Barlow, as genéricas e as instaladas (systemfonts)",
      { o <- unlist(.FONTES); all(c("Barlow", "sans", "serif") %in% o) && length(o) > 6 &&
        "Instaladas no computador (systemfonts)" %in% names(.FONTES) })
teste("a Barlow é a fonte padrão e está registrada", identical(CFG0$texto$fonte, "Barlow") && "Barlow" %in% .familias_fontes() &&
      all(file.exists(file.path(raiz, "fontes", "Barlow", c("Barlow-Regular.ttf", "Barlow-Bold.ttf", "Barlow-Italic.ttf", "Barlow-BoldItalic.ttf", "OFL.txt")))))

# ---- lançadores e ícone -------------------------------------------------------------------------------------------------
ico <- readBin(file.path("www", "icone.ico"), "raw", 6)
teste("o ícone é um .ico válido e os lançadores (bat, vbs, ps1, iniciar.R) existem",
      identical(ico[1:4], as.raw(c(0, 0, 1, 0))) && ico[5] >= as.raw(4) &&
      all(file.exists(file.path(raiz, c("abrir_app.bat", "iniciar_gerador_oculto.vbs", "criar_atalho.ps1", "Criar_atalho_na_area_de_trabalho.bat", "abrir_app.R"))),
          file.exists("iniciar.R")))
teste("iniciar_gerador() existe e usa o endereço bonito gerador.localhost", { source("iniciar.R"); is.function(iniciar_gerador) &&
      grepl("gerador.localhost", paste(deparse(iniciar_gerador), collapse = "")) })
teste("o .vbs e os .bat têm quebras de linha do Windows (CRLF)",
      all(vapply(file.path(raiz, c("abrir_app.bat", "iniciar_gerador_oculto.vbs", "Criar_atalho_na_area_de_trabalho.bat")),
                 function(f) { b <- readBin(f, "raw", file.size(f)); any(b[-length(b)] == as.raw(13) & b[-1] == as.raw(10)) }, NA)))

# ---- negrito, rotação, grossura, break pelo app --------------------------------------------------------------------
vn <- v0; vn$negrito_geral <- TRUE; vn$y_rotacao_titulo <- 0; vn$quebra_marca_largura_pt <- 4; vn$painel_fixo <- FALSE; vn$moldura_espessura_pt <- 2
vn$grade_menor_x <- TRUE; vn$legenda_negrito <- TRUE
vnn <- montar_variaveis(vn, CFG0)
teste("negrito geral, rotação do título, marca da quebra, caixa fixa desligada, moldura e grade menor viram as variáveis do painel",
      isTRUE(vnn$negrito_geral) && vnn$y_rotacao_titulo == 0 && vnn$quebra_marca_largura_pt == 4 && identical(vnn$painel_fixo, FALSE) &&
      vnn$moldura_espessura_pt == 2 && isTRUE(vnn$grade_menor_x) && isTRUE(vnn$legenda_negrito))
rn <- construir_grafico(d, vnn, CFG0)
teste("o gráfico com esses ajustes monta sem erro", is.null(rn$erro) && !is.null(rn$g))

# ---- servidor (testServer) -------------------------------------------------------------------------------------------
options(gerador_sem_guia = TRUE)
testServer(servidor, {
  session$setInputs(exemplo = "exemplo_dois_eixos_e_quebra.csv")
  teste("servidor: escolher um exemplo carrega os dados", !is.null(rv$dados) && nrow(rv$dados) == 12)
  session$setInputs(auto = FALSE, atualizar = 1)
  teste("servidor: 'Atualizar agora' monta a prévia", !is.null(rv$previa) && is.null(rv$erro))
  teste("servidor: a prévia calcula onde está a legenda (caixa que se arrasta) dentro do painel",
        !is.null(rv$geo) && all(rv$geo$legenda[1:2] >= rv$geo$painel[1:2] - 1e-6) && rv$geo$legenda[3] < rv$geo$painel[3])
  session$setInputs(legenda_arrastada = list(esq = 0.25, base = 0.5, t = 1), legenda_redimensionada = list(largura = 0.3, t = 1))
  teste("servidor: arrastar e redimensionar a legenda na prévia roda sem erro", is.null(rv$erro))
  session$setInputs(paleta_propria = "#112233, #445566, #778899", paleta_nome = "Teste", paleta_salvar = 1)
  teste("servidor: guardar a paleta própria cria 'salva:Teste' na lista e fica nos valores", identical(names(rv$paletas), "Teste") &&
        identical(rv$paletas$Teste, c("#112233", "#445566", "#778899")))
  session$setInputs(cores_paleta = "salva:Teste", atualizar = 11)
  teste("servidor: usar a paleta guardada monta o gráfico com as cores dela", is.null(rv$erro) && identical(rv$res$cfg$cores$personalizada, c("#112233", "#445566", "#778899")))
  session$setInputs(paleta_excluir = 1)
  teste("servidor: excluir a paleta guardada selecionada", length(rv$paletas) == 0)
  session$setInputs(cores_paleta = "classico", quebra_ativar = TRUE, quebra_sugerir = 1)
  teste("servidor: 'Achar o maior vazio' funciona sem erro (o resultado vai para os campos de/até)", is.null(rv$erro))
  session$setInputs(quebra_ativar = TRUE, quebra_de = 100000, quebra_ate = 450000, quebra_estilo = "continuo", atualizar = 2)
  teste("servidor: ligar a quebra muda o gráfico e aparece em 'o que você mudou'", "quebra_ativar" %in% rv$res$aplicado && is.null(rv$erro))
  session$setInputs(quebra_de = 450000, quebra_ate = 100000, atualizar = 3)
  teste("servidor: configuração impossível mostra o erro em português sem derrubar o app", !is.null(rv$erro) && grepl("de < ate", rv$erro))
})
cat(sprintf("\n==== %d PASSOU / %d FALHOU ====\n", ok, falhas))
if (falhas) quit(status = 1)
