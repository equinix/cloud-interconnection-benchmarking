alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS';
set linesize 300
set pagesize 150
col mins for a10
col status for a10
col operation for a10
select operation, object_type, status,
round((end_time - start_time) * 24 * 60,2) as Time, start_time, end_time
from v$rman_status
where operation='RESTORE'
and object_type='DATAFILE FULL'
and status in ( 'COMPLETED', 'RUNNING')
order by start_time;
