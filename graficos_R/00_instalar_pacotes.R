# =============================================================================
#  00_instalar_pacotes.R — rode UMA vez (ou quando quiser atualizar)
# =============================================================================
#  Instala/atualiza os pacotes usados pelo template. No notebook corporativo,
#  se não houver permissão de administrador, os pacotes vão para a sua pasta
#  pessoal de bibliotecas (criada automaticamente).
#
#  Se a rede da empresa usar proxy e o download falhar, descomente e ajuste:
#  Sys.setenv(https_proxy = "http://usuario:senha@proxy.empresa.com:8080")
#  Sys.setenv(http_proxy  = "http://usuario:senha@proxy.empresa.com:8080")
# =============================================================================

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Versões mínimas testadas
minimos <- c(
  ggplot2   = "3.5.0",   # gradientes, ticks menores, legenda "inside"  (testado 3.5.2 e 4.0.3)
  scales    = "1.3.0",   # transformações de eixo (testado 1.4.0)
  patchwork = "1.2.0",   # painéis empilhados (testado 1.3.2)
  ragg      = "1.5.0",   # PNG/TIFF/JPEG de qualidade; < 1.5 tem bug no gradiente radial
  systemfonts = "1.0.0"  # fontes: Barlow oficial (fontes/Barlow) e todas as instaladas no computador
)
opcionais <- c(
  svglite      = "2.1.0",  # SVG editável (Inkscape/Illustrator)
  devEMF       = "4.0",    # EMF para colar no Word/PowerPoint
  viridisLite  = "0.4.0",  # paletas viridis/magma/plasma/cividis
  RColorBrewer = "1.1-3",  # paletas brewer_*
  png          = "0.1-7",  # figuras anexadas ao gráfico (logotipo, esquema): PNG
  jpeg         = "0.1-9",  # figuras anexadas ao gráfico: JPEG
  shiny        = "1.7.0"   # aplicativo no navegador (app_shiny/, abrir_app.bat)
)

# Pasta de instalação: a padrão, ou a pessoal se a padrão não for gravável
lib <- .libPaths()[1]
if (file.access(lib, 2) != 0) {
  lib <- Sys.getenv("R_LIBS_USER")
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(lib, .libPaths()))
  message("Sem permissão na pasta padrão; instalando em: ", lib)
}

precisa <- function(p, v) {
  !requireNamespace(p, quietly = TRUE) || utils::packageVersion(p) < v
}
instalar <- function(lista, obrigatorio) {
  for (p in names(lista)) {
    if (precisa(p, lista[[p]])) {
      message(">> Instalando/atualizando ", p, " (>= ", lista[[p]], ")")
      tryCatch(utils::install.packages(p, lib = lib, dependencies = c("Depends", "Imports", "LinkingTo"),
                                       type = if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")),
               error = function(e) message("   Falhou: ", conditionMessage(e)))
    }
  }
}
instalar(minimos, TRUE)
instalar(opcionais, FALSE)

cat("\n================ RESULTADO ================\n")
ok <- TRUE
for (p in names(c(minimos, opcionais))) {
  v <- c(minimos, opcionais)[[p]]
  tem <- requireNamespace(p, quietly = TRUE)
  ver <- if (tem) as.character(utils::packageVersion(p)) else "-"
  st <- if (!tem) "FALTA" else if (utils::packageVersion(p) < v) "ANTIGO" else "ok"
  obrig <- p %in% names(minimos)
  if (obrig && st != "ok") ok <- FALSE
  cat(sprintf("  %-13s %-9s %-7s %s\n", p, ver, st, if (obrig) "(obrigatório)" else "(opcional)"))
}
cat(sprintf("  R             %-9s %s\n", as.character(getRversion()),
            if (getRversion() >= "4.2.0") "ok" else "ANTIGO: gradientes exigem R >= 4.2"))
if (ok) {
  cat("\nTudo pronto. Agora abra 03_executar.R e rode linha a linha (Ctrl+Enter).\n")
} else {
  cat("\nAlgum pacote obrigatório falhou. Causas comuns no notebook corporativo:\n",
      " 1) proxy: ajuste Sys.setenv(https_proxy=...) no topo deste arquivo;\n",
      " 2) bloqueio do CRAN: peça à TI liberação de https://cloud.r-project.org;\n",
      " 3) RStudio aberto com pacotes carregados: reinicie a sessão (Ctrl+Shift+F10) e rode de novo.\n")
}

cat("\nDICA RStudio: Tools > Global Options > General > Graphics > Backend = \"AGG\"\n",
    "  (deixa a aba Plots com as mesmas fontes e gradientes do arquivo final).\n", sep = "")
