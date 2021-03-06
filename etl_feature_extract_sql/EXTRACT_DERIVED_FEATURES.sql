USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[EXTRACT_DERIVED_FEATURES]    Script Date: 04/05/2011 15:01:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Zhu-Song Mei>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[EXTRACT_DERIVED_FEATURES]
	-- Add the parameters for the stored procedure here
	@parent_feature_name VARCHAR(255), -- LL_CPT_CHARGE_STD_
	@core_feature VARCHAR(255), --LL_LINE_CHARGE_OCPS
	@breakdown_feature1 VARCHAR(255), --LL_HOSPREV
	@breakdown_feature2 VARCHAR(255), --COVERAGE
	@line_number_column VARCHAR(255), -- LL_LINENUMBER_OCPS
    @source_table_name VARCHAR(255), -- MK_LL_OCPS_LLAGG_CLAIMLEVEL_WLLNO
	@keep_null_or_empty INT,
	@feature_block_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	DECLARE @feature_type VARCHAR(255)
	SET @feature_type = 'continuous'

	DECLARE @feature_level VARCHAR(255)
	SET @feature_level = 'claim'

	DECLARE @query VARCHAR(8000)

	DECLARE @t_source_table_name VARCHAR(255)
	SET @t_source_table_name = 'T_'+@parent_feature_name+'_breakdown'
	
	EXEC('SELECT * INTO ##temp_table2 FROM INFORMATION_SCHEMA.COLUMNS 
		  WHERE TABLE_CATALOG=''rework_wlp'' AND TABLE_NAME = '''+@t_source_table_name+'''')			
	IF NOT EXISTS(SELECT * FROM ##temp_table2) BEGIN
	
		--Add 'padding' column to source table if NOT present
		IF @breakdown_feature2='padding' BEGIN
			EXEC('SELECT * INTO ##temp_table4 FROM INFORMATION_SCHEMA.COLUMNS 
				  WHERE TABLE_NAME = '''+@source_table_name+''' AND  COLUMN_NAME = ''padding''')
			      
			IF NOT EXISTS(SELECT * FROM ##temp_table4) 
				EXEC('ALTER TABLE '+@source_table_name+' ADD padding VARCHAR(1,0)
					  UPDATE '+@source_table_name+' SET padding=''0''')
			
			DROP TABLE ##temp_table4	
		END
		
		--Determine if breakdown fields are text or not, create subquery accordingly		
		DECLARE @where_clause VARCHAR(MAX)
		SET @where_clause = @breakdown_feature1+' IS NOT NULL AND '+@breakdown_feature2+' IS NOT NULL '
		
		DECLARE @rtrim_bdf1 VARCHAR(8)
		SET @rtrim_bdf1 = ''''
		
		DECLARE @rtrim_bdf2 VARCHAR(8) 
		SET @rtrim_bdf2 = ''''
		
			--For Breakdown feature 1
			EXEC('SELECT DATA_TYPE INTO ##temp_table5 FROM INFORMATION_SCHEMA.COLUMNS 
				  WHERE TABLE_NAME = '''+@source_table_name+''' AND  COLUMN_NAME = '''+@breakdown_feature1+'''
				  AND DATA_TYPE IN (''nchar'',''nvarchar'',''ntext'',''char'',''varchar'',''text'')')		  
				
				IF EXISTS(SELECT * FROM ##temp_table5) BEGIN
					SET @where_clause = @where_clause+' AND '+@breakdown_feature1+'<>'''' '
					SET @rtrim_bdf1 = 'RTRIM'
				END 
			
			DROP TABLE ##temp_table5
			
			--For breakdown feature 2
			EXEC('SELECT DATA_TYPE INTO ##temp_table6 FROM INFORMATION_SCHEMA.COLUMNS 
				  WHERE TABLE_NAME = '''+@source_table_name+''' AND  COLUMN_NAME = '''+@breakdown_feature2+'''
				  AND DATA_TYPE IN (''nchar'',''nvarchar'',''ntext'',''char'',''varchar'',''text'')')		  
			
				IF EXISTS(SELECT * FROM ##temp_table6) BEGIN
					SET @where_clause = @where_clause+' AND '+@breakdown_feature2+'<>'''' '
					SET @rtrim_bdf2 = 'RTRIM'
				END 	
			
			DROP TABLE ##temp_table6
		
		--Determine if breakdown is at line_level or claim_level
		EXEC('SELECT * INTO ##temp_table7 FROM INFORMATION_SCHEMA.COLUMNS 
			  WHERE TABLE_NAME = '''+@source_table_name+''' AND  COLUMN_NAME = '''+@line_number_column+'''')		

		--Accordingly calculate the standard deviation of each record
		IF EXISTS(SELECT * FROM ##temp_table7) AND @feature_level='line' BEGIN

			SET @query = 'SELECT CLAIM_ID, '+@line_number_column+',DT2.'+@breakdown_feature1+
				   						',('+@core_feature+'-'+@core_feature+'_AVG)/'+@core_feature+'_STD '+@parent_feature_name+
						 ' INTO '+@t_source_table_name+
						 ' FROM (SELECT '+@breakdown_feature1+','+@breakdown_feature2+',AVG('+@core_feature+') AS '+@core_feature+'_AVG,
										  STDEV('+@core_feature+') '+@core_feature+'_STD 
								 FROM (SELECT DISTINCT CLAIM_ID,'+@line_number_column+','+@core_feature+','+@rtrim_bdf1+'('+@breakdown_feature1+') AS '+@breakdown_feature1+
						   									  ','+@rtrim_bdf1+'('+@breakdown_feature2+') AS '+@breakdown_feature2+' 
									   FROM '+@source_table_name+' WHERE '+@where_clause+')DT 
									   GROUP BY '+@breakdown_feature1+','+@breakdown_feature2+
									  ')DT1
								 JOIN (SELECT DISTINCT CLAIM_ID,'+@line_number_column+','+@core_feature+','+@rtrim_bdf1+'('+@breakdown_feature1+') AS '+@breakdown_feature1+
							   								  ','+@rtrim_bdf1+'('+@breakdown_feature2+') AS '+@breakdown_feature2+' 
									   FROM '+@source_table_name+' WHERE '+@where_clause+')DT2 
								 ON DT1.'+@breakdown_feature1+'=DT2.'+@breakdown_feature1+' AND DT1.'+@breakdown_feature2+'= DT2.'+@breakdown_feature2+'
								 WHERE '+@core_feature+'_STD IS NOT NULL AND '+@core_feature+'_STD<>0'
								 
		END ELSE BEGIN
		
			--calculate the standard deviation of each line
			SET @query = 'SELECT CLAIM_ID, DT2.'+@breakdown_feature1+',
				   				 CASE WHEN '+@core_feature+'_STD=0 THEN 0 
				   					  ELSE (CAST('+@core_feature+' AS DECIMAL(18,5))-'+@core_feature+'_AVG)/'+@core_feature+'_STD END 
				   				 AS '+@parent_feature_name+
						 ' INTO '+@t_source_table_name+
						 ' FROM (SELECT '+@breakdown_feature1+','+@breakdown_feature2+',AVG('+@core_feature+') AS '+@core_feature+'_AVG,
										  STDEV('+@core_feature+') AS '+@core_feature+'_STD 
								 FROM (SELECT DISTINCT CLAIM_ID,'+@core_feature+','+@rtrim_bdf1+'('+@breakdown_feature1+') AS '+@breakdown_feature1+
						   									  ','+@rtrim_bdf1+'('+@breakdown_feature2+') AS '+@breakdown_feature2+' 
									   FROM '+@source_table_name+' WHERE '+@where_clause+')DT 
								 GROUP BY '+@breakdown_feature1+','+@breakdown_feature2+ ')DT1
							JOIN (SELECT DISTINCT CLAIM_ID,'+@rtrim_bdf1+'('+@breakdown_feature1+') AS '+@breakdown_feature1+
							   							 ','+@rtrim_bdf1+'('+@breakdown_feature2+') AS '+@breakdown_feature2+
							   							 ',SUM('+@core_feature+') AS '+@core_feature+'
								  FROM '+@source_table_name+' 
								  WHERE '+@where_clause+'
								  GROUP BY CLAIM_ID,'+@breakdown_feature1+','+@breakdown_feature2+')DT2 
							ON DT1.'+@breakdown_feature1+'=DT2.'+@breakdown_feature1+' AND DT1.'+@breakdown_feature2+'= DT2.'+@breakdown_feature2+'
							WHERE '+@core_feature+'_STD IS NOT NULL AND '+@core_feature+'_STD<>0'
		
		END
		
		DROP TABLE ##temp_table7	
		PRINT(@query)
		EXEC(@query)
		PRINT('')
	END	
	
	DROP TABLE ##temp_table2

	-- create the claim level features
	SET @query = 'dbo.EXTRACT_DEPENDENT_CONTINUOUS_CLAIM_FEATURES '''+@parent_feature_name+ ''','''+@breakdown_feature1+''','''+@t_source_table_name+
														          ''',''FEATURES'',''CLAIM_FEATURES'','+CAST(@feature_block_id AS VARCHAR(9))
	PRINT(@query)
	EXEC(@query)
	PRINT('')

	-- create the line_level features
	IF @feature_level='line' BEGIN
		SET @query = 'dbo.EXTRACT_CONTINUOUS_FEATURES_BY_QUERY '''+@parent_feature_name+''','''+@t_source_table_name+''','
																  +CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(5))+','''
																  +@parent_feature_name+''','+CAST(@feature_block_id AS VARCHAR(9))+',line'
		PRINT(@query)
		--EXEC(@query)
		PRINT('')
	END
	--EXEC('DROP TABLE '+@t_source_table_name)

END
