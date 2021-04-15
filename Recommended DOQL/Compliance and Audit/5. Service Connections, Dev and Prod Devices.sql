with ips as
    (select distinct
                ld.device_pk as "Listening Device PK"
                ,ld.name as "Listening Device Name"
                ,cd.device_pk as "Client Device PK"
                ,cd.name as "Client Device Name"
                ,coalesce(ld.service_level, '') as "Listening Device Service Level"
                ,coalesce(cd.service_level, '') as "Client Device Service Level"
                ,case when (ld.service_level like 'Production' and cd.service_level not like 'Production')
                        or (ld.service_level not like 'Production' and cd.service_level like 'Production') then 'Yes'
                      else 'No' end as "Is Dev/Prod Mismatch"
            from view_servicecommunication_v2 sc
            left Join view_device_v2 ld ON ld.device_pk = sc.listener_device_fk
            Left Join view_device_v2 cd ON cd.device_pk = sc.client_device_fk
            Where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1')
  select *
  from ips
  where "Is Dev/Prod Mismatch" like 'Yes'