USE [rework_wlp]
GO
/****** Object:  StoredProcedure [dbo].[LOAD_RAW_INTO_CLAIM_DETAILS]    Script Date: 03/08/2011 17:48:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[LOAD_RAW_INTO_CLAIM_DETAILS]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
		SET NOCOUNT ON;
		
		IF NOT (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_CATALOG='rework_wlp' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='ETL_claim_details')) 
		BEGIN
			EXEC CREATE_TABLE_FROM_QUERY 'SELECT DISTINCT header_v_line, ACN_field, data_type, data_length, data_scale 
										  FROM ETL_Raw2ACN_Fields JOIN ETL_RawTableDefs ON table_name=raw_table
										  WHERE keep_field<>''N'' AND header_v_line=''ETL_claim_details''',
										 'ETL_claim_details','ln_proc_code VARCHAR(6) NULL,ln_mod_code VARCHAR(2) NULL',null
		END
		
	--Create ln_proc_code & ln_mod_code TEMP Tables
		SELECT DISTINCT CLCL_ID,CDML_SEQ_NO,SUBSTRING(AMSPRD_CLM_LINE.IPCD_ID,1,5) AS ln_proc_code,SUBSTRING(AMSPRD_CLM_LINE.IPCD_ID,6,2) AS ln_mod_code
		INTO #temp_LINE_CODES
		FROM (SELECT raw_claim_id FROM ETL_claims WHERE is_new=1)dt 
		JOIN AMSPRD_CLM_LINE ON (dt.raw_claim_id=AMSPRD_CLM_LINE.CLCL_ID)
 
	--INSERT STUFF INTO Claim Details
		INSERT INTO ETL_claim_details (--prc_CDNP_PRICE,prc_CDNP_RULE,prc_CDNP_SECTION,prc_CDNP_USAGE,
									   --ovr_CDOR_OR_AMT,ovr_CDOR_OR_ID,ovr_CDOR_OR_USID,ovr_EXCD_ID,
									   claim_id,
									   ln_APCD_ID,ln_APSI_STS_IND,ln_CDCB_ADJ_AMT,ln_CDCB_ALLOW_PRI,ln_CDCB_COB_ALLOW,ln_CDCB_COB_AMT,ln_CDCB_COB_APP,ln_CDCB_COB_COINS_AMT,ln_CDCB_COB_DED_AMT,ln_CDCB_COB_DISALLOW,ln_CDCB_COB_OOP,ln_CDCB_COB_REAS_CD,ln_CDCB_COB_SANCTION,ln_CDCB_COB_SAV,ln_CDCB_COB_TYPE,ln_CDCB_COINS_AMT_PRI,ln_CDCB_COPAY_AMT_PRI,ln_CDCB_DED_AMT_PRI,ln_CDCB_PAID_AMT_PRI,ln_CDCB_PRO_RATE_IND,ln_CDCB_SUBTRACT_AMT,ln_CDML_AG_PRICE,ln_amt_alow,ln_CDML_ANES_PHY_STAT,ln_CDML_CAP_IND,ln_amt_charge,ln_pay_in_netwk_flag,claim_diag_2,claim_diag_3,claim_diag_4,claim_diag_5,claim_diag_6,claim_diag_7,claim_diag_8,ln_CDML_COINS_AMT,ln_CDML_CONSIDER_CHG,ln_amt_copay,ln_status,ln_CDML_DED_AMT,ln_CDML_DIS_PA_LIAB,ln_CDML_DISALL_AMT,ln_CDML_DISALL_EXCD,ln_CDML_DISC_AMT,ln_CDML_EOB_EXCD,ln_CDML_EXT_LINE_NO,ln_CDML_FROM_DT,ln_CDML_HCPCS_AMT,ln_mod_code_2,ln_mod_code_3,ln_mod_code_4,ln_CDML_ITS_DISC_AMT,ln_CDML_MU_EDIT_IND,ln_CDML_OOP_CALC_BASE,ln_amt_paid,ln_CDML_PC_IND,ln_CDML_PF_PRICE,ln_CDML_POS_IND,ln_CDML_PR_PYMT_AMT,ln_CDML_PRE_AUTH_IND,ln_CDML_PRE_PAID_AMT,ln_CDML_PRICE_IND,ln_CDML_RISK_WH_AMT,ln_CDML_ROOM_TYPE,ln_CDML_SB_PYMT_AMT,ln_CDML_SE_PRICE,ln_CDML_SEPY_ACCT_CAT,ln_CDML_SEPY_EXP_CAT,line_no,ln_CDML_SUP_DISC_AMT,ln_CDML_TO_DT,ln_CDML_TOT_PA_LIAB,ln_CDML_UMREF_ID,ln_counter,ln_count_alow,raw_claim_id,ln_CRFD_FUND_ID,ln_CRPL_POOL_ID,ln_DEDE_PFX,ln_diag_1,ln_drg,ln_IPCD_ID,ln_LOBD_ID,ln_LTLT_PFX,ln_PDVC_LOBD_PTR,ln_plos,ln_rev_code,ln_SESE_ID,ln_SESE_RULE,
									   ln_proc_code,ln_mod_code
									  )
		SELECT DISTINCT --CDNP_NWX_PRCNG.CDNP_PRICE,CDNP_NWX_PRCNG.CDNP_RULE,CDNP_NWX_PRCNG.CDNP_SECTION,CDNP_NWX_PRCNG.CDNP_USAGE,
						--CMC_CDOR_LI_OVR.CDOR_OR_AMT,CMC_CDOR_LI_OVR.CDOR_OR_ID,CMC_CDOR_LI_OVR.CDOR_OR_USID,CMC_CDOR_LI_OVR.EXCD_ID,
						ETL_claims.claim_id,
						AMSPRD_CLM_LINE.APCD_ID,AMSPRD_CLM_LINE.APSI_STS_IND,AMSPRD_CLM_LINE.CDCB_ADJ_AMT,AMSPRD_CLM_LINE.CDCB_ALLOW_PRI,AMSPRD_CLM_LINE.CDCB_COB_ALLOW,AMSPRD_CLM_LINE.CDCB_COB_AMT,AMSPRD_CLM_LINE.CDCB_COB_APP,AMSPRD_CLM_LINE.CDCB_COB_COINS_AMT,AMSPRD_CLM_LINE.CDCB_COB_DED_AMT,AMSPRD_CLM_LINE.CDCB_COB_DISALLOW,AMSPRD_CLM_LINE.CDCB_COB_OOP,AMSPRD_CLM_LINE.CDCB_COB_REAS_CD,AMSPRD_CLM_LINE.CDCB_COB_SANCTION,AMSPRD_CLM_LINE.CDCB_COB_SAV,AMSPRD_CLM_LINE.CDCB_COB_TYPE,AMSPRD_CLM_LINE.CDCB_COINS_AMT_PRI,AMSPRD_CLM_LINE.CDCB_COPAY_AMT_PRI,AMSPRD_CLM_LINE.CDCB_DED_AMT_PRI,AMSPRD_CLM_LINE.CDCB_PAID_AMT_PRI,AMSPRD_CLM_LINE.CDCB_PRO_RATE_IND,AMSPRD_CLM_LINE.CDCB_SUBTRACT_AMT,AMSPRD_CLM_LINE.CDML_AG_PRICE,AMSPRD_CLM_LINE.CDML_ALLOW,AMSPRD_CLM_LINE.CDML_ANES_PHY_STAT,AMSPRD_CLM_LINE.CDML_CAP_IND,AMSPRD_CLM_LINE.CDML_CHG_AMT,AMSPRD_CLM_LINE.CDML_CL_NTWK_IND,AMSPRD_CLM_LINE.CDML_CLMD_TYPE2,AMSPRD_CLM_LINE.CDML_CLMD_TYPE3,AMSPRD_CLM_LINE.CDML_CLMD_TYPE4,AMSPRD_CLM_LINE.CDML_CLMD_TYPE5,AMSPRD_CLM_LINE.CDML_CLMD_TYPE6,AMSPRD_CLM_LINE.CDML_CLMD_TYPE7,AMSPRD_CLM_LINE.CDML_CLMD_TYPE8,AMSPRD_CLM_LINE.CDML_COINS_AMT,AMSPRD_CLM_LINE.CDML_CONSIDER_CHG,AMSPRD_CLM_LINE.CDML_COPAY_AMT,AMSPRD_CLM_LINE.CDML_CUR_STS,AMSPRD_CLM_LINE.CDML_DED_AMT,AMSPRD_CLM_LINE.CDML_DIS_PA_LIAB,AMSPRD_CLM_LINE.CDML_DISALL_AMT,AMSPRD_CLM_LINE.CDML_DISALL_EXCD,AMSPRD_CLM_LINE.CDML_DISC_AMT,AMSPRD_CLM_LINE.CDML_EOB_EXCD,AMSPRD_CLM_LINE.CDML_EXT_LINE_NO,AMSPRD_CLM_LINE.CDML_FROM_DT,AMSPRD_CLM_LINE.CDML_HCPCS_AMT,AMSPRD_CLM_LINE.CDML_IPCD_MOD2,AMSPRD_CLM_LINE.CDML_IPCD_MOD3,AMSPRD_CLM_LINE.CDML_IPCD_MOD4,AMSPRD_CLM_LINE.CDML_ITS_DISC_AMT,AMSPRD_CLM_LINE.CDML_MU_EDIT_IND,AMSPRD_CLM_LINE.CDML_OOP_CALC_BASE,AMSPRD_CLM_LINE.CDML_PAID_AMT,AMSPRD_CLM_LINE.CDML_PC_IND,AMSPRD_CLM_LINE.CDML_PF_PRICE,AMSPRD_CLM_LINE.CDML_POS_IND,AMSPRD_CLM_LINE.CDML_PR_PYMT_AMT,AMSPRD_CLM_LINE.CDML_PRE_AUTH_IND,AMSPRD_CLM_LINE.CDML_PRE_PAID_AMT,AMSPRD_CLM_LINE.CDML_PRICE_IND,AMSPRD_CLM_LINE.CDML_RISK_WH_AMT,AMSPRD_CLM_LINE.CDML_ROOM_TYPE,AMSPRD_CLM_LINE.CDML_SB_PYMT_AMT,AMSPRD_CLM_LINE.CDML_SE_PRICE,AMSPRD_CLM_LINE.CDML_SEPY_ACCT_CAT,AMSPRD_CLM_LINE.CDML_SEPY_EXP_CAT,AMSPRD_CLM_LINE.CDML_SEQ_NO,AMSPRD_CLM_LINE.CDML_SUP_DISC_AMT,AMSPRD_CLM_LINE.CDML_TO_DT,AMSPRD_CLM_LINE.CDML_TOT_PA_LIAB,AMSPRD_CLM_LINE.CDML_UMREF_ID,AMSPRD_CLM_LINE.CDML_UNITS,AMSPRD_CLM_LINE.CDML_UNITS_ALLOW,AMSPRD_CLM_LINE.CLCL_ID,AMSPRD_CLM_LINE.CRFD_FUND_ID,AMSPRD_CLM_LINE.CRPL_POOL_ID,AMSPRD_CLM_LINE.DEDE_PFX,AMSPRD_CLM_LINE.IDCD_ID,AMSPRD_CLM_LINE.IDCD_ID_REL,AMSPRD_CLM_LINE.IPCD_ID,AMSPRD_CLM_LINE.LOBD_ID,AMSPRD_CLM_LINE.LTLT_PFX,AMSPRD_CLM_LINE.PDVC_LOBD_PTR,AMSPRD_CLM_LINE.PSCD_ID,AMSPRD_CLM_LINE.RCRC_ID,AMSPRD_CLM_LINE.SESE_ID,AMSPRD_CLM_LINE.SESE_RULE,
						#temp_LINE_CODES.ln_proc_code,#temp_LINE_CODES.ln_mod_code
		FROM (SELECT raw_claim_id FROM ETL_claims WHERE is_new=1)dt 
		JOIN AMSPRD_CLM_LINE ON (dt.raw_claim_id=AMSPRD_CLM_LINE.CLCL_ID)
	    JOIN ETL_claims ON (dt.raw_claim_id=AMSPRD_CLM_LINE.CLCL_ID)
	    JOIN #temp_LINE_CODES ON (AMSPRD_CLM_LINE.CLCL_ID=#temp_LINE_CODES.CLCL_ID AND AMSPRD_CLM_LINE.CDML_SEQ_NO=#temp_LINE_CODES.CDML_SEQ_NO)

	--DROP temp table
		DROP TABLE #temp_LINE_CODES
END

	
		--INSERT INTO ETL_claim_details ( --prc_CDNP_PRICE,prc_CDNP_RULE,prc_CDNP_SECTION,prc_CDNP_USAGE,
		--								--ovr_CDOR_OR_AMT,ovr_CDOR_OR_ID,ovr_CDOR_OR_USID,ovr_EXCD_ID,
		--								claim_id,
		--								ln_APCD_ID,ln_APSI_STS_IND,ln_CDCB_ADJ_AMT,ln_CDCB_ALLOW_PRI,ln_CDCB_COB_ALLOW,ln_CDCB_COB_AMT,ln_CDCB_COB_APP,ln_CDCB_COB_COINS_AMT,ln_CDCB_COB_DED_AMT,ln_CDCB_COB_DISALLOW,ln_CDCB_COB_OOP,ln_CDCB_COB_REAS_CD,ln_CDCB_COB_SANCTION,ln_CDCB_COB_SAV,ln_CDCB_COB_TYPE,ln_CDCB_COINS_AMT_PRI,ln_CDCB_COPAY_AMT_PRI,ln_CDCB_DED_AMT_PRI,ln_CDCB_PAID_AMT_PRI,ln_CDCB_PRO_RATE_IND,ln_CDCB_SUBTRACT_AMT,ln_CDML_AG_PRICE,ln_amt_alow,ln_CDML_ANES_PHY_STAT,ln_CDML_CAP_IND,ln_amt_charge,ln_pay_in_netwk_flag,claim_diag_2,claim_diag_3,claim_diag_4,claim_diag_5,claim_diag_6,claim_diag_7,claim_diag_8,ln_CDML_COINS_AMT,ln_CDML_CONSIDER_CHG,ln_amt_copay,ln_status,ln_CDML_DED_AMT,ln_CDML_DIS_PA_LIAB,ln_CDML_DISALL_AMT,ln_CDML_DISALL_EXCD,ln_CDML_DISC_AMT,ln_CDML_EOB_EXCD,ln_CDML_EXT_LINE_NO,ln_CDML_FROM_DT,ln_CDML_HCPCS_AMT,ln_CDML_IPCD_MOD2,ln_CDML_IPCD_MOD3,ln_CDML_IPCD_MOD4,ln_CDML_ITS_DISC_AMT,ln_CDML_MU_EDIT_IND,ln_CDML_OOP_CALC_BASE,ln_amt_paid,ln_CDML_PC_IND,ln_CDML_PF_PRICE,ln_CDML_POS_IND,ln_CDML_PR_PYMT_AMT,ln_CDML_PRE_AUTH_IND,ln_CDML_PRE_PAID_AMT,ln_CDML_PRICE_IND,ln_CDML_RISK_WH_AMT,ln_CDML_ROOM_TYPE,ln_CDML_SB_PYMT_AMT,ln_CDML_SE_PRICE,ln_CDML_SEPY_ACCT_CAT,ln_CDML_SEPY_EXP_CAT,line_no,ln_CDML_SUP_DISC_AMT,ln_CDML_TO_DT,ln_CDML_TOT_PA_LIAB,ln_CDML_UMREF_ID,ln_counter,ln_count_alow,raw_claim_id,ln_CRFD_FUND_ID,ln_CRPL_POOL_ID,ln_DEDE_PFX,ln_diag_1,ln_drg,ln_proc_code,ln_LOBD_ID,ln_LTLT_PFX,ln_PDVC_LOBD_PTR,ln_plos,ln_rev_code,ln_SESE_ID,ln_SESE_RULE
		--							  )
		--SELECT DISTINCT --CDNP_NWX_PRCNG.CDNP_PRICE,CDNP_NWX_PRCNG.CDNP_RULE,CDNP_NWX_PRCNG.CDNP_SECTION,CDNP_NWX_PRCNG.CDNP_USAGE,
		--				--CMC_CDOR_LI_OVR.CDOR_OR_AMT,CMC_CDOR_LI_OVR.CDOR_OR_ID,CMC_CDOR_LI_OVR.CDOR_OR_USID,CMC_CDOR_LI_OVR.EXCD_ID,
		--				ETL_claims.claim_id,
		--				AMSPRD_CLM_LINE.APCD_ID,AMSPRD_CLM_LINE.APSI_STS_IND,AMSPRD_CLM_LINE.CDCB_ADJ_AMT,AMSPRD_CLM_LINE.CDCB_ALLOW_PRI,AMSPRD_CLM_LINE.CDCB_COB_ALLOW,AMSPRD_CLM_LINE.CDCB_COB_AMT,AMSPRD_CLM_LINE.CDCB_COB_APP,AMSPRD_CLM_LINE.CDCB_COB_COINS_AMT,AMSPRD_CLM_LINE.CDCB_COB_DED_AMT,AMSPRD_CLM_LINE.CDCB_COB_DISALLOW,AMSPRD_CLM_LINE.CDCB_COB_OOP,AMSPRD_CLM_LINE.CDCB_COB_REAS_CD,AMSPRD_CLM_LINE.CDCB_COB_SANCTION,AMSPRD_CLM_LINE.CDCB_COB_SAV,AMSPRD_CLM_LINE.CDCB_COB_TYPE,AMSPRD_CLM_LINE.CDCB_COINS_AMT_PRI,AMSPRD_CLM_LINE.CDCB_COPAY_AMT_PRI,AMSPRD_CLM_LINE.CDCB_DED_AMT_PRI,AMSPRD_CLM_LINE.CDCB_PAID_AMT_PRI,AMSPRD_CLM_LINE.CDCB_PRO_RATE_IND,AMSPRD_CLM_LINE.CDCB_SUBTRACT_AMT,AMSPRD_CLM_LINE.CDML_AG_PRICE,AMSPRD_CLM_LINE.CDML_ALLOW,AMSPRD_CLM_LINE.CDML_ANES_PHY_STAT,AMSPRD_CLM_LINE.CDML_CAP_IND,AMSPRD_CLM_LINE.CDML_CHG_AMT,AMSPRD_CLM_LINE.CDML_CL_NTWK_IND,AMSPRD_CLM_LINE.CDML_CLMD_TYPE2,AMSPRD_CLM_LINE.CDML_CLMD_TYPE3,AMSPRD_CLM_LINE.CDML_CLMD_TYPE4,AMSPRD_CLM_LINE.CDML_CLMD_TYPE5,AMSPRD_CLM_LINE.CDML_CLMD_TYPE6,AMSPRD_CLM_LINE.CDML_CLMD_TYPE7,AMSPRD_CLM_LINE.CDML_CLMD_TYPE8,AMSPRD_CLM_LINE.CDML_COINS_AMT,AMSPRD_CLM_LINE.CDML_CONSIDER_CHG,AMSPRD_CLM_LINE.CDML_COPAY_AMT,AMSPRD_CLM_LINE.CDML_CUR_STS,AMSPRD_CLM_LINE.CDML_DED_AMT,AMSPRD_CLM_LINE.CDML_DIS_PA_LIAB,AMSPRD_CLM_LINE.CDML_DISALL_AMT,AMSPRD_CLM_LINE.CDML_DISALL_EXCD,AMSPRD_CLM_LINE.CDML_DISC_AMT,AMSPRD_CLM_LINE.CDML_EOB_EXCD,AMSPRD_CLM_LINE.CDML_EXT_LINE_NO,AMSPRD_CLM_LINE.CDML_FROM_DT,AMSPRD_CLM_LINE.CDML_HCPCS_AMT,AMSPRD_CLM_LINE.CDML_IPCD_MOD2,AMSPRD_CLM_LINE.CDML_IPCD_MOD3,AMSPRD_CLM_LINE.CDML_IPCD_MOD4,AMSPRD_CLM_LINE.CDML_ITS_DISC_AMT,AMSPRD_CLM_LINE.CDML_MU_EDIT_IND,AMSPRD_CLM_LINE.CDML_OOP_CALC_BASE,AMSPRD_CLM_LINE.CDML_PAID_AMT,AMSPRD_CLM_LINE.CDML_PC_IND,AMSPRD_CLM_LINE.CDML_PF_PRICE,AMSPRD_CLM_LINE.CDML_POS_IND,AMSPRD_CLM_LINE.CDML_PR_PYMT_AMT,AMSPRD_CLM_LINE.CDML_PRE_AUTH_IND,AMSPRD_CLM_LINE.CDML_PRE_PAID_AMT,AMSPRD_CLM_LINE.CDML_PRICE_IND,AMSPRD_CLM_LINE.CDML_RISK_WH_AMT,AMSPRD_CLM_LINE.CDML_ROOM_TYPE,AMSPRD_CLM_LINE.CDML_SB_PYMT_AMT,AMSPRD_CLM_LINE.CDML_SE_PRICE,AMSPRD_CLM_LINE.CDML_SEPY_ACCT_CAT,AMSPRD_CLM_LINE.CDML_SEPY_EXP_CAT,AMSPRD_CLM_LINE.CDML_SEQ_NO,AMSPRD_CLM_LINE.CDML_SUP_DISC_AMT,AMSPRD_CLM_LINE.CDML_TO_DT,AMSPRD_CLM_LINE.CDML_TOT_PA_LIAB,AMSPRD_CLM_LINE.CDML_UMREF_ID,AMSPRD_CLM_LINE.CDML_UNITS,AMSPRD_CLM_LINE.CDML_UNITS_ALLOW,AMSPRD_CLM_LINE.CLCL_ID,AMSPRD_CLM_LINE.CRFD_FUND_ID,AMSPRD_CLM_LINE.CRPL_POOL_ID,AMSPRD_CLM_LINE.DEDE_PFX,AMSPRD_CLM_LINE.IDCD_ID,AMSPRD_CLM_LINE.IDCD_ID_REL,AMSPRD_CLM_LINE.IPCD_ID,AMSPRD_CLM_LINE.LOBD_ID,AMSPRD_CLM_LINE.LTLT_PFX,AMSPRD_CLM_LINE.PDVC_LOBD_PTR,AMSPRD_CLM_LINE.PSCD_ID,AMSPRD_CLM_LINE.RCRC_ID,AMSPRD_CLM_LINE.SESE_ID,AMSPRD_CLM_LINE.SESE_RULE
		--FROM (SELECT raw_claim_id FROM ETL_claims WHERE is_new=1)dt 
		--JOIN AMSPRD_CLM_LINE ON (dt.raw_claim_id=AMSPRD_CLM_LINE.CLCL_ID)
		--JOIN ETL_claims ON (ETL_claims.raw_claim_id=AMSPRD_CLM_LINE.CLCL_ID) 