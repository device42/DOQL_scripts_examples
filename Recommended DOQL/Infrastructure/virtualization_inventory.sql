/* Virtual Inventory    
Updated - 3/3/20 - consolidated the query and re-orged
Updated - 12/23/2019
          - added Core Threads and total compute capacity based upon CPUS * Core/Cpu * # of hyperthreads 
          - compute Compute Power dependent on what values are avail (for Host and Guest)		  
   Update 2020-10-19
   - updated the view_device_v1 to view_device_v2			  
*/
Select
    vmm.name "VM Manager",
  /*  Assemble Host information   */
    h.device_pk "Host Device ID",
    h.name "Host Device Name",
    h.type "Host Hardware Type",
    h.os_name "Host OS Name",
    h.os_architecture "Host OS Arch",
    h.os_version "Host OS Version",
    h.os_version_no "Host OS Version No",
    CASE When h.threads_per_core > 1
          Then 'YES'
          Else 'NO'
    END "Host Hyperthreaded?",
    h.total_cpus "Host CPU Count",
    h.core_per_cpu "Host CPU Cores",
    h.cpu_speed "Host CPU Speed GHz",
    h.ram "Host RAM GB",
  /* Additional Host info      */
    h.threads_per_core "Host Core Threads",
    CASE When h.core_per_cpu is Null
        Then h.total_cpus
		When h.threads_per_core > 1
        Then h.total_cpus * h.core_per_cpu * h.threads_per_core
		Else h.total_cpus * h.core_per_cpu
    END "Host Compute Power",	
  /* Assemble Guest information   */
    g.device_pk "Guest Device ID",
    g.name "Guest Name",
    split_part(g.name,'.',1) "Guest Name (SN)",
    (SELECT array_to_string(array(
      Select ip.ip_address
      From view_ipaddress_v1 ip
       Where ip.device_fk = g.device_pk),
     '; ')) as "Guest IP Address",
    g.os_name "Guest OS Name",
    g.in_service "Guest In Service?",
    g.os_architecture "Guest OS Arch",
    g.os_version "Guest OS Version",
    g.os_version_no "Guest OS Version No",
    CASE 
       When g.threads_per_core > 1
        Then 'YES'
        Else 'NO'
    END "Guest Hyperthreaded?",
    g.total_cpus "Guest CPU Count",
    g.core_per_cpu "Guest CPU Cores",
    g.cpu_speed "Guest CPU Speed GHz",
    g.ram "Guest RAM GB",
    g.hard_disk_count "Guest Disk Count",
    g.datastores "Datastores",
    CASE When c.parent_device_fk is null
      	Then 'N' 
		Else 'Y' 
    END "Guest Clustered",
    c.parent_device_name "Cluster Name",
 /* Additonal info available - for Hosts and Guests */
    g.threads_per_core "Guest Core Threads",
    CASE When g.core_per_cpu is Null
		Then g.total_cpus
		When g.threads_per_core > 1
        Then g.total_cpus * g.core_per_cpu * g.threads_per_core
		Else g.total_cpus * g.core_per_cpu
    END "Guest Compute Power",
    h.last_edited "Host Last Update", 
    g.last_edited "Guest Last Update", 
    (Select hmp.last_updated From view_mountpoint_v1 hmp Where hmp.device_fk = h.device_pk Limit 1) "Host MP Last Update",
    (Select gmp.last_updated From view_mountpoint_v1 gmp Where gmp.device_fk = g.device_pk Limit 1) "Guest MP Last Update",
    (Select count(*) From view_softwaredetails_v1 sd Where sd.device_fk = h.device_pk) "Host Software Discovered",   
    (Select count(*) From view_softwaredetails_v1 sd Where sd.device_fk = g.device_pk) "Guest Software Discovered"
/*   Get the Hosts that have virtual_host flag on - sub-query */
    From (Select * From view_device_v2 hsq 
            Where hsq.virtual_host and hsq.os_name NOT IN ('f5','netscaler'))h
/*   Get the virtual devices that are not part of the network OSes - sub-query*/            
    Left Join (Select * From view_device_v2 gsq 
            Where gsq.type_id = '3') g  ON h.device_pk = g.virtual_host_device_fk
    Left Join view_device_v2 vmm on vmm.device_pk = h.vm_manager_device_fk
    Left Join view_devices_in_cluster_v1 c ON c.child_device_fk = h.device_pk  
    Order by h.name ASC