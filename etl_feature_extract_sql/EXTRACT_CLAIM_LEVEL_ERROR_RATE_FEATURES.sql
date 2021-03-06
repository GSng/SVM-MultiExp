USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[EXTRACT_CLAIM_LEVEL_ERROR_RATE_FEATURES]    Script Date: 04/05/2011 14:58:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Zhu-Song Mei
-- Create date: 12-15-2009
-- Description:	update the aggregate features for certain fields based on their standard deviations. 
-- =============================================
ALTER PROCEDURE [dbo].[EXTRACT_CLAIM_LEVEL_ERROR_RATE_FEATURES]
	-- Add the parameters for the stored procedure here
	@core_feature VARCHAR(1024),
    @source_table_name VARCHAR(255),
	@keep_null_or_empty INT,
	@parent_feature_name VARCHAR(255),
	@feature_block_id INT,
	@raw_table_flag BIT = 0 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
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
	SET @col_name = SUBSTRING(@col_name,1,50)

    -- Insert statements for procedure here
    
    DECLARE @aggregate_table_name VARCHAR(128)
	SET @aggregate_table_name = 'TEMP_ERROR_'+@col_name
    DECLARE @aggregate_table_column VARCHAR(256)
	SET @aggregate_table_column = 'ERROR_'+@col_name
    
    SET @query = 'IF (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG=''rework_wlp'' AND TABLE_SCHEMA=''dbo'' 
				  AND TABLE_NAME='''+@aggregate_table_name+''')) DROP TABLE '+@aggregate_table_name
	EXEC (@query)
    
    EXEC('SELECT * INTO ##temp_table2 FROM INFORMATION_SCHEMA.COLUMNS 
		  WHERE TABLE_CATALOG=''rework_wlp'' AND TABLE_NAME = ''claim_summary_stats'' AND  COLUMN_NAME = '''+@aggregate_table_column+'''')			
	IF EXISTS(SELECT * FROM ##temp_table2) BEGIN
        
		SET @aggregate_table_name = 'claim_summary_stats'
    
    END ELSE BEGIN
    
		SET @query = 'SELECT DISTINCT '+@source_table_name+'.'+@col_name+' AS error_calc_field,claim_labels.claim_id,is_rework INTO ##temp_RawErrorTable1
					  FROM claim_labels INNER JOIN '+@source_table_name+' ON ('+@source_table_name+'.claim_id=claim_labels.claim_id) WHERE is_rework IS NOT NULL ORDER BY error_calc_field'
		EXEC(@query)

		SELECT dt1.error_calc_field, WRONG, CNT, CASE WHEN WRONG IS NULL THEN 0 ELSE CAST(WRONG AS NUMERIC(9,2))/CAST(CNT AS NUMERIC(9,2)) END AS ERROR 
		INTO ##temp_RawErrorTable2 FROM
			(SELECT DISTINCT error_calc_field, COUNT(DISTINCT claim_id) AS CNT FROM ##temp_RawErrorTable1 GROUP BY error_calc_field)dt1
		FULL JOIN
			(SELECT DISTINCT error_calc_field, COUNT(DISTINCT claim_id) AS WRONG FROM ##temp_RawErrorTable1 WHERE is_rework=1 GROUP BY error_calc_field)dt2
		ON (dt1.error_calc_field=dt2.error_calc_field)
	
		DROP TABLE ##temp_RawErrorTable1
	
		SET @query = 'SELECT DISTINCT claim_id, MAX(ERROR) AS '+@aggregate_table_column+' INTO '+@aggregate_table_name+'  
					   FROM ##temp_RawErrorTable2 JOIN '+@source_table_name+' ON ##temp_RawErrorTable2.error_calc_field='+@source_table_name+'.'+@col_name+
					 ' GROUP BY claim_id 
					   CREATE INDEX temp_claim_id_index ON '+ @aggregate_table_name +'(claim_id)'
		PRINT (@query)
		EXEC(@query)
		PRINT('')
		
		DROP TABLE ##temp_RawErrorTable2
	END
	
	DROP TABLE ##temp_table2

	SET @query ='dbo.EXTRACT_CONTINUOUS_FEATURES_BY_QUERY '''+@aggregate_table_column+''', '+@aggregate_table_name+','+CAST(@keep_null_or_empty AS VARCHAR(255))+','
																						+@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(256))+',claim'		
	PRINT @query
	EXEC (@query)
	PRINT('')
		
	IF @aggregate_table_name<>'claim_summary_stats' BEGIN
		
		IF NOT (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_CATALOG='rework_wlp' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='claim_summary_stats')) 
		BEGIN
			SET @query = 'SELECT * INTO claim_summary_stats FROM '+@aggregate_table_name
			EXEC(@query)
		END ELSE BEGIN
			SET @aggregate_table_column = 'ERROR_'+@col_name

			EXEC('SELECT * INTO ##temp_table2 FROM INFORMATION_SCHEMA.COLUMNS 
				  WHERE TABLE_NAME = ''claim_summary_stats'' AND  COLUMN_NAME = '''+@aggregate_table_column+'''')		
			
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