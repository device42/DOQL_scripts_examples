    select d.name as "Device Name"
          ,d.type as "Device Type"
          ,d.serial_no as "Serial Number"
          ,d.service_level as "Service Level"
          ,d.tags as "Tags"
          ,d.first_added as "First Added"
          ,d.last_changed as "Last Changed"
          ,vh.name as "Virtual Host Name"
          ,vh.service_level as "Virtual Host Service Level"
          ,vh.tags as "Virtual Host Tags"
          ,b.name as "Building Name" 
          ,rm.name as "Room Name" 
          ,rk.name as "Rack Name"
    from view_device_v2 d
    left join view_building_v1 b 
      on d.calculated_building_fk = b.building_pk 
    left join view_room_v1 rm 
      on d.calculated_room_fk = rm.room_pk 
    left join view_rack_v1 rk 
      on d.calculated_rack_fk = rk.rack_pk 
    left join view_device_v2 vh
      on d.virtual_host_device_fk = vh.device_pk
    where d.deviceos_fk is null  