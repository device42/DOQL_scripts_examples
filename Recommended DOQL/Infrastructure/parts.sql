/*
 - Name: parts
 - Purpose: Query that exports the current parts inventory.
 - Date Created: 10/01/20
 - Changes:
*/
SELECT
d.device_pk "Device ID",
p.pcount "Count",
pm.name "Part Model",
pm.modelno "Model #",
pm.type_name "Part Type",
p.slot "Slot",
p.serial_no "Serial #",
p.asset_no "Asset #",
p.firmware "Firmware Version",
p.checked_out_to "Assignement",
p.raid_type_name "Raid Type",
p.raid_group "Raid Group",
p.description "Description",
pm.speed "Part Speed",
pm.cores "Cores",
pm.threads "Threads",
pm.ramsize "RAM Size",
pm.ramsize_unit "RAM Size Unit",
pm.ramtype "RAM Type",
pm.hdsize "Disk Size",
pm.hdsize_unit "Disk Unit",
pm.connectivity_name "Connectivity",
pm.media_type_name "Media Type",
pm.connector_type_name "Connector Type",
pm.partno "Part Number"
from view_part_v1 p
join view_partmodel_v1 pm on pm.partmodel_pk = p.partmodel_fk
join view_device_v2 d on d.device_pk = p.device_fk