unit ufTFQuery;
{*******************************************************************************
|
| Description        :  SMS query class. This should be used in preference to a
|                       TQuery as it better handles record locks by other
|                       processes.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| ********************* Version 4.7.6.1 ****************************************
| 017366 20110513 MDA   Add lock handling for Open method. Added Database
|                       property to aid conversion to Nexus.
| ********************* Version 4.7.5.1 ****************************************
| 016698 20110121 MDA   Merge task 016697 from 4.7.1.6
|                       Moved record lock exception handling to ufBDELockHandler.
| ***************** Version 4.7.3.1 ********************************************
| 016550 20101026 MDA   Created.
*******************************************************************************}
interface

uses
   DBTables, DB;

type
   TFQuery = class(TQuery)
  private
      procedure SetDatabase(const aDatabase: TDatabase);
      function GetDatabase: TDatabase;
      function GetDataSet: TDataSet;
   public
      procedure ExecSQL;
      procedure Open;
   published
      property Database: TDatabase read GetDatabase write SetDatabase;
      property DataSet: TDataSet read GetDataSet;
   end;

implementation

uses
   Windows, MMSystem, ufBDELockHandler;

procedure TFQuery.ExecSQL;
{*******************************************************************************
|
| Description  :  Similar to the TFTable LockProtectDelEdit function. When we
|                 execute the query the record may be locked by another process
|                 e.g. DCM if this is running in SMS.
|
|                 This will keep trying to execute for a period in the hope
|                 that the lock will be released.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 016698 20110121 MDA   Merge task 016697 from 4.7.1.6
|                       Moved record lock exception handling to ufBDELockHandler.
| 016550 20101026 MDA   Created.
*******************************************************************************}
var
   lStartTime: DWORD;
   lSQLSuccessful: Boolean;
begin
   lSQLSuccessful := False;
   lStartTime := TimeGetTime;
   while not lSQLSuccessful do
   begin
      try
         inherited ExecSQL;
         lSQLSuccessful := True;
      except
         on E: EDBEngineError do
         begin
            if not HandleBDELockException(E, lStartTime) then
               raise;
         end;
      end;
   end;
end;

function TFQuery.GetDatabase: TDatabase;
{*******************************************************************************
|
| Description  :  Getter method for the Database property. This property is here
|                 to aid the conversion to the NexusDB TnxQuery component which
|                 uses this instead of DatabaseName and SessionName.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017366 20110513 MDA   Created.
*******************************************************************************}
begin
   Result := inherited Database;
end;

function TFQuery.GetDataSet: TDataSet;
begin
   Result := (Self as TDataset);
end;

procedure TFQuery.Open;
{*******************************************************************************
|
| Description  :  Opens the query object.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017366 20110513 MDA   Created.
*******************************************************************************}
var
   lStartTime: DWORD;
   lSQLSuccessful: Boolean;
begin
   lSQLSuccessful := False;
   lStartTime := TimeGetTime;
   while not lSQLSuccessful do
   begin
      try
         inherited Open;
         lSQLSuccessful := True;
      except
         on E: EDBEngineError do
         begin
            if not HandleBDELockException(E, lStartTime) then
               raise;
         end;
      end;
   end;
end;

procedure TFQuery.SetDatabase(const aDatabase: TDatabase);
{*******************************************************************************
|
| Description  :  Setter method for the Database property. This property is here
|                 to aid the conversion to the NexusDB TnxQuery component which
|                 uses this instead of DatabaseName and SessionName.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017366 20110513 MDA   Created.
*******************************************************************************}
begin
  DatabaseName := aDatabase.DatabaseName;
  SessionName  := aDatabase.SessionName;
end;

end.
