with ips as
    
    (select
                distinct 
                sc.listener_device_fk
                ,sc.client_device_fk
                ,ld.name as "Listening Device Name"
                ,ld.type as "Listening Device Type"
                ,ld.serial_no as "Listening Serial Number"
                ,ld.uuid as "Listening Device UUID"
                ,ld.service_level as "Listening Device Service Level"
                ,ld.tags as "Listening Device Tags"
                ,ld.first_added as "Listening Device First Added"
                ,ld.last_changed as "Listening Device Last Changed"
                ,split_part(sc.listener_ip::text, '/', 1) as "Listening IP"
                ,CASE
                  WHEN sc.protocol  = '6'
                  THEN 'TCP'
                  WHEN sc.protocol  = '17'
                  THEN 'UDP'
                  ELSE ''
                END "Protocol"
                ,sc.port "Port Communication"
                ,cd.name "Client Device Name"
                ,cd.type as "Client Device Type"
                ,cd.service_level as "Client Device Service Level"
                ,cd.first_added as "Client Device First Added"
                ,cd.last_changed as "Client Device Last Changed"
                ,split_part(sc.client_ip::text, '/', 1) "Client IP"
                ,case when (replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' OR
                            replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' OR
                            replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' OR
                            replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' OR
                            replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' OR
                            replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10') then 'Private'
                      else 'Public'
                      end as "Client Private or Public IP"
                ,case when (replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10') then 'Private'
                      else 'Public'
                      end as "Listener Private or Public IP"
            from view_servicecommunication_v2 sc
            left Join view_device_v2 ld ON ld.device_pk = sc.listener_device_fk
            left join view_ipaddress_v1 ip on ld.device_pk = ip.device_fk
            left Join view_servicelistenerport_v2 lp ON lp.servicelistenerport_pk = sc.servicelistenerport_fk
            left Join view_serviceinstance_v2 si ON si.serviceinstance_pk = lp.discovered_serviceinstance_fk
            left Join view_service_v2 s ON s.service_pk = si.service_fk
            Left Join view_device_v2 cd ON cd.device_pk = sc.client_device_fk
            Left Join view_affinitygroup_v2 ag ON ag.primary_device_fk = ld.device_pk
            Where sc.client_ip::text not like '%127.0.0.1%' and sc.client_ip::text not like '%::1%')
            
  select *
  from ips
  where ("Client Private or Public IP" like 'Public'
    or "Listener Private or Public IP" like 'Public')