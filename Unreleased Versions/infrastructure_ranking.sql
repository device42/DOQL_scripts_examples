 /*  Move Group - Ranking
     03-24-21 - Initial Report
*/
/*  Inline view of target data required (CTE - Common Table Expression) */
/* Get Affinity group devices to know what are know and with those that impact only  */
/* 											*/
 With Recursive
	target_device_data  as (
  /* get CPU type from hdw tbl  */
	Select 
        d.device_pk d_device_pk
        ,d.name hostname
		,d.type d_type
		,d.tags
		,d.service_level
		,d.virtualsubtype d_virtualsubtype
		,d.os_name
		,d.os_version
		,d.total_cpus
		,d.core_per_cpu
		,d.threads_per_core		
		,d.calculated_building_fk
		,d.hardware_fk
        ,Date(d.first_added) "Date Added"
        ,Case 
			When d.ram <= 0 or d.ram Is Null Then Null			 
		    When d.ram_size_type = 'MB' Then round((d.ram / 1024)::decimal,2)
			When d.ram_size_type = 'GB' Then d.ram  			 
            Else Null
		End ram_norm_gb
       From 
            view_device_v2 d
		Left Join view_containerinstance_v1 coi ON coi.device_fk = d.device_pk
		Where d.network_device = 'f' 
			and coi.container_id is Null	/* remove network devices and containers */
			and lower(d.type) Not IN ('cluster','unknown')
 ),
 /* Let's reduce the amount RU records needed  */
	ru_data_filter  as (
	Select 
        ru.*
	From view_rudata_v2 ru
		Where lower(sensor_type) IN ('cpu','disk','memory') and metric_id IN ('1','5') and measure_type_id IN ('1','2','3','4','15','16') and timeperiod_id IN ('3')
		/* and (sensor != '')   Temp take this out.. Will put back later..*/
	),
 /* get RU memory usage 95th used over the last 30 days; 95th percentile   */
	ru_data_mem_95  as (
		Select 
			ru.device_fk ru_device_fk
			,max(ru.value) ru_value_mem
	From ru_data_filter  ru
		Where lower(sensor_type) = 'memory' and metric_id = '5' and timeperiod_id = '3'
		Group by 1
	),	
 /* get RU CPU usage 95th used over the last 30 days; 95th percentile  */
	ru_data_cpu_95  as (
		Select 
			ru.device_fk ru_device_fk
			,max(ru.value) ru_value_cpu
	From ru_data_filter  ru
		Where lower(sensor_type) = 'cpu' and metric_id = '5' and timeperiod_id = '3'
		Group by 1
	),
 /* get RU Read IOPS usage 95th used over the last 30 days; 95th percentile   */
	ru_data_riops_95  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_riops
    From  
		(Select ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '3' and metric_id = '5' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1
	),		
 /* get RU Write IOPS usage 95th used over the last 30 days; 95th percentile   */
	ru_data_wiops_95  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_wiops
    From  
		(Select ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '4' and metric_id = '5' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1	
	),
 /* get RU Disk Total 95th used over the last 30 days; 95th percentile   */
	ru_data_dtotal_95  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_total
    From  
		(Select 
			ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '15' and metric_id = '5' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1
	),		
 /* get RU Disk Used 95th over the last 30 days; 95th percentile   */
	ru_data_dused_95  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_used
    From  
		(Select 
			ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '16' and metric_id = '5' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1
	),	
 /* get RU memory usage max used over the last 30 days - Max Value  */
	ru_data_mem_max  as (
	Select 
        ru.device_fk ru_device_fk
		,max(ru.value) ru_value_mem
	From ru_data_filter ru
		Where lower(sensor_type) = 'memory' and metric_id = '1' and timeperiod_id = '3'
		Group by 1
	),	
 /* get RU CPU usage max used over the last 30 days  - Max Value */
	ru_data_cpu_max as (
	Select 
        ru.device_fk ru_device_fk
		,max(ru.value) ru_value_cpu
	From ru_data_filter ru
		Where lower(sensor_type) = 'cpu' and metric_id = '1' and timeperiod_id = '3'
		Group by 1
	),
 /* get RU Read IOPS usage max used over the last 30 days; Max Value   */
	ru_data_riops_max  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_riops
    From  
		(Select 
			ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '3' and metric_id = '1' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1
	),		
 /* get RU Write IOPS usage max used over the last 30 days; Max Value   */
	ru_data_wiops_max  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_wiops
    From  
		(Select 
			ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '4' and metric_id = '1' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1
	),
 /* get RU Disk Total max used over the last 30 days; Max Value   */
	ru_data_dtotal_max  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_total
    From  
		(Select 
			ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '15' and metric_id = '1' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1
	),		
 /* get RU Disk Used max over the last 30 days; Max Value   */
	ru_data_dused_max  as (
	Select  
		ru1.device_fk ru_device_fk
		,sum(ru1.max_value) ru_value_used
    From  
		(Select 
			ru.sensor
			,ru.device_fk 
			,max(ru.value) max_value
		From ru_data_filter ru
		Where lower(sensor_type) = 'disk' and measure_type_id = '16' and metric_id = '1' and timeperiod_id = '3'
		Group by 1, 2) ru1
	Group by 1
	),	
 /* Set memory % based upon the data captured   */
	ru_data_mem_perc_95  as (
	Select 
        tdd.d_device_pk
		,round((100*(ru_value_mem/1024)/tdd.ram_norm_gb)::integer,2) mem_perc_95
	From target_device_data  tdd
		Left Join ru_data_mem_95 m95 ON m95.ru_device_fk = tdd.d_device_pk		
	),	
 /* Set memory % based upon the data captured   */
	ru_data_mem_perc_max  as (
	Select 
        tdd.d_device_pk
		,round((100*(ru_value_mem/1024)/tdd.ram_norm_gb)::integer,2) mem_perc_max
	From target_device_data  tdd
		Left Join ru_data_mem_max mm ON mm.ru_device_fk = tdd.d_device_pk	
	),
 /* Pull all the RU data into a single row per device   */
	ru_data_consolidated as (
	Select Distinct
		ru1.*
		,count (*) over () ru_cnt
		,round(100.0* rank() over(order by ru1.cpu_95)/nullif(count (*) over (),0)::decimal,2) rank_cpu_95
		,round(100.0 * rank() over(order by ru1.cpu_max)/nullif(count (*) over (),0)::decimal,2)rank_cpu_max
		,round(100.0 * rank() over(order by ru1.mem_95)/nullif(count (*) over (),0)::decimal,2) rank_mem_95	
		,round(100.0 * rank() over(order by ru1.mem_max)/nullif(count (*) over (),0)::decimal,2) rank_mem_max 
		,round(100.0 * rank() over(order by ru1.iops_95)/nullif(count (*) over (),0)::decimal,2) rank_iops_95	
		,round(100.0 * rank() over(order by ru1.iops_max)/nullif(count (*) over (),0)::decimal,2) rank_iops_max 
		,round(100.0 * rank() over(order by ru1.dtotal_95)/nullif(count (*) over (),0)::decimal,2) rank_dtotal_95	
		,round(100.0 * rank() over(order by ru1.dtotal_max)/nullif(count (*) over (),0)::decimal,2) rank_dtotal_max 
		,round(100.0 * rank() over(order by ru1.dused_95)/nullif(count (*) over (),0)::decimal,2) rank_dused_95	
		,round(100.0 * rank() over(order by ru1.dused_max)/nullif(count (*) over (),0)::decimal,2) rank_dused_max 	 
	From 
		(Select 
			tdd.d_device_pk 
			,coalesce(rdc95.ru_value_cpu,0) cpu_95
			,coalesce(rdcmax.ru_value_cpu,0) cpu_max	
			,coalesce(rdm95.mem_perc_95,0) mem_95
			,coalesce(rdmmax.mem_perc_max,0) mem_max
			,coalesce(rdr95.ru_value_riops,0)+ coalesce(rdw95.ru_value_wiops,0) iops_95
			,coalesce(rdrmax.ru_value_riops,0)+ coalesce(rdwmax.ru_value_wiops,0) iops_max		
			,coalesce(rddt95.ru_value_total,0) dtotal_95	
			,coalesce(rddu95.ru_value_used,0) dused_95
			,coalesce(rddtmax.ru_value_total,0) dtotal_max			
			,coalesce(rddumax.ru_value_used,0) dused_max
		From target_device_data tdd
			Left Join ru_data_cpu_95 rdc95 ON rdc95.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_cpu_max rdcmax ON rdcmax.ru_device_fk = tdd.d_device_pk	
			Left Join ru_data_mem_perc_95 rdm95 ON rdm95.d_device_pk = tdd.d_device_pk	 
			Left Join ru_data_mem_perc_max rdmmax ON rdmmax.d_device_pk = tdd.d_device_pk
			Left Join ru_data_riops_95 rdr95 ON rdr95.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_wiops_95 rdw95 ON rdw95.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_dtotal_95 rddt95 ON rddt95.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_dused_95 rddu95 ON rddu95.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_riops_max rdrmax ON rdrmax.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_wiops_max rdwmax ON rdwmax.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_dtotal_max rddtmax ON rddtmax.ru_device_fk = tdd.d_device_pk
			Left Join ru_data_dused_max rddumax ON rddumax.ru_device_fk = tdd.d_device_pk
		) ru1
	Where cpu_95 > 0 or cpu_max > 0 or mem_95 > 0 or mem_max > 0 or iops_95 > 0 or iops_max > 0 or dtotal_95 > 0 or dtotal_max > 0 or dused_95 > 0 or dused_max > 0
	),
