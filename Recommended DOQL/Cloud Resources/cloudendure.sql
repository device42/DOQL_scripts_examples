/* CloudEndure  Update
   9/9/20 - add tenancy, recommend_instance and recommendation_type
          - Only show data for AWS
          - prioritize recommendation_type ru over regular
*/
/* Get the RU CRE data  */
With 
    target_cre_data_ru  as (
    SELECT 
        cre.device_fk
        ,cre.tenancy
        ,cre.recommendation_type
        ,cre.recommended_instance
    From view_credata_v2 cre
     Where lower(cre.vendor) IN ('aws') and lower(cre.recommendation_type) = 'ru'   
    ),
/* Get the Regular CRE data  */
    target_cre_data_reg  as (
    SELECT 
        cre.device_fk
        ,cre.tenancy
        ,cre.recommendation_type
        ,cre.recommended_instance
    From view_credata_v2 cre
     Where lower(cre.vendor) IN ('aws') and lower(cre.recommendation_type) = 'regular'  
    )
/* Pull all the CRE dat and device data together */ 
    Select
        d.device_pk
        ,d.name "machineName"
        ,(SELECT array_to_string(array(
                      Select ip.ip_address
                      from view_ipaddress_v1 ip
                      Where ip.device_fk = d.device_pk),
                      ',')) "privateIPs"
        ,ru.tenancy ru_tenancy
        ,ru.recommendation_type ru_recommendation_type
        ,ru.recommended_instance ru_recommended_instance
        ,reg.tenancy reg_tenancy
        ,reg.recommendation_type reg_recommendation_type
        ,reg.recommended_instance reg_recommended_instance
        ,Case When ru.recommended_instance is Null
              Then reg.tenancy
              Else ru.tenancy
         End tenancy_sl
        ,Case When ru.recommended_instance is Null
              Then reg.recommendation_type
              Else ru.recommendation_type
         End recommendation_type_sl
        ,Case When ru.recommended_instance is Null
              Then reg.recommended_instance
              Else ru.recommended_instance
         End recommended_instance_sl        
     From 
                view_device_v1 d
        Left Join target_cre_data_ru ru on ru.device_fk = d.device_pk
        Left Join target_cre_data_reg reg on reg.device_fk = d.device_pk
        Where d.network_device = 'f' and (ru.recommended_instance != '' or reg.recommended_instance != '')