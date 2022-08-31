WITH
  software_data AS (
                  SELECT si.device_fk "device_id"
                          ,d.name "device_name"
                          ,d.os_fk "os_id"
                          ,d.os_name "os_name"                          
                          ,si.software_fk::text "software_id"
                          ,s.name "software"
                          ,'N/A' "service_id"
                          ,'N/A' "service_name"    
                          ,'software' "data_type"
                          ,json_build_object('software_data','No Details') AS "details"
                  FROM view_softwareinuse_v1 si
                  JOIN view_software_v1 s on si.software_fk = s.software_pk 
                  JOIN view_device_v2 d on d.device_pk = si.device_fk 
  ),
  services_data AS (
                  SELECT si.device_fk "device_id"
                          ,d.name "device_name"
                          ,d.os_fk "os_id"
                          ,d.os_name "os_name"
                          ,'N/A' "software_id"
                          ,'N/A' "software"                          
                          ,si.service_fk::text "service_id"
                          ,s.displayname "service_name"                          
                          ,'service' "data_type"
                          ,json_build_object('service_data','No Details') AS "details"
                  FROM view_serviceinstance_v2 si
                  JOIN view_service_v2 s on si.service_fk  = s.service_pk 
                  JOIN view_device_v2 d on d.device_pk = si.device_fk   
  ),
  service_communication_data AS (
                  SELECT sc.listener_device_fk  "device_id"
                          ,d.name "device_name"
                          ,d.os_fk "os_id"
                          ,d.os_name "os_name"
                          ,'N/A' "software_id"
                          ,'N/A' "software"                                   
                          ,si.service_fk::text "service_id"
                          ,s.displayname "service_name"                          
                          ,'service communication' "data_type"
                          ,json_build_object('service_comm_data',sc.*) AS "details"
                  FROM view_servicecommunication_v2 sc
                  JOIN view_device_v2 d on d.device_pk = sc.listener_device_fk
                  JOIN view_servicelistenerport_v2 slp on slp.servicelistenerport_pk = sc.servicelistenerport_fk 
                  JOIN view_serviceinstance_v2 si on si.serviceinstance_pk = slp.discovered_serviceinstance_fk 
                  JOIN view_service_v2 s on si.service_fk  = s.service_pk 
  ),
  ru_data AS (
                  SELECT ru.device_fk "device_id"
                          ,d.name "device_name"
                          ,d.os_fk "os_id"
                          ,d.os_name "os_name"
                          ,'N/A' "software_id"
                          ,'N/A' "software"                                   
                          ,'N/A' "service_id"
                          ,'N/A' "service_name"                           
                          ,'resource utilization' "data_type"
                          ,json_build_object('ru_data',ru.*) AS "details"
                  FROM view_rudata_v2 ru
                  JOIN view_device_v2 d on d.device_pk = ru.device_fk
                  WHERE measure_type_id IN ('1','2')
  )
SELECT * FROM software_data
UNION ALL
SELECT * FROM services_data
UNION ALL
SELECT * FROM service_communication_data
UNION ALL
SELECT * FROM ru_data