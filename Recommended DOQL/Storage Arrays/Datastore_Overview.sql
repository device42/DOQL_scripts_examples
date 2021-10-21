select mpsa.mountpoint_name as "Datastore Name"
		,mpsa.hypervisordisk_name as "Hypervisor Disk Name"
		,mpsa.hypervisor_name as "Hypervisor Name"
		,mpsa.storageresource_name as "LUN of FS Name"
		,mpsa.storageresource_type	 as "Storage Resource Type"
		,mpsa.storagearray_name	 as "Storage Array Name"
		,mpsa.storagearray_fk as "Storage Array ID"
		,mpsa.storagearray_type as "Storage Array Type"
		,mp.capacity as "Capacity"
		,mp.free_capacity as "Free Capacity"
		,mp.mountpoint_pk as "Mountpoint ID"
from view_mountpoint_to_storagearray_v2 mpsa 
left join view_mountpoint_v1 mp 
	on mpsa.mountpoint_fk = mp.mountpoint_pk 
left join view_deviceresource_v1 dr
	on mpsa.mountpoint_fk = dr.resource_fk
	and mp.mountpoint_pk = dr.device_fk