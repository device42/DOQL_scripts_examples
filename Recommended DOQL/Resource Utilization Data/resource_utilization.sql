/*
    2020-09-17 Resource Utilization
    Returns Discovery Device and RU info for all non-network devices
    - Changed to use the avg and max functions to replace the sum functions
    - Only showing devices that have RU data collected for CPU, Disk, Memory and NIC IO
 
   4/15/21
   - change device_v1 to device_v2 
*/
With 
    target_device_data  as (
        Select
            d.device_pk
            ,d.last_edited "Last Successful Discovery"
            ,d.name "Device Name"
            ,hd.name "Hypervisor Hostname"
            ,coalesce(cd.name, hcd.name, '') "Chassis Hostname"
            ,d.virtualsubtype "Virtual Subtype"
            ,d.os_name "OS Name"
            ,d.os_version_no "OS Version"
            ,d.os_architecture "OS Architecture"
            ,d.total_cpus "CPU Count"
            ,d.core_per_cpu "Cores Per Socket"
            ,CASE 
                When d.ram_size_type = 'GB' 
                Then d.ram*1024
                ELSE d.ram
            END "Ram"         
            ,CASE
                WHEN d.in_service = 't'
                THEN 'YES'
                ELSE 'NO'
            END "In Service?"
        From 
            view_device_v2 d
            left join (select * from view_device_v2 where blade_chassis = 't') cd on d.host_chassis_device_fk = cd.device_pk
            left join (select * from view_device_v2 where virtual_host = 't') hd on d.virtual_host_device_fk = hd.device_pk
            left join view_device_v2 hcd on hd.host_chassis_device_fk = hcd.device_pk
        Where Not d.network_device and d.ram > 0   
        Order by d.name 
    ),
 /* Pull the RU data and get the desired values  */ 
    target_ru_data  as (
        Select
            tdd.device_pk
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day CPU MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day CPU MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day CPU MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day CPU MAX (%)" 
            ,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day MEM AVG (%)"
            ,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day MEM MAX (%)"
            ,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day MEM AVG (%)"
            ,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day MEM MAX (%)"
            ,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day MEM AVG (%)"
            ,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day MEM MAX (%)"
            ,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day MEM AVG (%)"
            ,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day MEM MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day NIC Transfer IN AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day NIC Transfer IN MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day NIC Transfer OUT AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day NIC Transfer OUT MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day NIC Transfer IN AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day NIC Transfer IN MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day NIC Transfer OUT AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day NIC Transfer OUT MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day NIC Transfer IN AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day NIC Transfer IN MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day NIC Transfer OUT AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day NIC Transfer OUT MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day NIC Transfer IN AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day NIC Transfer IN MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day NIC Transfer OUT AVG (bytes)"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day NIC Transfer OUT MAX (bytes)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day NIC Speed IN AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day NIC Speed IN MAX (MB/s)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '1' and ru.metric_id = '3'))::numeric, 2) "1 Day NIC Speed OUT AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '1' and ru.metric_id = '1'))::numeric, 2) "1 Day NIC Speed OUT MAX (MB/s)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day NIC Speed IN AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day NIC Speed IN MAX (MB/s)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '2' and ru.metric_id = '3'))::numeric, 2) "7 Day NIC Speed OUT AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '2' and ru.metric_id = '1'))::numeric, 2) "7 Day NIC Speed OUT MAX (MB/s)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day NIC Speed IN AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day NIC Speed IN MAX (MB/s)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '3' and ru.metric_id = '3'))::numeric, 2) "30 Day NIC Speed OUT AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '3' and ru.metric_id = '1'))::numeric, 2) "30 Day NIC Speed OUT MAX (MB/s)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day NIC Speed IN AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '7' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day NIC Speed IN MAX (MB/s)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '4' and ru.metric_id = '3'))::numeric, 2) "90 Day NIC Speed OUT AVG (MB/s)"
            ,round(max((Select ru.value Where ru.measure_type_id = '8' and ru.timeperiod_id = '4' and ru.metric_id = '1'))::numeric, 2) "90 Day NIC Speed OUT MAX (MB/s)"
            ,rc.name "Remote Collector Name"
            ,rc.ip "Remote Collector IP"          
        From 
            target_device_data tdd
  /* Only get the CPU, Memory, Disk I/O and NIC RU data    */           
            Join view_rudata_v2 ru on tdd.device_pk = ru.device_fk and ru.measure_type_id IN ('1', '2', '3', '4', '7', '8', '9', '10')
            Left Join view_remotecollector_v1 rc on rc.remotecollector_pk = ru.remotecollector_fk           
        Group by
            tdd.device_pk
            ,rc.name
            ,rc.ip
    )
    /*  Now pull all the data together  */
