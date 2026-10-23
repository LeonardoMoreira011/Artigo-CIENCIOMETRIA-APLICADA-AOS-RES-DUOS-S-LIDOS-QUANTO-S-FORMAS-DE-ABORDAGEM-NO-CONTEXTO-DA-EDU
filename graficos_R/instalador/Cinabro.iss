; Instalador do Cinabro (Inno Setup 6). Compilar:  ISCC /DVersao=0.1.0 instalador\Cinabro.iss   (depois de rodar montar.ps1)
; Instala só para o usuário atual (sem administrador), em %LOCALAPPDATA%\Programs\Cinabro.
#ifndef Versao
  #define Versao "0.1.0"
#endif

[Setup]
AppId={{8B6F3C2E-5D41-4C9A-9E27-C1AB0C11AB01}
AppName=Cinabro
AppVersion={#Versao}
AppVerName=Cinabro {#Versao}
AppPublisher=Equipe Cinabro
DefaultDirName={localappdata}\Programs\Cinabro
DefaultGroupName=Cinabro
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=stage\graficos_R\app_shiny\www\icone.ico
UninstallDisplayIcon={app}\graficos_R\app_shiny\www\icone.ico
UninstallDisplayName=Cinabro
OutputDir=saida
OutputBaseFilename=Cinabro-Setup-{#Versao}
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar um atalho na área de trabalho"; GroupDescription: "Atalhos:"

[Dirs]
Name: "{localappdata}\Cinabro\log"

[InstallDelete]
; atualização limpa: nada de arquivo sobrando de uma versão anterior
Type: filesandordirs; Name: "{app}\R"
Type: filesandordirs; Name: "{app}\biblioteca"
Type: filesandordirs; Name: "{app}\graficos_R"

[Files]
Source: "stage\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\Cinabro"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Cinabro.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\graficos_R\app_shiny\www\icone.ico"; Comment: "Cinabro - laboratório de gráficos (abre no navegador)"
Name: "{autoprograms}\Cinabro (com janela, para diagnóstico)"; Filename: "{app}\Cinabro_com_janela.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\graficos_R\app_shiny\www\icone.ico"
Name: "{autoprograms}\Cinabro - registro de uso (para suporte)"; Filename: "{sys}\explorer.exe"; Parameters: """{localappdata}\Cinabro\log"""
Name: "{autodesktop}\Cinabro"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\Cinabro.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\graficos_R\app_shiny\www\icone.ico"; Tasks: desktopicon

[Run]
Filename: "{sys}\wscript.exe"; Parameters: """{app}\Cinabro.vbs"""; Description: "Abrir o Cinabro agora"; Flags: nowait postinstall skipifsilent
