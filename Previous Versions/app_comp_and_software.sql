/*
DOQL for App Comp's with related software in use details.
*/
select
ac.name "App Comp",
d.name "Device",
d.os_name "OS Name",
d.os_version "OS Version",
d.os_version_no "OS Version Number",
ip.ip_address "Device IP",
s.name "Software Name",
si.alias_name "Software Alias",
si.version "Version"
from view_appcomp_v1 ac
left join view_device_v1 d on d.device_pk = ac.device_fk
left join view_ipaddress_v1 ip on ip.device_fk = d.device_pk
left join view_softwareinuse_v1 si on si.appcomp_fk = ac.appcomp_pk
left join view_software_v1 s on s.software_pk = si.software_fk