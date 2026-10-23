# =============================================================================
#  app_shiny/codigo/ui_blocos.R — peças da tela (campos, blocos, cartões)
# =============================================================================
library(shiny)

# Seletor de cor: quadrado colorido (abre o seletor do navegador) + "×" para voltar ao padrão do template.
cor_input <- function(id, rotulo, padrao_hex = NULL) {
  div(class = "cor-input", `data-id` = id, `data-padrao` = padrao_hex %||% "",
      tags$label(rotulo),
      div(class = "cor-linha",
          tags$input(type = "color", value = padrao_hex %||% "#cccccc", class = "cor-seletor"),
          tags$span(class = if (is.null(padrao_hex)) "cor-estado vazio" else "cor-estado", if (is.null(padrao_hex)) "padrão" else padrao_hex),
          tags$button(type = "button", class = "cor-limpar", title = "Voltar ao padrão", HTML("&times;"))))
}

hex_de <- function(cor) {
  if (is.null(cor) || length(cor) != 1 || is.na(cor)) return(NULL)
  tryCatch({ m <- grDevices::col2rgb(cor); grDevices::rgb(m[1], m[2], m[3], maxColorValue = 255) }, error = function(e) NULL)
}

# numericInput que começa realmente vazio (o shiny escreve value="NA" quando o valor inicial é NA)
numero_vazio_ok <- function(tag, ini) {
  if (!is.na(ini)) return(tag)
  htmltools::tagQuery(tag)$find("input")$removeAttrs("value")$allTags()
}

# A lista suspensa abre no <body> para não ser cortada pelo bloco; nas de várias escolhas, cada item tem um "×".
OPC_SELECTIZE <- list(dropdownParent = "body", maxOptions = 2000)
OPC_SELECTIZE_MULTI <- list(dropdownParent = "body", maxOptions = 2000, plugins = list("remove_button"), closeAfterSelect = FALSE, hideSelected = FALSE)

ui_campo <- function(campo, cfg0) {
  id <- campo$id; ini <- valor_inicial(campo, cfg0)
  opc <- tr_nomes(campo$opcoes)                       # os nomes das opções, no idioma da tela (os valores não mudam)
  rot <- campo$rotulo
  ctrl <- switch(campo$tipo,
    num = numero_vazio_ok(numericInput(id, rot, value = ini, min = campo$min, max = campo$max, step = campo$passo), ini),
    int = numero_vazio_ok(numericInput(id, rot, value = ini, min = campo$min, max = campo$max, step = 1), ini),
    txt = textInput(id, rot, value = ini),
    vec = textInput(id, rot, value = ""),
    sel = , tri = selectInput(id, rot, choices = opc, selected = ini, selectize = FALSE),
    selbusca = selectizeInput(id, rot, choices = opc, selected = ini,
                              options = if (id == "cores_paleta") c(OPC_SELECTIZE, list(render = I("window.renderPaleta"))) else OPC_SELECTIZE),
    chk = checkboxInput(id, rot, value = ini),
    chkgrupo = checkboxGroupInput(id, rot, choices = opc, selected = ini, inline = TRUE),
    cor = cor_input(id, rot, hex_de(padrao_do_campo(campo, cfg0))),
    selmulti = selectizeInput(id, rot, choices = opc, selected = NULL, multiple = TRUE, options = OPC_SELECTIZE_MULTI),
    arquivo = tagList(fileInput(id, rot, accept = c(".png", ".jpg", ".jpeg"), buttonLabel = tr("Escolher arquivo..."), placeholder = tr("Nenhum arquivo"), width = "100%"),
                      uiOutput(paste0(id, "_estado"))),
    colx = selectInput(id, rot, choices = stats::setNames("", tr("(1ª coluna)")), selectize = FALSE),
    colsy = , colsy2 = tagList(
      selectizeInput(id, rot, choices = character(0), multiple = TRUE,
                     options = c(OPC_SELECTIZE_MULTI, list(placeholder = tr(if (campo$tipo == "colsy") "Vazio = todas as colunas numéricas" else "Clique para escolher...")))),
      div(class = "sel-atalhos", tags$a(href = "#", `data-sel-todas` = id, "Selecionar todas"), tags$a(href = "#", `data-sel-limpar` = id, "Limpar"))))
  if (id == "cores_paleta") ctrl <- tagList(ctrl, uiOutput("previa_paleta"))          # as cores da paleta escolhida, desenhadas
  caixa <- div(class = paste0("campo campo-", campo$tipo, if (campo$largura >= 12) " span2" else ""),
               ctrl, if (!is.null(campo$ajuda)) tags$small(class = "ajuda", campo$ajuda))
  if (is.null(campo$se)) return(caixa)
  cp <- conditionalPanel(condition = campo$se, caixa)           # (o span2 vai no painel condicional, que é o item da grade)
  if (campo$largura >= 12) cp <- tagAppendAttributes(cp, class = "span2")
  cp
}

