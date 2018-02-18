unit udSettings;
//DCL Oct 2016

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TdSettings = class(TForm)
    cbAutoComplete: TCheckBox;
    btnSchemaDir: TSpeedButton;
    lblSchemaDir: TLabel;
    lblSQLDir: TLabel;
    btnSQLDir: TSpeedButton;
    btnCallFolder: TSpeedButton;
    lblCallDir: TLabel;
    cboRemediUser: TComboBox;
    lblRemediUser: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure cbAutoCompleteClick(Sender: TObject);
    procedure btnSchemaDirClick(Sender: TObject);
    procedure btnSQLDirClick(Sender: TObject);
    procedure btnCallFolderClick(Sender: TObject);
    procedure cboRemediUserChange(Sender: TObject);
  private
    procedure FillDropdowns;

  public

  end;

implementation

uses uuGlobals, IniFiles, ufISQLQuery, ufDBEDatabase;

{$R *.dfm}

procedure TdSettings.FillDropdowns;
var
   lQuery : ISQLQuery;
   lDBEDatabase : TDBEDatabase;
begin
   cboRemediUser.Items.Clear;
   lDBEDatabase := TDBEDatabase.Create;
   try
      SetupRDConnection(lDBEDatabase);
      try
         lDBEDatabase.Connected := True;
      except
         on E : SysUtils.Exception do
         begin
            //Don't show a message, they may be offline
            //ShowMessage(E.Message);
            lDBEDatabase := nil;
            Exit;
         end;
      end;

      lQuery := lDBEDatabase.NewQuery;
      lQuery.SQL.Clear;
      lQuery.SQL.Add('select payroll_id from employee (nolock) where status_ind = ' + QuotedStr('Y') + ' order by payroll_id');
      try
         lQuery.Open;
         lQuery.First;
         while not lQuery.eof do
         begin
            cboRemediUser.Items.Add(lQuery.FieldByName('payroll_id').AsString);
            lQuery.Next;
         end;
      finally
         lQuery.Close;
      end;
   finally
      lQuery := nil;
      lDBEDatabase := nil;
   end;
end;

procedure TdSettings.btnSQLDirClick(Sender: TObject);
var
   lFolderNotChosen : Boolean;
   lFolderChosen : String;
   lRDDCIni : TIniFile;
begin
   lFolderChosen := ChooseFolder(lFolderNotChosen, 'Set SQL Directory',
      lblSQLDir.Caption, self);
   if not lFolderNotChosen then
   begin
      lblSQLDir.Caption  := lFolderChosen;
      gSettings.SQLDir   := lFolderChosen;
      //Write to ini
      lRDDCIni := TIniFile.Create(gAppPath + DC_INI);
      try
         lRDDCIni.WriteString('General', 'SQLDir', lFolderChosen);
      finally
         lRDDCIni.Free;
      end;
   end;
end;

procedure TdSettings.btnCallFolderClick(Sender: TObject);
var
   lFolderNotChosen : Boolean;
   lFolderChosen : String;
   lRDDCIni : TIniFile;
begin
   lFolderChosen := ChooseFolder(lFolderNotChosen, 'Set Call Directory',
      lblCallDir.Caption, self);
   if not lFolderNotChosen then
   begin
      lblCallDir.Caption := lFolderChosen;
      gSettings.CallDir  := lFolderChosen;
      //Write to ini
      lRDDCIni := TIniFile.Create(gAppPath + DC_INI);
      try
         lRDDCIni.WriteString('General', 'CallDir', lFolderChosen);
      finally
         lRDDCIni.Free;
      end;
   end;
end;

procedure TdSettings.btnSchemaDirClick(Sender: TObject);
var
   lFolderNotChosen : Boolean;
   lFolderChosen : String;
   lRDDCIni : TIniFile;
begin
   lFolderChosen := ChooseFolder(lFolderNotChosen, 'Set Schema Directory',
      lblSchemaDir.Caption, self);
   if not lFolderNotChosen then
   begin
      lblSchemaDir.Caption := lFolderChosen;
      gSettings.SchemaDir  := lFolderChosen;
      //Write to ini
      lRDDCIni := TIniFile.Create(gAppPath + DC_INI);
      try
         lRDDCIni.WriteString('General', 'SchemaDir', lFolderChosen);
      finally
         lRDDCIni.Free;
      end;
   end;
end;

procedure TdSettings.cbAutoCompleteClick(Sender: TObject);
var
   lRDDCIni : TIniFile;
   lValue : string;
begin
   gSettings.SQLAutoComplete := cbAutoComplete.Checked;
   if gSettings.SQLAutoComplete then
      lValue := 'Y'
   else
      lValue := 'N';
   //Write to ini
   lRDDCIni := TIniFile.Create(gAppPath + DC_INI);
   try
      lRDDCIni.WriteString('General', 'SQLAutoComplete', lValue);
   finally
      lRDDCIni.Free;
   end;
end;

procedure TdSettings.cboRemediUserChange(Sender: TObject);
var
   lRDDCIni : TIniFile;
   lValue : string;
begin
   gSettings.PayrollId := cboRemediUser.Text;
   //Write to ini
   lRDDCIni := TIniFile.Create(gAppPath + DC_INI);
   try
      lRDDCIni.WriteString('General', 'PayrollId', gSettings.PayrollId);
   finally
      lRDDCIni.Free;
   end;
end;

procedure TdSettings.FormCreate(Sender: TObject);
begin
   lblSchemaDir.Caption   := gSettings.SchemaDir;
   lblSQLDir.Caption      := gSettings.SQLDir;
   lblCallDir.Caption     := gSettings.CallDir;
   cbAutoComplete.Checked := gSettings.SQLAutoComplete;
   cboRemediUser.Text     := gSettings.PayrollId;
   FillDropdowns;
end;

end.
