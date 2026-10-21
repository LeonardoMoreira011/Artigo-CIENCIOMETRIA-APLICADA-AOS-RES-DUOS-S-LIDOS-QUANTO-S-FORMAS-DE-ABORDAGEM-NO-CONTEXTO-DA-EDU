# Cria os atalhos "Cinabro" (área de trabalho e menu Iniciar), com ícone, sem janela de comando.
$pasta = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbs   = Join-Path $pasta 'iniciar_gerador_oculto.vbs'
$icone = Join-Path $pasta 'app_shiny\www\icone.ico'
$ws    = New-Object -ComObject WScript.Shell
$destinos = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))
foreach ($d in $destinos) {
  if (-not (Test-Path $d)) { continue }
  $lnk = $ws.CreateShortcut((Join-Path $d 'Cinabro.lnk'))
  $lnk.TargetPath       = Join-Path $env:WINDIR 'System32\wscript.exe'
  $lnk.Arguments        = '"' + $vbs + '"'
  $lnk.WorkingDirectory = $pasta
  $lnk.IconLocation     = $icone + ',0'
  $lnk.Description      = 'Cinabro - laboratório de gráficos (abre no navegador)'
  $lnk.Save()
  Write-Host ('Atalho criado em: ' + $d)
}
