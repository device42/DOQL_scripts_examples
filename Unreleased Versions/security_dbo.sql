/* 
      DBO number 2: Security and Compliance

      Levi Davis, June 2021
      
    -  Updated 9/28/21 - SDay -    
    -		Corrected some minor bugs in original code.
    -       Removed 'JSON' and left data as string_agg
    -		Added no_os, no_cert_software, no_software, and ip_no_device cte's
    -  set d42_readonly_mt.d42_user_id = '1'
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
        ( 
        select device_fk
           ,service_level
           , max(last_detected) as last_detected_all
           , string_agg( concat('{Name:', a.name, ', ', 'Service Level:', a.listener_service_level, ', '
                                          ,'Device FK:', listener_device_fk, ', '
                                          ,'Last Detected',':', last_detected
                                          ,'}' ), '/')  as other_device
 --   FORMAT (getdate(), 'yyyy/MM/dd' 
       /*     ,concat("[", string_agg(concat("{Name:",a.name, ","
                                          ,"Service Level:", a.listener_service_level, ","
                                          ,"Device FK:", listener_device_fk, ","
                                          ,"Last Detected:", last_detected
                                          ,"}" )) order by last_detected desc), "]")::json as other_device*/
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
                  and ((lower(ld.service_level) like 'production' and lower(cd.service_level) not like 'production')
                        or (LOWER(ld.service_level) not like 'production' and lower(cd.service_level) like 'production'))
                  and ld.name <> ''
                  and ld.service_level <> ''
            group by 1,2,3,4,5 ) a
      group by 1,2
      
      ) ,
     


