SELECT ci.container_id "Container ID"
       ,ci.status "Container Status"
       ,ci.image_id "Image ID"
       ,dc.name "Container Name"
       ,CASE WHEN dc.virtual_host_device_fk IS NOT NULL THEN dh.name
            ELSE 'No Related Host'
        END "Container Host"
       ,CASE WHEN LOWER(dc.virtualsubtype) LIKE '%container' THEN dc.virtualsubtype
             ELSE 'Container Host'
        END "Type"
FROM view_containerinstance_v1 ci
JOIN view_device_v2 dc on ci.device_fk = dc.device_pk
LEFT JOIN view_device_v2 dh on dh.device_pk = dc.virtual_host_device_fk