    /*
 - Name: Detailed Physical Inventory
 - Purpose: Query to report on all physical devices and subtypes.
 - Date Created: 10/01/20
 - Changes: 10/12/20 Updated to use new subtypes and view_device_v2 introduced in 16.19
*/
select 
d.device_pk "Device ID"
d.name "Device Name",
d.physicalsubtype "Physical Subtype",
d.in_service "In Service",
d.serial_no "Serial No",
d.os_name "OS Name",
d.os_version "OS Version",
d.os_version_no "OS Version No",
d.os_architecture "OS Arch",
d.total_cpus "CPU Count",
d.core_per_cpu "CPU Core",
d.cpu_speed "CPU Speed",
d.ram "RAM",
d.last_edited "Last Updated"
from view_device_v2 d
where d.type_id = '2' and d.in_service = 'f' and date_part('day', now() :: timestamp - d.last_edited :: timestamp) <= 15
order by d.device_pk ASC, d.last_edited ASC