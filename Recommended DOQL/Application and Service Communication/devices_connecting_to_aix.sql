/*
Get all devices that communicate with AIX
Get all devices that do not communicate with AIX
*/
/* Get all the Devices with not AIX  */
With
  target_device_noaix as (
  /* get non-aix machines pks  */
	Select 
        d.device_pk non_device_pk
        ,d.name dev_name
		,d.type 
		,d.os_name
       From 
            view_device_v2 d
		Left Join view_containerinstance_v1 coi ON coi.device_fk = d.device_pk
		Where d.network_device = 'f' 
			and coi.container_id is Null	/* remove network devices and containers */
			and lower(d.type) Not IN ('cluster','unknown')
			and position('aix' IN lower(d.os_name)) = 0
 ),
  target_device_aix as (
  /* get aix machines pks  */
	Select 
        d.device_pk aix_device_pk
        ,d.name dev_name
		,d.type 
		,d.os_name
       From 
            view_device_v2 d
		Left Join view_containerinstance_v1 coi ON coi.device_fk = d.device_pk
		Where d.network_device = 'f' 
			and coi.container_id is Null	/* remove network devices and containers */
			and lower(d.type) Not IN ('cluster','unknown')
			and position('aix' IN lower(d.os_name)) > 0
 ), 
/* Get all the service communications  */ 
  target_sc_data as (
  /* get service communications */
	Select Distinct
		concat(sc.listener_device_fk,'|',sc.client_device_fk) sc_search_key
        ,sc.listener_device_fk
        ,ld.name ld_name
		,ld.os_name	ld_os_name
		,sc.listener_ip		
		,Case When position('aix' IN lower(ld.os_name)) > 0	Then 'aix' Else '' End ld_os_type
		,sc.client_device_fk		
		,cd.name cd_name 
		,cd.os_name cd_os_name
		,sc.client_ip
		,Case When position('aix' IN lower(cd.os_name)) > 0	Then 'aix' Else '' End cd_os_type		
       From 
            view_servicecommunication_v2 sc
		Left Join view_device_v2 ld ON ld.device_pk = sc.listener_device_fk
		Left Join view_device_v2 cd ON cd.device_pk = sc.client_device_fk
		Where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1'	
			and  (lower(ld.os_name) = 'aix' or lower(cd.os_name) = 'aix') 
			and  (lower(ld.os_name) != lower(cd.os_name))			
 ), 
    target_aix_data  as (
        Select
			tsc.*
			,Case When tsc.ld_os_type = 'aix' Then tsc.client_device_fk Else tsc.listener_device_fk End exclude_pk
			,Case When tsc.ld_os_type = 'aix' Then tsc.listener_device_fk Else tsc.client_device_fk End include_pk			
        From    
            target_sc_data tsc
 ),
	target_classify_data  as (
	Select 
		tdn.non_device_pk "Device ID"
        ,tdn.dev_name "Device name"
		,tdn.type "Device Type"
		,tdn.os_name "Device OS"
		,'Non-AIX Comm' as "Communication"		
		From target_device_noaix tdn
		 Left Join target_aix_data tad ON tad.exclude_pk = tdn.non_device_pk
		 Where tad.exclude_pk is Null
	Union
	Select 
		tdn.non_device_pk "Device ID"
        ,tdn.dev_name "Device name"
		,tdn.type "Device Type"
		,tdn.os_name "Device OS"
		,'AIX Comm' as "Communication"		
		From target_device_noaix tdn
		 Left Join target_aix_data tad ON tad.exclude_pk = tdn.non_device_pk
		 Where tad.exclude_pk is Not Null
 	Union
	Select 
		tda.aix_device_pk "Device ID"
        ,tda.dev_name "Device name"
		,tda.type "Device Type"
		,tda.os_name "Device OS"
		,'AIX-AIX Comm' as "Communication"		
		From target_device_aix tda
		 Left Join target_aix_data tad ON tad.include_pk = tda.aix_device_pk
		 Where tad.include_pk is Null
 )
 /* put out all the data  */
	Select tcd.*
	From target_classify_data tcd
	Order by "Communication" ASC, "Device ID" ASC