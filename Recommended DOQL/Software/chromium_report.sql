select
vnd.name "Vendor"
,sw.name "Software"
,siu.version "Version"
,siu.alias_name "Alias"
,d.name "Host"
,siu.first_detected "First Detected"
,siu.last_updated "Last Updated"
,dll.username "Last Logged On User"
from view_Device_v2 d
join view_softwareinuse_v1 siu on d.device_pk = siu.device_fk
join view_software_v1 sw on siu.software_fk = sw.software_pk
Join view_vendor_v1 vnd ON vnd.vendor_pk = sw.vendor_fk
left join view_devicelastlogin_v1 dll on d.device_pk = dll.device_fk
where sw.name = 'Google Chrome' and siu.version < '98.0.4758.102'
      OR sw.name = 'Microsoft Edge' and siu.version < '98.0.1108.55'