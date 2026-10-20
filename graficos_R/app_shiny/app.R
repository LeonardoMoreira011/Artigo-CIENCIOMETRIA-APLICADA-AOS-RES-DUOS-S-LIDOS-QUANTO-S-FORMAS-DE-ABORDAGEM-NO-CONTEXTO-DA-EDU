# =============================================================================
#  GERADOR DE GRÁFICOS — aplicativo Shiny (abre no navegador, sem editar script)
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
for (a in c("espec.R", "nucleo.R", "ui_blocos.R", "servidor.R")) source(file.path("codigo", a), encoding = "UTF-8", local = FALSE)

EXEMPLOS <- c("Dois eixos + quebra de eixo (Y esquerdo e direito)" = "exemplo_dois_eixos_e_quebra.csv",
              "Série temporal (eixo de datas)" = "serie_temporal.csv",
              "Ensaio de temperatura (linhas)" = "ensaio_temperatura.csv",
              "Resposta em frequência (escala logarítmica)" = "resposta_frequencia.csv",
              "Resistência de materiais (barras)" = "resistencia_materiais.csv",
              "Composição da liga (pizza)" = "composicao_liga.csv",
              "Replicatas (boxplot)" = "replicatas.csv", "Vários sinais" = "multissinal.csv")
EXEMPLOS <- EXEMPLOS[file.exists(file.path(raiz, "dados", EXEMPLOS))]

ui <- fluidPage(
  title = "Gerador de gráficos",
  tags$head(tags$link(rel = "icon", type = "image/png", href = "favicon.png"), tags$link(rel = "stylesheet", href = "estilo.css"), tags$script(src = "app.js"),
            tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")),
  tags$header(class = "topo",
    div(class = "marca", div(class = "marca-ico", HTML("&#9650;")),
        div(tags$h1("Gerador de gráficos"), tags$p("Monte, ajuste e baixe seus gráficos sem escrever código"))),
    div(class = "topo-acoes",
        selectInput("estilo", NULL, choices = c("Estilos prontos..." = "", "Padrão do template" = "padrao", "Publicação (artigo)" = "publicacao",
                                               "Apresentação (slides)" = "apresentacao"), selectize = FALSE, width = "190px"),
        actionButton("restaurar", "Restaurar tudo", class = "btn-topo"),
        actionButton("guia", "Como usar", class = "btn-topo btn-topo-forte"))),
  div(class = "area",
    tags$aside(class = "esq",
      div(class = "passos-mini", lapply(seq_along(ESPEC), function(i) tags$a(href = paste0("#bloco-", ESPEC[[i]]$id), title = ESPEC[[i]]$titulo, i))),
      div(class = "cartao dados-cartao",
          tags$h2(span(class = "num", "0"), "Seus dados"),
          tags$p(class = "ajuda", "Envie um CSV ou escolha um exemplo para ver o gráfico funcionando."),
          fileInput("arquivo", NULL, accept = c(".csv", ".txt", ".tsv"), buttonLabel = "Escolher arquivo...", placeholder = "Nenhum arquivo", width = "100%"),
          selectInput("exemplo", NULL, choices = c("...ou use um exemplo" = "", EXEMPLOS), selectize = FALSE, width = "100%"),
          uiOutput("resumo_dados")),
      lapply(seq_along(ESPEC), function(i) {
        b <- ESPEC[[i]]
        ui_bloco(b, i, CFG0, aberto = i == 1,
                 extra = if (b$id == "cores") div(class = "grupo", tags$h4("Série por série"),
                          tags$p(class = "ajuda", "Só preencha o que quiser diferente da paleta e dos valores gerais acima."), uiOutput("tabela_series"))
                         else if (b$id == "legenda") div(class = "grupo", tags$h4("Nomes na legenda"), tags$p(class = "ajuda", "Os nomes das séries são editados no bloco 8, em cada série."))
                         else if (b$id == "fonte") div(class = "grupo", tags$h4("Adicionar uma fonte de arquivo"),
                          tags$p(class = "ajuda", "Tem uma fonte em .ttf ou .otf que não está instalada? Escolha o arquivo (e, se quiser negrito/itálico de verdade, os arquivos -Bold, -Italic e -BoldItalic juntos). Ela entra na lista acima. Vale enquanto o app estiver aberto."),
                          textInput("fonte_nome", "Nome da fonte (opcional)", value = "", placeholder = "ex.: Minha Fonte"),
                          fileInput("fonte_arquivo", NULL, multiple = TRUE, accept = c(".ttf", ".otf"), buttonLabel = "Escolher arquivo(s)...", placeholder = "Nenhum arquivo", width = "100%"))
                         )
      }),
      div(class = "rodape", "Fonte oficial: Barlow (SIL Open Font License).")),
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
          uiOutput("avisos")),
      div(class = "cartao baixar-cartao",
          tags$h2("Baixar"),
          div(class = "botoes-baixar",
              downloadButton("baixar_png", "PNG", class = "btn-baixar"), downloadButton("baixar_tiff", "TIFF", class = "btn-baixar"),
              downloadButton("baixar_jpeg", "JPEG", class = "btn-baixar"), downloadButton("baixar_svg", "SVG", class = "btn-baixar"),
              downloadButton("baixar_pdf", "PDF", class = "btn-baixar")),
          tags$p(class = "ajuda", "Resolução e tamanho: bloco 12. PNG, TIFF e SVG usam a Barlow direto; no PDF a fonte precisa estar instalada no computador."),
          div(class = "botoes-config",
              downloadButton("salvar_cfg", "Salvar configuração", class = "btn-sec"),
              fileInput("carregar_cfg", NULL, accept = ".json", buttonLabel = "Carregar configuração...", placeholder = "", width = "230px"))),
      div(class = "cartao codigo-cartao",
          tags$details(tags$summary(tags$h2("Código equivalente (para usar no script)")),
            tags$p(class = "ajuda", "Estas linhas fazem o mesmo no painel_de_ajustes.R. Copie e cole, ou baixe o script pronto."),
            tags$pre(id = "codigo-txt", textOutput("codigo", inline = TRUE)),
            div(class = "botoes-config", tags$button(type = "button", class = "btn-sec", id = "copiar-codigo", "Copiar"),
                downloadButton("baixar_codigo", "Baixar script (.R)", class = "btn-sec")))))))

shinyApp(ui, servidor)
