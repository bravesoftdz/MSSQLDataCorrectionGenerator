unit ufBDELockHandler;
{*******************************************************************************
|
| Description        :  Manages locking exceptions raised by the BDE. A record
|                       may be locked by another process e.g. DCM if this is
|                       running in SMS.
|
|                       To handle this we keep trying to update the record for
|                       a set amount of time untill the other process releases
|                       the lock.
|
|                       The lock timeout in SMS is higher than the DCM so that
|                       DCM is always chosen as the victim if there is a
|                       deadlock between SMS and DCM (DCM will just retry the
|                       task where SMS would fail the update and often go to a
|                       halt screen).
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| ********************* Version 4.7.5.1 ****************************************
| 016698 20110121 MDA   Merge task 016697 from 4.7.1.6
|                       Created.
*******************************************************************************}
interface

uses
   DBTables, Windows, BDE;

   function HandleBDELockException(const E: EDBEngineError; const aStartTime: DWORD): Boolean;
   function LockingError(aErrorCode: Integer): Boolean;
   function LockTimeout: DWORD;
   function TimeSince(aStartTime: DWORD): DWORD;

implementation

uses Math, mmSystem;

const
   {----------------------------------------------------------------------------
   | Maximum number of milliseconds to wait for an edit or delete lock to be
   | released in SMS. The DCM should be chosen as the deadlock victim when
   | contesting with SMS so this is higher than the DCM timeout below.
   }
   SMS_MAXDELETEEDITLOCKTIME = 13000;

   {----------------------------------------------------------------------------
   | Maximum number of milliseconds to wait for an edit or delete lock to be
   | released in the DCM.
   }
   DCM_MAXDELETEEDITLOCKTIME = 8000;


function HandleBDELockException(const E: EDBEngineError;
   const aStartTime: DWORD): Boolean;
{*******************************************************************************
|
| Description  :  Handles a BDE exception raised when attempting to update the
|                 database.
|
| Parameters   :  E:          The exception that was raised.
|                 aStartTime: Time time when we first started attempting to
|                             update the record. Used so we can quit trying if
|                             it is been blocking for too long.
|
| Returns      :  True if the exception was 'handled' (i.e. we should try to
|                 update the record again).
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 016698 20110121 MDA   Merge task 016697 from 4.7.1.6
|                       Created from TFTable.LockProtectDelEdit.
*******************************************************************************}
var
   lErrorCode: Integer;
begin
   lErrorCode := E.Errors[E.ErrorCount - 1].ErrorCode;

   if (not LockingError(lErrorCode)) or
      (TimeSince(aStartTime) > LockTimeout) then
   begin
         // If this was not a locking error or we have been
         // trying for more than the lock timeout, give up.
         Result := False;
   end
   else
   begin
      sleep(100); // We will try again...
      Result := True;
   end;
end;

function LockingError(aErrorCode: Integer): Boolean;
{*******************************************************************************
|
| Description  :  Returns True if the error code is a locking error.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 016698 20110121 MDA   Merge task 016697 from 4.7.1.6
|                       Created.
*******************************************************************************}
begin
   Result := (aErrorCode = DBIERR_FILELOCKED) or
             (aErrorCode = DBIERR_LOCKED) or
             (aErrorCode = DBIERR_RECLOCKFAILED);
end;

function LockTimeout: DWORD;
{*******************************************************************************
|
| Description  :  Returns the maximum time in milliseconds to keep trying to
|                 update the database before raising the locking exception.
|
|                 The lock timeout in SMS is higher than the DCM so that DCM is
|                 always chosen as the victim if there is a deadlock between SMS
|                 and DCM.
|
| ******************************************************************************
| Maintenance Log
|
| Task   Date     Who   Description
| ------ -------- ---   --------------------------------------------------------
| 016698 20110121 MDA   Merge task 016697 from 4.7.1.6
|                       Created.
*******************************************************************************}
begin
   Result := SMS_MAXDELETEEDITLOCKTIME;
end;

function TimeSince(aStartTime: DWORD): DWORD;
var
   lNow: DWORD;
begin
   lNow := TimeGetTime;
   if lNow < aStartTime then
      Result := lNow + Round(Power(2, 32)) - aStartTime
   else
      Result := lNow - aStartTime;
end;

end.
