/*Include IPV6*/
select * from view_affinity_dependency_data_v1
where listener_ip <> '::1' and listener_ip <> '127.0.0.1' and listener_service_topology_status <> 3 and client_service_topology_status <> 3 and date_part('day', now() :: timestamp - client_connection_last_found :: timestamp) <= 30;