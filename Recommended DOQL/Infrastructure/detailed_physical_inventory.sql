    /*
 - Name: Detailed Physical Inventory
 - Purpose: Query to report on all physical devices and subtypes.
 - Date Created: 10/01/20
 - Changes: 10/12/20 Updated to use new subtypes and view_device_v2 introduced in 16.19
*/
select d.name "Device Name",
d.physicalsubtype "Physical Subtype",
d.serial_no "Serial No",
d.os_name "OS Name",
d.os_version "OS Version",
d.os_version_no "OS Version No",
d.os_architecture "OS Arch",
d.total_cpus "CPU Count",
d.core_per_cpu "CPU Core",
d.cpu_speed "CPU Speed",
d.ram "RAM",
pm.name "Part Name",
v.name "Part Mfr",
pm.partmodel_pk "Part Model ID",
pm.type_name "Part Type",
p.pcount "Part Count",
p.firmware "Part Firmware",
p.serial_no "Part Serial No",
p.slot "Part Slot",
pm.cores "Part Cores",
pm.threads "Part Threads",
pm.speed "Part Speed",
pm.ramsize "Part RAM",
pm.ramspeed "Part RAM Speed",
np.hwaddress2 "Part HW Address",
pm.hdsize "Part HDD Size",
pm.hdsize_unit "Part HDD Size Unit",
pm.hddtype_name "Part HDD Type"
from view_device_v2 d
left join view_part_v1 p on p.device_fk = d.device_pk
left join view_partmodel_v1 pm on pm.partmodel_pk = p.partmodel_fk
left join view_vendor_v1 v on pm.vendor_fk = v.vendor_pk
left join view_netport_v1 np on p.netport_fk = np.netport_pk
where d.type_id = '2'
order by d.name, pm.name