unit ufDBEQuery;
{*******************************************************************************
|
| Description        :  Subclass of the DBExpress TSQLQuery that implements the
|                       ISQLQuery interface.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| ********************* Version 4.9.16.1 ***************************************
| 024377	20140402	BCD	Ensure all SQL is compatible with mode 100.
| 024345 20140501 MDA   Clear parameters after executing SQL.
| ********************* Version 4.8.1.1 ****************************************
| 014684 20110719 CFR   Implement reference counting for self destruct.
| 017357 20110418 MDA   Created.
*******************************************************************************}
interface

uses
   Classes, DB, SqlExpr, ufISQLQuery;

type
   TDBEQuery = class(TSQLQuery, ISQLQuery)
   private
      fSQL      : TStringList;
      fRefCount : Integer;
      function  GetSQL: TStrings;
      function  GetEOF: Boolean;
      function  GetFieldCount: Integer;
      function  GetParams: TParams;
      function  GetFields: TFields;
      function  GetActive: Boolean;
      function  GetPrepared: Boolean;
      procedure AssignParentSQL(aSender : TObject);
      function  GetDataset: TDataSet;
      function  GetRowsAffected : Integer;
   protected
      function _AddRef: Integer; stdcall;
      function _Release: Integer; stdcall;
   public
      constructor Create(aOwner: TComponent); override;
      destructor  Destroy; override;

      procedure ExecSQL; reintroduce; overload;
      function  ExecSQL(ExecDirect: Boolean = False): Integer; overload; override;
      procedure Close; 

      procedure Prepare;

      procedure SetParams(const aParamNames : String; aParamValues : Variant);
      procedure SetDateParam(const aParamName : String; aDateTime : TDateTime);
      function  FormatDate(aDate: TDateTime): String;
      function  NoLock: String; overload;
      function  NoLock(aTableName: String): String; overload;
      function  CharLengthExpr(const aField: String): String;
      procedure SetUniDir(aValue : Boolean);

      property  SQL: TStrings read GetSQL;
      property  DataSet: TDataSet read GetDataSet;
      property  RowsAffected     : Integer      read GetRowsAffected;
   end;

implementation

uses
   SysUtils, SqlTimSt;

constructor TDBEQuery.Create(aOwner: TComponent);
{*******************************************************************************
|
| Description        :
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 014684 20110719 CFR   Created.
*******************************************************************************}
begin
   inherited;
   fRefCount := 0;
   fSQL      := TStringList.Create();
   fSQL.OnChange := AssignParentSQL;
end;

destructor TDBEQuery.Destroy;
{*******************************************************************************
|
| Description        :
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 014684 20110719 CFR   Created.
*******************************************************************************}
begin
   if Assigned(fSQL) then
      fSQL.Free;
   inherited;
end;

function  TDBEQuery.GetRowsAffected : Integer;
begin
   Result := RowsAffected;
end;

function TDBEQuery._AddRef: Integer;
{*******************************************************************************
|
| Description        :  Override behaviour to allow reference counting and
|                       indirect cleanup (expected from interface usage).
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 014684 20110719 CFR   Created.
*******************************************************************************}
begin
   Inc(fRefCount);
   Result := fRefCount;
end;

function TDBEQuery._Release: Integer;
{*******************************************************************************
|
| Description        :  Override behaviour to allow reference counting and
|                       indirect cleanup (expected from interface usage).
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 014684 20110719 CFR   Created.
*******************************************************************************}
begin
   Dec(fRefCount);
   Result := fRefCount;
   if Result = 0 then Destroy;
end;

procedure TDBEQuery.AssignParentSQL(aSender : TObject);
{*******************************************************************************
|
| Description        :  Assigns the TStringList exposed by this object, to the
|                       TWideStringList used by TSQLQuery.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   inherited SQL.Assign(fSQL);
end;

function TDBEQuery.CharLengthExpr(const aField: String): String;
{*******************************************************************************
|
| Description        :  Implementation of ISQLQuery CharLengthExpr. Returns the
|                       SQL expression to get the length of a Field.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   Result := ' LEN(' + aField + ') ';
end;

procedure TDBEQuery.Close;
begin
   inherited Close;
   Params.Clear;
end;

procedure TDBEQuery.ExecSQL;
begin
   ExecSQL(False);
   Params.Clear;
end;

function TDBEQuery.GetActive: Boolean;
begin
   Result := inherited Active;
end;

function TDBEQuery.GetDataset: TDataSet;
begin
   Result := (Self as TDataSet);
end;

function TDBEQuery.GetEOF: Boolean;
begin
   Result := inherited EOF;
end;

function TDBEQuery.GetFieldCount: Integer;
begin
   Result := inherited FieldCount;
end;

function TDBEQuery.GetFields: TFields;
begin
   Result := inherited Fields;
end;

function TDBEQuery.GetParams: TParams;
begin
   Result := inherited Params;
end;

function TDBEQuery.GetPrepared: Boolean;
begin
   Result := inherited Prepared;
end;

function TDBEQuery.ExecSQL(ExecDirect: Boolean): Integer;
{*******************************************************************************
|
| Description        :  Overrides the inherited ExecSQL. TSQLQuery uses a
|                       Unicode compatible TWideStrings for the SQL property.
|                       Since the Nexus components only use TStrings, this will
|                       ensure that they both implement the same interface by
|                       exposing a TStrings SQL property.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   inherited SQL.Clear;
   inherited SQL.Assign(fSQL);
   Result := inherited ExecSQL(ExecDirect);
   Params.Clear;
end;

function TDBEQuery.FormatDate(aDate: TDateTime): String;
{*******************************************************************************
|
| Description        :  Implementation of ISQLQuery FormatDate. Formats the date
|                       in a manner that can be used in an SQL where clause.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   Result := QuotedStr(FormatDateTime('yyyymmdd hh:mm:ss', aDate));
end;

function TDBEQuery.GetSQL: TStrings;
begin
   Result := fSQL;
end;

function TDBEQuery.NoLock(aTableName: String): String;
{*******************************************************************************
|
| Description        :  Implementation of ISQLQuery NoLock. Adds a (NOLOCK)
|                       locking hint after the table name.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   Result := ' ' + aTableName + NoLock;
end;

procedure TDBEQuery.Prepare;
begin
   inherited PrepareStatement;
end;

procedure TDBEQuery.SetDateParam(const aParamName: String; aDateTime: TDateTime);
{*******************************************************************************
|
| Description     :     Special considerations for a DateTime paramater
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 014684 20110719 CFR   Created.
*******************************************************************************}
begin
   Params.ParamByName(aParamName).AsSQLTimeStamp := DateTimeToSQLTimeStamp(aDateTime);
end;

procedure TDBEQuery.SetParams(const aParamNames: String; aParamValues: Variant);
{*******************************************************************************
|
| Description     :     Generic method to set a parameter value
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 014684 20110719 CFR   Created.
*******************************************************************************}
begin
   Params.ParamValues[aParamNames] := aParamValues;
end;

procedure TDBEQuery.SetUniDir(aValue : Boolean);
begin
   SetUniDirectional(aValue);
end;

function TDBEQuery.NoLock: String;
{*******************************************************************************
|
| Description        :  Implementation of ISQLQuery NoLock. Returns the (NOLOCK)
|                       locking hint.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 024377	20140402	BCD	Ensure all SQL is compatible with mode 100.
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   Result := ' WITH (NOLOCK) ';
end;

end.
