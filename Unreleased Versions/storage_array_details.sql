 /*   Storage Array report for AWS
       SAN/NAS asset data along with RU data
       2021-05-24 - Created
 */
 With
  /*  Get SAN  */
    target_storagearray_san as (
    Select Distinct 
        sa.storagearray_pk 
        ,sal.resource_fk        
        ,sa.name sa_name
        ,sa.vendor_define_type sa_array_type
        ,'SAN' array_type 
        ,sal.name
        ,sal.identifier
        ,sal.element_type
        ,sa.model
        ,sa.manufacturer
        ,sal.used_capacity
        ,sal.capacity
        ,'GB' capacity_type
        ,sal.raid_type
        ,sal.storagearraypool_name          
        ,Case When sal.is_thin = 't' Then 'Yes'
                Else 'No'
        End "Thin Provisioned?"       
        ,sa.vendor
        ,sal.technology media_type
        ,sal.protocol
    From view_storagearray_v2 sa
    Join view_storagearraylun_v2 sal ON sal.storagearray_fk = sa.storagearray_pk 
    ), 
  /*  Get NAS  */   
    target_storagearray_nas as (
    Select Distinct
        sa.storagearray_pk
        ,saf.resource_fk
        ,sa.name sa_name
        ,sa.vendor_define_type sa_array_type    
        ,'NAS' array_type 
        ,saf.name   
        ,saf.identifier
        ,saf.element_type
        ,sa.model
        ,sa.manufacturer
        ,saf.used_capacity
        ,saf.capacity
        ,'GB' capacity_type
        ,saf.raid_type
        ,saf.storagearraypool_name          
        ,Case When saf.thin_enabled Then 'Yes'
                Else 'No'
        End "Thin Provisioned?"       
        ,sa.vendor
        ,saf.technology media_type  
        ,saf.protocol
    From view_storagearray_v2 sa    
    Join view_storagearrayfs_v2 saf ON saf.storagearray_fk = sa.storagearray_pk 
    ),
  /*  Get remaining VOls for the arrays (mostly from Netapps) */    
    target_storagearray_nas_vol as (
    Select Distinct
        sa.storagearray_pk
        ,sav.resource_fk
        ,sa.name sa_name
        ,sa.vendor_define_type sa_array_type    
        ,'NAS' array_type 
        ,sav.name   
        ,sav.identifier
        ,sav.element_type
        ,sa.model
        ,sa.manufacturer
        ,sav.used_capacity
        ,sav.capacity
        ,'GB' capacity_type
/*      ,sav.raid_type   */
        ,Null raid_type
        ,sav.vol_aggregate storagearraypool_name        
/*      ,Case When sav.thin_enabled Then 'Yes'
                Else 'No'
        End "Thin Provisioned?"   */  
        ,'No' "Thin Provisioned?" /* make default value of "No" for now until value exposed. */
        ,sa.vendor
        ,sav.technology media_type  
        ,'nas' protocol
    From view_storagearray_v2 sa
    Join (Select vol.* From view_storagearrayvol_v2 vol join view_storagearrayvol_unused_v2 unuv ON unuv.storagearrayvol_fk = vol.storagearrayvol_pk) sav ON sav.storagearray_fk = sa.storagearray_pk   
    ),  
  /* Union the storagearray data  */
    target_storagearray_all  as (   
    Select * From target_storagearray_san
    Union All
    Select * From target_storagearray_nas
    Union All
    Select * From target_storagearray_nas_vol
    ),
 /* Filter RU data only those that we need  */
    ru_data_filter  as (    
    Select 
        ru.*
        ,start_time::date st_date
        ,end_time::date end_date        
    From view_rudata_v2 ru
        Where ru.sensor_type IN ('STORAGE_FS','STORAGE_LUN', 'STORAGE_VOL') and ru.metric_id IN ('1','3') and ru.measure_type IN ('STORAGE_IOS_PER_SEC','STORAGE_KB_DATA_PER_SEC','STORAGE_LATENCY') and ru.timeperiod_id IN ('1') and ru.window = '1'
    ),
  /* Inline view of RU data Summary for LUN that have RU data  */
    ru_data_summary_lun as (
    Select Distinct
        rdflia.resource_fk
        ,rdflia.sensor      
        ,rdflia.st_date     
        ,rdflia.end_date 
        ,rdflia.value iops_avg
        ,rdflip.value iops_max   
        ,round((rdflta.value/1024)::numeric,2) tp_avg
        ,round((rdfltp.value/1024)::numeric,2) tp_max  
        ,rdflla.value lat_avg
        ,rdfllp.value lat_max       
    From 
        (Select Distinct resource_fk, name From target_storagearray_san) spk
        Left Join ru_data_filter rdflia ON rdflia.resource_fk = spk.resource_fk and rdflia.sensor = spk.name and rdflia.sensor_type = 'STORAGE_LUN' and rdflia.measure_type = 'STORAGE_LATENCY' and rdflia.metric_id = '3'
        Left Join ru_data_filter rdflip ON rdflip.resource_fk = spk.resource_fk and rdflip.sensor = spk.name and rdflip.sensor_type = 'STORAGE_LUN' and rdflip.measure_type = 'STORAGE_LATENCY' and rdflip.metric_id = '1'  
        Left Join ru_data_filter rdflta ON rdflta.resource_fk = spk.resource_fk and rdflta.sensor = spk.name and rdflta.sensor_type = 'STORAGE_LUN' and rdflta.measure_type = 'STORAGE_KB_DATA_PER_SEC' and rdflta.metric_id = '3'
        Left Join ru_data_filter rdfltp ON rdfltp.resource_fk = spk.resource_fk and rdfltp.sensor = spk.name and rdfltp.sensor_type = 'STORAGE_LUN' and rdfltp.measure_type = 'STORAGE_KB_DATA_PER_SEC' and rdfltp.metric_id = '1'      
        Left Join ru_data_filter rdflla ON rdflla.resource_fk = spk.resource_fk and rdflla.sensor = spk.name and rdflla.sensor_type = 'STORAGE_LUN' and rdflla.measure_type = 'STORAGE_IOS_PER_SEC' and rdflla.metric_id = '3'
        Left Join ru_data_filter rdfllp ON rdfllp.resource_fk = spk.resource_fk and rdfllp.sensor = spk.name and rdfllp.sensor_type = 'STORAGE_LUN' and rdfllp.measure_type = 'STORAGE_IOS_PER_SEC' and rdfllp.metric_id = '1'  
    ),  
  /* Inline view of RU data Summary for FS that have RU data  */
    ru_data_summary_fs as (
    Select Distinct
        rdffia.resource_fk
        ,rdffia.sensor      
        ,rdffia.st_date     
        ,rdffia.end_date 
        ,rdffia.value iops_avg
        ,rdffip.value iops_max   
        ,round((rdffta.value/1024)::numeric,2) tp_avg
        ,round((rdfftp.value/1024)::numeric,2) tp_max  
        ,rdffla.value lat_avg
        ,rdfflp.value lat_max       
    From 
        (Select Distinct resource_fk, name From target_storagearray_nas) spk
        Left Join ru_data_filter rdffia ON rdffia.resource_fk = spk.resource_fk and rdffia.sensor = spk.name and rdffia.sensor_type = 'STORAGE_FS' and rdffia.measure_type = 'STORAGE_LATENCY' and rdffia.metric_id = '3'
        Left Join ru_data_filter rdffip ON rdffip.resource_fk = spk.resource_fk and rdffip.sensor = spk.name and rdffip.sensor_type = 'STORAGE_FS' and rdffip.measure_type = 'STORAGE_LATENCY' and rdffip.metric_id = '1'
        Left Join ru_data_filter rdffta ON rdffta.resource_fk = spk.resource_fk and rdffta.sensor = spk.name and rdffta.sensor_type = 'STORAGE_FS' and rdffta.measure_type = 'STORAGE_KB_DATA_PER_SEC' and rdffta.metric_id = '3'
        Left Join ru_data_filter rdfftp ON rdfftp.resource_fk = spk.resource_fk and rdfftp.sensor = spk.name and rdfftp.sensor_type = 'STORAGE_FS' and rdfftp.measure_type = 'STORAGE_KB_DATA_PER_SEC' and rdfftp.metric_id = '1'       
        Left Join ru_data_filter rdffla ON rdffla.resource_fk = spk.resource_fk and rdffla.sensor = spk.name and rdffla.sensor_type = 'STORAGE_FS' and rdffla.measure_type = 'STORAGE_IOS_PER_SEC' and rdffla.metric_id = '3'
        Left Join ru_data_filter rdfflp ON rdfflp.resource_fk = spk.resource_fk and rdfflp.sensor = spk.name and rdfflp.sensor_type = 'STORAGE_FS' and rdfflp.measure_type = 'STORAGE_IOS_PER_SEC' and rdfflp.metric_id = '1'
    ),
  /* Inline view of RU data Summary for VOL that have RU data  */
    ru_data_summary_vol as (
    Select Distinct
        rdffia.resource_fk
        ,rdffia.sensor      
        ,rdffia.st_date     
        ,rdffia.end_date 
        ,rdffia.value iops_avg
        ,rdffip.value iops_max   
        ,round((rdffta.value/1024)::numeric,2) tp_avg
        ,round((rdfftp.value/1024)::numeric,2) tp_max  
        ,rdffla.value lat_avg
        ,rdfflp.value lat_max       
    From 
        (Select Distinct resource_fk, name From target_storagearray_nas_vol) spk
        Left Join ru_data_filter rdffia ON rdffia.resource_fk = spk.resource_fk and rdffia.sensor = spk.name and rdffia.sensor_type = 'STORAGE_VOL' and rdffia.measure_type = 'STORAGE_LATENCY' and rdffia.metric_id = '3'
        Left Join ru_data_filter rdffip ON rdffip.resource_fk = spk.resource_fk and rdffip.sensor = spk.name and rdffip.sensor_type = 'STORAGE_VOL' and rdffip.measure_type = 'STORAGE_LATENCY' and rdffip.metric_id = '1'
        Left Join ru_data_filter rdffta ON rdffta.resource_fk = spk.resource_fk and rdffta.sensor = spk.name and rdffta.sensor_type = 'STORAGE_VOL' and rdffta.measure_type = 'STORAGE_KB_DATA_PER_SEC' and rdffta.metric_id = '3'
        Left Join ru_data_filter rdfftp ON rdfftp.resource_fk = spk.resource_fk and rdfftp.sensor = spk.name and rdfftp.sensor_type = 'STORAGE_VOL' and rdfftp.measure_type = 'STORAGE_KB_DATA_PER_SEC' and rdfftp.metric_id = '1'      
        Left Join ru_data_filter rdffla ON rdffla.resource_fk = spk.resource_fk and rdffla.sensor = spk.name and rdffla.sensor_type = 'STORAGE_VOL' and rdffla.measure_type = 'STORAGE_IOS_PER_SEC' and rdffla.metric_id = '3'
        Left Join ru_data_filter rdfflp ON rdfflp.resource_fk = spk.resource_fk and rdfflp.sensor = spk.name and rdfflp.sensor_type = 'STORAGE_VOL' and rdfflp.measure_type = 'STORAGE_IOS_PER_SEC' and rdfflp.metric_id = '1'
    ),  
  /* Union the RU data data  */
    ru_data_summary  as (   
    Select * From ru_data_summary_lun
    Union All
    Select * From ru_data_summary_fs
    Union All
    Select * From ru_data_summary_vol   
    )   
 /* Pull Records together  
 
 */ 
    Select
        tsa.name "Identifier/Volume"
        ,tsa.sa_name "Array Name"
        ,tsa.sa_array_type "Array Type"       
        ,tsa.array_type  "Storage Type (SAN/NAS)"
        ,tsa.capacity_type "Capacity Type (Usable/RAW)"
        ,round(tsa.capacity::numeric,2) "Total Capacity (GB)"
        ,tsa.identifier "LUN (only needed if SAN)"
        ,tsa.raid_type "RAID (RAID-6, RAID5, RAID 10, etc.)"
        ,round(tsa.used_capacity::numeric,2) "Used Capacity (GB)"
 /*     ,Null "Access Frequency (High, Medium, Low)"   Removed based on note from Aaron 6/10 */
        ,rds.iops_avg mean_iops
        ,rds.iops_max peak_iops
        ,rds.tp_avg mean_thruput
        ,rds.tp_max peak_thruput
        ,rds.lat_avg mean_lat
        ,rds.lat_max peak_lat
        ,tsa.protocol "Access Protocol (CIFS/NFS/FC/iSCSI)"
        ,Null "Utilization Date"
        ,tsa.media_type "Media Type"
        ,Null "Used For"
        ,Null "Label"
        ,Null "Notes"
        ,Null "Description"
        ,tsa.storagearraypool_name "Pool"
        ,tsa.vendor "Storage Vendor"
        ,tsa."Thin Provisioned?"
        ,tsa.storagearray_pk
        ,tsa.resource_fk
    From target_storagearray_all tsa
    Left Join ru_data_summary rds ON rds.resource_fk = tsa.resource_fk and rds.sensor = tsa.name
    Order by 2, 1, 3