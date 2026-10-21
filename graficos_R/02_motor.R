# =============================================================================
#  02_motor.R  —  MOTOR DE GRÁFICOS (carregador; não precisa editar)
# =============================================================================
#  Funções para o usuário:
#    ler_csv(arquivo)            lê o CSV (ponto decimal garantido)
#    colunas(dados)              lista as colunas lidas
#    plotar(dados, cfg)          monta o gráfico (ou painéis) a partir do cfg
#    visualizar(g, cfg)          prévia FIEL ao arquivo final (tamanho/fontes)
#    salvar(g, cfg)              exporta nos formatos de cfg$exportacao
#    exportar_lote(pasta, cfg)   mesmo estilo para todos os CSVs de uma pasta
#    salvar_estilo(cfg, nome)    guarda o visual em estilos/<nome>.R
#    carregar_estilo(nome, cfg)  aplica um estilo salvo
#    resetar_cfg()               volta tudo ao padrão do 01_config.R
#    ajuda(), galeria(), mostrar_paletas(), listar_fontes()  (04_catalogo.R)
#
#  O código do motor fica na pasta R/, um assunto por arquivo (leitura, eixos,
#  tema, um arquivo por tipo de gráfico, exportação...). Você continua dando
#  UM único source("02_motor.R"): este arquivo carrega os demais, na ordem.
#  Mantenha a pasta R/ junto do 02_motor.R.
# =============================================================================

# Pasta onde está este arquivo (a do projeto). Funciona mesmo quando o
# source() é feito com caminho completo a partir de outra pasta de trabalho.
.achar_pasta_motor <- function() {
  candidatas <- character(0)
  # source() deixa o caminho do arquivo em 'ofile' no seu quadro de chamada
  for (i in rev(seq_len(sys.nframe()))) {
    quadro <- tryCatch(sys.frame(i), error = function(e) NULL)
    if (!is.null(quadro) && exists("ofile", envir = quadro, inherits = FALSE)) {
      of <- get("ofile", envir = quadro, inherits = FALSE)
      if (is.character(of) && length(of) == 1 && file.exists(of)) {
        candidatas <- c(candidatas, dirname(normalizePath(of, winslash = "/")))
        break
      }
    }
  }
  candidatas <- c(candidatas, getwd())
  ok <- candidatas[file.exists(file.path(candidatas, "R", "01_base.R"))]
  if (!length(ok))
    stop("Não encontrei a pasta 'R' do motor ao lado do 02_motor.R.\n",
         "  Mantenha a pasta do projeto inteira junta e abra o projeto pelo graficos_R.Rproj ",
         "(ou use setwd() para a pasta graficos_R).\n  Procurei em: ",
         paste(unique(candidatas), collapse = " | "), call. = FALSE)
  normalizePath(ok[1], winslash = "/")
}
.motor_pasta <- .achar_pasta_motor()

.MOTOR_ARQUIVOS <- c("01_base.R", "02_paletas_dados.R", "02_cores_texto.R", "02_traducoes_motor.R", "03_leitura.R", "04_validacao.R",
                     "05_series.R", "06_eixos.R", "06_eixos_tempo.R", "07_tema.R", "08_tipos_comum.R",
                     "09_tipo_xy.R", "10_tipo_barras.R", "11_tipo_pizza.R",
                     "12_tipo_distribuicao.R", "13_tipo_boxplot.R", "14_montagem.R",
                     "15_entrada_paineis.R", "15_quebra_continua.R", "16_exportacao.R", "17_estilos.R", "18_painel.R", "19_marcadores.R",
                     "20_legenda_ajuste.R")
for (.a in .MOTOR_ARQUIVOS) source(file.path(.motor_pasta, "R", .a), encoding = "UTF-8")
rm(.a)

if (file.exists(file.path(.motor_pasta, "04_catalogo.R")))
  source(file.path(.motor_pasta, "04_catalogo.R"), encoding = "UTF-8")

message("Motor de gráficos carregado (ggplot2 ", utils::packageVersion("ggplot2"), "). ",
        "Comece por ajuda() ou abra 03_executar.R.")
