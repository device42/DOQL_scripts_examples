select sap.name as "Pool Name"
		,sap.storagearray_name as "Storrage Array Name"
		,sap.capacity/1024 as "Poole Capacity (TB)"
		,sap.used_capacity/1024 as "Pool Used Capacity (TB)"
		,(sap.capacity - sap.used_capacity)/1024 as "Pool Free Capacity (TB)"
		,lun.lun_count as "LUN Count"
		,sa.capacity_tb as "Capacity (TB)"
		,sa.free_capacity_tb as "Free Capacity (TB)"
		,sa.used_capacity_tb as "Used Capacity (TB)"
from view_storagearraypool_v2 sap
left join (select storagearray_fk
					,count(*) as lun_count
			from view_storagearray_to_lun_v2
			group by 1) lun
	on sap.storagearray_fk = lun.storagearray_fk
join view_storagearray_v2 sa
	on sap.storagearray_fk = sa.storagearray_pk