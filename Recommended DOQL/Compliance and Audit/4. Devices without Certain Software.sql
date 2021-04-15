select d.device_pk
      ,d.name as "Device Name"
      ,initcap(d.type) as "Device Type"
      ,d.serial_no as "Serial Number"
      ,d.uuid
      ,d.service_level as "Service Level"
      ,d.tags as "Tags"
      ,d.first_added as "First Added"
      ,d.last_edited as "Last Edited"
      ,d.last_changed as "Last Changed"
      ,coalesce(siu.all_software, 'No Software') as "All Software"
      ,coalesce(siu.all_software_categories, 'No Category') as "All Software Categories"
from view_device_v2 d
left join (select siu.device_fk
            ,string_agg(distinct siu.alias_name, ' | ') as all_software
            ,string_agg(distinct s.category_name, ' | ') as all_software_categories
      from view_softwareinuse_v1 siu
      left join view_software_v1 s
        on siu.software_fk = s.software_pk
      group by 1) siu
		on d.device_pk = siu.device_fk