/*  Subnet to Parent VLAN report
 - Changes:
  4/15/21
   - change device_v1 to device_v2 
*/
Select 	
	array_to_string(array_agg(distinct concat(v.number)),';') as vlan_identifier
	,left(array_to_string(array_agg(distinct concat(replace(v.name,',',''))),';'),8000) as vlan_name
	,array_to_string(array_agg(distinct concat(s.network,'/',s.mask_bits)),';') as subnet_network
	,array_to_string(array_agg(distinct concat(s.range_begin)),';') as range_begin
	,array_to_string(array_agg(distinct concat(s.range_end)),';') as range_end
	,left(array_to_string(array_agg(distinct concat(replace(n.description,',',''))),';'),8000) as ifalias
	,array_to_string(array_agg(distinct concat(d.name)),';') as devicename
	,max(v.last_edited) as datefoundlast
From view_vlan_v1 v 
	left join view_vlan_on_netport_v1 vn on vn.vlan_fk = v.vlan_pk 
	left join view_netport_v1 n on n.netport_pk = vn.netport_fk 
	left join view_device_v2 d on d.device_pk = n.device_fk 
	left join view_subnet_v1 s on s.parent_vlan_fk = v.vlan_pk	
Where v.number NOT IN (0,1) and s.network <> '0.0.0.0'
Group by v.vlan_pk   
Order by vlan_identifier