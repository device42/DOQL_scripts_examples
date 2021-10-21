        SELECT
              d.name "Client Device"
              ,mp.mountpoint "Mountpoint"
              ,split_part(mp.filesystem, ':', 1) "Filesystem Device"
              ,mp.filesystem "Filesystem"
              ,mp.fstype_name "FS Type"
              ,mp.capacity / 1024 "Total Capacity (GB)"
              ,mp.free_capacity / 1024 "Free Capacity (GB)"
        FROM view_mountpoint_v1 mp
        JOIN view_device_v2 d ON d.device_pk = mp.device_fk
        WHERE mp.fstype_name IN ('nfs4','nfs','cifs','fuse')