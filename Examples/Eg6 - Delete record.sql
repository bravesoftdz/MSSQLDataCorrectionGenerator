/*
  xxxxxx DCL 2-11-2016 script desc
*/
DECLARE
  @control_table               NVARCHAR(64),    -- This can either be the name of a global temp table or a persistent table.
  @transaction_sql             NVARCHAR(MAX),   -- Executed inside the transaction.
  @verification_condition_sql  NVARCHAR(MAX),   -- Inside IF condition before transaction is committed.
  @commit_tran                 CHAR(1),         -- 'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing.
  @debug_ind                   CHAR(1),         -- This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  @control_backup_table        NVARCHAR(64),    -- i.e.'rd_063567'
  @now                         DATETIME,        -- i.e. GetDate()
  --Audit Trail
  @calltasknum                 VARCHAR(12),     -- This is your Call Number or Task Number.
  @remediuser_code             VARCHAR(12),     -- This will be your ErrorEvent ID (auto-generated).
  @script_name                 VARCHAR(50),     -- This is the short description of your script.
  @script_desc                 VARCHAR(120),    -- This is the description of your script from SQL Checklist.
  --Replication
  @replication_ind             CHAR(1)          -- 'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored.

SET @control_table            = '##xxxxxx'
SET @commit_tran              = 'N'
SET @debug_ind                = 'Y'
  --Backup
SET @control_backup_table     = 'xxxxxx_backup'
SET @now                      = GetDate()
  --Audit Trail
SET @calltasknum              = 'xxxxxx'
SET @remediuser_code          = 'DCL'
SET @script_name              = 'script name'
SET @script_desc              = 'script desc'
  --Replication
SET @replication_ind          = 'N'

IF OBJECT_ID('tempdb..##xxxxxx') IS NOT NULL
BEGIN
   DROP TABLE ##xxxxxx
END
CREATE TABLE	##xxxxxx (
  execution_date_time DATETIME not null,
  table_name 		  VARCHAR(32) not null,
  backup_table        VARCHAR(32) not null,
  pkey                VARCHAR(32) not null,
  pkey_value	      VARCHAR(24) not null,
  insert_set_sql      NVARCHAR(1000) not null,  
  action_type 		  CHAR(1) not null
)

insert into ##xxxxxx
select
@now                          as execution_date_time
, 'pderecord'                 as table_name
, 'pderecord' + @calltasknum  as backup_table
, 'pderecord_id'              as pkey
, t.pderecord_id              as pkey_value
, N''                         as insert_set_sql
, 'D'                         as action_type
from pderecord t (nolock)
where pderecord_id = 'xxxxxxx'

SET @transaction_sql = N''
SET @verification_condition_sql = N''

EXEC dbo.usp_data_correction
    @control_table               -- This can either be the name of a global temp table or a persistent table.
  , @transaction_sql             -- NVARCHAR(MAX)   Executed inside the transaction.
  , @verification_condition_sql  -- NVARCHAR(MAX)   Inside IF condition before transaction is committed.
  , @commit_tran                 -- CHAR(1)        'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing.
  , @debug_ind                   -- CHAR(1),        This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  , @control_backup_table        -- NVARCHAR(64)    i.e.'rd_063567'
  , @now                         -- DATETIME        When the control table already exists, the transaction and backup will only effect this time
  --Audit Trail
  , @calltasknum                 -- VARCHAR(12)     This is your Call Number or Task Number.
  , @script_name                 -- VARCHAR(50)     This is the short description of your script.
  , @script_desc                 -- VARCHAR(120)    This is the description of your script from SQL Checklist.
  , @remediuser_code             -- VARCHAR(12)     This will be your ErrorEvent ID (auto-generated).
  --Replication
  , @replication_ind             -- CHAR(1)         'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored.

--COMMIT TRAN
--ROLLBACK TRAN