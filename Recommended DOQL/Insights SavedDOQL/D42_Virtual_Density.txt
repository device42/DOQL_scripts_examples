/*
Virtual Density Report
*/
Select
    a.*
    ,round(Case When a."Host Cores" =  0 Then Null Else 100.0 * a."Total vCores Allocated" / a."Host Cores" End, 4) "Cores Percent Allocated"
    ,round(Case When a."Host Ram" = 0 Then Null Else 100.0 * a."Total Ram Allocated" / a."Host Ram" End, 4) "Ram Percent Allocated"
    ,round(Case When a."Host Cores" =  0 Then Null Else 100.0  * a."Total vCores In Service" / a."Host Cores" End, 4) "Cores Percent In Service"
    ,round(Case When a."Host Ram" = 0 Then Null Else 100.0 * a."Total Ram In Service" / a."Host Ram" End, 4) "Ram Percent In Service"
From
    (    
    Select
        hv.last_edited "Host Last Discovered"
        ,m.name "VM Manager Name"
        ,hv.name "Host Device Name"
        ,hv.os_name "Host OS Name" 
        ,hv.cpucount * coalesce(hv.cpucore, 1) "Host Cores"
        ,hv.ram "Host Ram"
        ,count(*) "VM Count Allocated"
        ,sum(d.cpucount * coalesce(d.cpucore)) "Total vCores Allocated"
        ,sum(d.ram) "Total Ram Allocated"
        ,sum(Case When d.in_service = true Then 1 Else 0 End) "VM Count In Service"
        ,sum(Case When d.in_service = true Then d.cpucount * coalesce(d.cpucore) Else 0 End) "Total vCores In Service"
        ,sum(Case When d.in_service = true Then d.ram Else 0 End) "Total Ram In Service"
		,string_agg(d.name, ' | ') "VMs Allocated"
		,string_agg(Case When d.in_service = true Then d.name Else Null End, ' | ') "VMs In Service"
    From
        view_device_v1 d
        Inner Join view_device_v1 hv on d.virtual_host_device_fk = hv.device_pk
        Left Join view_device_v1 m on hv.vm_manager_device_fk = m.device_pk 
    Where 
        d.network_device = 'f'
    Group by
        hv.name
        ,hv.os_name
        ,m.name
        ,hv.in_service
        ,hv.cpucount * coalesce(hv.cpucore, 1)
        ,hv.ram
        ,hv.last_edited
    ) a 