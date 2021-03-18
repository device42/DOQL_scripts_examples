/*
Device mount storage information, but total'd for all mounts instead of a row for each mount.
*/
select
    a.last_edited Last_Update,
    a.device_pk Device_ID,
    a.name Device_name,
    h.device_pk Host_ID,
    h.name Virtual_Host_Hostname,
    a.type Hardware_Type,
    a.virtual_subtype Virtual_Subtype,
    a.os_name OS_Name,
    a.os_version OS_Version_No,
    sum(c.capacity) Volume_Capacity_in_MB,
    sum(c.free_capacity) Free_Space_in_MB,
    sum(c.capacity - c.free_capacity) Used_Space_in_MB
from
    view_device_v1 a
    left join view_device_v1 h on h.device_pk = a.virtual_host_device_fk
    left join view_mountpoint_v1 c on c.device_fk = a.device_pk where c.capacity>0
group by
    a.last_edited,
    a.device_pk,
    a.name,
    h.device_pk,
    h.name,
    a.type,
    a.virtual_subtype,
    a.os_name,
    a.os_version
order by a.device_pk