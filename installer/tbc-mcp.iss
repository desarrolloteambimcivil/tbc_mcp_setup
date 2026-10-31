; ============================================================================================
;  TBC-MCP Setup (Inno Setup 6): tbc-revit-mcp + tbc-acad-mcp in one installer.
;  Build with installer\build.ps1, which extracts both release ZIPs into installer\payload and
;  passes the versions. Do not compile this file directly.
; ============================================================================================
;
;  Each product keeps its own install.ps1, which checks, rolls back and reports every step.
;  This wizard detects Revit and AutoCAD/Civil 3D, lets the user pick the components and the AI
;  assistants, runs each install.ps1 and gives the suite a single uninstaller.
;
;  Per-user install: add-ins and bundles go to %APPDATA%\Autodesk and the servers to
;  %LOCALAPPDATA%, so no administrator rights are needed.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef RevitVersion
  #define RevitVersion "?"
#endif
#ifndef AcadVersion
  #define AcadVersion "?"
#endif

#define AppName "TBC-MCP"
#define AppPublisher "Nour Rouas - TeamBIMCivil"
#define RepoUrl "https://github.com/desarrolloteambimcivil/tbc_mcp_setup"
; AppId of the standalone tbc-revit-mcp installer, which this suite replaces.
#define RevitStandaloneKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\{9F3C2B71-5E84-4D0A-B6E2-7A41C9D85F13}_is1"

