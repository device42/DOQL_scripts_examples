/*
Built to be a concise report of application components with connections.
This leverages services that have been discovered with an App Comp, and joins their clients as the "dependents".
*/
select distinct
sac.name "App Comp",
d.name "Device",
s.name "Software Name",
siu.alias_name "Software Alias",
siu.version "Version",
sc.port "Port",
adb.name "DB Product Name",
adb.version "DB Product Version",
adbi.instance "DB Instance",
concat(cd.name, '|', sc.client_ip, '|', sc.client_process_display_name) "Dependents"
from view_serviceinstance_v2 si
left join view_servicelistenerport_v2 lp on si.serviceinstance_pk = lp.discovered_serviceinstance_fk
join view_servicecommunication_v2 sc on sc.servicelistenerport_fk = lp.servicelistenerport_pk
join view_serviceinstance_appcomp_v2 sica on sica.serviceinstance_fk = si.serviceinstance_pk
join view_appcomp_v1 sac on sac.appcomp_pk = sica.appcomp_fk
join view_device_v1 d on d.device_pk = sac.device_fk
left join view_device_v1 cd on cd.device_pk = sc.client_device_fk
left join view_appcomp_db_products_v1 adb on adb.appcomp_fk = sac.appcomp_pk
left join view_appcomp_db_data_paths_v1 adbp on adbp.appcomp_fk = sac.appcomp_pk
left join view_appcomp_db_protocols_v1 adpr on adpr.appcomp_fk = sac.appcomp_pk
left join view_appcomp_db_instances_v1 adbi on adbi.appcomp_fk = sac.appcomp_pk
left join view_softwareinuse_v1 siu on siu.appcomp_fk = sac.appcomp_pk
left join view_software_v1 s on s.software_pk = siu.software_fk