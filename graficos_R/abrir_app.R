# =============================================================================
#  abrir_app.R — abre o CINABRO (laboratório de gráficos) no navegador (RStudio: Source, ou rode no console)
# =============================================================================
#  Abre em http://127.0.0.1:8421 . Na primeira vez instala o pacote shiny (precisa de internet).
# =============================================================================
pasta <- if (dir.exists("app_shiny")) "app_shiny" else if (dir.exists("graficos_R/app_shiny")) "graficos_R/app_shiny" else
  stop("Abra o RStudio na pasta graficos_R (ou use setwd() para ela) e rode de novo.")
source(file.path(pasta, "iniciar.R"), encoding = "UTF-8")
iniciar_gerador(pasta)
