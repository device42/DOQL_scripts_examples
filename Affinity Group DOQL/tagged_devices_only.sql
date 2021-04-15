/*Listening devices with tags only
 Update 2020-10-19
  - updated the view_device_v1 to view_device_v2     
*/
select add.* from view_affinity_dependency_data_v1 add
join view_device_v2 ld  on ld.device_pk = add.listener_id
where family(listener_ip) <> 6 and listener_ip <> '::1' and listener_ip <> '127.0.0.1' and listener_service_topology_status <> 3 and client_service_topology_status <> 3 and ld.tags is not null and date_part('day', now() :: timestamp - client_connection_last_found :: timestamp) <= 30;