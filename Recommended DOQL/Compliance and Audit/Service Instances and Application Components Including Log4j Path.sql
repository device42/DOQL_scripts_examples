/* 0-day query
*/

With
serviceinstance_data as (
Select * From view_serviceinstance_cmdpaths_v2 sicp
Where  position('log4j' IN lower(sicp.cmd_path)) > 0
)
/* Report out */

Select  Distinct vnd.name "Vendor"
	,svc.displayname "Service"
	,svc.pretty_name "Pretty Name"
	,sw.name "Software"
	,siu.version "Version"
	,siu.alias_name "Alias"
	,dev.name "Host" 
	,acp.name "AppComp Name"
	,acp.application_category_name "AppComp Category"
	,acp.last_changed "AppComp Last_Changed" 
	,substring (sid.cmd_path, position('log4j' IN lower(sid.cmd_path))-50,105)
	,sid.cmd_path "Cmd Path"
	From serviceinstance_data sid
       Left Join view_serviceinstance_v2 si ON si.serviceinstance_pk = sid.serviceinstance_fk
	   Left Join view_serviceinstance_appcomp_v2 sia ON sia.serviceinstance_fk = sid.serviceinstance_fk
	   left Join view_appcomp_v1 acp ON acp.appcomp_pk = sia.appcomp_fk
	   Left Join view_device_v2 dev ON dev.device_pk = si.device_fk
	   Left Join view_service_v2 svc ON svc.service_pk = si.service_fk
	   Left Join view_softwareinuse_v1 siu ON siu.softwareinuse_pk = si.softwareinuse_fk
       Left Join view_software_v1 sw ON sw.software_pk = siu.software_fk	   
	   Left Join view_vendor_v1 vnd ON vnd.vendor_pk = svc.vendor_fk
  Order by 1, 2, 3, 4, 5