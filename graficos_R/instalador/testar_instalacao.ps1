# Testa uma instalação do Cinabro: o motor gera os arquivos e o app sobe pelo mesmo lançador dos atalhos.
# uso: powershell -File instalador\testar_instalacao.ps1 -Pasta <pasta onde o Cinabro está instalado (ou instalador\stage)>
param([Parameter(Mandatory = $true)][string]$Pasta)
$ErrorActionPreference = "Stop"
$aqui = $PSScriptRoot
$Pasta = (Resolve-Path $Pasta).Path
$rs = Join-Path $Pasta "R\bin\x64\Rscript.exe"
$env:R_LIBS = Join-Path $Pasta "biblioteca"; $env:R_LIBS_USER = $env:R_LIBS

Write-Host "== 1) motor + exportação (PNG, PDF, SVG) com o R e os pacotes instalados =="
$saida = Join-Path $env:TEMP "cinabro_fumaca"
& $rs (Join-Path $aqui "teste_motor_instalado.R") (Join-Path $Pasta "graficos_R") $saida
if ($LASTEXITCODE -ne 0) { throw "teste do motor falhou" }

Write-Host "== 2) o app sobe pelo lançador dos atalhos (Cinabro.vbs) =="
Get-Process Rscript -ErrorAction SilentlyContinue | Stop-Process -Force
$log = Join-Path $env:LOCALAPPDATA "Cinabro\log\inicio.log"
if (Test-Path $log) { Remove-Item $log -Force }
Start-Process -FilePath "$env:WINDIR\System32\wscript.exe" -ArgumentList "`"$(Join-Path $Pasta 'Cinabro.vbs')`""
$ok = $false; $html = ""
for ($i = 0; $i -lt 90 -and -not $ok; $i++) {
  Start-Sleep -Seconds 2
  try { $r = Invoke-WebRequest -Uri "http://127.0.0.1:8421/" -UseBasicParsing -TimeoutSec 5 -Proxy $null; if ($r.StatusCode -eq 200) { $ok = $true; $html = $r.Content } } catch { }
}
if (Test-Path $log) { Write-Host "---- inicio.log ----"; Get-Content $log -Tail 40; Write-Host "--------------------" }
if (-not $ok) { throw "o Cinabro não respondeu em http://127.0.0.1:8421/" }
if ($html -notmatch "CINABRO|Cinabro") { throw "a página abriu, mas não parece ser o Cinabro" }
Write-Host "Página do Cinabro no ar ($($html.Length) bytes)."
foreach ($arq in @("app.js", "estilo.css")) {
  $r = Invoke-WebRequest -Uri "http://127.0.0.1:8421/$arq" -UseBasicParsing -TimeoutSec 10 -Proxy $null
  if ($r.StatusCode -ne 200 -or $r.Content.Length -lt 1000) { throw "$arq não foi servido direito" }
}
Get-Process Rscript -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "FUMACA_OK"
