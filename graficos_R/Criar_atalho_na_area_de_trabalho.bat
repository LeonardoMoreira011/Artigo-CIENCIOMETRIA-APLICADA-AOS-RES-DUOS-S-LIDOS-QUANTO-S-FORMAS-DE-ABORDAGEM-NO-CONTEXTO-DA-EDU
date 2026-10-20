@echo off
setlocal EnableExtensions
chcp 65001 >nul
rem ============================================================================
rem  Cria o atalho "Gerador de graficos" (com icone) na area de trabalho e no menu Iniciar.
rem  O atalho abre o gerador SEM janela de comando. Rode este arquivo uma vez.
rem  Antes, de dois cliques em abrir_app.bat uma vez (ele instala o que falta).
rem ============================================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0criar_atalho.ps1"
if errorlevel 1 (
  echo.
  echo Nao consegui criar o atalho automaticamente. Faca assim: clique com o botao direito em
  echo iniciar_gerador_oculto.vbs, "Enviar para" ^> "Area de trabalho (criar atalho)"; depois, no atalho,
  echo "Propriedades" ^> "Alterar icone" ^> escolha app_shiny\www\icone.ico
) else (
  echo.
  echo Pronto! Procure "Gerador de graficos" na area de trabalho (ou no menu Iniciar).
)
echo.
pause
