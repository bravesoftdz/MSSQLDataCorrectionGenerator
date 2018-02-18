
----------usp_data_correction Example 2----------------
-- Author	: DCL 30-MAY-2016
/*
   This example will not do an update but will replicate itemcoloursupplier records by retail chain
*/
DECLARE
  @control_table               NVARCHAR(64),    -- This can either be the name of a global temp table or a persistent table
  @transaction_sql             VARCHAR(MAX),   -- Executed inside the transaction
  @verification_condition_sql  VARCHAR(MAX),   -- Inside IF condition before transaction is committed.
  @commit_tran                 CHAR(1),        -- 'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing
  @debug_ind                   CHAR(1),         -- This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  @control_backup_table       VARCHAR(64),    -- i.e.'rd_063567_22052016'
  @now                         DATETIME,       -- GetDate()
  --Audit Trail
  @calltasknum		           VARCHAR(12),	  -- This is your Call Number or Task Number
  @remediuser_code	           VARCHAR(12),	  -- This will be your ErrorEvent ID (auto-generated)
  @script_name		           VARCHAR(50),	  -- This is the short description of your script.
  @script_desc		           VARCHAR(120),	  -- This is the description of your script from SQL Checklist.
  --Replication
  @replication_ind             CHAR(1);        -- 'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored

SET @control_table          = '##rd_063646'
SET @commit_tran            = 'N'
SET @debug_ind              = 'Y'
  --Backup
SET @control_backup_table   = 'RD_063646_20160523'
SET @now                    = GetDate()
  --Audit Trail
SET @calltasknum		    = '063646'
SET @remediuser_code	    = 'SBU'
SET @script_name		    = 'Replicate ICSupp.'
SET @script_desc		    = 'Replicate ICSupp by Retail Chain.'
  --Replication
SET @replication_ind        = 'Y'     

IF OBJECT_ID('tempdb..##rd_063646') IS NOT NULL
BEGIN
  DROP TABLE ##rd_063646
END
CREATE TABLE	##rd_063646 (
  execution_date_time DATETIME not null,
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

insert into ##rd_063646
select  TOP 400
		@now                                    as  execution_date_time
    ,	'itemcoloursupplier'                    as  table_name
    ,   'itemcoloursupplier' + @calltasknum     as  backup_table	
	,   'itemcoloursupplier_id'                 as  pkey				
	,   icsupp.itemcoloursupplier_id            as  pkey_value  
	,   N''                                     as  insert_set_sql	
	,	'U'				                        as  action_type
	,   'O'                                     as  replicate_rec_ind
	,   'N'                                     as  replicated_ind
    ,   '^' + icr.retailchain_code              as  rep_target
    ,   'ToItem'                                as  businessobject_name	
	,	'N'                                     as  transmit_full_ind		
from	item				i		(nolock)
join	itemcolour	ic	(nolock) on	ic.item_code = i.item_code
join	itemretailchain	icr	(nolock) on	icr.item_code = ic.item_code
join	itemcoloursupplier	icsupp	(nolock) on	icsupp.itemcolour_id = ic.itemcolour_id
join	retailchain	rc (nolock) on	rc.retailchain_code	 = icr.retailchain_code
where	i.active_ind			= 'Y'
and		ic.active_ind			= 'Y'
and		rc.active_ind			= 'Y'
order by
		icr.retailchain_code
	,	ic.item_code
	,	ic.seq_in_item
	,	icsupp.primary_ind desc
	,	icsupp.supplier_code

SET @transaction_sql = N''
SET @verification_condition_sql = N''

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