ui_grade_campos <- function(campos, cfg0) {
  normais <- Filter(function(x) !isTRUE(x$mais), campos); mais <- Filter(function(x) isTRUE(x$mais), campos)
  tagList(
    if (length(normais)) div(class = "campos", lapply(normais, ui_campo, cfg0 = cfg0)),
    if (length(mais)) tags$details(class = "mais", tags$summary("Mais opções"), div(class = "campos", lapply(mais, ui_campo, cfg0 = cfg0))))
}

ui_bloco <- function(b, n, cfg0, aberto = FALSE, extra = NULL, antes = NULL) {
  div(class = paste("painel", if (aberto) "ativo"), id = paste0("bloco-", b$id), `data-painel` = b$id,
    div(class = "painel-cab", span(class = "num", n), div(class = "tit", tags$h3(b$titulo), tags$p(b$resumo)),
        span(class = "cong", title = "Congelar: este bloco mantém o que está agora ao restaurar tudo, ao criar uma aba nova e ao colar um modelo.",
             checkboxInput(paste0("cong_", b$id), "Congelar", value = FALSE))),
    div(class = "bloco-corpo",
        antes,
        if (!is.null(b$dica)) div(class = "dica", span(class = "dica-ic", "Dica"), b$dica),
        if (length(b$campos)) ui_grade_campos(b$campos, cfg0),
        lapply(b$grupos, function(g) {
          gr <- if (!length(g$campos)) div(class = "grupo-secao", tags$h4(g$titulo))
                else if (!is.null(g$ativo)) {             # cartão: a caixa "Usar" sempre aparece; o resto só com ela marcada
                  ca <- Filter(function(x) identical(x$chave, "ativo"), g$campos); resto <- Filter(function(x) !identical(x$chave, "ativo"), g$campos)
                  div(class = "grupo", tags$h4(g$titulo), ui_grade_campos(ca, cfg0), conditionalPanel(condition = paste0("input.", g$ativo), ui_grade_campos(resto, cfg0)))
                } else div(class = "grupo", tags$h4(g$titulo), ui_grade_campos(g$campos, cfg0))
          if (is.null(g$se)) gr else conditionalPanel(condition = g$se, gr)
        }),
        extra))
}

