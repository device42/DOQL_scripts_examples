/*
DBB-Compute v2
Purpose: An extensive query to report on all COMPUTE devices and majority of related objects/attributes.
		  This view does not contain network devices, blade-chassis, or containers.
 */

create  materialized view  view_dbb_compute_v2    as  (
with 
	
	/* get the records needed for storage size calculations - windows machines */
agg_mp_records_win  as (
	
	Select 
		mp.*, 
		dr.device_fk
	From view_mountpoint_v2 mp
	left Join view_deviceresource_v1 dr ON dr.resource_fk = mp.mountpoint_pk	 and lower(dr.relation) = 'mountpoint'
	Where mp.mountpoint = mp.label
	),
	
	/* Sum up local and remote disks for window devices  */      
sum_win_storage  as (
	Select 
    	coalesce(lcl.device_fk, rmt.device_fk)					device_fk,
    	coalesce(lcl.local_disk_count,0)						local_disk_count,
    	coalesce(lcl.local_stor,0) 								local_total_space_gb, 
    	coalesce(lcl.local_stor_free,0) 						local_free_space_gb,
		coalesce((lcl.local_stor - lcl.local_stor_free),0)		local_used_space_gb,
    	coalesce(rmt.remote_disk_count,0)						remote_disk_count,
    	coalesce(rmt.remote_stor,0) 							remote_total_space_gb, 
    	coalesce(rmt.remote_stor_free,0) 						remote_free_space_gb, 
    	coalesce((rmt.remote_stor - rmt.remote_stor_free),0)	remote_used_space_gb,
    	'WIN' mp_type
    From (
    	Select 
    		amrw.device_fk, 
    		round(sum(amrw.capacity/1024),2)  		local_stor, 
    		round(sum(amrw.free_capacity/1024),2)  	local_stor_free,
    		count(1)								local_disk_count
        From agg_mp_records_win amrw 
        Where (position(':' IN amrw.mountpoint) > 0 and ( amrw.filesystem is null or amrw.filesystem = '')  )
        Group by 1
        ) lcl
    full outer  Join (
    	Select 
    		amrw.device_fk, 
    		round(sum(amrw.capacity/1024),2) 		remote_stor, 
    		round(sum(amrw.free_capacity/1024),2) 	remote_stor_free ,
    		count(1)								remote_disk_count
        From agg_mp_records_win amrw 
        Where (position('\\' IN amrw.mountpoint) > 0 and amrw.fstype_name  is not null )
        Group by 1) rmt 					
    ON rmt.device_fk = lcl.device_fk   
    
    ) ,
  
 	/* get the records needed for storage size calculations - Non-Windows machines machines */ 

agg_mp_records_nix  as (
    Select Distinct on (dr.device_fk, mp.fstype_name, round(mp.capacity/1024,2), round(mp.free_capacity/1024,2) ) 
    	mp.*, 
    	dr.device_fk
    From view_mountpoint_v2 mp
    Join view_deviceresource_v1 dr ON dr.resource_fk = mp.mountpoint_pk and lower(dr.relation) = 'mountpoint'
    Where (mp.mountpoint != mp.label or mp.label is Null)
    ),
    
	/* Sum up local and remote for non-window devices (Nix and VMW)  */    
sum_nix_storage  as (
	Select 
		lcl.device_fk, 
		coalesce(lcl.local_disk_count,0)						local_disk_count,
		coalesce(lcl.local_stor ,0) 							local_total_space_gb, 
		coalesce(lcl.local_stor_free,0) 						local_free_space_gb,
		coalesce((lcl.local_stor - lcl.local_stor_free),0)		local_used_space_gb,
		coalesce(rmt.remote_disk_count,0)						remote_disk_count,
		coalesce(rmt.remote_stor ,0) 							remote_total_space_gb, 
		coalesce(rmt.remote_stor_free,0) 						remote_free_space_gb, 
    	coalesce((rmt.remote_stor - rmt.remote_stor_free),0)	remote_used_space_gb,
		'NIX' mp_type
	From (
		Select 
			amrw.device_fk, 
			round(sum(amrw.capacity/1024),2)  		local_stor, 
			round(sum(amrw.free_capacity/1024),2)  	local_stor_free  ,
			count(1)								local_disk_count
	    From agg_mp_records_nix amrw 
	    Where (lower(amrw.fstype_name) IN ('ntfs', 'fat32', 'vfat', 'ext2', 'ext3', 'ext4', 'apfs', 'btrfs', 'dev', 'fd', 'fdescfs', 'ffs', 'udf', 'ufs', 'xfs', 'zfs','vmfs') 
	    		or amrw.fstype_name is Null)  and amrw.capacity is not null
	    Group by 1) lcl
	left Join (
		Select amrw.device_fk, 
			round(sum(amrw.capacity/1024),2) 		remote_stor, 
			round(sum(amrw.free_capacity/1024),2) 	remote_stor_free ,
			count(1)								remote_disk_count
	    From agg_mp_records_nix amrw 
	    Where (lower(amrw.fstype_name) IN ('nfs', 'nfs4', 'cifs', 'smb', 'smbfs', 'dfsfuse_dfs', 'objfs')) and amrw.capacity is not null
	    Group by 1) rmt 			
		ON rmt.device_fk = lcl.device_fk   

    	),
    	
	/* union all the MP records from windows and non-windows machines.  */ 
cap  as (
   Select 	
   		coalesce (win.device_fk,nix.device_fk)					as device_fk,
    	win.local_disk_count + nix.local_disk_count 			as local_disk_count,
       win.local_total_space_gb + nix.local_total_space_gb 		as local_total_space_gb, 
       win.local_free_space_gb + nix.local_free_space_gb 		as local_free_space_gb,
	   win.local_used_space_gb + nix.local_used_space_gb 		as local_used_space_gb,
       win.remote_disk_count + nix.remote_disk_count 			as remote_disk_count,
       win.remote_total_space_gb + nix.remote_total_space_gb 	as remote_total_space_gb,  
       win.remote_free_space_gb + nix.remote_free_space_gb 		as remote_free_space_gb, 
       win.remote_used_space_gb + nix.remote_used_space_gb 		as remote_used_space_gb
  	From sum_win_storage win 
	full outer join sum_nix_storage nix	on win.device_fk = nix.device_fk
    )  ,   

parts_summary as 
     /* Lists all parts associated with a device */
        (select 
        		pt.device_fk
                ,string_agg(distinct pm.name, ' | ') as cpu_model
                ,string_agg(distinct pmv.name, ' | ') as cpu_manufacturer
                ,string_agg(distinct pt.description, ' | ') as cpu_description
                ,count(1) as parts_count
        from view_part_v1 pt
        join view_partmodel_v1 pm		 	on pm.partmodel_pk = pt.partmodel_fk
        left join view_vendor_v1 pmv 		on pmv.vendor_pk = pm.vendor_fk
        where lower(pm.type_name) = 'cpu' and pt.device_fk  is not null
        group by 1
  ), 

ip_aggregate as (
     /* Groups all ips associated with a device */
        Select 
			ipa.*
			,Case When ipa.all_ips = '' Then 0
				Else (CHAR_LENGTH(ipa.all_ips) - CHAR_LENGTH(REPLACE(ipa.all_ips, '|', '')))+1 
			End ip_count
		From (
			Select 
		 		device_pk 
				/* Get all IPs for this device */
				,left((SELECT array_to_string(array(Select distinct ip.ip_address From view_ipaddress_v1 ip 	Where ip.device_fk = d.device_pk order by ip.ip_address),' | ')),32000)	as all_ips		   
				,left((SELECT array_to_string(array(Select distinct ip.label From view_ipaddress_v1 ip Where ip.device_fk = d.device_pk order by ip.label), ' | ')),32000)		as all_labels
			 From view_device_v2 d
			 Order by 1) ipa
  	), 
  
eoseol_summary as 
     /* EOS/EOL for OS on each device */
        (  /* Microsoft os's */
        Select dev.device_pk
				,dev.os_name
				,dev.os_fk
				,dev.os_version
				,ose.eol
				,ose.eos
        From (Select d.device_pk, d.os_name, d.os_fk, Null os_version From view_device_v2 d Where position('windows' IN lower(d.os_name)) > 0 or
		            position('microsoft' IN lower(d.os_name)) > 0) dev
        Join view_oseoleos_v1 ose on ose.os_fk = dev.os_fk 
		union  
		/* non-Microsoft os's */
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
        (
        select pm.device_fk
                ,string_agg(pm.model  ,' | '  order by 1 ) as disk_type
         from  (select distinct
        			pt.device_fk
                	,pm.modelno::text || ' ' || pm.hddtype_name::text  as model
        		from view_part_v1 pt
        		join view_partmodel_v1 pm on pm.partmodel_pk = pt.partmodel_fk
        		where lower(pm.type_name) in ('hard disk', 'disk drive') and pt.device_fk is not null
        		order by 1,2
        		)   pm 
        where pm.model is not null
        group by 1
        ),

dns as (  /* split the dns record aggregation to combine the A and AAAA in separate fields  */
		Select * 
		From crosstab(	$$
		With 
			 /* Get max RU date  and then take previous 30 days  */
			dns_data  as (	
			select ip.device_fk
					,dr.type
					,left(string_agg(distinct (dr.name || '.' || dz.name), ' | '),32000) as dns_records		  
			From
				view_ipaddress_v1 ip
				join view_dnsrecords_v1 dr 	on dr.content like '%' || host(ip.ip_address) || '%'
				join view_dnszone_v1 as dz 	on dz.dnszone_pk = dr.dnszone_fk
				where dr.type in ('A','AAAA') and ip.device_fk is not null
			Group by 1,2
			)
		Select dd.device_fk, dd.type, dd.dns_records from dns_data dd Order by 1,2
			 $$,
	/* Dummy table to help keep the data values in proper cols */
			 $$select name from (
				Select 	'A' as  name
					Union	
				Select 'AAAA' as name) coln order by 1$$) 
		 AS final_result(device_fk NUMERIC, dns_A_records Text, dns_AAAA_records Text)
        ),
        
counts as (
 	select 
 		d.device_pk 
 		,sum(pli.cost) 											as all_line_item_costs
        ,sum(pch.cost) 											as all_po_costs
        ,min(pch.po_date) 										as first_po_date
        ,max(pch.po_date)										as last_po_date
        ,string_agg(distinct pch.order_no, ' | ')				as all_po_numbers
        ,string_agg(distinct pch.cc_code::text, ' | ') 			as all_cost_centers
        ,left(string_agg(distinct pch.cc_description::text, ' | '),32000) 	as all_cost_center_descriptions
 	from view_device_v2 d 
 	left join view_purchaselineitems_to_devices_v1 ptd 		on ptd.device_fk = d.device_pk
	left join view_purchaselineitem_v1 pli 					on ptd.purchaselineitem_fk = pli.purchaselineitem_pk
	left join view_purchase_v1 pch 							on pch.purchase_pk = pli.purchase_fk
	group by 1
	),

/* Aggregates in subquery */
cd as  (select device_pk, start_at, name										from view_device_v2 where blade_chassis = 't') ,
sd as  (select device_fk, count(1) as software_discovered 						from view_softwareinuse_v1 group by 1),
svd as (select device_fk, count(1) as services_discovered 						from view_serviceinstance_v2 group by 1) ,
acd as (select device_fk, count(1) as application_components_discovered 		from view_appcomp_v1 group by 1) ,
md as  (select device_fk, count(1) as mounts_discovered , string_agg(distinct filesystem, ' | ') as mount_points 	from view_mountpoint_v1 group by 1),
pd as  (select device_fk, count(1) as parts_discovered 	from view_part_v1 group by 1),
ns as  (select device_fk, left(string_agg(distinct name, ' | '),32000) as network_shares 	from view_networkshare_v1 group by 1) 

/* Direct joins to DOQL views */

select 
        d.device_pk,
        d.name 								as device_name,
		d.last_edited 						as last_discovered,
		d.first_added,
		d.last_edited,
        d.virtual_host_device_fk,
        cd.start_at 						as chassis_u_location,
		cd.device_pk 						as chassis_device_id,
		cd.name 							as chassis_device_name,
		d.start_at 							as u_position,
        hv.vm_manager_device_fk,
        d.tags,
        d.in_service,
        d.service_level,
        d.type 								as device_type,
        coalesce(d.physicalsubtype, '') || coalesce(d.virtualsubtype, '') as device_subtype,
        coalesce(d.virtualsubtype, '') 		as virtual_subtype,
        d.serial_no 						as device_serial,
        d.virtual_host 						as virtual_host,
        d.network_device 					as network_device,
        d.os_architecture 					as os_architecture,
        Case When d.core_per_cpu is Null Then d.total_cpus
			Else d.total_cpus*d.core_per_cpu
		End 								as total_cores,
        d.total_cpus 						as total_cpus,
        d.core_per_cpu 						as core_per_cpu,
        d.threads_per_core 					as threads_per_core,
        d.cpu_speed 						as cpu_speed,
        case when d.ram <= 0 or d.ram is null then null			 
	      when d.ram_size_type = 'TB' then d.ram * 1024^2
          when d.ram_size_type = 'GB' then d.ram * 1024
	      when d.ram_size_type = 'MB' then d.ram 
          else null 
        end 								as ram_mb,
        v2.name 							as os_vendor,
        osc.category_name 					as os_category,
		d.os_name,
        Case d.os_version 
        	When '' Then d.os_name 
        	Else coalesce(d.os_name || ' - ' || d.os_version,d.os_name) 
        End 								as os_name_ver,
	/* Normalize the OS/Version   */
	    Case 
	    	When position('windows' IN lower(d.os_name)) > 0 or position('microsoft' IN lower(d.os_name)) > 0 Then d.os_name
			When position('esxi' IN lower(d.os_name)) = 1 Then coalesce(v2.name || ' ' || d.os_name,d.os_name) 
			When  d.os_version = '' Then d.os_name 
			Else coalesce(d.os_name || ' - ' || d.os_version,d.os_name) 
		End 								as os_name_norm,
        d.os_version 						as os_version,
        d.os_version_no 					as os_version_number,
        ose.eol 							as os_end_of_life,
        ose.eos 							as os_end_of_support,
		h.end_of_life_date 					as hdw_end_of_life,
		h.end_of_support_date 				as hdw_end_of_support,		
        v.name 								as manufacturer,
        h.name 								as hardware_model,
        d.asset_no 							as asset_number,
        d.bios_version 						as bios_version,
        d.bios_revision 					as bios_revision,
        d.bios_release_date 				as bios_release_date,
        sr.name 							as storage_room,
        b.name 								as building_name,
        b.address 							as building_address,
        m.name 								as room_name,
        r.row 								as row_name,
        r.name 								as rack_name,
        h.size 								as size_ru,
		coalesce(b.name, ci.location,'')  	as server_location,   
        ci.account,
        c.name 								as customer_department,
        cv.name 							as cloud_service_provider,
        ci.service_name 					as cloud_service_name,
        ci.instance_id 						as cloud_instance_id,
        ci.instance_name 					as cloud_instance_name,
        ci.instance_type 					as cloud_instance_type,
        ci.status 							as cloud_instance_status,
        ci.location 						as cloud_location,
        ci.notes 							as cloud_notes,
        sd.software_discovered,
        svd.services_discovered,
        acd.application_components_discovered,
        md.mounts_discovered,
        md.mount_points,
        pd.parts_discovered,
        ns.network_shares,
        cap.local_disk_count,
        cap.local_used_space_gb,
        cap.local_total_space_gb,
        cap.local_free_space_gb,
        cap.remote_disk_count,
        cap.remote_used_space_gb,
        cap.remote_total_space_gb,
        cap.remote_free_space_gb,
        ps.cpu_model,
        ps.cpu_manufacturer,
        ps.cpu_description,
        ds.disk_type,
        ps.parts_count,
        dns.dns_a_records,
        dns.dns_aaaa_records,		
    /* Yes/No fields */
        case when cd.device_pk is null then 'No' ELSE 'Yes' end as is_blade,
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
		End 								AS "os_group",			
        ipa.ip_count as number_ip_addresses_discovered,
        ipa.all_ips,
        ipa.all_labels,
     /*   Aggregates */
        counts.all_line_item_costs,
        counts.all_po_costs,
        counts.first_po_date,
        counts.last_po_date,
        counts.all_po_numbers,
        counts.all_cost_centers,
        counts.all_cost_center_descriptions
        
/* Direct joins to DOQL views */
from view_device_v2 d
left join view_hardware_v2 h							on d.hardware_fk 	= h.hardware_pk
left join view_vendor_v1 v 								on h.vendor_fk 		= v.vendor_pk
left join view_room_v1 sr 								on sr.room_pk 		= d.storage_room_fk   
left join view_rack_v1 r 								on r.rack_pk 		= d.calculated_rack_fk  
left join view_room_v1 m 								on m.room_pk 		= d.calculated_room_fk  
left join view_building_v1 b							on b.building_pk 	= d.calculated_building_fk  
left join view_os_v1 osc								on osc.os_pk		= d.os_fk
left join view_vendor_v1 v2 							on osc.vendor_fk 	= v2.vendor_pk
left join view_customer_v1 c 							on d.customer_fk 	= c.customer_pk

left join view_cloudinstance_v1 ci 						on ci.device_fk 	= d.device_pk
left join view_vendor_v1 cv 							on cv.vendor_pk 	= ci.vendor_fk
left join view_customer_v1 cu							on cu.customer_pk 	= d.customer_fk
left join view_device_v2 hv 							on d.virtual_host_device_fk = hv.device_pk
left join view_containerinstance_v1 coi 				on coi.device_fk 	= d.device_pk

/* Joining CTEs */
left join eoseol_summary ose 	on ose.device_pk 			= d.device_pk
left join ip_aggregate ipa 		on ipa.device_pk 			= d.device_pk
left join counts				on counts.device_pk 		= d.device_pk 
left join cd 					on d.host_chassis_device_fk = cd.device_pk
left join sd 					on d.device_pk 				= sd.device_fk
left join svd 					on d.device_pk 				= svd.device_fk
left join acd 					on d.device_pk 				= acd.device_fk
left join md 					on d.device_pk 				= md.device_fk
left join pd 					on d.device_pk 				= pd.device_fk
left join ns 					on d.device_pk 				= ns.device_fk
left join cap 					on d.device_pk 				= cap.device_fk
left join parts_summary ps 		on d.device_pk 				= ps.device_fk
left join disk_summary ds 		on d.device_pk 				= ds.device_fk
left join dns 					on d.device_pk 				= dns.device_fk
where d.network_device	= 'f'		
  and lower(d.type) <> 'cluster'
  and coi.container_id is null 
)
with data;

/*Column Comments for DBB views*/

COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.device_name IS '#custom#.Name of Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.device_pk IS '#custom#.Primary Key for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.first_added IS '#custom#.Date the Device was First added';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.last_discovered IS '#custom#.Date the Device was Last Edited';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.virtual_host_device_fk IS '#custom#.Foreign Key to Device Virtual Host for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.chassis_u_location IS '#custom#.Starting Slot location for Chassis';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.chassis_device_id IS '#custom#.Device ID for the Chassis';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.chassis_device_name IS '#custom#.Device name for Chassis';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.u_position IS '#custom#.Device u_position';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.vm_manager_device_fk IS '#custom#.Foreign Key to VM Manager for Device Extended Data';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.tags IS '#custom#.Tags for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.in_service IS '#custom#.In Service for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.service_level IS '#custom#.Name for Service Level';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.device_type IS '#custom#.Device Type of Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.device_subtype IS '#custom#.Subtype of Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.virtual_subtype IS '#custom#.Virtual Subtype for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.device_serial IS '#custom#.Serial # for Device MB/GB for CPU Memory HardDisk';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.virtual_host IS '#custom#.Virtual/Container Host for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.network_device IS '#custom#.Network Device for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_architecture IS '#custom#.Architecture Type for Device Operating System';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.total_cores IS '#custom#.Total # of cores (core_per_cpu * total_cpu)';  
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.core_per_cpu IS '#custom#.Cores/CPU for CPU Memory HardDisk';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.total_cpus IS '#custom#.Total CPUs for CPU Memory HardDisk';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.threads_per_core IS '#custom#.Threads/Core for CPU Memory HardDisk';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cpu_speed IS '#custom#.CPU Speed for CPU Memory HardDisk';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.ram_mb IS '#custom#.RAM in MB for CPU Memory HardDisk';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_vendor IS '#custom#.Name of OS vendor';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_category IS '#custom#.Category of the OS';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_name IS '#custom#.Name for Operating System';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_name_ver IS '#custom#.Name and version of the OS';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_name_norm IS '#custom#.Normalized name for the OS';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_version IS '#custom#.OS Version for Device Operating System';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_version_number IS '#custom#.OS Version # for Device Operating System';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_end_of_life IS '#custom#.End of Life Date for Operating System';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_end_of_support IS '#custom#.End of Service Date for Operating System';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.hdw_end_of_life IS '#custom#.End of Life Date for Device Hardware Model';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.hdw_end_of_support IS '#custom#.End of Support Date for Device Hardware Model';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.manufacturer IS '#custom#.Name for Manufacturer';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.hardware_model IS '#custom#.Name for Device Hardware Model';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.asset_number IS '#custom#.Asset # for Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.bios_version IS '#custom#.Version for BIOS Info';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.bios_revision IS '#custom#.Revision for BIOS Info';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.bios_release_date IS '#custom#.Release Date for BIOS Info';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.storage_room IS '#custom#.Name for Room';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.building_name IS '#custom#.Name for Building';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.building_address IS '#custom#.Address of the Building';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.room_name IS '#custom#.Name of Room';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.row_name IS '#custom#.Row for Rack';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.rack_name IS '#custom#.Name for Rack';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.size_ru IS '#custom#.Size for Device Hardware Model in U';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.server_location IS '#custom#.Instance Server Location for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.account IS '#custom#.Account or sub ID for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.customer_department IS '#custom#.Name for Customer or Department';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_service_provider IS '#custom#.Cloud Service Provider';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_service_provider IS '#custom#.Cloude Service Name';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_instance_id IS '#custom#.Identifier Key for Cloud instance ID for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_instance_name IS '#custom#.Instance name for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_instance_type IS '#custom#.Instance type for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_instance_status IS '#custom#.Status for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_location IS '#custom#.Instance Location for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cloud_notes IS '#custom#.Notes for Cloud Instance Information';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.software_discovered IS '#custom#.List of All software discovered and associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.services_discovered IS '#custom#.List of All services discovered and associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.application_components_discovered IS '#custom#.List of All application components associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.mounts_discovered IS '#custom#.List of all mounts associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.mount_points IS '#custom#.List of all mount points associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.parts_discovered IS '#custom#.List of parts discovered associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.network_shares IS '#custom#.List of netword shares associated with Device -Max 32000 characters';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.local_disk_count IS '#custom#.Count of local disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.local_used_space_gb IS '#custom#.Total USED Space on Local Disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.local_total_space_gb IS '#custom#.Total Space on Local Disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.local_free_space_gb IS '#custom#.Total FREE Space on Local Disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.remote_disk_count IS '#custom#.Count of Remote Disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.remote_used_space_gb IS '#custom#.Total USED Space on Remote Disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.remote_total_space_gb IS '#custom#.Total Space on Remote Disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.remote_free_space_gb IS '#custom#.Total FREE Space on Remote Disks';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cpu_model IS '#custom#.Model of CPU';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cpu_manufacturer IS '#custom#.Manufacturer of CPU';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.cpu_description IS '#custom#.Description of CPU';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.disk_type IS '#custom#.type of Disk';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.parts_count IS '#custom#.Count of Parts associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.dns_a_records IS '#custom#.DNS A Records associated with Device -Max 32000 characters';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.dns_aaaa_records IS '#custom#.DNS  AAAA Records associated with Device -Max 32000 characters';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.is_blade IS '#custom#.Is the Device a Blade Yes/No';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.is_hyperthreaded IS '#custom#.Is the Device Hyperthreaded Yes/No';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.is_os_discovered IS '#custom#.Is the OS of the Device Discovered Yes/No';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.is_software_discovered IS '#custom#.Is the Software of the Device Discovered Yes/No';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.is_network_device IS '#custom#.Is the Device a Network Device  Yes/No';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.is_cluster IS '#custom#.Is the Device a Cluster Yes/No';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.is_container IS '#custom#.Is the Device a Container Yes/No';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.os_group IS '#custom#.OS Group - Taken from os names';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.number_ip_addresses_discovered IS '#custom#.Count of IP addresses associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.all_ips IS '#custom#.List of all IPs associated with Device -Max 32000 characters';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.all_labels IS '#custom#.List of all Labels associated with Device -Max 32000 characters';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.all_line_item_costs IS '#custom#.Total of all line item costs associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.all_po_costs IS '#custom#.Total of all PO Total costs associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.first_po_date IS '#custom#.First date of POs';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.last_po_date IS '#custom#.Last date of POs';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.all_po_numbers IS '#custom#.List of all PO numbers associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.all_cost_centers IS '#custom#.List of all cost centers associated with Device';
COMMENT ON COLUMN d42_readonly.view_dbb_compute_v2.all_cost_center_descriptions IS '#custom#.List of all cost center descriptions associated with Device -Max 32000 characters';

 create index view_dbb_compute_v2_device_pk_idx 		on d42_readonly.view_dbb_compute_v2 (device_pk); 
 create index view_dbb_compute_v2_device_type_idx 		on d42_readonly.view_dbb_compute_v2 (lower(device_type) );
 create index view_dbb_compute_v2_service_level_idx 	on d42_readonly.view_dbb_compute_v2 (lower(service_level));
 create index view_dbb_compute_v2_virtual_host_device_fk_idx 	on d42_readonly.view_dbb_compute_v2 (virtual_host_device_fk);
 create index view_dbb_compute_v2_vm_manager_device_fk_idx 		on d42_readonly.view_dbb_compute_v2 (vm_manager_device_fk);
