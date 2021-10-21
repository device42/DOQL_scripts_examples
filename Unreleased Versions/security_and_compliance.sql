/* 
      DBO number 2: Security and Compliance

      Levi Davis, June 2021
*/

with cpubip as 

    /* Client devices communicating with external public ips.  
      Allows report: 7_devices_accessed_by_ext_ip report */
    (select client_device_fk
          ,string_agg(distinct client_ip::text, ' | ') as client_external_ips
    from view_servicecommunication_v2 
    where not (replace(split_part(client_ip::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' or
              replace(split_part(client_ip::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' or
              replace(split_part(client_ip::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' or
              replace(split_part(client_ip::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' or
              replace(split_part(client_ip::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' or
              replace(split_part(client_ip::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10')
          and client_device_fk is not null
          and client_ip != '127.0.0.1' and client_ip != '::1'
    group by 1),


lpubip as

     /* Listener devices communicating with external ips.  
     Allows report: 7_devices_accessed_by_ext_ip report */
    (select listener_device_fk
          ,string_agg(distinct listener_ip::text, ' | ') as listener_external_ips
    from view_servicecommunication_v2 
    where not (replace(split_part(listener_ip::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' or
              replace(split_part(listener_ip::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' or
              replace(split_part(listener_ip::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' or
              replace(split_part(listener_ip::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' or
              replace(split_part(listener_ip::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' or
              replace(split_part(listener_ip::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10')
          and listener_device_fk is not null
          and listener_ip != '127.0.0.1' and listener_ip != '::1'
    group by 1),


dpl as

     /* Identifies dev/prod mismatch between device communicating listener devices.  
      Allows: 5_service_connections_dev_prod repor */
        (select device_fk
            ,service_level
            ,max(last_detected) as last_detected_all
            ,concat('[', string_agg(concat('{"Name":"',name, '",'
                                          ,'"Service Level":"', listener_service_level, '",'
                                          ,'"Device FK":"', listener_device_fk, '",'
                                          ,'"Last Detected":"', last_detected
                                          ,'"}'), ',' order by last_detected desc), ']')::json as other_device
      from
            (select cd.device_pk as device_fk
                        ,cd.service_level
                        ,ld.name
                        ,ld.service_level as listener_service_level
                        ,sc.listener_device_fk
                        ,max(sc.last_detected) as last_detected
                  from view_servicecommunication_v2 sc
                  left join view_device_v2 ld on ld.device_pk = sc.listener_device_fk
                  left join view_device_v2 cd on cd.device_pk = sc.client_device_fk
                  where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1'
                  and ((ld.service_level like 'production' and cd.service_level not like 'production')
                        or (ld.service_level not like 'production' and cd.service_level like 'production'))
                  and ld.name <> ''
                  and ld.service_level <> ''
            group by 1,2,3,4,5) a
      group by 1,2),


dpc as

     /* Identifies dev/prod mismatch between device communicating client devices.  
      Allows: 5_service_connections_dev_prod repor */
        (select device_fk
            ,service_level
            ,max(last_detected) as last_detected_all
            ,concat('[', string_agg(concat('{"Name":"',name, '",'
                                          ,'"Service Level":"', client_service_level, '",'
                                          ,'"Device FK":"', client_device_fk, '",'
                                          ,'"Last Detected":"', last_detected
                                          ,'"}'), ',' order by last_detected desc), ']')::json as other_device
      from
            (select ld.device_pk as device_fk
                        ,ld.service_level
                        ,cd.name
                        ,cd.service_level as client_service_level
                        ,sc.client_device_fk
                        ,max(sc.last_detected) as last_detected
                  from view_servicecommunication_v2 sc
                  left join view_device_v2 ld on ld.device_pk = sc.listener_device_fk
                  left join view_device_v2 cd on cd.device_pk = sc.client_device_fk
                  where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1'
                  and ((ld.service_level like 'production' and cd.service_level not like 'production')
                        or (ld.service_level not like 'production' and cd.service_level like 'production'))
                  and cd.name <> ''
                  and cd.service_level <> ''
            group by 1,2,3,4,5) a
      group by 1,2),

dev_prod_mismatch as

      /* 
      This combines the previous two CTEs to create lists of all client and listener 
      devices with mismatched service levels.
      */
      (select coalesce(dpl.device_fk, dpc.device_fk) as device_fk
            ,coalesce(dpl.service_level, dpc.service_level) as service_level
            ,dpl.last_detected_all as last_detected_listener
            ,dpc.last_detected_all as last_detected_client
            ,dpl.other_device as mismatched_listener_devices
            ,dpc.other_device as mismatched_client_devices
      from dpl
      full outer join dpc
      on dpl.device_fk = dpc.device_fk),

port as

      /* 
      Identifies devices communicating through typically insecure ports.
      Also, identifies if that communcation is using a public IP address
      */
      (select device_fk
            ,is_any_client_ip_public
            ,max(last_detected) as last_detected_insecure_port
            ,concat('[', string_agg(concat('{"Device FK":"',device_fk, '",'
                                          ,'"Port":"', port, '",'
                                          ,'"Client IP":"', client_ip, '",'
                                          ,'"Is Client IP Public":"', is_client_ip_public, '",'
                                          ,'"Last Detected":"', last_detected
                                          ,'"}'), ',' order by last_detected desc), ']')::json as insecure_port_other_device
      from
            (select slp.device_fk
                  ,slp.port
                  ,sc.client_ip
                  ,case when (replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' or
                              replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' or
                              replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' or
                              replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' or
                              replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' or
                              replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10') then 'No'
                        else 'Yes' end as is_client_ip_public
                  , case when
                        sum(case when (replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '127.0.0.0/8' or
                                    replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '10.0.0.0/8' or
                                    replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '172.16.0.0/12' or
                                    replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << '192.168.0.0/16' or
                                    replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << 'fc00::/7' or
                                    replace(split_part(sc.client_ip::text, '/', 1), '::ffff:', '')::inet << 'fe80::/10') then 0
                              else 1 end)
                        > 0 then 'Yes' else 'No' end as is_any_client_ip_public
                  ,max(last_detected) as last_detected
            from view_servicecommunication_v2 sc
            join view_servicelistenerport_v2 slp
            on sc.servicelistenerport_fk = slp.servicelistenerport_pk
            where slp.port in (21, 22, 23, 25, 53, 80, 139, 443, 445, 1433, 3306, 3389, 8080)
            group by 1,2,3,4) a
      group by 1,2),

pii as

      /* 
      Identifies if a device is using a business application
      set at containing PII data
      */
      (select bae.device_fk
                  ,case when ba.is_contains_pii then 'Yes'
                        when not ba.is_contains_pii then 'No'
                        else 'Not Set' end as contains_pii
            from view_businessapplicationelement_v1 bae
            join view_businessapplication_v1 ba
            on bae.businessapplication_fk = ba.businessapplication_pk),

no_software as

      /* 
      Identifies devices with no detected software
      */
      (select d.device_pk as device_fk
      from view_device_v2 d
      left join (select distinct device_fk
            from view_softwareinuse_v1 
            where device_fk is not null) siu
      on d.device_pk = siu.device_fk
      where siu.device_fk is null
      and d.deviceos_fk is not null)

/* 
      All together now
*/
select d.device_pk as device_fk
      ,d.name as device_name
      ,case when cpubip.client_device_fk is not null then 'Yes' else 'No' end as is_client_w_public_ips
      ,cpubip.client_external_ips
      ,case when pubip.listener_device_fk is not null then 'Yes' else 'No' end as is_listener_w_public_ips
      ,lpubip.listener_external_ips
      ,dev_prod_mismatch.service_level
      ,dev_prod_mismatch.last_detected_listener
      ,dev_prod_mismatch.last_detected_client
      ,dev_prod_mismatch.mismatched_listener_devices
      ,dev_prod_mismatch.mismatched_client_devices
      ,port.last_detected_insecure_port
      ,port.insecure_port_other_device
      ,coalesce(pii.contains_pii, 'Not Set') as contains_pii
      ,case when d.deviceos_fk is null then 'Yes' else 'No' end as is_missing_os
      ,case when no_software.device_fk is null then 'Yes' else 'No' end as is_missing_software
from view_device_v2 d
left join cpubip on d.device_pk = cpubip.client_device_fk
left join lpubip on d.device_pk = lpubip.listener_device_fk
left join dev_prod_mismatch on d.device_pk = dev_pro_mismatch.device_fk
left join port on d.device_pk = port.device_fk
left join pii on d.device_pk = pii.device_fk
left join no_software on d.device_pk = no_software.device_fk