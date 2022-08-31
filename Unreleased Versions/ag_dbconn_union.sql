WITH 
ag_data AS
(
select
    ag.client_name::text
    ,ag.client_id
    ,ag.client_service
    ,ag.client_service_name::text
    ,ag.client_service_display_name::text
    ,ag.client_service_instance_id
    ,ag.client_service_port_remote_ip_id
    ,ag.client_ip
    ,ag.client_service_pinned
    ,ag.client_service_appcomps
    ,ag.listener_service 
    ,ag.listener_service_display_name::text
    ,ag.listener_service_name::text
    ,ag.listener_name::text
    ,ag.listener_id
    ,ag.listener_service_instance_id
    ,true listener_service_pinned
    ,ag.listener_service_appcomps
    ,ag.listener_ip
   /* ,ld.tags::text
    ,cd.tags::text
    ,CONCAT(ld.tags, '', cd.tags) "All Tags" */
from view_affinity_dependency_data_v1 ag
left join view_device_v2 ld on ld.device_pk = ag.listener_id
left join view_device_v2 cd on cd.device_pk = ag.client_id
where family(listener_ip) <> 6 and listener_ip <> '::1' and listener_ip <> '127.0.0.1' and coalesce(listener_service_topology_status, 1) <> 3 and coalesce(client_service_topology_status, 1) <> 3
),
db_conn_resources AS (
select
    COALESCE(cr.resource_name, cd.name, sc.client_ip::text) client_name
    ,COALESCE(sc.client_resource_fk, sc.client_device_fk) client_id
    ,sc.client_process_name client_service
    ,sc.client_process_name client_service_name
    ,sc.client_process_name client_service_display_name
    ,sc.client_serviceinstance_fk client_service_instance_id
    ,sc.servicecommunication_pk client_service_port_remote_ip_id
    ,sc.client_ip client_ip
    ,COALESCE(csi.pinned, 'false') client_service_pinned
    ,null::json client_service_appcomps
    ,ls.displayname listener_service
    ,ls.displayname listener_service_display_name
    ,ls.pretty_name listener_service_name
    ,COALESCE(lr.resource_name, ld.name) listener_name
    ,COALESCE(sc.listener_resource_fk, sc.listener_device_fk) listener_id
    ,lsi.serviceinstance_pk listener_service_instance_id
    ,true listener_service_pinned
    ,null::json listener_service_appcomps
    ,sc.listener_ip listener_ip
    /*,COALESCE(lr.tags, ld.tags) tags
    ,COALESCE(cr.tags, cd.tags) tags
    ,CONCAT(COALESCE(lr.tags, ld.tags), '', COALESCE(cr.tags, cd.tags)) "All Tags" */
from
    view_servicecommunication_v2 sc
left join view_device_v2 ld on ld.device_pk = sc.listener_device_fk
left join view_device_v2 cd on cd.device_pk = sc.client_device_fk 
left join view_resource_v2 lr on lr.resource_pk = sc.listener_resource_fk 
left join view_resource_v2 cr on cr.resource_pk = sc.client_resource_fk
left join view_serviceinstance_v2 csi on csi.serviceinstance_pk = sc.client_serviceinstance_fk
left join view_servicelistenerport_v2 slp on slp.servicelistenerport_pk = sc.servicelistenerport_fk 
left join view_serviceinstance_v2 lsi on lsi.serviceinstance_pk = slp.discovered_serviceinstance_fk
left join view_service_v2 ls on ls.service_pk = lsi.service_fk 
where COALESCE(sc.listener_resource_fk, sc.client_resource_fk) IS NOT NULL
)
Select * from ag_data
Union All
Select * from db_conn_resources