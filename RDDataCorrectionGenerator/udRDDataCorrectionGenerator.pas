unit udRDDataCorrectionGenerator;
//DCL Oct 2016

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, SynEdit, SynMemo, SynCompletionProposal,
  SynEditHighlighter, SynHighlighterSQL, StdCtrls, ExtCtrls, Visio_TLB, Spin,
  Grids, DBGrids, SMDBGrid, DB, kbmMemTable, Buttons, ufDBEDatabase;

type
  TdRDDataCorrectionGenerator = class(TForm)
    pgcDC: TPageControl;
    tsCreate: TTabSheet;
    tsDataCorrections: TTabSheet;
    pgcSQL: TPageControl;
    tsSelectInto: TTabSheet;
    tsTransaction: TTabSheet;
    tsVerification: TTabSheet;
    tsResult: TTabSheet;
    sqlSelectInto: TSynMemo;
    hl1: TSynSQLSyn;
    scpSelectInto: TSynCompletionProposal;
    sqlTransaction: TSynMemo;
    sqlVerification: TSynMemo;
    sqlResult: TSynMemo;
    cboCallTask: TComboBox;
    lblCallTask: TLabel;
    edtControlTable: TLabeledEdit;
    edtControlBackupTable: TLabeledEdit;
    cboReplication: TComboBox;
    btnFlowchart: TButton;
    lblReplication: TLabel;
    btnSave: TButton;
    pnlAudit: TPanel;
    cboRemediUser: TComboBox;
    lblRemediUser: TLabel;
    edtScriptName: TLabeledEdit;
    edtScriptDesc: TLabeledEdit;
    edtRepLimit: TSpinEdit;
    lblRepLimit: TLabel;
    scpTransaction: TSynCompletionProposal;
    scpVerification: TSynCompletionProposal;
    dbgDCs: TSMDBGrid;
    dsDC: TDataSource;
    mtbDC: TkbmMemTable;
    sqlDC: TSynMemo;
    mtbDCname: TStringField;
    btnSettings: TSpeedButton;
    cbCommit: TCheckBox;
    cbDebug: TCheckBox;
    btnCallFolder: TSpeedButton;
    gbSExample: TGroupBox;
    cboSTables: TComboBox;
    cbReplicationOnly: TCheckBox;
    gbVExample: TGroupBox;
    cboVTables: TComboBox;
    btnClearT: TSpeedButton;
    btnClearS: TSpeedButton;
    btnClearV: TSpeedButton;
    btnVUpdate: TSpeedButton;
    btnTExample: TSpeedButton;
    btnSUpdate: TSpeedButton;
    btnSInsert: TSpeedButton;
    btnSDelete: TSpeedButton;
    btnLoad: TSpeedButton;
    btnHelp: TSpeedButton;
    procedure btnFlowchartClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edtScriptNameChange(Sender: TObject);
    procedure edtScriptDescChange(Sender: TObject);
    procedure cboRemediUserChange(Sender: TObject);
    procedure edtControlTableChange(Sender: TObject);
    procedure edtControlBackupTableChange(Sender: TObject);
    procedure cboCommitChange(Sender: TObject);
    procedure cboReplicationChange(Sender: TObject);
    procedure cboDebugChange(Sender: TObject);
    procedure cboCallTaskChange(Sender: TObject);
    procedure sqlSelectIntoChange(Sender: TObject);
    procedure sqlTransactionChange(Sender: TObject);
    procedure sqlVerificationChange(Sender: TObject);
    procedure edtRepLimitChange(Sender: TObject);
    procedure mmoSQLChange(Sender: TObject; scp : TSynCompletionProposal);
    procedure scpSelectIntoAfterCodeCompletion(Sender: TObject; const Value: WideString;
      Shift: TShiftState; Index: Integer; EndToken: WideChar);
    procedure btnClearSClick(Sender: TObject);
    procedure btnClearTClick(Sender: TObject);
    procedure btnClearVClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mtbDCAfterScroll(DataSet: TDataSet);
    procedure btnSettingsClick(Sender: TObject);
    procedure cboCallTaskExit(Sender: TObject);
    procedure btnCallFolderClick(Sender: TObject);
    procedure scpSelectIntoCodeCompletion(Sender: TObject;
      var Value: WideString; Shift: TShiftState; Index: Integer;
      EndToken: WideChar);
    procedure scpTransactionCodeCompletion(Sender: TObject;
      var Value: WideString; Shift: TShiftState; Index: Integer;
      EndToken: WideChar);
    procedure scpVerificationCodeCompletion(Sender: TObject;
      var Value: WideString; Shift: TShiftState; Index: Integer;
      EndToken: WideChar);
    procedure btnSUpdateClick(Sender: TObject);
    procedure btnSInsertClick(Sender: TObject);
    procedure btnSDeleteClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure cboCallTaskKeyPress(Sender: TObject; var Key: Char);
    procedure cbCommitClick(Sender: TObject);
    procedure cbDebugClick(Sender: TObject);
    procedure btnVUpdateClick(Sender: TObject);
    procedure btnTExampleClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
  private
    fTypedSQLChange, fJustSQLCompleted, fLoading : Boolean;
    procedure GenerateResult;
    function  DynamicToNormal(aSQL : String): string;
    function  NormalToDynamic(aSQL: String): string;
    function  ValidateInput : Boolean;
    function  GetCallStoredProc: TStringList;
    function  GetDeclarations: TStringList;
    function  GetSetVariables: TStringList;
    function  RepInBatches: Boolean;
    procedure LoadDCs;
    function  GetNotes: TStringList;
    procedure FillDropdowns;
    procedure PopulateCall;
    function  FindCallFolder(aCall : String): string;
    procedure ShowCallFolder(aCall : String);
    procedure Example(aActionType: String); 
  public

  end;

var
  dRDDataCorrectionGenerator: TdRDDataCorrectionGenerator;


implementation

uses
   uuGlobals, ShellAPI, uuSQLEditor, udSettings, ufISQLQuery, StrUtils, SynUnicode,
  udHelp;

{$R *.dfm}

procedure TdRDDataCorrectionGenerator.FormCreate(Sender: TObject);
begin
   gWin7 := CheckWin32Version(6,1); //Windows 7 or higher
   gAppPath := ExtractFilePath(ParamStr(0));
   ReadIni;

   fTypedSQLChange := True;
   fJustSQLCompleted := False;

