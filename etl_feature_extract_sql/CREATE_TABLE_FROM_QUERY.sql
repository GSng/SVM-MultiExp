USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[CREATE_TABLE_FROM_QUERY]    Script Date: 03/08/2011 17:45:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[CREATE_TABLE_FROM_QUERY]
	-- Add the parameters for the stored procedure here
	@query VARCHAR(MAX),
	@TableName_Ovr VARCHAR(64),
	@addfields VARCHAR(MAX),
	@IDname VARCHAR(64)

AS	
BEGIN		
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @TableName VARCHAR(32);
	DECLARE @FieldName VARCHAR(128);
	DECLARE @FieldType VARCHAR(32);
	DECLARE @FieldLength VARCHAR(2);
	DECLARE @FieldScale VARCHAR(2);
	
	DECLARE @NullNotNull VARCHAR(128);
	SET @NullNotNull = 'NULL';	
	DECLARE @CreateTableStmt VARCHAR(max);
	SET @CreateTableStmt = '';	
	DECLARE @CurrentTable VARCHAR(50);
	SET @CurrentTable = '';	
		
	SET @query = 'DECLARE MY_CURSOR CURSOR FOR '+@query
	PRINT (@query);
	EXEC(@query);
	
	OPEN MY_CURSOR
	FETCH NEXT FROM MY_CURSOR INTO @TableName, @FieldName, @FieldType, @FieldLength, @FieldScale		
	
	WHILE @@FETCH_STATUS = 0 BEGIN
	
		IF @TableName_Ovr IS NOT NULL SET @TableName=@TableName_Ovr
	
		IF (@TableName<>@CurrentTable OR @@FETCH_STATUS=1) BEGIN		
			
			IF @CreateTableStmt <> '' BEGIN
				SET @CreateTableStmt = @CreateTableStmt+')'
				PRINT(@CreateTableStmt)				
				EXEC(@CreateTableStmt)
			END
			
			SET @CurrentTable = @TableName;
			
			SET @CreateTableStmt = 'CREATE TABLE [dbo].['+@TableName+'] ('
			IF @IDname IS NOT NULL SET @CreateTableStmt = @CreateTableStmt+@IDname+' BIGINT IDENTITY(1,1), '
			IF @addfields IS NOT NULL SET @CreateTableStmt = @CreateTableStmt+@addfields+', '			
			SET @CreateTableStmt = @CreateTableStmt+@FieldName+' '+@FieldType				
			
		END ELSE BEGIN						
			SET @CreateTableStmt = @CreateTableStmt+', '+@FieldName+' '+@FieldType										
		END
		
		IF @FieldLength IS NOT NULL BEGIN
			SET @CreateTableStmt = @CreateTableStmt+'('+@FieldLength
			
			IF @FieldScale IS NOT NULL BEGIN
				SET @CreateTableStmt = @CreateTableStmt+'.'+@FieldScale+')'
			END ELSE BEGIN
				SET @CreateTableStmt = @CreateTableStmt+')'
			END
		END						
		SET @CreateTableStmt = @CreateTableStmt+' '+@NullNotNull			
		
		PRINT(@CreateTableStmt)			
		FETCH NEXT FROM MY_CURSOR INTO @TableName, @FieldName, @FieldType, @FieldLength, @FieldScale
	END	
	
	CLOSE MY_CURSOR
	DEALLOCATE MY_CURSOR
	
	SET @CreateTableStmt = @CreateTableStmt+')'
	PRINT(@CreateTableStmt)				
	EXEC(@CreateTableStmt)	
END
