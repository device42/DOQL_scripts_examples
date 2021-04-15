/*
DOQL for detailed data of Devices related to Discovery Scores and Job Scores.
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
*/
Select 
	ds.discoveryscores_pk "Discovery Score ID"
	,vsd.vserverdiscovery_pk "Job ID"
	,vsd.job_name "Job Name"
	,vsd.platform "Platform"
	,ds.port "TCP Port"
	,ds.discovery_server "Discovery Target"
	,ds.username "Username"
	,CASE
	  WHEN ds.port_check = 't'
	  THEN
	  'PASS'
	  ELSE
	  'FAIL'
	END "Port Check"
	,CASE
	  WHEN ds.authorization = 't'
	  THEN
	  'PASS'
	  ELSE
	  'FAIL'
	END "Auth Check"
	,CASE
	  WHEN ds.is_sudo_failed = 't'
	  THEN
	  'FAIL'
	  ELSE
	  'PASS'
	END "Sudo Check"
	,CASE
	  WHEN ds.supported_os = 't'
	  THEN
	  'PASS'
	  ELSE
	  'FAIL'
	END "OS Support"
	,ds.sudo_error_message "Sudo Error Message"
	,ds.discovery_exception_message "Exception Message"
	,ds.updated "Discovery Timestamp"
	,d.first_added "First Discovered"
	,d.last_edited "Last Updated"
	,ds.device_fk "Device ID"
	,d.name "Device Name"
	,d.os_name "Operating System"
	,d.os_version "OS Version"
	,(Select count(*) From view_softwaredetails_v1 sd Where sd.device_fk = d.device_pk) "Software Count"
	,(Select count(*) From view_serviceinstance_v2 si Where si.device_fk = d.device_pk) "Services Count"
	,(Select count(*) From view_mountpoint_v1 m Where m.device_fk = d.device_pk) "Mounts Count"
	,(Select count(*) From view_appcomp_v1 a Where a.device_fk = d.device_pk) "Application Components Count"
	,(Select count(*) From view_networkshare_v1 ns Where ns.device_fk = d.device_pk) "Network Shares Count"
	,(Select count(*) From view_part_v1 pt Where pt.device_fk = d.device_pk) "Parts Count"
	,(Select count(*) From view_rudata_v1 ru Where ru.device_fk = ds.device_fk) "RU Count"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.os'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.os'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device OS"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.osmanufacturer'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.osmanufacturer'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device OS Manufacturer"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.osserial'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.osserial'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device OS Serial"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.osver'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.osver'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device OS Ver"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.osverno'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.osverno'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device OS Ver No"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.ostype'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.ostype'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device OS Type"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.domain'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.domain'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device Domain"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.hardware'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.hardware'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device Hardware"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.manufacturer'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.manufacturer'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device Manufacturer"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.serial_no'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.serial_no'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device Serial No"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.uuid'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.uuid'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device UUID"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.bios_vendor'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.bios_vendor'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device BIOS Vendor"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.bios_release_date'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.bios_release_date'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device BIOS Release Date"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.bios_version'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.bios_version'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device BIOS Version"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.cpucount'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.cpucount'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device CPU Count"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.cpucore'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.cpucore'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device CPU Cores"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.cpupower'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.cpupower'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device CPU Speed"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.memory'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.memory'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device Memory"
	,CASE
	  WHEN ds.discovery_scores::json->>'services.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'services.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Services List"
	,CASE
	  WHEN ds.discovery_scores::json->>'software.info'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'software.info'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Software Info"
	,CASE
	  WHEN ds.discovery_scores::json->>'software.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'software.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Software List"
	,CASE
	  WHEN ds.discovery_scores::json->>'schedules.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'schedules.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Schedules List"
	,CASE
	  WHEN ds.discovery_scores::json->>'network.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'network.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Network List"
	,CASE
	  WHEN ds.discovery_scores::json->>'monitoring.hdds'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'monitoring.hdds'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Monitoring HDDs"
	,CASE
	  WHEN ds.discovery_scores::json->>'monitoring.nics'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'monitoring.nics'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Monitoring NICs"
	,CASE
	  WHEN ds.discovery_scores::json->>'serviceports.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'serviceports.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Service Ports List"
	,CASE
	  WHEN ds.discovery_scores::json->>'device.hosts.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'device.hosts.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Device Hosts List"
	,CASE
	  WHEN ds.discovery_scores::json->>'mountpoints.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'mountpoints.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Mount Points List"
	,CASE
	  WHEN ds.discovery_scores::json->>'networkshares.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'networkshares.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Network Shares List"
	,CASE
	  WHEN ds.discovery_scores::json->>'app.webserver.apache'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'app.webserver.apache'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "App-Webserver Apache"
	,CASE
	  WHEN ds.discovery_scores::json->>'app.webserver.iis7+'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'app.webserver.iis7+'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "App-Webserver IIS7+"
	,CASE
	  WHEN ds.discovery_scores::json->>'containers.docker.list'  = 'ok'
	  THEN
	  'PASS'
	  WHEN ds.discovery_scores::json->>'containers.docker.list'  = 'partial'
	  THEN
	  'PARTIAL'
	  ELSE
	  'FAIL'
	END "Containers-Docker List"
	,ds.discovery_scores::json->>'ips' "IPs"
	,ds.discovery_scores::json->>'macs' "MACs"
	,ds.discovery_scores::json->>'subnets' "Subnets"
	,ds.discovery_scores::json->>'services' "Services"
	,ds.discovery_scores::json->>'software' "Software"
	,ds.discovery_scores::json->>'mountpoints' "Mount Points"
	,ds.discovery_scores::json->>'device_match' "Device Match"
	,ds.discovery_scores::json->>'app_webserver' "App_Webserver"
	,ds.discovery_scores::json->>'service_ports' "Service Ports"
	,ds.discovery_scores::json->>'network_shares' "Network Shares"
	,ds.discovery_scores::json->>'software_services_bulk' "Software Services Bulk"
From view_discoveryscores_v1 ds
	Left Join view_device_v2 d ON d.device_pk = ds.device_fk
	Left Join view_jobscore_v1 js ON ds.jobscore_fk = js.jobscore_pk
	Left Join view_vserverdiscovery_v1 vsd ON js.vserverdiscovery_fk = vsd.vserverdiscovery_pk
	Where vsd.platform <> 'vmware' and ds.updated > current_date - 14 and (js.jobscore_pk in (select max(jobscore_pk) from view_jobscore_v1 jk group by jk.vserverdiscovery_fk))
	Order by ds.updated DESC 