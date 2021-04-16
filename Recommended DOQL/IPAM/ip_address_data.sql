/*
 - Name: IP Address Data
 - Purpose: Query for all IP Addresses
 - Date Created: 10/01/20
 - Changes:
  4/15/21
   - change device_v1 to device_v2 
*/
Select
   ip.ip_address "IP Address",
   ip.label "IP Address Label",
   ip.type "Type",
   s.network "Subnet",
   np.port "Port"
  from view_ipaddress_v1 ip
  left join view_subnet_v1 s on s.subnet_pk = ip.subnet_fk
  left join view_device_v2 d on d.device_pk = ip.device_fk
  left join view_netport_v1 np on np.netport_pk = ip.netport_fk
  left join view_vlan_v1 v on v.vlan_pk = s.parent_vlan_fk
  left join view_vrfgroup_v1 vr on vr.vrfgroup_pk = s.vrfgroup_fk