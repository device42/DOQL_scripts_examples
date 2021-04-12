/* AWS Migration Portfolio Assessment Update - Databases
   4/1/21 - Initial Creation: 
*/
/*   Pull together/filter for the DB information records
*/
 With 
    target_device_data  as (
  /* get CPU , device name,tags, device_pk  */
    Select 
        d.device_pk
        ,d.name device_name
        ,d.type d_type
        ,d.tags
        ,d.service_level
        ,d.virtualsubtype d_virtualsubtype
        ,d.os_name
        ,d.os_version
        ,d.total_cpus
        ,d.core_per_cpu
        ,d.threads_per_core
        ,d.total_cpus * coalesce(d.core_per_cpu,1) * coalesce(d.threads_per_core,1) total_cores     
        ,Date(d.first_added) "Date Added"
        ,Case 
            When d.ram <= 0 or d.ram Is Null Then Null            
            When d.ram_size_type = 'MB' Then round((d.ram / 1024)::decimal,2)
            When d.ram_size_type = 'GB' Then d.ram               
            Else Null
        End ram_norm_gb
    From view_device_v2 d
    Left Join view_containerinstance_v1 coi ON coi.device_fk = d.device_pk
    Where d.network_device = 'f' 
        and coi.container_id is Null    /* remove network devices and containers */
        and lower(d.type) Not IN ('cluster','unknown')
 ), 
 /* Get the RU/Reg CRE data; RU info taking precedence */
    target_cre_data as (
    Select 
        reg.device_fk cre_device_fk
        ,Case When reg.recommended_instance = '' and ru.recommended_instance = '' Then ''
              Else 'ReHost'
        End "Migration Strategy"
    From view_credata_v2 reg
        Left Join view_credata_v2 ru on reg.device_fk = ru.device_fk and Lower(ru.vendor) IN ('aws') and Lower(ru.recommendation_type) = 'ru' 
    Where 
     Lower(reg.vendor) IN ('aws') and Lower(reg.recommendation_type) = 'regular' 
    ),
 /* Let's reduce the amount RU records needed  */
    ru_data_filter  as (
    Select 
        ru.*
    From view_rudata_v2 ru
    /* get avg - 3 and peak (98%) - 6 (metric id); time period 30 days)    */
        Where lower(sensor_type) IN ('cpu','disk') and metric_id IN ('3','6') and measure_type_id IN ('1','3','4','15','16') and timeperiod_id IN ('3')
         and (sensor != '')  
    ),
 /* get RU CPU usage 98th used over the last 30 days; 98th percentile  */
    ru_data_cpu_98  as (
        Select 
            ru.device_fk ru_device_fk
            ,max(ru.value) ru_value_cpu
    From ru_data_filter  ru
        Where lower(sensor_type) = 'cpu' and metric_id = '6' and timeperiod_id = '3'
        Group by 1
    ),
 /* get RU Read IOPS usage 98th used over the last 30 days; 98th percentile   */
    ru_data_riops_98  as (
    Select  
        ru1.device_fk ru_device_fk
        ,sum(ru1.max_value) ru_value_riops
    From  
        (Select ru.sensor
            ,ru.device_fk 
            ,max(ru.value) max_value
        From ru_data_filter ru
        Where lower(sensor_type) = 'disk' and measure_type_id = '3' and metric_id = '6' and timeperiod_id = '3'
        Group by 1, 2) ru1
    Group by 1
    ),      
 /* get RU Write IOPS usage 98th used over the last 30 days; 98th percentile   */
    ru_data_wiops_98  as (
    Select  
        ru1.device_fk ru_device_fk
        ,sum(ru1.max_value) ru_value_wiops
    From  
        (Select ru.sensor
            ,ru.device_fk 
            ,max(ru.value) max_value
        From ru_data_filter ru
        Where lower(sensor_type) = 'disk' and measure_type_id = '4' and metric_id = '6' and timeperiod_id = '3'
        Group by 1, 2) ru1
    Group by 1  
    ),
 /* get RU Disk Total 98th used over the last 30 days; 98th percentile   */
    ru_data_dtotal_98  as (
    Select  
        ru1.device_fk ru_device_fk
        ,sum(ru1.max_value) ru_value_total
    From  
        (Select 
            ru.sensor
            ,ru.device_fk 
            ,max(ru.value) max_value
        From ru_data_filter ru
        Where lower(sensor_type) = 'disk' and measure_type_id = '15' and metric_id = '6' and timeperiod_id = '3'
        Group by 1, 2) ru1
    Group by 1
    ),      
 /* get RU Read IOPS usage avg used over the last 30 days; Avg Value   */
    ru_data_riops_avg  as (
    Select  
        ru1.device_fk ru_device_fk
        ,sum(ru1.avg_value) ru_value_riops
    From  
        (Select 
            ru.sensor
            ,ru.device_fk 
            ,max(ru.value) avg_value
        From ru_data_filter ru
        Where lower(sensor_type) = 'disk' and measure_type_id = '3' and metric_id = '3' and timeperiod_id = '3'
        Group by 1, 2) ru1
    Group by 1
    ),      
 /* get RU Write IOPS usage avg used over the last 30 days; Avg Value   */
    ru_data_wiops_avg  as (
    Select  
        ru1.device_fk ru_device_fk
        ,sum(ru1.avg_value) ru_value_wiops
    From  
        (Select 
            ru.sensor
            ,ru.device_fk 
            ,max(ru.value) avg_value
        From ru_data_filter ru
        Where lower(sensor_type) = 'disk' and measure_type_id = '4' and metric_id = '3' and timeperiod_id = '3'
        Group by 1, 2) ru1
    Group by 1
    ),
    app_comp as (
    Select 
        dbp.appcomp_fk
        ,ac.device_fk
        ,Null "Database Name"
        ,dbi.instance as "Instance Name"
        ,Case When position('oracle database ' IN lower(dbp.name)) > 0 Then btrim(split_part(dbp.name,' ',3))
            Else dbp.version 
        End version_raw
        ,split_part(ac.name, '-', 1) as "Source Engine Type"
        ,Case When position('sql server (' IN lower(dbp.name)) > 0 or position ('windows internal database (' IN lower(dbp.name)) > 0 Then btrim(split_part(dbp.name,' - ',2))
            When position('oracle database ' IN lower(dbp.name)) > 0 Then concat(btrim(split_part(dbp.name,' ',4)), ' ',btrim(split_part(dbp.name,' ',5)))
            Else ''
        End "Source Engine Edition"
        ,'No' as "Is in DB View"
        ,ct.name ct_name
        ,ct.contact_info ct_contact_info        
    From view_appcomp_db_products_v1 dbp
    Left Join view_appcomp_db_instances_v1 dbi ON dbi.appcomp_fk = dbp.appcomp_fk
    Left Join view_appcomp_v1 ac ON ac.appcomp_pk = dbp.appcomp_fk 
    Left Join view_customer_v1 ct ON ct.customer_pk = ac.customer_fk
    Where ac.application_category_name = 'Database' 
        and (position('NLS' IN dbp.name) = 0 and position('TNS' IN dbp.name) = 0 and position('PL/SQL' IN dbp.name) = 0)  /*  Remove Oracle unwanted entries   */
        and (position('Launchpad' IN dbp.name) = 0 and position('Server Analysis Services' IN dbp.name) = 0)  /*  Remove SQL Server unwanted entries   */
    ),  
    db as (
    Select 
        dbi.appcomp_fk
        ,ac.device_fk
        ,db.database_name as "Database Name"
        ,dbi.dbinstance_name as "Instance Name"
        ,Case When position('oracle database ' IN lower(dbp.name)) > 0 Then btrim(split_part(dbp.name,' ',3))
            Else dbp.version 
        End version_raw
        ,dbi.database_type as "Source Engine Type"
        ,Case When position('sql server (' IN lower(dbp.name)) > 0 or position ('windows internal database (' IN lower(dbp.name)) > 0 Then btrim(split_part(dbp.name,' - ',2))
            When position('oracle database ' IN lower(dbp.name)) > 0 Then concat(btrim(split_part(dbp.name,' ',4)), ' ',btrim(split_part(dbp.name,' ',5)))
            Else ''
        End "Source Engine Edition"       
        ,'Yes' as "Is in DB View"
        ,ct.name ct_name
        ,ct.contact_info ct_contact_info
    From view_database_v2 db 
    Left Join view_databaseinstance_v2 dbi ON db.databaseinstance_fk = dbi.databaseinstance_pk
    Left Join view_appcomp_db_products_v1 dbp ON dbi.appcomp_fk = dbp.appcomp_fk
    Left Join view_appcomp_v1 ac ON dbp.appcomp_fk = ac.appcomp_pk
    Left Join view_customer_v1 ct ON ct.customer_pk = ac.customer_fk
    Where (position('NLS' IN dbp.name) = 0 and position('TNS' IN dbp.name) = 0 and position('PL/SQL' IN dbp.name) = 0)  /*  Remove Oracle unwanted entries   */
        and (position('Launchpad' IN dbp.name) = 0 and position('Server Analysis Services' IN dbp.name) = 0)  /*  Remove SQL Server unwanted entries   */
    ),
    not_in_db_view as (
    Select app_comp.*
    From app_comp
    Left Join db ON app_comp.appcomp_fk = db.appcomp_fk
    Where db.appcomp_fk is Null
    )
 Select Distinct
    /*  dbinf.*     */
        concat('DB_',dbinf.appcomp_fk) "Database ID"
  /*    ,dbinf."Database Name" "DB Name"  */
        ,Null "DB Name"
        ,dbinf."Instance Name" "DB Instance Name"
  /* Normalize MS and Oracle     */
        ,Case When btrim(lower(dbinf."Source Engine Type")) IN ('microsoft sql', 'microsoft sql server') Then 'SQL Server'
            When btrim(lower(dbinf."Source Engine Type")) IN ('oracle database', 'oracle database server') Then 'Oracle Database'
            Else dbinf."Source Engine Type"
        End "Source Engine Type"
        ,Case When "Source Engine Type" ilike '%Microsoft%' Then case When btrim(substring(dbinf.version_raw,1,5)) = '10.25' Then 'Azure SQLDB'
                                                                    When btrim(substring(dbinf.version_raw,1,4)) = '10.5' Then '2008 R2' 
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '8' Then '2000' 
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '9' Then '2005'
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '10' Then '2008'
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '11' Then '2012'
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '12' Then '2014'
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '13' Then '2016'
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '14' Then '2017'
                                                                    When btrim(split_part(dbinf.version_raw,'.',1)) = '15' Then '2019'
                                                                    Else 'Other' End
            Else dbinf.version_raw End as "Source Engine Version"     
        ,dbinf."Source Engine Edition" "Source Engine Edition"
        ,Round((rddt98.ru_value_total/1024/1024/1024)::integer,0) "Total Size (GB)"
        ,tdd.device_name "Server ID"
        ,Null "Target Engine"
        ,Null "Deployment Type"
        ,dbinf.ct_name "Database Owner Name"
        ,dbinf.ct_contact_info "Database Owner Email"
        ,Null "Database Owner Phone"
        ,Null "License Model"
        ,Null "Oracle ADR (Y/N)"
        ,Null "Replication (Y/N)"
        ,Null "Cluster/Oracle RAC (Y/N)"
        ,rdr98.ru_value_riops + rdw98.ru_value_wiops "Peak IOPS (KB)"
        ,rdravg.ru_value_riops + rdwavg.ru_value_wiops "Average IOPS (KB)"
        ,Null "WQF Rating (1,2,3,4,5)"
        ,tcd."Migration Strategy"
        ,tdd.total_cores "CPU Cores"
        ,Null "Max Transactions per Second"
        ,Null "Redo Log Size (KB)"
        ,Null "Stored Procedures Lines of Code"
        ,Null "Triggers Lines of Code"
        ,rdc98.ru_value_cpu "Utilization"
        ,Null "Throughput (MBps)"             
    From 
        (   Select * From not_in_db_view
            Union All
            Select * From db) dbinf 
        Left join target_device_data tdd ON dbinf.device_fk = tdd.device_pk
        Left Join target_cre_data tcd ON tcd.cre_device_fk = tdd.device_pk          
        Left Join ru_data_cpu_98 rdc98 ON rdc98.ru_device_fk = tdd.device_pk
        Left Join ru_data_dtotal_98 rddt98 ON rddt98.ru_device_fk = tdd.device_pk
        Left Join ru_data_riops_98 rdr98 ON rdr98.ru_device_fk = tdd.device_pk
        Left Join ru_data_wiops_98 rdw98 ON rdw98.ru_device_fk = tdd.device_pk      
        Left Join ru_data_riops_avg rdravg ON rdravg.ru_device_fk = tdd.device_pk
        Left Join ru_data_wiops_avg rdwavg ON rdwavg.ru_device_fk = tdd.device_pk
    Order by "Database ID" 