//   cboCallTask.Text := 'xxxxxx';
//   //cboRemediUser.Text := 'DCL';
//   edtScriptName.Text := 'name';
//   edtScriptDesc.Text := 'desc';
//   edtControlTable.Text := 'control';
//   edtControlBackupTable.Text := 'controlbackup';
//   sqlSelectInto.Text := 'selectInto';
//   sqlTransaction.Text := 'transaction';
//   sqlVerification.Text := 'verify';
   GenerateResult;
   LoadDCs;
   FillDropdowns;
   cboRemediUser.Text := gSettings.PayrollId;
   pgcSQL.ActivePageIndex := 0;
end;

procedure TdRDDataCorrectionGenerator.FillDropdowns;
var
   lQuery : ISQLQuery;
   lDBEDatabase : TDBEDatabase;
   lTableNames : TStringList;
   I : Integer;
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

      lQuery.SQL.Clear;
      lQuery.SQL.Add('select c.call_code from call c (nolock)');
      lQuery.SQL.Add(' join employee e (nolock) on (e.employee_id = c.assigned_to_emp_id)');
      lQuery.SQL.Add(' where e.payroll_id = ' + QuotedStr(gSettings.PayrollId));
      lQuery.SQL.Add(' and c.last_callactiontype_code <> ''CLOSED''');
      lQuery.SQL.Add(' order by call_code');
      try
         lQuery.Open;
         lQuery.First;
         while not lQuery.eof do
         begin
            cboCallTask.Items.Add(lQuery.FieldByName('call_code').AsString);
            lQuery.Next;
         end;
      finally
         lQuery.Close;
      end;

   finally
      lQuery := nil;
      lDBEDatabase := nil;
   end;

   lTableNames := GetTableNamesFromSchema;
   try
      for I := 0 to lTableNames.Count - 1 do
      begin
         cboSTables.Items.Add(lTableNames[I]);
         cboVTables.Items.Add(lTableNames[I]);
      end;
   finally
      FreeAndNil(lTableNames);
   end;
end;

procedure TdRDDataCorrectionGenerator.PopulateCall;
var
   lQuery : ISQLQuery;
   lDBEDatabase : TDBEDatabase;
   lCall : string;
begin
   lCall := Trim(cboCallTask.Text);
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
      try
         lQuery.SQL.Clear;
         lQuery.SQL.Add('select e.payroll_id, c.customer_code, c.description');
         lQuery.SQL.Add(' from call c (nolock)');
         lQuery.SQL.Add(' left join employee e (nolock) on (e.employee_id = c.assigned_to_emp_id)');
         lQuery.SQL.Add(' where (c.call_code = ' + QuotedStr(lCall) + ')');
         lQuery.Open;

         if Trim(cboRemediUser.Text) = '' then
            cboRemediUser.Text := lQuery.FieldByName('payroll_id').AsString;
         if Trim(edtScriptName.Text) = '' then
            edtScriptName.Text := lQuery.FieldByName('description').AsString;
         if Trim(edtScriptDesc.Text) = '' then
            edtScriptDesc.Text := lQuery.FieldByName('customer_code').AsString + ' ' + lQuery.FieldByName('description').AsString;

         if Trim(edtControlTable.Text) = '' then
            edtControlTable.Text := '##rd_' + lCall;
         if Trim(edtControlBackupTable.Text) = '' then
            edtControlBackupTable.Text := 'rd_' + lCall + '_backup';
      finally
         lQuery.Close;
      end;
   finally
      lQuery := nil;
      lDBEDatabase := nil;
   end;
end;

procedure TdRDDataCorrectionGenerator.FormDestroy(Sender: TObject);
begin
   mtbDC.Close;
end;

procedure TdRDDataCorrectionGenerator.LoadDCs;
var
   searchResult : TSearchRec;
   tblStr : string;
begin
   fLoading := True;

   mtbDC.Close;
   mtbDC.Open;

   if FindFirst(gSettings.SQLDir + '\*.sql', faAnyFile, searchResult) = 0 then
   begin
      repeat
         tblStr := searchResult.Name;
         Delete(tblStr, Length(tblStr) - 3, 4);
         mtbDC.Append;
         mtbDCname.AsString := tblStr;
         mtbDC.Post;
      until FindNext(searchResult) <> 0;
      FindClose(searchResult);
      mtbDC.First;
      mtbDCAfterScroll(mtbDC);
   end;
   fLoading := False;
end;

procedure TdRDDataCorrectionGenerator.mtbDCAfterScroll(DataSet: TDataSet);
var
   lDDLFile : TextFile;
   lLine : string;
   lFileName : string;
begin
   if fLoading then Exit;
   lFileName := gSettings.SQLDir + '\' + mtbDCname.AsString + '.sql';
   if not FileExists(lFileName) then
      Exit;
   AssignFile(lDDLFile, lFileName);
   Reset(lDDLFile);
   sqlDC.Lines.Clear;
   while not EOF(lDDLFile) do
   begin
      ReadLn(lDDLFile, lLine);
      sqlDC.Lines.Add(lLine);
   end;
   CloseFile(lDDLFile);
end;

