select
    a.*,
    round(case when a."Host Cores" =  0 then null else 100.0 * a."Total vCores Allocated" / a."Host Cores" end, 4) "Cores Percent Allocated",
    round(case when a."Host Ram" = 0 then null else 100.0 * a."Total Ram Allocated" / a."Host Ram" end, 4) "Ram Percent Allocated",
    round(case when a."Host Cores" =  0 then null else 100.0  * a."Total vCores In Service" / a."Host Cores" end, 4) "Cores Percent In Service",
    round(case when a."Host Ram" = 0 then null else 100.0 * a."Total Ram In Service" / a."Host Ram" end, 4) "Ram Percent In Service"
from
    (    
    select
        hv.last_edited "Host Last Discovered",
        m.name "VM Manager Name",
        hv.name "Host Device Name",
        hv.os_name "Host OS Name", 
        hv.cpucount * coalesce(hv.cpucore, 1) "Host Cores",
        hv.ram "Host Ram",
        count(*) "VM Count Allocated",
        sum(d.cpucount * coalesce(d.cpucore)) "Total vCores Allocated",
        sum(d.ram) "Total Ram Allocated",
        sum(case when d.in_service = true then 1 else 0 end) "VM Count In Service",
        sum(case when d.in_service = true then d.cpucount * coalesce(d.cpucore) else 0 end) "Total vCores In Service",
        sum(case when d.in_service = true then d.ram else 0 end) "Total Ram In Service",
    string_agg(d.name, ' | ') "VMs Allocated",
    string_agg(case when d.in_service = true then d.name else null end, ' | ') "VMs In Service"
    from
        view_device_v1 d
        inner join view_device_v1 hv on d.virtual_host_device_fk = hv.device_pk
        left join view_device_v1 m on hv.vm_manager_device_fk = m.device_pk 
    where 
        d.network_device = 'f'
    group by
        hv.name,
        hv.os_name,
        m.name,
        hv.in_service,
        hv.cpucount * coalesce(hv.cpucore, 1),
        hv.ram,
        hv.last_edited
    ) a 