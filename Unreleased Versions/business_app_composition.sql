WITH

/* Get PDUs and their relationships to impacted infrastructure*/
  pdu_biz_apps AS (
    WITH 
          pdus AS (
            SELECT name
                   ,pdu_pk
                   ,CONCAT('/admin/rackraj/pdu/',pdu_pk,'/') "url_string"
                   ,CONCAT('/admin/rackraj/tools/connections/pdu/',pdu_pk,'/') "map_url_string"
                   ,CONCAT('/admin/rackraj/pdu/power_trends/',pdu_pk,'/') "trends_url_string"
            FROM view_pdu_v1
          ),
          impacted_devices AS (
            SELECT d.device_pk
                   ,d.name "device" 
                   ,COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk) "host_id"
                   ,h.name "host"
                   ,b.name "business_application"
                   ,b.businessapplication_pk "business_app_id"
                   ,COALESCE(d.physicalsubtype, d.virtualsubtype) "device_subtype"
            FROM view_device_v2 d
            LEFT JOIN view_device_v2 h on h.device_pk = COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk)
            JOIN view_businessapplicationelement_v1 bae on bae.device_fk = d.device_pk
            JOIN view_businessapplication_v1 b on b.businessapplication_pk = bae.businessapplication_fk 
          )
    SELECT SPLIT_PART(p.name,' ',1) "object_name"
           ,CONCAT('<a href="',p.url_string,' "target="_blank" rel="noopener noreferrer">',SPLIT_PART(p.name,' ',1),'</a>') "object"
           ,CONCAT('<a href="',p.map_url_string,' "target="_blank" rel="noopener noreferrer">','Port Map View</a>') "relationship_view_url"
           ,CONCAT('<a href="',p.trends_url_string,' "target="_blank" rel="noopener noreferrer">','PDU Trends View</a>') "trends_url"
           ,pp.port_name "port"
           ,pp.port_type_name  "type"
           ,id.device "impacted_object"
           ,CASE WHEN id.host IS NOT NULL THEN id.host 
                 ELSE 'No Host'
           END "device_host"
           ,id.device_subtype
           ,CASE WHEN id.device_pk = pp.psu_device_fk THEN 'Connected to PDU'
                 ELSE 'Client on Host with PDU'
           END "impact_reason"
           ,id."business_app_id"
           ,'pdu' "relationship_type"
    FROM pdus p
    JOIN view_pduports_v1 pp on pp.pdu_fk = p.pdu_pk 
    JOIN impacted_devices id on id.device_pk = pp.psu_device_fk OR id.host_id = pp.psu_device_fk
  ),

/* Get network devices and their relationships to impacted infrastructure*/
  network_biz_apps AS (
    WITH
          network_devices AS (
            SELECT name
                   ,device_pk
                   ,CONCAT('/admin/rackraj/device/',device_pk,'/') "url_string"
                   ,CONCAT('/admin/rackraj/device/impactgraph/',device_pk,'/?diagram_type=netports') "map_url_string"
                   ,'No Trends' "trends_url_string"
            FROM view_device_v2
            WHERE network_device = True
          ),
          impacted_devices AS (
            SELECT d.device_pk
                   ,d.name "device" 
                   ,COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk) "host_id"
                   ,h.name "host"
                   ,b.name "business_application"
                   ,b.businessapplication_pk "business_app_id"
                   ,COALESCE(d.physicalsubtype, d.virtualsubtype) "device_subtype"
            FROM view_device_v2 d
            LEFT JOIN view_device_v2 h on h.device_pk = COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk)
            JOIN view_businessapplicationelement_v1 bae on bae.device_fk = d.device_pk
            JOIN view_businessapplication_v1 b on b.businessapplication_pk = bae.businessapplication_fk
          )
    SELECT p.name "object_name"
           ,CONCAT('<a href="',p.url_string,' "target="_blank" rel="noopener noreferrer">',p.name,'</a>') "object"
           ,CONCAT('<a href="',p.map_url_string,' "target="_blank" rel="noopener noreferrer">','Switch Port Map View</a>') "relationship_view_url"
           ,p.trends_url_string "trends_url"
           ,pnp.port "port"
           ,pnp.type_name  "type"
           ,id.device "impacted_object"
           ,CASE WHEN id.host IS NOT NULL THEN id.host 
                 ELSE 'No Host'
           END "device_host"
           ,id.device_subtype
           ,CASE WHEN id.device_pk = idp.device_fk THEN 'Connected to Switch'
                 ELSE 'Client on Host with Switch Connection'
           END "impact_reason"
           ,id."business_app_id"
           ,'network' "relationship_type"
    FROM network_devices p
    JOIN view_netport_v1 pnp on pnp.device_fk = p.device_pk 
    JOIN view_netport_v1 idp on (idp.netport_pk  = pnp.remote_netport_fk OR idp.remote_netport_fk = pnp.netport_pk)
    JOIN impacted_devices id on id.device_pk = idp.device_fk  OR id.host_id = idp.device_fk  
  ),

