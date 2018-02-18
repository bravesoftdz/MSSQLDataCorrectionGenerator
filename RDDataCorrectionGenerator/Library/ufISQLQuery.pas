unit ufISQLQuery;
{*******************************************************************************
|
| Description     :     Generic Query interface.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| ********************* Version 4.8.1.1 ****************************************
| 017357 20110418 MDA   Created.
*******************************************************************************}
interface

uses
   Classes, DB;

type
   ISQLQuery = interface
   ['{1F941B99-1857-4B8C-9869-9BA899C19C27}']
      function  GetSQL: TStrings;
      function  GetEOF: Boolean;
      function  GetFieldCount: Integer;
      function  GetFields: TFields;
      function  GetParams: TParams;
      function  GetActive: Boolean;
      function  GetPrepared: Boolean;
      function  GetRecordCount: Integer;
      procedure SetActive(aActive: Boolean);
      function  GetDataset: TDataSet;
      function  GetRowsAffected : Integer;

      procedure Open;
      procedure ExecSQL;
      procedure Prior;
      procedure Next;
      procedure Close;
      procedure First;
      procedure Append;
      procedure Edit;
      procedure Post;
      procedure Refresh;
      procedure EnableControls;
      procedure DisableControls;
      function  IsEmpty: Boolean;
      function  FindField(const aFieldName: WideString): TField;
      function  FieldByName(const aFieldName: WideString): TField;
      function  ParamByName(const aName: String): TParam;
      procedure SetParams(const aParamNames : String; aParamValues : Variant);
      procedure SetDateParam(const aParamName : String; aDateTime : TDateTime);
      procedure Prepare;

      function  NoLock: String; overload;
      function  NoLock(aTableName: String): String; overload;
      function  FormatDate(aDate: TDateTime): String;
      function  CharLengthExpr(const aField: String): String;
      procedure SetUniDir(aValue : Boolean);

      property  SQL         : TStrings  read GetSQL;
      property  Eof         : Boolean   read GetEOF;
      property  FieldCount  : Integer   read GetFieldCount;
      property  Fields      : TFields   read GetFields;
      property  Params      : TParams   read GetParams;
      property  Active      : Boolean   read GetActive         write SetActive;
      property  Prepared    : Boolean   read GetPrepared;
      property  RecordCount : Integer   read GetRecordCount;
      property  DataSet     : TDataSet  read GetDataSet;
      property  RowsAffected : Integer   read GetRowsAffected;
   end;


implementation

end.
