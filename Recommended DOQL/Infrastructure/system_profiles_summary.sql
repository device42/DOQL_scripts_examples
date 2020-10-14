    /*
 - Name: System Profiles Summary
 - Purpose: Query for summary of all discovered hardware profiles.
 - Date Created: 10/01/20
 - Changes: 10/12/20 Updated to use new subtypes and view_device_v2 introduced in 16.19
*/
select count (*) "Quantity",
v.name "Manufacturer",
h.name "Model",
d.physicalsubtype "Physical Subtype",
h.size "RU Size",
h.depth "Depth",
h.end_of_life "End of Life",
h.end_of_support "End of Support",
d.total_cpus "Total CPUs",
d.core_per_cpu "Cores Per CPU",
d.ram "Memory"
from view_device_v2 d
join view_hardware_v1 h on d.hardware_fk = h.hardware_pk
left join view_vendor_v1 v on v.vendor_pk = h.vendor_fk
group by d.physicalsubtype,d.total_cpus,d.core_per_cpu,d.ram,h.name,v.name,h.size,h.depth,h.end_of_life,h.end_of_support
order by v.name,h.name ASC