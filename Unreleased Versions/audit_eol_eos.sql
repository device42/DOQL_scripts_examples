WITH

/* Select all eol & eos data to union to one table */
    hardware_eol_eos AS (
        SELECT
              hardware_pk "object_id"
              ,name "object_name"
              ,'N/A' "version"
              ,end_of_support_date "eos_date"
              ,end_of_life_date "eol_date"
              ,CONCAT('/admin/rackraj/hardware/',hardware_pk,'/') "url_string"
              ,'Hardware' "audit_type"
        FROM view_hardware_v2
        WHERE end_of_support_date IS NOT NULL or end_of_life_date IS NOT NULL
    ),
    operatingsystem_eol_eos AS (
            SELECT
              os.os_pk "object_id"
              ,os.name "object_name"
              ,eos.version "version"
              ,eos.eos "eos_date"
              ,eos.eol "eol_date"
              ,CONCAT('/admin/rackraj/os/',os.os_pk,'/') "url_string"
              ,'Operating System' "audit_type"
        FROM view_os_v1 os
        JOIN view_oseoleos_v1 eos ON eos.os_fk = os.os_pk
    ),
    software_eol_eos AS (
            SELECT
              s.software_pk "object_id"
              ,s.name "object_name"
              ,eos.version "version"
              ,eos.eos "eos_date"
              ,eos.eol "eol_date"
              ,CONCAT('/admin/rackraj/software/',s.software_pk,'/') "url_string"
              ,'Software' "audit_type"
        FROM view_software_v1 s
        JOIN view_softwareeoleos_v1 eos ON eos.software_fk = s.software_pk 
    ),
    eol_eos_union AS (
            SELECT * FROM hardware_eol_eos
            UNION ALL
            SELECT * FROM operatingsystem_eol_eos
            UNION ALL
            SELECT * FROM software_eol_eos
    ),
    
/* Select for software inventory with EOL/EOS data*/
    software_inventory AS (
            SELECT
              s."object_id" "software_id"
              ,siu.softwareinuse_pk "softwareinuse_id"
              ,siu.version "software_version"
              ,d.device_pk "device_id"
              ,ba.businessapplication_pk
              ,d.name "device_name"
              ,CONCAT('/admin/rackraj/device/',d.device_pk,'/') "url_string"
              ,CONCAT('/admin/rackraj/software_detail/',siu.softwareinuse_pk,'/') "softwaredetail_url_string"
        FROM software_eol_eos s
        JOIN view_softwareinuse_v1 siu ON siu.software_fk = s."object_id"
        JOIN view_device_v2 d ON d.device_pk = siu.device_fk
        LEFT JOIN view_businessapplicationelement_v1 bae ON bae.device_fk = d.device_pk
        LEFT JOIN view_businessapplication_v1 ba ON ba.businessapplication_pk = bae.businessapplication_fk        
    ),
    
/* Select for hardware inventory and business app relationship */
    hardware_inventory AS (
            SELECT
              d.device_pk "device_id"
              ,ba.businessapplication_pk
              ,d.name "device_name"
              ,d.hardware_fk "hardware_id"
              ,CONCAT('/admin/rackraj/device/',d.device_pk,'/') "url_string"
        FROM view_device_v2 d
        LEFT JOIN view_businessapplicationelement_v1 bae ON bae.device_fk = d.device_pk
        LEFT JOIN view_businessapplication_v1 ba ON ba.businessapplication_pk = bae.businessapplication_fk
    ),
    
/* Select for os inventory and business app relationship */
    os_inventory AS (
            SELECT
              d.device_pk "device_id"
              ,ba.businessapplication_pk
              ,d.name "device_name"
              ,d.os_fk "os_id"
              ,d.os_version "os_version"
              ,CONCAT('/admin/rackraj/device/',d.device_pk,'/') "url_string"
        FROM view_device_v2 d
        LEFT JOIN view_businessapplicationelement_v1 bae ON bae.device_fk = d.device_pk
        LEFT JOIN view_businessapplication_v1 ba ON ba.businessapplication_pk = bae.businessapplication_fk
    ),    