/* Get the RU/Reg CRE data; RU info taking precedence */
    target_cre_data as (
    Select 
        reg.device_fk cre_device_fk
		,ru.tenancy ru_tenancy
		,ru.recommendation_type ru_recommendation_type
		,ru.recommended_instance ru_recommended_instance
		,ru.matching_os ru_matching_os
		,reg.tenancy reg_tenancy
		,reg.recommendation_type reg_recommendation_type
		,reg.recommended_instance reg_recommended_instance
		,reg.matching_os reg_matching_os		
		,coalesce(ru.tenancy,reg.tenancy, '') tenancy
		,coalesce(ru.recommendation_type,reg.recommendation_type,'') recommendation_type
		,coalesce(ru.recommended_instance,reg.recommended_instance,'') recommended_instance
		,coalesce(ru.matching_os,reg.matching_os,'') matching_os		
		,coalesce(ru.row_color,reg.row_color,'') recommended_color
		,Case When (reg.recommended_instance = '' and ru.recommended_instance = '') or lower(reg.row_color) IN ('yellow','red') Then 'RePlatform'
			  Else 'ReHost'
		End "R-Lane Classification"
    From view_credata_v2 reg
		Left Join view_credata_v2 ru on reg.device_fk = ru.device_fk and Lower(ru.vendor) IN ('aws') and Lower(ru.recommendation_type) = 'ru' 
	Where 
     Lower(reg.vendor) IN ('aws') and Lower(reg.recommendation_type) = 'regular' 
	),
 /* get Appcomp info to see complexity  
   	DOQL for App Comp's and the category       
						                  */
	target_appcomp_data  as (  
	Select Distinct
		ac.device_fk
		,ac.application_category_name
		,count(ac.appcomp_pk) Over (Partition by ac.device_fk, ac.application_category_name) appcomp_cnt
	From view_appcomp_v1 ac
	Where lower(ac.application_category_name) IN ('database','web server','application layer')
	),
 /* get Appcomp info  
   	DOQL for App Comp's and the category       
						                  */
	target_appcomp_data_pvt as ( 
	Select 
		acc.*
 		,count (*) over ()  overall_appcomp_total
		,round(100.0 * rank() over(order by acc."Total AppComp Count")/nullif(count (*) over () ,0)::decimal,2) rank_appcomp
		,Case When wb_cnt_str = '' and ap_cnt_str = '' and db_cnt_str = '' Then ''
			When wb_cnt_str != '' and ap_cnt_str != '' and db_cnt_str != '' Then concat(wb_cnt_str ,',', ap_cnt_str ,',', db_cnt_str)
			When wb_cnt_str != '' and ap_cnt_str != '' Then concat(wb_cnt_str ,',', ap_cnt_str)
			When wb_cnt_str != '' and db_cnt_str != '' Then concat(wb_cnt_str ,',', db_cnt_str)
			When ap_cnt_str != '' and db_cnt_str != '' Then concat(ap_cnt_str ,',', db_cnt_str)
			When wb_cnt_str != '' Then wb_cnt_str 			
			When ap_cnt_str != '' Then ap_cnt_str
			Else db_cnt_str		
		End app_comp_str
		,wb_cnt + ap_cnt + db_cnt  tot_appcomp_unq_cnt
	  From 
	   (Select
		tdd.d_device_pk
		,tad1.appcomp_cnt "Web Server Count"
		,tad2.appcomp_cnt "App Layer Count"
		,tad.appcomp_cnt "DB Count"
		,Case When tad1.appcomp_cnt > 0 Then 1 Else 0 End wb_cnt
		,Case When tad2.appcomp_cnt > 0 Then 1 Else 0 End ap_cnt
		,Case When tad.appcomp_cnt  > 0 Then 1 Else 0 End db_cnt
		,Case When tad1.appcomp_cnt > 0 Then concat('Web(',tad1.appcomp_cnt,')') Else '' End wb_cnt_str
		,Case When tad2.appcomp_cnt > 0 Then concat('App(',tad2.appcomp_cnt,')') Else '' End ap_cnt_str
		,Case When tad.appcomp_cnt  > 0 Then concat('DB(',tad.appcomp_cnt,')') Else '' End db_cnt_str				
		,coalesce(tad.appcomp_cnt,0) + coalesce(tad1.appcomp_cnt,0) + coalesce(tad2.appcomp_cnt,0) "Total AppComp Count"
	From target_device_data tdd
		Left Join target_appcomp_data tad ON  tad .device_fk = tdd.d_device_pk and lower(tad.application_category_name) IN ('database')
		Left Join target_appcomp_data tad1 ON tad1.device_fk = tdd.d_device_pk and lower(tad1.application_category_name) IN ('web server')
		Left Join target_appcomp_data tad2 ON tad2.device_fk = tdd.d_device_pk and lower(tad2.application_category_name) IN ('application layer')
	) acc
	Where acc."Total AppComp Count" != 0
	),
 /* Physical device extract  		
 */	
 /* Get target data       */
	target_phy_records as (
	Select Distinct
		fdev.d_device_pk 
		,fdev.hostname dev_name
		,fdev.total_cpus
		,fdev.core_per_cpu
		,fdev.threads_per_core
		,fdev.ram_norm_gb "Memory GB"
		,concat(fdev.os_name, ' ', fdev.os_version) "Operating System"  		 
		,bd.name "Location"
		,vd.name "Make"
		,hd.name "Model"
	 From (Select 
			tdd.* 
		 From target_device_data tdd
		 Where lower(tdd.d_type) IN ('physical') /* Physical */
		 ) fdev 
	 Left Join view_building_v1 bd on bd.building_pk = fdev.calculated_building_fk
	 Left Join view_hardware_v2 hd on hd.hardware_pk = fdev.hardware_fk 
     Left Join view_vendor_v1 vd on vd.vendor_pk = hd.vendor_fk
  ),
   /* Inline view of Parts Data Summary   */	 
	parts_summary as (
    Select Distinct
        pt.device_fk
        ,string_agg(distinct pm.name, ',') "CPU Model"
        ,string_agg(distinct pmv.name, ',') "CPU Manufacturer"
		,string_agg(distinct pt.description, ',') "CPU String"
    From view_part_v1 pt
        Join view_partmodel_v1 pm on pm.partmodel_pk = pt.partmodel_fk and pm.type_id = '1'
        Left Join view_vendor_v1 pmv on pmv.vendor_pk = pm.vendor_fk
    Group by pt.device_fk
    Having string_agg(pm.name, ',') is not null and string_agg(pmv.name, ',') is not null
  ),   
   /* Inline view of Disk Data Summary   */	 
	disk_summary as (
    Select Distinct
        pt.device_fk
        ,string_agg(distinct pm.modelno, '|') "Disk Type"
    From 
        view_part_v1 pt
        Join view_partmodel_v1 pm on pm.partmodel_pk = pt.partmodel_fk and pm.type_id = '3'
    Group by pt.device_fk
    Having string_agg(pm.modelno, '|') is not null
  ),
 /*    
  - Physical Extract Report                                         */
	phy_device_summary as (
	Select Distinct
		tr.d_device_pk
		,tr.dev_name
		,tr.total_cpus
		,tr.core_per_cpu
		,tr.threads_per_core
		,tr."Memory GB"
		,pt."CPU String"
		,pt."CPU Manufacturer"
		,pt."CPU Model"
		,tr."Operating System"
/*		,tr."Remote Storage Size GB" 
		,'SSD/HDD' "Remote Storage Type"
		,tr."Local Storage Size GB"
		,Case When tr."Local Storage Size GB" = 0
		   Then ' '
		   When strpos(lower(dk."Disk Type"),'ssd') > 0
		   Then 'SSD'
		   Else 'HDD' 
		End "Local Storage Type"
*/
		,tr."Location"
		,tr."Make"
		,tr."Model" 	
	From target_phy_records tr
		  Left Join parts_summary pt on pt.device_fk = tr.d_device_pk  
		  Left Join disk_summary dk on dk.device_fk = tr.d_device_pk 
		  Order by tr.dev_name ASC
  ),
 /*    
  - Virtual Extract Report                                         */
	target_virt_count  as (
	Select
		vmm.name "VM Manager"
	  /*  Assemble Host information   */
		,h.device_pk h_device_pk
		,count (g.device_pk) Over (Partition by h.device_pk) guest_count
		,h.name "Host Device Name"
		,h.type "Host Hardware Type"
		,h.os_name "Host OS Name"
		,h.os_architecture "Host OS Arch"
		,h.os_version "Host OS Version"
		,Case 
			When h.threads_per_core > 1 Then 'YES'
			Else 'NO'
		End "Host Hyperthreaded?"
		,h.total_cpus "Host CPU Count"
		,h.core_per_cpu "Host CPU Cores"
		,h.cpu_speed "Host CPU Speed GHz"
		,Case 
			When h.ram_size_type = 'GB' Then h.ram
			Else round((h.ram / 1024)::decimal,2)
		End "Host RAM GB"	
	  /* Additional Host info      */
		,h.threads_per_core "Host Core Threads"
	  /* Assemble Guest information   */
		,g.device_pk g_device_pk
		,g.name "Guest Name"
		,g.os_name "Guest OS Name"
		,g.in_service "Guest In Service?"
		,g.os_architecture "Guest OS Arch"
		,g.os_version "Guest OS Version"
		,Case 
			When g.threads_per_core > 1 Then 'YES'
			Else 'NO'
		End "Guest Hyperthreaded?"
		,g.total_cpus "Guest CPU Count"
		,g.core_per_cpu "Guest CPU Cores"
		,Case 
			When g.ram_size_type = 'GB' Then g.ram
			Else round((g.ram / 1024)::decimal,2)
		End "Guest RAM GB"		
		,g.hard_disk_count "Guest Disk Count"
		,g.datastores "Datastores"
		,Case 
			When c.parent_device_fk is Null Then 'N' 
			Else 'Y' 
		End "Guest Clustered"
		,c.parent_device_name "Cluster Name"
	 /* Additonal info available - for Hosts and Guests */
		,g.threads_per_core "Guest Core Threads"
		,h.last_edited "Host Last Update"
		,g.last_edited "Guest Last Update"
/*   Get the Hosts that have virtual_host flag on - sub-query */
    From (Select * From view_device_v2 hsq 
            Where hsq.virtual_host and hsq.os_name NOT IN ('f5','netscaler') and Not hsq.network_device and lower(hsq.type)Not IN ('cluster'))h
/*   Get the virtual devices that are not part of the network OSes - sub-query*/            
	Left Join (Select * From view_device_v2 gsq 
            Where gsq.type_id = '3') g  ON h.device_pk = g.virtual_host_device_fk
    Left Join view_device_v2 vmm ON vmm.device_pk = h.vm_manager_device_fk
    Left Join view_devices_in_cluster_v1 c ON c.child_device_fk = h.device_pk  
    Order by h.name ASC
 ),
 /*    
  - Virtual Extract Report                                         */
	target_virt_records  as (
	Select
	  /* Assemble Guest information   */
		g.device_pk g_device_pk
		,g.name "Guest Name"
		,g.os_name "Guest OS Name"
		,g.in_service "Guest In Service?"
		,g.os_architecture "Guest OS Arch"
		,g.os_version "Guest OS Version"
		,Case 
			When g.threads_per_core > 1 Then 'YES'
			Else 'NO'
		End "Guest Hyperthreaded?"
		,g.total_cpus "Guest CPU Count"
		,g.core_per_cpu "Guest CPU Cores"
		,Case 
			When g.ram_size_type = 'GB' Then g.ram
			Else round((g.ram / 1024)::decimal,2)
		End "Guest RAM GB"		
		,g.hard_disk_count "Guest Disk Count"
		,g.datastores "Datastores"

	 /* Additonal info available - for Hosts and Guests */
		,g.threads_per_core "Guest Core Threads"
		,g.last_edited "Guest Last Update"
/*   Get the Hosts that have virtual_host flag on - sub-query */
     From view_device_v2 g 
        Where g.type_id = '3'
		Order by g.device_pk ASC
 ),
 /*    
  - Service Dependencies Report                                         */
	target_sd_records  as (
	Select Distinct
		ld.d_device_pk ld_device_pk
		,sum(sc.netstat_active_samples) over (Partition by ld.d_device_pk)  sc_activity
		,sc2.listener_cnt	
	From
		view_servicecommunication_v2 sc
		Join target_device_data ld ON ld.d_device_pk = sc.listener_device_fk
		Left Join target_device_data cd ON cd.d_device_pk = sc.client_device_fk
		Left Join (Select Distinct ct2.listener_device_fk, count (*)  over (Partition by ct2.listener_device_fk) listener_cnt From (Select Distinct ct.listener_device_fk, ct.client_ip From view_servicecommunication_v2 ct ) ct2) sc2 ON sc2.listener_device_fk = sc.listener_device_fk
	Where
		sc.client_ip != '127.0.0.1'
		and sc.client_ip != '::1'
/*		and sc.netstat_active_samples::text != '' */
	),
