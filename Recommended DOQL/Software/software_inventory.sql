/* Software Inventory Data Extract    
    Update 2020-10-19 
        - updated the view_device_v1 to view_device_v2
    Update 2021-04-07
        - changed array_to_string to CTE to fix duplicate SIU records when devices have more than 1 IP
        - changed left join on device view to join to remove siu records where there is no device fk
*/
WITH ip_info AS (
    SELECT 
        ip.device_fk d_fk,
        array_to_string(array_agg(ip.ip_address), ' | ') d_ips
    FROM 
        view_ipaddress_v1 ip 
    WHERE ip.device_fk IS NOT NULL
    GROUP BY ip.device_fk
)
Select 
	d.name "Device Name"
    ,d.device_pk "Device ID"
    ,i.d_ips "Device IP Addresses"
	,s.software_pk "Software ID"
    ,siu.softwareinuse_pk "SIU PK"
	,s.name "Software Name"
	,siu.component_name "Software Component Name"
	,ac.name "Related App Comp"
	,siu.alias_name "Software Alias"
	,siu.version "Software Version"
	,siu.file_version "File Version"
	,siu.install_date "Installation Date"
	,siu.install_path "Installation Path"
    ,s.licensed_count "Allowed License Count"
    ,s.discovered_count "Discovered License Count"
From view_softwareinuse_v1 siu
Left Join view_software_v1 s ON s.software_pk = siu.software_fk
Left Join view_appcomp_v1 ac ON siu.appcomp_fk = ac.appcomp_pk
Join view_device_v2 d ON siu.device_fk = d.device_pk
Left Join ip_info i ON i.d_fk = d.device_pk
Order by d.name ASC