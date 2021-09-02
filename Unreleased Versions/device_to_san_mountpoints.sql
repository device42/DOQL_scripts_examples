        SELECT DISTINCT
              vd.virtualmachine_name "VM Name"
              ,vd.hypervisor_name "Hypervisor"
              ,vd.file_name "File Name"
              ,vda.mountpoint_name "Mount"
              ,mp.capacity "Total Capacity"
              ,mp.free_capacity "Free Capacity"
              ,vda.storagearray_name "Array"
              ,vda.hypervisordisk_name "Hypervisor Disk Name"
              ,vda.storageresource_name "LUN"
        FROM view_vdisk_v2 vd
        Join view_vdisk_to_storagearray_v2 vda on vda.vdisk_fk = vd.vdisk_pk
        Join view_mountpoint_v2 mp on mp.mountpoint_pk = vda.mountpoint_fk