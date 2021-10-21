With
  /* get the records needed for storage size calculations - windows and nix  machines */
	get_mp_records_all as (
		Select mp.*, dr.device_fk
		From view_mountpoint_v2 mp
		Join view_deviceresource_v1 dr ON dr.resource_fk = mp.mountpoint_pk and lower(dr.relation) = 'mountpoint'
	),
  /* get the records needed for storage size calculations - ESXi machines */
 	agg_mp_records_vmw  as (
		Select mpa.*, 'VMW' d_type
		From (Select Distinct mpa.device_fk From get_mp_records_all mpa Where lower(mpa.fstype_name) IN ('vmfs')) key
		Join (Select mpd.* From get_mp_records_all mpd) mpa ON mpa.device_fk = key.device_fk
	),  
 /* Sum up local and remote for VMW devices  */		
 	sum_vmw_storage  as (
		Select lcl.device_fk, coalesce(lcl.local_stor,0) "Local Storage Size GB" , 0 "Remote Storage Size GB", lcl.d_type
		From (Select amrw.device_fk, round(sum(amrw.capacity/1024),2)  local_stor, amrw.d_type 
				 From agg_mp_records_vmw amrw Where (lower(amrw.fstype_name) IN ('vmfs')) Group by 1,3) lcl
	/* Using NFS fstype to determine remote storage for VMWare */ 				 
		Left Join (Select amrw.device_fk, round(sum(amrw.capacity/1024),2) remote_stor 
					 From agg_mp_records_vmw amrw Where (lower(amrw.fstype_name) IN ('nfs')) Group by 1) rmt ON rmt.device_fk = lcl.device_fk 				 
	),
  /* get the records needed for storage size calculations - windows machines */
	agg_mp_records_win  as (
		Select mpa.*, 'WIN' d_type
		From get_mp_records_all mpa
		Join view_deviceresource_v1 dr ON dr.resource_fk = mpa.mountpoint_pk and lower(dr.relation) = 'mountpoint'		
		Where mpa.mountpoint = mpa.label
	),
 /* Sum up local and remote for window devices  */		
	sum_win_storage  as (
		Select lcl.device_fk, coalesce(lcl.local_stor,0) "Local Storage Size GB" , coalesce(rmt.remote_stor,0) "Remote Storage Size GB", lcl.d_type
		From (Select amrw.device_fk, round(sum(amrw.capacity/1024),2)  local_stor, amrw.d_type  
				From agg_mp_records_win amrw Where (position(':' IN amrw.mountpoint) > 0 and amrw.filesystem = '') Group by 1,3) lcl
		Left Join (Select amrw.device_fk, round(sum(amrw.capacity/1024),2) remote_stor 
				From agg_mp_records_win amrw Where (position('\\' IN amrw.mountpoint) > 0 and amrw.fstype_name != '') Group by 1) rmt ON rmt.device_fk = lcl.device_fk   
	),
 /* get the records needed for storage size calculations - Non-Windows machines machines */	
	agg_mp_records_nix  as (
		Select mpa.*, 'NIX' d_type
		From get_mp_records_all mpa
		Join view_deviceresource_v1 dr ON dr.resource_fk = mpa.mountpoint_pk and lower(dr.relation) = 'mountpoint'		
		Where mpa.mountpoint != mpa.label
	),
 /* Sum up local and remote for non-window devices  */	
	sum_nix_storage  as (
		Select lcl.device_fk, coalesce(lcl.local_stor ,0) "Local Storage Size GB", coalesce(rmt.remote_stor ,0) "Remote Storage Size GB", lcl.d_type
		From (Select amrw.device_fk, round(sum(amrw.capacity/1024),2)  local_stor, amrw.d_type 
				 From agg_mp_records_nix amrw Where (lower(amrw.fstype_name) NOT IN ('nfs','nfs4','cifs','smb','vmfs') or amrw.fstype_name = '') Group by 1,3) lcl
		Left Join (Select amrw.device_fk, round(sum(amrw.capacity/1024),2) remote_stor 
					 From agg_mp_records_nix amrw Where (lower(amrw.fstype_name) IN ('nfs','nfs4','cifs','smb')) Group by 1) rmt ON rmt.device_fk = lcl.device_fk   
	),
 /* union all the MP records from windows and non-windows machines.  */	
	union_mp_records  as (
		Select win.* 
		From (Select win.* 
			From sum_win_storage win 
			Union All
			Select nix.* 
			From sum_nix_storage nix			
			Union All
			Select vmw.* 
			From sum_vmw_storage vmw) win
		Order by win.device_fk
	)
	Select * from union_mp_records