# ---- trilho de ícones (à esquerda) e faixa de ferramentas (acima do gráfico) ---------------------------------------------------------------
# Ícones desenhados para o Cinabro (traços simples, sem biblioteca de terceiros).
.ICONES <- c(
  dados = '<ellipse cx="12" cy="6" rx="7" ry="3"/><path d="M5 6v6c0 1.7 3.1 3 7 3s7-1.3 7-3V6M5 12v6c0 1.7 3.1 3 7 3s7-1.3 7-3v-6"/>',
  intervalos = '<path d="M3 18h18M5 18v-5M9 18v-3M13 18v-5M17 18v-3M21 18v-5"/><path d="M3 7h18" stroke-dasharray="2 3"/>',
  escala = '<path d="M4 4v16h16"/><path d="M6 17c2-1 3-7 6-9s4-2 6-2"/>',
  numeros = '<text x="12" y="16.5" text-anchor="middle" font-size="10.5" font-weight="700" fill="currentColor" stroke="none" font-family="Barlow,sans-serif">123</text>',
  grade = '<rect x="4" y="4" width="16" height="16" rx="1"/><path d="M4 9.3h16M4 14.7h16M9.3 4v16M14.7 4v16"/>',
  quebra = '<path d="M4 4v6M4 14v6M4 20h16"/><path d="M1.5 12.5l5-2M1.5 14.5l5-2"/><path d="M9 15l3-3 3 2 4-5"/>',
  y2 = '<path d="M4 4v16h16V4"/><path d="M7 16l3.5-5 3 3 3.5-6"/>',
  cores = '<path d="M12 3a9 9 0 100 18c1.6 0 2.2-1 2.2-2s-.9-1.5-.9-2.6.9-1.9 2-1.9H18a3.5 3.5 0 003.5-3.6C21 6.6 17 3 12 3z"/><circle cx="7.8" cy="11" r="1.1" fill="currentColor"/><circle cx="11" cy="7.4" r="1.1" fill="currentColor"/><circle cx="15.4" cy="8.2" r="1.1" fill="currentColor"/>',
  fonte = '<text x="12" y="17" text-anchor="middle" font-size="15" font-weight="700" fill="currentColor" stroke="none" font-family="Barlow,sans-serif">Aa</text>',
  moldura = '<rect x="4" y="5" width="16" height="14" rx="1"/><path d="M8 15l3-4 3 3 2-2"/>',
  legenda = '<rect x="4" y="5" width="16" height="14" rx="2"/><path d="M7.5 9h2M11.5 9H17M7.5 12h2M11.5 12H17M7.5 15h2M11.5 15H17"/>',
  estatistica = '<path d="M4 20h16"/><path d="M5 19c3.2 0 3.2-14 7-14s3.8 14 7 14"/>',
  formas = '<rect x="3.5" y="4" width="9" height="9" rx="1.2"/><circle cx="16.5" cy="16" r="4.2"/>',
  exportacao = '<path d="M12 4v11M7.5 11l4.5 4.5 4.5-4.5M5 20h14"/>')
.TRILHO <- list("dados", c("intervalos", "escala", "numeros", "grade", "quebra", "y2"), c("cores", "fonte", "moldura", "legenda"), c("estatistica", "formas"), "exportacao")
ui_trilho <- function() {
  num <- stats::setNames(seq_along(ESPEC), vapply(ESPEC, function(b) b$id, ""))
  tags$nav(class = "trilho",
    lapply(.TRILHO, function(g) div(class = "trilho-grupo", lapply(g, function(id) {
      tags$button(type = "button", class = "trilho-btn", `data-painel` = id, title = ESPEC[[num[[id]]]]$titulo,
                  HTML(sprintf('<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">%s</svg>', .ICONES[[id]])),
                  span(class = "trilho-n", num[[id]]))
    }))))
}
.rapido <- function(rot, ...) tags$button(type = "button", class = "faixa-btn", `data-rapido` = as.character(jsonlite::toJSON(list(...), auto_unbox = TRUE)), rot)
.menu_faixa <- function(rot, itens) tags$details(class = "faixa-menu", tags$summary(class = "faixa-btn", rot, HTML("&nbsp;&#9662;")), div(class = "faixa-lista", itens))
ui_faixa <- function() {
  div(class = "faixa",
    div(class = "faixa-grupo", span(class = "faixa-tit", "Análise"),
        .menu_faixa("Ajuste de curva", lapply(seq_along(.AJUSTES_OPC), function(i) .rapido(names(.AJUSTES_OPC)[i], acao = "ajuste", tipo = unname(.AJUSTES_OPC[i])))),
        .rapido("Média ± DP", acao = "marca"), .rapido("Caixa de estatística", acao = "caixa"),
        tags$button(type = "button", class = "faixa-btn", `data-abrir` = "estatistica", "Tabelas e testes")),
    div(class = "faixa-grupo", span(class = "faixa-tit", "Anotar"),
        .rapido("Texto", acao = "texto"),
        .menu_faixa("Forma", lapply(seq_along(.TIPOS_FORMA)[-1], function(i) .rapido(names(.TIPOS_FORMA)[i], acao = "forma", tipo = unname(.TIPOS_FORMA[i])))),
        .rapido("Figura", acao = "figura")),
    div(class = "faixa-grupo faixa-dir", uiOutput("botoes_baixar", inline = TRUE),
        tags$button(type = "button", class = "faixa-btn faixa-max", id = "maximizar", `data-sair` = "Mostrar painéis", title = "Esconde o trilho e o painel para o gráfico ocupar a tela toda (Esc volta).", "Maximizar")))
}

