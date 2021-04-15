/*
 - Name: Device Connectivity
 - Purpose: Query that exports the current devices with connections.
 - Date Created: 10/01/20
 - Changes:
  Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
  - bladeno to blade_slot_no
*/
Select
    d.name "Device Name"
    ,hp.hwaddress "Host MAC Address"
    ,hp.port "Host Port"
    ,sp.port "Switch Port"
    ,sp.hwaddress "Switch MAC Address"
    ,s.name "Switch Name"
    ,v.number "VLAN"
From view_device_v2 d
    Join view_netport_v1 hp ON hp.device_fk =  d.device_pk
    Join view_netport_v1 sp ON (sp.netport_pk = hp.remote_netport_fk or sp.remote_netport_fk = hp.netport_pk)
    Join view_device_v2 s ON s.device_pk = sp.device_fk and s.network_device = 't'
    Left Join  view_vlan_on_netport_v1 vp ON vp.netport_fk = sp.netport_pk
    Left Join  view_vlan_v1 v ON v.vlan_pk = vp.vlan_fk
    Left Join  view_hardware_v1 hws ON hws.hardware_pk = s.hardware_fk
    Left Join  view_hardware_v1 hw ON hw.hardware_pk = d.hardware_fk
    Left Join  view_device_v1 hv ON d.virtual_host_device_fk = hv.device_pk
    Left Join  view_devices_in_cluster_v1 c ON c.child_device_fk = coalesce(hv.device_pk, case when d.blade_slot_no <> '' then d.device_pk end)
Where d.network_device = 'f' and s.name <> ''
Order by d.name ASC