/*
 - Name: Cloud DNS
 - Purpose: Provides details on discovered DNS information for CSP's.
 - Date Created:10/01/20
 - Changes:
*/
With 
    target_zone_cloud_data  as (
Select 
	dz.dnszone_pk
    ,ci.cloudinfrastructure_name "Cloud Infrastructure Name"
    ,ci.account_id "Account ID"
    ,ci.organization "Organization"
    ,dz.name "DNS Zone"
    ,dz.nameserver "Nameserver"
    ,dz.date_added "Zone First Discovered"
    ,dz.date_updated "Zone Last Discovered"
    ,dz.vrfgroup_fk
 From view_dnszone_v1 dz 
 Join view_cloudinfrastructure_v2 ci on ci.cloudinfrastructure_pk = dz.cloudinfrastructure_fk 	
 ) 	
Select 
    tzc."Cloud Infrastructure Name"
    ,tzc."Account ID"
    ,tzc."Organization"
    ,tzc."DNS Zone"
    ,tzc."Nameserver"
    ,tzc."Zone First Discovered"
    ,tzc."Zone Last Discovered"
    ,dr.name "Record Name"
    ,dr.type "Record Type"
    ,dr.content "Record Value"
    ,dr.ttl "Record TTL"
    ,dr.prio "Record Priority"
    ,dr.date_added "Record First Discovered"
    ,dr.date_updated "Record Last Discovered"
    ,vrf.name "VRF Group"
From view_dnsrecords_v1 dr 
Join target_zone_cloud_data tzc on tzc.dnszone_pk = dr.dnszone_fk 
Left Join view_vrfgroup_v1 vrf on vrf.vrfgroup_pk = tzc.vrfgroup_fk
Order by tzc."DNS Zone" ASC