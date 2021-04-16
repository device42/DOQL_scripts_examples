/* DOQL Query for JSM Cloud Automation Rule - 04_16_21  */
/*
This is an example query that can be used as part of a JSM Automation rule to fetch data from Device42 DOQL.
*/
select
d.device_pk "key",
d.name "Device_Name",
d.in_service "In Service",
d.service_level "Service_Level",
d.type "Device_Type",
COALESCE(d.physicalsubtype, '') || COALESCE(d.virtualsubtype, '') "Device Subtype",
d.serial_no "Device_Serial",
d.virtual_host "Virtual Host",
d.network_device "Network Device",
d.os_architecture "OS Architecture",
d.total_cpus "Total CPUs",
d.core_per_cpu "Cores Per CPU",
d.threads_per_core "Threads Per Core",
d.cpu_speed "CPU Speed",
d.total_cpus*d.core_per_cpu "Total Cores",
d.ram "RAM",
CASE d.os_version
WHEN '' then d.os_name
ELSE coalesce(d.os_name || ' - ' ||
d.os_version,d.os_name)
END "OS Name",
d.os_version "OS Version"
from view_device_v2 d where d.device_pk={device_id}