# =============================================================================
#  app_shiny/iniciar.R — abre o Cinabro no navegador, com endereço fixo e bonito
# =============================================================================
#  iniciar_gerador()                  # abre em  http://127.0.0.1:8421  (endereço simples: funciona com proxy e IPv6)
#  iniciar_gerador(encerrar_ao_fechar = TRUE)   # o R também fecha sozinho quando você fecha a aba (para o atalho sem janela)
# =============================================================================
iniciar_gerador <- function(pasta = NULL, encerrar_ao_fechar = FALSE, porta = 8421L, nome = "127.0.0.1", abrir = TRUE) {
  if (is.null(pasta)) pasta <- if (file.exists("app.R")) "." else if (dir.exists("app_shiny")) "app_shiny" else "graficos_R/app_shiny"
  arq_pacotes <- file.path(pasta, "pacotes.R")                    # instala sozinho o que faltar (1ª abertura); depois só confere
  if (file.exists(arq_pacotes)) { source(arq_pacotes, encoding = "UTF-8"); if (!garantir_pacotes()) stop("Faltam pacotes do Cinabro (veja a mensagem acima).", call. = FALSE) }
  else if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny", repos = "https://cloud.r-project.org")
  livre <- function(p) { s <- tryCatch(httpuv::startServer("127.0.0.1", p, list()), error = function(e) NULL)
                         if (is.null(s)) FALSE else { httpuv::stopServer(s); TRUE } }
  if (!livre(porta)) porta <- httpuv::randomPort()               # a porta fixa já está em uso (outro gerador aberto?)
  options(gerador_encerrar_ao_fechar = isTRUE(encerrar_ao_fechar))
  abrir_navegador <- function(url) {
    bonito <- sub("127.0.0.1", nome, url, fixed = TRUE)
    message("Cinabro em:  ", bonito, "   (ou ", url, ")")
    utils::browseURL(bonito)
  }
  shiny::runApp(pasta, port = porta, host = "127.0.0.1", launch.browser = if (abrir) abrir_navegador else FALSE)
}
