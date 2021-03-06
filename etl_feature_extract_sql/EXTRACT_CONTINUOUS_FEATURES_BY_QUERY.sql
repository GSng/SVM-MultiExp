USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[EXTRACT_CONTINUOUS_FEATURES_BY_QUERY]    Script Date: 04/05/2011 14:59:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[EXTRACT_CONTINUOUS_FEATURES_BY_QUERY]
	-- Add the parameters for the stored procedure here
	@feature_query VARCHAR(MAX),
    @source_table_name VARCHAR(64),
	@keep_null_or_empty INT,
	@parent_feature_name VARCHAR(64),
	@feature_block_id INT,
	@claim_or_line VARCHAR(5),
	@rebuild INT = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SET @feature_query = '('+@feature_query+')'
	
    -- Insert statements for procedure here
    DECLARE @query VARCHAR(MAX)
    DECLARE @keep_null_or_empty_query VARCHAR(MAX) 
	DECLARE @rebuild_clause VARCHAR(MAX)
        	
	DECLARE @feature_type VARCHAR(255)
	SET @feature_type = 'continuous'

	DECLARE @feature_level VARCHAR(10)
	IF @claim_or_line='CLAIM' SET @feature_level = 'claim'
	IF @claim_or_line='LINE' SET @feature_level = 'line'

	DECLARE @min_query VARCHAR(MAX)
	SET @min_query = '(SELECT MIN('+@feature_query+') FROM '+@source_table_name+')'
	
	DECLARE @max_query VARCHAR(MAX)
	SET @max_query = '(SELECT MAX('+@feature_query+') FROM '+@source_table_name+')'
	
	DECLARE @check_feature_query VARCHAR(MAX)
	SET @check_feature_query = ' name = '''+@parent_feature_name+''' AND feature_type = '''+@feature_type+''' AND parent_feature_id IS NULL AND derived_feature_id IS NULL'
	
	SET @query = 'UPDATE features SET updated_at=GETDATE() WHERE '+@check_feature_query
	PRINT(@query)
	EXEC(@query)
	PRINT('')	
	
	-- insert the feature IF it doesn't exist
	SET @query = 'IF NOT EXISTS(SELECT * FROM features WHERE '+@check_feature_query+ ') 
				   INSERT INTO features(name,feature_type,feature_level,status_cd,created_at,feature_block_id) 
				  VALUES('''+ @parent_feature_name +''','''+@feature_type+''','''+@feature_level+''',''active'', GETDATE(),'+CAST(@feature_block_id AS VARCHAR(4))+')'	
	PRINT(@query)
	EXEC(@query)
	PRINT('')
	
	-- update the min and max
	SET @query = 'UPDATE features SET min_range = '+@min_query + ' WHERE ' +@check_feature_query
	PRINT(@query)
	EXEC(@query)
	PRINT('')
			
	SET @query = 'UPDATE features SET max_range = '+@max_query + ' WHERE ' +@check_feature_query
	PRINT(@query)
	EXEC(@query)
	PRINT('')	
	
	IF @keep_null_or_empty = 1 BEGIN
		SET @keep_null_or_empty_query = ' AND '+@feature_query+' IS NOT NULL'
	END ELSE BEGIN
		SET @keep_null_or_empty_query = ' AND '+@feature_query+' IS NOT NULL AND '+@feature_query+'<>0'
	END

	IF @rebuild = 1 BEGIN
		
		SET @query = 'DELETE FROM claim_features WHERE feature_id = (SELECT feature_id FROM features WHERE '+@check_feature_query+')'
		EXEC(@query)
		PRINT('')
		
		SET @rebuild_clause = 'claims.need_sparse_matrix_update <> -100 ' 
	
	END ELSE BEGIN
		SET @rebuild_clause = 'claims.need_sparse_matrix_update = 1 ' 
	END
	
	IF @feature_level='claim'
	SET @query = 'SELECT DISTINCT claims.claim_id, '+@feature_query+' AS fn1 
				  INTO #temp_claimid_featureval 
				  FROM '+@source_table_name+' JOIN claims ON claims.claim_id = '+@source_table_name+ '.claim_id 
				  WHERE '+@rebuild_clause+' '+@keep_null_or_empty_query+' '+
				  
				 'INSERT INTO claim_features (claim_id, feature_id,line_no, value,created_at) 
				  SELECT DISTINCT claim_id, (SELECT feature_id FROM features WHERE '+@check_feature_query+'),0,fn1,GETDATE() 
				  FROM #temp_claimid_featureval 
				  
				  DROP TABLE #temp_claimid_featureval'
	
	IF @feature_level='line'
	SET @query = 'SELECT DISTINCT claims.claim_id, '+@feature_query+' AS fn1, line_no 
				  INTO #temp_claimid_featureval      
				  FROM '+@source_table_name+' JOIN claims ON claims.claim_id = '+@source_table_name+'.claim_id 
				  WHERE '+@rebuild_clause+' '+@keep_null_or_empty_query+' '+
	
				 'INSERT INTO claim_features (claim_id, feature_id,line_no, value,created_at) 
				  SELECT DISTINCT claim_id, (SELECT feature_id FROM features WHERE '+@check_feature_query+'),line_no,fn1,GETDATE() 
				  FROM #temp_claimid_fetureval 
				  
				  DROP TABLE #temp_claimid_featureval'
	
	PRINT @query
	EXEC(@query)
	PRINT('')

END
