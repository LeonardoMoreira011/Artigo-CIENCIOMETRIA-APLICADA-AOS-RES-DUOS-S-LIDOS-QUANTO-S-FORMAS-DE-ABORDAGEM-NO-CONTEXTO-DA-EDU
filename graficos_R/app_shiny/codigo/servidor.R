# =============================================================================
#  app_shiny/codigo/servidor.R — o que acontece quando você mexe na tela
# =============================================================================

PRESETS <- list(
  publicacao = list(caixa_fechada = TRUE, ticks_espelhados = TRUE, grade_x = FALSE, grade_y = FALSE, linha_espessura_pt = 1.2,
                    simbolo_tamanho_pt = 5, painel_largura_cm = 8.5, painel_altura_cm = 6, dpi = 600, tamanho_texto_pt = 9,
                    x_ticks_direcao = "dentro", y_ticks_direcao = "dentro"),
  apresentacao = list(tamanho_texto_pt = 18, linha_espessura_pt = 2.5, simbolo_tamanho_pt = 10, grade_y = TRUE, grade_tipo = "dashed",
                      grade_opacidade = 0.3, dpi = 200, largura_cm = 24, altura_cm = 13.5, cores_paleta = "cinabro", legenda_escala = 1.2))

# Os ids dos campos de cada bloco (para "congelar" um bloco inteiro).
BLOCO_IDS <- stats::setNames(lapply(ESPEC, function(b) vapply(c(b$campos, unlist(lapply(b$grupos, function(g) g$campos), recursive = FALSE)), function(c) c$id, "")),
                             vapply(ESPEC, function(b) b$id, ""))
IDS_ARQUIVO <- names(ESPEC_CAMPOS)[vapply(ESPEC_CAMPOS, function(c) identical(c$tipo, "arquivo"), NA)]
IDS_SERIE_SEL <- c(unlist(lapply(c("ajustes", "marcas_estatisticas"), function(g) paste0(SLOTS[[g]]$pref, seq_len(SLOTS[[g]]$n), "_serie"))))
IDS_SERIES_MULTI <- paste0(SLOTS$caixas_estatisticas$pref, seq_len(SLOTS$caixas_estatisticas$n), "_series")

# Atualiza um campo da tela (qualquer tipo). valor = NULL volta ao inicial.
atualizar_campo <- function(session, campo, valor, cfg0, colunas = NULL) {
  id <- campo$id
  if (is.null(valor)) valor <- valor_inicial(campo, cfg0)
  if (identical(id, "cores_paleta") && length(valor) == 1 && as.character(valor) %in% names(.PALETAS_ANTIGAS)) valor <- .PALETAS_ANTIGAS[[as.character(valor)]]   # paleta que saiu da lista: vale a mais parecida
  switch(campo$tipo,
    num = , int = updateNumericInput(session, id, value = if (is.null(valor) || length(valor) != 1) NA else valor),
    txt = , vec = updateTextInput(session, id, value = paste(valor, collapse = ", ")),
    area = updateTextAreaInput(session, id, value = paste(valor, collapse = "\n")),
    sel = , tri = , selbusca = updateSelectInput(session, id, selected = as.character(valor)),
    chk = updateCheckboxInput(session, id, value = isTRUE(valor)),
    cor = session$sendCustomMessage("set_cor", list(id = id, valor = as.character(valor %||% ""))),
    selmulti = updateSelectInput(session, id, selected = as.character(valor)),
    chkgrupo = updateCheckboxGroupInput(session, id, selected = as.character(valor)),
    colx = updateSelectInput(session, id, selected = as.character(valor %||% "")),
    colsy = , colsy2 = updateSelectInput(session, id, selected = as.character(valor)),
    arquivo = NULL)               # a figura anexada é guardada à parte (rv$img), não volta por aqui
}

# Registro de uso (para descobrir por que o app ficou lento ou caiu): %LOCALAPPDATA%/Cinabro/log/app.log (no Windows). Só texto,
# sem dados: horário, tempos de cada gráfico, erros e quando as abas abrem e fecham. Passa de 2 MB, vira app.log.antigo.
.log_arq <- local({
  base <- Sys.getenv("LOCALAPPDATA"); if (!nzchar(base)) base <- file.path(Sys.getenv("HOME"), ".local", "share")
  d <- file.path(base, "Cinabro", "log")
  ok <- tryCatch({ dir.create(d, recursive = TRUE, showWarnings = FALSE); dir.exists(d) }, error = function(e) FALSE)
  if (ok) file.path(d, "app.log") else NULL
})
# Salvamento automático: %LOCALAPPDATA%/Cinabro/sessao (ultima.json = configuração; dados_atual.csv = o CSV). Ao reabrir, o Cinabro oferece retomar.
dir_sessao <- function() {
  if (isTRUE(getOption("cinabro.sem_sessao"))) return(NULL)
  base <- Sys.getenv("LOCALAPPDATA"); if (!nzchar(base)) base <- file.path(Sys.getenv("HOME"), ".local", "share")
  d <- file.path(base, "Cinabro", "sessao")
  if (tryCatch({ dir.create(d, recursive = TRUE, showWarnings = FALSE); dir.exists(d) }, error = function(e) FALSE)) d else NULL
}
registrar_log <- function(...) {
  if (is.null(.log_arq) || isTRUE(getOption("cinabro.sem_log"))) return(invisible())
  tryCatch({
    if (file.exists(.log_arq) && file.size(.log_arq) > 2e6) file.rename(.log_arq, paste0(.log_arq, ".antigo"))
    cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " ", paste0(...), "\n", file = .log_arq, append = TRUE, sep = "")
  }, error = function(e) NULL)
}

# Sessões abertas: com gerador_encerrar_ao_fechar (atalho sem janela), o R termina quando a última aba fecha E passam .GRACA_ENCERRAR segundos
# sem nenhuma aba aberta. A espera era de 6 s: o computador suspender, o navegador "dormir" a aba ou o antivírus cortar a conexão por um instante
# bastava para o R sumir e a tela ficar cinza. O botão "Sair" (cabeçalho) encerra na hora.
.GRACA_ENCERRAR <- 600
.sessoes <- new.env(); .sessoes$n <- 0; .sessoes$visto <- FALSE
# Se o R foi aberto pelo atalho (sem janela) e o navegador nunca chegou a conectar (ex.: foi bloqueado), não deixa o R escondido para sempre.
if (isTRUE(getOption("gerador_encerrar_ao_fechar")) && requireNamespace("later", quietly = TRUE))
  later::later(function() if (!.sessoes$visto && .sessoes$n <= 0) shiny::stopApp(), 180)

