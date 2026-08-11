create or replace task TASK_ADC_BULK_ANR
	warehouse=SCA_PRD_DI_ADC_XS_WH
	schedule='USING CRON 0 6,18 * * * EST5EDT'
	as CALL SCA_DEV.XFRM.SP_ADC_BULK_ANR();
