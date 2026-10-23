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
options(cinabro.sem_log = TRUE)                      # os testes não escrevem no registro de uso
raiz <- normalizePath("..", winslash = "/")
source(file.path(raiz, "01_config.R"), encoding = "UTF-8"); suppressMessages(source(file.path(raiz, "02_motor.R"), encoding = "UTF-8"))
CFG0 <- .completar_cfg(cfg)
for (a in c("idiomas.R", "espec.R", "nucleo.R", "ui_blocos.R", "servidor.R")) source(file.path("codigo", a), encoding = "UTF-8")
carregar_dicionarios("idiomas")

# ---- cobertura: tudo o que o painel tem, o app tem -------------------------------------------------------------------
L <- readLines(file.path(raiz, "painel_de_ajustes.R"), encoding = "UTF-8")
L <- L[(grep("PAINEL DE AJUSTES DO GRÁFICO", L)[1]):(grep("EXECUÇÃO \\(não precisa editar\\)", L)[1])]
vars_painel <- sub(" *<- .*", "", grep("^[a-z_A-Z0-9]+ +<- ", L, value = TRUE))
vars_painel <- setdiff(vars_painel, "ARQUIVO_CSV")
tratadas_a_parte <- c("fonte_pasta",                                    # arquivo da fonte: o app já traz a Barlow
                      "cores_personalizadas", "cores_por_serie", "legenda_nomes", "linha_espessura_por_serie",
                      "simbolo_tamanho_por_serie", "simbolo_borda_por_serie", "simbolo_forma_por_serie",   # tabela de séries
                      "simbolo_variar", "legenda_sombra_deslocamento_pt", "legenda_ancora",
                      "pasta_saida", "idioma")                                  # a pasta: o navegador é que baixa o arquivo
teste("o app tem um campo para cada variável do painel_de_ajustes.R (as exceções estão listadas e são tratadas à parte)",
      length(setdiff(vars_painel, c(names(ESPEC_CAMPOS), tratadas_a_parte, names(SLOTS)))) == 0)
if (length(setdiff(vars_painel, c(names(ESPEC_CAMPOS), tratadas_a_parte, names(SLOTS))))) print(setdiff(vars_painel, c(names(ESPEC_CAMPOS), tratadas_a_parte, names(SLOTS))))
teste("todo campo do app vira uma variável do painel (ou é um dos auxiliares conhecidos)",
      all(names(ESPEC_CAMPOS) %in% c(vars_painel, "simbolo_modo", "legenda_sombra_dx", "legenda_sombra_dy", IDS_SLOT)))
teste("cada bloco do app tem número, título, resumo e pelo menos um campo", all(vapply(ESPEC, function(b)
  nzchar(b$titulo) && nzchar(b$resumo) && (length(b$campos) + length(b$grupos)) > 0, NA)) && length(ESPEC) == 14)

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
      identical({ vq <- v0; vq$cores_paleta <- "tol_suave"; montar_variaveis(vq, CFG0)$cores_paleta }, "tol_suave"))
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

# ---- idiomas: português (BR), inglês e espanhol -------------------------------------------------------------------------------
teste("os dicionários de inglês e espanhol carregam (mais de 650 textos cada)", all(c("en", "es") %in% names(.i18n$dic)) &&
      all(vapply(.i18n$dic, length, 1L) > 650))
textos_espec <- local({
  out <- character(0); add <- function(x) { x <- unlist(x, use.names = FALSE); out <<- c(out, x[!is.na(x) & nzchar(x)]) }
  nomes_rec <- function(x) { if (is.list(x)) { add(names(x)); for (e in x) nomes_rec(e) } else if (!is.null(names(x))) add(names(x)) }
  for (b in ESPEC) { add(c(b$titulo, b$resumo, b$dica)); for (g in b$grupos) add(g$titulo)
    for (c in c(b$campos, unlist(lapply(b$grupos, function(g) g$campos), recursive = FALSE))) { add(c(c$rotulo, c$ajuda)); if (!is.null(c$opcoes)) nomes_rec(c$opcoes) } }
  nomes_rec(.PALETAS_GRUPOS); unique(out) })
