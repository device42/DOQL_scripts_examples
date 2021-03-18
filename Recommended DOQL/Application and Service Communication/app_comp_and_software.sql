/*
DOQL for App Comp's with related software in use details.
*/
 /*  Inline view of target data required (CTE - Common Table Expression) 
  Get target data       
 */
 With target_select_data  as (
Select
	ac.name "App Comp"
	,ac.application_category_name "App Category"
	,d.name "Device"
	,ip.ip_address "Device IP"
	,s.name "Software Name"
	,si.alias_name "Software Alias"
	,si.version "Version"
	,concat(acws.web_site, '|', acws.pool_name, '|', acws.description, '|', acwb.binding, '|', acwb.protocol) "Web App Details"
	,concat(acwvd.path, '|', acwvd.physical_path) "Web Dir Path"
	,concat(acwdb.name, '|', acwdb.connection, '|', acwdb.provider) "Web DB Connection"
	,adb.name "DB Product Name"
	,adb.version "DB Product Version"
	,adbi.instance "DB Instance"
From view_appcomp_v1 ac
Left Join view_device_v1 d ON d.device_pk = ac.device_fk
Left Join view_ipaddress_v1 ip ON ip.device_fk = d.device_pk
Left Join view_softwareinuse_v1 si ON si.appcomp_fk = ac.appcomp_pk
Left Join view_software_v1 s ON s.software_pk = si.software_fk
Left Join view_appcomp_db_products_v1 adb ON adb.appcomp_fk = ac.appcomp_pk
Left Join view_appcomp_db_data_paths_v1 adbp ON adbp.appcomp_fk = ac.appcomp_pk
Left Join view_appcomp_db_protocols_v1 adpr ON adpr.appcomp_fk = ac.appcomp_pk
Left Join view_appcomp_db_instances_v1 adbi ON adbi.appcomp_fk = ac.appcomp_pk
Left Join view_appcompwebapps_v1 acw ON acw.appcomp_fk = ac.appcomp_pk
Left Join view_appcomp_web_bindings_v1 acwb ON acwb.appcomp_fk = ac.appcomp_pk
Left Join view_appcomp_web_sites_v1 acws ON acws.appcomp_fk = ac.appcomp_pk
Left Join view_appcomp_web_virtual_dir_v1 acwvd ON acwvd.appcompwebapps_fk = acw.appcompwebapps_pk
Left Join view_appcomp_web_sites_db_conn_v1 acwdb ON acwdb.appcompwebapps_fk = acw.appcompwebapps_pk
)
Select Distinct
	tsd."App Comp"
	,tsd."Device"
	,tsd."Device IP"
	,tsd."Software Name"
	,tsd."Software Alias"
	,tsd."Version"
	,Case When tsd."Web App Details" = '||||' Then Null Else tsd."Web App Details" End "Web App Details"
	,Case When tsd."Web Dir Path" = '|' Then Null Else tsd."Web Dir Path" End "Web Dir Path"
	,Case When tsd."Web DB Connection" = '||' Then Null Else tsd."Web DB Connection" End "Web DB Connection"	
	,tsd."DB Product Name"
	,tsd."DB Product Version"
	,tsd."DB Instance"
 From target_select_data tsd	