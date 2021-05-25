/* Discovery Jobs Status Report       -   11/26/2019                     
   Updates:
 

*/
 /*  Inline view of target data required (CTE - Common Table Expression)  */
 With target_records  as (
 Select DISTINCT
    js.jobscore_pk "Job Score ID",
	coalesce(
		vserverdiscovery.vserverdiscovery_pk
	) "Job ID",
    js.discovery_type_name "Discovery Type",
    coalesce(
		vserverdiscovery.job_name
	) "Job Name",
    js.is_local_rc "Local RC",
    vserverdiscovery.discovery_target "Discovery Target",
	coalesce(
		vserverdiscovery.port
	) "Target Port",
	js.basic_servers "Devices in Scope",
	js.remotecollector_fk "Remote Collector ID",
	rc.name "Remote Collector Name",
	rc.ip "Remote Collector IP",
	rc.version "Remote Collector SW Version",
	js.basic_runstart "Job Start Time",
	js.detailed_runend "Job End Time" 
   From view_jobscore_v1 js
   Join view_vserverdiscovery_v1 vserverdiscovery ON vserverdiscovery.vserverdiscovery_pk = js.vserverdiscovery_fk
   Left Join view_remotecollector_v1 rc ON rc.remotecollector_pk = js.remotecollector_fk
   ),
 
 /*  Inline view of Discovery Score data normalization required (CTE - Common Table Expression) 11/22/19 */
 ds_norm_records  as (
 Select 
    ds.jobscore_fk,
    Case WHEN lower(ds.sub_type) in('nix', 'free bsd','solaris', 'hp ux')
         THEN 'Linux'
         ELSE ds.sub_type
    END  "Discovery Subtype",
	ds.sub_type,
	CASE When ds.port_check = 't'
	     Then 't'
	     Else NULL
    END "NORM PC",		 
	CASE When ds.authorization = 't'
	     Then 't'
	     Else NULL
    END "NORM AC",
	CASE When ds.supported_os = 't'
	     Then 't'
	     Else NULL
    END "NORM OC",
	CASE When ds.object_added = 't'
	     Then 't'
	     Else NULL
    END "NORM OA",
	CASE When ds.status in ('partial','ok')
	     Then 't'
	     Else NULL
    END "NORM ST"		
   From view_discoveryscores_v1 ds 
   ) 
 
  /* Actual join of target_records and normalized discovery data  */	
  /* Jobs Status Report                            */
  Select Distinct
    tr."Job Score ID",
	tr."Job ID",
    tr."Discovery Type",
    dsn."Discovery Subtype",
    tr."Job Name",
    tr."Local RC",
    tr."Discovery Target",
	tr."Target Port",
  /* counting # of rows that have values in them for each col below.   */
   (count(dsn."NORM PC") over (Partition BY tr."Job Score ID")) "Port Check Success",  
   (count(dsn."NORM AC") over (Partition BY tr."Job Score ID")) "Auth Success",
   (count(dsn."NORM OC") over (Partition BY tr."Job Score ID")) "Supported OS",
   (count(dsn."NORM OA") over (Partition BY tr."Job Score ID")) "Devices Added",
   (count(dsn."NORM ST") over (Partition BY tr."Job Score ID")) "Discovered Devices",
	tr."Devices in Scope",	
	tr."Remote Collector ID",
	tr."Remote Collector Name",
	tr."Remote Collector IP",
	tr."Remote Collector SW Version",
	tr."Job Start Time",
	tr."Job End Time" 
  From target_records tr
  Left Join ds_norm_records dsn ON tr."Job Score ID" = dsn.jobscore_fk
  Order by  tr."Job Score ID" DESC