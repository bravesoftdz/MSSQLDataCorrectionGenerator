unit ufDBEDatabase;
{*******************************************************************************
|
| Description        :  Head office database class. Uses DBExpress to connect
|                       to the MSSQL database.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| ********************* Version 4.9.18.5 ***************************************
| 024072 20141201 DKN   Add a SetConnected function to handle the disconnect
|                       sequence.
|                       You need to do this for the DBExpress adapater or
|                       you'll get Access Violations when you try to close it
|                       normally.
| ********************* Version 4.9.16.1 ***************************************
| 024345 20140501 MDA   Ignore tempdb when getting database names.
| ********************* Version 4.8.1.1 ****************************************
| 014684 20110719 CFR   Adapted for Promotion Engine usage.
| 017357 20110418 MDA   Created.
*******************************************************************************}
interface

uses
   Classes, SqlExpr, ufISQLDatabase, ufISQLQuery, DBXCommon;

type
   TDBEDatabase = class(TSQLDatabase)
   private
      fConnection : TSQLConnection;
      //fTransaction : TDBXTransaction;
   protected
      function GetConnected: Boolean; override;
      procedure SetConnected(const aConnected: Boolean); override;
      function  GetInTransaction: Boolean; override;
      function  GetTimeout: Integer; override;
      procedure SetTimeout(const aTimeout: Integer); override;      
   public
      constructor Create;
      destructor  Destroy; override;

      function  NewQuery: ISQLQuery; override;
      procedure Connect; override;
      function  GetDatabaseNames: TStrings; override;

      function  GetServerName: String; override;
      function  GetAliasName: String;  override;
      function  GetUserName: String;   override;
      function  GetPassword: String;   override;
      procedure SetServerName(const aServerName: String); override;
      procedure SetAliasName(const aAliasName: String); override; 
      procedure SetUserName(const aUserName: String);   override;
      procedure SetPassword(const aPassword: String);   override;
      procedure StartTransaction(aTablesAffected: TStringList = nil); override;
      procedure Commit; override;
      procedure Rollback; override;
      procedure DeleteAlias(aAliasName: String); override;
      procedure UsePipedTransport; override;
      function  GetTableNames: TStringList; override;
      function  GetStoredProcNames: TStringList; override;

      property  ServerName : String   read GetServerName write SetServerName;
      property  AliasName  : String   read GetAliasName  write SetAliasName;
      property  UserName   : String   read GetUserName   write SetUserName;
      property  Password   : String   read GetPassword   write SetPassword;
      property  InTransaction : Boolean         read GetInTransaction;
      property  Timeout    : Integer  read GetTimeout    write SetTimeout;
   end;

implementation

uses
   SysUtils, ufDBEQuery;