textos_codigo <- local({            # textos entre aspas dentro de T(), TF(), tr() e trf() nos arquivos do app
  out <- character(0)
  for (arq in c("codigo/servidor.R", "codigo/ui_blocos.R")) {
    walk <- function(e) if (is.call(e)) {
      if (is.symbol(e[[1]]) && as.character(e[[1]]) %in% c("T", "TF", "tr", "trf") && length(e) > 1 && is.character(e[[2]])) out <<- c(out, e[[2]])
      for (i in seq_along(e)) if (!identical(e[[i]], quote(expr = ))) walk(e[[i]]) }
    for (e in parse(arq, keep.source = FALSE, encoding = "UTF-8")) walk(e) }
  unique(out) })
for (lg in c("en", "es"))
  teste(paste0("todo texto do app tem tradução em ", lg, " (", length(textos_espec) + length(textos_codigo), " textos conferidos)"),
        { f <- setdiff(c(textos_espec, textos_codigo), names(.i18n$dic[[lg]])); if (length(f)) print(head(f, 10)); length(f) == 0 })
teste("tr(), tr_nomes() e trf() traduzem; texto sem tradução volta igual; em português nada muda",
      identical(tr("Mais opções", "en"), "More options") && identical(tr("Mais opções", "pt"), "Mais opções") && identical(tr("texto que não existe", "es"), "texto que não existe") &&
      identical(names(tr_nomes(c("Limpar" = "a", "Sem chave" = "b"), "en")), c("Clear", "Sem chave")) && identical(trf("Maior vazio: de %s a %s.", 1, 2, idioma = "es"), "Mayor vacío: de 1 a 2."))
tg <- tags$div(class = "x", tags$label("Limpar"), tags$input(placeholder = "Nenhum arquivo", value = "Limpar"), HTML("Limpar"))
th <- as.character(traduzir_html(tg, "en"))
teste("traduzir_html troca o texto e o placeholder, mas não o value nem o HTML cru", grepl(">Clear<", th, fixed = TRUE) && grepl('placeholder="No file"', th, fixed = TRUE) &&
      grepl('value="Limpar"', th, fixed = TRUE) && grepl("Limpar\n</div>", th, fixed = TRUE))
teste("a tela inteira monta em inglês e em espanhol, sem restos do texto-chave em português nos títulos dos blocos", {
  tudo_ok <- TRUE
  for (lg in c("en", "es")) { .i18n$idioma <- lg; h <- paste(as.character(traduzir_html(ui_bloco(ESPEC[[2]], 2, CFG0, aberto = TRUE), lg)), collapse = "")
    tudo_ok <- tudo_ok && !grepl("Intervalos dos eixos", h, fixed = TRUE) && grepl(tr("Intervalos dos eixos", lg), h, fixed = TRUE) }
  .i18n$idioma <- "pt"; tudo_ok })
teste("o idioma vem do endereço (?idioma=en | es); valor estranho vira português", identical(idioma_do_pedido(list(QUERY_STRING = "?idioma=en")), "en") &&
      identical(idioma_do_pedido(list(QUERY_STRING = "?idioma=es")), "es") && identical(idioma_do_pedido(list(QUERY_STRING = "?idioma=xx")), "pt") && identical(idioma_do_pedido(list(QUERY_STRING = "")), "pt"))
re_en <- construir_grafico(d <- ler_csv(file.path(raiz, "dados", "exemplo_dois_eixos_e_quebra.csv"), utils::modifyList(CFG0$dados, list(relatorio = FALSE))),
                           list(quebra_ativar = TRUE, quebra_de = 10, quebra_ate = 5), CFG0, idioma = "en")
