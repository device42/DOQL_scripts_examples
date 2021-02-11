/* Find the DNS records for all discovery scores that have a DNS record.
If no DNS record match then drop.
  Created - 01/26/21
*/
 /*  Inline view of target data required (CTE - Common Table Expression) 
  Get target data       
 */
 With target_discovery_data  as (
    Select Distinct
        ds.discovery_server "Discovered Server"
		,vd.job_name "Discovery Job"
		,ds.port_check "Port Check"
		,ds.authorization "Authorization"
        ,dr.content "DNS IP"
        ,dr.name  "DNS Name"
        ,concat(dr.name,'.',dz.name) "FQDN"
--      ,dr.*
    From 
        view_discoveryscores_v1 ds
		join view_jobscore_v1 js ON js.jobscore_pk = ds.jobscore_fk
		join view_vserverdiscovery_v1 vd ON vd.vserverdiscovery_pk = js.vserverdiscovery_fk
        Join view_dnsrecords_v1 dr ON dr.content = ds.discovery_server and dr.type = 'A'
        Left Join view_dnszone_v1 dz ON dz.dnszone_pk = dr.dnszone_fk
    Order by 1
    )
/* Put out all the records  */
    Select 
       tdd.*
    From target_discovery_data tdd