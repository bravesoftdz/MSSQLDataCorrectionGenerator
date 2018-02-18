-- Author	: DCL     30-MAY-2016 Created with automatic control backup, audit trail and replication.
--            DCL     17-SEP-2016 Removed dynamic custom select SQL parameter. Now the control table is created before calling the stored procedure.
--                                Backup table control field backup multiple tables at once.
--                                Automatic live update/insert/deletes using control table. (Before the transactional statements had to be in @transaction_sql as dynamic)
--            DCL     19-SEP-2016 Out of necessity, introduced replicate_rec_ind = 'O' to replicate without making a DB change.
--                                Introduced @debug_ind
--            DCL        OCT-2016 Completed RDDataCorrectionGenerator.exe

--TODO Make the @now variable internal to the procedure somehow?
--     Include languagetrans/languagetext as a control table field instead of hard coding it to 'N'
--     Create appropriate primary keys and indices on the temp tables


---------NECESSARY CONTROL TABLE FIELDS-----------------

--  execution_date_time       -- i.e. @now = GetDate
--  table_name                -- i.e. 'sale'
--  backup_tablename          -- 'Call_067345'
--  pkey                      -- i.e. 'sale_code'
--  pkey_value                -- i.e. '21045356734'
--  action_type               -- 'I'(Insert), 'U'(Update), 'D'(Delete)
--  insert_set_sql            -- For inserts i.e. '(a,b,c,d) VALUES (1,2,3,4)' 
--                            -- Updates i.e. 'script.status_ind = control.status_ind_new, script.product_ref = NULL'
--	    					  -- For deletes it must be ''
--Replication fields (IF @replication_ind <> 'N')
--  replicate_rec_ind	      -- 'Y'(Yes), 'N'(No). 'O' (Replicate Only, no DB change). If 'N', then the following parameters are ignored
--  replicated_ind            -- 'Y'(Yes), 'N'(No).
--  businessobject_name       -- i.e. 'ToSale', 'ToLayby', 'ToUnitLoad'      	  
--  transmit_full_ind         -- 'Y'(Replicate the whole BO), 'N'(Just from this table)	  
--  rep_target                -- This record will only replicate to this location. NULL/'' means everywhere. 
--                               Use ('^' + retailchain_code) to replicate to all locations in a retail chain. 

