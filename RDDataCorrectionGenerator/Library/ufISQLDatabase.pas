unit ufISQLDatabase;
{*******************************************************************************
|
| Description        :  Abstract base class for a 'Database' - either a head
|                       office MSSQL database or a POS Nexus database.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| ********************* Version 4.9.16.1 ***************************************
| 024345 20140501 MDA   Added GetDatabaseNames function.
| ********************* Version 4.8.1.1 ****************************************
| 014684 20110719 CFR   Added Interface definition
| 017357 20110418 MDA   Created.
*******************************************************************************}
interface

uses
   Classes, ufISQLQuery;

type
   ISQLDatabase = interface
   ['{BF29F0B1-18E4-484D-92C4-DF87404A5147}']
      function  GetConnected: Boolean;
      function  GetServerName: String;
      function  GetAliasName: String;
      function  GetUserName: String;
      function  GetPassword: String;
      function  GetTimeout: Integer;
      procedure SetConnected(const aConnected: Boolean);
      procedure SetServerName(const aServerName: String);
      procedure SetAliasName(const aAliasName: String);
      procedure SetUserName(const aUserName: String);
      procedure SetPassword(const aPassword: String);
      procedure SetTimeout(const aTimeout: Integer);
      procedure DeleteAlias(aAliasName: String);
      function  GetInTransaction: Boolean;
      procedure Connect;
      function  NewQuery: ISQLQuery;
      function  GetDatabaseNames: TStrings;
      procedure StartTransaction(aTablesAffected : TStringList = nil);
      procedure Commit;
      procedure Rollback;
      function  GetTableNames: TStringList;
      function  GetStoredProcNames: TStringList;
      procedure UsePipedTransport;
      property  InTransaction : Boolean  read GetInTransaction;
      property  Connected  : Boolean  read GetConnected  write SetConnected;
      property  ServerName : String   read GetServerName write SetServerName;
      property  AliasName  : String   read GetAliasName  write SetAliasName;
      property  UserName   : String   read GetUserName   write SetUserName;
      property  Password   : String   read GetPassword   write SetPassword;
      property  Timeout    : Integer  read GetTimeout    write SetTimeout;
   end;

   TAfterConnectEvent = procedure of object;

   TSQLDatabase = class(TInterfacedObject, ISQLDatabase)
   private
      fAfterConnect: TAfterConnectEvent;
   protected
      function  GetInTransaction: Boolean; virtual; abstract;
      function  GetConnected: Boolean; virtual; abstract;
      function  GetServerName: String; virtual; abstract;
      function  GetAliasName: String; virtual; abstract;
      function  GetUserName: String;  virtual; abstract;
      function  GetPassword: String; virtual; abstract;
      procedure SetConnected(const aConnected: Boolean); virtual;
      procedure SetServerName(const aServerName: String); virtual; abstract;
      procedure SetAliasName(const aAliasName: String); virtual; abstract;
      procedure SetUserName(const aUserName: String); virtual; abstract;
      procedure SetPassword(const aPassword: String); virtual; abstract;
      function  GetTimeout: Integer; virtual; abstract;
      procedure SetTimeout(const aTimeout: Integer); virtual; abstract;
      procedure DoAfterConnect;
   public
      procedure Connect; virtual; abstract;
      procedure StartTransaction(aTablesAffected : TStringList = nil); virtual; abstract;
      procedure Commit; virtual; abstract;
      procedure Rollback; virtual; abstract;
      function  NewQuery: ISQLQuery; virtual; abstract;
      function  GetDatabaseNames: TStrings; virtual;
      function  GetTableNames: TStringList; virtual; abstract;
      function  GetStoredProcNames: TStringList; virtual; abstract;
      procedure DeleteAlias(aAliasName: String); virtual; abstract;
      procedure UsePipedTransport; virtual; abstract;

      property  AfterConnect : TAfterConnectEvent   read fAfterConnect   write fAfterConnect;
      property  Connected    : Boolean              read GetConnected    write SetConnected;
      property  ServerName   : String               read GetServerName   write SetServerName;
      property  AliasName    : String               read GetAliasName    write SetAliasName;
      property  UserName     : String               read GetUserName     write SetUserName;
      property  Password     : String               read GetPassword     write SetPassword;
      property  InTransaction  : Boolean         read GetInTransaction;
      property  Timeout    : Integer  read GetTimeout    write SetTimeout;
   end;

implementation

procedure TSQLDatabase.DoAfterConnect;
{*******************************************************************************
|
| Description        :  Fires the AfterConnect event if it is assigned.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   -------------------------------------------------------
| 017357 20110622 MDA   Created.
*******************************************************************************}
begin
   if Assigned(fAfterConnect) then
      fAfterConnect;
end;

function TSQLDatabase.GetDatabaseNames: TStrings;
begin
   Result := nil;
end;

procedure TSQLDatabase.SetConnected(const aConnected: Boolean);
{*******************************************************************************
|
| Description        :  Setter for the Connected property.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   -------------------------------------------------------
| 017357 20110622 MDA   Created.
*******************************************************************************}
begin
   if aConnected and (not Connected) then
      Connect;
end;

end.
