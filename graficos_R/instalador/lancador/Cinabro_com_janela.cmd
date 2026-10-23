@echo off
rem Abre o Cinabro COM janela de comando (para diagnostico: mostra as mensagens do R).
rem Use se o atalho normal nao abrir. Feche esta janela para encerrar o Cinabro.
chcp 65001 >nul
set "BASE=%~dp0"
set "R_LIBS=%BASE%biblioteca"
set "R_LIBS_USER=%BASE%biblioteca"
cd /d "%BASE%graficos_R"
"%BASE%R\bin\x64\Rscript.exe" -e "source('app_shiny/iniciar.R', encoding='UTF-8'); iniciar_gerador(encerrar_ao_fechar = TRUE)"
echo.
echo O Cinabro terminou. Se houve erro, copie as mensagens acima.
pause