# Cartão de uma série (cor, forma, tamanhos e nome na legenda).
ui_serie <- function(i, nome) {
  div(class = "serie-cartao",
      div(class = "serie-nome", span(class = "bolinha"), nome),
      div(class = "campos",
          cor_input(paste0("ser_cor_", i), "Cor (vazio = da paleta)", NULL),
          div(class = "campo", selectInput(paste0("ser_forma_", i), "Forma", choices = tr_nomes(c("(padrão)" = "", .FORMAS)), selectize = FALSE)),
          div(class = "campo", numero_vazio_ok(numericInput(paste0("ser_tamanho_", i), "Tamanho do ponto (pt)", value = NA, min = 0, step = 0.5), NA)),
          div(class = "campo", numero_vazio_ok(numericInput(paste0("ser_linha_", i), "Grossura da linha (pt)", value = NA, min = 0, step = 0.25), NA)),
          div(class = "campo", numero_vazio_ok(numericInput(paste0("ser_borda_", i), "Contorno do ponto (pt)", value = NA, min = 0, step = 0.25), NA)),
          div(class = "campo", textInput(paste0("ser_legenda_", i), "Nome na legenda", value = nome))))
}

guia_rapido <- function() {
  modalDialog(easyClose = TRUE, size = "l", footer = modalButton("Entendi"), title = "Como usar em 4 passos",
    div(class = "guia",
      div(class = "passo", span(class = "num", "1"), div(tags$b("Carregue seus dados"), tags$p("Envie um arquivo CSV (1ª linha com os títulos das colunas) ou escolha um dos exemplos. Escolha o tipo de gráfico."))),
      div(class = "passo", span(class = "num", "2"), div(tags$b("Monte e ajuste"), tags$p("O trilho de ícones, à esquerda, abre um painel de cada vez: intervalos, escala, números, grade, quebra, eixo direito, cores, fonte, moldura, legenda, análises e formas. Na faixa acima do gráfico, um clique liga um ajuste de curva, a média ± DP, uma caixa de estatística, um texto, uma forma ou uma figura. Clique no título ou nos nomes dos eixos, no próprio gráfico, para editá-los. \"Maximizar\" dá a tela toda ao gráfico."))),
      div(class = "passo", span(class = "num", "3"), div(tags$b("Confira o gráfico"), tags$p("A prévia mostra o gráfico como vai sair no arquivo. Os avisos abaixo dela explicam, em português, qualquer problema."))),
      div(class = "passo", span(class = "num", "4"), div(tags$b("Baixe"), tags$p("Marque o tipo de arquivo no bloco 12 (PNG, TIFF, JPEG, SVG, PDF...) e use o botão de baixar. Salve a configuração para repetir depois, ou copie o código para usar no script."))),
      tags$h4("Dica: quantas séries, quais cores"),
      tags$p("Até 4 ou 5 séries, a paleta \"Marca (azul e verde)\" funciona bem: as primeiras cores foram ordenadas para serem as mais diferentes entre si, também para quem tem daltonismo. Passando disso, as cores de azul e verde começam a se parecer: use uma paleta de apoio (\"Okabe-Ito\" é feita para daltonismo) ou varie também a forma do ponto e o tipo da linha. Para valores contínuos, prefira um degradê."),
      tags$h4("Vários gráficos"),
      tags$p("As abas no alto guardam gráficos diferentes: cada uma tem os seus dados e as suas configurações, e dá para ver outra aba ao lado do gráfico que você edita. Marque \"Congelar\" nos blocos que quer repetir (por exemplo fonte, moldura e cores): eles não voltam ao padrão em \"Restaurar tudo\" e passam para as abas novas. \"Copiar modelo\" e \"Colar modelo...\" levam todas as configurações de um gráfico para outro."),
      tags$h4("Palavras que aparecem"),
      tags$dl(
        tags$dt("Traço (tick)"), tags$dd("Marca pequena no eixo, ao lado de cada número. Grande = com número; pequeno = entre dois grandes."),
        tags$dt("Intervalo"), tags$dd("A distância entre dois traços grandes: 1 = de 1 em 1, 2 = de 2 em 2."),
        tags$dt("Grade"), tags$dd("Linhas de fundo, uma em cada traço grande."),
        tags$dt("Quebra do eixo"), tags$dd("Corta o trecho vazio entre dois grupos de dados muito distantes."),
        tags$dt("Eixo Y da direita (Y2)"), tags$dd("Um segundo eixo vertical, com escala própria, para séries de outra grandeza."),
        tags$dt("Caixa do gráfico"), tags$dd("A área dentro dos eixos. Com tamanho fixo, ela é igual em todos os gráficos."))))
}

