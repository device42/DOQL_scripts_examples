/*
Query for all discovered connections to service instances.
  - Update 10/1/2020
  - Add affinity group to listener and client 
  - Add Business Apps to listener and client
  - Add device obj category to listener and client
  - Add App Components to listener and client Service Instance
  - Add Service End User to listener and client Service Instance
  Updated 4/15/21
  - Changed from view_device_v1 to View_device_v2
*/
/* Get all the Device info required for this report once.  */
With 
    target_device_data  as (
        Select
            dev.device_pk
            ,dev.name "Device"
            ,dev.os_name "OS Name"
            ,dev.os_version "OS Version"
            ,dev.os_version_no "OS Version Number"
            ,dev.tags "Device Tags"
            ,oc.name "Object Category"
            ,ag.name "Affinity Group"
            ,ba.name "Business App"       
        From    
            view_device_v2 dev
 /* get Object Category for  for both listener and client  */   
            Left Join view_objectcategory_v1 oc On oc.objectcategory_pk = dev.objectcategory_fk
 /* get affinity Group for both listener and client  */ 
            Left Join view_affinitygroup_v2 ag On ag.primary_device_fk = dev.device_pk
 /* get Business Apps for both listener and client  */  
        Left Join view_businessapplicationelement_v1 bae on bae.device_fk = dev.device_pk
        Left Join view_businessapplication_v1 ba on ba.businessapplication_pk = bae.businessapplication_fk
    )
 /*Pull all the data together for the report  */        
Select Distinct
    ldev."Device" "Listener Device"
    ,ldev."OS Name" "Listener OS"
    ,ldev."OS Version" "Listener OS Version"
    ,ldev."OS Version Number" "Listener OS Version Number"
    ,ldev."Device Tags" "Listener Tag"
    ,ac.name "Listener App Comp"
    ,ldev."Affinity Group" "Listener Affinity Group"
    ,ldev."Business App" "Listener Business App"  /* Can comment out this row if you do not want Business App in Rpt  */
    ,ldev."Object Category" "Listener Object Category"  /* Can comment out this row if you do not want Object Category in Rpt */
    ,sc.listener_ip "Listening IP"
    ,lp.port "Listening Port"
    ,s.displayname "Listening Service"
	,eu.name "Listener Service User"
    ,sc.port "Port Communication"
	,CASE
		WHEN sc.protocol  = '6'
			THEN 'TCP'
		WHEN sc.protocol  = '17'
			THEN 'UDP'
		ELSE ''
	END "Protocol"
    ,scl.displayname "Client Service"
	,euc.name "Client Service User"
    ,acc.name "Client App Comp"	
    ,cdev."Device" "Client Device"
    ,cdev."OS Name" "Client OS"
    ,cdev."OS Version" "Client OS Version"
    ,cdev."OS Version Number" "Client OS Version Number"
    ,cdev."Device Tags" "Client Tag"
    ,cdev."Affinity Group" "Client Affinity Group"   /* Can comment out this row if you do not want Affinity Grp in Rpt  */
    ,cdev."Business App" "Client Business App"   /* Can comment out this row if you do not want Business App in Rpt */
    ,cdev."Object Category" "Client Object Category"    /* Can comment out this row if you do not want Object Category in Rpt  */
    ,sc.client_ip "Client IP"
    ,sc.port "Client Port Communication"
    ,sc.client_process_display_name "Process Display Name"
    ,sc.client_process_name "Process Name"
    ,sc.last_detected "Communication Last Detected"
    ,sc.netstat_active_samples "Netstat # Times Port Actively Connected at Discovery"
    ,sc.netstat_total_samples "Netstat # Times Discovery Checked for Connection"
    ,sc.netstat_total_eports "Netstat Total # Port Connections at Discovery"
    ,sc.netstat_all_first_stat "Netstat Time First Time Port Connected at Discovery"
    ,sc.netstat_all_last_stat "Netstat Last Time Port Connected at Discovery"
From 
        view_servicecommunication_v2 sc
    Join target_device_data ldev On ldev.device_pk = sc.listener_device_fk
    Join view_servicelistenerport_v2 lp On lp.servicelistenerport_pk = sc.servicelistenerport_fk
    Join view_serviceinstance_v2 si On si.serviceinstance_pk = lp.discovered_serviceinstance_fk
    Join view_service_v2 s On s.service_pk = si.service_fk
    Left Join view_serviceinstance_v2 sic On sic.serviceinstance_pk = sc.client_service_fk
    Left Join view_service_v2 scl On scl.service_pk = sic.service_fk
	Left Join view_enduser_v1 euc On euc.enduser_pk = sic.enduser_fk	
	Left Join view_enduser_v1 eu On eu.enduser_pk = si.enduser_fk
    Left Join view_serviceinstance_appcomp_v2 sia on sia.serviceinstance_fk = si.serviceinstance_pk
    Left Join view_appcomp_v1 ac on ac.appcomp_pk = sia.appcomp_fk
    Left Join view_serviceinstance_appcomp_v2 siac on siac.serviceinstance_fk = sic.serviceinstance_pk
    Left Join view_appcomp_v1 acc on acc.appcomp_pk = siac.appcomp_fk	
    Left Join target_device_data cdev On cdev.device_pk = sc.client_device_fk
Where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1' and coalesce(si.topology_status_id,1) <> 3 and coalesce(sic.topology_status_id,1) <> 3