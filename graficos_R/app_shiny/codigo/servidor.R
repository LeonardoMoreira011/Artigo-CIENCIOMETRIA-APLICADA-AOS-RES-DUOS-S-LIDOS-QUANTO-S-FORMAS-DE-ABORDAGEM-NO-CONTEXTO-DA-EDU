# =============================================================================
#  app_shiny/codigo/servidor.R — o que acontece quando você mexe na tela
# =============================================================================

PRESETS <- list(
  publicacao = list(caixa_fechada = TRUE, ticks_espelhados = TRUE, grade_x = FALSE, grade_y = FALSE, linha_espessura_pt = 1.2,
                    simbolo_tamanho_pt = 5, painel_largura_cm = 8.5, painel_altura_cm = 6, dpi = 600, tamanho_texto_pt = 9,
                    x_ticks_direcao = "dentro", y_ticks_direcao = "dentro"),
  apresentacao = list(tamanho_texto_pt = 18, linha_espessura_pt = 2.5, simbolo_tamanho_pt = 10, grade_y = TRUE, grade_tipo = "dashed",
                      grade_opacidade = 0.3, dpi = 200, largura_cm = 24, altura_cm = 13.5, cores_paleta = "marca", legenda_escala = 1.2))

# Atualiza um campo da tela (qualquer tipo). valor = NULL volta ao inicial.
atualizar_campo <- function(session, campo, valor, cfg0, colunas = NULL) {
  id <- campo$id
  if (is.null(valor)) valor <- valor_inicial(campo, cfg0)
  switch(campo$tipo,
    num = , int = updateNumericInput(session, id, value = if (is.null(valor) || length(valor) != 1) NA else valor),
    txt = , vec = updateTextInput(session, id, value = paste(valor, collapse = ", ")),
    sel = , tri = updateSelectInput(session, id, selected = as.character(valor)),
    chk = updateCheckboxInput(session, id, value = isTRUE(valor)),
    cor = session$sendCustomMessage("set_cor", list(id = id, valor = as.character(valor %||% ""))),
    selmulti = updateSelectInput(session, id, selected = as.character(valor)),
    colx = updateSelectInput(session, id, selected = as.character(valor %||% "")),
    colsy = , colsy2 = updateSelectInput(session, id, selected = as.character(valor)))
}

# Sessões abertas: com gerador_encerrar_ao_fechar (atalho sem janela), o R termina quando a última aba fecha.
.sessoes <- new.env(); .sessoes$n <- 0

