# Monta a "carga" do instalador em instalador\stage: R portátil + pacotes fixos + o Cinabro + lançadores.
# uso (na pasta graficos_R, com o R 4.5 x64 no PATH):  powershell -File instalador\montar.ps1 -Foto 2026-02-01
param([string]$Foto = "2026-02-01")
$ErrorActionPreference = "Stop"
$aqui = $PSScriptRoot
$proj = (Resolve-Path (Join-Path $aqui "..")).Path
$stage = Join-Path $aqui "stage"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null

# 1) R portátil: copia a instalação do R que está no PATH (sem documentação nem testes)
$rhome = (& Rscript -e "cat(normalizePath(R.home(), winslash='\\'))").Trim()
if (-not (Test-Path (Join-Path $rhome "bin\x64\Rscript.exe"))) { throw "R x64 não encontrado em $rhome" }
Write-Host "R de origem: $rhome"
robocopy $rhome (Join-Path $stage "R") /E /XD doc tests demos /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy do R falhou ($LASTEXITCODE)" }
$global:LASTEXITCODE = 0
$rs = Join-Path $stage "R\bin\x64\Rscript.exe"

# 2) pacotes, sempre da mesma foto do CRAN, com o R que vai junto
& $rs (Join-Path $aqui "instalar_pacotes.R") (Join-Path $stage "biblioteca") $Foto
if ($LASTEXITCODE -ne 0) { throw "instalação dos pacotes falhou" }

# 3) o Cinabro (só o que o programa precisa para rodar; sem testes, relatórios nem arquivos de desenvolvimento)
$dest = Join-Path $stage "graficos_R"
robocopy $proj $dest /E /XD saida ferramentas idiomas_arquivados instalador stage manual .git /XF "Rplots.pdf" "*.Rproj" "*.bat" "*.vbs" "*.ps1" "caminho_do_R.txt" ".pronto" "06_testes.R" "05_exemplos.R" "07_verificar_windows.R" "testes_app.R" "AUDITORIA.md" "RELATORIO_REVISAO.md" "abrir_app.R" "00_instalar_pacotes.R" "03_executar.R" /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy do app falhou ($LASTEXITCODE)" }
$global:LASTEXITCODE = 0

# 4) lançadores e versão
Copy-Item (Join-Path $aqui "lancador\*") $stage
Copy-Item (Join-Path $aqui "VERSAO.txt") $stage

$mb = [math]::Round(((Get-ChildItem $stage -Recurse -File | Measure-Object Length -Sum).Sum) / 1MB)
Write-Host "Carga montada em $stage ($mb MB)"