/* Select for Business Apps*/
    business_apps AS (
            SELECT
              ba.businessapplication_pk 
              ,ba.name "business_app"
              ,CONCAT('/admin/rackraj/businessapp/',ba.businessapplication_pk,'/') "ba_url_string"
            FROM view_businessapplication_v1 ba
    )
    
SELECT
       eu."audit_type" AS "Audit Type"
       ,ba."business_app" AS "Business App Name"
       ,eu."object_name" AS "Product Name"
       ,eu."version" AS "Product Version"
       ,COALESCE(s."device_name", h."device_name", os."device_name") AS "Device Name"
       ,eu."eos_date" AS "EOS Date"
       ,eu."eol_date" AS "EOL Date"
       ,eu."eos_date" - CURRENT_DATE AS "Days Until End of Support"
       ,eu."eol_date" - CURRENT_DATE AS "Days Until End of Life"
       ,CASE WHEN eu."eos_date" < CURRENT_DATE THEN True
            ELSE False
        END "Is End of Support"
       ,CASE WHEN eu."eol_date" < CURRENT_DATE THEN True
            ELSE False
        END "Is End of Life"
       ,CASE WHEN eu."eos_date" IS NULL THEN 'No EOS Date'
             WHEN eu."eos_date" < CURRENT_DATE THEN 'End of Support'
             WHEN (eu."eos_date" - CURRENT_DATE) BETWEEN 0 AND 90 THEN '3 Months'
             WHEN (eu."eos_date" - CURRENT_DATE) BETWEEN 91 AND 365 THEN '1 Year'
             WHEN (eu."eos_date" - CURRENT_DATE) BETWEEN 366 AND 1095 THEN '3 Years'
             WHEN (eu."eos_date" - CURRENT_DATE) BETWEEN 1096 AND 1825 THEN '5 Years'
            ELSE '5+ Years'
        END "EOS Groups"
       ,CASE WHEN eu."eol_date" IS NULL THEN 'No EOL Date'
             WHEN eu."eol_date" < CURRENT_DATE THEN 'End of Life'
             WHEN (eu."eol_date" - CURRENT_DATE) BETWEEN 0 AND 90 THEN '3 Months'
             WHEN (eu."eol_date" - CURRENT_DATE) BETWEEN 91 AND 365 THEN '1 Year'
             WHEN (eu."eol_date" - CURRENT_DATE) BETWEEN 366 AND 1095 THEN '3 Years'
             WHEN (eu."eol_date" - CURRENT_DATE) BETWEEN 1096 AND 1825 THEN '5 Years'
            ELSE '5+ Years'
        END "EOL Groups"
       ,CONCAT('<a href="',eu."object_id",' "target="_blank" rel="noopener noreferrer">',eu."object_name",'</a>') "Product"
       ,CONCAT('<a href="',ba."ba_url_string",' "target="_blank" rel="noopener noreferrer">',ba."business_app",'</a>') "Business App"
       ,CONCAT('<a href="',COALESCE(s."url_string", h."url_string", os."url_string"),' "target="_blank" rel="noopener noreferrer">',COALESCE(s."device_name", h."device_name", os."device_name"),'</a>') "Device"
FROM eol_eos_union eu
LEFT JOIN software_inventory s ON s."software_id" = eu."object_id"
LEFT JOIN hardware_inventory h ON h."hardware_id" = eu."object_id"
LEFT JOIN os_inventory os ON os."os_id" = eu."object_id"
LEFT JOIN business_apps ba ON ba.businessapplication_pk = COALESCE(s.businessapplication_pk, h.businessapplication_pk, os.businessapplication_pk)
ORDER BY eu."audit_type", ba."business_app"