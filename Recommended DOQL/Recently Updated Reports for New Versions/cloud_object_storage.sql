/*
 - Name: Cloud Object Storage
 - Purpose: Report on Cloud services like S3 and Blob
 - Date Created: 10/01/20
 - Changes:
*/

With 
    target_category AS (

Select 
    r2.device_fk
    ,r2.cloudinfrastructure_fk
    ,r2.resource_name 
    ,r2.identifier 
    ,unnest(r2.category) cat 
    ,r2.subtype 
    ,r2.region 
    ,unnest(r2.zones) zne
    ,r2.vendor_define_type 
From view_resource_v2 r2  
    )

Select 
    ci.cloudinfrastructure_name "Cloud Infrastructure Name"
    ,ci.account_id "Account ID"
    ,ci.organization "Organization"
    ,d.name "Name"
    ,tc.resource_name "Resource Name"
    ,tc.identifier "Resource ID"
    ,tc.cat "Resource Category"
    ,tc.subtype "Resource Subtype"
    ,tc.region "Resource Region"
    ,tc.zne "Resource Zones"
    ,tc.vendor_define_type "Type"
From target_category tc 
Left Join view_cloudinfrastructure_v2 ci On ci.cloudinfrastructure_pk = tc.cloudinfrastructure_fk
Left Join view_device_v1 d on d.device_pk = tc.device_fk
where strpos(lower(tc.cat),'object') > 0 
Order by d.name ASC