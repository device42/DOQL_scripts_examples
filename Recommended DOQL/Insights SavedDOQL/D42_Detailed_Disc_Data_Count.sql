/*
Will give a count of all detailed discovery data to help identify hosts with or without detailed child objects.
*/
 Select 
	dh.*
    ,lower(deval.alias_name) "Alias/FQDN"
    From(
      Select
       d.device_pk "Device_ID"
       ,lower(split_part(d.name,'.',1)) "Device Name (SN)"
       ,lower(d.name) "Device Name"
       ,d.os_name "Operating System"
       ,(Select count(*) From view_softwaredetails_v1 sd Where sd.device_fk = d.device_pk) "Software Discovered"
       ,(Select count(*) From view_serviceinstance_v2 si Where si.device_fk = d.device_pk) "Services Discovered"
	   ,(Select count(*) From view_servicecommunication_v2 sc Where sc.listener_device_fk = d.device_pk) "Service Connections Discovered"
       ,(Select count(*) From view_mountpoint_v1 m Where m.device_fk = d.device_pk) "Mounts Discovered"
       ,(Select count(*) From view_appcomp_v1 a Where a.device_fk = d.device_pk) "Application components Discovered"
       ,d.first_added "First Added"
       ,d.last_edited "Last Updated"
     From
       view_device_v1 d) dh
       Left Join view_devicealias_v1 deval On deval.device_fk = dh."Device_ID"