/*    
  - Service Dependencies Ranking                                         */
	target_sd_rank  as (
	Select Distinct
		rr.ld_device_pk
		,rr.sc_activity
		,rr.listener_cnt
		,round(100.0* rank() over(order by rr.sc_activity)/nullif(count (*) over (),0)::decimal,2) rank_sc_activity
		,round(100.0* rank() over(order by rr.listener_cnt)/nullif(count (*) over (),0)::decimal,2) rank_listener_cnt			
	From
		(Select 
			tsrd.ld_device_pk
			,coalesce (tsrd.sc_activity,0) sc_activity
			,tsrd.listener_cnt
		From target_sd_records tsrd) rr
	),	
 /* Recursive CTEs
   Get all the affinity data for the impact charts   
				- impact report							*/
    impact AS ( 
    Select da1.*,
           ag.primary_device_fk, ag.name, ag.affinitygroup_pk, ag.report_type_id, ag.report_type_name, ag.last_processed ag_last_processed
    From view_affinitygroup_v2 ag
    Join view_deviceaffinity_v2 AS da1 on ag.primary_device_fk = da1.dependency_device_fk
                                      AND da1.effective_from <= ag.last_processed
                                      AND (da1.effective_to IS NULL OR da1.effective_to > current_date) 
    Where ag.report_type_id = 0
    UNION 
    Select da2.*,
           dep.primary_device_fk, dep.name, dep.affinitygroup_pk, dep.report_type_id, dep.report_type_name, dep.ag_last_processed
    From impact AS dep
         Join view_deviceaffinity_v2 da2 on dep.dependent_device_fk = da2.dependency_device_fk
                                        AND da2.effective_from <= dep.ag_last_processed
                                        AND (da2.effective_to IS NULL OR da2.effective_to > current_date) 
),
/* just get counts of rows per affinity group   */
    target_impact_count AS (
	Select Distinct
		impc.affinitygroup_pk
		,impc.primary_device_fk
		,count (*) over (Partition by impc.primary_device_fk) aff_device_cnt		
	 From impact impc
	 ),
