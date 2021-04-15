    /*
 - Name: Detailed Physical Inventory
 - Purpose: Query to report on all physical devices and subtypes.
 - Date Created: 10/01/20
 - Changes: 10/12/20 Updated to use new subtypes and view_device_v2 introduced in 16.19
  Update 2020-10-19
  - Reformatted
*/
Select 
    d.name "Device Name"
    ,d.physicalsubtype "Physical Subtype"
    ,d.serial_no "Serial No"
    ,d.os_name "OS Name"
    ,d.os_version "OS Version"
    ,d.os_version_no "OS Version No"
    ,d.os_architecture "OS Arch"
    ,d.total_cpus "CPU Count"
    ,d.core_per_cpu "CPU Core"
    ,d.cpu_speed "CPU Speed"
    ,d.ram "RAM"
    ,pm.name "Part Name"
    ,v.name "Part Mfr"
    ,pm.partmodel_pk "Part Model ID"
    ,pm.type_name "Part Type"
    ,p.pcount "Part Count"
    ,p.firmware "Part Firmware"
    ,p.serial_no "Part Serial No"
    ,p.slot "Part Slot"
    ,pm.cores "Part Cores"
    ,pm.threads "Part Threads"
    ,pm.speed "Part Speed"
    ,pm.ramsize "Part RAM"
    ,pm.ramspeed "Part RAM Speed"
    ,np.hwaddress2 "Part HW Address"
    ,pm.hdsize "Part HDD Size"
    ,pm.hdsize_unit "Part HDD Size Unit"
    ,pm.hddtype_name "Part HDD Type"
From view_device_v2 d
 Left Join view_part_v1 p ON p.device_fk = d.device_pk
 Left Join view_partmodel_v1 pm ON pm.partmodel_pk = p.partmodel_fk
 Left Join view_vendor_v1 v ON pm.vendor_fk = v.vendor_pk
 Left Join view_netport_v1 np ON p.netport_fk = np.netport_pk
Where d.type_id = '2'
Order by d.name, pm.name