servidor <- function(input, output, session) {
  .sessoes$n <- .sessoes$n + 1; .sessoes$visto <- TRUE
  registrar_log("sessão aberta (", .sessoes$n, " aberta(s) agora; R ", getRversion(), ", shiny ", utils::packageVersion("shiny"), ", ggplot2 ", utils::packageVersion("ggplot2"), ")")
  session$onSessionEnded(function() {
    isolate(salvar_sessao())                                          # o que estava na tela fica guardado para retomar
    .sessoes$n <- .sessoes$n - 1
    registrar_log("sessão fechada (", .sessoes$n, " aberta(s) agora)")
    if (isTRUE(getOption("gerador_encerrar_ao_fechar")))          # espera 10 min: recarregar a página, suspender o PC ou uma queda curta não encerram o app
      later::later(function() if (.sessoes$n <= 0) shiny::stopApp(), .GRACA_ENCERRAR)
  })
  observeEvent(input$sair, {                                        # botão "Sair": encerra o R na hora
    registrar_log("botão Sair")
    session$sendCustomMessage("adeus", list())
    later::later(function() shiny::stopApp(), 1.5)
  })
  rv <- reactiveValues(dados = NULL, nome = NULL, res = NULL, previa = NULL, erro = NULL, pend_series = NULL, geo = NULL,
                       paletas = list(), cartao_novo = NULL, pend_calc = FALSE, img = list(), palco_larg = NULL, palco_usado = NULL, bruto = NULL, abas = list(list(nome = NULL, snap = NULL)), aba = 1L, est = NULL)
  dir_dados <- file.path(raiz, "dados")
  # Cartões sob demanda: a tela nasce sem cartões de ajuste, traços, caixa, forma e figura; cada um é montado (insertUI) quando o usuário adiciona
  # ou quando uma configuração/aba guardada precisa dele. 'criados' guarda os que já existem na tela desta sessão.
  criados <- new.env(); criados$ids <- character(0); criados$novos <- character(0)
  abrir_cartao <- function(slot, k) {
    chave <- paste0(SLOTS[[slot]]$pref, k)
    if (chave %in% criados$ids) return(invisible(FALSE))
    ok <- tryCatch({ insertUI(selector = paste0("#slot-", slot), where = "beforeEnd", ui = UI(ui_cartao(slot, k, CFG0)), immediate = TRUE, session = session); TRUE }, error = function(e) FALSE)
    if (ok) { criados$ids <- c(criados$ids, chave); criados$novos <- c(criados$novos, chave); rv$cartao_novo <- as.numeric(Sys.time()) }
    invisible(ok)
  }
  garantir_cartoes <- function(valores) for (slot in names(SLOTS)) for (k in seq_len(SLOTS[[slot]]$n))
    if (isTRUE(valores[[paste0(SLOTS[[slot]]$pref, k, "_ativo")]])) abrir_cartao(slot, k)
  # idioma da página (vem do endereço, ?idioma=en) e atalhos para traduzir o que o servidor escreve na tela
  idioma <- reactive("pt")                                 # só português (inglês e espanhol arquivados); antes: input$idioma_pagina %||% "pt"
  T <- function(x) tr(x, idioma())                         # um texto
  TF <- function(molde, ...) trf(molde, ..., idioma = idioma())   # um molde com %s / %.1f
  UI <- function(x) traduzir_html(x, idioma())             # um pedaço de tela

  # ---- dados -------------------------------------------------------------------------------------------------
  carregar <- function(caminho, nome) {
    op <- utils::modifyList(CFG0$dados, list(relatorio = FALSE))
    d <- tryCatch(suppressWarnings(com_idioma(idioma(), ler_csv(caminho, op))), error = function(e) {
      rv$erro <- paste0(T("Não consegui ler o arquivo: "), conditionMessage(e)); NULL })
    if (is.null(d)) return(invisible())
    rv$dados <- d; rv$nome <- nome; rv$erro <- NULL
    rv$bruto <- guardar_bruto(caminho)
    definir_colunas(d)
    updateSelectInput(session, "simbolos_ordem", selected = character(0))
  }
  # as listas de colunas (X, Y, Y2) a partir da tabela; 'sel' = valores a marcar (ao trocar de aba)
  definir_colunas <- function(d, sel = NULL) {
    if (is.null(d)) { cols <- character(0); num <- character(0) } else { cols <- names(d); num <- cols[vapply(d, is.numeric, NA)] }
    x <- sel$coluna_x; x <- if (is.null(x) || !nzchar(x) || !x %in% cols) "" else x
    xr <- if (nzchar(x)) x else cols[1]
    num <- setdiff(num, xr)
    updateSelectInput(session, "coluna_x", choices = stats::setNames(c("", cols), c(T("(1ª coluna)"), cols)), selected = x)
    updateSelectizeInput(session, "colunas_y", choices = stats::setNames(num, num), selected = intersect(as.character(unlist(sel$colunas_y)), num))
    updateSelectizeInput(session, "y2_series", choices = stats::setNames(num, num), selected = intersect(as.character(unlist(sel$y2_series)), num))
    updateSelectizeInput(session, "colunas_erro", choices = stats::setNames(num, num), selected = intersect(as.character(unlist(sel$colunas_erro)), num))
    for (id in c("multi_variaveis", "multi_ambientais"))      # PCA/CA/CCA: quais colunas são variáveis e quais são ambientais
      updateSelectizeInput(session, id, choices = stats::setNames(num, num), selected = intersect(as.character(unlist(sel[[id]])), num))
    g <- sel$coluna_grupo; g <- if (is.null(g) || !nzchar(g) || !g %in% cols) "" else g
    updateSelectInput(session, "coluna_grupo", choices = stats::setNames(c("", cols), c(T("(sem grupos)"), cols)), selected = g)
  }
  # a coluna do eixo X não aparece nas listas de séries (Y e Y2)
  observeEvent(input$coluna_x, {
    d <- rv$dados; req(d)
    x <- input$coluna_x; if (is.null(x) || !nzchar(x)) x <- names(d)[1]
    num <- setdiff(names(d)[vapply(d, is.numeric, NA)], x)
    for (id in c("colunas_y", "y2_series", "colunas_erro", "multi_variaveis", "multi_ambientais"))
      updateSelectizeInput(session, id, choices = stats::setNames(num, num), selected = intersect(isolate(input[[id]]), num))
  }, ignoreInit = TRUE)
  observeEvent(input$arquivo, { carregar(input$arquivo$datapath, input$arquivo$name); updateSelectInput(session, "exemplo", selected = "") })
  observeEvent(input$exemplo, { if (nzchar(input$exemplo)) carregar(file.path(dir_dados, input$exemplo), input$exemplo) })

  output$resumo_dados <- renderUI({
    d <- rv$dados
    if (is.null(d)) return(UI(div(class = "vazio", "Nenhum dado carregado ainda.")))
    div(class = "resumo-dados",
        div(class = "chips", span(class = "chip chip-verde", rv$nome), span(class = "chip", paste(nrow(d), T("linhas"))), span(class = "chip", paste(ncol(d), T("colunas")))),
        tags$table(class = "mini", tags$thead(tags$tr(lapply(names(d), function(n) tags$th(n)))),
                   tags$tbody(lapply(seq_len(min(5, nrow(d))), function(i) tags$tr(lapply(d[i, ], function(x) tags$td(format(x, digits = 6))))))))
  })

  # ---- paletas: desenho da escolhida, editor próprio, paletas guardadas (no navegador) ------------------------------------------
  cores_da_paleta <- function(nome, n = 10) {
    nome <- nome %||% "cinabro"
    if (identical(nome, "propria")) return(ler_cores_texto(input$paleta_propria))
    if (startsWith(nome, "salva:")) return(as.character(rv$paletas[[sub("^salva:", "", nome)]]))
    tryCatch(.paleta(nome, n, CFG0$cores), error = function(e) character(0))
  }
  output$previa_paleta <- renderUI({
    nome <- input$cores_paleta %||% "cinabro"
    n <- if (!is.null(rv$dados)) min(max(length(series_nomes_seguro()), 3), 14) else 10
    cores <- cores_da_paleta(nome, n)
    if (!length(cores)) return(UI(div(class = "paleta-previa vazio", "(sem cores: escreva os códigos no editor abaixo)")))
    div(class = "paleta-previa", lapply(cores, function(h) span(class = "paleta-cor", style = paste0("background:", h), title = h)))
  })
  atualizar_lista_paletas <- function(escolher = NULL) {
    updateSelectizeInput(session, "cores_paleta", choices = tr_nomes(opcoes_paletas(names(rv$paletas)), idioma()),
                         selected = escolher %||% isolate(input$cores_paleta) %||% "cinabro")
    session$sendCustomMessage("guardar_paletas", as.character(jsonlite::toJSON(rv$paletas, auto_unbox = FALSE)))
  }
  observeEvent(input$paletas_do_navegador, {            # o navegador envia o que estava guardado
    p <- input$paletas_do_navegador
    if (is.list(p) && length(p)) {
      rv$paletas <- lapply(p, function(x) as.character(unlist(x)))
      updateSelectizeInput(session, "cores_paleta", choices = tr_nomes(opcoes_paletas(names(rv$paletas)), idioma()), selected = isolate(input$cores_paleta) %||% "cinabro")
    }
  }, once = TRUE)
  observeEvent(input$paleta_copiar, {
    cores <- cores_da_paleta(input$cores_paleta, 8)
    if (length(cores)) updateTextAreaInput(session, "paleta_propria", value = paste(cores, collapse = ", "))
  })
  observeEvent(input$paleta_salvar, {
    nome <- trimws(input$paleta_nome %||% ""); cores <- ler_cores_texto(input$paleta_propria)
    if (!nzchar(nome)) return(showNotification(T("Dê um nome para guardar a paleta."), type = "warning"))
    if (!length(cores)) return(showNotification(T("Escreva pelo menos uma cor no editor."), type = "warning"))
    rv$paletas[[nome]] <- cores
    atualizar_lista_paletas(paste0("salva:", nome))
    showNotification(TF("Paleta \"%s\" guardada.", nome), type = "message")
  })
  observeEvent(input$paleta_excluir, {
    sel <- input$cores_paleta %||% ""
    if (!startsWith(sel, "salva:")) return(showNotification(T("Escolha, na lista de paletas, uma das suas paletas guardadas para excluir."), type = "warning"))
    rv$paletas[[sub("^salva:", "", sel)]] <- NULL
    atualizar_lista_paletas("cinabro")
  })

  # ---- séries (tabela por série) ------------------------------------------------------------------------------
  series_nomes <- reactive({
    d <- rv$dados; req(d)
    x <- input$coluna_x; if (is.null(x) || !nzchar(x)) x <- names(d)[1]
    num <- setdiff(names(d)[vapply(d, is.numeric, NA)], x)
    err <- input$colunas_erro                              # coluna de erro não é série
    sel <- setdiff(input$colunas_y, err); num <- setdiff(num, err)
    if (length(sel)) sel else num
  })
  series_nomes_seguro <- function() tryCatch(series_nomes(), error = function(e) character(0))
  nomes_chave <- reactiveVal(character(0))                 # a tabela de séries só é refeita quando a LISTA de séries muda
  observe({ n <- series_nomes_seguro(); if (!identical(n, isolate(nomes_chave()))) nomes_chave(n) })
  output$tabela_series <- renderUI({
    nomes_chave(); d <- rv$dados
    if (is.null(d)) return(UI(div(class = "vazio", "Carregue os dados para editar cada série.")))
    tp <- input$tipo_grafico %||% "linha_pontos"
    if (!tp %in% c("pontos", "linha", "linha_pontos", "area", "area_empilhada"))
      return(UI(div(class = "vazio", "A edição série por série vale para gráficos de linha, pontos e área.")))
    nomes <- isolate(series_nomes())
    UI(div(class = "series", lapply(seq_along(nomes), function(i) ui_serie(i, nomes[i]))))
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
               erro = vapply(seq_len(n), function(i) { e <- input$colunas_erro; if (i <= length(e)) as.character(e[i]) else "" }, ""),   # a i-ésima coluna de erro vale para a i-ésima série
               stringsAsFactors = FALSE)
  })

  # as listas "Série" dos cartões de análise acompanham as séries do gráfico (e um cartão novo recebe a lista na hora em que nasce)
  atualizar_series_cartoes <- function(ids_sel = IDS_SERIE_SEL, ids_multi = IDS_SERIES_MULTI) {
    nomes <- unique(c(series_nomes_seguro(), input$y2_series))
    for (id in ids_sel) updateSelectInput(session, id, choices = c(tr_nomes(.SERIES_TODAS, idioma()), stats::setNames(nomes, nomes)), selected = isolate(input[[id]]) %||% "todas")
    for (id in ids_multi) updateSelectizeInput(session, id, choices = stats::setNames(nomes, nomes), selected = intersect(isolate(input[[id]]), nomes))
  }
  observe(atualizar_series_cartoes())
  observeEvent(rv$cartao_novo, isolate({
    for (k in criados$novos) atualizar_series_cartoes(grep(paste0("^", k, "_"), IDS_SERIE_SEL, value = TRUE), grep(paste0("^", k, "_"), IDS_SERIES_MULTI, value = TRUE))
    criados$novos <- character(0)
  }), ignoreNULL = TRUE)

  # ---- do que está na tela às variáveis do painel -------------------------------------------------------------------
  valores <- reactive({ v <- lapply(names(ESPEC_CAMPOS), function(id) input[[id]]); names(v) <- names(ESPEC_CAMPOS)
                        for (id in IDS_ARQUIVO) v[id] <- list(rv$img[[id]]$caminho)       # figuras anexadas: o caminho da cópia desta sessão
                        v$simbolo_modo <- input$simbolo_modo
                        v$.paleta_propria <- input$paleta_propria; v$.paletas_salvas <- rv$paletas; v })
  vars_atual <- reactive({
    s <- if (!is.null(rv$dados)) tryCatch(series_df(), error = function(e) NULL) else NULL
    v <- montar_variaveis(valores(), CFG0, s)
    if (idioma() != "pt") v$idioma <- idioma()               # o idioma entra no código equivalente (idioma <- "en")
    v
  })
  vars_deb <- debounce(vars_atual, 700)

  st <- new.env(); st$ate <- Sys.time() - 1                 # troca de aba em andamento: espera as telas serem atualizadas antes de montar
  calcular <- function() {
    if (Sys.time() < st$ate) { rv$pend_calc <- TRUE; return(invisible()) }
    if (is.null(rv$dados)) { rv$erro <- NULL; return(invisible()) }
    t_ini <- Sys.time()
    withProgress(message = T("Montando o gráfico..."), value = 0.4, {
      r <- construir_grafico(rv$dados, vars_atual(), CFG0, idioma = idioma())
      t_mont <- as.numeric(difftime(Sys.time(), t_ini, units = "secs"))
      if (!is.null(r$erro)) { rv$erro <- r$erro; rv$res <- r; registrar_log("gráfico com erro (", sprintf("%.2f", t_mont), " s): ", substr(r$erro, 1, 200)); return(invisible()) }
      incProgress(0.3)
      prep <- tryCatch(.preparar_saida(r$g, r$cfg), error = function(e) NULL)                # o gráfico é montado uma vez e serve ao desenho e às medidas
      p <- tryCatch(desenhar_previa(r$g, r$cfg, dpi = 130, alvo_px = if (!is.null(rv$palco_larg)) rv$palco_larg - 30, prep = prep), error = function(e) { rv$erro <- conditionMessage(e); NULL })
      if (!is.null(p)) rv$palco_usado <- rv$palco_larg
      registrar_log("gráfico: montar ", sprintf("%.2f", t_mont), " s, total ", sprintf("%.2f", as.numeric(difftime(Sys.time(), t_ini, units = "secs"))),
                    " s; campos em uso: ", paste(names(vars_atual()), collapse = ","), "; memória do R ", round(sum(gc()[, 2])), " MB; pasta temporária ",
                    length(list.files(tempdir(), recursive = TRUE)), " arquivos")
      if (!is.null(p)) {
        if (!is.null(rv$previa$arquivo)) unlink(rv$previa$arquivo)          # a prévia anterior não fica acumulando na pasta temporária
        rv$res <- r; rv$previa <- p; rv$erro <- NULL
        geo <- tryCatch(.geometria_legenda(r$g, r$cfg, prep), error = function(e) NULL)   # onde está a legenda (caixa que se arrasta)
        rv$geo <- geo
        zonas <- tryCatch(.geometria_zonas(r$g, r$cfg, prep), error = function(e) NULL)       # títulos clicáveis sobre a prévia
        caixas <- tryCatch(.geometria_caixas(r$g, r$cfg, prep), error = function(e) NULL)     # figuras, textos, formas e caixas de estatística que se movem
        session$sendCustomMessage("legenda_geom", if (is.null(geo)) list(ok = FALSE, zonas = zonas, caixas = caixas)
                                  else list(ok = TRUE, painel = geo$painel, legenda = geo$legenda, pagina = geo$pagina, zonas = zonas, caixas = caixas))
      }
    })
  }
  observe({ req(isTRUE(rv$pend_calc)); invalidateLater(400); isolate(if (Sys.time() >= st$ate) { rv$pend_calc <- FALSE; if (isTRUE(input$auto)) calcular() }) })
  observeEvent(vars_deb(), { if (isTRUE(input$auto) && !is.null(rv$dados)) calcular() }, ignoreInit = TRUE)
  observeEvent(rv$dados, { if (isTRUE(input$auto)) calcular() }, ignoreInit = TRUE, priority = -10)
  observeEvent(input$atualizar, calcular())

  # ---- prévia, avisos ------------------------------------------------------------------------------------------------
  output$previa <- renderImage({
    p <- rv$previa; req(p)
    list(src = p$arquivo, contentType = "image/png", alt = T("Prévia do gráfico"))
  }, deleteFile = FALSE)
  output$estado <- renderUI({
    if (is.null(rv$dados)) UI(div(class = "vazio grande", tags$b("Comece pelos dados."), tags$p("Envie um CSV ou escolha um exemplo no painel Dados; o gráfico aparece aqui.")))
  })
  output$info_previa <- renderUI({
    r <- rv$res; p <- rv$previa; if (is.null(r) || is.null(r$cfg) || is.null(p)) return(NULL)
    div(class = "chips", span(class = "chip", TF("Página %.1f × %.1f cm", p$larg_px / (p$dpi %||% 130) * 2.54, p$alt_px / (p$dpi %||% 130) * 2.54)),
        if (!is.null(r$cfg$caixa$painel_largura_cm)) span(class = "chip chip-verde", TF("Caixa fixa %.1f × %.1f cm", r$cfg$caixa$painel_largura_cm, r$cfg$caixa$painel_altura_cm %||% NA)),
        if (!is.null(r$decimado)) span(class = "chip chip-aviso", title = T("Para a prévia ficar rápida, só uma amostra das linhas é desenhada (os picos e vales ficam). O arquivo baixado usa todas as linhas."),
                                       TF("Prévia simplificada: %s de %s linhas", format(r$decimado[["para"]], big.mark = ".", decimal.mark = ","), format(r$decimado[["de"]], big.mark = ".", decimal.mark = ","))),
        span(class = "chip", paste(T("Fonte:"), r$cfg$texto$fonte)))
  })
  derivados <- c(cores_personalizadas = "Cores da minha paleta", legenda_sombra_deslocamento_pt = "Sombra da legenda: deslocamento",
                 legenda_nomes = "Nomes na legenda", cores_por_serie = "Cores por série", simbolo_forma_por_serie = "Formas por série",
                 simbolo_tamanho_por_serie = "Tamanho dos pontos por série", linha_espessura_por_serie = "Grossura das linhas por série",
                 simbolo_borda_por_serie = "Contorno dos pontos por série", erro_por_serie = "Colunas de erro (barras de erro)", ajustes = "Curvas de ajuste", marcas_estatisticas = "Traços de média e desvio",
                 caixas_estatisticas = "Caixas de estatística", formas = "Caixas de texto e polígonos", imagens = "Figuras anexadas")
  rotulo_de <- function(id) { c <- ESPEC_CAMPOS[[id]]; if (!is.null(c)) c$rotulo else if (id %in% names(derivados)) derivados[[id]] else id }
  output$avisos <- renderUI({
    r <- rv$res
    UI(tagList(
      if (!is.null(rv$erro)) div(class = "alerta alerta-erro", tags$b("Algo precisa de ajuste: "), tags$span(rv$erro)),
      if (!is.null(r) && length(r$avisos)) div(class = "alerta alerta-aviso", tags$b("Avisos"), tags$ul(lapply(r$avisos, tags$li))),
      if (!is.null(r) && length(setdiff(r$aplicado, c("formatos", "idioma")))) div(class = "mudou", tags$b("O que você mudou: "),
                                                 lapply(setdiff(r$aplicado, c("formatos", "idioma")), function(n) span(class = "chip chip-mudou", rotulo_de(n))))))
  })

  # ---- baixar ------------------------------------------------------------------------------------------------------------
  nome_base <- reactive({
    n <- trimws(input$nome_arquivo %||% ""); if (nzchar(n)) return(gsub("[^A-Za-z0-9_.-]+", "_", n))
    paste0(tools::file_path_sans_ext(rv$nome %||% "grafico"), "_grafico")
  })
  baixar <- function(ext) downloadHandler(
    filename = function() paste0(nome_base(), ".", if (ext == "jpeg") "jpg" else ext),
    content = function(file) {
      validate(need(!is.null(rv$dados), T("Carregue os dados primeiro.")))
      r <- construir_grafico(rv$dados, vars_atual(), CFG0, preview = FALSE, idioma = idioma())
      if (!is.null(r$erro)) stop(r$erro)
      cfg <- r$cfg; cfg$exportacao$pasta <- tempfile("saida_"); cfg$exportacao$formatos <- ext
      cfg$exportacao$nome_arquivo <- "grafico_app"; cfg$exportacao$carimbo_data <- FALSE; cfg$exportacao$sobrescrever <- TRUE
      arqs <- suppressMessages(suppressWarnings(salvar(r$g, cfg)))
      file.copy(arqs[1], file, overwrite = TRUE)
    })
  for (ext in unname(.FORMATOS)) local({ e <- ext; output[[paste0("baixar_", e)]] <- baixar(e) })
  output$botoes_baixar <- renderUI({              # um botão para cada tipo de arquivo marcado em Exportação
    f <- input$formatos; if (!length(f)) f <- "png"
    f <- intersect(unname(.FORMATOS), f)
    div(class = "botoes-baixar", lapply(f, function(e) downloadButton(paste0("baixar_", e), paste(T("Baixar"), toupper(e)), class = "btn-baixar")))
  })

  # ---- código equivalente ----------------------------------------------------------------------------------------
  output$codigo <- renderText(gerar_codigo(vars_codigo()))
  output$baixar_codigo <- downloadHandler(filename = function() paste0(nome_base(), ".R"),
    content = function(file) writeLines(gerar_codigo(vars_codigo(), arquivo_csv = rv$nome, script_completo = TRUE), file, useBytes = TRUE))

  # ---- figuras anexadas (bloco 14): cada cartão guarda uma cópia do arquivo enviado --------------------------------------------------
  for (id in IDS_ARQUIVO) local({
    i <- id
    observeEvent(input[[i]], {
      f <- input[[i]]; req(nrow(f) == 1)
      ext <- tolower(tools::file_ext(f$name))
      if (!ext %in% c("png", "jpg", "jpeg")) return(showNotification(T("Use uma figura PNG ou JPEG."), type = "error"))
      pk <- if (ext == "png") "png" else "jpeg"
      if (!requireNamespace(pk, quietly = TRUE)) return(showNotification(TF("Para usar figuras é preciso o pacote %s (install.packages(\"%s\")).", pk, pk), type = "error"))
      pasta <- file.path(tempdir(), "figuras_app"); dir.create(pasta, showWarnings = FALSE)
      destino <- file.path(pasta, paste0(i, "_", as.integer(Sys.time()), ".", ext)); file.copy(f$datapath, destino, overwrite = TRUE)
      rv$img[[i]] <- list(nome = f$name, caminho = destino)
    })
    output[[paste0(i, "_estado")]] <- renderUI({
      x <- rv$img[[i]]; if (is.null(x)) return(NULL)
      UI(div(class = "chips", span(class = "chip chip-verde", x$nome),
             tags$a(href = "#", onclick = sprintf("Shiny.setInputValue('img_remover', '%s', {priority: 'event'}); return false;", i), "Remover a figura")))
    })
  })
  observeEvent(input$img_remover, { rv$img[[input$img_remover]] <- NULL })
  # no código equivalente, a figura aparece pelo nome do arquivo que você enviou (coloque-o ao lado do script)
  vars_codigo <- function() {
    v <- vars_atual()
    if (!is.null(v$imagens)) {
      nomes <- stats::setNames(vapply(rv$img, function(x) x$nome, ""), vapply(rv$img, function(x) x$caminho, ""))
      v$imagens <- lapply(v$imagens, function(it) { if (!is.null(it$arquivo) && !is.na(nomes[it$arquivo])) it$arquivo <- unname(nomes[it$arquivo]); it })
    }
    v
  }

  # ---- largura do palco (o gráfico é desenhado na largura que a tela dá a ele) ----------------------------------------------------------------
  observeEvent(input$palco_larg, {
    w <- input$palco_larg; if (!is.numeric(w) || w < 200) return()
    rv$palco_larg <- w
    if (!is.null(rv$previa) && !is.null(rv$palco_usado) && abs(w - rv$palco_usado) / rv$palco_usado > 0.12 && isTRUE(input$auto)) calcular()
  })

  # ---- faixa de ferramentas: um clique liga o primeiro cartão livre do tipo pedido ------------------------------------------------------------
  observeEvent(input$rapido, {
    r <- input$rapido; acao <- r$acao
    grupo <- switch(acao, ajuste = "ajustes", marca = "marcas_estatisticas", caixa = "caixas_estatisticas", texto = , forma = "formas", figura = "imagens")
    req(grupo); g <- SLOTS[[grupo]]; pref <- g$pref
    painel <- "analise"
    livre <- NULL
    for (k in seq_len(g$n)) if (!isTRUE(input[[paste0(pref, k, "_ativo")]])) { livre <- k; break }
    if (is.null(livre)) {
      showNotification(T("Todos os cartões deste tipo já estão em uso. Desligue um para reaproveitar."), type = "warning")
      return(session$sendCustomMessage("abrir_painel", list(id = painel)))
    }
    id <- function(ch) paste0(pref, livre, "_", ch)
    abrir_cartao(grupo, livre)
    updateCheckboxInput(session, id("ativo"), value = TRUE)
    # regra: ajuste e média ± DP não escrevem números colados na linha; cada um ganha a sua caixa de estatística, que se move e se edita à parte
    criar_caixa <- function(itens, ajuste = NULL) {
      g2 <- SLOTS$caixas_estatisticas; p2 <- g2$pref; k2 <- NULL
      for (kk in seq_len(g2$n)) if (!isTRUE(input[[paste0(p2, kk, "_ativo")]])) { k2 <- kk; break }
      if (is.null(k2)) { showNotification(T("Todos os cartões de caixa de estatística já estão em uso: o resultado não ganhou caixa. Desligue um para reaproveitar."), type = "warning"); return(invisible()) }
      id2 <- function(ch) paste0(p2, k2, "_", ch)
      abrir_cartao("caixas_estatisticas", k2)
      usadas <- sum(vapply(seq_len(g2$n), function(kk) isTRUE(input[[paste0(p2, kk, "_ativo")]]), NA))
      updateCheckboxInput(session, id2("ativo"), value = TRUE)
      updateSelectInput(session, id2("itens"), selected = itens)
      if (!is.null(ajuste)) updateTextInput(session, id2("ajustes"), value = as.character(ajuste))
      updateSelectInput(session, id2("ancora"), selected = "inf_dir"); updateNumericInput(session, id2("x"), value = 0.97)       # canto de baixo, à direita; cada caixa nova sobe um pouco
      updateNumericInput(session, id2("y"), value = round(min(0.04 + 0.2 * usadas, 0.8), 2))
      updateNumericInput(session, id2("tamanho_pt"), value = 8)                 # começa pequena; a alça do canto muda o tamanho
    }
    if (acao == "ajuste") criar_caixa(if (identical(r$tipo, "externa")) c("equacao", "r2", "rmse") else c("equacao", "r2"), ajuste = livre)
    if (acao == "marca") criar_caixa(c("n", "media", "dp"))
    switch(acao,
      ajuste = updateSelectInput(session, id("tipo"), selected = r$tipo),
      marca = updateCheckboxInput(session, id("preencher"), value = TRUE),
      forma = { updateSelectInput(session, id("tipo"), selected = r$tipo)
                if (identical(r$tipo, "poligono")) updateTextInput(session, id("vertices"), value = "0.3,0.3; 0.7,0.3; 0.5,0.7") },
      texto = updateTextInput(session, id("texto"), value = T("Texto")))
    session$sendCustomMessage("abrir_painel", list(id = painel, cartao = id("ativo")))
  })

  # ---- congelar blocos, salvar / carregar / copiar / colar o modelo ------------------------------------------------------------------
  congelados <- function() { b <- names(BLOCO_IDS); b[vapply(b, function(i) isTRUE(input[[paste0("cong_", i)]]), NA)] }
  ids_congelados <- function() unlist(BLOCO_IDS[congelados()], use.names = FALSE)
  modelo_lista <- function() {
    v <- isolate(valores()); v$paleta_propria <- input$paleta_propria %||% ""; v <- v[!vapply(v, is.null, NA)]
    s <- if (!is.null(rv$dados)) tryCatch(series_df(), error = function(e) NULL) else NULL
    v <- v[setdiff(names(v), IDS_ARQUIVO)]                          # figuras anexadas não vão no modelo (são arquivos desta sessão)
    list(versao = 2, dados = rv$nome, valores = v[!startsWith(names(v), ".")], series = s, paletas = rv$paletas, congelados = unname(congelados()))
  }
  modelo_json <- function() as.character(jsonlite::toJSON(modelo_lista(), auto_unbox = TRUE, null = "null", na = "null", pretty = TRUE))
  output$salvar_cfg <- downloadHandler(filename = function() paste0(nome_base(), "_configuracao.json"), content = function(file) writeLines(modelo_json(), file, useBytes = TRUE))
  # Aplica valores salvos (o que não está no modelo volta ao padrão). Blocos congelados não mudam (respeitar = TRUE).
  aplicar_config <- function(j, respeitar = TRUE, com_congelados = FALSE) {
    cong <- if (respeitar) ids_congelados() else character(0)
    garantir_cartoes(j$valores[setdiff(names(j$valores), cong)])                 # cartões ligados na configuração precisam existir na tela
    for (id in setdiff(names(ESPEC_CAMPOS), cong)) {
      c <- ESPEC_CAMPOS[[id]]; v <- j$valores[[id]]
      if (c$tipo == "arquivo" || (c$tipo %in% c("colx", "colsy", "colsy2") && is.null(v))) next
      atualizar_campo(session, c, v, CFG0)
    }
    if (!is.null(j$valores$paleta_propria)) updateTextAreaInput(session, "paleta_propria", value = as.character(j$valores$paleta_propria))
    if (!is.null(j$valores$simbolo_modo)) updateSelectInput(session, "simbolo_modo", selected = j$valores$simbolo_modo)
    if (is.list(j$paletas) && length(j$paletas)) {
      rv$paletas <- utils::modifyList(rv$paletas, lapply(j$paletas, function(x) as.character(unlist(x)))); atualizar_lista_paletas()
    }
    if (com_congelados) for (b in names(BLOCO_IDS)) updateCheckboxInput(session, paste0("cong_", b), value = b %in% as.character(unlist(j$congelados)))
    if (!is.null(j$series) && length(j$series)) rv$pend_series <- as.data.frame(j$series)
    length(unique(congelados()))
  }
  # ---- salvamento automático e projeto ------------------------------------------------------------------------------------------
  guardar_bruto <- function(caminho) {                               # guarda uma cópia do CSV enviado (para o salvamento automático e para o projeto)
    d <- dir_sessao(); if (is.null(d)) return(caminho)
    dest <- file.path(d, "dados_atual.csv")
    if (identical(normalizePath(caminho, mustWork = FALSE), normalizePath(dest, mustWork = FALSE))) return(dest)
    if (isTRUE(tryCatch(file.copy(caminho, dest, overwrite = TRUE), error = function(e) FALSE))) dest else caminho
  }
  salvar_sessao <- function() {
    d <- dir_sessao()
    if (is.null(d) || is.null(rv$dados) || is.null(rv$bruto) || !file.exists(rv$bruto)) return(invisible())     # sem dados: não apaga o que estava salvo
    tryCatch({
      m <- modelo_lista(); m$salvo_em <- format(Sys.time(), "%d/%m/%Y %H:%M"); m$arquivo_dados <- basename(rv$bruto)
      tmp <- file.path(d, "ultima.json.tmp")
      writeLines(as.character(jsonlite::toJSON(m, auto_unbox = TRUE, null = "null", na = "null")), tmp, useBytes = TRUE)
      file.rename(tmp, file.path(d, "ultima.json"))
    }, error = function(e) registrar_log("salvamento automático falhou: ", conditionMessage(e)))
    invisible()
  }
  ler_sessao_salva <- function() {
    d <- dir_sessao(); if (is.null(d)) return(NULL)
    arq <- file.path(d, "ultima.json"); if (!file.exists(arq)) return(NULL)
    j <- ler_modelo(arq); if (is.null(j) || !file.exists(file.path(d, j$arquivo_dados %||% "dados_atual.csv"))) NULL else j
  }
  gatilho_sessao <- debounce(reactive({ valores(); rv$nome }), 4000)           # 4 s depois da última mudança
  observeEvent(gatilho_sessao(), salvar_sessao(), ignoreInit = TRUE)
  output$salvar_projeto <- downloadHandler(filename = function() paste0(tools::file_path_sans_ext(rv$nome %||% "cinabro"), ".cinabro"),
    content = function(file) writeLines(projeto_json(montar_projeto(modelo_lista(), rv$bruto)), file, useBytes = TRUE))
  observeEvent(input$abrir_projeto, {
    j <- ler_modelo(input$abrir_projeto$datapath)
    if (is.null(j)) { showNotification(T("Arquivo de projeto inválido."), type = "error"); return() }
    tmp <- extrair_dados_projeto(j, tempfile(fileext = ".csv"))
    if (!is.null(tmp)) carregar(tmp, j$dados %||% "dados.csv")
    aplicar_config(j, respeitar = FALSE, com_congelados = TRUE)
    showNotification(if (is.null(tmp)) T("Projeto aberto (sem dados dentro: carregue o CSV).") else T("Projeto aberto, com os dados e a configuração."), type = "message")
  })
  modal_retomar <- function(j) modalDialog(title = "Retomar de onde você parou?", easyClose = FALSE, size = "s",
    footer = tagList(actionButton("retomar_nao", "Começar do zero"), actionButton("retomar_sim", "Retomar", class = "btn-verde")),
    tags$p("O Cinabro guardou sozinho o seu último gráfico:"),
    tags$p(tags$b(j$dados %||% "dados"), tags$br(), tags$span(class = "ajuda", paste("salvo em", j$salvo_em %||% ""))))
  observeEvent(input$retomar_nao, removeModal())
  observeEvent(input$retomar_sim, {
    j <- ler_sessao_salva(); req(j)
    carregar(file.path(dir_sessao(), j$arquivo_dados %||% "dados_atual.csv"), j$dados %||% "dados.csv"); req(rv$dados)
    aplicar_config(j, respeitar = FALSE, com_congelados = TRUE)
    removeModal(); showNotification(T("Retomado de onde você parou."), type = "message")
  })
  ler_modelo <- function(txt) {
    j <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = TRUE), error = function(e) NULL)
    if (is.null(j) || !is.list(j) || is.null(j$valores)) NULL else j
  }
  observeEvent(input$carregar_cfg, {
    j <- ler_modelo(input$carregar_cfg$datapath)
    if (is.null(j)) { showNotification(T("Arquivo de configuração inválido."), type = "error"); return() }
    aplicar_config(j, respeitar = TRUE, com_congelados = FALSE)
    showNotification(T("Configuração carregada."), type = "message")
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

  # ---- quebra: sugerir o maior vazio -----------------------------------------------------------------------------------------------------
  observeEvent(input$quebra_sugerir, {
    req(rv$dados)
    v <- vars_atual(); v$quebra_ativar <- NULL; v$quebra_de <- NULL; v$quebra_ate <- NULL
    sug <- tryCatch({
      cfg <- suppressMessages(aplicar_painel(CFG0, painel = list2env(v, parent = emptyenv()), dados = rv$dados))
      utils::capture.output(r <- sugerir_quebra(rv$dados, cfg)); r
    }, error = function(e) { showNotification(paste(T("Não consegui sugerir:"), conditionMessage(e)), type = "error"); NULL })
    if (is.null(sug)) return()
    updateNumericInput(session, "quebra_de", value = signif(sug$de, 6)); updateNumericInput(session, "quebra_ate", value = signif(sug$ate, 6))
    showNotification(TF("Maior vazio: de %s a %s.", format(signif(sug$de, 6), scientific = FALSE), format(signif(sug$ate, 6), scientific = FALSE)), type = "message")
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
                   error = function(e) { showNotification(paste(T("Não consegui adicionar a fonte:"), conditionMessage(e)), type = "error"); FALSE })
    if (ok) {
      updateSelectizeInput(session, "fonte", choices = tr_nomes(opcoes_fontes(), idioma()), selected = familia, server = FALSE)
      showNotification(TF("Fonte \"%s\" adicionada e selecionada.", familia), type = "message")
    }
  })

  # ---- tabelas de resultados (bloco 13) ----------------------------------------------------------------------------------------------
  tabelas_estat <- eventReactive(input$estat_calcular, {
    validate(need(!is.null(rv$dados), T("Carregue os dados primeiro.")))
    cfg <- tryCatch(suppressMessages(suppressWarnings(aplicar_painel(CFG0, painel = list2env(vars_atual(), parent = emptyenv()), dados = rv$dados))), error = function(e) NULL)
    validate(need(!is.null(cfg), T("Corrija o aviso de erro abaixo da prévia primeiro.")))
    com_idioma(idioma(), suppressWarnings(estatisticas(rv$dados, cfg, testes = input$estat_testes)))
  })
  fmt_tab <- function(df, nomes) {
    if (!nrow(df)) return(NULL)
    for (n in names(df)) if (is.numeric(df[[n]])) df[[n]] <- ifelse(is.na(df[[n]]), "", vapply(df[[n]], function(z) if (is.na(z)) "" else if (n %in% c("n", "gl")) as.character(z) else if (grepl("^p", n) && z < 0.001) "<0.001" else format(signif(z, 4), trim = TRUE, scientific = FALSE), ""))
    names(df) <- ifelse(names(df) %in% names(nomes), nomes[names(df)], names(df))
    tags$table(tags$thead(tags$tr(lapply(names(df), tags$th))), tags$tbody(lapply(seq_len(nrow(df)), function(i) tags$tr(lapply(df[i, ], function(x) tags$td(as.character(x)))))))
  }
  output$estat_tabelas <- renderUI({
    r <- tabelas_estat(); op <- options(cinabro.idioma = idioma()); on.exit(options(op))
    base <- c(serie = T("Série"), ajuste = T("Ajuste"), equacao = T("Equação"), termo = T("Termo"), estimativa = T("Estimativa"), ep = .re("ep"), t = "t", p = "p", ic_inf = T("IC 95% inf."), ic_sup = T("IC 95% sup."),
              teste = T("Teste"), grupos = T("Grupos"), estatistica = T("Estatística"), gl = .re("gl"), detalhe = T("Detalhe"), r2 = "R²", r2_aj = .re("r2_aj"), rmse = "RMSE", aic = "AIC", bic = "BIC", n = "n",
              media = .re("media"), mediana = .re("mediana"), dp = .re("dp"), soma = .re("soma"), minimo = .re("minimo"), maximo = .re("maximo"), amplitude = .re("amplitude"),
              variancia = .re("variancia"), cv = "CV (%)", q1 = "Q1", q3 = "Q3", ic_inf = T("IC 95% inf."), ic_sup = T("IC 95% sup."))
    UI(tagList(
      if (nrow(r$descritiva)) tagList(tags$h5(T("Resumo de cada série")), fmt_tab(r$descritiva, base)),
      if (nrow(r$ajustes)) tagList(tags$h5(T("Ajustes de curva")), fmt_tab(r$ajustes, base)),
      if (nrow(r$parametros)) tagList(tags$h5(T("Parâmetros dos ajustes")), fmt_tab(r$parametros, base)),
      # (colunas dos testes: o valor de p logo depois dos grupos, para caber na largura do painel)
      if (nrow(r$testes)) tagList(tags$h5(T("Testes estatísticos")), fmt_tab(r$testes[, intersect(c("teste", "grupos", "p", "estatistica", "gl", "detalhe"), names(r$testes)), drop = FALSE], base)),
      if (!nrow(r$ajustes)) tags$p(class = "ajuda", T("Para ver os ajustes aqui, ligue um cartão de ajuste acima."))))
  })
  output$estat_baixar <- downloadHandler(filename = function() paste0(nome_base(), "_estatisticas.csv"), content = function(file) {
    r <- tabelas_estat(); linhas <- character(0)
    for (n in names(r)) if (nrow(r[[n]])) linhas <- c(linhas, paste0("# ", n), utils::capture.output(utils::write.csv(r[[n]], row.names = FALSE)), "")
    writeLines(linhas, file, useBytes = TRUE)
  })

  # ---- abas: vários gráficos, um de cada vez na tela ---------------------------------------------------------------
  nome_aba <- function(i) { n <- rv$abas[[i]]$nome; if (is.null(n)) TF("Gráfico %d", i) else n }
  capturar <- function() list(valores = isolate(valores()), series = if (!is.null(rv$dados)) isolate(tryCatch(series_df(), error = function(e) NULL)),
                              dados = rv$dados, nome_dados = rv$nome, cong = unname(congelados()), img = rv$img)
  # só envia à tela o que muda de uma aba para a outra: de 646 mensagens (~10 s) para as poucas que de fato diferem
  igual_campo <- function(a, b) identical(as.character(unlist(a)), as.character(unlist(b)))
  restaurar_aba <- function(snap) {
    atual <- isolate(valores()); cong_atual <- isolate(congelados())
    rv$dados <- snap$dados; rv$nome <- snap$nome_dados; rv$erro <- NULL; rv$res <- NULL; rv$previa <- NULL; rv$pend_calc <- TRUE
    rv$img <- snap$img %||% list()
    garantir_cartoes(snap$valores)
    definir_colunas(snap$dados, snap$valores)
    n <- 0L
    for (id in names(ESPEC_CAMPOS)) {
      c <- ESPEC_CAMPOS[[id]]; if (c$tipo %in% c("colx", "colsy", "colsy2")) next
      alvo <- snap$valores[[id]]; if (is.null(alvo)) alvo <- valor_inicial(c, CFG0)
      if (igual_campo(atual[[id]], alvo)) next
      atualizar_campo(session, c, snap$valores[[id]], CFG0); n <- n + 1L
    }
    if (!igual_campo(atual$.paleta_propria, snap$valores$.paleta_propria)) updateTextAreaInput(session, "paleta_propria", value = as.character(snap$valores$.paleta_propria %||% ""))
    if (!igual_campo(atual$simbolo_modo, snap$valores$simbolo_modo %||% "variar")) updateSelectInput(session, "simbolo_modo", selected = snap$valores$simbolo_modo %||% "variar")
    for (b in names(BLOCO_IDS)) if ((b %in% snap$cong) != (b %in% cong_atual)) updateCheckboxInput(session, paste0("cong_", b), value = b %in% snap$cong)
    st$ate <- Sys.time() + min(1.8, 0.4 + 0.003 * n)           # as telas levam um instante para receber os valores; só então monta o gráfico
    ps <- snap$series
    session$onFlushed(function() isolate(rv$pend_series <- if (!is.null(ps) && nrow(ps)) ps else NULL), once = TRUE)
  }
  trocar_aba <- function(i) {
    i <- as.integer(i); cur <- rv$aba
    if (is.na(i) || i == cur || i < 1 || i > length(rv$abas)) return(invisible())
    rv$abas[[cur]]$snap <- capturar(); rv$aba <- i; restaurar_aba(rv$abas[[i]]$snap)
  }
  observeEvent(input$aba_ir, trocar_aba(input$aba_ir))
  observeEvent(input$aba_nova, {
    cur <- rv$aba; snap <- capturar(); rv$abas[[cur]]$snap <- snap
    livre <- setdiff(names(snap$valores), unlist(BLOCO_IDS[snap$cong], use.names = FALSE))      # só os blocos congelados vão para a aba nova
    nova <- list(valores = snap$valores[setdiff(names(snap$valores), livre)], series = NULL, dados = NULL, nome_dados = NULL, cong = snap$cong,
                 img = snap$img[intersect(names(snap$img), unlist(BLOCO_IDS[snap$cong], use.names = FALSE))])
    nova$valores$simbolo_modo <- if ("cores" %in% snap$cong) snap$valores$simbolo_modo else NULL
    rv$abas[[length(rv$abas) + 1]] <- list(nome = NULL, snap = nova); rv$aba <- length(rv$abas); restaurar_aba(nova)
    showNotification(if (length(snap$cong)) TF("Aba nova: %d bloco(s) congelado(s) foram mantidos; o resto voltou ao padrão. Carregue os dados desta aba.", length(snap$cong)) else T("Aba nova, com o padrão do template. Carregue os dados desta aba."), type = "message")
  })
  observeEvent(input$aba_duplicar, {
    cur <- rv$aba; snap <- capturar(); rv$abas[[cur]]$snap <- snap
    rv$abas[[length(rv$abas) + 1]] <- list(nome = paste0(nome_aba(cur), T(" (cópia)")), snap = snap); rv$aba <- length(rv$abas)
    showNotification(T("Aba duplicada, com as mesmas configurações e os mesmos dados."), type = "message")
  })
  observeEvent(input$aba_fechar, {
    i <- as.integer(input$aba_fechar); n <- length(rv$abas); cur <- rv$aba
    if (n < 2 || is.na(i) || i < 1 || i > n) return()
    rv$abas[[i]] <- NULL
    if (i == cur) { rv$aba <- max(1L, i - 1L); restaurar_aba(rv$abas[[rv$aba]]$snap) } else if (i < cur) rv$aba <- cur - 1L
  })
  observeEvent(input$aba_renomear, {
    showModal(UI(modalDialog(title = "Nome desta aba", easyClose = TRUE, footer = tagList(modalButton("Cancelar"), actionButton("aba_nome_ok", "Salvar nome", class = "btn-verde")),
                             textInput("aba_nome_novo", NULL, value = nome_aba(rv$aba), width = "100%"))))
  })
  observeEvent(input$aba_nome_ok, { n <- trimws(input$aba_nome_novo %||% ""); if (nzchar(n)) rv$abas[[rv$aba]]$nome <- n; removeModal() })
  output$abas_ui <- renderUI({
    n <- length(rv$abas); cur <- rv$aba
    UI(tagList(
      lapply(seq_len(n), function(i) tags$span(class = paste("aba", if (i == cur) "ativa"), onclick = sprintf("Shiny.setInputValue('aba_ir', %d, {priority: 'event'})", i),
                                              tags$span(nome_aba(i)),
                                              if (n > 1) tags$span(class = "aba-x", title = "Fechar esta aba", onclick = sprintf("event.stopPropagation(); Shiny.setInputValue('aba_fechar', %d, {priority: 'event'})", i), HTML("&times;")))),
      tags$span(class = "aba-acao", title = "Outro gráfico, sem dados e só com os blocos congelados mantidos.", onclick = "Shiny.setInputValue('aba_nova', Date.now(), {priority: 'event'})", "+ Nova aba"),
      tags$span(class = "aba-acao", title = "Cópia deste gráfico (configurações e dados) para variar.", onclick = "Shiny.setInputValue('aba_duplicar', Date.now(), {priority: 'event'})", "Duplicar"),
      tags$span(class = "aba-acao", onclick = "Shiny.setInputValue('aba_renomear', Date.now(), {priority: 'event'})", "Renomear")))
  })

  # ---- estilos prontos, restaurar, guia ------------------------------------------------------------------------------------
  restaurar_campos <- function() {
    cong <- ids_congelados()
    for (id in setdiff(names(ESPEC_CAMPOS), cong)) if (!ESPEC_CAMPOS[[id]]$tipo %in% c("colx", "colsy", "colsy2")) atualizar_campo(session, ESPEC_CAMPOS[[id]], NULL, CFG0)
    rv$img <- rv$img[intersect(names(rv$img), cong)]                  # as figuras anexadas dos blocos livres saem
    if (!"cores" %in% congelados()) updateSelectInput(session, "simbolo_modo", selected = "variar")
  }
  observeEvent(input$restaurar, {
    restaurar_campos(); updateSelectInput(session, "estilo", selected = "")
    n <- length(congelados())
    showNotification(if (n) TF("Tudo voltou ao padrão do template (%d bloco(s) congelado(s) mantido(s)).", n) else T("Tudo voltou ao padrão do template."))
  })
  observeEvent(input$estilo, {
    if (!nzchar(input$estilo)) return()
    restaurar_campos()
    p <- PRESETS[[input$estilo]]; cong <- ids_congelados()
    for (id in setdiff(names(p), cong)) if (!is.null(ESPEC_CAMPOS[[id]])) atualizar_campo(session, ESPEC_CAMPOS[[id]], p[[id]], CFG0)
  }, ignoreInit = TRUE)
  observeEvent(input$guia, showModal(UI(guia_rapido())))
  observeEvent(input$idioma_pagina, {
    j <- ler_sessao_salva()
    if (!is.null(j)) showModal(UI(modal_retomar(j)))                  # há trabalho guardado: oferece retomar (no lugar do guia)
    else if (!isTRUE(getOption("gerador_sem_guia"))) showModal(UI(guia_rapido()))
  }, once = TRUE)
}
