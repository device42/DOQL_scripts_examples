   /*
 - Name: Compute Resources Business Object
 - Purpose: An extensive query to report on all devices and majority of related objects/attributes.
 - Date Created: 5/14/21
  - Updated 7/13/21
     - added field with just os_name and os_name_ver
	 - changed view_hardware_v1 to view_hardware_v2
	 - added hdw eos and eol 
  - Updated 8/24/21
	- added OS_group, first_added date and last_edited date
	- corrected the IP addresses aggregation so it did not include the CIDR block # IP only.
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

parts_summary as 

     /* Lists all parts associated with a device */
        (select pt.device_fk
                ,string_agg(distinct pm.name, ' | ') as cpu_model
                ,string_agg(distinct pmv.name, ' | ') as cpu_manufacturer
                ,string_agg(distinct pt.description, ' | ') as cpu_string
                ,count(*) as parts_count
        from view_part_v1 pt
        join view_partmodel_v1 pm on pm.partmodel_pk = pt.partmodel_fk
        left join view_vendor_v1 pmv on pmv.vendor_pk = pm.vendor_fk
        where pm.type_id = '1'
        group by 1
  ), 

ip_aggregate as 

     /* Groups all ips associated with a device */
        (Select 
			ipa.*
			,Case When ipa.all_ips = '' Then 0
				Else (CHAR_LENGTH(ipa.all_ips) - CHAR_LENGTH(REPLACE(ipa.all_ips, '|', '')))+1 
			End ip_count
		From (Select 
		 device_pk 
	/* Get all IPs for this device */
		,(SELECT array_to_string(array(
			Select ip.ip_address
			From view_ipaddress_v1 ip
			Where ip.device_fk = d.device_pk),
               ' | ')) as all_ips		   
		,(SELECT array_to_string(array(
			Select ip.label
			From view_ipaddress_v1 ip
			Where ip.device_fk = d.device_pk),
               ' | ')) as all_labels
		From view_device_v2 d
		Order by 1) ipa
  ), 
  
eoseol_summary as 

     /* EOS/EOL for each device */
        (Select dev.device_pk
				,dev.os_name
				,dev.os_fk
				,dev.os_version
				,ose.eol
				,ose.eos
        From (Select d.device_pk, d.os_name, d.os_fk, Null os_version From view_device_v2 d Where position('windows' IN lower(d.os_name)) > 0 or
		            position('microsoft' IN lower(d.os_name)) > 0) dev
        Join view_oseoleos_v1 ose on ose.os_fk = dev.os_fk 
		Union
		Select dev1.device_pk
				,dev1.os_name
				,dev1.os_fk
				,dev1.os_version
				,ose1.eol
				,ose1.eos				
        From (Select d.device_pk, d.os_name, d.os_fk, d.os_version From view_device_v2 d Where position('windows' IN lower(d.os_name)) = 0 and
		            position('microsoft' IN lower(d.os_name)) = 0) dev1
        Join view_oseoleos_v1 ose1 on ose1.os_fk = dev1.os_fk and ose1.version = dev1.os_version		
		),  

disk_summary as 

     /* Lists all disks associated with a device */
        (select pt.device_fk
                ,string_agg(distinct pm.modelno, ' | ') as disk_type
        from view_part_v1 pt
        join view_partmodel_v1 pm on pm.partmodel_pk = pt.partmodel_fk 
        where pm.type_id = '3'
        group by 1),

dns as

        (select ip.device_fk
                ,string_agg(dr.name || '.' || dz.name, ' | ') as dns_records
        From
            view_ipaddress_v1 ip
            join view_dnsrecords_v1 dr on dr.content like '%' || host(ip.ip_address) || '%'
            join view_dnszone_v1 as dz on dz.dnszone_pk = dr.dnszone_fk
        group by 1)

select d.last_edited as last_discovered,
        d.device_pk,
		d.first_added,
		d.last_edited,
        d.virtual_host_device_fk,
        cd.start_at as chassis_u_location,
		cd.device_pk as chassis_device_id,
		cd.name as chassis_device_name,
        hv.vm_manager_device_fk,
        d.name as device_name,
        d.tags,
        d.in_service,
        d.service_level,
        d.type as device_type,
        coalesce(d.physicalsubtype, '') || coalesce(d.virtualsubtype, '') as device_subtype,
        coalesce(d.virtualsubtype, '') as virtual_subtype,
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
		d.os_name,
        Case d.os_version When '' Then d.os_name Else coalesce(d.os_name || ' - ' || d.os_version,d.os_name) End as os_name_ver,
