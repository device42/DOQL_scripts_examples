/*
Will give a count of all detailed discovery data to help identify hosts with or without detailed child objects.
*/
 Select dh.*,
     lower(deval.alias_name) "Alias/FQDN"
     from(
      Select
       d.device_pk "Device_ID",
       lower(split_part(d.name,'.',1)) "Device Name (SN)",
       lower(d.name) "Device Name",
       d.os_name "Operating System",
      (select count(*) from view_softwaredetails_v1 sd where sd.device_fk = d.device_pk) "Software Discovered",
      (select count(*) from view_serviceinstance_v2 si where si.device_fk = d.device_pk) "Services Discovered",
	  (select count(*) from view_servicecommunication_v2 sc where sc.listener_device_fk = d.device_pk) "Service Connections Discovered",
      (select count(*) from view_mountpoint_v1 m where m.device_fk = d.device_pk) "Mounts Discovered",
      (select count(*) from view_appcomp_v1 a where a.device_fk = d.device_pk) "Application components Discovered",
      d.first_added "First Added",
      d.last_edited "Last Updated"
     from
      view_device_v1 d) dh
      left join view_devicealias_v1 deval on deval.device_fk = dh."Device_ID"