re_es <- construir_grafico(d, list(quebra_ativar = TRUE, quebra_de = 10, quebra_ate = 5), CFG0, idioma = "es")
re_pt <- construir_grafico(d, list(quebra_ativar = TRUE, quebra_de = 10, quebra_ate = 5), CFG0)
teste("as mensagens do motor chegam ao app no idioma da tela (e o idioma do motor volta ao português depois)",
      grepl("set de < ate", re_en$erro, fixed = TRUE) && grepl("define de < ate", re_es$erro, fixed = TRUE) && grepl("defina", re_pt$erro) && identical(getOption("cinabro.idioma", "pt"), "pt"))
vi <- montar_variaveis(v0, CFG0); vi$idioma <- "en"
teste("o idioma entra no código equivalente (idioma <- \"en\") e a variável idioma é aceita pelo painel", grepl('idioma +<- "en"', gerar_codigo(vi)) &&
      { r <- construir_grafico(d, vi, CFG0, idioma = "en"); is.null(r$erro) })

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
      all(file.exists(file.path(raiz, c("abrir_app.bat", "iniciar_gerador_oculto.vbs", "criar_atalho.ps1", "criar_atalho.vbs", "Criar_atalho_na_area_de_trabalho.bat", "abrir_app.R"))),
          file.exists("iniciar.R")))
teste("iniciar_gerador() existe e usa o endereço bonito cinabro.localhost", { source("iniciar.R"); is.function(iniciar_gerador) &&
      grepl("cinabro.localhost", paste(deparse(iniciar_gerador), collapse = "")) })
teste("o .vbs e os .bat têm quebras de linha do Windows (CRLF)",
      all(vapply(file.path(raiz, c("abrir_app.bat", "iniciar_gerador_oculto.vbs", "criar_atalho.vbs", "Criar_atalho_na_area_de_trabalho.bat")),
                 function(f) { b <- readBin(f, "raw", file.size(f)); any(b[-length(b)] == as.raw(13) & b[-1] == as.raw(10)) }, NA)))
bat <- paste(readLines(file.path(raiz, "abrir_app.bat"), warn = FALSE), collapse = "\n")
teste("abrir_app.bat: a janela fecha sozinha quando o R termina bem (só pede tecla se o R deu erro)",
      grepl("iniciar_gerador\\(encerrar_ao_fechar = TRUE\\)\"\nif errorlevel 1 \\(", bat) && grepl("exit /b 0\n\n:registro", bat))
vbsa <- paste(readLines(file.path(raiz, "criar_atalho.vbs"), warn = FALSE), collapse = "\n")
teste("criar_atalho.vbs cria o atalho na área de trabalho e no menu Iniciar, com o ícone, sem PowerShell",
      grepl("SpecialFolders(\"Desktop\")", vbsa, fixed = TRUE) && grepl("SpecialFolders(\"Programs\")", vbsa, fixed = TRUE) && grepl("icone.ico", vbsa, fixed = TRUE) &&
      grepl("CreateShortcut", vbsa, fixed = TRUE) && !any(grepl("[^ -~]", readLines(file.path(raiz, "criar_atalho.vbs"), warn = FALSE))))

# ---- negrito, rotação, grossura, break pelo app --------------------------------------------------------------------
vn <- v0; vn$negrito_geral <- TRUE; vn$y_rotacao_titulo <- 0; vn$quebra_marca_largura_pt <- 4; vn$painel_fixo <- FALSE; vn$moldura_espessura_pt <- 2
vn$grade_menor_x <- TRUE; vn$legenda_negrito <- TRUE
vnn <- montar_variaveis(vn, CFG0)
teste("negrito geral, rotação do título, marca da quebra, caixa fixa desligada, moldura e grade menor viram as variáveis do painel",
      isTRUE(vnn$negrito_geral) && vnn$y_rotacao_titulo == 0 && vnn$quebra_marca_largura_pt == 4 && identical(vnn$painel_fixo, FALSE) &&
      vnn$moldura_espessura_pt == 2 && isTRUE(vnn$grade_menor_x) && isTRUE(vnn$legenda_negrito))
