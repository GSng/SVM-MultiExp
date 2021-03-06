USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[LOAD_RAW_INTO_CUSTOM_TABLES]    Script Date: 03/08/2011 17:48:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[LOAD_RAW_INTO_CUSTOM_TABLES]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
		SET NOCOUNT ON;                                                         	 

	--SELECT ALL NEW CLAIMS
		SELECT DISTINCT * INTO #temp_CLMID  FROM ETL_claims WHERE is_new=1 
		
	--Create FLAG for lines where CDNP_PRICE of max_seq_no NOT equal to allowable amount
		SELECT DISTINCT claim_id, line_no, CASE WHEN ROUND(CDNP_PRICE,0)!=ln_amt_alow THEN 1 ELSE 0 END AS FLAG INTO #temp_NWX FROM
			(SELECT DISTINCT dt2.claim_id, line_no, ln_amt_alow, CDNP_PRICE FROM ETL_claim_details JOIN
				(SELECT DISTINCT dt10.* FROM
					(SELECT DISTINCT claim_id,CDNP_LINE_SEQ_NO,MAX(CDNP_SEQ_NO) AS MAX_CDNP_SEQ_NO FROM
						(SELECT DISTINCT claim_id,CDNP_LINE_SEQ_NO,CDNP_SEQ_NO,CDNP_PRICE FROM #temp_CLMID JOIN CDNP_NWX_PRCNG
						 ON #temp_CLMID.raw_claim_id=CDNP_NWX_PRCNG.CLCL_IDck
						)dt0
					 GROUP BY claim_id,CDNP_LINE_SEQ_NO
					)dt1	
				 JOIN 
					(SELECT DISTINCT claim_id,CDNP_LINE_SEQ_NO,CDNP_SEQ_NO,CDNP_PRICE FROM #temp_CLMID JOIN CDNP_NWX_PRCNG
					 ON #temp_CLMID.raw_claim_id=CDNP_NWX_PRCNG.CLCL_IDck
					)dt10
				 ON (dt1.claim_id=dt10.claim_ID AND dt1.CDNP_LINE_SEQ_NO=dt10.CDNP_LINE_SEQ_NO AND dt1.MAX_CDNP_SEQ_NO=dt10.CDNP_SEQ_NO)
				)dt2
			 ON ETL_claim_details.line_no=dt2.CDNP_LINE_SEQ_NO AND ETL_claim_details.claim_id=dt2.claim_id
			)dt3

		--Append above Flag to ETL_claim_details
			IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='ETL_claim_details' AND COLUMN_NAME='ln_CDNP_PRICE_NE_AMT_ALOW_flag')
				ALTER TABLE ETL_claim_details ADD ln_CDNP_PRICE_NE_AMT_ALOW_flag BIT				 
			
			UPDATE ETL_claim_details SET ETL_claim_details.ln_CDNP_PRICE_NE_AMT_ALOW_flag=#temp_NWX.FLAG 
			FROM #temp_NWX JOIN ETL_claim_details ON (ETL_claim_details.claim_id=#temp_NWX.claim_id AND ETL_claim_details.line_no=#temp_NWX.line_no)
													     
	--Insert New Claim Modifier Codes		
		IF NOT (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_CATALOG='rework_wlp' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='ETL_claim_mod_codes')) 
		BEGIN
			CREATE TABLE ETL_claim_mod_codes (claim_id INT NULL,ln_mod_code VARCHAR(2) NULL,updated_at DATETIME NULL)
		END
	
		INSERT INTO ETL_claim_mod_codes (claim_id,ln_mod_code,updated_at) 
			SELECT DISTINCT dt.claim_id,dt.ln_mod_code,GETDATE() FROM
				(SELECT DISTINCT  ETL_claim_details.claim_id,ln_mod_code FROM #temp_CLMID 
								JOIN ETL_claim_details ON (ETL_claim_details.claim_id=#temp_CLMID.claim_id)
					UNION (SELECT DISTINCT ETL_claim_details.claim_id,ln_mod_code_2 FROM #temp_CLMID 
								JOIN ETL_claim_details ON (ETL_claim_details.claim_id=#temp_CLMID.claim_id))
					UNION (SELECT DISTINCT  ETL_claim_details.claim_id,ln_mod_code_3 FROM #temp_CLMID 
								JOIN ETL_claim_details ON (ETL_claim_details.claim_id=#temp_CLMID.claim_id))
					UNION (SELECT DISTINCT  ETL_claim_details.claim_id,ln_mod_code_4 FROM #temp_CLMID 
								JOIN ETL_claim_details ON (ETL_claim_details.claim_id=#temp_CLMID.claim_id))
				)dt
			ORDER BY claim_id
			
	--Status
		IF NOT (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_CATALOG='rework_wlp' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='ETL_claim_sts_codes')) 
		BEGIN
			CREATE TABLE ETL_claim_sts_codes (claim_id INT NULL,sts_code VARCHAR(10) NULL,updated_at DATETIME NULL)
		END
		
		INSERT INTO ETL_claim_sts_codes (claim_id,sts_code,updated_at) 
		SELECT DISTINCT claim_id, CLST_STS, GETDATE()
		FROM #temp_CLMID JOIN CMC_CLST_STATUS ON #temp_CLMID.raw_claim_id=CMC_CLST_STATUS.CLCL_ID
		ORDER BY claim_id
	
	--Pricing
		IF NOT (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_CATALOG='rework_wlp' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='ETL_claim_nwx_rules')) 
		BEGIN
			CREATE TABLE ETL_claim_nwx_rules (claim_id INT NULL,pricing_rule VARCHAR(10) NULL,updated_at DATETIME NULL)
		END
		
		INSERT INTO ETL_claim_nwx_rules (claim_id,pricing_rule,updated_at) 
		SELECT DISTINCT claim_id, CDNP_RULE, GETDATE()
		FROM #temp_CLMID JOIN CDNP_NWX_PRCNG ON #temp_CLMID.raw_claim_id=CDNP_NWX_PRCNG.CLCL_IDck
		ORDER BY claim_id
	
	--Override
		IF NOT (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_CATALOG='rework_wlp' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='ETL_claim_ovr_codes')) 
		BEGIN
			CREATE TABLE ETL_claim_ovr_codes (claim_id INT NULL,ovr_codes VARCHAR(10) NULL,updated_at DATETIME NULL)
		END
		
		INSERT INTO ETL_claim_ovr_codes (claim_id,ovr_codes,updated_at) 
		SELECT DISTINCT claim_id, CDOR_OR_ID+'_'+EXCD_ID, GETDATE()
		FROM #temp_CLMID JOIN CMC_CDOR_LI_OVR ON #temp_CLMID.raw_claim_id=CMC_CDOR_LI_OVR.CLCL_ID
		ORDER BY claim_id
	
	DROP TABLE #temp_CLMID
	DROP TABLE #temp_NWX
	
END
