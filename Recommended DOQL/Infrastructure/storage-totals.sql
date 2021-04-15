/*
Device mount storage information, but total'd for all mounts instead of a row for each mount.
Changes:
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
*/
Select
    d.last_edited Last_Update
    ,d.device_pk Device_ID
    ,d.name Device_name
    ,d.type Hardware_Type
    ,d.virtualsubtype Virtual_Subtype
    ,d.os_name OS_Name
    ,d.os_version OS_Version_No
    ,sum(c.capacity) Volume_Capacity_in_MB
    ,sum(c.free_capacity) Free_Space_in_MB
    ,sum(c.capacity - c.free_capacity) Used_Space_in_MB
From
    view_device_v2 d
    Left Join view_mountpoint_v1 c ON c.device_fk = d.device_pk 
    Where c.capacity > 0
Group by
    d.last_edited
    ,d.device_pk
    ,d.name
    ,d.type
    ,d.virtualsubtype
    ,d.os_name
    ,d.os_version
Order by d.device_pk ASC