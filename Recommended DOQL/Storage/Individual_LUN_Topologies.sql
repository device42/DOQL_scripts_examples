select vd.virtualmachine_name as "VM Name"
		,vd.hypervisor_name as "Hypervisor Name"
		,vd.vdisk_name as "VDisk Name"
		,va.mountpoint_name as "Datastore Name"
		,va.vdisk_backing as "VDisk Backing"
		,va.storagearray_name as "Storage Array Name"
		,va.storagearray_type as "Storage Array Type"
from view_vdisk_to_hypervisor_v2 vd 
left join view_vdisk_to_storagearray_v2 va 
	on vd.vdisk_fk = va.vdisk_fk;