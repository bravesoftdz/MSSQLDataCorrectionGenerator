GO
If OBJECT_ID('dbo.usp_column_matrix') IS NOT NULL
  DROP PROCEDURE dbo.usp_column_matrix;
GO

CREATE PROCEDURE dbo.usp_column_matrix 
  @table_name VARCHAR(32),
  @column_matrix VARCHAR(255) OUTPUT
AS
BEGIN
    DECLARE @column_count INTEGER;

    -- Number of columns in table
	SELECT @column_count  = COUNT(1) - 1 
	FROM  sys.columns c
	JOIN sys.objects o on c.object_id = o.object_id
	JOIN sys.schemas s on o.schema_id = s.schema_id
	WHERE  o.name = @table_name
	AND s.name = 'dbo'                                                   
 
    SET @column_matrix = 'F' + replicate('1', @column_count) + 'X'
END
GO