procedure TdRDDataCorrectionGenerator.cbCommitClick(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.cbDebugClick(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.cboCallTaskChange(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.cboCallTaskExit(Sender: TObject);
begin
   if Trim(cboCallTask.Text) <> '' then
      PopulateCall;
end;

procedure TdRDDataCorrectionGenerator.cboCallTaskKeyPress(Sender: TObject;
  var Key: Char);
begin
   if (Key = #13) and (Trim(cboCallTask.Text) <> '') then
   begin
      PopulateCall;
   end;
end;

procedure TdRDDataCorrectionGenerator.cboCommitChange(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.cboDebugChange(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.cboRemediUserChange(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.cboReplicationChange(Sender: TObject);
begin
   GenerateResult;
   cbReplicationOnly.Visible := cboReplication.Text = 'Y';
   if cboReplication.Text = 'P' then
   begin
      ShowMessage('Reminder: In this mode you are replicating from an existing persistent control table.' + #13#10 + 'So there is no need for any select/transaction/verification statement or control backup table.');
   end;
end;

function TdRDDataCorrectionGenerator.DynamicToNormal(aSQL : String) : string;
begin
   Result := StringReplace(aSQL, '''''', '''', [rfReplaceAll]); //Replace '' with '
   //Get rid of ' at start and end
   Delete(Result, 1, 1);
   Delete(Result, Length(Result), 1);
end;

procedure TdRDDataCorrectionGenerator.edtControlBackupTableChange(
  Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.edtControlTableChange(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.edtRepLimitChange(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.edtScriptDescChange(Sender: TObject);
begin
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.edtScriptNameChange(Sender: TObject);
begin
   GenerateResult;
end;

function TdRDDataCorrectionGenerator.NormalToDynamic(aSQL : String) : string;
begin
   Result := StringReplace(aSQL, '''', '''''', [rfReplaceAll]); //Replace ' with ''
   Result := '''' + Result + '''';
end;

procedure TdRDDataCorrectionGenerator.scpSelectIntoAfterCodeCompletion(Sender: TObject;
  const Value: WideString; Shift: TShiftState; Index: Integer;
  EndToken: WideChar);
begin
   fJustSQLCompleted := True;
end;

procedure TdRDDataCorrectionGenerator.scpSelectIntoCodeCompletion(
  Sender: TObject; var Value: WideString; Shift: TShiftState; Index: Integer;
  EndToken: WideChar);
var
   lCurrentSelText: UnicodeString;
begin
   lCurrentSelText := (Sender as TSynCompletionProposal).Editor.SelText;
   if UnicodeString('.') =
      Copy(lCurrentSelText, Length(lCurrentSelText), Length(lCurrentSelText)) then
   begin
      Value := lCurrentSelText + Value;
   end;
end;

procedure TdRDDataCorrectionGenerator.scpTransactionCodeCompletion(
  Sender: TObject; var Value: WideString; Shift: TShiftState; Index: Integer;
  EndToken: WideChar);
var
   lCurrentSelText: UnicodeString;
begin
   lCurrentSelText := (Sender as TSynCompletionProposal).Editor.SelText;
   if UnicodeString('.') =
      Copy(lCurrentSelText, Length(lCurrentSelText), Length(lCurrentSelText)) then
   begin
      Value := lCurrentSelText + Value;
   end;
end;

procedure TdRDDataCorrectionGenerator.scpVerificationCodeCompletion(
  Sender: TObject; var Value: WideString; Shift: TShiftState; Index: Integer;
  EndToken: WideChar);
var
   lCurrentSelText: UnicodeString;
begin
   lCurrentSelText := (Sender as TSynCompletionProposal).Editor.SelText;
   if UnicodeString('.') =
      Copy(lCurrentSelText, Length(lCurrentSelText), Length(lCurrentSelText)) then
   begin
      Value := lCurrentSelText + Value;
   end;
end;

procedure TdRDDataCorrectionGenerator.sqlSelectIntoChange(Sender: TObject);
begin
   GenerateResult;
   mmoSQLChange(Sender, scpSelectInto);
end;

procedure TdRDDataCorrectionGenerator.sqlTransactionChange(Sender: TObject);
begin
   GenerateResult;
   mmoSQLChange(Sender, scpTransaction);
end;

procedure TdRDDataCorrectionGenerator.sqlVerificationChange(Sender: TObject);
begin
   GenerateResult;
   mmoSQLChange(Sender, scpVerification);
end;

function TdRDDataCorrectionGenerator.ValidateInput : Boolean;
var
   lControlTable, lControlBackupTable, lCallNum, lRemediUserCode,
   lScriptName, lScriptDesc : string;
   lReplication : String;
   lSelectInto, lTransaction, lVerification : string;
begin
   Result := True;

   lControlTable       := Trim(edtControlTable.Text);
   lControlBackupTable := Trim(edtControlBackupTable.Text);
   lCallNum            := Trim(cboCallTask.Text);
   lRemediUserCode     := Trim(cboRemediUser.Text);
   lScriptName         := Trim(edtScriptName.Text);
   lScriptDesc         := Trim(edtScriptDesc.Text);
   lReplication        := Trim(cboReplication.Text);
   lSelectInto         := Trim(sqlSelectInto.Text);
   lTransaction        := Trim(sqlTransaction.Text);
   lVerification       := Trim(sqlVerification.Text);

   //Validation
   if lControlTable = '' then
   begin
      ShowMessage('The control table cannot be blank');
      edtControlTable.SetFocus;
      Result := False;
   end
   else if lControlBackupTable = '' then
   begin
      ShowMessage('The control backup table cannot be blank');
      edtControlBackupTable.SetFocus;
      Result := False;
   end
   else if lCallNum = '' then
   begin
      ShowMessage('The task/call number cannot be blank');
      cboCallTask.SetFocus;
      Result := False;
   end
   else if lRemediUserCode = '' then
   begin
      ShowMessage('The remedi user cannot be blank');
      cboRemediUser.SetFocus;
      Result := False;
   end
   else if lScriptName = '' then
   begin
      ShowMessage('The script name cannot be blank');
      edtScriptName.SetFocus;
      Result := False;
   end
   else if lScriptDesc = '' then
   begin
      ShowMessage('The script desc cannot be blank');
      edtScriptDesc.SetFocus;
      Result := False;
   end
   else if (lReplication <> 'Y') and (lReplication <> 'N') and (lReplication <> 'P') then
   begin
      ShowMessage('Replication must Y, N or P');
      cboReplication.SetFocus;
      Result := False;
   end
   else if (Pos('#', lControlTable) > 0) and (not (Pos('##', lControlTable) > 0)) then
   begin
      ShowMessage('The control table cannot be a temporary table');
      edtControlTable.SetFocus;
      Result := False;
   end
   else if (lReplication = 'P') and (Pos('##', lControlTable) > 0) then
   begin
      ShowMessage('In order to replicate in batches you must use a persistent table');
      edtControlTable.SetFocus;
      Result := False;
   end
   else if (Pos('##', lControlTable) > 0) and (edtRepLimit.Value > 0) then
   begin
      ShowMessage('In order to replicate in batches you must use a persistent table');
      edtControlTable.SetFocus;
      Result := False;
   end
   else if (lReplication = 'P') and (lControlBackupTable <> '') then
   begin
      ShowMessage('You don''t need a control backup table to replicate from a persistent table');
      edtControlBackupTable.SetFocus;
      Result := False;
   end
   else if (lReplication = 'P') and ((lSelectInto <> '') or (lTransaction <> '') or (lVerification <> '')) then
   begin
      ShowMessage('To replicate from an existing persistent table, you don''t need any SQL statements');
      Result := False;
   end;
end;

function TdRDDataCorrectionGenerator.GetDeclarations : TStringList;
var
   lStr, lEnd : string;
begin
   Result := TStringList.Create;
   with Result do
   begin
      Add('DECLARE');
      Add('  @control_table               NVARCHAR(64),    -- This can either be the name of a global temp table or a persistent table.');
      Add('  @transaction_sql             NVARCHAR(MAX),   -- Executed inside the transaction.');
      Add('  @verification_condition_sql  NVARCHAR(MAX),   -- Inside IF condition before transaction is committed.');
      Add('  @commit_tran                 CHAR(1),         -- ''Y''(Yes), ''N''(No). If ''N'', then you have the opportunity to spot check before committing.');
      Add('  @debug_ind                   CHAR(1),         -- This will select some intermediate tables used in the calculation. It doesn''t stop the transaction.');
      Add('  --Backup');
      Add('  @control_backup_table        NVARCHAR(64),    -- i.e.''rd_063567''');
      Add('  @now                         DATETIME,        -- i.e. GetDate()');
      Add('  --Audit Trail');
      Add('  @calltasknum                 VARCHAR(12),     -- This is your Call Number or Task Number.');
      Add('  @remediuser_code             VARCHAR(12),     -- This will be your ErrorEvent ID (auto-generated).');
      Add('  @script_name                 VARCHAR(50),     -- This is the short description of your script.');
      Add('  @script_desc                 VARCHAR(120),    -- This is the description of your script from SQL Checklist.');
      Add('  --Replication');
      lStr := '  @replication_ind             CHAR(1)';
      lEnd := '         -- ''Y''(Yes), ''N''(No). If ''N'', then the following parameters are ignored.';
      if RepInBatches then
         Add(lStr + ',' + lEnd)
      else
         Add(lStr + ' ' + lEnd);
      if RepInBatches then
         Add('  @rep_batch_limit             INTEGER          -- This is the number of records to replicate, for all tables being replicated. NULL means no limit.');
   end;
end;

function TdRDDataCorrectionGenerator.RepInBatches : Boolean;
begin
   Result := (Trim(cboReplication.Text) = 'P') and (edtRepLimit.Value > -1);
end;

function TdRDDataCorrectionGenerator.GetSetVariables : TStringList;
var
   lControlTable, lControlBackupTable, lCallNum, lRemediUserCode,
   lScriptName, lScriptDesc : string;
   lCommit, lDebug, lReplication, lRepLimit : String;
begin
   lControlTable       := Trim(edtControlTable.Text);
   lControlBackupTable := Trim(edtControlBackupTable.Text);
   lCallNum            := Trim(cboCallTask.Text);
   lRemediUserCode     := Trim(cboRemediUser.Text);
   lScriptName         := Trim(edtScriptName.Text);
   lScriptDesc         := Trim(edtScriptDesc.Text);
   lCommit             := IfThen(cbCommit.Checked, 'Y', 'N');
   lDebug              := IfThen(cbDebug.Checked, 'Y', 'N');
   lReplication        := Trim(cboReplication.Text);
   lRepLimit           := Trim(edtRepLimit.Text);

   Result := TStringList.Create;
   with Result do
   begin
      Add('SET @control_table            = ' + QuotedStr(lControlTable));
      Add('SET @commit_tran              = ' + QuotedStr(lCommit));
      Add('SET @debug_ind                = ' + QuotedStr(lDebug));
      Add('  --Backup');
      Add('SET @control_backup_table     = ' + QuotedStr(lControlBackupTable));
      Add('SET @now                      = GetDate()');
      Add('  --Audit Trail');
      Add('SET @calltasknum              = ' + QuotedStr(lCallNum));
      Add('SET @remediuser_code          = ' + QuotedStr(lRemediUserCode));
      Add('SET @script_name              = ' + QuotedStr(lScriptName));
      Add('SET @script_desc              = ' + QuotedStr(lScriptDesc));
      Add('  --Replication');
      Add('SET @replication_ind          = ' + QuotedStr(lReplication));
      if RepInBatches then
         Add('SET @rep_batch_limit          = ' + lRepLimit);
   end;
end;

function TdRDDataCorrectionGenerator.GetCallStoredProc : TStringList;
begin
   Result := TStringList.Create;
   with Result do
   begin
      Add('EXEC dbo.usp_data_correction');
      Add('    @control_table               -- This can either be the name of a global temp table or a persistent table.');
      Add('  , @transaction_sql             -- NVARCHAR(MAX)   Executed inside the transaction.');
      Add('  , @verification_condition_sql  -- NVARCHAR(MAX)   Inside IF condition before transaction is committed.');
      Add('  , @commit_tran                 -- CHAR(1)        ''Y''(Yes), ''N''(No). If ''N'', then you have the opportunity to spot check before committing.');
      Add('  , @debug_ind                   -- CHAR(1),        This will select some intermediate tables used in the calculation. It doesn''t stop the transaction.');
      Add('  --Backup');
      Add('  , @control_backup_table        -- NVARCHAR(64)    i.e.''rd_063567''');
      Add('  , @now                         -- DATETIME        When the control table already exists, the transaction and backup will only effect this time');
      Add('  --Audit Trail');
      Add('  , @calltasknum                 -- VARCHAR(12)     This is your Call Number or Task Number.');
      Add('  , @script_name                 -- VARCHAR(50)     This is the short description of your script.');
      Add('  , @script_desc                 -- VARCHAR(120)    This is the description of your script from SQL Checklist.');
      Add('  , @remediuser_code             -- VARCHAR(12)     This will be your ErrorEvent ID (auto-generated).');
      Add('  --Replication');
      Add('  , @replication_ind             -- CHAR(1)         ''Y''(Yes), ''N''(No). If ''N'', then the following parameters are ignored.');
      if RepInBatches then
         Add('  , @rep_batch_limit             -- INTEGER         This is the number of records to replicate, for all tables being replicated. NULL means no limit.')
   end;
end;

function TdRDDataCorrectionGenerator.GetNotes : TStringList;
var
   lCallNum, lUserCode, lCallDesc : String;
   lDay, lMonth, lYear : Word;
begin
   lCallNum  := Trim(cboCallTask.Text);
   lUserCode := Trim(cboRemediUser.Text);
   lCallDesc := Trim(edtScriptDesc.Text);
   DecodeDate(Now, lYear, lMonth, lDay);

   Result := TStringList.Create;
   with Result do
   begin
      Add('  ' + lCallNum + ' ' + lUserCode + ' ' + IntToStr(lDay) + '-' + IntToStr(lMonth) + '-' + IntToStr(lYear) + ' ' + lCallDesc);
   end;
end;

procedure TdRDDataCorrectionGenerator.GenerateResult;
var
   lTransaction, lVerification : string;
   lNotes, lDeclarations, lSetVariables, lCallStoredProc : TStringList;
   I : Integer;
   lControlTable : string;
begin
   if fLoading then Exit;

   //Construct SQL
   with sqlResult.Lines do
   begin
      Clear;
      Add('/*');
      lNotes := GetNotes;
      try
         for I := 0 to lNotes.Count - 1 do
         begin
            Add(lNotes[I]);
         end;
      finally
         FreeAndNil(lNotes);
      end;
      Add('*/');

      lDeclarations := GetDeclarations;
      try
         for I := 0 to lDeclarations.Count - 1 do
         begin
            Add(lDeclarations[I]);
         end;
      finally
         FreeAndNil(lDeclarations);
      end;
      Add('');

      lSetVariables := GetSetVariables;
      try
         for I := 0 to lSetVariables.Count - 1 do
         begin
            Add(lSetVariables[I]);
         end;
      finally
         FreeAndNil(lSetVariables);
      end;
      Add('');

      if Trim(cboReplication.Text) <> 'P' then
      begin
         lControlTable := Trim(edtControlTable.Text);
         if AnsiContainsStr(lControlTable, '##') then
         begin
            Add('IF OBJECT_ID(''tempdb..' + lControlTable + ''') IS NOT NULL');
            Add('BEGIN');
            Add('   DROP TABLE ' + lControlTable);
            Add('END');
         end
         else
         begin
            Add('IF OBJECT_ID(''' + lControlTable + ''') IS NOT NULL');
            Add('BEGIN');
            Add('   DROP TABLE ' + lControlTable);
            Add('END');
         end;
         Add('CREATE TABLE ' + lControlTable + ' (');
         Add('  execution_date_time DATETIME not null,');
         Add('  table_name          VARCHAR(32) not null,');
         Add('  backup_table        VARCHAR(32) not null,');
         Add('  pkey                VARCHAR(32) not null,');
         Add('  pkey_value          VARCHAR(24) not null,');
         Add('  insert_set_sql      NVARCHAR(1000) not null,');
         if Trim(cboReplication.Text) = 'Y' then
         begin
            Add('  action_type         CHAR(1) not null,');
            Add('  replicate_rec_ind   CHAR(1) not null,');
            Add('  replicated_ind      CHAR(1) not null,');
            Add('  rep_target          VARCHAR(13),');
            Add('  businessobject_name VARCHAR(34) not null,');
            Add('  transmit_full_ind   CHAR(1) null');
         end
         else
            Add('  action_type         CHAR(1) not null');
         Add(')');
         Add('');

      end;

      for I := 0 to sqlSelectInto.Lines.Count - 1 do
      begin
         if Trim(sqlSelectInto.Lines[I]) <> '' then
            Add(Trim(sqlSelectInto.Lines[I]));
      end;

      //TODO: These lines aren't split up
      lTransaction        := NormalToDynamic(Trim(sqlTransaction.Text));
      lVerification       := NormalToDynamic(Trim(sqlVerification.Text));

      Add('');
      Add('SET @transaction_sql = N' + lTransaction);
      Add('');
      Add('SET @verification_condition_sql = N' + lVerification);
      Add('');

      lCallStoredProc := GetCallStoredProc;
      try
         for I := 0 to lCallStoredProc.Count - 1 do
         begin
            Add(lCallStoredProc[I]);
         end;
      finally
         FreeAndNil(lCallStoredProc);
      end;
      Add('');

      if not cbCommit.Checked then
      begin
         Add('--COMMIT TRAN');
         Add('--ROLLBACK TRAN');
      end;
   end;
end;

procedure TdRDDataCorrectionGenerator.btnSaveClick(Sender: TObject);
var
   lNotChosen : Boolean;
   lFileName : string;
   lDefaultFile, lDefaultFolder : string;
begin
   if not ValidateInput then
      Exit;
   lDefaultFile := Trim(cboCallTask.Text) + '-' + Trim(edtScriptName.Text);
   lDefaultFolder := FindCallFolder(Trim(cboCallTask.Text));
   lFileName := SaveFile(lNotChosen, 'Save Data Correction SQL', lDefaultFile, lDefaultFolder, Self);
   if not lNotChosen then
   begin
      sqlResult.Lines.SaveToFile(lFileName);
      //Open it in Excel. It will depend on the file types default program
      ShellExecute(Handle, 'open', PChar(lFileName), nil, nil, SW_SHOWNORMAL);
   end;
end;

procedure TdRDDataCorrectionGenerator.btnSettingsClick(Sender: TObject);
var
   lSettings : TdSettings;
begin
   lSettings := TdSettings.Create(nil);
   try
      lSettings.ShowModal;
   finally
      FreeAndNil(lSettings);
   end;
end;

procedure TdRDDataCorrectionGenerator.btnCallFolderClick(Sender: TObject);
begin
   if Trim(cboCallTask.Text) <> '' then
      ShowCallFolder(Trim(cboCallTask.Text));
end;

procedure TdRDDataCorrectionGenerator.ShowCallFolder(aCall: string);
var
   lFolder : string;
begin
   lFolder := FindCallFolder(aCall);
   if lFolder <> '' then
      ShellExecute(Application.Handle,PChar('explore'),PChar(lFolder),nil,nil,SW_SHOWNORMAL)
end;

function TdRDDataCorrectionGenerator.FindCallFolder(aCall : String) : string;
var
  sr: TSearchRec;
  lCall : string;
begin
   Result := '';
   lCall := Trim(cboCallTask.Text);
   if not DirectoryExists(gSettings.CallDir) then
   begin
      ShowMessage('Could not find ' + gSettings.CallDir);
      Exit;
   end;

   if lCall <> '' then
   begin
      //First check for call folder without a description
      Result := gSettings.CallDir + aCall;
      if not DirectoryExists(Result) then //will need to find it with a description
      begin
         Result := '';
         try
            if FindFirst(IncludeTrailingPathDelimiter(gSettings.CallDir) + '*.*', faDirectory, sr) < 0 then
               Exit
            else
            repeat
               if ((sr.Attr and faDirectory <> 0) AND (sr.Name <> '.') AND (sr.Name <> '..')) then
               begin
                  if AnsiStartsStr(aCall, sr.Name) then
                  begin
                     Result := gSettings.CallDir + sr.Name;
                     Break;
                  end;
               end;
            until FindNext(sr) <> 0;
         finally
           SysUtils.FindClose(sr);
         end;

         if Result = '' then
            Result := gSettings.CallDir;
      end
      else
         Result := gSettings.CallDir + aCall;
   end
   else
      Result := gSettings.CallDir;
end;

procedure TdRDDataCorrectionGenerator.btnClearSClick(Sender: TObject);
begin
   sqlSelectInto.Text := '';
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.btnClearTClick(Sender: TObject);
begin
   sqlTransaction.Text := '';
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.btnClearVClick(Sender: TObject);
begin
   sqlVerification.Text := '';
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.btnFlowchartClick(Sender: TObject);
var
   AppVisio : TVisioApplication;
   docsObj, stnObjs : IVDocuments;
   DocObj, stnObj : IVDocument;
   pagsObj : IVPages;
   pagObj : IVPage;
   mastObjs : IVMasters;
   mastObj : IVMaster;
   sNotes, sDeclarations, sSetVariables, sSelectInto, sTransaction,
      sVerification, sCallStoredProc : IVShape;
   lLine : IVShape;
   lWindow : IVWindow;
   lSelectInto, lTransaction, lVerification : string;
   lNotes, lDeclarations, lSetVariables, lCallStoredProc : TStringList;
   lControlTable : string;
begin
   if not ValidateInput then
      Exit;

   if Trim(cboReplication.Text) <> 'P' then
   begin
      lControlTable := Trim(edtControlTable.Text);
      if AnsiContainsStr(lControlTable, '##') then
         lSelectInto :=
         'IF OBJECT_ID(''tempdb..' + lControlTable + ''') IS NOT NULL' + #13#10 +
         'BEGIN' + #13#10 +
         '   DROP TABLE ' + lControlTable + #13#10 +
         'END' + #13#10 + #13#10
      else
         lSelectInto :=
         'IF OBJECT_ID(''' + lControlTable + ''') IS NOT NULL' + #13#10 +
         'BEGIN' + #13#10 +
         '   DROP TABLE ' + lControlTable + #13#10 +
         'END' + #13#10 + #13#10;

      lSelectInto := lSelectInto +
         'CREATE TABLE	' + lControlTable + ' (' + #13#10 +
         '  execution_date_time DATETIME not null,' + #13#10 +
         '  table_name 		  VARCHAR(32) not null,' + #13#10 +
         '  backup_table        VARCHAR(32) not null,' + #13#10 +
         '  pkey                VARCHAR(32) not null,' + #13#10 +
         '  pkey_value	      VARCHAR(24) not null,' + #13#10 +
         '  insert_set_sql      NVARCHAR(1000) not null,' + #13#10 +
         '  action_type 		  CHAR(1) not null' + #13#10;

      if Trim(cboReplication.Text) = 'Y' then
      begin
         lSelectInto := lSelectInto +
         '  replicate_rec_ind   CHAR(1) not null,' + #13#10 +
         '  replicated_ind      CHAR(1) not null,' + #13#10 +
         '  rep_target          VARCHAR(13),' + #13#10 +
         '  businessobject_name VARCHAR(34) not null,' + #13#10 +
         '  transmit_full_ind	  CHAR(1) null' + #13#10;
      end;
      lSelectInto := lSelectInto + ')' + #13#10 + #13#10;
   end;

   lSelectInto         := lSelectInto + Trim(sqlSelectInto.Text);
   lTransaction        := NormalToDynamic(Trim(sqlTransaction.Text));
   lVerification       := NormalToDynamic(Trim(sqlVerification.Text));

   AppVisio := TVisioApplication.Create(nil);
   try
      docsObj  := AppVisio.Documents;
      DocObj   := docsObj.Add('Basic Diagram.vst');

      pagsObj  := AppVisio.ActiveDocument.Pages;
      pagObj   := pagsObj.Item[1];

      stnObjs  := AppVisio.Documents;
      stnObj   := stnObjs.Item['Basic Shapes.vss'];
      mastObjs := stnObj.Masters;

      lNotes := GetNotes;
      try
         if Trim(lNotes.Text) <> '' then
         begin
            //mastObj := stnObj.Masters['Text'];
            sNotes := pagObj.DrawRectangle(0.7, 10.7, 7.3, 11.2);
            sNotes.Text := lNotes.Text;
         end;
      finally
         FreeAndNil(lNotes);
      end;

      mastObj := stnObj.Masters['Rectangle'];

      lDeclarations := GetDeclarations;
      try
         if Trim(lDeclarations.Text) <> '' then
         begin
            sDeclarations := pagObj.DrawRectangle(0.7, 8.3, 7.3, 10.6);
            sDeclarations.Text := lDeclarations.Text;
         end;
      finally
         FreeAndNil(lDeclarations);
      end;

      lSetVariables := GetSetVariables;
      try
         if Trim(lSetVariables.Text) <> '' then
         begin
            sSetVariables := pagObj.DrawRectangle(2.6, 6, 5.4, 8);
            sSetVariables.Text := lSetVariables.Text;
         end;
      finally
         FreeAndNil(lSetVariables);
      end;

      sDeclarations.AutoConnect(sSetVariables, visAutoConnectDirDown, lLine);

      if lSelectInto <> '' then
      begin
         sSelectInto := pagObj.DrawRectangle(1, 3.5, 7, 5.5);
         sSelectInto.Text := lSelectInto;
      end;

      sSetVariables.AutoConnect(sSelectInto, visAutoConnectDirDown, lLine);

      sTransaction := pagObj.DrawRectangle(2.5, 2, 5.5, 3);
      sTransaction.Text := 'SET @transaction_sql = N' + lTransaction;

      sSelectInto.AutoConnect(sTransaction, visAutoConnectDirDown, lLine);

      sVerification := pagObj.DrawRectangle(2.5, 0, 5.5, 1.5);
      sVerification.Text := 'SET @verification_condition_sql = N' + lVerification;

      sTransaction.AutoConnect(sVerification, visAutoConnectDirDown, lLine);

      lCallStoredProc := GetCallStoredProc;
      try
         sCallStoredProc := pagObj.DrawRectangle(1, -3, 7, -0.5);
         sCallStoredProc.Text := lCallStoredProc.Text;
      finally
         FreeAndNil(lCallStoredProc);
      end;

      sVerification.AutoConnect(sCallStoredProc, visAutoConnectDirDown, lLine);

      lWindow := AppVisio.ActiveWindow;
      lWindow.SelectAll;
      AppVisio.DoCmd(visCmdTextHAlignLeft);
      lWindow.DeselectAll;
      lWindow.Zoom := 1;
      DocObj.SaveAs(Trim(cboCallTask.Text) + '-' + Trim(edtScriptName.Text) + '.vsd');



      //AppVisio.Quit;
   finally
      FreeAndNil(AppVisio);
   end;
end;

procedure TdRDDataCorrectionGenerator.btnHelpClick(Sender: TObject);
var
   ldHelp : TdHelp;
begin
   ldHelp := TdHelp.Create(nil);
   try
      ldHelp.ShowModal;
   finally
      FreeAndNil(ldHelp);
   end;
end;

procedure TdRDDataCorrectionGenerator.Example(aActionType: String);
var
   lTable, lPrimaryKey, lControl, lBusinessObject : String;
   lSelectStr : string;
begin
   lTable := Trim(cboSTables.Text);
   lPrimaryKey := GetPrimaryKey(lTable);
   lControl := Trim(edtControlTable.Text);
   lBusinessObject := GetBusinessObject(lTable);
   with sqlSelectInto.Lines do
   begin
      Add('insert into ' + lControl);
      lSelectStr := 'select';
      if aActionType = 'I' then
         lSelectStr := lSelectStr + ' top 1';
      Add(lSelectStr);
      Add('   @now                          as execution_date_time');
      if aActionType = 'U' then
      begin
         Add('  ,''xxxxx''                     as update_value1');
         Add('  ,''zzzzz''                     as update_value2');
      end;
      Add('  , ''' + lTable + '''                 as table_name');
      Add('  , ''' + lTable + ''' + @calltasknum  as backup_table');
      Add('  , ''' + lPrimaryKey + '''            as pkey');
      Add('  , t.' + lPrimaryKey + '              as pkey_value');
      if (aActionType = 'D') or cbReplicationOnly.Checked then
         Add('  , N'''' as insert_set_sql')
      else if aActionType = 'U' then
         Add('  , N''t.status_ind = control.update_value1, t.active_ind = control.update_value2'' as insert_set_sql')
      else if aActionType = 'I' then
         Add('  , N''(,,) VALUES (,,)'' as insert_set_sql');
      Add('  , ''' + aActionType + '''            as action_type');

      if cboReplication.Text <> 'N' then
      begin
         if cbReplicationOnly.Checked then
            Add('  , ''O''                      as replicate_rec_ind')
         else
            Add('  , ''Y''                      as replicate_rec_ind');
         Add('  , ''N''                      as replicated_ind');
         Add('  , ''''                       as rep_target');
         Add('  ,''' + lBusinessObject + '''                as businessobject_name');
         Add('  , ''N''                      as transmit_full_ind');
      end;
      Add(' from ' + lTable + ' t (nolock)');
      if aActionType <> 'I' then
         Add(' where ' + lPrimaryKey + ' = ''xxxxxxx''');
   end;
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.btnSUpdateClick(Sender: TObject);
begin
   Example('U');
end;

procedure TdRDDataCorrectionGenerator.btnVUpdateClick(Sender: TObject);
var
   lTable, lPrimaryKey : String;
begin
   lTable := Trim(cboVTables.Text);
   lPrimaryKey := GetPrimaryKey(lTable);
   with sqlVerification.Lines do
   begin
      Add('not exists (');
      Add(' select top 1 1 from ' + lTable + ' t (nolock)');
      Add(' join ' + Trim(edtControlBackupTable.Text) + ' cb on cb.' + lPrimaryKey + ' = t.' + lPrimaryKey);
      Add(' where cb.status_ind_new <> t.status_ind');
      Add(' and   cb.execution_date_time = '' + CONVERT(VARCHAR, @now, 121) + '')');
   end;
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.btnTExampleClick(Sender: TObject);
begin
   with sqlTransaction.Lines do
   begin
      Add('DECLARE');
      Add(' @tradeweek_code   varchar(12),');
      Add(' @store_code       varchar(12);');
      Add('');
      Add('WHILE EXISTS (SELECT TOP 1 1 FROM ##tmp_tradeweek WHERE processed_ind = ''N'')');
      Add('BEGIN');
      Add('  SELECT TOP 1 1');
      Add('  @tradeweek_code = tradeweek_code,');
      Add('  @store_code = store_code');
      Add('  FROM ##tmp_tradeweek tmp WHERE processed_ind = ''N''');
      Add('');
      Add('  --Call a stored procedure');
      Add('  exec up_reload_salescube_tables');
      Add('  @tradeweek_code,');
      Add('  @store_code,');
      Add('  ''Y'', --create backup summary tables');
      Add('  ''N'' --Use original salelinecost records');
      Add('');
      Add('  --update the loop variable');
      Add('  UPDATE ##tmp_tradeweek SET processed_ind = ''Y''');
      Add('  WHERE  tradeweek_code = @tradeweek_code');
      Add('  AND    store_code = @store_code');
	   Add('END');
   end;
   GenerateResult;
end;

procedure TdRDDataCorrectionGenerator.btnSInsertClick(Sender: TObject);
begin
   Example('I');
end;

procedure TdRDDataCorrectionGenerator.btnSDeleteClick(Sender: TObject);
begin
   Example('D');
end;

procedure TdRDDataCorrectionGenerator.btnLoadClick(Sender: TObject);
var
   lFileName : String;
   lNotChosen : Boolean;
   lDC : TextFile;
   lLine : string;
   lPos : Integer;
   lWords : TStringList;
   lInDropTable, lInSelectInto, lInTransaction, lInVerification, lInProcCall : Boolean;
   lFinishedWithLine : Boolean;
begin
   lFileName := OpenFile(lNotChosen, 'Load Data Correction', '', self);

   if not lNotChosen then
   begin
      fLoading := True;
      lInDropTable := False;
      lInSelectInto := False;
      lInTransaction := False;
      lInVerification := False;
      lInProcCall := False;
      
      sqlResult.Lines.Clear;
      sqlSelectInto.Lines.Clear;
      sqlTransaction.Lines.Clear;
      sqlVerification.Lines.Clear;
      sqlResult.Lines.Clear;

      edtControlTable.Text       := '';
      edtControlBackupTable.Text := '';
      cboCallTask.Text           := '';
      cboRemediUser.Text         := '';
      edtScriptName.Text         := '';
      edtScriptDesc.Text         := '';
      cbCommit.Checked           := False;
      cbDebug.Checked            := False;
      cboReplication.Text        := 'N';
      edtRepLimit.Value          := -1;

      AssignFile(lDC, lFileName);
      Reset(lDC);
      lWords := TStringList.Create;
      try
         while not EOF(lDC) do
         begin
            lFinishedWithLine := False;
            ReadLn(lDC, lLine);
            lLine := Trim(lLine);
            SplitSql(lWords, lLine, ' ', False);

            if lWords.Count > 2 then
            begin
               if (lWords[0] = 'SET') then
               begin
                  if (lWords[1] = '@control_table') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        edtControlTable.Text := DynamicToNormal(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@control_backup_table') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        edtControlBackupTable.Text := DynamicToNormal(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@calltasknum') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        cboCallTask.Text := DynamicToNormal(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@remediuser_code') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        cboRemediUser.Text := DynamicToNormal(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@script_name') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        edtScriptName.Text := DynamicToNormal(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@script_desc') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        edtScriptDesc.Text := DynamicToNormal(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                     lInSelectInto := True;
                  end
                  else if (lWords[1] = '@commit_tran') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        cbCommit.Checked := DynamicToNormal(Trim(lLine)) = 'Y';
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@debug_ind') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        cbDebug.Checked := DynamicToNormal(Trim(lLine)) = 'Y';
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@replication_ind') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        cboReplication.Text := DynamicToNormal(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@rep_batch_limit') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        edtRepLimit.Value := StrToInt(Trim(lLine));
                     end;
                     lFinishedWithLine := True;
                  end
                  else if (lWords[1] = '@transaction_sql') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        sqlTransaction.Lines.Add(DynamicToNormal(Trim(lLine)));
                     end;
                     lFinishedWithLine := True;
                     lInTransaction := True;
                     lInVerification := False;
                     lInSelectInto := False;
                  end
                  else if (lWords[1] = '@verification_condition_sql') then
                  begin
                     lPos := AnsiPos('=', lLine);
                     if lPos <> 0 then
                     begin
                        Delete(lLine, 1, lPos);
                        sqlVerification.Lines.Add(DynamicToNormal(Trim(lLine)));
                     end;
                     lFinishedWithLine := True;
                     lInVerification := True;
                     lInTransaction := False;
                     lInSelectInto := False;
                  end;
               end;
            end;

            if (not lFinishedWithLine) then
            begin
               if AnsiContainsStr(Trim(lLine), 'EXEC dbo.usp_data_correction') or
                  AnsiContainsStr(Trim(lLine), 'EXEC usp_data_correction') then
                  lInProcCall := True;

               if not lInProcCall then
               begin
                  if AnsiContainsStr(Trim(lLine),'IF OBJECT_ID(''tempdb..') and AnsiContainsStr(Trim(lLine),') IS NOT NULL') then
                     lInDropTable := True
                  else if AnsiContainsStr(Trim(lLine),'END') and lInDropTable then
                  begin
                     lInDropTable := False;
                  end
                  else if (not lInDropTable) then
                  begin
                     if lInTransaction and (not lInSelectInto) and (not lInVerification) then
                     begin
                        sqlTransaction.Lines.Add(DynamicToNormal(Trim(lLine)));
                     end
                     else if lInVerification and (not lInSelectInto) and (not lInTransaction) then
                     begin
                        sqlVerification.Lines.Add(DynamicToNormal(Trim(lLine)));
                     end
                     else if lInSelectInto and (not lInTransaction) and (not lInVerification) then
                     begin
                        sqlSelectInto.Lines.Add(Trim(lLine));
                     end                     
                  end;
               end;
            end;
         end;
      finally
        fLoading := False;
        CloseFile(lDC);
        FreeAndNil(lWords);
      end;
      GenerateResult;
   end;
end;

procedure TdRDDataCorrectionGenerator.mmoSQLChange(Sender: TObject; scp : TSynCompletionProposal);
var
   lWordBeforeCursor : String;
   lWordAfterDot : String;
   lDotPos, lAliasIndex : Integer;
   lTableNames, lAliases : TStringList;
   lmmo : TSynMemo;
begin
   if (not gSettings.SQLAutoComplete) or fLoading then
      Exit;
   if fTypedSQLChange then
   begin
      lmmo := Sender as TSynMemo;

      //if the character after the cursor is whitespace
      //and the character before is not whitespace
      //then get the word before the cursor and use that
      //to filter the proposal
      scp.ItemList.Clear;

      if not fJustSQLCompleted then
      begin
         lWordBeforeCursor := GetWordBeforeCursor(lmmo);
         if lWordBeforeCursor <> '' then
         begin
            lDotPos := LastDelimiter('.', lWordBeforeCursor);
            if lDotPos <> 0 then
            begin
               lWordAfterDot := Copy(lWordBeforeCursor, lDotPos + 1, Length(lWordBeforeCursor) - lDotPos);
               Delete(lWordBeforeCursor, Length(lWordBeforeCursor), 1);

               lAliases := TStringList.Create;
               try
                  lTableNames := GetTableNames(Trim(lmmo.Text), lAliases);
                  lAliasIndex := lAliases.IndexOf(lWordBeforeCursor);
                  if lAliasIndex <> -1 then
                     AddFieldNamesToCompletionList(lWordAfterDot, lTableNames[lAliasIndex], scp)
                  else
                     AddFieldNamesToCompletionList(lWordAfterDot, lWordBeforeCursor, scp);
               finally
                  FreeAndNil(lAliases);
                  FreeAndNil(lTableNames);
               end;
            end
            else
            begin
               AddSQLKeywordsToCompletionList(lWordBeforeCursor, scp);
               AddTableNamesToCompletionList(lWordBeforeCursor, scp);
               AddFieldNamesFromTablesInSQLAndAliases(lWordBeforeCursor, lmmo, scp);
            end;
            scp.ActivateCompletion;
         end
         else
            scp.CancelCompletion;
      end
      else
         scp.CancelCompletion;

      fJustSQLCompleted := False;
   end;
end;

end.
