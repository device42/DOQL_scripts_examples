  /*
- Name: Compute Resources Business Object
- Purpose: An extensive query to report on all devices and majority of related objects/attributes.
- Date Created: 5/14/21
*/


with cap as

   /* Storage capacity rolled up to the device level */
   (select device_fk
           ,count(*) as local_disk_count
           ,sum(capacity-free_capacity)/1024 as used_space
           ,sum(capacity/1024) as total_space
           ,sum(free_capacity/1024) as total_free_space
   from view_mountpoint_v1
   where fstype_name <> 'nfs'
     and fstype_name <> 'nfs4'
     and filesystem not like '\\\\%'
   group by 1),

cpubip as

   /* Client devices communicating with external ips.  Allows 7_devices_accessed_by_ext_ip report */
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

    /* Listener devices communicating with external ips.  Allows 7_devices_accessed_by_ext_ip report */
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

dev_prod_list as

    /* Identifies dev/prod mismatch between communicating devices.  Allows 5_service_connections_dev_prod report */
       (select distinct
               ld.device_pk as device_fk
       from view_servicecommunication_v2 sc
       left join view_device_v2 ld on ld.device_pk = sc.listener_device_fk
       left join view_device_v2 cd on cd.device_pk = sc.client_device_fk
       where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1'
         and ((ld.service_level like 'production' and cd.service_level not like 'production')
               or (ld.service_level not like 'production' and cd.service_level like 'production'))),

dev_prod_client as

    /* Identifies dev/prod mismatch between communicating devices.  Allows 5_service_connections_dev_prod report */
       (select distinct
               cd.device_pk as device_fk
       from view_servicecommunication_v2 sc
       left join view_device_v2 ld on ld.device_pk = sc.listener_device_fk
       left join view_device_v2 cd on cd.device_pk = sc.client_device_fk
       where sc.client_ip != '127.0.0.1' and sc.client_ip != '::1'
         and ((ld.service_level like 'production' and cd.service_level not like 'production')
               or (ld.service_level not like 'production' and cd.service_level like 'production'))),

parts_summary as

    /* Lists all parts associated with a device */
       (select pt.device_fk
               ,string_agg(distinct pm.name, ' | ') as cpu_model
               ,string_agg(distinct pmv.name, ' | ') as cpu_manufacturer
               ,string_agg(distinct pt.description, ' | ') as cpu_string
       from view_part_v1 pt
       join view_partmodel_v1 pm on pm.partmodel_pk = pt.partmodel_fk
       left join view_vendor_v1 pmv on pmv.vendor_pk = pm.vendor_fk
       where pm.type_id = '1'
       group by 1
 ),

disk_summary as

    /* Lists all disks associated with a device */
       (select pt.device_fk
               ,string_agg(distinct pm.modelno, ' | ') as disk_type
       from view_part_v1 pt
       join view_partmodel_v1 pm on pm.partmodel_pk = pt.partmodel_fk
       where pm.type_id = '3'
       group by 1
 )


select d.last_edited as last_discovered,
       d.device_pk,
       d.virtual_host_device_fk,
       cd.start_at as chassis_u_location,
       cd.device_pk as chassis_device_id,
       cd.name as chassis_device_name,
       case when cd.device_pk is not null then 'Yes' else 'No' end as is_blade_yes_no,
       hv.vm_manager_device_fk,
       d.name as device_name,
       d.tags,
       d.in_service,
       d.service_level,
       d.type as device_type,
       coalesce(d.physicalsubtype, '') || coalesce(d.virtualsubtype, '') as device_subtype,
       d.serial_no as device_serial,
       d.virtual_host as virtual_host,
       d.network_device as network_device,
       d.os_architecture as os_architecture,
       d.total_cpus as total_cpus,
       d.core_per_cpu as cores_per_cpu,
       d.threads_per_core as threads_per_core,
       d.cpu_speed as cpu_speed,
       d.total_cpus*d.core_per_cpu as total_cores,
       case when d.ram <= 0 or d.ram is null then null                        
             when d.ram_size_type = 'TB' then d.ram * 1024^2
             when d.ram_size_type = 'GB' then d.ram * 1024
             when d.ram_size_type = 'MB' then d.ram
             else null end as ram_mb,
       v2.name as os_vendor,
       osc.category_name as os_category,
       case d.os_version when '' then d.os_name
                         else coalesce(d.os_name || ' - ' ||  d.os_version,d.os_name)
                         end as os_name,
       case when d.os_name is null or d.os_name = '' then 'No' else 'Yes' end as os_discovered_yes_no,
       d.os_version as os_version,
       d.os_version_no as os_version_number,
       ose.eol as os_end_of_life,
       ose.eos as os_end_of_support,
       v.name as manufacturer,
       h.name as hardware_model,
       d.asset_no as asset_number,
       d.bios_version as bios_version,
       d.bios_revision as bios_revision,
       d.bios_release_date as bios_release_date,
       sr.name as storage_room,
       b.name as building_name,
       m.name as room_name,
       r.row as row_name,
       r.name as rack_name,
       h.size as size_ru,
       ci.account,
       c.name as customer_department,
       cv.name as cloud_service_provider,
       ci.service_name as cloud_service_name,
       ci.instance_id as cloud_instance_id,
       ci.instance_name as cloud_instance_name,
       ci.instance_type as cloud_instance_type,
       ci.status as cloud_instance_status,
       ci.location as cloud_location,
       ci.notes as cloud_notes,
       sd.software_discovered,
       case when sd.software_discovered is null then 'No' else 'Yes' end as software_discovered_yes_no,
       svd.services_discovered,
       acd.application_components_discovered,
       md.mounts_discovered,
       md.mount_points,
       pd.parts_discovered,
       ns.network_shares,
       cap.local_disk_count,
       cap.used_space,
       cap.total_space,
       cap.total_free_space,
       case when cpubip.client_device_fk is not null then 'Yes' else 'No' end as client_accessed_by_ext_ip,
       cpubip.client_external_ips,
       case when lpubip.listener_device_fk is not null then 'Yes' else 'No' end as listener_accessed_by_ext_ip,
       lpubip.listener_external_ips,
       case when dev_prod_list.device_fk is not null then 'Yes' else 'No' end as service_level_mismatch_as_listener,
       case when dev_prod_client.device_fk is not null then 'Yes' else 'No' end as service_level_mismatch_as_client,
       ps.cpu_model,
       ps.cpu_manufacturer,
       ps.cpu_string,
       ds.disk_type,
       count(distinct ipaddress_pk) as number_ip_addresses_discovered,
       string_agg(distinct ip.ip_address::text, ' | ') as all_ips,
       string_agg(distinct ip.label, ' | ') as all_labels,
       sum(pli.cost) as line_item_cost,
       sum(pch.cost) as po_cost,
       min(pch.po_date) as first_po_date,
       max(pch.po_date) as last_po_date
