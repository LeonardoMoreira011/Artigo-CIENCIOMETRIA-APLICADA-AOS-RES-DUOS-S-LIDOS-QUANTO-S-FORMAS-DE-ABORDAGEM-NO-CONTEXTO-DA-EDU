# =============================================================================
#  app_shiny/pacotes.R — garante, sozinho, todos os pacotes que o Cinabro usa
# =============================================================================
#  Chamado pelo abrir_app.bat (e por iniciar.R / app.R): na PRIMEIRA abertura baixa o que falta do CRAN (precisa de internet,
#  leva alguns minutos); nas seguintes só confere (menos de 1 s). Ninguém precisa rodar o 00_instalar_pacotes.R.
#  Sem permissão de escrita na pasta de pacotes do R (comum em notebook corporativo), usa a biblioteca pessoal do usuário.
#  No Windows baixa pacotes já compilados (não precisa de Rtools).
# =============================================================================

# versão mínima testada de cada pacote
.PACOTES_OBRIGATORIOS <- c(shiny = "1.7.0", ggplot2 = "3.5.0", scales = "1.3.0", patchwork = "1.2.0", ragg = "1.5.0",   # ragg < 1.5: bug no gradiente radial
                           systemfonts = "1.0.0", jsonlite = "1.8.0", gtable = "0.3.0", later = "1.3.0", htmltools = "0.5.0", httpuv = "1.6.0")
# sem estes o programa abre, mas perde um recurso (figuras anexadas, SVG, EMF, paletas magma/inferno/turbo)
.PACOTES_OPCIONAIS <- c(png = "0.1-7", jpeg = "0.1-9", svglite = "2.1.0", devEMF = "4.0", viridisLite = "0.4.0", base64enc = "0.1-3")

garantir_pacotes <- function(instalar = TRUE) {
  falta <- function(lista) names(lista)[!vapply(names(lista), function(p)
    tryCatch(utils::packageVersion(p) >= lista[[p]], error = function(e) FALSE), NA)]
  fo <- falta(.PACOTES_OBRIGATORIOS); fp <- falta(.PACOTES_OPCIONAIS)
  if (!length(fo) && !length(fp)) return(invisible(TRUE))
  if (!instalar) return(invisible(!length(fo)))

  message("\n== Cinabro: primeira abertura ==\nInstalando os pacotes que faltam (precisa de internet; pode levar alguns minutos):\n  ",
          paste(c(fo, fp), collapse = ", "), "\n")
  # onde instalar: a pasta padrão do R se der para gravar; senão a biblioteca pessoal
  gravaveis <- .libPaths()[file.access(.libPaths(), 2) == 0]
  if (length(gravaveis)) lib <- gravaveis[1] else {
    lib <- Sys.getenv("R_LIBS_USER")
    if (!nzchar(lib)) lib <- file.path(Sys.getenv("LOCALAPPDATA", unset = path.expand("~")), "R", "win-library",
                                       paste(R.version$major, sub("\\..*$", "", R.version$minor), sep = "."))
    dir.create(lib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(lib, .libPaths()))
    message("Sem permissão na pasta padrão do R; instalando na sua pasta pessoal: ", lib)
  }
  r <- getOption("repos")
  if (is.null(r) || any(r == "@CRAN@")) options(repos = c(CRAN = "https://cloud.r-project.org"))
  tipo <- if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")
  tryCatch(utils::install.packages(c(fo, fp), lib = lib, type = tipo, dependencies = c("Depends", "Imports", "LinkingTo")),
           error = function(e) message("Falhou: ", conditionMessage(e)))

  fo <- falta(.PACOTES_OBRIGATORIOS); fp <- falta(.PACOTES_OPCIONAIS)
  if (length(fp)) message("Aviso: não consegui instalar (o programa abre, mas sem o recurso): ", paste(fp, collapse = ", "))
  if (length(fo)) {
    message("\nNÃO consegui instalar pacotes que o Cinabro precisa: ", paste(fo, collapse = ", "),
            "\nConfira a internet (na rede da empresa pode precisar do proxy: Sys.setenv(https_proxy = \"http://usuario:senha@proxy:porta\")) e abra de novo.")
    return(invisible(FALSE))
  }
  message("Pacotes prontos.\n")
  invisible(TRUE)
}
