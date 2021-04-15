/*
	2019-10-25 Servers Activity and Utilization
	Returns discovery, RU, and service connection information to give a sense of when this device
	was last discovered or how it has been used. Includes fields like last attempted/successful discovery,
	last service comms and software install, last login, general device details and RU data. 
	Useful in identifying underutilized or zombie servers.
	2020-09-15 - Updated to correct a few issues:
	- Used the avg/max functions vs the sum on many of the data reporting
	- corrected the ram calculations to figure out if data is in mb or gb
	- only look at non-network devices
	- remove the filtering of devices that have a job scan. (want to see all devices that have not been scan)
	- used CTEs and simplified the grouping
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2  	
*/
With 
    target_device_data  as (
        Select
            d.device_pk
            ,d.last_edited "Last Successful Discovery"
            ,d.name "Device Name"
            ,d.virtualsubtype "Virtual Subtype"
            ,d.os_name "OS Name"
            ,d.os_version_no "OS Version"
            ,d.os_architecture "OS Architecture"
            ,d.total_cpus "CPU Count"
            ,d.core_per_cpu "Cores Per Socket"
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
        From 
            view_device_v2 d
		Where Not network_device	
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
            ,round(sum((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '1' and ru.metric_id = '4'))::numeric, 2) "1 Day NIC Transfer IN"
            ,round(sum((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '1' and ru.metric_id = '4'))::numeric, 2) "1 Day NIC Transfer OUT"
            ,round(sum((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '2' and ru.metric_id = '4'))::numeric, 2) "7 Day NIC Transfer IN"
            ,round(sum((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '2' and ru.metric_id = '4'))::numeric, 2) "7 Day NIC Transfer OUT"
            ,round(sum((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '3' and ru.metric_id = '4'))::numeric, 2) "30 Day NIC Transfer IN"
            ,round(sum((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '3' and ru.metric_id = '4'))::numeric, 2) "30 Day NIC Transfer OUT"
            ,round(sum((Select ru.value Where ru.measure_type_id = '9' and ru.timeperiod_id = '4' and ru.metric_id = '4'))::numeric, 2) "90 Day NIC Transfer IN"
            ,round(sum((Select ru.value Where ru.measure_type_id = '10' and ru.timeperiod_id = '4' and ru.metric_id = '4'))::numeric, 2) "90 Day NIC Transfer OUT"
        From 
            target_device_data tdd
            Left Join view_rudata_v2 ru on tdd.device_pk = ru.device_fk	
		Group by
            tdd.device_pk		
	)
	/*  Now pull all the data together  */
Select
	tdd."Last Successful Discovery"
	,ds.updated "Last Attempted Discovery"
	,(Select max(scl.last_detected) From view_servicecommunication_v2 scl Where tdd.device_pk = scl.listener_device_fk) "Last Detected Comms (Listener)"
	,(Select max(scc.last_detected) From view_servicecommunication_v2 scc Where tdd.device_pk = scc.client_device_fk) "Last Detected Comms (Client)"
	,(Select max(siu.install_date) From view_softwareinuse_v1 siu Where tdd.device_pk = siu.device_fk) "Last Software Installation"
	,tdd.device_pk
	,tdd."Device Name"
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
	,trd."1 Day NIC Transfer IN"	
	,trd."1 Day NIC Transfer OUT"	
	,trd."7 Day NIC Transfer IN"	
	,trd."7 Day NIC Transfer OUT"	
	,trd."30 Day NIC Transfer IN"	
	,trd."30 Day NIC Transfer OUT"	
	,trd."90 Day NIC Transfer IN"	
	,trd."90 Day NIC Transfer OUT"	
	,l.last_login
	,l.domain
	,l.username
From
    target_device_data tdd
	Left Join target_ru_data trd on trd.device_pk = tdd.device_pk
	Left Join view_discoveryscores_v1 ds on ds.device_fk = tdd.device_pk and
									   ds.added = (Select max(lds.added) From view_discoveryscores_v1 lds Where lds.device_fk = tdd.device_pk)	
	Left Join view_jobscore_v1 js on ds.jobscore_fk = js.jobscore_pk and
							    js.jobscore_pk = (Select max(ljs.jobscore_pk) From view_jobscore_v1 ljs Where ljs.jobscore_pk = ds.jobscore_fk)
	Left Join view_devicelastlogin_v1 l on l.device_fk = tdd.device_pk and 
                                      l.last_login = (Select max(lr.last_login) From view_devicelastlogin_v1 lr Where lr.device_fk = tdd.device_pk)   
/* Removed the where clause because it was filtering out devices that had not been scan recently (> 7 days)
 Where 
    js.jobscore_pk in (Select max(jobscore_pk) From view_jobscore_v1 jk Group by jk.vserverdiscovery_fk) */  
Order by tdd."Last Successful Discovery" ASC, "Last Attempted Discovery" ASC, tdd."Device Name" ASC 	