constructor TDBEDatabase.Create;
{*******************************************************************************
|
| Description        :  Initialises a new TDBEDatabase
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   fConnection := TSQLConnection.Create(nil);
   fConnection.DriverName     := 'MSSQL';
   fConnection.LibraryName    := 'dbxmss30.dll';
   fConnection.VendorLib      := 'oledb';
   fConnection.GetDriverFunc  := 'getSQLDriverMSSQL';
   fConnection.LoginPrompt    := False;
end;

destructor TDBEDatabase.Destroy;
{*******************************************************************************
|
| Description        :  Cleans up the TDBEDatabase object.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110622 MDA   Created.
*******************************************************************************}
begin
   if Assigned(fConnection) then
   begin
      fConnection.Close();          
      FreeAndNil(fConnection);
   end;
   inherited;
end;

procedure TDBEDatabase.Connect;
{*******************************************************************************
|
| Description        :  Creates the connection to the head office database.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
begin
   fConnection.Connected := True;
   DoAfterConnect;
end;

function TDBEDatabase.GetConnected: Boolean;
{*******************************************************************************
|
| Description        :  Getter for the Connected property.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110622 MDA   Created.
*******************************************************************************}
begin
   Result := fConnection.Connected;
end;

function TDBEDatabase.GetDatabaseNames: TStrings;
{*******************************************************************************
|
| Description        :  Gets a list of database names available on the server.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 024345 20140501 MDA   Ignore tempdb.
| 017357 20110622 MDA   Created.
*******************************************************************************}
begin
   Result := TStringList.Create;
   with NewQuery do
   begin
      SQL.Add('SELECT Name');
      SQL.Add('FROM Sysdatabases');
      SQL.Add('WHERE Name <> ' + QuotedStr('master'));
      SQL.Add('AND Name <> '   + QuotedStr('model'));
      SQL.Add('AND Name <> '   + QuotedStr('msdb'));
      SQL.Add('AND Name <> '   + QuotedStr('pubs'));
      SQL.Add('AND Name <> '   + QuotedStr('tempdb'));
      Open;
      First;
      while not EOF do
      begin
         Result.Add(FieldByName('Name').AsString);
         Next;
      end;
   end;
end;

function TDBEDatabase.NewQuery: ISQLQuery;
{*******************************************************************************
|
| Description        :  Creates and returns a new THeadOfficeQuery
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 017357 20110418 MDA   Created.
*******************************************************************************}
var
   lQry: TDBEQuery;
begin
   inherited;
   lQry := TDBEQuery.Create(nil);
   lQry.SQLConnection := fConnection;
   Result := (lQry as ISQLQuery);
end;

function TDBEDatabase.GetServerName: String;
begin
   Result := fConnection.Params.Values['HostName'];
end;

function TDBEDatabase.GetTableNames: TStringList;
begin
   Result := TStringList.Create;
   fConnection.GetTableNames(Result, True);
end;

function  TDBEDatabase.GetStoredProcNames: TStringList;
begin
   Result := TStringList.Create;
end;

function TDBEDatabase.GetTimeout: Integer;
begin
   Result := 0;
   //Result := StrToInt(fConnection.Params.Values['ConnectTimeout']);
end;

function TDBEDatabase.GetAliasName: String;
begin
   Result := fConnection.Params.Values['DataBase'];
end;

function TDBEDatabase.GetUserName: String;
begin
   Result := fConnection.Params.Values['User_Name'];
end;

function TDBEDatabase.GetPassword: String;
begin
   Result := fConnection.Params.Values['Password'];
end;

procedure TDBEDatabase.SetServerName(const aServerName: String);
begin
   fConnection.Params.Values['HostName']  := aServerName;
end;

procedure TDBEDatabase.SetTimeout(const aTimeout: Integer);
begin
  inherited;
  //This doesn't exist here
  //fConnection.Params.Values['ConnectTimeout'] := IntToStr(aTimeout);
end;

procedure TDBEDatabase.SetAliasName(const aAliasName: String);
begin
   fConnection.Params.Values['DataBase']  := aAliasName;
end;

procedure TDBEDatabase.SetConnected(const aConnected: Boolean);  
{*******************************************************************************
|
| Description        :  Set the connected status of the connection
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 024072 20141201 DKN   Created.
*******************************************************************************}
begin
  //inherited;
   if aConnected then //connecting now. (doesn't mean 'already connected')
   begin
      inherited SetConnected(aConnected);
   end
   else //disconnecting
   begin
      try // except
         //You must do the extra step of closing datasets for this
         //DBExpress adapater.
         with fConnection do
         begin
            if Connected then
            begin
               CloseDataSets;
               Close;
            end; // if connected
         end; // with fConnection

      except
      end; // try...except
   end; 
end;

procedure TDBEDatabase.SetUserName(const aUserName: String);
begin
   fConnection.Params.Values['User_Name'] := aUserName;
end;

procedure TDBEDatabase.SetPassword(const aPassword: String);
begin
   fConnection.Params.Values['Password']  := aPassword;
end;

procedure TDBEDatabase.StartTransaction(aTablesAffected : TStringList = nil);
begin
   //fTransaction := fConnection.BeginTransaction;
end;

procedure TDBEDatabase.Commit;
begin
   //fConnection.Commit(fTransaction);
end;

procedure TDBEDatabase.Rollback;
begin
   //fConnection.Rollback(fTransaction);
end;

function TDBEDatabase.GetInTransaction: Boolean;
begin
   Result := fConnection.InTransaction;
end;

procedure TDBEDatabase.DeleteAlias(aAliasName: String);
begin
//   fConnection.Session.Active := True;
//   if Session.IsAlias(aAliasName) then
//      Session.DeleteAlias(aAliasName);
end;

procedure TDBEDatabase.UsePipedTransport;
begin
   //nothing for MSSQL
end;

end.
