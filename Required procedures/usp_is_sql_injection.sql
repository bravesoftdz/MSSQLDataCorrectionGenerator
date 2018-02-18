GO
If OBJECT_ID('dbo.usp_is_sql_injection') IS NOT NULL
  DROP PROCEDURE dbo.usp_is_sql_injection;
GO

CREATE PROCEDURE dbo.usp_is_sql_injection 
  @some_sql NVARCHAR(MAX)
AS
BEGIN
  DECLARE @my_result BIT,
    @sql NVARCHAR(MAX);
			  
  SET @sql = N'
	IF UPPER(''' + @some_sql + N''')  LIKE UPPER(''%0x%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%;%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%--%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%/*%*/%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%EXEC%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%xp_%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%sp_%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%TRUNCATE%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%CREATE%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%ALTER%'')
    OR UPPER(''' + @some_sql + N''')  LIKE UPPER(''%DROP%'')
	   SET @RESULT = 1
	ELSE
	  SET @RESULT = 0';		
	  
    EXEC sp_executesql
      @stmt = @sql,
	  @params = N'@RESULT AS BIT OUTPUT',
	  @RESULT = @my_result OUTPUT;
	  
    RETURN @my_result;
  END
  GO