/* Rank the affinity group values  */
    target_impact_rank AS (
	Select Distinct
		tic.*
		,count (*) over () affin_rec_cnt
		,round(100 * rank() over(order by coalesce(tic.aff_device_cnt,0))/nullif(count (*) over (),0)::decimal,2 ) rank_aff_device_cnt2			
	 From target_impact_count tic
	 ) 
/* Join up of all the records and Final report out   */ 
	Select Distinct
        tdd.d_device_pk
        ,tdd.hostname
		,initcap(tdd.d_type) d_type
		,tdd.d_virtualsubtype
		,tdd.tags
		,Case When tdd.tags = '' Then 0 
			Else (length(tdd.tags) - length(replace(tdd.tags, ',', '')) )::int  / length(',') + 1
		End no_tags
		,tdd.service_level
		,tvrh.guest_count
		,coalesce(pds.total_cpus, tvrg."Guest CPU Count", 0) total_cpus
		,coalesce(pds.core_per_cpu, tvrg."Guest CPU Cores",0) cores_per_cpu
		,coalesce(pds.threads_per_core,1) cpu_threads
		,coalesce(pds."Memory GB", tvrg."Guest RAM GB") "Memory GB"
		,pds."CPU String"
		,pds."CPU Manufacturer"
		,pds."CPU Model"
		,coalesce(pds."Operating System",tvrg."Guest OS Name") "Operating System"
		,pds."Location"
		,pds."Make"
		,pds."Model"
		,Case When tcd.recommended_color = 'normal' Then 'Matching OS'
			When tcd.recommended_color = 'yellow' Then 'Change OS'
			When tcd.recommended_color = 'red' Then 'No Match'
			Else ''
		End "Row Color"		
		,tcd.recommended_instance "Recommended Instance"
		,tcd.matching_os "Suggested OS"
		,coalesce(tcd."R-Lane Classification",'RePlatform')  "R-Lane Classification"
 		,Case When rdc.rank_cpu_95 < 34 Then 'Low'
			When rdc.rank_cpu_95 >= 34  and rdc.rank_cpu_95 < 67 Then 'Medium'
			When rdc.rank_cpu_95 > 67 Then 'High'
			Else ''
		End "cpu_95_level"	
 		,Case When rdc.rank_cpu_max < 34 Then 'Low'
			When rdc.rank_cpu_max >= 34  and rdc.rank_cpu_max < 67 Then 'Medium'
			When rdc.rank_cpu_max > 67 Then 'High'
			Else ''
		End "cpu_max_level"	
 		,Case When rdc.rank_mem_95 < 34 Then 'Low'
			When rdc.rank_mem_95 >= 34  and rdc.rank_mem_95 < 67 Then 'Medium'
			When rdc.rank_mem_95 > 67 Then 'High'
			Else ''
		End "mem_95_level"	
 		,Case When rdc.rank_mem_max < 34 Then 'Low'
			When rdc.rank_mem_max >= 34  and rdc.rank_mem_max < 67 Then 'Medium'
			When rdc.rank_mem_max > 67 Then 'High'
			Else ''
		End "mem_max_level"	
 		,Case When rdc.rank_iops_95 < 34 Then 'Low'
			When rdc.rank_iops_95 >= 34  and rdc.rank_iops_95 < 67 Then 'Medium'
			When rdc.rank_iops_95 > 67 Then 'High'
			Else ''
		End "iops_95_level"	
 		,Case When rdc.rank_iops_max < 34 Then 'Low'
			When rdc.rank_iops_max >= 34  and rdc.rank_iops_max < 67 Then 'Medium'
			When rdc.rank_iops_max > 67 Then 'High'
			Else ''
		End "iops_max_level"	
 		,Case When rdc.rank_dtotal_95 < 34 Then 'Low'
			When rdc.rank_dtotal_95 >= 34  and rdc.rank_dtotal_95 < 67 Then 'Medium'
			When rdc.rank_dtotal_95 > 67 Then 'High'
			Else ''
		End "dtotal_95_level"	
 		,Case When rdc.rank_dtotal_max < 34 Then 'Low'
			When rdc.rank_dtotal_max >= 34  and rdc.rank_dtotal_max < 67 Then 'Medium'
			When rdc.rank_dtotal_max > 67 Then 'High'
			Else ''
		End "dtotal_max_level"	
 		,Case When rdc.rank_dused_95 < 34 Then 'Low'
			When rdc.rank_dused_95 >= 34  and rdc.rank_dused_95 < 67 Then 'Medium'
			When rdc.rank_dused_95 > 67 Then 'High'
			Else ''
		End "dused_95_level"	
 		,Case When rdc.rank_dused_max < 34 Then 'Low'
			When rdc.rank_dused_max >= 34  and rdc.rank_dused_max < 67 Then 'Medium'
			When rdc.rank_dused_max > 67 Then 'High'
			Else ''
		End "dused_max_level"	
 		,Case When tsr.rank_sc_activity < 34 Then 'Low'
			When tsr.rank_sc_activity >= 34 and tsr.rank_sc_activity < 67 Then 'Medium'
			When tsr.rank_sc_activity > 67 Then 'High'
			Else ''
		End "sc_activity_level"	
 		,Case When tsr.rank_listener_cnt < 34 Then 'Low'
			When tsr.rank_listener_cnt >= 34  and tsr.rank_listener_cnt < 67 Then 'Medium'
			When tsr.rank_listener_cnt > 67 Then 'High'
			Else ''
		End "sc_interface_level"	
 		,Case When tadp.tot_appcomp_unq_cnt = 1 Then 'Low'
			When tadp.tot_appcomp_unq_cnt = 2 Then 'Medium'
			When tadp.tot_appcomp_unq_cnt = 3 Then 'High'
			Else ''
		End "rank_appcomp_level"	
 		,Case When tir.rank_aff_device_cnt2 < 34 Then 'Low'
			When tir.rank_aff_device_cnt2 >= 34  and tir.rank_aff_device_cnt2 < 67 Then 'Medium'
			When tir.rank_aff_device_cnt2 > 67 Then 'High'
			Else ''
		End "rank_aff_device_cnt2_level"		
