# =============================================================================
#  abrir_app.R — abre o GERADOR DE GRÁFICOS no navegador (RStudio: Source, ou rode no console)
# =============================================================================
#  Na primeira vez instala o pacote shiny (precisa de internet). Depois é só rodar de novo.
# =============================================================================
if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny", repos = "https://cloud.r-project.org")
pasta <- if (dir.exists("app_shiny")) "app_shiny" else if (dir.exists("graficos_R/app_shiny")) "graficos_R/app_shiny" else
  stop("Abra o RStudio na pasta graficos_R (ou use setwd() para ela) e rode de novo.")
shiny::runApp(pasta, launch.browser = TRUE)
