/*
Virtual Density Report
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2 
  - fixed memory to normalize to MB
*/
 With target_records  as (
  Select
        hv.last_edited "Host Last Discovered"
        ,m.name "VM Manager Name"
        ,hv.name "Host Device Name"
        ,hv.os_name "Host OS Name" 
        ,hv.total_cpus * coalesce(hv.core_per_cpu, 1) "Host Cores"
        ,CASE When hv.ram_size_type = 'GB' 
              Then hv.ram*1024
              Else hv.ram 
        END "Host Ram"
        ,count(*) "VM Count Allocated"
        ,sum(d.total_cpus * coalesce(d.core_per_cpu)) "Total vCores Allocated"
        ,sum (CASE When d.ram_size_type = 'GB' 
              Then d.ram*1024
              Else d.ram 
			 END  )"Total Ram Allocated" 
        ,sum(Case When d.in_service = true Then 1 Else 0 End) "VM Count In Service"
        ,sum(Case When d.in_service = true Then d.total_cpus * coalesce(d.core_per_cpu) Else 0 End) "Total vCores In Service"
        ,sum(Case When d.in_service = true Then d.ram Else 0 End) "Total Ram In Service"
		,string_agg(d.name, ' | ') "VMs Allocated"
		,string_agg(Case When d.in_service = true Then d.name Else Null End, ' | ') "VMs In Service"
    From
        view_device_v2 d
        Inner Join view_device_v2 hv ON d.virtual_host_device_fk = hv.device_pk
        Left Join view_device_v2 m ON hv.vm_manager_device_fk = m.device_pk 
    Where 
        d.network_device = 'f'
    Group by
        hv.name
        ,hv.os_name
        ,m.name
        ,hv.in_service
        ,hv.total_cpus * coalesce(hv.core_per_cpu, 1)
        ,hv.ram
        ,hv.last_edited
		,hv.ram_size_type
	)
Select
    tr.*
    ,round(Case When tr."Host Cores" =  0 Then Null Else 100.0 * tr."Total vCores Allocated" / tr."Host Cores" End, 4) "Cores Percent Allocated"
    ,round(Case When tr."Host Ram" = 0 Then Null Else 100.0 * tr."Total Ram Allocated" / tr."Host Ram" End, 4) "Ram Percent Allocated"
    ,round(Case When tr."Host Cores" =  0 Then Null Else 100.0  * tr."Total vCores In Service" / tr."Host Cores" End, 4) "Cores Percent In Service"
    ,round(Case When tr."Host Ram" = 0 Then Null Else 100.0 * tr."Total Ram In Service" / tr."Host Ram" End, 4) "Ram Percent In Service"
From
    target_records tr