/* Get host devices and their relationships to impacted infrastructure*/
  host_biz_apps AS (
    WITH
          host_devices AS (
            SELECT name
                   ,device_pk
                   ,CONCAT('/admin/rackraj/device/',device_pk,'/') "url_string"
                   ,CONCAT('/admin/rackraj/device/impactgraph/',device_pk,'/') "map_url_string"
                   ,'No Trends' "trends_url_string"
            FROM view_device_v2
            WHERE virtual_host = True OR blade_chassis = True
          ),
          impacted_devices AS (
            SELECT d.device_pk
                   ,d.name "device" 
                   ,COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk) "host_id"
                   ,h.name "host"
                   ,b.name "business_application"
                   ,b.businessapplication_pk "business_app_id"
                   ,COALESCE(d.physicalsubtype, d.virtualsubtype) "device_subtype"
            FROM view_device_v2 d
            LEFT JOIN view_device_v2 h on h.device_pk = COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk)
            JOIN view_businessapplicationelement_v1 bae on bae.device_fk = d.device_pk
            JOIN view_businessapplication_v1 b on b.businessapplication_pk = bae.businessapplication_fk
          )
    SELECT p.name "object_name"
           ,CONCAT('<a href="',p.url_string,' "target="_blank" rel="noopener noreferrer">',p.name,'</a>') "object"
           ,CONCAT('<a href="',p.map_url_string,' "target="_blank" rel="noopener noreferrer">','Host Map View</a>') "relationship_view_url"
           ,p.trends_url_string "trends_url"
           ,'N/A' "port"
           ,id."device_subtype"  "type"
           ,id.device "impacted_object"
           ,CASE WHEN id.host IS NOT NULL THEN id.host 
                 ELSE 'No Host'
           END "device_host"
           ,id.device_subtype
           ,'Client on Host' "impact_reason"
           ,id."business_app_id"
           ,'guest vm or blade chassis ' "relationship_type"
    FROM host_devices p
    JOIN impacted_devices id on id."host_id" = p.device_pk
  ),

