/* Database Connection  - Information Extract */
/* Inline view of Target CTE (inline views) to streamline the process  - 
   Update 2020-10-19
   - updated the view_device_v1 to view_device_v2			 
		*/
Select 
	dc.host_name "Database Server"
	,dc.program_name "Program Name"
	,dc.connect_time "Connect Time"
	,di.dbinstance_name "Instance Name"
	,di.database_type "Database Type"
	,di.connection_count "Connection Count"
	,CASE
	  WHEN di.is_default_instance = 't'
	  THEN
	  'YES'
	  WHEN di.is_default_instance = 'f'
	  THEN
	  'NO'
	  ELSE
	  'N/A'
	END "Default Instance?"
	,dc.num_reads "# Reads"
	,dc.num_writes "# Writes"
	,sc.client_ip "Client IP"
	,cd.name "Client Device Name"
	,dc.login_name "Username"
	,cd.os_name "Client OS Name"
	,cd.os_architecture "Client OS Arch"
From view_databaseconnection_v2 dc
Left Join view_databaseinstance_v2 di ON di.databaseinstance_pk = dc.databaseinstance_fk
Left Join view_servicecommunication_v2 sc ON sc.servicecommunication_pk = dc.serviceportremoteip_fk
Left Join view_device_v2 cd ON sc.client_device_fk = cd.device_pk