WITH
    function_accounts AS(
        SELECT r.resource_name 
               ,rr.from_resource_fk "account_id"
               ,rr.to_resource_fk "function_id"
        FROM view_resourcerelationship_v2 rr
        JOIN view_resource_v2 r ON r.resource_pk = rr.from_resource_fk 
        WHERE relation = 'account_functions'
    )

SELECT
        r.resource_name "Resource"
        ,a.resource_name "Account"
        ,r.category "Resource Category"
        ,r.vendor_resource_type "Resource Type"
        ,r.region AS "Region"
        ,r.details ->> 'runtime' AS "Runtime"
        ,r.details ->> 'version' AS "Function Version"
        ,r.details ->> 'description' AS "Description"
        ,r.details ->> 'role' AS "AWS Role"
        ,r.details AS "Details JSON"
        ,r.vendor_custom_fields AS "Vendor Custom Fields"
FROM view_resource_v2 r
JOIN function_accounts a ON a.function_id = r.resource_pk
WHERE LOWER(CAST(category AS TEXT)) LIKE '%function%' AND LOWER(r.details ->> 'runtime') LIKE '%nodejs12%'