/* Get app servers and their relationships to impacted infrastructure*/
  appservers_biz_apps AS (
    WITH
          app_comps AS (
            SELECT ac.name
                   ,ac.appcomp_pk
                   ,ac.application_category_name
                   ,ba.name "business_app"
                   ,ba.businessapplication_pk
                   ,COALESCE(ac.device_fk, ac.resource_fk) "related_object_id" 
                   ,CONCAT('/admin/rackraj/appcomp/',ac.appcomp_pk,'/') "url_string"
                   ,CASE WHEN ac.device_fk IS NOT NULL THEN CONCAT('/admin/rackraj/device/impactgraph/',ac.device_fk,'/') 
                         WHEN ac.resource_fk IS NOT NULL THEN CONCAT('/admin/rackraj/resource/',ac.resource_fk,'/map/')
                         ELSE 'No Relationship View'
                   END "map_url_string"
                   ,'No Trends' "trends_url_string"
            FROM view_appcomp_v1 ac
            LEFT JOIN view_businessapplicationelement_v1 bae on bae.appcomp_fk = ac.appcomp_pk
            LEFT JOIN view_businessapplication_v1 ba on ba.businessapplication_pk = bae.businessapplication_fk 
          ),
          impacted_devices AS (
            SELECT d.device_pk
                   ,d.name "device" 
                   ,COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk) "host_id"
                   ,h.name "host"
                   ,b.name "business_application"
                   ,b.businessapplication_pk "business_app_id"
                   ,COALESCE(d.physicalsubtype, d.virtualsubtype) "device_subtype"
            FROM view_device_v2 d
            LEFT JOIN view_device_v2 h on h.device_pk = COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk)
            JOIN view_businessapplicationelement_v1 bae on bae.device_fk = d.device_pk
            JOIN view_businessapplication_v1 b on b.businessapplication_pk = bae.businessapplication_fk
          )
    SELECT p.name "object_name"
           ,CONCAT('<a href="',p.url_string,' "target="_blank" rel="noopener noreferrer">',p.name,'</a>') "object"
           ,CONCAT('<a href="',p.map_url_string,' "target="_blank" rel="noopener noreferrer">','App Relationship View</a>') "relationship_view_url"
           ,p.trends_url_string "trends_url"
           ,'N/A' "port"
           ,CASE WHEN p.application_category_name IS NULL THEN 'Application Component' 
                 ELSE p.application_category_name
           END "type"
           ,id.device "impacted_object"
           ,CASE WHEN id.host IS NOT NULL THEN id.host 
                 ELSE 'No Host'
           END "device_host"
           ,id.device_subtype
           ,'Application Component' "impact_reason"
           ,COALESCE(p.businessapplication_pk, id."business_app_id") "business_app_id"
           ,CASE WHEN p.application_category_name IS NULL THEN 'Application Component'
                 ELSE p.application_category_name
           END "relationship_type"
    FROM app_comps p
    JOIN impacted_devices id on id.device_pk = p."related_object_id"
  ),

/* Get LB Virtual Server Affinity Groups and their relationships to pool member infrastructure*/
  lb_vs_biz_apps AS (
    WITH
          virtual_servers AS (
            SELECT ag.primary_resource_name "name"
                   ,ag.primary_resource_fk
                   ,COALESCE(add.listener_id, add.client_id) "related_object_id"
                   ,add.listener_port
                   ,add.listener_service
                   ,r.vendor_resource_type 
                   ,CONCAT('/admin/rackraj/resource/',ag.primary_resource_fk,'/') "url_string"
                   ,CONCAT('/admin/rackraj/affinitygroup/chart/',ag.affinitygroup_pk,'/') "map_url_string"
                   ,'No Trends' "trends_url_string"
            FROM view_affinitygroup_v2 ag
            JOIN view_affinity_dependency_data_v1 add on COALESCE(add.listener_resource_id, add.client_resource_id) = ag.primary_resource_fk 
            JOIN view_resource_v2 r on r.resource_pk = ag.primary_resource_fk 
            WHERE ag.primary_resource_fk IS NOT NULL
          ),
          impacted_devices AS (
            SELECT d.device_pk
                   ,d.name "device" 
                   ,COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk) "host_id"
                   ,h.name "host"
                   ,b.name "business_application"
                   ,b.businessapplication_pk "business_app_id"
                   ,COALESCE(d.physicalsubtype, d.virtualsubtype) "device_subtype"
            FROM view_device_v2 d
            LEFT JOIN view_device_v2 h on h.device_pk = COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk)
            JOIN view_businessapplicationelement_v1 bae on bae.device_fk = d.device_pk
            JOIN view_businessapplication_v1 b on b.businessapplication_pk = bae.businessapplication_fk
          )
    SELECT p.name "object_name"
           ,CONCAT('<a href="',p.url_string,' "target="_blank" rel="noopener noreferrer">',p.name,'</a>') "object"
           ,CONCAT('<a href="',p.map_url_string,' "target="_blank" rel="noopener noreferrer">','Pool Map View</a>') "relationship_view_url"
           ,p.trends_url_string "trends_url"
           ,p.listener_port::text "port"
           ,p.vendor_resource_type "type"
           ,id.device "impacted_object"
           ,CASE WHEN id.host IS NOT NULL THEN id.host 
                 ELSE 'No Host'
           END "device_host"           
           ,id.device_subtype
           ,'Virtual Server to Pool Member' "impact_reason"
           ,id."business_app_id" "business_app_id"
           ,'LB Pool Member' "relationship_type"
    FROM virtual_servers p
    JOIN impacted_devices id on id.device_pk = p."related_object_id"
  ),