[Setup]
AppId={{3E7A0C52-91B4-4F6D-8C2A-5D17E9B4A260}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#RepoUrl}
AppSupportURL={#RepoUrl}/issues
AppUpdatesURL={#RepoUrl}/releases/latest
VersionInfoVersion={#AppVersion}
VersionInfoCompany=TeamBIMCivil
VersionInfoDescription=TBC-MCP Setup (tbc-revit-mcp {#RevitVersion}, tbc-acad-mcp {#AcadVersion})
VersionInfoCopyright=Copyright 2026 Nour Rouas. Based on rvt-mcp and dwg-mcp by Bimwright (Apache-2.0)

; Each install.ps1 decides where its files go; this folder only keeps the packages for
; uninstall and repair, so the user is not asked for a directory.
DefaultDirName={localappdata}\NourRouas\tbc-mcp\setup
DisableDirPage=yes
DisableProgramGroupPage=yes
UsePreviousAppDir=no
; Components follow what is installed on this computer now, not the previous run.
UsePreviousSetupType=no
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible

OutputDir=output
OutputBaseFilename=TbcMcp_Setup_{#AppVersion}
SetupIconFile=assets\teambimcivil.ico
UninstallDisplayIcon={app}\teambimcivil.ico
UninstallDisplayName={#AppName} {#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
DisableWelcomePage=no
WizardImageFile=assets\wizard-large.bmp
WizardSmallImageFile=assets\wizard-small.bmp
LicenseFile=..\LICENSE
ShowLanguageDialog=auto

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "custom"; Description: "custom"; Flags: iscustom

[Components]
Name: "revit"; Description: "{cm:CompRevit}"; Types: custom
Name: "acad"; Description: "{cm:CompAcad}"; Types: custom
#ifdef WithSkills
Name: "skills"; Description: "{cm:CompSkills}"; Types: custom
#endif

[Files]
; The extracted release ZIPs, each with its own install.ps1, uninstall.ps1 and manifest.json.
Source: "payload\revit\*"; DestDir: "{app}\revit"; Components: revit; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "payload\acad\*"; DestDir: "{app}\acad"; Components: acad; Flags: ignoreversion recursesubdirs createallsubdirs
#ifdef WithSkills
Source: "payload\skills\*"; DestDir: "{app}\skills"; Components: skills; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "skills.ps1"; DestDir: "{app}"; Components: skills; Flags: ignoreversion
#endif
Source: "payload\suite.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "assets\teambimcivil.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\NOTICE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[UninstallRun]
; Per product: first the client entries and the add-ins or bundle, then the server copies.
; Personal data (settings, logs, ledger, ToolBaker) is kept.
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\revit\install.ps1"" -Uninstall -Client auto"; Components: revit; Flags: runhidden waituntilterminated; RunOnceId: "RevitClientsAndAddins"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\revit\uninstall.ps1"" -Yes"; Components: revit; Flags: runhidden waituntilterminated; RunOnceId: "RevitServer"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\acad\install.ps1"" -Uninstall -Client auto"; Components: acad; Flags: runhidden waituntilterminated; RunOnceId: "AcadClientsAndBundle"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\acad\uninstall.ps1"" -Yes"; Components: acad; Flags: runhidden waituntilterminated; RunOnceId: "AcadServer"
#ifdef WithSkills
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\skills.ps1"" -Uninstall -Record ""{app}\skills-installed.json"""; Components: skills; Flags: runhidden waituntilterminated; RunOnceId: "Skills"
#endif

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Messages]
spanish.WelcomeLabel2=Se va a instalar [name/ver] en este equipo.%n%nTBC-MCP conecta Claude y otros asistentes de IA con Autodesk Revit 2022–2027 (tbc-revit-mcp {#RevitVersion}) y con AutoCAD y Civil 3D 2022–2027 (tbc-acad-mcp {#AcadVersion}). El asistente puede leer un plano DWG y modelarlo en Revit en la misma conversación.%n%nCierra Revit, AutoCAD y tus asistentes de IA (Claude Code, Claude Desktop…) antes de continuar.
english.WelcomeLabel2=This will install [name/ver] on your computer.%n%nTBC-MCP connects Claude and other AI assistants to Autodesk Revit 2022–2027 (tbc-revit-mcp {#RevitVersion}) and to AutoCAD and Civil 3D 2022–2027 (tbc-acad-mcp {#AcadVersion}). The assistant can read a DWG drawing and model it in Revit in the same conversation.%n%nClose Revit, AutoCAD and your AI assistants (Claude Code, Claude Desktop…) before continuing.
spanish.FinishedLabel=[name] se ha instalado.%n%nAbre Revit o AutoCAD y reinicia tu asistente de IA. Después pídele, por ejemplo: «¿En qué vista de Revit estoy?» o «¿Qué capas tiene el plano abierto?».
english.FinishedLabel=[name] has been installed.%n%nOpen Revit or AutoCAD and restart your AI assistant. Then ask, for example: "Which Revit view am I in?" or "Which layers does the open drawing have?".

[CustomMessages]
spanish.CompRevit=Revit 2022–2027 · tbc-revit-mcp {#RevitVersion}
spanish.CompAcad=AutoCAD y Civil 3D 2022–2027 · tbc-acad-mcp {#AcadVersion}
spanish.CompSkills=Skills de Claude Code de TeamBIMCivil
spanish.NotFound=%1 (no instalado en este equipo)
spanish.NoHost=No se ha encontrado Revit ni AutoCAD/Civil 3D 2022–2027 en este equipo. TBC-MCP necesita al menos uno de los dos.
spanish.NothingSelected=Elige al menos un programa.
spanish.ClientsCaption=Asistentes de IA
spanish.ClientsHeading=¿Con qué asistentes de IA quieres usar TBC-MCP?
spanish.ClientsHint=Se añaden las entradas «tbc-revit-mcp» y «tbc-acad-mcp» a su configuración (con copia de seguridad). Los detectados en este equipo ya están marcados.
spanish.ClientClaudeCode=Claude Code
spanish.ClientClaudeDesktop=Claude Desktop
spanish.ClientCursor=Cursor
spanish.ClientCodex=Codex
spanish.CloseFirst=Cierra estos programas y pulsa Siguiente para volver a comprobarlo:%n%n%1%nLos asistentes de IA (Claude Code, Claude Desktop, Cursor…) mantienen los servidores en uso mientras están abiertos.
spanish.CloseFirstUninstall=Cierra estos programas y vuelve a ejecutar la desinstalación:%n%n%1
spanish.StandaloneFailed=No se ha podido quitar la instalación anterior de tbc-revit-mcp. Desinstálala desde Configuración → Aplicaciones y vuelve a ejecutar este instalador.
spanish.RemovingStandalone=Quitando la instalación anterior de tbc-revit-mcp (se conservan tus datos)…
spanish.RunningRevit=Instalando los complementos de Revit y configurando los asistentes…
spanish.RunningAcad=Instalando el complemento de AutoCAD/Civil 3D y configurando los asistentes…
spanish.RunningSkills=Instalando las skills de Claude Code…
spanish.Failed=La instalación de %1 no se ha completado y se ha dejado como estaba.%n%nDetalles en:%n%2
spanish.FailedFinished=Alguna parte no se ha instalado: %1. Revisa los registros en %2 y vuelve a ejecutar el instalador.
english.CompRevit=Revit 2022–2027 · tbc-revit-mcp {#RevitVersion}
english.CompAcad=AutoCAD and Civil 3D 2022–2027 · tbc-acad-mcp {#AcadVersion}
english.CompSkills=TeamBIMCivil Claude Code skills
english.NotFound=%1 (not installed on this computer)
english.NoHost=Neither Revit nor AutoCAD/Civil 3D 2022–2027 was found on this computer. TBC-MCP needs at least one of them.
english.NothingSelected=Choose at least one program.
english.ClientsCaption=AI assistants
english.ClientsHeading=Which AI assistants do you want to use TBC-MCP with?
english.ClientsHint=The "tbc-revit-mcp" and "tbc-acad-mcp" entries are added to their configuration (a backup is made first). Assistants found on this computer are already ticked.
english.ClientClaudeCode=Claude Code
english.ClientClaudeDesktop=Claude Desktop
english.ClientCursor=Cursor
english.ClientCodex=Codex
english.CloseFirst=Close these programs, then click Next to check again:%n%n%1%nAI assistants (Claude Code, Claude Desktop, Cursor…) keep the servers in use while they are open.
english.CloseFirstUninstall=Close these programs, then run the uninstaller again:%n%n%1
english.StandaloneFailed=The previous tbc-revit-mcp installation could not be removed. Uninstall it from Settings → Apps and run this installer again.
english.RemovingStandalone=Removing the previous tbc-revit-mcp installation (your data is kept)…
english.RunningRevit=Installing the Revit add-ins and wiring your AI assistants…
english.RunningAcad=Installing the AutoCAD/Civil 3D plugin and wiring your AI assistants…
english.RunningSkills=Installing the Claude Code skills…
english.Failed=Installing %1 did not complete and it was left as it was.%n%nDetails:%n%2
english.FailedFinished=Some parts were not installed: %1. Check the logs in %2 and run the installer again.

[Code]
var
  ClientsPage: TInputOptionWizardPage;
  HasRevit, HasAcad, ComponentsSet: Boolean;
  FailedParts: String;

{ Running processes whose name matches one of the given names, one per line. A WMI failure
  returns an empty list: the check is a convenience and each install.ps1 checks again. }
function RunningProcesses(const Names: array of String): String;
var
  Locator, Service, Items, Item: Variant;
  Query, Name: String;
  I: Integer;
begin
  Result := '';
  Query := '';
  for I := 0 to GetArrayLength(Names) - 1 do
  begin
    if Query <> '' then Query := Query + ' OR ';
    Query := Query + 'Name = ''' + Names[I] + '''';
  end;
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Service := Locator.ConnectServer('.', 'root\CIMV2');
    Items := Service.ExecQuery('SELECT Name FROM Win32_Process WHERE ' + Query);
    for I := 0 to Items.Count - 1 do
    begin
      Item := Items.ItemIndex(I);
      Name := Item.Name;
      if Pos(Name, Result) = 0 then
        Result := Result + '  • ' + Name + #13#10;
    end;
  except
    Result := '';
  end;
end;

{ A year counts when its executable exists, the same rule both install.ps1 scripts use.
  Civil 3D installs into the AutoCAD folder of its year, so acad.exe covers it. }
function HostInstalled(const Folder, Exe: String): Boolean;
var
  Year: Integer;
begin
  Result := False;
  for Year := 2022 to 2027 do
    if FileExists(ExpandConstant('{commonpf64}\Autodesk\') + Folder + ' ' + IntToStr(Year) + '\' + Exe) then
      Result := True;
end;

function ClaudeDesktopPresent(): Boolean;
var
  FindRec: TFindRec;
begin
  Result := DirExists(ExpandConstant('{userappdata}\Claude')) or DirExists(ExpandConstant('{localappdata}\AnthropicClaude'));
  if not Result and FindFirst(ExpandConstant('{localappdata}\Packages\Claude_*'), FindRec) then
  begin
    Result := True;
    FindClose(FindRec);
  end;
end;

function InitializeSetup(): Boolean;
begin
  HasRevit := HostInstalled('Revit', 'Revit.exe');
  HasAcad := HostInstalled('AutoCAD', 'acad.exe');
  Result := HasRevit or HasAcad;
  if not Result then
    MsgBox(CustomMessage('NoHost'), mbError, MB_OK);
end;

{ A product whose program is missing stays visible but cannot be ticked. }
procedure SetComponent(Index: Integer; Present: Boolean; const Caption: String);
begin
  WizardForm.ComponentsList.Checked[Index] := Present;
  WizardForm.ComponentsList.ItemEnabled[Index] := Present;
  if not Present then
    WizardForm.ComponentsList.ItemCaption[Index] := FmtMessage(CustomMessage('NotFound'), [Caption]);
end;

procedure InitializeWizard();
begin
  ClientsPage := CreateInputOptionPage(wpSelectComponents,
    CustomMessage('ClientsCaption'), CustomMessage('ClientsHeading'), CustomMessage('ClientsHint'),
    False, False);
  ClientsPage.Add(CustomMessage('ClientClaudeCode'));
  ClientsPage.Add(CustomMessage('ClientClaudeDesktop'));
  ClientsPage.Add(CustomMessage('ClientCursor'));
  ClientsPage.Add(CustomMessage('ClientCodex'));
  ClientsPage.Values[0] := FileExists(ExpandConstant('{%USERPROFILE}\.claude.json'));
  ClientsPage.Values[1] := ClaudeDesktopPresent();
  ClientsPage.Values[2] := DirExists(ExpandConstant('{%USERPROFILE}\.cursor'));
  ClientsPage.Values[3] := DirExists(ExpandConstant('{%USERPROFILE}\.codex'));
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectComponents) and not WizardIsComponentSelected('revit') and not WizardIsComponentSelected('acad') then
  begin
    MsgBox(CustomMessage('NothingSelected'), mbError, MB_OK);
    Result := False;
  end;
end;

{ install.ps1 client names for the ticked boxes (the same names in both products); none keeps
  every client config untouched. }
function SelectedClients(): String;
begin
  Result := '';
  if ClientsPage.Values[0] then Result := Result + ',claude';
  if ClientsPage.Values[1] then Result := Result + ',claude-desktop';
  if ClientsPage.Values[2] then Result := Result + ',cursor';
  if ClientsPage.Values[3] then Result := Result + ',codex';
  if Result = '' then Result := 'none' else Delete(Result, 1, 1);
end;

function ProgramsToClose(): String;
begin
  Result := '';
  if WizardIsComponentSelected('revit') then
    Result := Result + RunningProcesses(['Revit.exe', 'tbc-revit-mcp.exe', 'RvtMcp.Server.exe', 'rvt-mcp.exe']);
  if WizardIsComponentSelected('acad') then
    Result := Result + RunningProcesses(['acad.exe', 'tbc-acad-mcp.exe']);
end;

{ The standalone tbc-revit-mcp installer and this suite would install the same add-ins and
  server, and either uninstaller would remove them under the other. Its uninstaller keeps the
  user's data; the suite then installs the same files again. Inno's uninstaller hands over to a
  copy of itself, so wait until its registry entry is gone rather than for the process. }
function RemoveStandaloneRevit(): Boolean;
var
  Command: String;
  ResultCode, Waited: Integer;
begin
  Result := True;
  if not RegQueryStringValue(HKCU, '{#RevitStandaloneKey}', 'UninstallString', Command) then
    Exit;
  WizardForm.PreparingLabel.Caption := CustomMessage('RemovingStandalone');
  Exec(RemoveQuotes(Command), '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Waited := 0;
  while RegKeyExists(HKCU, '{#RevitStandaloneKey}') and (Waited < 120) do
  begin
    Sleep(500);
    Waited := Waited + 1;
  end;
  Result := not RegKeyExists(HKCU, '{#RevitStandaloneKey}');
end;

{ Runs before any file is copied. Revit and AutoCAD lock the add-in DLLs and an open AI
  assistant keeps the installed servers running, so replacing them would fail. }
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Running: String;
begin
  Result := '';
  Running := ProgramsToClose();
  if Running <> '' then
    Result := FmtMessage(CustomMessage('CloseFirst'), [Running])
  else if WizardIsComponentSelected('revit') and not RemoveStandaloneRevit() then
    Result := CustomMessage('StandaloneFailed');
end;

{ Runs one install.ps1 with its output in a log; the script throws on failure after rolling
  its own changes back. }
function RunScript(const Script, Arguments, Log, Status: String): Boolean;
var
  Command: String;
  ResultCode: Integer;
begin
  WizardForm.StatusLabel.Caption := Status;
  Command := '-NoProfile -ExecutionPolicy Bypass -Command "& { try { & ''' + Script + ''' ' + Arguments +
    ' *>&1 | Out-File -FilePath ''' + Log + ''' -Encoding utf8; exit 0 } catch { $_ | Out-File -FilePath ''' + Log +
    ''' -Append -Encoding utf8; exit 1 } }"';
  Result := Exec('powershell.exe', Command, ExpandConstant('{app}'), SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure InstallPart(const Part, Name, Arguments, Status: String);
var
  Script, Log: String;
begin
  if Part = 'skills' then Script := ExpandConstant('{app}\skills.ps1')
  else Script := ExpandConstant('{app}\') + Part + '\install.ps1';
  { Logs stay outside the product folders: install.ps1 checks those against their manifest. }
  Log := ExpandConstant('{app}\install-') + Part + '.log';
  if not RunScript(Script, Arguments, Log, Status) then
  begin
    if FailedParts <> '' then FailedParts := FailedParts + ', ';
    FailedParts := FailedParts + Name;
    MsgBox(FmtMessage(CustomMessage('Failed'), [Name, Log]), mbError, MB_OK);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep <> ssPostInstall then Exit;
  { A silent install skips the components page, so a missing program is checked here too. }
  if WizardIsComponentSelected('revit') and HasRevit then
    InstallPart('revit', 'tbc-revit-mcp', '-Client ' + SelectedClients(), CustomMessage('RunningRevit'));
  if WizardIsComponentSelected('acad') and HasAcad then
    InstallPart('acad', 'tbc-acad-mcp', '-Client ' + SelectedClients(), CustomMessage('RunningAcad'));
#ifdef WithSkills
  if WizardIsComponentSelected('skills') then
    InstallPart('skills', 'skills', '-Source ''' + ExpandConstant('{app}\skills') + ''' -Record ''' + ExpandConstant('{app}\skills-installed.json') + '''', CustomMessage('RunningSkills'));
#endif
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  { Once, on the first visit: Inno fills the list from the setup type before this point, and
    going Back must keep what the user changed. }
  if (CurPageID = wpSelectComponents) and not ComponentsSet then
  begin
    SetComponent(0, HasRevit, CustomMessage('CompRevit'));
    SetComponent(1, HasAcad, CustomMessage('CompAcad'));
    ComponentsSet := True;
  end;
  if (CurPageID = wpFinished) and (FailedParts <> '') then
    WizardForm.FinishedLabel.Caption := FmtMessage(CustomMessage('FailedFinished'), [FailedParts, ExpandConstant('{app}')]);
end;

function InitializeUninstall(): Boolean;
var
  Running: String;
begin
  Running := RunningProcesses(['Revit.exe', 'acad.exe', 'tbc-revit-mcp.exe', 'RvtMcp.Server.exe', 'tbc-acad-mcp.exe']);
  Result := Running = '';
  if not Result then
    MsgBox(FmtMessage(CustomMessage('CloseFirstUninstall'), [Running]), mbError, MB_OK);
end;
