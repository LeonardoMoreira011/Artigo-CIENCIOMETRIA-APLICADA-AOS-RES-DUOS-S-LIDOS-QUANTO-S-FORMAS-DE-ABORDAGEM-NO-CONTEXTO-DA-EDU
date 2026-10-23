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

carregar_dicionarios(file.path("idiomas"))      # (pasta ausente de propósito: só português; veja idiomas_arquivados/)

EXEMPLOS <- c("Dois eixos + quebra de eixo (Y esquerdo e direito)" = "exemplo_dois_eixos_e_quebra.csv",
              "Série temporal (eixo de datas)" = "serie_temporal.csv",
              "Ensaio de temperatura (linhas)" = "ensaio_temperatura.csv",
              "Resposta em frequência (escala logarítmica)" = "resposta_frequencia.csv",
              "Resistência de materiais (barras)" = "resistencia_materiais.csv",
              "Composição da liga (pizza)" = "composicao_liga.csv",
              "Replicatas (boxplot)" = "replicatas.csv", "Vários sinais" = "multissinal.csv")
EXEMPLOS <- EXEMPLOS[file.exists(file.path(raiz, "dados", EXEMPLOS))]

cartao_dados <- function() div(class = "dados-cartao",
  tags$h2("Seus dados"),
  tags$p(class = "ajuda", "Envie um CSV ou escolha um exemplo para ver o gráfico funcionando."),
  fileInput("arquivo", NULL, accept = c(".csv", ".txt", ".tsv"), buttonLabel = "Escolher arquivo...", placeholder = "Nenhum arquivo", width = "100%"),
  selectInput("exemplo", NULL, choices = tr_nomes(c("...ou use um exemplo" = "", EXEMPLOS)), selectize = FALSE, width = "100%"),
  uiOutput("resumo_dados"))

options(shiny.error = function() registrar_log("ERRO não tratado: ", gsub("\n", " | ", substr(geterrmessage(), 1, 400))))   # vai para o registro de uso