rn <- construir_grafico(d, vnn, CFG0)
teste("o gráfico com esses ajustes monta sem erro", is.null(rn$erro) && !is.null(rn$g))

# ---- blocos 13 e 14: os cartões viram listas do painel ----------------------------------------------------------------------------
vs <- lapply(ESPEC_CAMPOS, valor_inicial, cfg0 = CFG0)
teste("cartões desligados não geram nada; ligados geram só o que difere do padrão (e a lista certa)", {
  length(montar_variaveis(vs, CFG0)[names(SLOTS)]) == length(SLOTS) && all(vapply(montar_variaveis(vs, CFG0)[names(SLOTS)], is.null, NA)) && {
    v1 <- vs; v1$aj1_ativo <- TRUE; v1$aj1_tipo <- "formula"; v1$aj1_formula <- "a*exp(-b*x)+c"; v1$aj1_inicio <- "a=5, b=0.1, c=0"; v1$fm1_ativo <- TRUE; v1$fm1_sem_fundo <- TRUE; v1$fm1_tipo <- "elipse"
    r <- montar_variaveis(v1, CFG0)
    identical(r$ajustes[[1]], list(tipo = "formula", formula = "a*exp(-b*x)+c", inicio = c(a = 5, b = 0.1, c = 0))) && identical(r$formas[[1]], list(tipo = "elipse", fundo = NA)) } })
erros_slot <- character(0)
for (id in IDS_SLOT[!grepl("_ativo$", IDS_SLOT)]) {                  # cada campo de cada cartão, com o cartão ligado
  vc <- vs; for (a in grep("_ativo$", IDS_SLOT, value = TRUE)) vc[[a]] <- TRUE
  vc[[id]] <- alt_campo(ESPEC_CAMPOS[[id]], vs[[id]])
  r <- tryCatch({ vars <- montar_variaveis(vc, CFG0); suppressMessages(suppressWarnings(aplicar_painel(CFG0, list2env(vars, parent = emptyenv()), dados = NULL))); "" },
                error = function(e) paste0(id, ": ", conditionMessage(e)))
  if (nzchar(r)) erros_slot <- c(erros_slot, r)
}
if (length(erros_slot)) print(erros_slot)
teste("todos os campos dos cartões (com todos os cartões ligados), alterados um a um, viram variáveis e o painel aplica sem erro", length(erros_slot) == 0)
teste("os 4 cartões de ajuste, 3 de traços, 3 de caixas e 6 de formas existem, e o 2º só aparece com o 1º ligado", {
  g <- ESPEC[[13]]$grupos; any(vapply(g, function(x) identical(x$ativo, "aj2_ativo") && identical(x$se, "input.aj1_ativo"), NA)) &&
    sum(vapply(c(ESPEC[[13]]$grupos, ESPEC[[14]]$grupos), function(x) !is.null(x$ativo), NA)) == 19 })
teste("cada bloco tem o tic 'Congelar' no cabeçalho", all(vapply(seq_along(ESPEC), function(i) grepl(paste0("cong_", ESPEC[[i]]$id), paste(as.character(ui_bloco(ESPEC[[i]], i, CFG0)), collapse = ""), fixed = TRUE), NA)))
re_slot <- construir_grafico(ler_csv(file.path(raiz, "dados", "ensaio_temperatura.csv"), utils::modifyList(CFG0$dados, list(relatorio = FALSE))),
  list(tipo_grafico = "pontos", ajustes = list(list(tipo = "linear", banda = TRUE)), caixas_estatisticas = list(list(itens = c("media", "r2"))), formas = list(list(tipo = "texto", texto = "oi"))), CFG0)
