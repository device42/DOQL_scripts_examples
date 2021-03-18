/* Database Servers  - Information Extract */
/* Inline view of Target CTE (inline views) to streamline the process  - 
   Update 2020-10-19
   - updated the view_device_v1 to view_device_v2			 
		*/
/* v16.0  */
Select Distinct
  d.last_edited "Last Discovered",
  d.device_pk "Device Unique Key",
  d.name "Device Name",
  d.in_service "In Service",
  d.service_level "Service Level",
  d.total_cpus "CPU Sockets",
  d.core_per_cpu "Cores Per Processor",
  d.core_per_cpu*d.total_cpus "Total Cores",
    CASE 
       When d.threads_per_core >= 2
        Then 'YES'
        Else 'NO'
       END "Hyperthreaded",
  d.cpu_speed  "CPU Speed", 
  d.os_name "OS Name",
  d.os_architecture "OS Arch",
  d.os_version "OS Version",
  d.os_version_no "OS Version No",
  d.ram "Memory",
  d.ram_size_type "Memory Size Base",
  s.pretty_name "Service Name",
  si.serviceinstance_pk,
  ap.name "Application Name",
  trim(split_part(ap.name , '-',1)) "Database Type",
  /* App Component Data Extract  */
  /*   Instances                 */
  (
    SELECT string_agg(trim(JsonString::text, '"'), ' | ')
    FROM json_array_elements(json::json->'instances') JsonString
  ) AS "Service Instances",
  /*   Paths                    */
  (
    SELECT string_agg(trim(JsonString::text, '"'), ' | ')
    FROM json_array_elements(json::json->'data_paths') JsonString
  ) AS  "Database Paths",
  /*   DB Versions              */
  (CASE WHEN json_array_length(json::json->'products') > 0
       THEN
       (SELECT string_agg(trim(JsonVersion->>'version', '"'), ' | ')
        FROM json_array_elements(json::json->'products') JsonVersion
       )
       WHEN json_array_length(json::json->'services') > 0
       THEN 
       (SELECT string_agg(trim(JsonVersion->>'version', '"'), ' | ')
        FROM json_array_elements(json::json->'services') JsonVersion
       )
       ELSE 
       (SELECT string_agg(trim(JsonVersion->>'version', '"'), ' | ')
        FROM json_array_elements(json::json->'protocols') JsonVersion
       )
   END)  AS  "Database Versions"  
 From
  view_device_v2 d
   Left Join view_appcomp_v1 ap ON ap.device_fk = d.device_pk
   Left Join view_ipaddress_v1 i ON i.device_fk = ap.device_fk
   Left Join view_serviceinstance_appcomp_v2 siapp ON siapp.appcomp_fk = ap.appcomp_pk
   Left Join view_serviceinstance_v2 si ON si.serviceinstance_pk = siapp.serviceinstance_fk
   Left Join view_service_v2 s ON si.service_fk = s.service_pk
  Where 
  /*  Which DBs are we filtering for   */
	trim(split_part(ap.name , '-',1)) in ('Microsoft SQL Server','MySQL','Oracle Database Server','PostgreSQL','Sybase','MongoDB','MariaDB','Apache Derby','SAP Hana','Hadoop','DB2')
 Order by d.name ASC