construir_ui <- function(idioma) fluidPage(
  title = "Cinabro — laboratório de gráficos",
  tags$head(tags$script(HTML(sprintf("window.IDIOMA = '%s'; $(document).on('shiny:connected', function () { Shiny.setInputValue('idioma_pagina', window.IDIOMA); });", idioma))), tags$link(rel = "icon", type = "image/png", href = "favicon.png"), tags$link(rel = "stylesheet", href = "estilo.css"), tags$script(HTML(paste0("window.PALETAS = ", jsonlite::toJSON(paletas_js(), auto_unbox = TRUE), ";"))), tags$script(src = "app.js"),
            tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"), tags$meta(name = "theme-color", content = "#20242B")),
  tags$header(class = "topo",
    div(class = "marca", div(class = "marca-ico", tags$img(src = "emblema.svg", alt = "Cinabro")),
        div(tags$h1(class = "nome", "Cinabro"), tags$p(class = "frase", "A punctis ad curvam: ubi data colorem accipiunt."),
            div(class = "fio", tags$i(), tags$i(), tags$i(), tags$i()))),
    div(class = "topo-acoes",
        selectInput("estilo", NULL, choices = tr_nomes(c("Estilos prontos..." = "", "Padrão do template" = "padrao", "Publicação (artigo)" = "publicacao",
                                               "Apresentação (slides)" = "apresentacao")), selectize = FALSE, width = "190px"),
        actionButton("restaurar", "Restaurar tudo", class = "btn-topo"),
        actionButton("sair", "Sair", class = "btn-topo", title = "Encerra o Cinabro (fecha o R). Seus gráficos não salvos se perdem: salve a configuração antes."),
        actionButton("guia", "Como usar", class = "btn-topo btn-topo-forte"))),
  div(class = "abas-barra", uiOutput("abas_ui", inline = TRUE),
      div(class = "aba-lado", checkboxInput("lado_ativo", "Mostrar outra aba ao lado", value = FALSE), uiOutput("lado_sel", inline = TRUE))),
  div(class = "estudio gaveta-aberta",
    ui_trilho(),
    tags$aside(class = "gaveta",
      lapply(seq_along(ESPEC), function(i) {
        b <- ESPEC[[i]]
        ui_bloco(b, i, CFG0, aberto = i == 1, antes = if (b$id == "dados") cartao_dados(),
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
    ),
    tags$main(class = "palco",
      ui_faixa(),
      div(class = "cartao previa-cartao",
          div(class = "previa-barra",
              div(class = "previa-ctl", checkboxInput("arrastar", "Mover legenda e caixas com o mouse", TRUE), checkboxInput("auto", "Atualizar sozinho", TRUE),
                  actionButton("atualizar", "Atualizar agora", class = "btn-verde"))),
          div(class = "previa-quadro", uiOutput("estado"), imageOutput("previa", height = "auto"),
              div(id = "legenda-caixa", title = "Arraste para mover; puxe a alça da direita para mudar a largura",
                  span(class = "legenda-rotulo", "legenda"), div(class = "legenda-alca"))),
          div(id = "edicao-rotulos", style = "display:none",
              span(`data-z` = "titulo", "Título do gráfico"), span(`data-z` = "xlab", "Título do eixo X"), span(`data-z` = "ylab", "Título do eixo Y"),
              span(`data-z` = "dica", "Clique para editar o texto, o negrito e o tamanho"), span(`data-z` = "fechar", "Fechar"),
              span(`data-z` = "cx_estatistica", "Caixa de estatística"), span(`data-z` = "cx_texto", "Texto"), span(`data-z` = "cx_forma", "Forma"),
              span(`data-z` = "cx_figura", "Figura"), span(`data-z` = "cx_dica", "Arraste para mover, puxe o quadradinho do canto para mudar o tamanho, clique para editar"),
              span(`data-z` = "cx_mais", "Todas as opções")),
          uiOutput("info_previa"),
          uiOutput("avisos"),
          uiOutput("previa_lado")),
      tags$details(class = "cartao mais-cartao",
          tags$summary(tags$h2("Modelo, configuração e código")),
          tags$p(class = "ajuda", tags$a(href = "#bloco-exportacao", "Escolher o tipo de arquivo, a resolução e o tamanho (bloco 12)"), ". PNG, TIFF e SVG usam a Barlow direto; no PDF a fonte precisa estar instalada no computador."),
          div(class = "botoes-config",
              actionButton("copiar_modelo", "Copiar modelo", class = "btn-sec", title = "Copia todas as configurações deste gráfico como texto, para colar em outra aba, outro computador ou num e-mail."),
              actionButton("colar_modelo", "Colar modelo...", class = "btn-sec", title = "Cola um modelo copiado antes e aplica aqui (os blocos congelados ficam como estão).")),
          div(class = "botoes-config",
              downloadButton("salvar_cfg", "Salvar configuração", class = "btn-sec"),
              fileInput("carregar_cfg", NULL, accept = ".json", buttonLabel = "Carregar configuração...", placeholder = "", width = "230px")),
          tags$h4("Código equivalente (para usar no script)"),
          tags$p(class = "ajuda", "Estas linhas fazem o mesmo no painel_de_ajustes.R. Copie e cole, ou baixe o script pronto."),
          tags$pre(id = "codigo-txt", textOutput("codigo", inline = TRUE)),
          div(class = "botoes-config", tags$button(type = "button", class = "btn-sec", id = "copiar-codigo", `data-copiado` = "Copiado!", "Copiar"),
              downloadButton("baixar_codigo", "Baixar script (.R)", class = "btn-sec"))))))

# A tela é montada em português UMA vez, ao abrir o programa, e a mesma serve a todas as abas e recarregamentos. Antes ela era refeita a cada
# página aberta (cerca de 2 s com o R parado, medidos na auditoria). O idioma pedido no endereço é ignorado: só português.
.UI_PRONTA <- traduzir_html(construir_ui("pt"), "pt")
# Montar o HTML final a partir das tags também custava ~1 s por página (5,5 mil tags): a resposta pronta do shiny é guardada na 1ª visita e
# reaproveitada. Se o shiny não oferecer esse caminho, cai para a tela montada (UI_PRONTA), que é a versão segura.
.UI_RESPOSTA <- NULL
ui <- function(request) {
  if (is.null(.UI_RESPOSTA))
    .UI_RESPOSTA <<- tryCatch({ r <- utils::getFromNamespace("uiHttpHandler", "shiny")(.UI_PRONTA)(request); if (inherits(r, "httpResponse")) r else NULL }, error = function(e) NULL)
  if (is.null(.UI_RESPOSTA)) .UI_PRONTA else .UI_RESPOSTA
}

# Aquecimento: o primeiro gráfico de um R recém-aberto leva alguns segundos a mais (fontes, pacotes). Desenha um gráfico pequeno agora, ao abrir,
# para que o primeiro gráfico de verdade já saia rápido. Qualquer falha aqui é ignorada.
try(local({
  dm <- suppressMessages(ler_csv(file.path(raiz, "dados", "ensaio_temperatura.csv"), utils::modifyList(CFG0$dados, list(relatorio = FALSE))))
  r <- construir_grafico(dm, montar_variaveis(list(), CFG0, NULL), CFG0)
  if (is.null(r$erro)) { p <- desenhar_previa(r$g, r$cfg, dpi = 72); unlink(p$arquivo) }
}), silent = TRUE)

shinyApp(ui, servidor)
