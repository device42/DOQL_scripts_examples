/*
 - Name: IP Address Data
 - Purpose: Query for all IP Addresses
 - Date Created: 10/01/20
 - Changes:
 Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
*/
Select
   ip.ip_address "IP Address"
   ,ip.label "IP Address Label"
   ,ip.type "Type"
   ,s.network "Subnet"
   ,np.port "Port"
  From view_ipaddress_v1 ip
   Left Join view_subnet_v1 s ON s.subnet_pk = ip.subnet_fk
   Left Join view_device_v2 d ON d.device_pk = ip.device_fk
   Left Join view_netport_v1 np ON np.netport_pk = ip.netport_fk
   Left Join view_vlan_v1 v ON v.vlan_pk = s.parent_vlan_fk
   Left Join view_vrfgroup_v1 vr ON vr.vrfgroup_pk = s.vrfgroup_fk