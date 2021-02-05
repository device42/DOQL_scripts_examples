select
    sp.port "Switch Port",
    sp.description "Switch Port Description",
    sp.hwaddress "Switch MAC Address",
    sd.name "Switch Name",
    rd.name "Remote Device",
    rp.hwaddress "Remote MAC Address",
    rp.port "Remote Port",
    rp.description "Remote Port Description",
    v.number "VLAN"
FROM
    view_netport_v1 sp
    join view_device_v2 sd on sd.device_pk = sp.device_fk and sd.network_device = 't'
    left join view_netport_v1 rp on rp.remote_netport_fk = sp.remote_netport_fk
    left join view_device_v2 rd on rd.device_pk = rp.device_fk
    left join view_vlan_on_netport_v1 vp on vp.netport_fk = sp.netport_pk
    left join view_vlan_v1 v on v.vlan_pk = vp.vlan_fk
order by sd.name ASC