
----------usp_data_correction Example 4 Part 2----------------
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
  @replication_ind             CHAR(1),        -- 'Y'(Yes), 'N'(No). If 'N', then the following parameters are ignored 
  @rep_batch_limit             INTEGER;
  
SET @control_table          = 'rd_xxxxxx'  --Persistent
SET @commit_tran            = 'N'
SET @debug_ind              = 'Y'
  --Backup
SET @control_backup_table   = ''   --It's already been backed up
SET @now                    = GetDate()
  --Audit Trail
SET @calltasknum		    = 'xxxxxx'
SET @remediuser_code	    = 'DCL'
SET @script_name		    = 'Replicate in batches.'
SET @script_desc		    = 'Replicate in batches.'
  --Replication
SET @replication_ind        = 'P'
SET @rep_batch_limit        = 3    

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
  , @rep_batch_limit

--ROLLBACK TRAN
--COMMIT TRAN 
