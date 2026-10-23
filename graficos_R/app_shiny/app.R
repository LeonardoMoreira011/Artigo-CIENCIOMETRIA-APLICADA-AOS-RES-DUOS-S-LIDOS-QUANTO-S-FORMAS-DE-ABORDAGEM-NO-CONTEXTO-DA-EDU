# =============================================================================
#  CINABRO — laboratório de gráficos (aplicativo Shiny (abre no navegador, sem editar script)
# =============================================================================
#  Como abrir:  no RStudio, abra este arquivo e clique em "Run App"; ou dê dois cliques em abrir_app.bat
#  (Windows); ou, no R:  shiny::runApp("app_shiny").  A pasta graficos_R precisa estar inteira (o app usa o motor
#  de gráficos que fica na pasta acima desta).
# =============================================================================
suppressPackageStartupMessages({ library(shiny) })

raiz <- normalizePath(if (file.exists("../02_motor.R")) ".." else if (file.exists("02_motor.R")) "." else
                      stop("Não achei o motor de gráficos (02_motor.R). Abra o app a partir da pasta graficos_R/app_shiny."),
                      winslash = "/")
source(file.path(raiz, "01_config.R"), encoding = "UTF-8")
suppressMessages(source(file.path(raiz, "02_motor.R"), encoding = "UTF-8"))
CFG0 <- .completar_cfg(cfg)
assign("raiz", raiz, envir = globalenv()); assign("CFG0", CFG0, envir = globalenv())   # usados pelos arquivos de R/
addResourcePath("fontes", file.path(raiz, "fontes"))
for (a in c("idiomas.R", "espec.R", "nucleo.R", "ui_blocos.R", "servidor.R")) source(file.path("codigo", a), encoding = "UTF-8", local = FALSE)

carregar_dicionarios(file.path("idiomas"))

EXEMPLOS <- c("Dois eixos + quebra de eixo (Y esquerdo e direito)" = "exemplo_dois_eixos_e_quebra.csv",
              "Série temporal (eixo de datas)" = "serie_temporal.csv",
              "Ensaio de temperatura (linhas)" = "ensaio_temperatura.csv",
              "Resposta em frequência (escala logarítmica)" = "resposta_frequencia.csv",
              "Resistência de materiais (barras)" = "resistencia_materiais.csv",
              "Composição da liga (pizza)" = "composicao_liga.csv",
              "Replicatas (boxplot)" = "replicatas.csv", "Vários sinais" = "multissinal.csv")
EXEMPLOS <- EXEMPLOS[file.exists(file.path(raiz, "dados", EXEMPLOS))]

