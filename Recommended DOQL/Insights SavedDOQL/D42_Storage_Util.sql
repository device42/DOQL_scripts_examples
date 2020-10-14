/*
Device mount storage information, but total'd for all mounts instead of a row for each mount.
  2020-09-21 - Simplify the grouping information by using Over(Partition by...)
*/
Select Distinct
    d.last_edited "Last_Update"
    ,d.device_pk "Device_ID"
    ,d.name "Device_Name"
    ,d.type "Hardware_Type"
    ,d.virtual_subtype "Virtual_Subtype"
    ,d.os_name "OS_Name"
    ,d.os_version "OS_Version_No"
    ,sum(c.capacity) Over(Partition by d.device_pk) "Volume_Capacity_in_MB"
    ,sum(c.free_capacity) Over(Partition by d.device_pk) "Free_Space_in_MB"
    ,sum(c.capacity - c.free_capacity) Over(Partition by d.device_pk) "Used_Space_in_MB"
From
    view_device_v1 d
    Left Join view_mountpoint_v1 c on c.device_fk = d.device_pk 
Where c.capacity>0 
Order by d.device_pk