# Editor da paleta própria (bloco 8): códigos de cor, quadradinhos que se editam, guardar com um nome.
ui_paleta_propria <- function() {
  div(class = "grupo", id = "paleta-editor",
      tags$h4("Criar a minha paleta"),
      tags$p(class = "ajuda", "Cole os códigos das cores (por exemplo os de uma paleta que você gostou, de um site de paletas ou do manual da sua empresa), separados por vírgula, espaço ou linha. Os quadradinhos abaixo podem ser clicados para trocar a cor. As séries usam as cores nesta ordem. Para usar, escolha \"A que estou criando\" na lista de paletas, em cima."),
      textAreaInput("paleta_propria", NULL, value = "", rows = 3, width = "100%", placeholder = "#B3262E, #2F6670, #C96A4A, #20242B"),
      div(id = "paleta-chips", class = "paleta-chips"),
      div(class = "botoes-config",
          tags$button(type = "button", class = "btn-sec", id = "paleta-mais", "+ Cor"),
          tags$button(type = "button", class = "btn-sec", id = "paleta-inverter", "Inverter ordem"),
          tags$button(type = "button", class = "btn-sec", id = "paleta-limpar", "Limpar"),
          actionButton("paleta_copiar", "Começar pela paleta escolhida", class = "btn-sec")),
      div(class = "campos paleta-guardar",
          div(class = "campo", textInput("paleta_nome", "Nome para guardar", value = "", placeholder = "ex.: Minha marca")),
          div(class = "campo botoes-config", actionButton("paleta_salvar", "Guardar paleta", class = "btn-verde"),
              actionButton("paleta_excluir", "Excluir a guardada selecionada", class = "btn-sec"))),
      tags$p(class = "ajuda", "As paletas guardadas ficam neste navegador (e vão junto na configuração salva)."))
}

# As cores de cada paleta pronta (6 de cada), para desenhar os quadradinhos na lista de paletas.
paletas_js <- function() {
  ids <- unlist(.PALETAS_GRUPOS, use.names = FALSE)
  stats::setNames(lapply(ids, function(i) as.list(tryCatch(.paleta(i, 6, CFG0$cores), error = function(e) character(0)))), ids)
}
