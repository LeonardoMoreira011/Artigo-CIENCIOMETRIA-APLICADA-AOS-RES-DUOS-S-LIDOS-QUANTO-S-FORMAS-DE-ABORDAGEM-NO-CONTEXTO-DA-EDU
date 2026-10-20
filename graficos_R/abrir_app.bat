@echo off
rem ============================================================================
rem  Abre o GERADOR DE GRÁFICOS no navegador (dois cliques neste arquivo).
rem  Precisa do R instalado. Na primeira vez instala o pacote shiny (precisa de internet).
rem ============================================================================
chcp 65001 >nul
cd /d "%~dp0"
set "RS="
where Rscript >nul 2>nul && set "RS=Rscript"
if not defined RS (
  for /d %%d in ("%ProgramFiles%\R\R-*") do if exist "%%d\bin\Rscript.exe" set "RS=%%d\bin\Rscript.exe"
)
if not defined RS (
  echo Nao encontrei o R neste computador. Instale o R e tente de novo.
  pause
  exit /b 1
)
echo Abrindo o gerador de graficos... (feche esta janela para encerrar)
"%RS%" -e "options(repos=c(CRAN='https://cloud.r-project.org')); for (p in c('shiny','ggplot2','scales','patchwork','ragg')) if (!requireNamespace(p, quietly=TRUE)) install.packages(p); shiny::runApp('app_shiny', launch.browser=TRUE)"
pause
