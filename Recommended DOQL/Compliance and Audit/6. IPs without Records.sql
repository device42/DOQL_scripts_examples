with ips as
    
    (select
                sc.servicecommunication_pk
                ,ld.name "Listening Device"
                ,ld.device_pk
                ,ld.name as "Listening Device Name"
                ,ld.serial_no as "Listening Serial Number"
                ,ld.uuid as "Listening Device UUID"
                ,ld.service_level as "Listening Device Service Level"
                ,ld.tags as "Listening Device Tags"
                ,ld.first_added as "Listening Device First Added"
                ,ld.last_edited as "Listening Device Last Edited"
                ,ld.last_changed as "Listening Device Last Changed"
                ,case when ld.device_pk is null then 'Missing Device' else 'Device Found' end as "Is Listening Device Found"
                ,case when ld.deviceos_fk is null then 'Missing OS' else 'OS Found' end as "Is Listening OS Found"
                ,case when ls.all_software is null then 'Missing Software' else 'Software Found' end as "Is Listening Software Found"
                ,split_part(sc.listener_ip::text, '/', 1)  "Listening IP"
                ,dns.name as "DNS Name"
                ,dns.type as "DNS Type"
                ,dns.content as "DNS Content"
                ,s.displayname "Listening Service"
                ,CASE
                  WHEN sc.protocol  = '6'
                  THEN 'TCP'
                  WHEN sc.protocol  = '17'
                  THEN 'UDP'
                  ELSE ''
                END "Protocol"
                ,sc.port "Port Communication"
                ,cd.name "Client Device Name"
                ,split_part(sc.client_ip::text, '/', 1)  "Client IP"
                ,case when (replace(split_part(sc.client_ip ::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' OR
                            replace(split_part(sc.client_ip ::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' OR
                            replace(split_part(sc.client_ip ::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' OR
                            replace(split_part(sc.client_ip ::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' OR
                            replace(split_part(sc.client_ip ::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' OR
                            replace(split_part(sc.client_ip ::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10') then 'Private'
                      else 'Public'
                      end as "Client IP Private or Public"
                ,case when (replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' OR
                            replace(split_part(sc.listener_ip::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10') then 'Private'
                      else 'Public'
                      end as "Listening IP Private or Public"
                ,coalesce(sc.client_process_name,sc.client_process_display_name) "Client Process Name"
                ,sc.last_detected "Communication Last Detected"
                ,case when cd.device_pk is null then 'Missing Device' else 'Device Found' end as "Is Client Device Found"
                ,case when cd.deviceos_fk is null then 'Missing OS' else 'OS Found' end as "Is Client OS Found"
                ,case when cs.all_software is null then 'Missing Software' else 'Software Found' end as "Is Client Software Found"
            from view_servicecommunication_v2 sc
            left Join view_device_v2 ld ON ld.device_pk = sc.listener_device_fk
            left join view_ipaddress_v1 ip on ld.device_pk = ip.device_fk
            left join view_dnsrecords_v1 dns
                    on host(ip.ip_address) =  dns.content
                    and dns.type like 'A'
            left join (select device_fk
                              ,string_agg(distinct alias_name, ' | ') as all_software
                        from view_softwareinuse_v1 
                        group by 1) ls on ld.device_pk = ls.device_fk
            left Join view_servicelistenerport_v2 lp ON lp.servicelistenerport_pk = sc.servicelistenerport_fk
            left Join view_serviceinstance_v2 si ON si.serviceinstance_pk = lp.discovered_serviceinstance_fk
            left Join view_service_v2 s ON s.service_pk = si.service_fk
            Left Join view_device_v2 cd ON cd.device_pk = sc.client_device_fk
            left join (select device_fk
                              ,string_agg(distinct alias_name, ' | ') as all_software
                        from view_softwareinuse_v1 
                        group by 1) cs on cd.device_pk = cs.device_fk
            Left Join view_affinitygroup_v2 ag ON ag.primary_device_fk = ld.device_pk
            Where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1')
            
  select *
  from ips
  where (("Is Listening Device Found" like 'Missing Device'
      or "Is Listening OS Found" like 'Missing OS'
      or "Is Listening Software Found" like 'Missing Software')
    and "Listening IP Private or Public" like 'Private')
  or
        (("Is Client Device Found" like 'Missing Device'
      or "Is Client OS Found" like 'Missing OS'
      or "Is Client Software Found" like 'Missing Software')
    and "Client IP Private or Public" like 'Private')