select
s.software_pk "Software ID",
s.name "Software Name",
v.name "Software Vendor",
swlm.name "License Model",
swlm.license_type "License Type",
s.licensed_count "Licensed Count",
s.discovered_count "Discovered Count",
s.software_type "Software Type",
s.category_name	"Software Category",
round(case when s.discovered_count = 0 then null else 100.0 * s.discovered_count / s.licensed_count end, 4) "License Consumption"
from view_software_v1 s
left join view_vendor_v1 v on v.vendor_pk = s.vendor_fk
left join view_softwarelicensemodel_v1 swlm on s.softwarelicensemodel_fk = swlm.softwarelicensemodel_pk