teste("o gráfico monta com os ajustes, a caixa e a forma vindos dos cartões", is.null(re_slot$erro) && !is.null(re_slot$g))
teste("o trilho tem um ícone por bloco (14) e a faixa de ferramentas tem os 7 tipos de ajuste, as formas, média ± DP, caixa, texto e figura", {
  tr_html <- paste(as.character(ui_trilho()), collapse = ""); fx <- gsub("&quot;", "\"", paste(as.character(ui_faixa()), collapse = ""), fixed = TRUE)
  all(vapply(ESPEC, function(b) grepl(paste0('data-painel="', b$id, '"'), tr_html, fixed = TRUE), NA)) &&
    all(vapply(unname(.AJUSTES_OPC), function(t) grepl(paste0('"tipo":"', t, '"'), fx, fixed = TRUE), NA)) &&
    all(vapply(c("marca", "caixa", "texto", "figura", "forma"), function(a) grepl(paste0('"acao":"', a, '"'), fx, fixed = TRUE), NA)) })
teste("desenhar_previa ajusta a resolução à largura do palco (entre 96 e 300 dpi) e devolve o dpi usado; .geometria_zonas funciona no gráfico do app", {
  rz <- construir_grafico(ler_csv(file.path(raiz, "dados", "ensaio_temperatura.csv"), utils::modifyList(CFG0$dados, list(relatorio = FALSE))), list(titulo_grafico = "T"), CFG0)
  p1 <- desenhar_previa(rz$g, rz$cfg, alvo_px = 700); p2 <- desenhar_previa(rz$g, rz$cfg, alvo_px = 1400)
  z <- .geometria_zonas(rz$g, rz$cfg)
  p1$dpi >= 96 && p2$dpi <= 300 && p2$dpi > p1$dpi && p2$larg_px > p1$larg_px && all(c("titulo", "xlab", "ylab") %in% names(z)) })
teste("o campo de figura (PNG/JPEG) existe nos 3 cartões, como campo de arquivo, e vira 'arquivo' na lista imagens", {
  vi <- vs; vi$im1_ativo <- TRUE; vi$im1_arquivo <- "/tmp/x.png"; vi$im1_ancora <- "sup_dir"; vi$im1_largura <- 0.3
  length(IDS_ARQUIVO) == 3 && all(vapply(ESPEC_CAMPOS[IDS_ARQUIVO], function(c) c$tipo == "arquivo", NA)) &&
    identical(montar_variaveis(vi, CFG0)$imagens, list(list(arquivo = "/tmp/x.png", largura = 0.3, ancora = "sup_dir"))) &&
    grepl("fileInput|im1_arquivo", paste(as.character(ui_campo(ESPEC_CAMPOS$im1_arquivo, CFG0)), collapse = ""))
})

