/* Get report to Support Impact List 
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
*/
/* Inline view of  Target service and Device data  - Filters down to just the records needed   
        Change xxxxx or xxxxy to the device id of the focused host before running          */
With 
    src as (
       Select Distinct
            dev.device_pk
            ,dev.name
       From view_device_v2 as dev
         Where dev.device_pk IN ('365') /* specify device pk - Can put as many entries as long as each one is put in single quotes and separated by a comma  */
    ),	 
     target_host as (
       Select Distinct		   
            dev.device_pk device_id
            ,'Host' typed
            ,dev.name host
            ,NULL app_comm
            ,NULL service
            ,NULL client_host
            ,NULL::int listener_port                           
       From src, view_device_v2 as dev
        Where dev.device_pk = src.device_pk  
    ),
     target_appcomp as (
       Select Distinct
		      ac.device_fk device_id
            ,'AppComp' typed
            ,NULL host
            ,ac.name app_comm
            ,NULL service
            ,NULL client_host
            ,NULL::int listener_port                           
       From src, view_appcomp_v1 as ac
        Where ac.device_fk = src.device_pk 
    ),
	 target_find_device_comms as (
       Select Distinct	 
            sc.listener_device_fk device_id
            ,'SVC_COMM' typed
            ,NULL host
            ,NULL app_comm
            ,s.displayname service
            ,cd.name client_host
            ,sc.port listener_port                          
       From src, view_servicecommunication_v2 as sc
		 Left Join view_device_v2 ld ON ld.device_pk = sc.listener_device_fk
		 Left Join view_device_v2 cd ON cd.device_pk = sc.client_device_fk
		 Left Join view_servicelistenerport_v2 lp ON lp.servicelistenerport_pk = sc.servicelistenerport_fk
       Left Join view_serviceinstance_v2 si ON si.serviceinstance_pk = lp.discovered_serviceinstance_fk
       Left Join view_service_v2 s ON s.service_pk = si.service_fk		 
        Where sc.listener_device_fk = src.device_pk and cd.name != '' 
    ),
     target_find_device_services as (
        Select Distinct
            dev.device_pk device_id
            ,'SVCS' typed
            ,NULL host
            ,NULL app_comm
            ,s2.displayname service
            ,NULL client_host
            ,NULL::int listener_port                                
       From src , view_device_v2 as dev
       Left Join view_serviceinstance_v2 dsi ON dsi.device_fk = dev.device_pk
       Left Join view_service_v2 s2 ON s2.service_pk = dsi.service_fk
        Where dev.device_pk = src.device_pk 
    ), 
     My_Result as 
      (Select Distinct
        target_host.*
        From target_host
      UNION
       Select Distinct
        target_appcomp.*
        From target_appcomp
      UNION   
       Select Distinct
        target_find_device_comms.*
        From target_find_device_comms
      UNION   
       Select Distinct
        target_find_device_services.*
        From target_find_device_services
	)
	 Select * From My_Result 
      Order By 
	  device_id ASC 
	  ,Case When typed = 'Host' 
	      Then 1 
		   When typed = 'AppComp' 
		   Then 2 
		   When typed = 'SVC_COMM' 
		   Then 3 When typed = 'SVCS' 
		   Then 4 
      END ASC 
	  ,listener_port ASC
	  ,service ASC 
	  ,client_host ASC	 