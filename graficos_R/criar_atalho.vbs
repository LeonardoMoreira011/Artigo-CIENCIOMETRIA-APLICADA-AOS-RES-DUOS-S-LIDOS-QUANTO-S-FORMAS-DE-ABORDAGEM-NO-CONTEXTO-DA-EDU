' ============================================================================
'  Cria o atalho "Gerador de graficos" (com icone) na area de trabalho e no menu Iniciar.
'  Chamado por Criar_atalho_na_area_de_trabalho.bat (nao precisa do PowerShell).
' ============================================================================
Option Explicit
Dim sh, fso, pasta, vbs, icone, destinos, i, d, lnk, n
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
pasta = fso.GetParentFolderName(WScript.ScriptFullName)
vbs = pasta & "\iniciar_gerador_oculto.vbs"
icone = pasta & "\app_shiny\www\icone.ico"
If Not fso.FileExists(vbs) Then
  WScript.Echo "Nao achei iniciar_gerador_oculto.vbs em " & pasta & ". Extraia o ZIP inteiro antes (nao rode de dentro do ZIP)."
  WScript.Quit 2
End If
destinos = Array(sh.SpecialFolders("Desktop"), sh.SpecialFolders("Programs"))
n = 0
For i = 0 To 1
  d = destinos(i)
  If d <> "" Then
    If fso.FolderExists(d) Then
      On Error Resume Next
      Set lnk = sh.CreateShortcut(d & "\Gerador de graficos.lnk")
      lnk.TargetPath = sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\wscript.exe"
      lnk.Arguments = """" & vbs & """"
      lnk.WorkingDirectory = pasta
      If fso.FileExists(icone) Then lnk.IconLocation = icone & ",0"
      lnk.Description = "Gerador de graficos (abre no navegador)"
      lnk.Save
      If Err.Number = 0 Then
        n = n + 1
        WScript.Echo "Atalho criado em: " & d
      Else
        WScript.Echo "Nao consegui criar em " & d & ": " & Err.Description
      End If
      Err.Clear
      On Error GoTo 0
    End If
  End If
Next
If n = 0 Then WScript.Quit 1
