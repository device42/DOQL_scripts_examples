/*
Built to be a concise report of application components with connections.
This leverages services that have been discovered with an App Comp, and Joins their clients as the "dependents".
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
*/
Select distinct
    sac.name "App Comp "
    ,d.name "Device "
    ,s.name "Software Name "
    ,siu.alias_name "Software Alias "
    ,siu.version "Version "
    ,sc.port "Port "
    ,adb.name "DB Product Name "
    ,adb.version "DB Product Version "
    ,adbi.instance "DB Instance "
    ,concat(cd.name, '|', sc.client_ip, '|', sc.client_process_display_name) "Dependents"
From view_serviceinstance_v2 si
Left Join view_servicelistenerport_v2 lp ON si.serviceinstance_pk = lp.discovered_serviceinstance_fk
Join view_servicecommunication_v2 sc ON sc.servicelistenerport_fk = lp.servicelistenerport_pk
Join view_serviceinstance_appcomp_v2 sica ON sica.serviceinstance_fk = si.serviceinstance_pk
Join view_appcomp_v1 sac ON sac.appcomp_pk = sica.appcomp_fk
Join view_device_v2 d ON d.device_pk = sac.device_fk
Left Join view_device_v1 cd ON cd.device_pk = sc.client_device_fk
Left Join view_appcomp_db_products_v1 adb ON adb.appcomp_fk = sac.appcomp_pk
Left Join view_appcomp_db_data_paths_v1 adbp ON adbp.appcomp_fk = sac.appcomp_pk
Left Join view_appcomp_db_protocols_v1 adpr ON adpr.appcomp_fk = sac.appcomp_pk
Left Join view_appcomp_db_instances_v1 adbi ON adbi.appcomp_fk = sac.appcomp_pk
Left Join view_softwareinuse_v1 siu ON siu.appcomp_fk = sac.appcomp_pk
Left Join view_software_v1 s ON s.software_pk = siu.software_fk