servidor <- function(input, output, session) {
  .sessoes$n <- .sessoes$n + 1
  session$onSessionEnded(function() {
    .sessoes$n <- .sessoes$n - 1
    if (isTRUE(getOption("gerador_encerrar_ao_fechar")))          # espera 6 s: recarregar a página não encerra o app
      later::later(function() if (.sessoes$n <= 0) shiny::stopApp(), 6)
  })
  rv <- reactiveValues(dados = NULL, nome = NULL, res = NULL, previa = NULL, erro = NULL, pend_series = NULL, geo = NULL)
  dir_dados <- file.path(raiz, "dados")

  # ---- dados -------------------------------------------------------------------------------------------------
  carregar <- function(caminho, nome) {
    op <- utils::modifyList(CFG0$dados, list(relatorio = FALSE))
    d <- tryCatch(suppressWarnings(ler_csv(caminho, op)), error = function(e) {
      rv$erro <- paste0("Não consegui ler o arquivo: ", conditionMessage(e)); NULL })
    if (is.null(d)) return(invisible())
    rv$dados <- d; rv$nome <- nome; rv$erro <- NULL
    cols <- names(d); num <- cols[vapply(d, is.numeric, NA)]
    updateSelectInput(session, "coluna_x", choices = c("(1ª coluna)" = "", stats::setNames(cols, cols)), selected = "")
    updateSelectInput(session, "colunas_y", choices = stats::setNames(num, num), selected = character(0))
    updateSelectInput(session, "y2_series", choices = stats::setNames(num, num), selected = character(0))
    updateSelectInput(session, "simbolos_ordem", selected = character(0))
  }
  observeEvent(input$arquivo, { carregar(input$arquivo$datapath, input$arquivo$name); updateSelectInput(session, "exemplo", selected = "") })
  observeEvent(input$exemplo, { if (nzchar(input$exemplo)) carregar(file.path(dir_dados, input$exemplo), input$exemplo) })

  output$resumo_dados <- renderUI({
    d <- rv$dados
    if (is.null(d)) return(div(class = "vazio", "Nenhum dado carregado ainda."))
    tipos <- vapply(d, function(v) if (is.numeric(v)) "número" else "texto", "")
    div(class = "resumo-dados",
        div(class = "chips", span(class = "chip chip-verde", rv$nome), span(class = "chip", paste(nrow(d), "linhas")), span(class = "chip", paste(ncol(d), "colunas"))),
        tags$table(class = "mini", tags$thead(tags$tr(lapply(names(d), function(n) tags$th(n)))),
                   tags$tbody(lapply(seq_len(min(5, nrow(d))), function(i) tags$tr(lapply(d[i, ], function(x) tags$td(format(x, digits = 6))))))))
  })

  # ---- séries (tabela por série) ------------------------------------------------------------------------------
  series_nomes <- reactive({
    d <- rv$dados; req(d)
    x <- input$coluna_x; if (is.null(x) || !nzchar(x)) x <- names(d)[1]
    num <- setdiff(names(d)[vapply(d, is.numeric, NA)], x)
    sel <- input$colunas_y
    if (length(sel)) sel else num
  })
  output$tabela_series <- renderUI({
    d <- rv$dados
    if (is.null(d)) return(div(class = "vazio", "Carregue os dados para editar cada série."))
    tp <- input$tipo_grafico %||% "linha_pontos"
    if (!tp %in% c("pontos", "linha", "linha_pontos", "area", "area_empilhada"))
      return(div(class = "vazio", "A edição série por série vale para gráficos de linha, pontos e área."))
    nomes <- isolate(series_nomes())
    div(class = "series", lapply(seq_along(nomes), function(i) ui_serie(i, nomes[i])))
  })
  series_df <- reactive({
    nomes <- series_nomes(); n <- length(nomes)
    g <- function(p, i, padrao) { v <- input[[paste0(p, i)]]; if (is.null(v) || (is.numeric(v) && is.na(v))) padrao else v }
    data.frame(nome = nomes,
               cor = vapply(seq_len(n), function(i) as.character(g("ser_cor_", i, "")), ""),
               forma = vapply(seq_len(n), function(i) as.character(g("ser_forma_", i, "")), ""),
               tamanho = vapply(seq_len(n), function(i) as.numeric(g("ser_tamanho_", i, NA_real_)), 0),
               linha = vapply(seq_len(n), function(i) as.numeric(g("ser_linha_", i, NA_real_)), 0),
               borda = vapply(seq_len(n), function(i) as.numeric(g("ser_borda_", i, NA_real_)), 0),
               legenda = vapply(seq_len(n), function(i) as.character(g("ser_legenda_", i, nomes[i])), ""),
               stringsAsFactors = FALSE)
  })

  # ---- do que está na tela às variáveis do painel -------------------------------------------------------------------
  valores <- reactive({ v <- lapply(names(ESPEC_CAMPOS), function(id) input[[id]]); names(v) <- names(ESPEC_CAMPOS)
                        v$simbolo_modo <- input$simbolo_modo; v })
  vars_atual <- reactive({
    s <- if (!is.null(rv$dados)) tryCatch(series_df(), error = function(e) NULL) else NULL
    montar_variaveis(valores(), CFG0, s)
  })
  vars_deb <- debounce(vars_atual, 700)

  calcular <- function() {
    if (is.null(rv$dados)) { rv$erro <- NULL; return(invisible()) }
    withProgress(message = "Montando o gráfico...", value = 0.4, {
      r <- construir_grafico(rv$dados, vars_atual(), CFG0)
      if (!is.null(r$erro)) { rv$erro <- r$erro; rv$res <- r; return(invisible()) }
      incProgress(0.3)
      p <- tryCatch(desenhar_previa(r$g, r$cfg, dpi = 130), error = function(e) { rv$erro <- conditionMessage(e); NULL })
      if (!is.null(p)) {
        rv$res <- r; rv$previa <- p; rv$erro <- NULL
        geo <- tryCatch(.geometria_legenda(r$g, r$cfg), error = function(e) NULL)   # onde está a legenda (caixa que se arrasta)
        rv$geo <- geo
        session$sendCustomMessage("legenda_geom", if (is.null(geo)) list(ok = FALSE)
                                  else list(ok = TRUE, painel = geo$painel, legenda = geo$legenda, pagina = geo$pagina))
      }
    })
  }
  observeEvent(vars_deb(), { if (isTRUE(input$auto) && !is.null(rv$dados)) calcular() }, ignoreInit = TRUE)
  observeEvent(rv$dados, { if (isTRUE(input$auto)) calcular() }, ignoreInit = TRUE, priority = -10)
  observeEvent(input$atualizar, calcular())

  # ---- prévia, avisos ------------------------------------------------------------------------------------------------
  output$previa <- renderImage({
    p <- rv$previa; req(p)
    list(src = p$arquivo, contentType = "image/png", alt = "Prévia do gráfico")
  }, deleteFile = FALSE)
  output$estado <- renderUI({
    if (is.null(rv$dados)) div(class = "vazio grande", tags$b("Comece pelos dados."), tags$p("Envie um CSV ou escolha um exemplo no bloco \"Seus dados\"; o gráfico aparece aqui."))
  })
  output$info_previa <- renderUI({
    r <- rv$res; p <- rv$previa; if (is.null(r) || is.null(r$cfg) || is.null(p)) return(NULL)
    div(class = "chips", span(class = "chip", sprintf("Página %.1f × %.1f cm", p$larg_px / 130 * 2.54, p$alt_px / 130 * 2.54)),
        if (!is.null(r$cfg$caixa$painel_largura_cm)) span(class = "chip chip-verde", sprintf("Caixa fixa %.1f × %.1f cm", r$cfg$caixa$painel_largura_cm, r$cfg$caixa$painel_altura_cm %||% NA)),
        span(class = "chip", paste("Fonte:", r$cfg$texto$fonte)))
  })
  rotulo_de <- function(id) { c <- ESPEC_CAMPOS[[id]]; if (is.null(c)) id else c$rotulo }
  output$avisos <- renderUI({
    r <- rv$res
    tagList(
      if (!is.null(rv$erro)) div(class = "alerta alerta-erro", tags$b("Algo precisa de ajuste: "), rv$erro),
      if (!is.null(r) && length(r$avisos)) div(class = "alerta alerta-aviso", tags$b("Avisos"), tags$ul(lapply(r$avisos, tags$li))),
      if (!is.null(r) && length(r$aplicado)) div(class = "mudou", tags$b("O que você mudou: "),
                                                 lapply(r$aplicado, function(n) span(class = "chip chip-mudou", rotulo_de(n)))))
  })

  # ---- baixar ------------------------------------------------------------------------------------------------------------
  nome_base <- reactive({
    n <- trimws(input$nome_arquivo %||% ""); if (nzchar(n)) return(gsub("[^A-Za-z0-9_.-]+", "_", n))
    paste0(tools::file_path_sans_ext(rv$nome %||% "grafico"), "_grafico")
  })
  baixar <- function(ext) downloadHandler(
    filename = function() paste0(nome_base(), ".", if (ext == "jpeg") "jpg" else ext),
    content = function(file) {
      validate(need(!is.null(rv$dados), "Carregue os dados primeiro."))
      r <- construir_grafico(rv$dados, vars_atual(), CFG0, preview = FALSE)
      if (!is.null(r$erro)) stop(r$erro)
      cfg <- r$cfg; cfg$exportacao$pasta <- tempfile("saida_"); cfg$exportacao$formatos <- ext
      cfg$exportacao$nome_arquivo <- "grafico_app"; cfg$exportacao$carimbo_data <- FALSE; cfg$exportacao$sobrescrever <- TRUE
      arqs <- suppressMessages(suppressWarnings(salvar(r$g, cfg)))
      file.copy(arqs[1], file, overwrite = TRUE)
    })
  for (ext in c("png", "tiff", "jpeg", "svg", "pdf")) local({ e <- ext; output[[paste0("baixar_", e)]] <- baixar(e) })

  # ---- código equivalente ----------------------------------------------------------------------------------------
  output$codigo <- renderText(gerar_codigo(vars_atual()))
  output$baixar_codigo <- downloadHandler(filename = function() paste0(nome_base(), ".R"),
    content = function(file) writeLines(gerar_codigo(vars_atual(), arquivo_csv = rv$nome, script_completo = TRUE), file, useBytes = TRUE))

  # ---- salvar / carregar configuração -------------------------------------------------------------------------------
  output$salvar_cfg <- downloadHandler(filename = function() paste0(nome_base(), "_configuracao.json"),
    content = function(file) {
      v <- valores(); v <- v[!vapply(v, is.null, NA)]
      s <- if (!is.null(rv$dados)) series_df() else NULL
      writeLines(jsonlite::toJSON(list(versao = 1, dados = rv$nome, valores = v, series = s), auto_unbox = TRUE, null = "null", na = "null",
                                  pretty = TRUE), file, useBytes = TRUE)
    })
  observeEvent(input$carregar_cfg, {
    j <- tryCatch(jsonlite::fromJSON(input$carregar_cfg$datapath, simplifyVector = TRUE), error = function(e) NULL)
    if (is.null(j) || is.null(j$valores)) { showNotification("Arquivo de configuração inválido.", type = "error"); return() }
    for (id in names(ESPEC_CAMPOS)) if (!is.null(j$valores[[id]])) atualizar_campo(session, ESPEC_CAMPOS[[id]], j$valores[[id]], CFG0)
    if (!is.null(j$valores$simbolo_modo)) updateSelectInput(session, "simbolo_modo", selected = j$valores$simbolo_modo)
    if (!is.null(j$series)) rv$pend_series <- as.data.frame(j$series)
    showNotification("Configuração carregada.", type = "message")
  })
  observe({                         # séries salvas: aplica quando a tabela da tela já existir
    ps <- rv$pend_series; req(ps, !is.null(input$ser_legenda_1))
    isolate({
      for (i in seq_len(min(nrow(ps), length(series_nomes())))) {
        session$sendCustomMessage("set_cor", list(id = paste0("ser_cor_", i), valor = as.character(ps$cor[i] %||% "")))
        updateSelectInput(session, paste0("ser_forma_", i), selected = as.character(ps$forma[i] %||% ""))
        for (k in c("tamanho", "linha", "borda")) updateNumericInput(session, paste0("ser_", k, "_", i), value = suppressWarnings(as.numeric(ps[[k]][i])))
        updateTextInput(session, paste0("ser_legenda_", i), value = as.character(ps$legenda[i] %||% ps$nome[i]))
      }
      rv$pend_series <- NULL
    })
  })

  # ---- legenda arrastada / redimensionada na prévia --------------------------------------------------------------------------
  observeEvent(input$legenda_arrastada, {
    d <- input$legenda_arrastada; geo <- rv$geo; req(geo, d)
    lwf <- geo$legenda[3] / geo$painel[3]; lhf <- geo$legenda[4] / geo$painel[4]
    x <- min(max(d$esq / max(1 - lwf, 1e-6), 0), 1); y <- min(max(d$base / max(1 - lhf, 1e-6), 0), 1)
    updateSelectInput(session, "legenda_posicao", selected = "dentro")
    updateSelectInput(session, "legenda_canto", selected = "")                 # posição manual: a âncora volta ao automático
    updateNumericInput(session, "legenda_x", value = round(x, 3)); updateNumericInput(session, "legenda_y", value = round(y, 3))
    updateNumericInput(session, "legenda_x_dados", value = NA); updateNumericInput(session, "legenda_y_dados", value = NA)
  })
  observeEvent(input$legenda_redimensionada, {
    d <- input$legenda_redimensionada; geo <- rv$geo; req(geo, d)
    updateNumericInput(session, "legenda_largura_pt", value = max(round(d$largura * geo$pagina[1] * 72), 10))
  })

  # ---- adicionar fonte de arquivo (systemfonts) ----------------------------------------------------------------------------
  observeEvent(input$fonte_arquivo, {
    f <- input$fonte_arquivo; req(nrow(f) > 0)
    base <- tools::file_path_sans_ext(f$name)
    familia <- trimws(input$fonte_nome %||% "")
    if (!nzchar(familia)) {
      familia <- sub("[-_ ]?(Regular|Bold|Italic|BoldItalic|Oblique|Light|Medium|SemiBold|Black|Thin|ExtraBold).*$", "", base[1], ignore.case = TRUE)
      familia <- trimws(gsub("([a-z])([A-Z])", "\\1 \\2", familia))
    }
    pasta <- file.path(tempdir(), "fontes_app"); dir.create(pasta, showWarnings = FALSE)
    destino <- file.path(pasta, f$name); file.copy(f$datapath, destino, overwrite = TRUE)
    n <- tolower(base); neg <- grepl("bold|black|heavy", n); ita <- grepl("italic|oblique", n)
    pega <- function(i) if (any(i)) destino[which(i)[1]] else NA_character_
    arq <- c(regular = pega(!neg & !ita), bold = pega(neg & !ita), italic = pega(!neg & ita), bolditalic = pega(neg & ita))
    if (is.na(arq[["regular"]])) arq[["regular"]] <- destino[1]
    ok <- tryCatch({ registrar_fonte(familia, arquivos = arq, silencioso = TRUE); TRUE },
                   error = function(e) { showNotification(paste("Não consegui adicionar a fonte:", conditionMessage(e)), type = "error"); FALSE })
    if (ok) {
      updateSelectizeInput(session, "fonte", choices = opcoes_fontes(), selected = familia, server = FALSE)
      showNotification(paste0("Fonte \"", familia, "\" adicionada e selecionada."), type = "message")
    }
  })

  # ---- estilos prontos, restaurar, guia ------------------------------------------------------------------------------------
  restaurar_campos <- function() {
    for (id in names(ESPEC_CAMPOS)) if (!ESPEC_CAMPOS[[id]]$tipo %in% c("colx", "colsy", "colsy2")) atualizar_campo(session, ESPEC_CAMPOS[[id]], NULL, CFG0)
    updateSelectInput(session, "simbolo_modo", selected = "variar")
  }
  observeEvent(input$restaurar, { restaurar_campos(); updateSelectInput(session, "estilo", selected = ""); showNotification("Tudo voltou ao padrão do template.") })
  observeEvent(input$estilo, {
    if (!nzchar(input$estilo)) return()
    restaurar_campos()
    p <- PRESETS[[input$estilo]]
    for (id in names(p)) if (!is.null(ESPEC_CAMPOS[[id]])) atualizar_campo(session, ESPEC_CAMPOS[[id]], p[[id]], CFG0)
  }, ignoreInit = TRUE)
  observeEvent(input$guia, showModal(guia_rapido()))
  observeEvent(TRUE, { if (!isTRUE(getOption("gerador_sem_guia"))) showModal(guia_rapido()) }, once = TRUE)
}
