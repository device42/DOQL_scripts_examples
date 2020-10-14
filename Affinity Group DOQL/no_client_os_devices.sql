/*
Affinity Group query to remove any devices with a client OS.
*/
select * from view_affinity_dependency_data_v1
where
listener_os not like '%Windows 10%' and listener_os not like '%Windows 7%' and listener_os not like '%Windows 8%' and listener_os not like '%Windows XP%' and
client_os not like '%Windows 10%' and client_os not like '%Windows 7%' and client_os not like '%Windows 8%' and client_os not like '%Windows XP%' and
family(listener_ip) <> 6 and listener_ip <> '::1' and listener_ip <> '127.0.0.1' and listener_service_topology_status <> 3 and client_service_topology_status <> 3 and date_part('day', now() :: timestamp - client_connection_last_found :: timestamp) <= 30