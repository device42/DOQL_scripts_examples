 select vdh.virtualmachine_name as "VM Name"
		,vdh.hypervisor_name as "Hypervisor Name"
		,vdh.vdisk_name as "VDisk Name"
		,vdsa.mountpoint_name	as "Datastore Name"
		,vdsa.vdisk_backing as "VDisk Backing"
		,vdsa.storageresource_name as "LUN Filesystem"
		,vdsa.storagearray_name as "Storage Array Name"	
		,vdsa.storagearray_type as "Storage Array Type"
from view_vdisk_to_hypervisor_v2 vdh 
left join view_vdisk_to_storagearray_v2 vdsa 
 	on vdh.vdisk_fk = vdsa.vdisk_fk