Select Distinct
    tdd."Last Successful Discovery"
    ,tdd.device_pk
    ,tdd."Device Name"
    ,tdd."Hypervisor Hostname"
    ,tdd."Chassis Hostname"
    ,tdd."Virtual Subtype"
    ,tdd."OS Name"
    ,tdd."OS Version"
    ,tdd."OS Architecture"
    ,tdd."CPU Count"
    ,tdd."Cores Per Socket"
    ,tdd."In Service?"
    ,trd."1 Day CPU AVG (%)"  
    ,trd."1 Day CPU MAX (%)"  
    ,trd."7 Day CPU AVG (%)"  
    ,trd."7 Day CPU MAX (%)"  
    ,trd."30 Day CPU AVG (%)" 
    ,trd."30 Day CPU MAX (%)" 
    ,trd."90 Day CPU AVG (%)" 
    ,trd."90 Day CPU MAX (%)" 
    ,trd."1 Day MEM AVG (%)"  
    ,trd."1 Day MEM MAX (%)"  
    ,trd."7 Day MEM AVG (%)"  
    ,trd."7 Day MEM MAX (%)"  
    ,trd."30 Day MEM AVG (%)" 
    ,trd."30 Day MEM MAX (%)" 
    ,trd."90 Day MEM AVG (%)" 
    ,trd."90 Day MEM MAX (%)" 
    ,trd."1 Day DISK IO Read AVG" 
    ,trd."1 Day DISK IO Read MAX" 
    ,trd."7 Day DISK IO Read AVG" 
    ,trd."7 Day DISK IO Read MAX" 
    ,trd."30 Day DISK IO Read AVG"    
    ,trd."30 Day DISK IO Read MAX"    
    ,trd."90 Day DISK IO Read AVG"    
    ,trd."90 Day DISK IO Read MAX"    
    ,trd."1 Day DISK IO Write AVG"    
    ,trd."1 Day DISK IO Write MAX"    
    ,trd."7 Day DISK IO Write AVG"    
    ,trd."7 Day DISK IO Write MAX"    
    ,trd."30 Day DISK IO Write AVG"   
    ,trd."30 Day DISK IO Write MAX"   
    ,trd."90 Day DISK IO Write AVG"   
    ,trd."90 Day DISK IO Write MAX"   
    ,trd. "1 Day NIC Transfer IN AVG (bytes)"
    ,trd. "1 Day NIC Transfer IN MAX (bytes)"
    ,trd. "1 Day NIC Transfer OUT AVG (bytes)"
    ,trd. "1 Day NIC Transfer OUT MAX (bytes)"
    ,trd. "7 Day NIC Transfer IN AVG (bytes)"
    ,trd. "7 Day NIC Transfer IN MAX (bytes)"
    ,trd. "7 Day NIC Transfer OUT AVG (bytes)"
    ,trd. "7 Day NIC Transfer OUT MAX (bytes)"
    ,trd. "30 Day NIC Transfer IN AVG (bytes)"
    ,trd. "30 Day NIC Transfer IN MAX (bytes)"
    ,trd. "30 Day NIC Transfer OUT AVG (bytes)"
    ,trd. "30 Day NIC Transfer OUT MAX (bytes)"
    ,trd. "90 Day NIC Transfer IN AVG (bytes)"
    ,trd. "90 Day NIC Transfer IN MAX (bytes)"
    ,trd. "90 Day NIC Transfer OUT AVG (bytes)"
    ,trd. "90 Day NIC Transfer OUT MAX (bytes)"
    ,trd. "1 Day NIC Speed IN AVG (MB/s)"
    ,trd. "1 Day NIC Speed IN MAX (MB/s)"
    ,trd. "1 Day NIC Speed OUT AVG (MB/s)"
    ,trd. "1 Day NIC Speed OUT MAX (MB/s)"
    ,trd. "7 Day NIC Speed IN AVG (MB/s)"
    ,trd. "7 Day NIC Speed IN MAX (MB/s)"
    ,trd. "7 Day NIC Speed OUT AVG (MB/s)"
    ,trd. "7 Day NIC Speed OUT MAX (MB/s)"
    ,trd. "30 Day NIC Speed IN AVG (MB/s)"
    ,trd. "30 Day NIC Speed IN MAX (MB/s)"
    ,trd. "30 Day NIC Speed OUT AVG (MB/s)"
    ,trd. "30 Day NIC Speed OUT MAX (MB/s)"
    ,trd. "90 Day NIC Speed IN AVG (MB/s)"
    ,trd. "90 Day NIC Speed IN MAX (MB/s)"
    ,trd. "90 Day NIC Speed OUT AVG (MB/s)"
    ,trd. "90 Day NIC Speed OUT MAX (MB/s)"
    ,trd."Remote Collector Name"
    ,trd."Remote Collector IP"
    ,l.last_login
    ,l.domain
    ,l.username
From
    target_device_data tdd
    Join target_ru_data trd on trd.device_pk = tdd.device_pk
    Left Join view_devicelastlogin_v1 l on l.device_fk = tdd.device_pk and 
                                      l.last_login = (Select max(lr.last_login) From view_devicelastlogin_v1 lr Where lr.device_fk = tdd.device_pk)     
Order by tdd."Last Successful Discovery" ASC, tdd."Device Name" ASC