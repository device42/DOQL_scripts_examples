WITH
    vdisk_to_array AS (
        SELECT vd.name
               ,vd.identifier 
               ,vd.virtualmachine_name "vm_name"
               ,vd.virtualmachine_fk "vm_id"
               ,vd.hypervisor_name "host"
               ,vd.hypervisor_fk "host_id"
               ,vd.file_name::text "object_details"
               ,vds.storageresource_name 
               ,vds.storagearray_name
               ,'vdisk to array' "relationship_type"
        FROM view_vdisk_v2 vd
        JOIN view_vdisk_to_storagearray_v2 vds on vds.vdisk_fk = vd.vdisk_pk 
    ),
    host_vol_to_array AS (
        SELECT mpsa.mountpoint_name "name"
               ,mp.filesystem "identifier" 
               ,'Host Only' "vm_name"
               ,null::INTEGER  "vm_id"
               ,mpsa.hypervisor_name  "host" 
               ,dr.device_fk "host_id" 
               ,mpsa.storageresource_type "object_details"
               ,mpsa.storageresource_name 
               ,mpsa.storagearray_name
               ,'host mountpoint on array' "relationship_type"
       from view_mountpoint_to_storagearray_v2 mpsa 
       left join view_mountpoint_v1 mp 
	      on mpsa.mountpoint_fk = mp.mountpoint_pk 
       left join view_deviceresource_v1 dr
	      on mpsa.mountpoint_fk = dr.resource_fk
	      and mp.mountpoint_pk = dr.device_fk
    )
SELECT * from vdisk_to_array
UNION ALL
SELECT * from host_vol_to_array