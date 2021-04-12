select sa.model as "Array Model"
             ,name as "Array Name"
             ,sa.software_version as "Software Version"
             ,sa.capacity_tb as "Capacity (TB)"
             ,sa.free_capacity_tb as "Free Capacity (TB)"
             ,sa.used_capacity_tb as "Used Capacity (TB)"
			 ,sa.raw_capacity_tb as "Raw Capacity (TB)"	
			 ,sa.raw_used_capacity_tb as "Raw Used Capacity (TB)"
			 ,sa.raw_capacity_tb - raw_used_capacity_tb as "Raw Free Capacity (TB)" 
			 ,sa.raw_used_capacity_tb/nullif(raw_capacity_tb, 0) as "Raw Used Percentage"
			 ,sadc.disk_counts as "Disk Counts"
from view_storagearray_v2 sa
left join view_storagearray_disk_counts_v2 sadc 
	on sa.storagearray_pk = sadc.storagearray_fk