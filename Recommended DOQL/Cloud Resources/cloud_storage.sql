/*
 - Name: cloud storage
 - Purpose: provides details on discovered Cloud storage services.
 - Date Created: 10/01/20
 - Changes:
   Update 2020-10-19
  - updated the view_device_v1 to view_device_v2 
*/
Select 
    ci.cloudinfrastructure_name "Cloud Infrastructure Name"
    ,ci.account_id "Account ID"
    ,ci.organization "Organization"
    ,d.name "Name"
    ,r2.resource_name "Resource Name"
    ,r2.identifier "Resource ID"
    ,unnest(r2.category) "Resource Category"
    ,r2.subtype "Resource Subtype"
    ,r2.region "Resource Region"
    ,unnest(r2.zones) "Resource Zones"
    ,r2.vendor_define_type "Type"
From view_resource_v2 r2 
Left Join view_cloudinfrastructure_v2 ci ON ci.cloudinfrastructure_pk = r2.cloudinfrastructure_fk
Left Join view_device_v2 d ON d.device_pk = r2.device_fk