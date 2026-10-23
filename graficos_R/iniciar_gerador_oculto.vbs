' ============================================================================
'  Abre o CINABRO (laboratorio de graficos) no navegador SEM janela de comando.
'  Use pelo atalho da area de trabalho (veja Criar_atalho_na_area_de_trabalho.bat).
'  O R fecha sozinho 10 minutos depois que voce fecha a aba do navegador (ou na hora, pelo botao Sair do Cinabro).
' ============================================================================
Option Explicit
Dim sh, fso, pasta, rs, f, cmd
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
pasta = fso.GetParentFolderName(WScript.ScriptFullName)
sh.CurrentDirectory = pasta
rs = ""

' 1) caminho que voce ja informou antes (caminho_do_R.txt)
If fso.FileExists(pasta & "\caminho_do_R.txt") Then
  Set f = fso.OpenTextFile(pasta & "\caminho_do_R.txt", 1)
  If Not f.AtEndOfStream Then rs = Trim(f.ReadLine)
  f.Close
  If Not fso.FileExists(rs) Then rs = ""
End If

' 2) registro do Windows
If rs = "" Then rs = DoRegistro("HKCU\SOFTWARE\R-core\R\InstallPath")
If rs = "" Then rs = DoRegistro("HKLM\SOFTWARE\R-core\R\InstallPath")

' 3) pastas comuns (a versao mais nova vence)
If rs = "" Then rs = DaPasta(sh.ExpandEnvironmentStrings("%ProgramFiles%") & "\R")
If rs = "" Then rs = DaPasta(sh.ExpandEnvironmentStrings("%ProgramW6432%") & "\R")
If rs = "" Then rs = DaPasta(sh.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\R")
If rs = "" Then rs = DaPasta(sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\R")
If rs = "" Then rs = DaPasta(sh.ExpandEnvironmentStrings("%USERPROFILE%") & "\R")
If rs = "" Then rs = DaPasta("C:\R")

' primeira vez (pacotes ainda nao instalados) ou R nao encontrado: abre o abrir_app.bat com janela, que resolve tudo
If rs = "" Or Not fso.FileExists(pasta & "\app_shiny\.pronto") Then
  sh.Run """" & pasta & "\abrir_app.bat""", 1, False
  WScript.Quit
End If

cmd = """" & rs & """ -e ""source('app_shiny/iniciar.R', encoding='UTF-8'); iniciar_gerador(encerrar_ao_fechar = TRUE)"""
sh.Run cmd, 0, False        ' 0 = janela oculta

Function DoRegistro(chave)
  Dim v
  DoRegistro = ""
  On Error Resume Next
  v = sh.RegRead(chave)
  If Err.Number = 0 Then
    If fso.FileExists(v & "\bin\Rscript.exe") Then DoRegistro = v & "\bin\Rscript.exe"
  End If
  Err.Clear
  On Error GoTo 0
End Function

Function DaPasta(raiz)
  Dim sub1, melhor, nomeMelhor
  DaPasta = ""
  melhor = "" : nomeMelhor = ""
  If Not fso.FolderExists(raiz) Then Exit Function
  For Each sub1 In fso.GetFolder(raiz).SubFolders
    If LCase(Left(sub1.Name, 2)) = "r-" Then
      If fso.FileExists(sub1.Path & "\bin\Rscript.exe") Then
        If melhor = "" Or sub1.Name > nomeMelhor Then melhor = sub1.Path & "\bin\Rscript.exe" : nomeMelhor = sub1.Name
      End If
    End If
  Next
  DaPasta = melhor
End Function
