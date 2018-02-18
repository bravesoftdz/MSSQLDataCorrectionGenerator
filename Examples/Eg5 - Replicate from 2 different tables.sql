
----------usp_data_correction Example 5----------------
-- Author	: DCL 30-MAY-2016
/*
   This made up example will replicate from 2 different tables.
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

SET @control_table          = '##rd_xxxxxx'
SET @commit_tran            = 'N'
SET @debug_ind              = 'Y'
  --Backup
SET @control_backup_table   = 'RD_xxxxxx_20160523'
SET @now                    = GetDate()
  --Audit Trail
SET @calltasknum		    = 'xxxxxx'
SET @remediuser_code	    = 'DCL'
SET @script_name		    = 'Replicate 2 tables.'
SET @script_desc		    = 'Replicate 2 tables.'
  --Replication
SET @replication_ind        = 'Y'     

IF OBJECT_ID('tempdb..##rd_xxxxxx') IS NOT NULL
BEGIN
  DROP TABLE ##rd_xxxxxx
END
CREATE TABLE	##rd_xxxxxx (
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

insert into ##rd_xxxxxx 	
select 
	@now	                   as execution_date_time
  , 'image'	                   as table_name             -- i.e. 'sale'
  , 'image' + @calltasknum     as backup_table
  , 'image_code'               as pkey
  , i.image_code               as pkey_value
  , N''                        as insert_set_sql
  , 'U'                        as action_type            -- 'I'(Insert), 'U'(Update), 'D'(Delete)  
  , 'O'                        as replicate_rec_ind	   -- 'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored
  , 'N'                        as replicated_ind
  , ''                         as rep_target             -- This record will only replicate to this location.  
  , 'ToImage'                  as businessobject_name    -- i.e. 'ToSale', 'ToLayby', 'ToUnitLoad'  
  , 'N'                        as transmit_full_ind      -- 'Y'(Replicate the whole BO), 'N'(Just this record)    
from image i (nolock)
where image_code = '00zz3ua10'

insert into ##rd_xxxxxx 
select
	@now	                   as execution_date_time
  , 'itemcolourimage'	       as table_name             -- i.e. 'sale'
  , 'itemcolourimage' + @calltasknum     as  backup_table
  , 'itemcolourimage_id'       as pkey
  , icm.itemcolourimage_id     as pkey_value
  , N''                        as insert_set_sql
  , 'U'                        as action_type        -- 'I'(Insert), 'U'(Update), 'D'(Delete)  
  , 'O'                        as replicate_rec_ind	   -- 'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored
  , 'N'                        as replicated_ind
  , ''                         as rep_target           -- This record will only replicate to this location.
  , 'ToItem'                   as businessobject_name    -- i.e. 'ToSale', 'ToLayby', 'ToUnitLoad'  
  , 'N'                        as transmit_full_ind      -- 'Y'(Replicate the whole BO), 'N'(Just this record)   
from itemcolourimage icm (nolock)
where itemcolourimage_id = '00zz3ua0z'    


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