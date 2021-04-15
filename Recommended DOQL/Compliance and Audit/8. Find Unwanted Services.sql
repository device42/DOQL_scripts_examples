select  d.name as "Device Name"
      ,initcap(d.type) as "Device Type"
      ,d.serial_no as "Serial Number"
      ,d.in_service as "Is in Service"
      ,d.service_level as "Service Level"
      ,d.first_added as "First Added"
      ,d.last_edited as "Last Edited"
      ,d.last_changed as "Last Changed"
      ,s.pretty_name as "Service Pretty Name"
      ,s.displayname as "Service Display Name"
      ,si.topology_status as "Topology Status"
      ,si.pinned as "Pinned"
from view_device_v2 d
left join view_serviceinstance_v2 si
  on d.device_pk = si.device_fk
left join view_service_v2 s
  on si.service_fk = s.service_pk