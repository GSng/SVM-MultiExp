USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[RUN_ETL]    Script Date: 03/08/2011 17:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Zhu-Song Mei
-- Create date: 11-16-2009
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[RUN_ETL]
	@selectquery VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	-- !!!!!MAKE SURE TO INDEX COLUMNS AND CREATE TABLES PRIOR TO EXECUTION!!!!!
	PRINT('!!!!!MAKE SURE TO INDEX COLUMNS AND CREATE TABLES PRIOR TO EXECUTION!!!!!')
	
	SET NOCOUNT ON;
	DECLARE @etl_run_id INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @labelquery VARCHAR(MAX)
	
	--Insert new ETL run
		INSERT INTO ETL_runs(start_time) VALUES (GETDATE())	
		SET @etl_run_id = (SELECT MAX(id) FROM ETL_runs)
	
	--Insert New Claims ETL Claims table
		PRINT('Finding New Claims')
		UPDATE ETL_runs SET comments = 'ETL START', status_cd = 'Finding New Claims' WHERE id = @etl_run_id			
		
		SET @query = 'INSERT INTO ETL_claims(raw_claim_id,is_new,created_at,needs_featureupdate)
					  SELECT raw_claim_id, 1, GETDATE(), 1 FROM('+@selectquery+' EXCEPT (SELECT raw_claim_id FROM ETL_claims))dt'
		PRINT(@query)
		EXEC(@query)

		UPDATE ETL_runs SET n_new_claims = (SELECT COUNT(*) FROM ETL_claims WHERE is_new = 1) WHERE id=@etl_run_id
		
	--Load Claim Headers
		PRINT('Loading Claim Headers')
		UPDATE ETL_runs SET comments = 'ETL START', status_cd = 'Loading Claim Headers' WHERE id = @etl_run_id
		EXEC dbo.LOAD_RAW_INTO_CLAIM_HEADERS
		
	--Load Claim Details
		PRINT('Loading Claim Details')
		UPDATE ETL_runs SET comments = 'ETL START', status_cd = 'Loading Claim Details' WHERE id = @etl_run_id
		EXEC dbo.LOAD_RAW_INTO_CLAIM_DETAILS
							
	--Update One-Off ETL Tables
		PRINT('Loading One-Off Fields')
		UPDATE ETL_runs SET comments = 'ETL START', status_cd = 'Loading Custom Tables' WHERE id = @etl_run_id
		EXEC dbo.LOAD_RAW_INTO_CUSTOM_TABLES
	
	--Check to see if claims are labeled and signify accordingly
		PRINT('Inserting Claim Labels')
		UPDATE ETL_runs SET comments = 'ETL START', status_cd = 'Inserting Claim Labels' WHERE id = @etl_run_id		
		
		INSERT INTO claim_labels(claim_id,is_rework,is_underpay,is_overpay,created_at,updated_at)
		SELECT DISTINCT claim_id,is_rework,is_rework_underpay_phase1,is_rework_overpay_phase1,GETDATE() AS created_at,GETDATE() AS updated_at 
		FROM (SELECT DISTINCT CLCL_ID FROM
				(SELECT CLCL_ID, COUNT(CLCL_ID) AS CNT FROM
					(SELECT DISTINCT CLCL_ID,is_rework,is_rework_underpay_phase1,is_rework_overpay_phase1
					 FROM MK_final_labels WHERE is_rework IS NOT NULL 
					)dt1
				 GROUP BY CLCL_ID
				)dt2
			  WHERE CNT=1
			 )dt3
		INNER JOIN ETL_claims ON (dt3.CLCL_ID=ETL_claims.raw_claim_id)
		INNER JOIN MK_final_labels ON (dt3.CLCL_ID=MK_final_labels.CLCL_ID)
		WHERE ETL_claims.is_new=1
		
		UPDATE claim_labels SET is_rework=0 WHERE is_rework IS NULL
	
	--Update Claims Table
		INSERT INTO claims(claim_id,raw_claim_no,need_sparse_matrix_update,is_new)
		SELECT claim_id, raw_claim_id, 1, 1 FROM ETL_claims WHERE ETL_claims.is_new=1

	--Update ETL Claims
		UPDATE ETL_claims SET is_new=1 WHERE claim_id IN (SELECT DISTINCT claim_id FROM claims)
		
	--Extract Features		                                                                                    					
		EXEC UPDATE_CLAIM_FEATURES @ETL_RUN_ID,'current'
		EXEC UPDATE_CLAIM_FEATURES @ETL_RUN_ID,'new'
		
	--Update ETL_runs
		UPDATE etl_runs SET comments = 'ETL COMPLETE', 
							END_TIME = GETDATE(), 
							STATUS_CD = 'COMPLETED'				
		WHERE ID = @ETL_RUN_ID
			
END
