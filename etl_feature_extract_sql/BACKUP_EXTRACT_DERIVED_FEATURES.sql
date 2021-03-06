USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[BACKUP_EXTRACT_DERIVED_FEATURES]    Script Date: 03/08/2011 17:44:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Zhu-Song Mei>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[BACKUP_EXTRACT_DERIVED_FEATURES]
	-- Add the parameters for the stored procedure here
	@new_feature_name VARCHAR(255), -- LL_CPT_CHARGE_STD_
	@raw_data_column VARCHAR(255), --LL_LINE_CHARGE_OCPS
	@parent_feature_name VARCHAR(255), --LL_HOSPREV
	@breakdown_column VARCHAR(255), --COVERAGE
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
	SET @t_source_table_name = 'T_'+@new_feature_name+'_SOURCE_TABLE2'

	--calculate the standard deviation of each line

	SET @query = 'SELECT CLAIM_ID, '+@line_number_column+',DT2.'+@parent_feature_name+
				   			    ',('+@raw_data_column+'-'+@raw_data_column+'_AVG)/'+@raw_data_column+'_STD '+@new_feature_name+
				 ' INTO '+@t_source_table_name+
				 ' FROM (SELECT '+@parent_feature_name+','+@breakdown_column+',AVG('+@raw_data_column+') AS '+@raw_data_column+'_AVG,
								  STDEV('+@raw_data_column+') '+@raw_data_column+'_STD 
						 FROM (SELECT DISTINCT CLAIM_ID,'+@line_number_column+','+@raw_data_column+',RTRIM('+@parent_feature_name+') AS '+@parent_feature_name+
						   						      ',RTRIM('+@breakdown_column+') AS '+@breakdown_column+' 
							   FROM '+@source_table_name+' WHERE '+@parent_feature_name+'<>'''' AND '+@breakdown_column+'<>'''' )DT
							   GROUP BY '+@parent_feature_name+','+@breakdown_column+
							  ')DT1
						 JOIN (SELECT DISTINCT CLAIM_ID,'+@line_number_column+','+@raw_data_column+',RTRIM('+@parent_feature_name+') AS '+@parent_feature_name+
							   					      ',RTRIM('+@breakdown_column+') AS '+@breakdown_column+' 
							   FROM '+@source_table_name+' WHERE '+@parent_feature_name+'<>'''' AND '+@breakdown_column+'<>'''' 
							  )DT2
						 ON DT1.'+@parent_feature_name+'=DT2.'+@parent_feature_name+' AND DT1.'+@breakdown_column+'= DT2.'+@breakdown_column+'
						 WHERE '+@raw_data_column+'_STD IS NOT NULL AND '+@raw_data_column+'_STD<>0'

	PRINT(@query)
	EXEC(@query)

	-- create the claim level features
	EXEC('dbo.EXTRACT_DEPENDENT_CONTINUOUS_CLAIM_FEATURES '''+@new_feature_name+ ''','''+@parent_feature_name+''','''+@t_source_table_name+''',''FEATURES'',''CLAIM_FEATURES''')

	-- create the line_level features
	SET @query = 'dbo.EXTRACT_CONTINUOUS_FEATURES_BY_QUERY '''+@t_source_table_name+'.'+@new_feature_name+''','''+@t_source_table_name+''','
															  +CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(5))+','''
															  +@new_feature_name+''','+CAST(@feature_block_id AS VARCHAR(9))+','+@feature_level
	EXEC(@query)
	EXEC('DROP TABLE '+@t_source_table_name)

END