GO
If OBJECT_ID('dbo.usp_data_correction', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_data_correction;
GO

CREATE PROCEDURE dbo.usp_data_correction
  @control_table               AS NVARCHAR(64),    -- This can either be the name of a global temp table or a persistent table
  @transaction_sql             AS NVARCHAR(MAX),   -- Additional custom SQL, executed inside the transaction. Optional for rare occasions.
  @verification_condition_sql  AS NVARCHAR(MAX),   -- This SQL goes inside an IF condition before the transaction is committed. It's optional.
  @commit_tran                 CHAR(1),            -- 'Y'(Yes), 'N'(No). If 'N', then you have the opportunity to spot check before committing.
  @debug_ind                   CHAR(1),            -- This will select some intermediate tables used in the calculation. It doesn't stop the transaction.
  --Backup
  @control_backup_table        AS NVARCHAR(64),    -- i.e.'rd_063567_22052016'
  @now                         DATETIME,           -- GetDate()
  --Audit Trail (Writes to errorevent table)
  @calltasknum		           VARCHAR(12),	       -- This is your Call Number or Task Number
  @remediuser_code	           VARCHAR(12),	       -- This will be your ErrorEvent ID (auto-generated)
  @script_name		           VARCHAR(50),	       -- This is the short description of your script.
  @script_desc		           VARCHAR(120),       -- This is the description of your script from SQL Checklist.
  --Replication
  @replication_ind             CHAR(1) = 'N',      -- 'Y'(Yes), 'N'(No), 'P'(Only replicate from a persistent control table created previously without DB changes).   
  @rep_batch_limit             INTEGER = NULL      -- This is the number of records to replicate, for all tables being replicated. NULL means no limit.
  /*
  --Replication Hints: 
  -If replication_ind = 'N', then the replication fields in @control_table aren't necessary. Nothing is replicated.      
  -If you only want to replicate records without changing head office data, use @replication_ind = 'O'
  -If doing a data correction but wanting to replicate later in batches you should be using a persistent control table (otherwise it might not be there later). 
     Use @replication_ind = 'Y'/'N' on the first run, then 'P' on all subsequent runs.
  */  
AS
BEGIN
  SET XACT_ABORT ON --Rollback transaction if there is an unexpected error
  SET NOCOUNT ON
  
  DECLARE 
    @sql                     AS NVARCHAR(MAX),
    @msg                     AS NVARCHAR(500),
    @error_message              VARCHAR(50),
	@sql_result                 BIT,
	@is_temp_table              CHAR(1),
	@object_id_str              AS NVARCHAR(72),
	--Replication
    @task_id 	                VARCHAR(12),	
    @curr_businessobject_name   VARCHAR(32),	               
	@curr_table_name            VARCHAR(32),
	@curr_backup_table          VARCHAR(32),
	@curr_pkey                  VARCHAR(32),
	@curr_pkey_value            VARCHAR(24),
	@curr_action_type           CHAR(1),
	@curr_insert_set_sql        NVARCHAR(4000),
	@curr_column_matrix         VARCHAR(255),
	@curr_transmit_full_ind     CHAR(1),
	@curr_rep_target            VARCHAR(13),
	@dcm_content_count          INTEGER,	
	@last_rep_target            VARCHAR(13), 
	@last_transmit_full_ind     CHAR(1),
	@continue_ind               CHAR(1),
	@MAX_DCM_CONTENTS           INTEGER,
	@rep_counter                INTEGER,
    @dcmcount	                INTEGER,
    @my_repl_count	            INTEGER,	
	@my_not_repl_count          INTEGER,
	@my_error                   INTEGER,
	@last_table_name            VARCHAR(32),
	@last_action_type           CHAR(1);
	
  SET @MAX_DCM_CONTENTS = 198
  
  --Change parameters so we don't have to do this later
  SET @control_table               = ISNULL(@control_table, N'')
  SET @transaction_sql             = ISNULL(@transaction_sql, N'')
  SET @verification_condition_sql  = ISNULL(@verification_condition_sql, N'')
  SET @commit_tran                 = UPPER(ISNULL(@commit_tran, 'N'))
  SET @debug_ind                   = UPPER(ISNULL(@debug_ind, 'N'))
  SET @control_backup_table        = ISNULL(@control_backup_table, N'')
  SET @calltasknum		           = ISNULL(@calltasknum, '')
  SET @remediuser_code	           = ISNULL(@remediuser_code, '')
  SET @script_name		           = ISNULL(@script_name, '')
  SET @script_desc		           = ISNULL(@script_desc, '')
  SET @replication_ind             = UPPER(ISNULL(@replication_ind, 'N')) 
  --These 'last' variables are used when looping through the control table for replication
  SET @last_table_name             = ''
  SET @last_action_type            = '' 
  
  -----------VALIDATION-------------

  --Check if in transaction
  IF @@TRANCOUNT <> 0
  BEGIN
    PRINT 'You cannot use this script while in a transaction. The transaction must be rolled back. No changes made.';
    --ROLLBACK TRAN;
    RETURN;
  END

  -- Check that the required procedures exist
  IF (OBJECT_ID ('usp_post_audit_trail', 'P') IS NULL)
  	OR (OBJECT_ID ('usp_is_sql_true', 'P')    IS NULL)
	OR (OBJECT_ID ('usp_column_matrix', 'P')  IS NULL)  
    OR ((@replication_ind <> 'N') AND 
     ((OBJECT_ID ('up_get_next_dcmtask', 'P')   IS NULL)
	  OR (OBJECT_ID ('up_get_nexttask', 'P')    IS NULL)
	  OR (OBJECT_ID ('usp_column_matrix', 'P')  IS NULL)))
  BEGIN
	PRINT	'The following stored procedures are required to execute this script:'
	PRINT	'	usp_post_audit_trail'
    PRINT	'	usp_is_sql_true'
	--PRINT	'	usp_is_sql_injection'
	IF @replication_ind <> 'N'
	BEGIN
	  PRINT	'	up_get_next_dcmtask'
	  PRINT	'	up_get_nexttask'	
	  PRINT	'	usp_column_matrix'
    END	
	PRINT	'Create these stored procedures and run this script again.'
	PRINT	'No changes made to database'
	RETURN
  END

  --The @control_table can either be a global temp table (##) or a persistent table ()
  IF LEFT(@control_table, 2) = '##'
  BEGIN
    SET @is_temp_table = 'Y'
	SET @object_id_str = 'tempdb..' + @control_table
  END
  ELSE IF LEFT(@control_table, 1) = '#'
  BEGIN
    PRINT  'The @control_table parameter cannot be a temporary table. ' +
	       'It must either be a persistent or global temporary table. No changes made.'
	RETURN;
  END  
  ELSE
  BEGIN  
    SET @is_temp_table = 'N'	
	SET @object_id_str = @control_table	
  END  

  --Check for missing input
  IF (@replication_ind = 'P')
    AND   ((@control_table                = '')
	    OR (@control_backup_table         <> '')
		OR (@rep_batch_limit            IS NULL)
		OR (@rep_batch_limit               < 1))
  BEGIN
    PRINT  'Incorrect parameters used when replicating from a persistent control table. No changes made.';
	RETURN;  
  END  
  ELSE IF (@replication_ind <> 'P')
       AND ((@control_table       = '')  
       OR (@control_backup_table  = ''))
  BEGIN
    PRINT  'Missing input parameters: '
	  + CASE WHEN (@control_table           = '')      THEN '@control_table;' END
      + CASE WHEN (@control_backup_table        = '')  THEN '@control_backup_table;' END
      + ' No changes made.';
    RETURN;
  END

  --Check @control_backup_table isn't the same as @control_table
  IF (@control_backup_table <> '') AND (@control_backup_table = @control_table)
  BEGIN
    PRINT  '@control_backup_table cannot have the same name as @control_table. No changes made.'
    RETURN;
  END
  
/*  	  
  --Check for sql injection
  EXEC @sql_result = dbo.usp_is_sql_injection @control_table
  IF  @sql_result = 1
  BEGIN
    PRINT  'Possible SQL injection attempt in @control_table. No changes made.';
    RETURN;
  END  
  
  EXEC @sql_result = dbo.usp_is_sql_injection @control_backup_table
  IF  @sql_result = 1
  BEGIN
    PRINT  'Possible SQL injection attempt in @control_backup_table. No changes made.';
    RETURN;
  END
  
  EXEC @sql_result = dbo.usp_is_sql_injection @transaction_sql
  IF  @sql_result = 1
  BEGIN
    PRINT  'Possible SQL injection attempt in @transaction_sql. No changes made.';
    RETURN;
  END
  
  EXEC @sql_result = dbo.usp_is_sql_injection @verification_condition_sql
  IF  @sql_result = 1
  BEGIN
    PRINT  'Possible SQL injection attempt in @verification_condition_sql. No changes made.';
    RETURN;
  END
*/	    

  --Check if @control_table exists
  IF (OBJECT_ID(@object_id_str) IS NULL)
  BEGIN
    PRINT  @control_table + ' has not been created. No changes made.';
    RETURN;
  END  

  --Check to make sure @control_backup_table doesn't exist, unless replicating from a persistent control table
  IF (@replication_ind  <> 'P') AND (OBJECT_ID(@control_backup_table) IS NOT NULL)
  BEGIN
    PRINT  @control_backup_table + ' already exists. No changes made.';
    RETURN;
  END   
  
  --Check if @control_table has records  
  SET @sql = 'NOT EXISTS (SELECT TOP 1 1 FROM ' + @control_table + ')';  
  EXEC @sql_result = dbo.usp_is_sql_true @sql
  IF @sql_result = 1 
  BEGIN
    PRINT  @control_table + ' is empty. No changes made.';
    RETURN;
  END	  

  --Validate field names of control table  
  
  IF OBJECT_ID('tempdb..#tmp_control_fieldnames') IS NOT NULL
  BEGIN
    DROP TABLE #tmp_control_fieldnames 
  END
  
  SELECT name 
  INTO #tmp_control_fieldnames FROM tempdb.sys.columns 
  WHERE OBJECT_ID = OBJECT_ID(@object_id_str);

  IF   (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'execution_date_time'))
    OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'table_name'))
    OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'pkey'))
    OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'pkey_value'))
    OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'action_type'))
    OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'insert_set_sql'))
    OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'backup_table'))
  BEGIN
    PRINT  'Missing field names in @control_table. Required: '
      + 'execution_date_time,'
      + 'table_name,'	
      + 'pkey,'	 
      + 'pkey_value,'	 
      + 'action_type,'	 
      + 'insert_set_sql,'
	  + 'backup_table.'	  
      + ' No changes made.';	  
    RETURN;
  END

  IF (@replication_ind  <> 'N')
  BEGIN
    IF   (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'replicate_rec_ind'))
      OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'replicated_ind'))
      OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'businessobject_name'))
      OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'transmit_full_ind'))
      OR (NOT EXISTS (SELECT TOP 1 1 FROM #tmp_control_fieldnames WHERE name = 'rep_target'))
    BEGIN
      PRINT  'Missing field names in @control_table. Required: '
        + 'replicate_rec_ind,'
        + 'replicated_ind,'	
        + 'businessobject_name,'	 
        + 'transmit_full_ind,'	 	 
        + 'rep_target.' 
        + ' No changes made.';	  
      RETURN;
	END  
  END
  
  DROP TABLE #tmp_control_fieldnames

  --Validate control table field values when needed
  
  --These fields should never be empty/null
  SET @sql = N'EXISTS (SELECT TOP 1 1 FROM ' + @control_table + 
             N' WHERE COALESCE(table_name, '''') = ''''' +
			 N' OR COALESCE(pkey, '''') = ''''' +
			 N' OR COALESCE(pkey_value, '''') = ''''' +
			 N' OR COALESCE(action_type, '''') not in (''U'', ''I'', ''D'')' +
			 N' OR COALESCE(backup_table, '''') = ''''' +
			 N' OR insert_set_sql IS NULL' +
			 N')'  
  EXEC @sql_result = dbo.usp_is_sql_true @sql
  IF @sql_result = 1 
  BEGIN
    PRINT  'Empty, null (or incorrect action_type) fields in @control_table: '
      + 'table_name,'
      + 'pkey,'	
      + 'pkey_value,'	 
      + 'action_type,'	 
      + 'backup_table,'
      + '(insert_set_sql cannot be null).'	  
      + ' No changes made.';	  
    RETURN;  
  END

  
  IF (@replication_ind  <> 'N')  --Replicating
  BEGIN
    --Basic validation on replication fields
    SET @sql = N'EXISTS (SELECT TOP 1 1 FROM ' + @control_table + 
               N' WHERE COALESCE(replicate_rec_ind, '''') not in (''Y'', ''N'', ''O'')' +
			   N' OR COALESCE(replicated_ind, '''') not in (''Y'', ''N'')' +
			   N' OR COALESCE(businessobject_name, '''') = ''''' +
			   N' OR COALESCE(transmit_full_ind, '''') not in (''Y'', ''N'')' +
	  		   N')'  
    EXEC @sql_result = dbo.usp_is_sql_true @sql
    IF @sql_result = 1 
    BEGIN
      PRINT  'Empty or null fields in @control_table: '
        + 'replicate_rec_ind,'
        + 'replicated_ind,'	
        + 'businessobject_name,'	 
        + 'transmit_full_ind,'		
        + ' No changes made.';	  
      RETURN;  
    END
	
	--Replication only doesn't need insert_set_sql. In this case, insert_set_sql will be ignored but it suggests the user doesn't know what they're doing
    SET @sql = N'EXISTS (SELECT TOP 1 1 FROM ' + @control_table + 
               N' WHERE replicate_rec_ind = ''O''' +
	  		   N' AND insert_set_sql <> ''''' +
	  		   N')'  
    EXEC @sql_result = dbo.usp_is_sql_true @sql
    IF @sql_result = 1 
    BEGIN
      PRINT  'The @control_table contains non-empty insert_set_sql for records that replicate only: '
        + ' No changes made.';	  
      RETURN;  
    END		
  END;

  --Any deletion should have insert_set_sql = ''. Also, any insert/update should have non-empty insert_set_sql, unless replicating only 
  SET @sql = N'EXISTS (SELECT TOP 1 1 FROM ' + @control_table + 
             N' WHERE (action_type = ''D'' AND insert_set_sql <> '''')' +
			 N' OR    (action_type <> ''D'' AND insert_set_sql = ''''';
			 
  IF (@replication_ind  <> 'N')
  BEGIN
    SET @sql = @sql + N' AND replicate_rec_ind <> ''O''))'
  END
  ELSE
  BEGIN
    SET @sql = @sql +  N'))'
  END	
  
  EXEC @sql_result = dbo.usp_is_sql_true @sql
  IF @sql_result = 1 
  BEGIN
    PRINT  'The @control_table either: '
      + 'Contains action_type = D with non-empty insert_set_sql   OR'
      + 'Contains action_type <> D with empty insert_set_sql.' 
      + ' No changes made.';	  
    RETURN;  
  END
   
  ------------END VALIDATION-------------------------

  -- Audit trail
  EXECUTE	usp_post_audit_trail 
	1,
	@calltasknum,
	@script_name,
	@script_desc,
	null,
	@remediuser_code

  EXECUTE usp_post_audit_trail 
	2,
	@calltasknum,
	@script_name,
	'Temp Tables.',
	'Create and populate temp tables.',
	@remediuser_code  

  IF @replication_ind <> 'P'
  BEGIN  
    --Global temp table used for grouping tables to backup	
    IF OBJECT_ID('tempdb..##tmp_backup_tables') IS NOT NULL
    BEGIN
      DROP TABLE ##tmp_backup_tables 
    END

    --Global temp table used for grouping update/delete/insert sql statements	
    IF OBJECT_ID('tempdb..##tmp_sql_statements') IS NOT NULL
    BEGIN
      DROP TABLE ##tmp_sql_statements 
    END

	-- The backup tables are split up by table_name and backup_table. 
	-- This means the user can select different parts of the same table into different backup tables.
	
	--Note: For inserts into a particular table, the insert_set_sql should be unique. Therefore, each insert statement will execute independently
	--      For updates on a particular table, they are only split up if the SET statement is different i.e. insert_set_sql
	--      For deletes on a particular table, they are never split up because insert_set_sql = ''
	--      Don't include records in ##tmp_sql_statements if replicate_rec_ind = 'O' (Replicate Only)
	
	--Is SELECT DISTINCT expensive, should I be using GROUP BY?
    SET @sql = N'
      SELECT DISTINCT rd.table_name, rd.backup_table, rd.pkey, ''N'' as processed_ind
      INTO ##tmp_backup_tables FROM ' + @control_table + N' rd' + 
	  
      N' SELECT DISTINCT rd.table_name, rd.pkey, rd.action_type, rd.insert_set_sql, ''N'' as processed_ind
      INTO ##tmp_sql_statements FROM ' + @control_table + N' rd';
    IF @replication_ind <> 'N'
    BEGIN
      --We don't want to transact on a record the user has chosen to replicate only	
	  SET @sql = @sql + N' WHERE rd.replicate_rec_ind <> ''O'''
    END
    EXEC sp_executesql
      @stmt = @sql
	  	  
  END	
  
  --Note: The replication from the control table doesn't care about execution_date_time. 
  --      This means if there are already records in the control_table from an earlier time that haven't replicated yet,
  --      they will be replicated this time around.
  --      This kind of thing could happen if somebody doesn't purposefully drop the control table when they should.
  IF @replication_ind <> 'N'
  BEGIN   
    ---------DECLARE REPLICATION TEMP TABLES---------------
    IF OBJECT_ID('tempdb..#tmp_dcmtask') IS NOT NULL
    BEGIN
	  DROP TABLE #tmp_dcmtask 
    END
    CREATE TABLE	#tmp_dcmtask (
	  task_id 		        CHAR(9) not null,
	  businessobject_name 	VARCHAR(32) null,
	  status_ind 		    CHAR(1) null,
	  language_ind 		    CHAR(1) null,
	  language_code 		VARCHAR(12) null,
	  transmit_full_ind 	CHAR(1) null,
	  created_date_time 	DATETIME null,
	  primary key clustered (task_id)
    )

    IF OBJECT_ID('tempdb..#tmp_dcmtaskcontents') IS NOT NULL
    BEGIN
	  DROP TABLE #tmp_dcmtaskcontents 
    END
    CREATE TABLE	#tmp_dcmtaskcontents (
	  task_id 		    CHAR(9) not null,
	  table_name 		VARCHAR(32) not null,
	  primary_key_value	VARCHAR(24) not null,
	  action_ind 		CHAR(1) not null,
	  column_matrix 	VARCHAR(255) null,
	  transmit_full_ind	CHAR(1) null,
	  primary key clustered (task_id, table_name, primary_key_value, action_ind)
    )

    IF OBJECT_ID('tempdb..#tmp_dcmtasktarget') IS NOT NULL
    BEGIN
	  DROP TABLE #tmp_dcmtasktarget 
    END
    CREATE TABLE	#tmp_dcmtasktarget (
	  task_id 		        CHAR(9) not null,
	  target_location_code 	VARCHAR(12) not null,
	  primary key clustered (task_id, target_location_code)
    )

    ---------POPULATE TASK IDs---------------------
	SET @dcm_content_count      = 0
	SET @last_transmit_full_ind = ''
	SET @last_rep_target        = ''
	SET @rep_counter            = 0;

	--Determine whether to loop
    SET @sql = N'EXISTS (SELECT TOP 1 1 FROM ' + @control_table + ' WHERE replicated_ind = ''N'' AND replicate_rec_ind <> ''N'')';  
    EXEC @sql_result = dbo.usp_is_sql_true @sql
    IF @sql_result = 1 
	  SET @continue_ind = 'Y' 
	ELSE 
	  SET @continue_ind = 'N'
	
	--Are there any records left to replicate or have we passed the limit?
    WHILE (@continue_ind = 'Y') AND ((@rep_batch_limit IS NULL) OR (@rep_counter < @rep_batch_limit))
    BEGIN
	  SET @sql = N' 
        SELECT TOP 1 @businessobject_name   = businessobject_name,	               
	                 @table_name            = table_name,
				     @pkey_value            = pkey_value,
				     @action_type           = action_type,
				     @transmit_full_ind     = transmit_full_ind,
				     @rep_target            = rep_target
	    FROM ' + @control_table + '
	    WHERE replicated_ind = ''N'' AND replicate_rec_ind <> ''N'' 
		ORDER BY rep_target, businessobject_name, table_name, action_type 
      '			  
      EXEC sp_executesql
      @stmt = @sql,
      @params = N'
	    @businessobject_name AS VARCHAR(32)  OUTPUT,
		@table_name          AS VARCHAR(32)  OUTPUT,
		@pkey_value          AS VARCHAR(24)  OUTPUT,
		@action_type         AS CHAR(1)      OUTPUT,
		@transmit_full_ind   AS CHAR(1)      OUTPUT,
		@rep_target          AS VARCHAR(13)  OUTPUT',
      @businessobject_name = @curr_businessobject_name OUTPUT,	
	  @table_name          = @curr_table_name OUTPUT,
	  @pkey_value          = @curr_pkey_value OUTPUT,
	  @action_type         = @curr_action_type OUTPUT,
      @transmit_full_ind   = @curr_transmit_full_ind OUTPUT,
	  @rep_target          = @curr_rep_target OUTPUT;

	  --TODO: Validate these variables are not empty. If they are, explain then Abort_Script
	  
	  --Recalculate the column matrix only if we have to
	  IF (@last_table_name <> @curr_table_name) OR (@last_action_type <> @curr_action_type)
	  BEGIN
	    IF @curr_action_type = 'D'
		BEGIN
		   SET  @curr_column_matrix = 'FX'
		END
		ELSE
		BEGIN
		   EXEC dbo.usp_column_matrix @curr_table_name, @column_matrix = @curr_column_matrix OUTPUT
		END   
		
	    SET  @last_table_name  = @curr_table_name
		SET  @last_action_type = @curr_action_type
	  END
	  
	  --As long as rep_target/transmit_full_ind doesn't change, we can keep packing the records into dcmtaskcontents for the same task
	  --until we get to 197
	  IF (@dcm_content_count = @MAX_DCM_CONTENTS) OR 
		((ISNULL(@curr_transmit_full_ind, '') <> @last_transmit_full_ind)) OR
		((ISNULL(@curr_rep_target, '')        <> @last_rep_target))
      BEGIN
        SET @dcm_content_count      = 0
		SET @last_transmit_full_ind = ISNULL(@curr_transmit_full_ind, '')
		SET @last_rep_target        = ISNULL(@curr_rep_target, '')
		  
	    --Get next available task id
	    EXEC up_get_next_dcmtask @new_dcm_task_id = @task_id OUTPUT

	    --Create the DCMTask entry
	    INSERT	#tmp_dcmtask
	    (
		   task_id,
		   businessobject_name,
		   status_ind,
		   language_ind,
		   transmit_full_ind,
		   created_date_time
	    )
	    VALUES	(
		   @task_id,
		   @curr_businessobject_name,
		   --Should these 2 be @control_table field names as well??
		   'C', --Created
		   'N', --TO DO: languagetrans/languagetext tables field in control table
		   @curr_transmit_full_ind,
		   GetDate()
		)					 
      END		 

	  --Create the DCMTaskContents entries
	  INSERT	#tmp_dcmtaskcontents
	  (
		task_id,
		table_name,
		primary_key_value,
		action_ind,
		column_matrix,
		transmit_full_ind
	  )
	  SELECT	
	    @task_id,
		@curr_table_name,
		@curr_pkey_value,
		@curr_action_type,
		@curr_column_matrix,
		@curr_transmit_full_ind       				
			
	  --Create the DCMTaskTarget entries for store specific replication
      --Only set the target if the dcmtask is new
      IF (@dcm_content_count = 0) AND (ISNULL(@curr_rep_target, '') <> '')
      BEGIN	  
	    INSERT	#tmp_dcmtasktarget
	    (
		  task_id,
		  target_location_code
	    )
	    SELECT  
		  @task_id,
		  @curr_rep_target
	  END

      SET @dcm_content_count = @dcm_content_count + 1;
      SET @rep_counter       = @rep_counter + 1;
	  
	  --Update the loop variable
	  SET @sql = N'
	    UPDATE	' + @control_table + ' SET replicated_ind = ''Y''
	    WHERE     pkey_value = ''' + @curr_pkey_value + '''
	    AND       table_name = ''' + @curr_table_name + '''
		AND       rep_target = ''' + @curr_rep_target + '''
		AND       replicate_rec_ind <> ''N'' AND replicated_ind = ''N'''
      EXEC sp_executesql
        @stmt = @sql
	  
	  --Determine whether to loop again
      SET @sql = N'
	  EXISTS (SELECT TOP 1 1 FROM ' + @control_table + ' WHERE replicated_ind = ''N'' AND replicate_rec_ind <> ''N'')
	  '	  
      EXEC @sql_result = dbo.usp_is_sql_true @sql
      IF @sql_result = 1 
	    SET @continue_ind = 'Y' 
	  ELSE 
	    SET @continue_ind = 'N'
  
    END

	--Check we have replicated the number of records we intended to.
    SELECT	@dcmcount = count(1)
    FROM	#tmp_dcmtaskcontents
	
	IF @rep_batch_limit IS NOT NULL --If replicating in batches
	BEGIN
	  --We've gone over the limit
	  IF @dcmcount > @rep_batch_limit
      BEGIN
        PRINT  'Error in processing - too many records were replicated. No changes made.';
        RETURN;  
      END 
	  
	  --How many records left to replicate?
	  SET @sql = N' 
        SELECT	@not_repl_count = count(1)
        FROM	' + @control_table + '
        WHERE	replicated_ind = ''N'' and replicate_rec_ind <> ''N''
      '			  
      EXEC sp_executesql
        @stmt = @sql,
        @params = N'
	      @not_repl_count AS INTEGER  OUTPUT',
        @not_repl_count = @my_not_repl_count OUTPUT;	 
	  
	  --We haven't reached the batch limit and there are still records to replicate
      IF (@dcmcount < @rep_batch_limit) AND (@my_not_repl_count > 0) 
      BEGIN
        PRINT  'Error in processing - not all dcmtasks were created. No changes made.';
        RETURN;  
      END
    END  		  
    ELSE --Not replicating in batches
	BEGIN
	  SET @sql = N' 
        SELECT	@repl_count = count(1)
        FROM	' + @control_table + '
        WHERE	replicated_ind = ''Y'' and replicate_rec_ind <> ''N''
      '			  
      EXEC sp_executesql
        @stmt = @sql,
        @params = N'
	      @repl_count AS INTEGER  OUTPUT',
        @repl_count = @my_repl_count OUTPUT;
	
	  IF @dcmcount <> @my_repl_count 
      BEGIN
        PRINT  'Error in processing - not all dcmtasks were created. No changes made.';
        RETURN;  
      END		
	END
  END

  -- Debugging
  IF @debug_ind = 'Y'
  BEGIN   
    SELECT * FROM ##tmp_sql_statements
	PRINT 'SELECT * FROM ##tmp_sql_statements'
    SELECT * FROM ##tmp_backup_tables
	PRINT 'SELECT * FROM ##tmp_backup_tables'
    IF @replication_ind <> 'N'
    BEGIN 
      SELECT * FROM #tmp_dcmtask
	  PRINT 'SELECT * FROM #tmp_dcmtask'
      SELECT * FROM #tmp_dcmtaskcontents
	  PRINT 'SELECT * FROM #tmp_dcmtaskcontents'
      SELECT * FROM #tmp_dcmtasktarget
	  PRINT 'SELECT * FROM #tmp_dcmtasktarget'
    END
  END  
  
  -- Audit Trail
  execute usp_post_audit_trail 
    3,
	@calltasknum,
	@script_name,
	'DB Tran.',
	'Open DB Transaction.',
	@remediuser_code	


  --------- START TRANSACTION ---------------  
  BEGIN TRAN

  IF @replication_ind <> 'P'
  BEGIN  
    --Create a backup table of the control table inside the transaction
    SET @sql = 	N'
      IF OBJECT_ID(''' + @control_backup_table + ''') IS NULL
      BEGIN
		SELECT	*
		INTO	' + @control_backup_table + '
		FROM    ' + @control_table + ' 
		WHERE	1 = 2
	  END' 
    EXEC sp_executesql
      @stmt = @sql
  
    --Populate backup control table
    SET @sql = N'
      INSERT INTO ' + @control_backup_table + '
      SELECT	*
      FROM	' + @control_table + ' tmp
	  WHERE	tmp.execution_date_time = ''' + CONVERT(VARCHAR, @now, 121) + '''
	
	  SET @error = @@error 
	  '
    EXEC sp_executesql
      @stmt = @sql,
      @params = N'
	    @error AS INTEGER  OUTPUT',
      @error = @my_error OUTPUT;
	  
    IF @my_error <> 0 
    BEGIN
	  SET @error_message = 'Failed to backup the control table.'
	  GOTO Abort_Script
    END	

    IF @debug_ind = 'Y'
    BEGIN
        SET @sql = N'SELECT * FROM ' + @control_backup_table
        EXEC sp_executesql
          @stmt = @sql
    END	
	
	----------BACKUP TABLES FROM CONTROL TABLE----------------	  
	--Cycle through tmp_backup_tables to back up all relevant tables
    WHILE EXISTS (SELECT TOP 1 1 FROM ##tmp_backup_tables WHERE processed_ind = 'N')
	BEGIN
      SELECT TOP 1 @curr_table_name      = table_name,
				   @curr_backup_table    = backup_table,
				   @curr_pkey            = pkey
	  FROM ##tmp_backup_tables
	  WHERE processed_ind = 'N'

      --Create a backup table of @curr_table_name called @curr_backup_table if it doesn't exist already
      SET @sql = 	N'
        IF OBJECT_ID(''' + @curr_backup_table + ''') IS NULL
        BEGIN
		  SELECT	*
		  INTO	' + @curr_backup_table + '
		  FROM    ' + @curr_table_name + ' 
		  WHERE	1 = 2
	    END' 
      EXEC sp_executesql
        @stmt = @sql
	  
	  --Insert into @curr_backup_table from @curr_table_name using a join to the control table 
	  SET @sql = N'
	  INSERT INTO ' + @curr_backup_table + N'
	  SELECT	t.*
	  FROM ' + @curr_table_name + N' t
	  JOIN ' + @control_table + N' control 
	  ON (t.' + @curr_pkey + N' = control.pkey_value) 
	  WHERE control.table_name = ''' + @curr_table_name + N'''
	  AND   control.backup_table = ''' + @curr_backup_table + N'''
	  AND	control.execution_date_time = ''' + CONVERT(VARCHAR, @now, 121) + '''
	  
	  SET @error = @@error 
	  '	  
      EXEC sp_executesql
        @stmt = @sql,
        @params = N'
	    @error AS INTEGER  OUTPUT',
        @error = @my_error OUTPUT;
	  
      IF @my_error <> 0 
      BEGIN
	    SET @error_message = 'Failed to backup ' + @curr_table_name + ' records.'
	    GOTO Abort_Script
      END
	
      IF @debug_ind = 'Y'
      BEGIN
        SET @sql = N'SELECT * FROM ' + @curr_backup_table
		PRINT 'SELECT * FROM ' + @curr_backup_table
        EXEC sp_executesql
          @stmt = @sql
      END	
	
	  --Update the loop variable
	  UPDATE	##tmp_backup_tables SET processed_ind = 'Y'
	  WHERE     table_name = @curr_table_name
      AND       backup_table = @curr_backup_table
	  AND       pkey = @curr_pkey
    END
	
    ----------TRANSACT FROM CONTROL TABLE-----------------------	
	--Cycle through ##tmp_sql_statements to either execute an update/delete/insert statement
    WHILE EXISTS (SELECT TOP 1 1 FROM ##tmp_sql_statements WHERE processed_ind = 'N')
	BEGIN
      SELECT TOP 1 @curr_table_name      = table_name,
	               @curr_pkey            = pkey,
				   @curr_action_type     = action_type,
				   @curr_insert_set_sql  = insert_set_sql
	  FROM ##tmp_sql_statements
	  WHERE processed_ind = 'N'
	  
	  --Below, when an update/insert/delete is made, it joins by primary key to the relevant records in @control_backup_table
	  
	  --One thing to note is that the backup of the tables above depends on @curr_backup_table,
	  --but there's no reason to split up the transactional statements for rows that have 
	  --different @curr_backup_table
	  
	  IF @curr_action_type = 'U' -------------UPDATES---------------------
	  BEGIN
        SET @sql = N'
          UPDATE t SET ' + @curr_insert_set_sql + N'
		  FROM ' + @curr_table_name + N' t' + 
		  N' INNER JOIN ' + @control_backup_table + N' control ON (t.' + @curr_pkey + N' = control.pkey_value)
		  WHERE control.table_name = ''' + @curr_table_name + N'''
		  AND   control.action_type = ''U''
		  AND   control.insert_set_sql = ''' + @curr_insert_set_sql + N'''
		  AND	control.execution_date_time = ''' + CONVERT(VARCHAR, @now, 121) + '''
	
	      SET @error = @@error 
	      '
        EXEC sp_executesql
          @stmt = @sql,
          @params = N'
	      @error AS INTEGER  OUTPUT',
          @error = @my_error OUTPUT;
	  
        IF @my_error <> 0 
        BEGIN
	      SET @error_message = 'Failed to update ' + @curr_table_name + ': ' + @curr_insert_set_sql
	      GOTO Abort_Script
        END	  
	  END
	  ELSE IF @curr_action_type = 'D' -------------DELETES---------------------
	  BEGIN
        SET @sql = N'
          DELETE t FROM ' + @curr_table_name + N' t 
		  INNER JOIN ' + @control_backup_table + N' control ON (t.' + @curr_pkey + N' = control.pkey_value)
		  WHERE control.table_name = ''' + @curr_table_name + N'''
	      AND   control.action_type = ''D''
		  AND	control.execution_date_time = ''' + CONVERT(VARCHAR, @now, 121) + '''
		  
	      SET @error = @@error 
	      '
        EXEC sp_executesql
          @stmt = @sql,
          @params = N'
	      @error AS INTEGER  OUTPUT',
          @error = @my_error OUTPUT;
	  
        IF @my_error <> 0 
        BEGIN
	      SET @error_message = 'Failed to delete from ' + @curr_table_name
	      GOTO Abort_Script
        END	  
	  END
	  ELSE IF @curr_action_type = 'I' -------------INSERTS---------------------
	  BEGIN
        SET @sql = N'
		  INSERT INTO ' + @curr_table_name + N' ' + @curr_insert_set_sql + N'
		  
	      SET @error = @@error 
	      '
        EXEC sp_executesql
          @stmt = @sql,
          @params = N'
	      @error AS INTEGER  OUTPUT',
          @error = @my_error OUTPUT;
	  
        IF @my_error <> 0 
        BEGIN
	      SET @error_message = 'Failed to insert record into ' + @curr_table_name + '; ' + @curr_insert_set_sql
	      GOTO Abort_Script
        END		  
	  END     
		
	  --Update the loop variable
	  UPDATE	##tmp_sql_statements SET processed_ind = 'Y'
	  WHERE     table_name     = @curr_table_name
      AND 	    pkey           = @curr_pkey
	  AND       action_type    = @curr_action_type
	  AND       insert_set_sql = @curr_insert_set_sql  
    END 
	
	
    ----------CUSTOM @transaction_sql-------------------------
    IF @transaction_sql <> ''
    BEGIN	  	  
      SET @transaction_sql = @transaction_sql + N' 	
	    SET @error     = @@error'
  
      EXEC sp_executesql
        @stmt = @transaction_sql,
        @params = N'
	      @error     AS INTEGER  OUTPUT',
        @error     = @my_error OUTPUT;
	
      IF @my_error <> 0 
      BEGIN
	    SET @error_message = 'Failed to execute @transaction_sql.'
	    GOTO Abort_Script
      END	  
    END -- @transaction_sql <> ''
  END -- @replication_ind <> 'P' 
  
  ----------------LIVE REPLICATION---------------------
  IF @replication_ind <> 'N'
  BEGIN
    --Insert dcmtask records
	INSERT	dcmtask
    SELECT	*
    FROM	#tmp_dcmtask

	IF @@error <> 0
	BEGIN
	  SET @error_message = 'Failed to insert dcmtask records.'
      GOTO Abort_Script
	END
	
	--Insert dcmtaskcontent records	
	INSERT	dcmtaskcontents
    SELECT	*
    FROM	#tmp_dcmtaskcontents

	IF @@error <> 0
	BEGIN
	  SET @error_message = 'Failed to insert dcmtaskcontents records.'
      GOTO Abort_Script
	END
        
    --Insert dcmtasktarget records
    INSERT	dcmtasktarget
    SELECT	*
    FROM	#tmp_dcmtasktarget

	IF @@error <> 0
	BEGIN
	  SET @error_message = 'Failed to insert dcmtasktarget records.'
      GOTO Abort_Script
	END		  		  
	
  END --@replication_ind <> 'N'	

  SET @sql = @verification_condition_sql
  IF @sql <> ''
    EXEC @sql_result = dbo.usp_is_sql_true @sql
	  
  IF (@sql = '') or (@sql_result = 1)
  BEGIN
    IF @commit_tran = 'Y'
      COMMIT TRAN
  
    PRINT 	'Data Correction completed.'
	--Print out number of records replicated
	IF @replication_ind <> 'N'
	  PRINT CONVERT(VARCHAR(12), @rep_counter) + ' records will be replicated.'
	  
	EXECUTE usp_post_audit_trail 
		99,
		@calltasknum,
		@script_name,
		'DB Tran.',
		'Commit. Data Correction completed',
		@remediuser_code
	
    SET XACT_ABORT OFF
	
	RETURN
  END
  ELSE
  BEGIN	
	SET @error_message = 'Failed verification.';
	GOTO Abort_Script;	  
  END

  Abort_Script:
	IF @@trancount > 0
		ROLLBACK TRAN
	
	PRINT	@error_message + ' Data correction will not be proceeded with and any changes rolled back.'	
	SET     @error_message = 'Rollback. ' + @error_message;

	EXECUTE usp_post_audit_trail 
		99,
		@calltasknum,
		@script_name,
		'DB Tran Rolled back',
		@error_message,
		@remediuser_code
		
	SET XACT_ABORT OFF
	
	RETURN

END	
  --Don't drop the replication tables, they can be reviewed

