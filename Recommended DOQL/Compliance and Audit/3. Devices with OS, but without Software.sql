select d.name as "Device Name"
      ,d.type as "Device Type"
      ,d.service_level as "Service Level"
      ,d.tags as "Tags"
      ,d.first_added as "First Added"
      ,d.last_changed as "Last Changed"
      ,d.os_name as "OS Name"
      ,coalesce(d.os_version, d.os_version_no)  as "OS Version:"
      ,oc.name as "Object Category"
from view_device_v2 d
left join (select distinct device_fk
          from view_softwareinuse_v1 
          where device_fk is not null) siu
on d.device_pk = siu.device_fk
left join view_objectcategory_v1 oc
  on d.objectcategory_fk = oc.objectcategory_pk
where siu.device_fk is null
and d.deviceos_fk is not null