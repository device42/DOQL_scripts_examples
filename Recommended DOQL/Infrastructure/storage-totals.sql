/*
Device mount storage information, but total'd for all mounts instead of a row for each mount.
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
  4/15/21
  - Remove the network and container devices  
*/
Select
    a.last_edited Last_Update,
    a.device_pk Device_ID,
    a.name Device_name,
    h.device_pk Host_ID,
    h.name Virtual_Host_Hostname,
    a.type Hardware_Type,
    a.virtualsubtype Virtual_Subtype,
    a.os_name OS_Name,
    a.os_version OS_Version_No,
    sum(c.capacity) Volume_Capacity_in_MB,
    sum(c.free_capacity) Free_Space_in_MB,
    sum(c.capacity - c.free_capacity) Used_Space_in_MB
From
    view_device_v2 a
    Left Join view_device_v2 h on h.device_pk = a.virtual_host_device_fk
	Left Join view_containerinstance_v1 coi ON coi.device_fk = a.device_pk    
    Left Join view_mountpoint_v1 c on c.device_fk = a.device_pk 
    Where c.capacity>0
	    and a.network_device = 'f' 
		and coi.container_id is Null	/* remove network devices and containers */
		and lower(a.type) Not IN ('cluster','unknown')    
group by
    a.last_edited,
    a.device_pk,
    a.name,
    h.device_pk,
    h.name,
    a.type,
    a.virtualsubtype,
    a.os_name,
    a.os_version
order by a.device_pk