/* Software Inventory Data Extract    
   
   Update 2020-10-19
   - updated the view_device_v1 to view_device_v2	
*/
Select 
	d.name "Device Name"
	,(SELECT array_to_string(array(
			Select ip.ip_address
			From view_ipaddress_v1 ip
			Where ip.device_fk = d.device_pk),
			' | ')) "Device IP Addresses"
	,s.software_pk "Software ID"
	,s.name "Software Name"
    ,v.name "Vendor"
	,siu.component_name "Software Component Name"
	,ac.name "Related App Comp"
	,siu.alias_name "Software Alias"
	,siu.version "Software Version"
	,siu.file_version "File Version"
	,siu.install_date "Installation Date"
	,siu.install_path "Installation Path"
From view_softwareinuse_v1 siu
Left Join view_software_v1 s ON s.software_pk = siu.software_fk
Left Join view_vendor_v1 v ON v.vendor_pk = s.vendor_fk
Left Join view_appcomp_v1 ac ON siu.appcomp_fk = ac.appcomp_pk
Left Join view_device_v2 d ON siu.device_fk = d.device_pk
Left Join view_ipaddress_v1 ip ON ip.device_fk = d.device_pk
Order by d.name ASC