/*
DOQL for App Comp's with related software in use details.
*/
select
ac.name "App Comp",
d.name "Device",
d.os_name "Device OS",
d.os_version "OS Version",
d.os_version_no "OS Version Number",
ip.ip_address "Device IP",
s.name "Software Name",
si.alias_name "Software Alias",
si.version "Version",
concat(acws.web_site, '|', acws.pool_name, '|', acws.description, '|', acwb.binding, '|', acwb.protocol) "Web App Details",
concat(acwvd.path, '|', acwvd.physical_path) "Web Dir Path",
concat(acwdb.name, '|', acwdb.connection, '|', acwdb.provider) "Web DB Connection",
adb.name "DB Product Name",
adb.version "DB Product Version",
adbi.instance "DB Instance"
from view_appcomp_v1 ac
left join view_device_v1 d on d.device_pk = ac.device_fk
left join view_ipaddress_v1 ip on ip.device_fk = d.device_pk
left join view_softwareinuse_v1 si on si.appcomp_fk = ac.appcomp_pk
left join view_software_v1 s on s.software_pk = si.software_fk
left join view_appcomp_db_products_v1 adb on adb.appcomp_fk = ac.appcomp_pk
left join view_appcomp_db_data_paths_v1 adbp on adbp.appcomp_fk = ac.appcomp_pk
left join view_appcomp_db_protocols_v1 adpr on adpr.appcomp_fk = ac.appcomp_pk
left join view_appcomp_db_instances_v1 adbi on adbi.appcomp_fk = ac.appcomp_pk
left join view_appcompwebapps_v1 acw on acw.appcomp_fk = ac.appcomp_pk
left join view_appcomp_web_bindings_v1 acwb on acwb.appcomp_fk = ac.appcomp_pk
left join view_appcomp_web_sites_v1 acws on acws.appcomp_fk = ac.appcomp_pk
left join view_appcomp_web_virtual_dir_v1 acwvd on acwvd.appcompwebapps_fk = acw.appcompwebapps_pk
left join view_appcomp_web_sites_db_conn_v1 acwdb on acwdb.appcompwebapps_fk = acw.appcompwebapps_pk