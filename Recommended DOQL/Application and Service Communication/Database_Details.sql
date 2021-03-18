/* Database Details  - Information Extract */
/* Inline view of Target CTE (inline views) to streamline the process  - 
   Update 2020-10-19
   - updated the view_device_v1 to view_device_v2			 
		*/
Select
	dbs.databasesize_pk,
	d.name "Device Name",
	CASE 
		   When di.is_default_instance = 't'
			Then 'YES'
			Else 'NO'
		   END "Default Instance",
	di.database_type "Database Type",
	db.compatibility_level "Compatibility Level",
	di.dbinstance_name "Database Instance Name",
	db.database_name "Database Name",
	dbs.name "Logical File Name",
	dbs.create_date "File Create Date",
	dbs.size "File Size",
	dbs.type "File Type",
	dbs.path "Physical File Path"
From view_databasesize_v2 dbs
Left Join view_database_v2 db ON dbs.database_fk = db.database_pk
Left Join view_databaseinstance_v2 di ON db.databaseinstance_fk = di.databaseinstance_pk
Left Join view_appcomp_v1 ac ON di.appcomp_fk = ac.appcomp_pk
Left Join view_device_v2 d ON d.device_pk = ac.device_fk