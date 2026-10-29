# Instala, na pasta dada, os pacotes que o Cinabro usa, sempre da MESMA foto do CRAN (Posit Package Manager),
# para todo mundo ter exatamente as mesmas versões. uso: Rscript instalar_pacotes.R <pasta_da_biblioteca> <data AAAA-MM-DD>
args <- commandArgs(TRUE)
lib <- normalizePath(args[1], winslash = "/", mustWork = FALSE); foto <- args[2]
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .Library))
repo <- paste0("https://packagemanager.posit.co/cran/", foto)
options(repos = c(CRAN = repo), pkgType = "binary", Ncpus = 2L)
pacotes <- c("shiny", "ggplot2", "scales", "patchwork", "ragg", "systemfonts", "jsonlite", "gtable", "later", "htmltools",
             "png", "jpeg", "svglite", "devEMF", "base64enc", "viridisLite", "sf", "vegan", "ggrepel")
cat("Repositório:", repo, "\nDestino:", lib, "\n")
utils::install.packages(pacotes, lib = lib, type = "binary", dependencies = c("Depends", "Imports", "LinkingTo"))
falta <- setdiff(pacotes, rownames(utils::installed.packages(lib.loc = lib)))
if (length(falta)) stop("Não instalou: ", paste(falta, collapse = ", "))
for (p in pacotes) suppressPackageStartupMessages(library(p, character.only = TRUE, lib.loc = lib))   # carrega de verdade: acusa DLL faltando
ins <- utils::installed.packages(lib.loc = lib)[, c("Package", "Version")]
ins <- ins[order(ins[, "Package"]), , drop = FALSE]
writeLines(c(paste("R", getRversion()), paste("Foto do CRAN:", foto), "", paste(ins[, "Package"], ins[, "Version"])),
           file.path(dirname(lib), "versoes_dos_pacotes.txt"))
cat(nrow(ins), "pacotes instalados.\n")
