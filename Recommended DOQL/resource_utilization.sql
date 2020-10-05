/*
	2020-09-17 Resource Utilization
	Returns Discovery Device and RU info for all non-network devices
	- Changed to use the avg and max functions to replace the sum functions
	- Only showing devices that have RU data collected for CPU, Disk, Memory and NIC IO
	- add in location - for on Prem use building; for cloud use cloud_location 
*/
With 
    target_device_data  as (
        Select
            d.device_pk
            ,d.last_edited "Last Successful Discovery"
            ,d.name "Device Name"
            ,d.virtual_subtype "Virtual Subtype"
            ,d.os_name "OS Name"
            ,d.os_version_no "OS Version"
            ,d.os_arch "OS Architecture"
            ,d.cpucount "CPU Count"
            ,d.cpucore "Cores Per Socket"
            ,CASE 
				When ram_size_type = 'GB' 
				Then d.ram*1024
				ELSE d.ram
            END "Ram"			
            ,CASE
				WHEN d.in_service = 't'
				THEN 'YES'
				ELSE 'NO'
            END "In Service?"
			,b.name "Building Loc"
			,d.cloud_location "Cloud Loc"
			,coalesce(d.cloud_location,b.name) "Location"			
        From 
            view_device_v1 d
		Left Join view_building_v1 b on b.building_pk = d.building_fk
		Where Not network_device and d.ram > 0	
		Order by d.name	
	),
 /* Pull the RU data and get the desired values  */	
    target_ru_data  as (
        Select
            tdd.device_pk
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day CPU MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day CPU MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day CPU MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day CPU AVG (%)"
            ,round(max((Select ru.value Where ru.measure_type_id = '1' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day CPU MAX (%)"
			,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day MEM AVG (%)"
			,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day MEM MAX (%)"
			,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day MEM AVG (%)"
			,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day MEM MAX (%)"
			,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day MEM AVG (%)"
			,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day MEM MAX (%)"
			,round(avg((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day MEM AVG (%)"
			,round(max((Select ru.value * 100 / tdd."Ram" Where ru.measure_type_id = '2' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day MEM MAX (%)"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day DISK IO Read AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '3' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day DISK IO Read MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day DISK IO Write AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '4' and ru.metric_id = '1')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day DISK IO Write MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day NIC Transfer IN AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day NIC Transfer IN MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day NIC Transfer OUT AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "1 Day NIC Transfer OUT MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day NIC Transfer IN AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day NIC Transfer IN MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day NIC Transfer OUT AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "7 Day NIC Transfer OUT MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day NIC Transfer IN AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day NIC Transfer IN MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day NIC Transfer OUT AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "30 Day NIC Transfer OUT MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day NIC Transfer IN AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '9' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day NIC Transfer IN MAX"
            ,round(avg((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day NIC Transfer OUT AVG"
            ,round(max((Select ru.value Where ru.measure_type_id = '10' and ru.metric_id = '3')) over(Partition by tdd.device_pk, ru.timeperiod_id)::numeric, 2) "90 Day NIC Transfer OUT MAX"
			,rc.name "Remote Collector Name"
			,rc.ip "Remote Collector IP"			
        From 
            target_device_data tdd
  /* Only get the CPU, Memory, Disk I/O and NIC RU data    */			
            Join view_rudata_v2 ru on tdd.device_pk = ru.device_fk and ru.measure_type_id IN ('1', '2', '3', '4', '9', '10')
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
	,tdd."Virtual Subtype"
	,tdd."OS Name"
	,tdd."OS Version"
	,tdd."OS Architecture"
	,tdd."CPU Count"
	,tdd."Cores Per Socket"
	,tdd."In Service?"
	,tdd."Building Loc"
	,tdd."Cloud Loc"
	,tdd."Location"
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
	,trd. "1 Day NIC Transfer IN AVG"
	,trd. "1 Day NIC Transfer IN MAX"
	,trd. "1 Day NIC Transfer OUT AVG"
	,trd. "1 Day NIC Transfer OUT MAX"
	,trd. "7 Day NIC Transfer IN AVG"
	,trd. "7 Day NIC Transfer IN MAX"
	,trd. "7 Day NIC Transfer OUT AVG"
	,trd. "7 Day NIC Transfer OUT MAX"
	,trd. "30 Day NIC Transfer IN AVG"
	,trd. "30 Day NIC Transfer IN MAX"
	,trd. "30 Day NIC Transfer OUT AVG"
	,trd. "30 Day NIC Transfer OUT MAX"
	,trd. "90 Day NIC Transfer IN AVG"
	,trd. "90 Day NIC Transfer IN MAX"
	,trd. "90 Day NIC Transfer OUT AVG"
	,trd. "90 Day NIC Transfer OUT MAX"
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