/* Get virtual disks on storage arrays and their relationships to business app infrastructure*/
  vdisk_storage_biz_apps AS (
    WITH
        vdisks AS (
         SELECT vd.name
               ,vd.identifier 
               ,vd.virtualmachine_name "vm_name"
               ,vd.virtualmachine_fk "vm_id"
               ,vd.hypervisor_name "host"
               ,vd.hypervisor_fk "host_id"
               ,vd.file_name::text "object_details"
               ,vds.storageresource_name 
               ,vds.storagearray_name
               ,vds.storagearray_fk
               ,'vdisk to array' "relationship_type"
               ,CONCAT('/admin/rackraj/storage/',vds.storagearray_fk,'/') "url_string"
               ,CONCAT('/admin/rackraj/storage/',vds.storagearray_fk,'/map/') "map_url_string"
               ,CONCAT('/admin/rackraj/storage/',vds.storagearray_fk,'/trends/') "trends_url_string"
               ,COALESCE(d.physicalsubtype,d.virtualsubtype) "device_subtype"
               ,ba.businessapplication_pk "business_app_id"
        FROM view_vdisk_v2 vd
        JOIN view_vdisk_to_storagearray_v2 vds on vds.vdisk_fk = vd.vdisk_pk
        JOIN view_businessapplicationelement_v1 bae on bae.device_fk = vd.virtualmachine_fk
        JOIN view_businessapplication_v1 ba on ba.businessapplication_pk = bae.businessapplication_fk
        JOIN view_device_v2 d on vd.virtualmachine_fk = d.device_pk
        WHERE vds.storagearray_fk IS NOT NULL
        )
    SELECT p.storagearray_name "object_name"
           ,CONCAT('<a href="',p.url_string,' "target="_blank" rel="noopener noreferrer">',p.name,'</a>') "object"
           ,CONCAT('<a href="',p.map_url_string,' "target="_blank" rel="noopener noreferrer">','Storage Map View</a>') "relationship_view_url"
           ,p.trends_url_string "trends_url"
           ,'N/A' "port"
           ,'virtual disk' "type"
           ,p.vm_name "impacted_object"
           ,p.host "device_host"           
           ,p.device_subtype
           ,'Virtual Disk on Host Backed by Array' "impact_reason"
           ,p."business_app_id" "business_app_id"
           ,'Virtual Disk on Array' "relationship_type"
    FROM vdisks p
  ),

  /* Get Certs and their relationships to impacted infrastructure*/
  cert_biz_apps AS (
    WITH 
          certs AS (
            SELECT issued_to "name"
                   ,certificate_pk
                   ,CONCAT('/admin/rackraj/certificate/',certificate_pk,'/') "url_string"
                   ,'No Relationship View' "map_url_string"
                   ,'No Trends' "trends_url_string"
            FROM view_certificate_v1
          ),
          impacted_devices AS (
            SELECT d.device_pk
                   ,d.name "device"
                   ,COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk) "host_id"
                   ,h.name "host"
                   ,b.name "business_application"
                   ,b.businessapplication_pk "business_app_id"
                   ,COALESCE(d.physicalsubtype, d.virtualsubtype) "device_subtype"
            FROM view_device_v2 d
            LEFT JOIN view_device_v2 h on h.device_pk = COALESCE(d.virtual_host_device_fk, d.host_chassis_device_fk)
            JOIN view_businessapplicationelement_v1 bae on bae.device_fk = d.device_pk
            JOIN view_businessapplication_v1 b on b.businessapplication_pk = bae.businessapplication_fk
          )
    SELECT p."name" "object_name"
           ,CONCAT('<a href="',p.url_string,' "target="_blank" rel="noopener noreferrer">',p."name",'</a>') "object"
           ,CONCAT('<a href="',p.map_url_string,' "target="_blank" rel="noopener noreferrer">','Port Map View</a>') "relationship_view_url"
           ,CONCAT('<a href="',p.trends_url_string,' "target="_blank" rel="noopener noreferrer">','PDU Trends View</a>') "trends_url"
           ,'N/A' "port"
           ,dc.ssl_version "type"
           ,id.device "impacted_object"
           ,CASE WHEN id.host IS NOT NULL THEN id.host 
                 ELSE 'No Host'
           END "device_host"
           ,id.device_subtype
           ,CONCAT('Certificate Valid to',': ', dc.valid_to)"impact_reason"
           ,id."business_app_id"
           ,'Certificate' "relationship_type"
    FROM certs p
    JOIN view_devicecertificate_v1 dc on dc.certificate_fk = p.certificate_pk 
    JOIN impacted_devices id on id.device_pk = dc.device_fk
  ),

