/*
 - Name: cloud storage
 - Purpose: provides details on discovered Cloud storage services.
 - Date Created: 10/01/20
 - Updated - 4/15/21
    - Change view_device_v1 to view_device_v2
*/
Select DISTINCT
    ci.cloudinfrastructure_name "Cloud Infrastructure Name"
    ,ci.account_id "Account ID"
    ,ci.organization "Organization"
    ,d.name "Name"
    ,r2.resource_name "Resource Name"
    ,r2.identifier "Resource ID"
    ,unnest(r2.category) "Resource Category"
    ,r2.vendor_resource_subtype "Resource Subtype"
    ,r2.region "Resource Region"
    ,unnest(r2.zones) "Resource Zones"
    ,r2.vendor_resource_type "Type"
From view_resource_v2 r2 
Left Join view_cloudinfrastructure_v2 ci On ci.cloudinfrastructure_pk = r2.cloudinfrastructure_fk
Left Join view_deviceresource_v1 dr On dr.resource_fk = r2.resource_pk
Left Join view_device_v2 d On d.device_pk = dr.device_fk