GO
If OBJECT_ID('dbo.usp_is_sql_true') IS NOT NULL
  DROP PROCEDURE dbo.usp_is_sql_true;
GO

CREATE PROCEDURE dbo.usp_is_sql_true 
  @some_sql NVARCHAR(MAX)
AS
BEGIN
  DECLARE @my_result BIT,
        @sql NVARCHAR(MAX);

  SET @sql = N'
  IF ' + @some_sql + '
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