/* union all infrastructure and relationships*/
  related_object_union AS (
    SELECT * FROM pdu_biz_apps
    UNION ALL
    SELECT * FROM network_biz_apps
    UNION ALL
    SELECT * FROM host_biz_apps
    UNION ALL
    SELECT * FROM appservers_biz_apps
    UNION ALL
    SELECT * FROM lb_vs_biz_apps
    UNION ALL
    SELECT * FROM vdisk_storage_biz_apps
    UNION ALL
    SELECT * FROM cert_biz_apps    
  ),
  biz_apps AS (
            SELECT ba.name "name"
                   ,ba.businessapplication_pk
                   ,CONCAT('/admin/rackraj/businessapp/',ba.businessapplication_pk,'/') "url_string"
                   ,CONCAT('/admin/rackraj/businessapp/',ba.businessapplication_pk,'/view_application/') "map_url_string"
            FROM view_businessapplication_v1 ba
  )
SELECT DISTINCT 
       ba.name "business_app_name"
       ,CONCAT('<a href="',ba.url_string,' "target="_blank" rel="noopener noreferrer">',ba.name,'</a>') "business_app"
       ,CONCAT('<a href="',ba.map_url_string,' "target="_blank" rel="noopener noreferrer">','Business App Diagram</a>') "ba_diagram_url"       
       ,p."object_name"
       ,p."object"
       ,p."relationship_view_url"
       ,p."trends_url"
       ,CASE WHEN p."port" IS NULL THEN 'No Port'
             ELSE p."port"
       END "port"
       ,CASE WHEN p."type" IS NULL THEN 'N/A'
             ELSE p."type"
       END "type"
       ,p."impacted_object"
       ,p."device_host"
       ,p."device_subtype"
       ,p."impact_reason"
       ,p."business_app_id"
       ,p."relationship_type"
FROM biz_apps ba
JOIN related_object_union p on p."business_app_id" = ba.businessapplication_pk
ORDER BY ba.name ASC, p."relationship_type"