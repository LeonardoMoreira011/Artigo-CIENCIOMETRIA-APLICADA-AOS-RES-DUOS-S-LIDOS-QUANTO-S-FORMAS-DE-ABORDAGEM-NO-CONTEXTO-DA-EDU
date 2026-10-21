@echo off
setlocal EnableExtensions
chcp 65001 >nul
rem ============================================================================
rem  Cria o atalho "Cinabro" (com icone) na area de trabalho e no menu Iniciar.
rem  O atalho abre o gerador SEM janela de comando. Rode este arquivo uma vez.
rem  Antes, de dois cliques em abrir_app.bat uma vez (ele instala o que falta).
rem  IMPORTANTE: extraia o ZIP inteiro numa pasta (nao rode de dentro do ZIP).
rem ============================================================================
pushd "%~dp0"
if not exist "iniciar_gerador_oculto.vbs" (
  echo.
  echo Nao achei os outros arquivos do gerador nesta pasta. Extraia o ZIP INTEIRO ^(botao direito ^> Extrair tudo^)
  echo e rode este arquivo de dentro da pasta extraida.
  goto :fim
)

rem 1) jeito principal: VBScript (nao depende do PowerShell)
set "OK="
cscript //nologo "%~dp0criar_atalho.vbs"
if not errorlevel 1 set "OK=1"

rem 2) se falhar: PowerShell
if not defined OK if exist "%~dp0criar_atalho.ps1" (
  echo Tentando pelo PowerShell...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0criar_atalho.ps1"
  if not errorlevel 1 set "OK=1"
)

rem 3) ultimo recurso: um arquivo .cmd na area de trabalho (sem icone) que abre o gerador
if not defined OK (
  set "DESK="
  if defined OneDriveCommercial if exist "%OneDriveCommercial%\Desktop" set "DESK=%OneDriveCommercial%\Desktop"
  if not defined DESK if defined OneDrive if exist "%OneDrive%\Desktop" set "DESK=%OneDrive%\Desktop"
  if not defined DESK if exist "%USERPROFILE%\Desktop" set "DESK=%USERPROFILE%\Desktop"
  if defined DESK (
    > "%DESK%\Cinabro.cmd" echo @echo off
    >> "%DESK%\Cinabro.cmd" echo call "%~dp0abrir_app.bat"
    if exist "%DESK%\Cinabro.cmd" (
      echo.
      echo O Windows bloqueou a criacao do atalho com icone. Criei no lugar o arquivo
      echo "%DESK%\Cinabro.cmd" ^(abre o Cinabro; sem icone, com janela de comando^).
      set "OK=1"
    )
  )
)

if defined OK (
  echo.
  echo Pronto! Procure "Cinabro" na area de trabalho ^(ou no menu Iniciar^).
) else (
  echo.
  echo Nao consegui criar o atalho automaticamente ^(talvez o computador bloqueie scripts^). Faca assim: clique com o
  echo botao direito em iniciar_gerador_oculto.vbs, "Enviar para" ^> "Area de trabalho ^(criar atalho^)"; depois, no
  echo atalho, "Propriedades" ^> "Alterar icone" ^> escolha app_shiny\www\icone.ico
)
:fim
echo.
popd
pause
