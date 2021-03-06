USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[UPDATE_CLAIM_FEATURES]    Script Date: 04/05/2011 15:01:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- AUTHOR:		Gaurav Singhal
-- CREATE DATE: 201-01-111
-- DESCRIPTION:	UPDATES EXISTING CLAIMS ONLY
-- =============================================
ALTER PROCEDURE [dbo].[UPDATE_CLAIM_FEATURES]
	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
	@etl_run_id INT,
	@new_or_current VARCHAR(7),
	@feature_block_conditions VARCHAR(MAX) = ''
AS
BEGIN
	-- SET NOCOUNT ON ADDED TO PREVENT EXTRA RESULT SETS FROM INTERFERING WITH SELECT STATEMENTS.
	SET NOCOUNT ON;

	DECLARE @source_table VARCHAR(255)
	DECLARE @parent_feature_name VARCHAR(255)
	DECLARE @feature_block_type VARCHAR(255)
	DECLARE @iscontinuous BIT
	DECLARE @feature_level VARCHAR(255)
	DECLARE @core_feature VARCHAR(255)
	DECLARE @breakdown_feature1 VARCHAR(255)
	DECLARE @breakdown_feature2 VARCHAR(255)
	DECLARE @keep_null_or_empty INT
	DECLARE @feature_block_id INT
	DECLARE @aggregate_function VARCHAR(255)
	DECLARE @feature_query VARCHAR(MAX)
	DECLARE @query VARCHAR(MAX)
	
    -- INSERT STATEMENTS FOR PROCEDURE HERE
	
	IF SUBSTRING(@new_or_current,1,1)='c' OR SUBSTRING(@new_or_current,1,1)='C' BEGIN
	
		--Set ALL EXISTING CLAIMS ONLY to need_sparse_matrix_update = 1 in table CLAIMS
		SELECT DISTINCT claim_id INTO #temp_update_new FROM claims WHERE is_new=1
		SELECT DISTINCT claim_id INTO #temp_update_old FROM claims WHERE is_new=0 AND need_sparse_matrix_update=1;
		SELECT DISTINCT claim_id INTO #temp_keep_old   FROM claims WHERE is_new=0 AND need_sparse_matrix_update=0;
		
		UPDATE claims SET need_sparse_matrix_update=0
		UPDATE claims SET need_sparse_matrix_update=1 WHERE claim_id IN (SELECT claim_id FROM #temp_update_old)
		
		--Select ALL currently existing feature_blocks
		SELECT DISTINCT feature_id INTO #temp_ftID FROM claim_features WHERE claim_id IN(SELECT claim_id FROM #temp_update_old)		
		SELECT DISTINCT feature_block_id INTO #temp_current_fblocks FROM features WHERE feature_id IN	
			(SELECT DISTINCT feature_id FROM features WHERE parent_feature_id IS NULL 
				AND feature_id IN (SELECT * FROM #temp_ftID) 
			 UNION 
			 SELECT DISTINCT parent_feature_id FROM features WHERE parent_feature_id IS NOT NULL  
				AND feature_id IN (SELECT * FROM #temp_ftID)
			)
		DROP TABLE #temp_ftID

		--Select outdated feature_ids
		SELECT DISTINCT feature_id INTO #temp_outdated_feat_ids FROM 
			(SELECT DISTINCT feature_id FROM features WHERE parent_feature_id IN
				(SELECT DISTINCT feature_id  FROM feature_blocks JOIN features ON (features.feature_block_id=feature_blocks.id) 
				 WHERE parent_feature_id IS NULL AND feature_blocks.updated_at>features.updated_at)
			 UNION 
				(SELECT DISTINCT feature_id FROM feature_blocks JOIN features ON (features.feature_block_id=feature_blocks.id) 
				 WHERE parent_feature_id IS NULL AND feature_blocks.updated_at>features.updated_at)	 
			)dt

		--Select ALL feature_blocks that either 1)NEW 2)UPDATED 3)Failed Previously
		SELECT DISTINCT id INTO ##temp_fblocks_for_current_claims FROM
			(SELECT DISTINCT id FROM feature_blocks WHERE status_cd='active' 
				EXCEPT(SELECT DISTINCT feature_block_id FROM features) 
			 UNION
			 (SELECT DISTINCT id FROM feature_blocks JOIN features ON (features.feature_block_id=feature_blocks.id) 
				 WHERE parent_feature_id IS NULL AND feature_blocks.updated_at>features.updated_at AND feature_blocks.status_cd = 'active')	
			 UNION 
			 SELECT DISTINCT feature_block_id FROM features WHERE feature_block_id NOT IN 
				(SELECT * FROM #temp_current_fblocks)
			)dt

		--DELETE all claim_features associated with outdated feature_ids AND feature_blocks to be updated
		DELETE FROM claim_features WHERE claim_feature_id IN( 
			SELECT claim_feature_id FROM 
				(SELECT claim_feature_id,claim_id FROM claim_features WHERE feature_id IN( 
					SELECT * FROM #temp_outdated_feat_ids 
					UNION(SELECT feature_id FROM features WHERE feature_block_id IN(SELECT * FROM ##temp_fblocks_for_current_claims))
					UNION(SELECT feature_id FROM features WHERE parent_feature_id IN
						(SELECT feature_id FROM features WHERE feature_block_id IN(SELECT * FROM ##temp_fblocks_for_current_claims)))
				))DT
			WHERE claim_id IN (SELECT * FROM #temp_update_old)
		)
		DROP TABLE #temp_current_fblocks
		DROP TABLE #temp_outdated_feat_ids			
		
		--delete claim_features from claim_features join claims on claims.claim_id = claim_features.claim_id where need_sparse_matrix_update = 1
			
		SET @query  = 'DECLARE my_cursor CURSOR FOR SELECT DISTINCT source_table,db_name,feature_block_type,iscontinuous,feature_level, 
																	core_feature,feature_query,breakdown_feature1,breakdown_feature2,
																	keep_null_or_empty,ID,aggregate_function 
						FROM feature_blocks WHERE id IN (SELECT * FROM ##temp_fblocks_for_current_claims) AND status_cd=''active'''
						+@feature_block_conditions+' ORDER BY feature_blocks.id ASC'
	END ELSE BEGIN
		
		SET @query  = 'DECLARE my_cursor CURSOR FOR SELECT DISTINCT source_table,db_name,feature_block_type,iscontinuous,feature_level, 
																core_feature,feature_query,breakdown_feature1,breakdown_feature2,
																keep_null_or_empty,ID,aggregate_function 
					   FROM feature_blocks WHERE status_cd = ''active'''
				       +@feature_block_conditions+' ORDER BY feature_blocks.id ASC'
	END
							
	PRINT (@QUERY)
	EXEC(@query)
	PRINT('')
	
	OPEN my_cursor
	FETCH NEXT FROM my_cursor 
	INTO @source_table, @parent_feature_name,@feature_block_type,@iscontinuous,@feature_level,@core_feature,@feature_query,
		 @breakdown_feature1,@breakdown_feature2,@keep_null_or_empty,@feature_block_id,@aggregate_function

	WHILE @@FETCH_STATUS = 0 BEGIN
		
		PRINT @core_feature
		
		--Update the ETL status
		IF @ETL_RUN_ID IS NOT NULL BEGIN
			UPDATE etl_runs SET comments = 'Extracting feature: '+@core_feature WHERE ID = @ETL_RUN_ID
		END ELSE BEGIN
			PRINT('Extracting feature: '+@core_feature)
		END
		
		IF (@feature_query IS NULL OR @feature_query='') SET @feature_query = @core_feature
		SET @feature_query = REPLACE(@feature_query,'''','''''')		
				
		IF @feature_block_type = 'SINGLE' BEGIN			
			
			PRINT @feature_block_type
			PRINT @iscontinuous	
		
			IF @iscontinuous = 1 							
				SET @query ='dbo.EXTRACT_CONTINUOUS_FEATURES_BY_QUERY '''+@feature_query+''','+@source_table+','+CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(255))+','
																	     +@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(255))+','+@feature_level
			
			IF @iscontinuous = 0 								
				SET @query ='dbo.EXTRACT_DISCONTINUOUS_FEATURES_BY_QUERY '''+@feature_query+''','+@source_table+','+CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(255))+','
																	        +@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(255))+','+@feature_level			
			
		END ELSE BEGIN			
			
			PRINT @feature_block_type	
				
			IF @feature_block_type = 'WITH_2_BREAKDOWNS' 											
				SET @query = 'DBO.EXTRACT_DERIVED_FEATURES '+@parent_feature_name+','+@core_feature+','+@breakdown_feature1+','+@breakdown_feature2+',LINE_NO,'
														   +@source_table+','+CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(255))+','+CAST(@feature_block_id AS VARCHAR(255))
							
			IF @feature_block_type = 'claim_level_stdev_aggregate'	
				SET @query = 'dbo.EXTRACT_CLAIM_LEVEL_STDEV_AGGREGATE_FEATURES '''+@feature_query+''','+@source_table+','+CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(255))+','
																			   +@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(255))+','+@aggregate_function+',0'				
			
			IF @feature_block_type = 'claim_level_stdev_aggregate_raw'		
				SET @query = 'dbo.EXTRACT_CLAIM_LEVEL_STDEV_AGGREGATE_FEATURES '''+@feature_query+''','+@source_table+','+CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(255))+','
																			   +@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(255))+','+@aggregate_function+',1'							
			
			IF @feature_block_type = 'claim_level_line_stat_summary' 
				SET @query = 'dbo.EXTRACT_CLAIM_LEVEL_LINE_SUMMARY_STAT_FEATURES '''+@feature_query+''','+@source_table+','+CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(255))+','
																		   +@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(255))+','+@aggregate_function+',1'       

			IF @feature_block_type = 'claim_level_error_rate' 
				SET @query = 'dbo.EXTRACT_CLAIM_LEVEL_ERROR_RATE_FEATURES '''+@feature_query+''','+@source_table+','+CAST(ISNULL(@keep_null_or_empty,0) AS VARCHAR(255))+','
																		   +@parent_feature_name+','+CAST(@feature_block_id AS VARCHAR(255))    																		   		

		END 
		
		PRINT(@query)
		EXEC(@query)
		PRINT('')

		FETCH NEXT FROM my_cursor 
		INTO @source_table, @parent_feature_name,@feature_block_type,@iscontinuous,@feature_level,@core_feature,@feature_query,
			 @breakdown_feature1,@breakdown_feature2,@keep_null_or_empty,@feature_block_id,@aggregate_function
			 
	END

	CLOSE my_cursor
	DEALLOCATE my_cursor

	--UPDATE CLAIMS table
	
	UPDATE claims SET updated_at = GETDATE() WHERE need_sparse_matrix_update = 1				
	UPDATE claims SET is_new = 0  WHERE need_sparse_matrix_update = 1	
	UPDATE claims SET need_sparse_matrix_update = 0 WHERE need_sparse_matrix_update = 1
		
	IF SUBSTRING(@new_or_current,1,1)='c' OR SUBSTRING(@new_or_current,1,1)='C' BEGIN
		UPDATE claims SET need_sparse_matrix_update=1 WHERE claim_id IN (SELECT claim_id FROM #temp_update_new)
		UPDATE claims SET need_sparse_matrix_update=0 WHERE claim_id IN (SELECT claim_id FROM #temp_keep_old)	
		
		DROP TABLE #temp_update_new
		DROP TABLE #temp_keep_old
		DROP TABLE #temp_update_old
	END 

	
	--UPDATE FEATURE USE LEVEL
	UPDATE features SET use_level = 'claim_and_line'
	WHERE feature_level = 'line' and feature_type = 'discontinuous'

	UPDATE features SET use_level = 'claim_and_line'
	WHERE feature_level = 'claim' and feature_type = 'discontinuous'

	UPDATE features SET use_level = 'line'
	WHERE feature_level = 'line'  and feature_type = 'continuous'

	UPDATE features SET use_level = 'claim_and_line'
	WHERE feature_level = 'claim'  and feature_type = 'continuous'

END
