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

ui_campo <- function(campo, cfg0) {
  id <- campo$id; ini <- valor_inicial(campo, cfg0)
  rot <- campo$rotulo
  ctrl <- switch(campo$tipo,
    num = numero_vazio_ok(numericInput(id, rot, value = ini, min = campo$min, max = campo$max, step = campo$passo), ini),
    int = numero_vazio_ok(numericInput(id, rot, value = ini, min = campo$min, max = campo$max, step = 1), ini),
    txt = textInput(id, rot, value = ini),
    vec = textInput(id, rot, value = ""),
    sel = , tri = selectInput(id, rot, choices = campo$opcoes, selected = ini, selectize = FALSE),
    selbusca = selectInput(id, rot, choices = campo$opcoes, selected = ini, selectize = TRUE),
    chk = checkboxInput(id, rot, value = ini),
    cor = cor_input(id, rot, hex_de(padrao_do_campo(campo, cfg0))),
    selmulti = selectInput(id, rot, choices = campo$opcoes, selected = NULL, multiple = TRUE, selectize = TRUE),
    colx = selectInput(id, rot, choices = c("(1ª coluna)" = ""), selectize = FALSE),
    colsy = , colsy2 = selectInput(id, rot, choices = character(0), multiple = TRUE, selectize = TRUE))
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

ui_bloco <- function(b, n, cfg0, aberto = FALSE, extra = NULL) {
  tags$details(class = "bloco", id = paste0("bloco-", b$id), open = if (aberto) NA else NULL,
    tags$summary(class = "bloco-cab", span(class = "num", n), div(class = "tit", tags$h3(b$titulo), tags$p(b$resumo)), span(class = "seta")),
    div(class = "bloco-corpo",
        if (!is.null(b$dica)) div(class = "dica", span(class = "dica-ic", "Dica"), b$dica),
        if (length(b$campos)) ui_grade_campos(b$campos, cfg0),
        lapply(b$grupos, function(g) div(class = "grupo", tags$h4(g$titulo), ui_grade_campos(g$campos, cfg0))),
        extra))
}

# Cartão de uma série (cor, forma, tamanhos e nome na legenda).
ui_serie <- function(i, nome) {
  div(class = "serie-cartao",
      div(class = "serie-nome", span(class = "bolinha"), nome),
      div(class = "campos",
          cor_input(paste0("ser_cor_", i), "Cor (vazio = da paleta)", NULL),
          div(class = "campo", selectInput(paste0("ser_forma_", i), "Forma", choices = c("(padrão)" = "", .FORMAS), selectize = FALSE)),
          div(class = "campo", numero_vazio_ok(numericInput(paste0("ser_tamanho_", i), "Tamanho do ponto (pt)", value = NA, min = 0, step = 0.5), NA)),
          div(class = "campo", numero_vazio_ok(numericInput(paste0("ser_linha_", i), "Grossura da linha (pt)", value = NA, min = 0, step = 0.25), NA)),
          div(class = "campo", numero_vazio_ok(numericInput(paste0("ser_borda_", i), "Contorno do ponto (pt)", value = NA, min = 0, step = 0.25), NA)),
          div(class = "campo", textInput(paste0("ser_legenda_", i), "Nome na legenda", value = nome))))
}

guia_rapido <- function() {
  modalDialog(easyClose = TRUE, size = "l", footer = modalButton("Entendi"), title = "Como usar em 4 passos",
    div(class = "guia",
      div(class = "passo", span(class = "num", "1"), div(tags$b("Carregue seus dados"), tags$p("Envie um arquivo CSV (1ª linha com os títulos das colunas) ou escolha um dos exemplos. Escolha o tipo de gráfico."))),
      div(class = "passo", span(class = "num", "2"), div(tags$b("Ajuste os blocos"), tags$p("Cada bloco numerado tem um assunto: intervalos, escala, números, grade, quebra, eixo direito, cores, fonte, legenda... Abra um bloco e mude só o que precisar. O gráfico se atualiza ao lado."))),
      div(class = "passo", span(class = "num", "3"), div(tags$b("Confira o gráfico"), tags$p("A prévia mostra o gráfico como vai sair no arquivo. Os avisos abaixo dela explicam, em português, qualquer problema."))),
      div(class = "passo", span(class = "num", "4"), div(tags$b("Baixe"), tags$p("Escolha o formato (PNG, TIFF, SVG, PDF...). Salve a configuração para repetir depois, ou copie o código para usar no script."))),
      tags$h4("Palavras que aparecem"),
      tags$dl(
        tags$dt("Traço (tick)"), tags$dd("Marca pequena no eixo, ao lado de cada número. Grande = com número; pequeno = entre dois grandes."),
        tags$dt("Intervalo"), tags$dd("A distância entre dois traços grandes: 1 = de 1 em 1, 2 = de 2 em 2."),
        tags$dt("Grade"), tags$dd("Linhas de fundo, uma em cada traço grande."),
        tags$dt("Quebra do eixo"), tags$dd("Corta o trecho vazio entre dois grupos de dados muito distantes."),
        tags$dt("Eixo Y da direita (Y2)"), tags$dd("Um segundo eixo vertical, com escala própria, para séries de outra grandeza."),
        tags$dt("Caixa do gráfico"), tags$dd("A área dentro dos eixos. Com tamanho fixo, ela é igual em todos os gráficos."))))
}
