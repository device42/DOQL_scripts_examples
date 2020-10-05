/*
DOQL for Discovery Scores and Job Scores.
*/
select 
ds.updated "Timestamp",
ds.discovery_type "Discovery Type",
ds.sub_type "Discovery Subtype",
js.vserverdiscovery_fk "Job ID",
vs.job_name "Job Name",
ds.current_mode "Mode",
ds.status "Status",
ds.discovery_server "Target",
ds.port "Target Port",
ds.devicename "Device Name",
ds.supported_os "Supported OS",
ds.device_added "Device Added?",
ds.port_check "Port Check",
ds.username "Username",
ds.authorization "Authorization",
js.is_local_rc "Local RC",
rc.name "Remote Collector",
rc.ip "Remote Collector IP"
from view_discoveryscores_v1 ds
left join view_jobscore_v1 js on js.jobscore_pk = ds.jobscore_fk
left join view_vserverdiscovery_v1 vs on vs.vserverdiscovery_pk = js.vserverdiscovery_fk
left join view_remotecollector_v1 rc on rc.remotecollector_pk = js.remotecollector_fk
order by ds.discoveryscores_pk DESC