construir_ui <- function(idioma) fluidPage(
  title = "Cinabro — laboratório de gráficos",
  tags$head(tags$script(HTML(sprintf("window.IDIOMA = '%s'; $(document).on('shiny:connected', function () { Shiny.setInputValue('idioma_pagina', window.IDIOMA); });", idioma))), tags$link(rel = "icon", type = "image/png", href = "favicon.png"), tags$link(rel = "stylesheet", href = "estilo.css"), tags$script(HTML(paste0("window.PALETAS = ", jsonlite::toJSON(paletas_js(), auto_unbox = TRUE), ";"))), tags$script(src = "app.js"),
            tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"), tags$meta(name = "theme-color", content = "#20242B")),
  tags$header(class = "topo",
    div(class = "marca", div(class = "marca-ico", tags$img(src = "emblema.svg", alt = "Cinabro")),
        div(tags$h1("Cinabro"), tags$p("A punctis ad curvam: ubi data colorem accipiunt."))),
    div(class = "topo-acoes",
        selectInput("idioma_sel", NULL, choices = IDIOMAS, selected = idioma, selectize = FALSE, width = "140px"),
        selectInput("estilo", NULL, choices = tr_nomes(c("Estilos prontos..." = "", "Padrão do template" = "padrao", "Publicação (artigo)" = "publicacao",
                                               "Apresentação (slides)" = "apresentacao")), selectize = FALSE, width = "190px"),
        actionButton("restaurar", "Restaurar tudo", class = "btn-topo"),
        actionButton("guia", "Como usar", class = "btn-topo btn-topo-forte"))),
  div(class = "abas-barra", uiOutput("abas_ui", inline = TRUE),
      div(class = "aba-lado", checkboxInput("lado_ativo", "Mostrar outra aba ao lado", value = FALSE), uiOutput("lado_sel", inline = TRUE))),
  div(class = "area",
    tags$aside(class = "esq",
      div(class = "passos-mini", lapply(seq_along(ESPEC), function(i) tags$a(href = paste0("#bloco-", ESPEC[[i]]$id), title = ESPEC[[i]]$titulo, i))),
      div(class = "cartao dados-cartao",
          tags$h2(span(class = "num", "0"), "Seus dados"),
          tags$p(class = "ajuda", "Envie um CSV ou escolha um exemplo para ver o gráfico funcionando."),
          fileInput("arquivo", NULL, accept = c(".csv", ".txt", ".tsv"), buttonLabel = "Escolher arquivo...", placeholder = "Nenhum arquivo", width = "100%"),
          selectInput("exemplo", NULL, choices = tr_nomes(c("...ou use um exemplo" = "", EXEMPLOS)), selectize = FALSE, width = "100%"),
          uiOutput("resumo_dados")),
      lapply(seq_along(ESPEC), function(i) {
        b <- ESPEC[[i]]
        ui_bloco(b, i, CFG0, aberto = i == 1,
                 extra = if (b$id == "cores") tagList(ui_paleta_propria(), div(class = "grupo", tags$h4("Série por série"),
                          tags$p(class = "ajuda", "Só preencha o que quiser diferente da paleta e dos valores gerais acima."), uiOutput("tabela_series")))
                         else if (b$id == "quebra") conditionalPanel("input.quebra_ativar", div(class = "botoes-config",
                          actionButton("quebra_sugerir", "Achar o maior vazio nos meus dados", class = "btn-verde"),
                          tags$small(class = "ajuda", "Preenche \"de\" e \"até\" com o maior espaço vazio entre os valores do eixo esquerdo.")))
                         else if (b$id == "estatistica") div(class = "grupo", tags$h4("Resultados em números"),
                          tags$p(class = "ajuda", "Tabelas com o resumo de cada série, os ajustes (equação, R², p), os parâmetros e os testes escolhidos. Calcule quando quiser; dá para baixar em CSV."),
                          selectizeInput("estat_testes", "Testes na tabela", choices = tr_nomes(.ITENS_ESTAT[["Testes estatísticos"]]), selected = c("pearson", "shapiro"), multiple = TRUE, options = OPC_SELECTIZE_MULTI),
                          div(class = "botoes-config", actionButton("estat_calcular", "Calcular as tabelas", class = "btn-verde"), downloadButton("estat_baixar", "Baixar em CSV", class = "btn-sec")),
                          div(class = "estat-tabelas", uiOutput("estat_tabelas")))
                                                  else if (b$id == "legenda") div(class = "grupo", tags$h4("Nomes na legenda"), tags$p(class = "ajuda", "Os nomes das séries são editados no bloco 8, em cada série."))
                         else if (b$id == "fonte") div(class = "grupo", tags$h4("Adicionar uma fonte de arquivo"),
                          tags$p(class = "ajuda", "Tem uma fonte em .ttf ou .otf que não está instalada? Escolha o arquivo (e, se quiser negrito/itálico de verdade, os arquivos -Bold, -Italic e -BoldItalic juntos). Ela entra na lista acima. Vale enquanto o app estiver aberto."),
                          textInput("fonte_nome", "Nome da fonte (opcional)", value = "", placeholder = "ex.: Minha Fonte"),
                          fileInput("fonte_arquivo", NULL, multiple = TRUE, accept = c(".ttf", ".otf"), buttonLabel = "Escolher arquivo(s)...", placeholder = "Nenhum arquivo", width = "100%"))
                         )
      }),
      NULL),
    tags$main(class = "dir",
      div(class = "cartao previa-cartao",
          div(class = "previa-barra",
              tags$h2("Prévia"),
              div(class = "previa-ctl", checkboxInput("arrastar", "Arrastar a legenda", TRUE), checkboxInput("auto", "Atualizar sozinho", TRUE),
                  actionButton("atualizar", "Atualizar agora", class = "btn-verde"))),
          div(class = "previa-quadro", uiOutput("estado"), imageOutput("previa", height = "auto"),
              div(id = "legenda-caixa", title = "Arraste para mover; puxe a alça da direita para mudar a largura",
                  span(class = "legenda-rotulo", "legenda"), div(class = "legenda-alca"))),
          uiOutput("info_previa"),
          uiOutput("avisos"),
          uiOutput("previa_lado")),
      div(class = "cartao baixar-cartao",
          tags$h2("Baixar"),
          uiOutput("botoes_baixar"),
          tags$p(class = "ajuda", tags$a(href = "#bloco-exportacao", "Escolher o tipo de arquivo, a resolução e o tamanho (bloco 12)"), ". PNG, TIFF e SVG usam a Barlow direto; no PDF a fonte precisa estar instalada no computador."),
          div(class = "botoes-config",
              actionButton("copiar_modelo", "Copiar modelo", class = "btn-sec", title = "Copia todas as configurações deste gráfico como texto, para colar em outra aba, outro computador ou num e-mail."),
              actionButton("colar_modelo", "Colar modelo...", class = "btn-sec", title = "Cola um modelo copiado antes e aplica aqui (os blocos congelados ficam como estão).")),
          div(class = "botoes-config",
              downloadButton("salvar_cfg", "Salvar configuração", class = "btn-sec"),
              fileInput("carregar_cfg", NULL, accept = ".json", buttonLabel = "Carregar configuração...", placeholder = "", width = "230px"))),
      div(class = "cartao codigo-cartao",
          tags$details(tags$summary(tags$h2("Código equivalente (para usar no script)")),
            tags$p(class = "ajuda", "Estas linhas fazem o mesmo no painel_de_ajustes.R. Copie e cole, ou baixe o script pronto."),
            tags$pre(id = "codigo-txt", textOutput("codigo", inline = TRUE)),
            div(class = "botoes-config", tags$button(type = "button", class = "btn-sec", id = "copiar-codigo", `data-copiado` = "Copiado!", "Copiar"),
                downloadButton("baixar_codigo", "Baixar script (.R)", class = "btn-sec")))))))

# A tela é montada em português e traduzida para o idioma pedido no endereço (?idioma=en | es).
ui <- function(request) {
  idioma <- idioma_do_pedido(request)
  .i18n$idioma <- idioma
  traduzir_html(construir_ui(idioma), idioma)
}

shinyApp(ui, servidor)