dpc as

     /* Identifies dev/prod mismatch between device communicating client devices.  
      Allows: 5_service_connections_dev_prod repor */
        (select device_fk
            ,service_level
            ,max(last_detected) as last_detected_all
          /*  ,concat('[', string_agg(concat('{"Name":"',name, '",'
                                          ,'"Service Level":"', client_service_level, '",'
                                          ,'"Device FK":"', client_device_fk, '",'
                                          ,'"Last Detected":"', last_detected
                                          ,'"}'), ',' order by last_detected desc), ']')::json as other_device
          */                             
                                          
           , string_agg(concat('{Name:', a.name, ', ', 'Service Level:', a.client_service_level, ', '
                                  ,'Device FK:', client_device_fk, ', '
                                  ,'Last Detected:', last_detected
                                  ,'}' ), '/')  as other_device                   
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
                 	and ((lower(ld.service_level) like 'production' and LOWER(cd.service_level) not like 'production')
                        or (LOWER(ld.service_level) not like 'production' and LOWER(cd.service_level) like 'production'))
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
            ,coalesce(dpl.service_level, dpc.service_level) as service_level   --  is this really the device service_level
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

      (
      /*select device_fk
            ,is_any_client_ip_public
            ,max(last_detected) as last_detected_insecure_port
            ,concat('[', string_agg(concat('{"Device FK":"',device_fk, '",'
                                          ,'"Port":"', port, '",'
                                          ,'"Client IP":"', client_ip, '",'
                                          ,'"Is Client IP Public":"', is_client_ip_public, '",'
                                          ,'"Last Detected":"', last_detected
                                          ,'"}'), ',' order by last_detected desc), ']')::json as insecure_port_other_device
       */                                   
      select device_fk
            ,is_any_client_ip_public     -- <<<<<   where is this carried forward?
            ,max(last_detected) as last_detected_insecure_port
            ,string_agg(concat('{Device FK:',device_fk, ','
                                          ,'Port:', port, ','
                                          ,'Client IP:', client_ip, ','
                                          ,'Is Client IP Public:', is_client_ip_public, ','
                                          ,'Last Detected:', last_detected
                                          ,'}'), ',' order by last_detected desc) as insecure_port_other_device                                     
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
      group by 1,2 ),

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
      3 - Identifies devices with OS, no detected software
      */ 
	  (select d.device_pk
			,d.deviceos_fk
	  from view_device_v2 d
	  left outer join view_softwareinuse_v1 siu  on d.device_pk = siu.device_fk 
	  where siu.device_fk is null 
	  	and d.deviceos_fk is not null)
	  	,
      
no_os as
	  /* 
	  2 - Identifies devices with no OS 
	  */
	  (select  d.device_pk
			  ,physicalsubtype_fk 
			  ,d.deviceos_fk
	  from view_device_v2 d
	  where d.deviceos_fk is null
	  	and ( physicalsubtype_fk is null or physicalsubtype_fk in ( 1,2,3,4,6,7,14,1009,1012))
	  	),
   --   select distinct physicalsubtype , physicalsubtype_fk, count(distinct os_fk)from view_device_v2 group by 1,2
      
	  	
ip_no_device as 
		(select ip.ipaddress_pk
			  ,null::integer 							as device_pk
	          ,split_part(ip.ip_address::text, '/', 1) 	as ip_address
	          ,'No'										as has_device
	          ,sn.network 								as subnet_network
	          ,range_begin 								as subnet_range_begin
	          ,range_end 								as subnet_range_end
	          ,sn.mask_bits 							as mask_bits
	          ,dns.name 								as dns_name
	          ,dns.type 								as dns_type
	          ,dns.content 								as dns_content
	          ,dns.dnszone_fk
	    from view_ipaddress_v1 ip
	    left join view_subnet_v1 sn			on ip.subnet_fk = sn.subnet_pk
	    left join view_dnsrecords_v1 dns    on host(ip.ip_address) =  dns.content
	      									and dns.type like 'A'
	    where ip.device_fk is null
	    and not ip.available
     	)
    
     	
      
/* 
      All together now
*/
select d.device_pk 
      ,coalesce(d.name, no_os.device_name) 										as device_name
      ,initcap(d.type) 															as device_type
      ,ps.physicalsubtype_name 
      ,d.serial_no 																as serial_number
      ,d.uuid 
      ,d.tags
      ,d.service_level
      ,d.first_added 
      ,d.last_edited 
      ,d.last_changed 
      ,coalesce(siu.all_software, 'No Software') as "all_software"
      ,coalesce(siu.all_software_categories, 'No Category') as "all_software_categories"
      ,case when cpubip.client_device_fk is not null then 'Yes' 
      		else 'No' end 														as is_client_w_public_ips
      ,cpubip.client_external_ips
      ,case when lpubip.listener_device_fk is not null then 'Yes' 
      		else 'No' end 														as is_listener_w_public_ips
      ,lpubip.listener_external_ips
      ,dev_prod_mismatch.service_level
      ,dev_prod_mismatch.last_detected_listener
      ,dev_prod_mismatch.last_detected_client
      ,dev_prod_mismatch.mismatched_listener_devices
      ,dev_prod_mismatch.mismatched_client_devices
      ,port.last_detected_insecure_port
      ,port.insecure_port_other_device
      ,coalesce(pii.contains_pii, 'Not Set') as contains_pii
      ,case when no_software.device_pk is not null and no_software.deviceos_fk is null then 'Yes' 
      		when d.device_pk  is null then 'Yes'
      		else 'No' end 														as is_missing_software
      ,case when no_os.device_pk is not null then 'Yes' 
      		when d.device_pk  is null then 'Yes'
      		else 'No' end 														as is_missing_os
      ,case when ip_no_device.has_device = 'No' then 'No' 
      		else 'Yes' end  													as has_device
      ,ip_no_device.ipaddress_pk
      ,ip_no_device.ip_address
      ,ip_no_device.subnet_network
      ,ip_no_device.subnet_range_begin
      ,ip_no_device.subnet_range_end
      ,ip_no_device.mask_bits
      ,ip_no_device.dns_name
      ,ip_no_device.dns_type
      ,ip_no_device.dns_content
      ,ip_no_device.dnszone_fk
from view_device_v2 d
left join (select siu1.device_fk
	            ,string_agg(distinct siu1.alias_name, ' | ') as all_software
	            ,string_agg(distinct s.category_name, ' | ') as all_software_categories
	      	from view_softwareinuse_v1 siu1
	      	left join view_software_v1 s  on siu1.software_fk = s.software_pk  group by 1
	      ) siu on 						d.device_pk 	 	 	= siu.device_fk
left join cpubip on                 	d.device_pk      	 	= cpubip.client_device_fk
left join lpubip on                 	d.device_pk       		= lpubip.listener_device_fk
left join dev_prod_mismatch on      	d.device_pk       		= dev_prod_mismatch.device_fk
left join port on                   	d.device_pk       		= port.device_fk
left join pii on                    	d.device_pk       		= pii.device_fk
left join no_software on            	d.device_pk       		= no_software.device_pk
left join no_os on						d.device_pk 	  		= no_os.device_pk
left join view_physicalsubtype_v2 ps on d.physicalsubtype_fk	= ps.physicalsubtype_pk 
full outer join ip_no_device on 		d.device_pk		  		= ip_no_device.device_pk where ip_no_device.device_pk is null