/* Normalize the OS/Version   */
	    Case When position('windows' IN lower(d.os_name)) > 0 or position('microsoft' IN lower(d.os_name)) > 0 Then d.os_name
			When position('esxi' IN lower(d.os_name)) = 1 Then coalesce(v2.name || ' ' || d.os_name,d.os_name) 
			When  d.os_version = '' Then d.os_name Else coalesce(d.os_name || ' - ' || d.os_version,d.os_name) 
		End as os_name_norm,
        d.os_version as os_version,
        d.os_version_no as os_version_number,
        ose.eol as os_end_of_life,
        ose.eos as os_end_of_support,
		h.end_of_life_date as hdw_end_of_life,
		h.end_of_support_date as hdw_end_of_support,		
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
        ps.cpu_model,
        ps.cpu_manufacturer,
        ps.cpu_string,
        ds.disk_type,
        ps.parts_count,
        dns.dns_records,
        /* Yes/No fields */
        case when cd.device_pk is not null then 'Yes' else 'No' end as is_blade,
        case when d.threads_per_core >= 2 then 'Yes' else 'No' end as is_hyperthreaded,
        case when d.os_name is null or d.os_name = '' then 'No' else 'Yes' end as is_os_discovered,
        case when sd.software_discovered is null then 'No' else 'Yes' end as is_software_discovered,
        case when d.network_device then 'Yes' else 'No' end as is_network_device,
        case when lower(d.type) = 'cluster' then 'Yes' else 'No' end as is_cluster,
        case when coi.container_id is not null then 'Yes' else 'No' end as is_container,
	/* Normalize - Grp the OS's */
	    CASE When position('windows' IN lower(d.os_name)) > 0 or
	            position('microsoft' IN lower(d.os_name)) > 0 
	       Then 'Windows'
	       When position('linux' IN lower(d.os_name)) > 0 or
	            position('centos' IN lower(d.os_name)) > 0 or
	            position('redhat' IN lower(d.os_name)) > 0 or	 /* Redhat  */	
	            position('ubuntu' IN lower(d.os_name)) > 0 or
	            position('suse' IN lower(d.os_name)) > 0 or
	            position('debian' IN lower(d.os_name)) > 0 or
	            position('sles' IN lower(d.os_name)) > 0 
	       Then 'Linux'					
	       When position('freebsd' IN lower(d.os_name)) > 0 or
				position('aix' IN lower(d.os_name)) > 0 or
	            position('hp' IN lower(d.os_name)) > 0 or
                   position('sunos' IN lower(d.os_name)) > 0 or
	            position('solaris' IN lower(d.os_name)) > 0 					
	       Then 'Unix'					
	       When position('400' IN lower(d.os_name)) > 0 
	       Then 'OS400'
	       When position('z/os' IN lower(d.os_name)) > 0 
	       Then 'z/OS'			   				   
	       When (position('ios' IN lower(d.os_name)) > 0 and Not d.network_device) or
	            position('mac' IN lower(d.os_name)) > 0 
	       Then 'Apple'	
	       When position('esx' IN lower(d.os_name)) > 0 or
	            position('vmware' IN lower(d.os_name)) > 0 
	       Then 'ESX'
	       When position('xen' IN lower(d.os_name)) > 0
	       Then 'XEN'			   
	       When position('virtbox' IN lower(d.os_name)) > 0
	       Then 'VM'				   
		   Else 'N/A'
		End AS "OS Group",			
        ipa.ip_count as number_ip_addresses_discovered,
        ipa.all_ips,
        ipa.all_labels,
        /* Aggregates */
        sum(pli.cost) as line_item_cost,
        sum(pch.cost) as po_cost,
        min(pch.po_date) as first_po_date,
        max(pch.po_date) as last_po_date,
        string_agg(distinct pch.cc_code::text, ' | ') as all_cost_centers,
        string_agg(distinct pch.cc_description::text, ' | ') as all_cost_center_descriptions
/* Direct joins to DOQL views */
from view_device_v2 d
left join ip_aggregate ipa on ipa.device_pk = d.device_pk
left join view_purchaselineitems_to_devices_v1 ptd on ptd.device_fk = d.device_pk
left join view_purchaselineitem_v1 pli on ptd.purchaselineitem_fk = pli.purchaselineitem_pk
left join view_purchase_v1 pch on pch.purchase_pk = pli.purchase_fk
left join eoseol_summary ose on ose.device_pk = d.device_pk
left join view_hardware_v2 h on d.hardware_fk = h.hardware_pk
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
left join view_device_v2 hv on d.virtual_host_device_fk = hv.device_pk
left join view_containerinstance_v1 coi on coi.device_fk = d.device_pk
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
left join parts_summary ps on d.device_pk = ps.device_fk
left join disk_summary ds on d.device_pk = ds.device_fk
left join dns on d.device_pk = dns.device_fk
/* Removes network devices, clusters and containers.
   Consider removing if needed */
where not d.network_device
      and lower(d.type) <> 'cluster' /* Remove clusters */
      and coi.container_id is null /* remove network devices and containers */
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41
        ,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72 ,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87