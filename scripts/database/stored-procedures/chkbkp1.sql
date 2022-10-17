col STATUS format a9
col hrs format 999.99
set head off
set feedback off
select SESSION_KEY, INPUT_TYPE, STATUS,
to_char(START_TIME,'mm/dd/yy hh24:mi') start_time,
to_char(END_TIME,'mm/dd/yy hh24:mi') end_time,
round(elapsed_seconds/60, 1) Mins from V$RMAN_BACKUP_JOB_DETAILS
--where SESSION_KEY = ( select max(SESSION_KEY) from V$RMAN_BACKUP_JOB_DETAILS)
;
