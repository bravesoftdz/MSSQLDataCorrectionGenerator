
----------usp_data_correction Example 4 Part 1----------------
-- Author	: DCL 30-MAY-2016
/*
   This made up example will update a handful of layby records but replicate them out in batches, meaning that the remaining records are
   replicated in Part 2
*/
DECLARE
  @control_table               NVARCHAR(64),    -- This can either be the name of a global temp table or a persistent table
  @transaction_sql             VARCHAR(MAX),   -- Executed inside the transaction
  @verification_condition_sql  VARCHAR(MAX),   -- Inside IF condition before transaction is committed.
  @commit_tran                 CHAR(1),        -- 'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing
  @debug_ind                   CHAR(1),         -- This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  @control_backup_table        VARCHAR(64),    -- i.e.'rd_063567_22052016'
  @now                         DATETIME,       -- GetDate()
  --Audit Trail
  @calltasknum		           VARCHAR(12),	  -- This is your Call Number or Task Number
  @remediuser_code	           VARCHAR(12),	  -- This will be your ErrorEvent ID (auto-generated)
  @script_name		           VARCHAR(50),	  -- This is the short description of your script.
  @script_desc		           VARCHAR(120),	  -- This is the description of your script from SQL Checklist.
  --Replication
  @replication_ind             CHAR(1);        -- 'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored


SET @control_table          = 'rd_xxxxxx'  --Persistent
SET @commit_tran            = 'N'
SET @debug_ind              = 'Y'
  --Backup
SET @control_backup_table   = 'RD_xxxxxx_20160523'
SET @now                    = GetDate()
  --Audit Trail
SET @calltasknum		    = 'xxxxxx'
SET @remediuser_code	    = 'DCL'
SET @script_name		    = 'Replicate in batches.'
SET @script_desc		    = 'Replicate in batches.'
  --Replication
SET @replication_ind        = 'N'

IF OBJECT_ID('rd_xxxxxx') IS NOT NULL
BEGIN
  DROP TABLE rd_xxxxxx
END
CREATE TABLE	rd_xxxxxx (
  execution_date_time DATETIME not null,
  layby_status_ind_new CHAR(1) not null,
  table_name 		  VARCHAR(32) not null,
  backup_table        VARCHAR(32) not null,
  pkey                VARCHAR(32) not null,
  pkey_value	      VARCHAR(24) not null,
  insert_set_sql      NVARCHAR(1000) not null,  
  action_type 		  CHAR(1) not null,
  replicate_rec_ind   CHAR(1) not null,
  replicated_ind      CHAR(1) not null,
  rep_target          VARCHAR(13),
  businessobject_name VARCHAR(34) not null,  
  transmit_full_ind	  CHAR(1) null
)

insert into rd_xxxxxx	
select	
        @now                       as execution_date_time 
    ,   'F'                        as layby_status_ind_new
	,   'layby'	                   as table_name
	,   'layby' + @calltasknum     as backup_tablename
    ,   'layby_id'                 as pkey
    ,   l.layby_id                 as pkey_value
    ,   N't.layby_status_ind = control.layby_status_ind_new' as insert_set_sql
    ,   'U'                        as action_type            -- ''I''(Insert), ''U''(Update), ''D''(Delete)	
    ,   'Y'                        as replicate_rec_ind	   -- ''Y''(Yes), ''N''(No). If ''N'', then the following parameters are ignored
	,   'N'                        as replicated_ind
    ,   l.store_code               as rep_target             -- This record will only replicate to this location. NULL/'' means everywhere	
    ,   'ToLayby'                  as businessobject_name    -- i.e. ''ToSale'', ''ToLayby'', ''ToUnitLoad''    
	,   'N'                        as transmit_full_ind      -- ''Y''(Replicate the whole BO), ''N''(Just this record)	
from	layby	l	with (nolock)
where layby_id in (
                     'xxxxxxxxxxxxxxx',
					 'xxxxxxxxxxxxxxx'
                   )	

SET @transaction_sql = N''

SET @verification_condition_sql = N'
    not exists
	(	select	top 1 1
		from	layby	l	(nolock)
		join	' + @control_backup_table + ' t
		on		t.pkey_value = l.layby_id
		where	t.execution_date_time = ''' + CONVERT(VARCHAR, @now, 121) + '''
		and		t.layby_status_ind_new <> l.layby_status_ind)
'

EXEC dbo.usp_data_correction
    @control_table               -- This can either be the name of a global temp table or a persistent table
  , @transaction_sql             -- VARCHAR(MAX)   Executed inside the transaction
  , @verification_condition_sql  -- VARCHAR(MAX)   Inside IF condition before transaction is committed.
  , @commit_tran                 -- CHAR(1)        'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing
  , @debug_ind                   -- CHAR(1),        This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  , @control_backup_table        -- VARCHAR(64)    i.e.'rd_063567_22052016'
  , @now                         -- GetDate()
  --Audit Trail
  , @calltasknum                 -- VARCHAR(12)    This is your Call Number or Task Number
  , @script_name                 -- VARCHAR(50)    This is the short description of your script.
  , @script_desc                 -- VARCHAR(120)   This is the description of your script from SQL Checklist.
  , @remediuser_code             -- VARCHAR(12)    This will be your ErrorEvent ID (auto-generated)
  --Replication
  , @replication_ind             -- CHAR(1)        'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored
  

--ROLLBACK TRAN  
--COMMIT TRAN 
