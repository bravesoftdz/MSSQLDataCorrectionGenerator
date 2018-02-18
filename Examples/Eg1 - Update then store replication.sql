
----------usp_data_correction Example 1----------------
-- Author	: DCL 30-MAY-2016
/*
   This example is updating one field for a range of script records, with store specific replication
*/
DECLARE
  @control_table               NVARCHAR(64),    -- This can either be the name of a global temp table or a persistent table
  @transaction_sql             NVARCHAR(MAX),   -- Executed inside the transaction
  @verification_condition_sql  NVARCHAR(MAX),   -- Inside IF condition before transaction is committed.
  @commit_tran                 CHAR(1),         -- 'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing
  @debug_ind                   CHAR(1),         -- This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  @control_backup_table        NVARCHAR(64),    -- i.e.'rd_063567_22052016'
  @now                         DATETIME,        -- GetDate()
  --Audit Trail
  @calltasknum		           VARCHAR(12),	    -- This is your Call Number or Task Number
  @remediuser_code	           VARCHAR(12),	    -- This will be your ErrorEvent ID (auto-generated)
  @script_name		           VARCHAR(50),	    -- This is the short description of your script.
  @script_desc		           VARCHAR(120),	-- This is the description of your script from SQL Checklist.
  --Replication
  @replication_ind             CHAR(1);         -- 'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored

SET @control_table          = '##rd_063567'  
SET @commit_tran            = 'N'
SET @debug_ind              = 'Y'
  --Backup
SET @control_backup_table   = 'rd_063567_22052016'
SET @now                    = GetDate()
  --Audit Trail
SET @calltasknum		    = '063802'
SET @remediuser_code	    = 'DCL'
SET @script_name		    = 'Change Script status.'
SET @script_desc		    = 'Change Script status.'
  --Replication
SET @replication_ind        = 'Y'     

IF OBJECT_ID('tempdb..##rd_063567') IS NOT NULL
BEGIN
  DROP TABLE ##rd_063567
END
CREATE TABLE	##rd_063567 (
  execution_date_time DATETIME not null,
  status_ind_new      CHAR(1) not null,
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

insert into ##rd_063567
select     
  	@now                       as execution_date_time
  ,	'P'                 	   as status_ind_new	   -- Update value
  , 'script'	               as table_name
  , 'script' + @calltasknum    as backup_table
  , 'script_id'                as pkey
  , t.script_id                as pkey_value
  , N't.status_ind = control.status_ind_new' as insert_set_sql
  , 'U'                        as action_type            -- ''I''(Insert), ''U''(Update), ''D''(Delete)  
  --Replication fields
  , 'Y'                        as replicate_rec_ind	     -- ''Y''(Yes), ''N''(No). If ''N'', then the following parameters are ignored
  , 'N'                        as replicated_ind
  , t.store_code               as rep_target             -- This record will only replicate to this location. NULL/'' means everywhere  
  , 'ToScript'                 as businessobject_name    -- i.e. ''ToSale'', ''ToLayby'', ''ToUnitLoad''      	  
  , 'N'                        as transmit_full_ind      -- ''Y''(Replicate the whole BO), ''N''(Just this record)	    
from script t (nolock)
left join sale s (nolock) on (s.sale_code = t.sale_code)
where t.status_ind = 'A'
and (s.sale_status_ind in ('A', 'V', 'P'))
and t.store_code is not null
and not exists
 (select 1 from saleline sl1 (nolock) 
 where (sl1.backward_xy_pointer = t.script_id))	 

SET @transaction_sql = N''
	
SET @verification_condition_sql = N'
            not exists (
			select top 1 1
			from	script	s	(nolock)
			join	' + @control_backup_table + ' t
			on		(t.pkey_value = s.script_id)  
			where   t.status_ind_new <> s.status_ind
			and     t.table_name = ''script''
			and	    t.execution_date_time = ''' + CONVERT(VARCHAR, @now, 121) + ''')'


EXEC dbo.usp_data_correction
    @control_table               -- This can either be the name of a global temp table or a persistent table
  , @transaction_sql             -- NVARCHAR(MAX)   Executed inside the transaction
  , @verification_condition_sql  -- NVARCHAR(MAX)   Inside IF condition before transaction is committed.
  , @commit_tran                 -- CHAR(1)        'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing
  , @debug_ind                   -- CHAR(1),        This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  , @control_backup_table        -- NVARCHAR(64)    i.e.'rd_063567_22052016'
  , @now                         -- GetDate()
  --Audit Trail
  , @calltasknum                 -- VARCHAR(12)    This is your Call Number or Task Number
  , @script_name                 -- VARCHAR(50)    This is the short description of your script.
  , @script_desc                 -- VARCHAR(120)   This is the description of your script from SQL Checklist.
  , @remediuser_code             -- VARCHAR(12)    This will be your ErrorEvent ID (auto-generated)
  --Replication
  , @replication_ind             -- CHAR(1)        'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored

--COMMIT TRAN 
--ROLLBACK TRAN
