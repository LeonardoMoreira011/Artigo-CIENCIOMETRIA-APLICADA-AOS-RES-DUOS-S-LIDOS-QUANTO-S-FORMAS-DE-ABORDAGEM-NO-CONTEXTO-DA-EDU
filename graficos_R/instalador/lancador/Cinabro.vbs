' ============================================================================
'  Abre o CINABRO sem janela de comando (usado pelos atalhos do instalador).
'  Se ja estiver aberto, so abre o navegador de novo. Se o R nao subir em ~30 s,
'  avisa e mostra onde esta o registro (%LOCALAPPDATA%\Cinabro\log\inicio.log).
' ============================================================================
Option Explicit
Dim sh, fso, base, rs, logd, logf, cmd, i, ok, env, q, url, msg
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
q = Chr(34)
url = "http://127.0.0.1:8421/"
base = fso.GetParentFolderName(WScript.ScriptFullName)

If Responde(url) Then
  sh.Run url, 1, False
  WScript.Quit 0
End If

rs = base & "\R\bin\x64\Rscript.exe"
If Not fso.FileExists(rs) Then
  sh.Popup "Nao achei o R dentro da pasta do Cinabro (" & base & "\R)." & vbCrLf & "Reinstale o Cinabro.", 30, "Cinabro", 16
  WScript.Quit 1
End If

logd = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Cinabro\log"
If Not fso.FolderExists(sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Cinabro") Then fso.CreateFolder sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Cinabro"
If Not fso.FolderExists(logd) Then fso.CreateFolder logd
logf = logd & "\inicio.log"

' so os pacotes que vieram com o instalador (nada da biblioteca pessoal do usuario)
Set env = sh.Environment("Process")
env("R_LIBS") = base & "\biblioteca"
env("R_LIBS_USER") = base & "\biblioteca"
sh.CurrentDirectory = base & "\graficos_R"

cmd = "cmd /c " & q & q & rs & q & " -e " & q & "source('app_shiny/iniciar.R', encoding='UTF-8'); iniciar_gerador(encerrar_ao_fechar = TRUE)" & q & " > " & q & logf & q & " 2>&1" & q
sh.Run cmd, 0, False

ok = False
For i = 1 To 60
  WScript.Sleep 500
  If Responde(url) Then
    ok = True
    Exit For
  End If
Next
If Not ok Then
  msg = "O Cinabro nao abriu em 30 segundos." & vbCrLf & vbCrLf & "Se o navegador nao abrir sozinho, tente de novo em instantes." & vbCrLf & "Para ver o que aconteceu, abra este arquivo e mande para quem cuida do programa:" & vbCrLf & logf
  sh.Popup msg, 60, "Cinabro", 48
End If

Function Responde(u)
  Dim h
  Responde = False
  On Error Resume Next
  Set h = CreateObject("MSXML2.ServerXMLHTTP.6.0")
  h.setProxy 1                      ' direto: o endereco local nao passa pelo proxy da empresa
  h.setTimeouts 500, 500, 1500, 1500
  h.open "GET", u, False
  h.send
  If Err.Number = 0 Then
    If h.status = 200 Then Responde = True
  End If
  Err.Clear
  On Error GoTo 0
End Function
