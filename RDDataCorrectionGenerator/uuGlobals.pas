unit uuGlobals;

interface

uses
   Classes, ufDBEDatabase;

type
  TSettings = Record
     SchemaDir : String;
     SQLDir : string;
     SQLAutoComplete : Boolean;
     CallDir : string;
     PayrollId : string;
  end;

procedure ReadIni;
function OpenFile(var aNotChosen : Boolean;
   aCaption : String; aDefaultFolder : String; aOwner: TComponent) : String;
function SaveFile(var aNotChosen : Boolean;
   aCaption : String; aDefaultFile, aDefaultFolder : String; aOwner: TComponent) : String;
function ChooseFolder(var aNotChosen : Boolean;
   aCaption : String; aDefaultFolder : String; aOwner: TComponent) : String;
procedure SetupRDConnection(var aDBEDatabase : TDBEDatabase);
function GetBusinessObject(aTableName : String) : string;

const
  DC_INI = 'RDDataCorrection.ini';

var
   gSettings : TSettings;
   gWin7 : Boolean;
   gAppPath : string;

implementation

uses
   Dialogs, FileCtrl, SysUtils, IniFiles, ShellAPI;

procedure ReadIni;
var
   DCIni : TIniFile;
   lValue : string;
begin
   DCIni := TIniFile.Create(gAppPath + DC_INI);
   try
      gSettings.SchemaDir       := DCIni.ReadString('General', 'SchemaDir', '');
      gSettings.SQLDir          := DCIni.ReadString('General', 'SQLDir', '');
      lValue                    := DCIni.ReadString('General', 'SQLAutoComplete', 'Y');
      gSettings.SQLAutoComplete := lValue = 'Y';
      gSettings.CallDir         := DCIni.ReadString('General', 'CallDir', '');
      gSettings.PayrollId       := DCIni.ReadString('General', 'PayrollId', '');
   finally
      DCIni.Free;
   end;
end;

function OpenFile(var aNotChosen : Boolean; aCaption : String;
   aDefaultFolder : String; aOwner: TComponent) : String;
var
   OpenDialog: TFileOpenDialog;
   Dialog : TOpenDialog;
begin
   aNotChosen := True;
   if gWin7 then
      OpenDialog := TFileOpenDialog.Create(aOwner)
   else
      Dialog := TOpenDialog.Create(aOwner);
   try
      if gWin7 then
      begin
         with OpenDialog.FileTypes.Add do
         begin
            DisplayName := 'sql file';
            FileMask := '*.sql';
         end;
         OpenDialog.DefaultFolder := aDefaultFolder;
         aNotChosen := not OpenDialog.Execute;
         Result := OpenDialog.FileName;
      end
      else
      begin
         //Dialog.Filter :=
         Dialog.InitialDir := aDefaultFolder;
         aNotChosen := not Dialog.Execute;
         Result := Dialog.FileName;
      end;
   finally
      if gWin7 then
         OpenDialog.Free
      else
         Dialog.Free;
   end;

end;

function SaveFile(var aNotChosen : Boolean; aCaption : String;
   aDefaultFile, aDefaultFolder : String; aOwner: TComponent) : String;
var
   SaveDialog: TFileSaveDialog;
   Dialog : TSaveDialog;
begin
   aNotChosen := True;
   if gWin7 then
      SaveDialog := TFileSaveDialog.Create(aOwner)
   else
      Dialog := TSaveDialog.Create(aOwner);
   try
      if gWin7 then
      begin
         SaveDialog.DefaultExtension := 'sql';
         with SaveDialog.FileTypes.Add do
         begin
            DisplayName := 'sql file';
            FileMask := '*.sql';
         end;
         SaveDialog.FileName := aDefaultFile;
         SaveDialog.DefaultFolder := aDefaultFolder;
         aNotChosen := not SaveDialog.Execute;
         Result := SaveDialog.FileName;
      end
      else
      begin
         //Dialog.Filter :=
         //Dialog.InitialDir := aDefaultFile;
         aNotChosen := not Dialog.Execute;
         Result := Dialog.FileName;
      end;
   finally
      if gWin7 then
         SaveDialog.Free
      else
         Dialog.Free;
   end;

end;

function ChooseFolder(var aNotChosen : Boolean;
   aCaption : String; aDefaultFolder : String; aOwner: TComponent) : String;
var
  OpenDialog: TFileOpenDialog;
begin
   Result := '';
   aNotChosen := False;
   if gWin7 then
      OpenDialog := TFileOpenDialog.Create(aOwner);
   try
      if gWin7 then
      begin
         if DirectoryExists(aDefaultFolder) then
            OpenDialog.DefaultFolder := aDefaultFolder;

         OpenDialog.Options := OpenDialog.Options + [fdoPickFolders];

         if (not OpenDialog.Execute) then
            aNotChosen := True
         else
            Result := OpenDialog.FileName;
      end
      else
      begin
         aNotChosen := not SelectDirectory(aCaption, aDefaultFolder, Result, [sdNewFolder]);
      end;
   finally
      if gWin7 then
         OpenDialog.Free;
   end;
end;

procedure SetupRDConnection(var aDBEDatabase : TDBEDatabase);
var
   SMSDataEditorIni : TIniFile;
begin
   SMSDataEditorIni := TIniFile.Create(gAppPath + DC_INI);
   try
      aDBEDatabase.ServerName := SMSDataEditorIni.ReadString('RDHeadOffice', 'Server', '');
      aDBEDatabase.AliasName  := SMSDataEditorIni.ReadString('RDHeadOffice', 'AliasName', '');
      aDBEDatabase.UserName   := SMSDataEditorIni.ReadString('RDHeadOffice', 'Username', '');
      aDBEDatabase.Password   := SMSDataEditorIni.ReadString('RDHeadOffice', 'Password', '');
      //aDBEDatabase.Timeout    := 4;
   finally
      SMSDataEditorIni.Free;
   end;
end;

function GetBusinessObject(aTableName : String) : string;
var
   DCIni : TIniFile;
   I : Integer;
begin
   DCIni := TIniFile.Create(gAppPath + DC_INI);
   try
      Result  := DCIni.ReadString('BOList', aTableName, '');
   finally
      DCIni.Free;
   end;
end;

end.
