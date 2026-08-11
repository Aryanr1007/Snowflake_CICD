create or replace task TASK_PLM_COLOR
	warehouse=SOURCING_DEV_XS_WH
	schedule='USING CRON 30 7 * * * EST5EDT'
	as BEGIN
  CALL USP_PLM_COLOR();
END;