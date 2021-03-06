USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[EXTRACT_CLAIM_LEVEL_STDEV_AGGREGATE_FEATURES]    Script Date: 04/05/2011 14:59:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Zhu-Song Mei
-- Create date: 12-15-2009
-- Description:	update the aggregate features for certain fields based on their standard deviations. 
-- =============================================
ALTER PROCEDURE [dbo].[EXTRACT_CLAIM_LEVEL_STDEV_AGGREGATE_FEATURES]
	-- Add the parameters for the stored procedure here
	@core_feature VARCHAR(512),
    @source_table_name VARCHAR(255),
	@keep_null_or_empty INT,
	@parent_feature_name VARCHAR(255),
	@feature_block_id INT,
	@aggregate_function VARCHAR(255),
	@raw_table_flag BIT = 0 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @aggregate_function = ' ' SET @aggregate_function=''
    
	DECLARE @query VARCHAR(8000)
	DECLARE @col_name VARCHAR(255)
	SET @col_name = 
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(
											REPLACE(
												 REPLACE(@core_feature,' ','')
											,'=','')
										,')','')
									,'(','')
								,'.','')
							,'''','')
						,CHAR(13),'')
					,CHAR(9),'')
				,CHAR(10),'')
			,',','')
	
	DECLARE @temp_table VARCHAR(64)
	SET @temp_table = 'temp_'+@col_name+'_std'
	
	DECLARE @aggregate_table_column VARCHAR(256)
	SET @aggregate_table_column = @aggregate_function+'_'+@col_name+'_std'
	
	DECLARE @aggregate_table_name VARCHAR(128)
	SET @aggregate_table_name = 'temp_'+@aggregate_function+'_'+@col_name+'_std'

	SET @query = 'IF (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG=''rework_wlp'' AND TABLE_SCHEMA=''dbo'' 
				  AND TABLE_NAME='''+@temp_table+''')) DROP TABLE '+@temp_table
	EXEC (@query)
	
	EXEC('SELECT * INTO ##temp_table2 FROM INFORMATION_SCHEMA.COLUMNS 
		  WHERE TABLE_CATALOG=''rework_wlp'' AND TABLE_NAME = ''claim_summary_stats'' AND  COLUMN_NAME = '''+@aggregate_table_column+'''')			
	IF EXISTS(SELECT * FROM ##temp_table2) BEGIN
	
		SET @aggregate_table_name = 'claim_summary_stats'
	
	END ELSE BEGIN
	
		IF @raw_table_flag=1 BEGIN
		
			DECLARE @agg_table VARCHAR(128)
			DECLARE @agg_field VARCHAR(128)
			
			SET @query = 'DECLARE my_cursor CURSOR FOR SELECT DISTINCT raw_table FROM ETL_raw2acn_fields 
						  WHERE ACN_field='''+@col_name+''' AND keep_field<>''N'''
			EXEC(@query)
			OPEN my_cursor FETCH NEXT FROM my_cursor INTO @agg_table
			CLOSE my_cursor
			
			SET @query = 'DECLARE my_cursor CURSOR FOR SELECT DISTINCT raw_field FROM ETL_raw2acn_fields 
						  WHERE raw_table='''+@agg_table+''' AND ACN_field='''+@col_name+''' AND keep_field<>''N'''
			EXEC(@query)
			OPEN my_cursor FETCH NEXT FROM my_cursor INTO @agg_field
			CLOSE my_cursor
			
			DEALLOCATE my_cursor		
		END	ELSE BEGIN
			SET @agg_field = @core_feature
			SET @agg_table = @source_table_name
		END
		
		SET @query = 'SELECT DISTINCT claim_id, 
					  ('+@core_feature+'-(SELECT avg('+@agg_field+') FROM '+@agg_table+'))/(SELECT stdev('+@agg_field+') FROM '+@agg_table+') 
					  AS '+@col_name+'_std INTO ##s_'+@col_name+'_std
					  FROM '+@source_table_name
		PRINT (@query)
		EXEC(@query)
		PRINT('')


		SET @query = 'IF (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG=''rework_wlp'' AND TABLE_SCHEMA=''dbo'' 
					  AND TABLE_NAME='''+@aggregate_table_name+''')) DROP TABLE '+@aggregate_table_name
		EXEC (@query)		

		SET @query = 'SELECT * INTO '+ @aggregate_table_name +' FROM(SELECT claim_id, '+@aggregate_function+'('+@col_name+'_std) 
					  AS '+@aggregate_table_column+' 
					  FROM ##s_'+@col_name+'_std GROUP BY claim_id)DT
					  CREATE INDEX temp_claim_id_index ON '+ @aggregate_table_name +'(claim_id)'
		PRINT (@query)
		EXEC(@query)
		PRINT('')
		
		EXEC('DROP TABLE ##s_'+@col_name+'_std')	
	END
	
	DROP TABLE ##temp_table2
	
	SET @aggregate_table_column = @aggregate_table_name+'.'+@aggregate_function+'_'+@col_name+'_std'

	SET @query ='dbo.EXTRACT_CONTINUOUS_FEATURES_BY_QUERY '''+@aggregate_table_column+''', '+@aggregate_table_name+','+CAST(@keep_null_or_empty AS VARCHAR(255))+','
																						 +@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(256))+',claim'		
	PRINT @query
	EXEC (@query)
	PRINT('')

	IF @aggregate_table_name<>'claim_summary_stats'	BEGIN	
		
		IF NOT (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_CATALOG='rework_wlp' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='claim_summary_stats')) 
		BEGIN
			SET @query = 'SELECT * INTO claim_summary_stats FROM '+@aggregate_table_name
			EXEC(@query)
		END ELSE BEGIN
			SET @aggregate_table_column = @aggregate_function+'_'+@col_name+'_std'

			EXEC('SELECT * INTO ##temp_table2 FROM INFORMATION_SCHEMA.COLUMNS 
				  WHERE TABLE_CATALOG=''rework_wlp'' AND TABLE_NAME=''claim_summary_stats'' AND COLUMN_NAME='''+@aggregate_table_column+'''')		
			
			IF NOT EXISTS(SELECT * FROM ##temp_table2)
				EXEC('ALTER TABLE claim_summary_stats ADD '+@aggregate_table_column+' numeric(9,2)')
			
			DROP TABLE ##temp_table2
			
			EXEC('INSERT INTO claim_summary_stats (claim_id) SELECT DISTINCT claim_id FROM '+@aggregate_table_name+
														   ' EXCEPT(SELECT DISTINCT claim_id FROM claim_summary_stats)'
				)
			EXEC('UPDATE claim_summary_stats SET '+@aggregate_table_column+'='+@aggregate_table_name+'.'+@aggregate_table_column+
				 ' FROM '+@aggregate_table_name+' JOIN claim_summary_stats ON (claim_summary_stats.claim_id='+@aggregate_table_name+'.claim_id)'
				)					 
		END
		
		SET @query = 'DROP TABLE '+@aggregate_table_name
		EXEC(@query)
	
	END
END