/*		,tsr.ld_device_pk
		,coalesce(tsr."Client Device",split_part(host(tsr."Client IP"),'/',1),'') client_entity
*/		,tsr.rank_sc_activity
		,tsr.rank_listener_cnt		
		,tsr.sc_activity
		,tsr.listener_cnt	
		,tadp."Web Server Count"
		,tadp."App Layer Count"
		,tadp."DB Count"		
		,tadp."Total AppComp Count"
		,tadp.overall_appcomp_total
		,tadp.tot_appcomp_unq_cnt
		,tadp.app_comp_str
		,tadp.rank_appcomp		
		,rdc.cpu_95
		,rdc.cpu_max	
		,rdc.mem_95
		,rdc.mem_max
 		,rdc.rank_cpu_95
		,rdc.rank_cpu_max
		,rdc.rank_mem_95	
		,rdc.rank_mem_max 
		,rdc.rank_iops_95	
		,rdc.rank_iops_max 
		,rdc.rank_dtotal_95	
		,rdc.rank_dtotal_max 
		,rdc.rank_dused_95	
		,rdc.rank_dused_max 		 		
		,coalesce(tir.aff_device_cnt,0) affin_cnt
		,tir.affin_rec_cnt
		,tir.rank_aff_device_cnt2
		,Case When tcd.recommended_color = 'normal' Then 0
			When tcd.recommended_color = 'yellow' Then 1
			When tcd.recommended_color = 'red' Then 2
			Else 3
		End rc_sort		
/* get basic device data					    */
	From target_device_data tdd
	Left Join phy_device_summary pds ON pds.d_device_pk = tdd.d_device_pk
	Left Join target_virt_count tvrh ON tvrh.h_device_pk = tdd.d_device_pk
	Left Join target_virt_count tvcnt ON tvcnt.g_device_pk = tdd.d_device_pk
	Left Join target_virt_records tvrg ON tvrg.g_device_pk = tdd.d_device_pk	
/*  Get RU data and CRE data 					*/
	Left Join ru_data_consolidated rdc ON rdc.d_device_pk = tdd.d_device_pk	
	Left Join target_cre_data tcd ON cre_device_fk = tdd.d_device_pk
/* Get SD, appcomp and AG..  					*/	
	Left Join target_sd_rank tsr ON tsr.ld_device_pk = tdd.d_device_pk
	Left Join target_appcomp_data_pvt tadp ON tadp.d_device_pk = tdd.d_device_pk
	Left Join target_impact_rank tir ON tir.primary_device_fk = tdd.d_device_pk
	Order by d_type ASC, rc_sort ASC, tdd.d_device_pk ASC