/* Direct joins to DOQL views */
from view_device_v2 d
left join view_ipaddress_v1 ip on ip.device_fk = d.device_pk
left join view_purchaselineitems_to_devices_v1 ptd on ptd.device_fk = d.device_pk
left join view_purchaselineitem_v1 pli on ptd.purchaselineitem_fk = pli.purchaselineitem_pk
left join view_purchase_v1 pch on pch.purchase_pk = pli.purchase_fk
left join view_oseoleos_v1 ose on ose.os_fk = d.os_fk
                             and ose.version = d.os_version
left join view_hardware_v1 h on d.hardware_fk = h.hardware_pk
left join view_vendor_v1 v on h.vendor_fk = v.vendor_pk
left join view_room_v1 sr on sr.room_pk = d.storage_room_fk
left join view_rack_v1 r on d.rack_fk = r.rack_pk
left join view_room_v1 m on r.room_fk = m.room_pk
left join view_building_v1 b on b.building_pk = m.building_fk
left join view_os_v1 osc on osc.os_pk = d.os_fk
left join view_vendor_v1 v2 on osc.vendor_fk = v2.vendor_pk
left join view_customer_v1 c on d.customer_fk = c.customer_pk
left join view_device_custom_fields_flat_v1 dcf on dcf.device_fk = d.device_pk
left join view_cloudinstance_v1 ci on ci.device_fk = d.device_pk
left join view_vendor_v1 cv on cv.vendor_pk = ci.vendor_fk
left join view_customer_v1 cu on cu.customer_pk = d.customer_fk
/* Aggregates in subquery */
left join (select * from view_device_v2 where blade_chassis = 't') cd on d.host_chassis_device_fk = cd.device_pk
left join (select device_fk, count(*) as software_discovered from view_softwareinuse_v1 group by 1) sd on d.device_pk = sd.device_fk
left join (select device_fk, count(*) as services_discovered from view_serviceinstance_v2 group by 1) svd on d.device_pk = svd.device_fk
left join (select device_fk, count(*) as application_components_discovered from view_appcomp_v1 group by 1) acd on d.device_pk = acd.device_fk
left join (select device_fk, count(*) as mounts_discovered , string_agg(distinct filesystem, ' | ') as mount_points from view_mountpoint_v1 group by 1) md on d.device_pk = md.device_fk
left join (select device_fk, count(*) as parts_discovered from view_part_v1 group by 1) pd on d.device_pk = pd.device_fk
left join (select device_fk, string_agg(distinct name, ' | ') as network_shares from view_networkshare_v1 group by 1) ns on d.device_pk = ns.device_fk
/* Joining CTEs */
left join cap on d.device_pk = cap.device_fk
left join cpubip on d.device_pk = cpubip.client_device_fk
left join lpubip on d.device_pk = lpubip.listener_device_fk
left join dev_prod_list on d.device_pk = dev_prod_list.device_fk
left join dev_prod_client on d.device_pk = dev_prod_client.device_fk
left join view_device_v2 hv on d.virtual_host_device_fk = hv.device_pk
left join view_containerinstance_v1 coi on coi.device_fk = d.device_pk
left join parts_summary ps on d.device_pk = ps.device_fk
left join disk_summary ds on d.device_pk = ds.device_fk
where not d.network_device and lower(d.type) <> 'cluster' /* Remove clusters */
 and coi.container_id is null /* remove network devices and containers */
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
       ,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72 ,73,74,75,76