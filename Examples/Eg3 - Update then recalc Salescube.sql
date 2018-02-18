
----------usp_data_correction Example 3----------------
-- Author	: DCL 30-MAY-2016
/*
   This example will update salelines, then as a consequence, will recalculate the SaleCube summary tables for all affected tradeweeks/stores
   To do this, the script introduces a new global temp table. It must be global(##) rather than local(#), so it can be resolved inside the dynamic sql.
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
SET @control_backup_table   = 'RD_063646_20160523'
SET @now                    = GetDate()
  --Audit Trail
SET @calltasknum		    = 'xxxxxx'
SET @remediuser_code	    = 'DCL'
SET @script_name		    = 'Fix salelines.'
SET @script_desc		    = 'Fix salelines.'
SET @replication_ind        = 'N'

declare @start_date  datetime
declare @end_date    datetime 
set @start_date    = '2015-01-01'
set @end_date      = '2015-02-01'

--Note: Being ordered by retail_chain means dcmtaskcontents will get packed as much as possible
if object_id('tempdb..##tmp_tradeweek') is not null
	drop table dbo.##tmp_tradeweek	
CREATE TABLE ##tmp_tradeweek (
	store_code 		    CHAR(12),
	tradeweek_code		VARCHAR(12),
	processed_ind	    VARCHAR(1)
)
	
IF OBJECT_ID('tempdb..##rd_xxxxxx') IS NOT NULL
BEGIN
  DROP TABLE ##rd_xxxxxx
END	
CREATE TABLE	##rd_xxxxxx (
  execution_date_time DATETIME not null,
  store_code          VARCHAR(12) not null,
  tradeweek_code      VARCHAR(12) not null,
  saleline_type_ind_new CHAR(1) not null,
  table_name 		  VARCHAR(32) not null,
  backup_table        VARCHAR(32) not null,
  pkey                VARCHAR(32) not null,
  pkey_value	      VARCHAR(24) not null,
  insert_set_sql      NVARCHAR(1000) not null,  
  action_type 		  CHAR(1) not null
)

insert into ##rd_xxxxxx	
select	@now	                                    as execution_date_time
        s.store_code, 
       (select tw.tradeweek_code from tradeweek tw with (nolock) 
	      where tw.active_ind = ''Y'' 
	      and s.transaction_date_time between tw.from_date and tw.to_date) as tradeweek_code
	,	'C'	                                        as saleline_type_ind_new
	,   'saleline' + @calltasknum                   as table_name
	,   'saleline' + @calltasknum                   as backup_table
    ,   'saleline_id'                               as pkey
    ,   sl.saleline_id                              as pkey_value		
	't.saleline_type_ind = control.saleline_type_ind_new' as insert_set_sql
	,   'U'                                         as action_type
from	saleline	sl	with (nolock)
join    sale      s   with (nolock) on (s.sale_code = sl.sale_code)
join    itemcoloursize ics with (nolock) on (ics.itemcoloursize_id = sl.itemcoloursize_id) 
join    itemcolour ic with (nolock) on (ic.itemcolour_id = ics.itemcolour_id)
join    item i with (nolock) on (i.item_code = ic.item_code)
where	sl.saleline_type_ind = 'N'
and     s.sale_status_ind = 'A'  --not voided
and     s.transaction_date_time between @start_date and @end_date
and     sl.saleline_status_ind = 'N'  --not voided
and     (sl.backward_xy_pointer is not null) --script attached
and     (sl.backward_xy_pointer <> '') 
and     i.itemtype_ind = 'C'	

insert into
		##tmp_tradeweek
select	DISTINCT
        rd.store_code, 
        rd.tradeweek_code, 
		'N' as processed_ind
from	##rd_063646 rd
order by rd.store_code, rd.tradeweek_code

--Call a stored procedure for each record in ##tmp_tradeweek
--If you introduced a 'processes_ind' into the control table, you could loop through that as well
SET @transaction_sql = N'
	DECLARE 
	  @tradeweek_code   varchar(12),
	  @store_code       varchar(12);
		
	WHILE EXISTS (SELECT TOP 1 1 FROM ##tmp_tradeweek WHERE processed_ind = ''N'')
	BEGIN
		SELECT TOP 1 
		    @tradeweek_code = tmp.tradeweek_code,
            @store_code = tmp.store_code			   
		FROM ##tmp_tradeweek tmp WHERE processed_ind = ''N''
		
		--Call a stored procedure
		exec up_reload_salescube_tables
		@tradeweek_code, 
		@store_code, 
		''Y'', --create backup summary tables
		''N'' --Use original salelinecost records
		
		--update the loop variable
		UPDATE	##tmp_tradeweek SET processed_ind = ''Y'' 
		WHERE  tradeweek_code = @tradeweek_code 
		and    store_code = @store_code
	END	
'	

SET @verification_condition_sql = N'
not exists
	(	select	top 1 1
		from	saleline	sl	(nolock)
		join	' + @control_backup_table + ' t
		on		t.pkey_value = sl.saleline_id
		where	t.execution_date_time = ''' + CONVERT(VARCHAR, @now, 121) + '''
		and		t.saleline_type_ind_new <> sl.saleline_type_ind)
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

--Spot checks  
--SELECT * FROM rd_063646
--SELECT * FROM ##tmp_tradeweek
  
--COMMIT TRAN
