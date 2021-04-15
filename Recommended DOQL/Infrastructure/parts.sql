/*
 - Name: parts
 - Purpose: Query that exports the current parts inventory.
 - Date Created: 10/01/20
 - Changes:
*/
SELECT
    p.pcount "Count"
    ,pm.name "Part Model"
    ,pm.modelno "Model #"
    ,p.slot "Slot"
    ,p.serial_no "Serial #"
    ,p.asset_no "Asset #"
    ,p.firmware "Firmware Version"
    ,p.checked_out_to "Assignement"
    ,p.raid_type_name "Raid Type"
    ,p.raid_group "Raid Group"
    ,p.description "Description"
From view_part_v1 p
Join view_partmodel_v1 pm ON pm.partmodel_pk = p.partmodel_fk