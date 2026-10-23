@echo off
setlocal EnableExtensions
chcp 65001 >nul
rem ============================================================================
rem  Abre o CINABRO (laboratorio de graficos) no navegador (dois cliques neste arquivo).
rem  Procura o R sozinho (PATH, registro do Windows e as pastas de instalacao mais comuns).
rem  Se nao achar, pergunta o caminho do Rscript.exe uma vez e guarda em caminho_do_R.txt.
rem  Na primeira vez instala TODOS os pacotes necessarios sozinho (precisa de internet; pode levar alguns minutos).
rem ============================================================================
pushd "%~dp0"
if not exist "app_shiny\app.R" (
  echo.
  echo Nao achei a pasta app_shiny aqui. Extraia o ZIP INTEIRO ^(botao direito ^> Extrair tudo^) e rode este arquivo
  echo de dentro da pasta extraida.
  pause
  exit /b 1
)
set "RS="

rem 1) caminho que voce ja informou antes (caminho_do_R.txt)
if exist "caminho_do_R.txt" set /p RS=<"caminho_do_R.txt"
if defined RS if not exist "%RS%" set "RS="

rem 2) R no PATH
if not defined RS for /f "delims=" %%p in ('where Rscript 2^>nul') do if not defined RS set "RS=%%p"

rem 3) registro do Windows (instalacao do R)
if not defined RS call :registro HKCU
if not defined RS call :registro HKLM

rem 4) pastas de instalacao mais comuns (a versao mais nova vence)
if not defined RS call :pasta "%ProgramFiles%\R"
if not defined RS call :pasta "%ProgramW6432%\R"
if not defined RS call :pasta "%ProgramFiles(x86)%\R"
if not defined RS call :pasta "%LOCALAPPDATA%\Programs\R"
if not defined RS call :pasta "%USERPROFILE%\R"
if not defined RS call :pasta "%USERPROFILE%\Documents\R"
if not defined RS call :pasta "C:\R"

if defined RS goto :rodar

:perguntar
echo.
echo Nao encontrei o R automaticamente neste computador.
echo Procure o arquivo Rscript.exe (por exemplo em C:\Program Files\R\R-4.4.1\bin\ ou em
echo %LOCALAPPDATA%\Programs\R\R-4.4.1\bin\), clique nele com o botao direito, escolha "Copiar como caminho"
echo e cole abaixo (clique com o botao direito na janela para colar).
echo.
set "RS="
set /p "RS=Caminho do Rscript.exe: "
if not defined RS goto :semR
set "RS=%RS:"=%"
if not exist "%RS%" goto :semR
> "caminho_do_R.txt" echo %RS%
goto :rodar

:semR
echo.
echo Arquivo nao encontrado. Se o R nao estiver instalado, instale-o em https://cran.r-project.org
echo Alternativa: abra o RStudio, abra o arquivo abrir_app.R e clique em Source.
pause
exit /b 1

:rodar
echo.
echo R encontrado: %RS%
echo Abrindo o Cinabro no navegador (http://127.0.0.1:8421)...
echo Esta janela fecha sozinha 10 minutos depois que voce fechar a aba do navegador (ou na hora, pelo botao Sair do Cinabro). Para nao ver a janela, use Criar_atalho_na_area_de_trabalho.bat.
"%RS%" -e "source('app_shiny/pacotes.R', encoding='UTF-8'); if (!garantir_pacotes()) quit(status = 1); file.create('app_shiny/.pronto'); source('app_shiny/iniciar.R', encoding='UTF-8'); iniciar_gerador(encerrar_ao_fechar = TRUE)"
if errorlevel 1 (
  echo.
  echo O R terminou com erro ^(veja as mensagens acima^). Se faltou internet na primeira vez, conecte e rode de novo.
  pause
  exit /b 1
)
exit /b 0

:registro
for /f "tokens=2,*" %%a in ('reg query "%~1\Software\R-core\R" /v InstallPath 2^>nul ^| find "InstallPath"') do if exist "%%b\bin\Rscript.exe" set "RS=%%b\bin\Rscript.exe"
exit /b 0

:pasta
for /d %%d in ("%~1\R-*") do if exist "%%d\bin\Rscript.exe" set "RS=%%d\bin\Rscript.exe"
exit /b 0
