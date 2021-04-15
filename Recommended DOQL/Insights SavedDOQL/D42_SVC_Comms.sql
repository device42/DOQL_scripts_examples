/*
Query for all discovered connections to service instances.
  - Update 9/16/2020
  - Add affinity group to the client as well as the listener
  - Add Business Apps to listener and client
  - Add device obj category to listener and client
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2  
*/
/* Get all the Device info required for this report once.  */
With 
    target_device_data  as (
        Select
            dev.device_pk
            ,dev.name "Device"
            ,oc.name "Object Category"
            ,ag.name "Affinity Group"
            ,ba.name "Business App"       
        From    
            view_device_v2 dev
 /* get Object Category for  for both listener and client  */   
        Left Join view_objectcategory_v1 oc ON oc.objectcategory_pk = dev.objectcategory_fk
 /* get affinity Group for both listener and client  */ 
        Left Join view_affinitygroup_v2 ag ON ag.primary_device_fk = dev.device_pk
 /* get Business Apps for both listener and client  */  
        Left Join view_businessapplicationelement_v1 bae ON bae.device_fk = dev.device_pk
        Left Join view_businessapplication_v1 ba ON ba.businessapplication_pk = bae.businessapplication_fk
    )
 /*Pull all the data together for the report  */        
Select
    ldev."Device" "Listener Device"
    ,ldev."Affinity Group" "Listener Affinity Group"
    ,ldev."Business App" "Listener Business App"  /* Can comment out this row if you do not want Business App in Rpt  */
    ,ldev."Object Category" "Listener Object Category"  /* Can comment out this row if you do not want Object Category in Rpt */
    ,sc.listener_ip "Listening IP"
    ,lp.port "Listening Port"
    ,s.displayname "Listening Service"
    ,sc.port "Port Communication"
    ,sc.protocol "Protocol"
    ,cdev."Device" "Client Device"
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
    Join target_device_data ldev ON ldev.device_pk = sc.listener_device_fk
    Join view_servicelistenerport_v2 lp ON lp.servicelistenerport_pk = sc.servicelistenerport_fk
    Join view_serviceinstance_v2 si ON si.serviceinstance_pk = lp.discovered_serviceinstance_fk
    Join view_service_v2 s ON s.service_pk = si.service_fk
    Left Join target_device_data cdev ON cdev.device_pk = sc.client_device_fk
Where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1'