teste("o registro de uso grava linhas de texto com horário, respeita a opção que o desliga e gira o arquivo quando passa de 2 MB", {
  antigo <- .log_arq; tmp_log <- tempfile(fileext = ".log"); assign(".log_arq", tmp_log, envir = globalenv()); on.exit(assign(".log_arq", antigo, envir = globalenv()), add = TRUE)
  options(cinabro.sem_log = FALSE); registrar_log("linha de teste"); l1 <- readLines(tmp_log)
  options(cinabro.sem_log = TRUE); registrar_log("não deve aparecer"); l2 <- readLines(tmp_log); options(cinabro.sem_log = FALSE)
  cat(strrep("x", 2.1e6), file = tmp_log); registrar_log("depois de girar"); girou <- file.exists(paste0(tmp_log, ".antigo")) && file.size(tmp_log) < 1000
  options(cinabro.sem_log = TRUE)
  grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8} linha de teste$", l1) && length(l2) == 1 && girou })
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
  session$setInputs(idioma_pagina = "en")
  teste("servidor: com idioma_pagina = en, a tela do servidor (avisos e resumo dos dados) sai em inglês", {
    session$setInputs(quebra_ativar = TRUE, quebra_de = 450000, quebra_ate = 100000, atualizar = 20)
    h <- paste(as.character(output$avisos$html), collapse = ""); grepl("Something needs adjusting", h, fixed = TRUE) && !grepl("Algo precisa", h, fixed = TRUE) })
  session$setInputs(quebra_ativar = FALSE, idioma_pagina = "pt")
  session$setInputs(paleta_propria = "#112233, #445566, #778899", paleta_nome = "Teste", paleta_salvar = 1)
  teste("servidor: guardar a paleta própria cria 'salva:Teste' na lista e fica nos valores", identical(names(rv$paletas), "Teste") &&
        identical(rv$paletas$Teste, c("#112233", "#445566", "#778899")))
  session$setInputs(cores_paleta = "salva:Teste", atualizar = 11)
  teste("servidor: usar a paleta guardada monta o gráfico com as cores dela", is.null(rv$erro) && identical(rv$res$cfg$cores$personalizada, c("#112233", "#445566", "#778899")))
  session$setInputs(paleta_excluir = 1)
  teste("servidor: excluir a paleta guardada selecionada", length(rv$paletas) == 0)
  session$setInputs(cores_paleta = "cinabro", quebra_ativar = TRUE, quebra_sugerir = 1)
  teste("servidor: 'Achar o maior vazio' funciona sem erro (o resultado vai para os campos de/até)", is.null(rv$erro))
  session$setInputs(quebra_ativar = TRUE, quebra_de = 100000, quebra_ate = 450000, quebra_estilo = "continuo", atualizar = 2)
  teste("servidor: ligar a quebra muda o gráfico e aparece em 'o que você mudou'", "quebra_ativar" %in% rv$res$aplicado && is.null(rv$erro))
  session$setInputs(quebra_de = 450000, quebra_ate = 100000, atualizar = 3)
  teste("servidor: configuração impossível mostra o erro em português sem derrubar o app", !is.null(rv$erro) && grepl("de < ate", rv$erro))

  # ---- blocos 13 e 14, congelar, modelo e abas ----------------------------------------------------------------------------------
  session$setInputs(quebra_ativar = FALSE, exemplo = "ensaio_temperatura.csv"); session$setInputs(tipo_grafico = "pontos", colunas_y = c("Amostra A", "Amostra B"))
  session$setInputs(aj1_ativo = TRUE, aj1_serie = "Amostra A", aj1_tipo = "polinomial", aj1_grau = 3, aj1_banda = TRUE,
                    mk1_ativo = TRUE, mk1_serie = "Amostra B", mk1_preencher = TRUE,
                    cx1_ativo = TRUE, cx1_itens = c("media", "dp", "equacao", "r2", "anova"), cx1_sombra = TRUE,
                    fm1_ativo = TRUE, fm1_tipo = "poligono", fm1_vertices = "0.6,0.1; 0.9,0.1; 0.75,0.3", fm2_ativo = TRUE, fm2_texto = "m^{2}", atualizar = 30)
  teste("servidor: ajuste, traços, caixa de estatística e formas ligados na tela chegam ao gráfico sem erro", is.null(rv$erro) && length(rv$res$cfg$ajustes) == 1 &&
        length(rv$res$cfg$marcas_estatisticas) == 1 && length(rv$res$cfg$caixas_estatisticas) == 1 && length(rv$res$cfg$formas) == 2 && "formas" %in% rv$res$aplicado)
  session$setInputs(estat_testes = c("shapiro", "pearson"), estat_calcular = 1)
  teste("servidor: a tabela de resultados traz o resumo, o ajuste, os parâmetros e os testes", {
    r <- tabelas_estat(); nrow(r$descritiva) == 2 && nrow(r$ajustes) == 1 && nrow(r$parametros) == 4 && nrow(r$testes) == 4 })
  teste("servidor: a tabela de resultados é desenhada na tela", { h <- paste(as.character(output$estat_tabelas$html), collapse = ""); grepl("<table", h, fixed = TRUE) && grepl("Amostra A", h, fixed = TRUE) })
  session$setInputs(cong_cores = TRUE, cores_paleta = "okabe_ito", cong_legenda = FALSE)
  teste("servidor: o tic 'Congelar' vale para os campos do bloco (e só dele)", "cores_paleta" %in% ids_congelados() && !"tipo_grafico" %in% ids_congelados() && identical(congelados(), "cores"))
  txt <- modelo_json(); j <- ler_modelo(txt)
  teste("servidor: o modelo copiado é um JSON com valores, séries, paletas e blocos congelados, e dá para ler de volta", !is.null(j) && identical(j$valores$aj1_tipo, "polinomial") &&
        identical(j$congelados, "cores") && !is.null(j$series) && is.null(ler_modelo("isto não é um modelo")))
  teste("servidor: aplicar_config devolve quantos blocos congelados manteve e não falha", aplicar_config(j, respeitar = TRUE) == 1)
  if (requireNamespace("png", quietly = TRUE)) {
    f_fig <- tempfile(fileext = ".png"); png::writePNG(array(runif(30 * 60 * 4), c(30, 60, 4)), f_fig)
    rv$img[["im1_arquivo"]] <- list(nome = "logo.png", caminho = f_fig)
    session$setInputs(im1_ativo = TRUE, im1_largura = 0.3, atualizar = 40)
    teste("servidor: a figura anexada aparece no gráfico (cfg$imagens) e o código equivalente usa o nome do arquivo enviado", is.null(rv$erro) && length(rv$res$cfg$imagens) == 1 &&
          grepl('arquivo = "logo.png"', paste(gerar_codigo(vars_codigo()), collapse = ""), fixed = TRUE) && !"im1_arquivo" %in% names(modelo_lista()$valores))
  }
  ant <- rv$previa$arquivo; session$setInputs(atualizar = 39)
  teste("servidor: a prévia anterior é apagada quando a nova é desenhada", !is.null(ant) && !identical(ant, rv$previa$arquivo) && !file.exists(ant) && file.exists(rv$previa$arquivo))
  session$setInputs(rapido = list(acao = "ajuste", tipo = "exponencial", t = 1), palco_larg = 1000, atualizar = 41)
  teste("servidor: a faixa de ferramentas (clique rápido) e a largura do palco rodam sem erro", is.null(rv$erro) && identical(rv$palco_larg, 1000))
  session$setInputs(aba_nova = 1)
  teste("servidor: aba nova começa sem dados e mantém só o que estava congelado", length(rv$abas) == 2 && rv$aba == 2 && is.null(rv$dados) && is.null(rv$abas[[2]]$snap$valores$aj1_ativo) &&
        identical(rv$abas[[2]]$snap$valores$cores_paleta, "okabe_ito") && identical(rv$abas[[2]]$snap$cong, "cores"))
  session$setInputs(aba_ir = 1)
  teste("servidor: a figura anexada não passa para a aba nova (bloco não congelado) e volta com a aba 1", length(rv$abas[[2]]$snap$img) == 0 &&
        length(rv$img) == if (requireNamespace("png", quietly = TRUE)) 1 else 0)
  teste("servidor: voltar à aba 1 devolve os dados e a configuração dela", rv$aba == 1 && !is.null(rv$dados) && nrow(rv$dados) == 13 && identical(rv$abas[[2]]$snap$cong, "cores"))
  session$setInputs(aba_duplicar = 1)
  teste("servidor: duplicar a aba copia dados e configuração, com o nome '(cópia)'", length(rv$abas) == 3 && rv$aba == 3 && grepl("cópia", nome_aba(3)) && nrow(rv$dados) == 13)
  session$setInputs(aba_fechar = 3)
  teste("servidor: fechar a aba ativa volta para a anterior", length(rv$abas) == 2 && rv$aba == 2)
  session$setInputs(aba_nome_novo = "Meu gráfico", aba_nome_ok = 1)
  teste("servidor: renomear a aba", identical(nome_aba(rv$aba), "Meu gráfico"))
})
cat(sprintf("\n==== %d PASSOU / %d FALHOU ====\n", ok, falhas))
if (falhas) quit(status = 1)
