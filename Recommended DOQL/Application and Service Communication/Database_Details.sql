/* Databases
 * Creation: 01/11/2023
 * Desc: Returns information on individual databases
 *  - this is a repurposed version of the Exago report - not a 1-1 match up
 * ********************
 * Update: 01/31/2023
 *  - Update join criteria to db instances
 */
WITH db_appcomps AS (
      SELECT
        ac.device_fk
        ,ac.appcomp_pk
        ,ac.name AS ac_name
        ,split_part(ac.name, '-', 1) AS ac_type
      FROM view_appcomp_v1 ac
      WHERE 
        ac.application_category_name = 'Database'
)
SELECT
  d."name"                                                                  AS "Device Name"
  ,ac.ac_type                                                               AS "Database Type"
  ,dbi.dbinstance_name                                                      AS "Database Instance"
  ,INITCAP(dbi.is_default_instance::text)                                   AS "Default"
  ,dbi.host_name                                                            AS "Database Instance Hostname"
  ,db.database_name                                                         AS "Database"
  ,db.compatibility_level                                                   AS "Compatability Level"
  ,db.recovery_model                                                        AS "Recovery Model"
  ,db.creation_date                                                         AS "Creation Date"
  ,dbs."size"::bigint                                                       AS "File Size"
  ,dbs."type"                                                               AS "File Type"
  ,dbs."path"                                                               AS "Physical File Path"
FROM view_database_v2 db            
JOIN view_databaseinstance_v2 dbi   ON dbi.databaseinstance_pk = db.databaseinstance_fk
JOIN view_appcomp_resources_v2 acr  ON acr.resource_fk = dbi.databaseinstance_pk
JOIN db_appcomps ac                 ON ac.appcomp_pk = acr.appcomp_fk
JOIN view_device_v2 d               ON ac.device_fk = d.device_pk
JOIN view_databasesize_v2 dbs       ON dbs.database_fk = db.database_pk
ORDER BY 
  d.name
  ,ac.ac_type
  ,dbi.dbinstance_name
  ,db.database_name
