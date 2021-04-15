 /*
 Infrastructure information Report
   Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
  - removed d.cloud_vendor_fk because replacement would have been a duplicate ci.vendor_fk

 */
 Select
        d.last_edited "Last_Discovered"
        ,d.name "Device_Name"
        ,d.in_service "In Service"
        ,d.service_level "Service_Level"
        ,d.type "Device_Type"
        ,d.physicalsubtype "Device Subtype"
        ,d.virtualsubtype "Virtual_Subtype"
        ,d.serial_no "Device_Serial"
        ,d.virtual_host "Virtual Host"
        ,d.network_device "Network Device"
        ,d.os_architecture "OS_Arch"
        ,d.total_cpus "CPU Sockets"
        ,d.core_per_cpu "Cores Per CPU"
        ,d.cpu_speed "CPU Speed"
        ,d.total_cpus*d.core_per_cpu "Total Cores"
        ,CASE When ram_size_type = 'GB' 
          Then d.ram*1024
          ELSE d.ram
        END "RAM"        
        ,v2.name "OS Vendor"
        ,osc.category_name "OS Category"
        ,CASE d.os_version 
          WHEN '' then d.os_name
          ELSE coalesce(d.os_name || ' - ' || d.os_version,d.os_name)
        END "OS Name"
        ,d.os_version "OS Version"
        ,d.os_version_no "OS Version Number"
        ,ose.eol "OS_End of Life"
	      ,ose.eos "OS_End of Support"
        ,v.name "Manufacturer"
        ,h.name "Hardware Model"
        ,d.asset_no "Asset Number"
	    	,(Select count(*) From view_softwaredetails_v1 sd Where sd.device_fk = d.device_pk) "Software Discovered"
        ,(Select count(*) From view_serviceinstance_v2 si Where si.device_fk = d.device_pk) "Services Discovered"
        ,(Select count(*) From view_appcomp_v1 a Where a.device_fk = d.device_pk) "Application Components Discovered"
        ,(Select count(*) From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs' and m.fstype_name <> 'nfs4' and m.filesystem not like '\\\\%')"Local Disk Count"
        ,(Select count(*) From view_mountpoint_v1 mp Where mp.device_fk = d.device_pk) "Mounts Discovered"
        ,(Select count(*) From view_ipaddress_v1 ip Where ip.device_fk = d.device_pk) "IP Addresses Discovered"
        ,(Select count(*) From view_part_v1 p Where p.device_fk = d.device_pk) "Parts Discovered"
        ,d.bios_version "BIOS Version"
        ,d.bios_revision "BIOS Revision"
        ,d.bios_release_date "BIOS Release Date"
        ,sr.name "Storage Room"
        ,b.name "Building Name"
        ,m.name "Room Name"
        ,r.row "Row Name"
        ,r.name "Rack Name"
        ,h.size "Size (RU)"
        ,(Select array_to_string(array(
                  Select ns.name
                  From view_networkshare_v1 ns
                  Where ns.device_fk = d.device_pk),
                  ' | ')) network_shares
        ,(Select array_to_string(array(
                  Select mp.filesystem
                  From view_mountpoint_v1 mp
                  Where mp.device_fk = d.device_pk),
                  ' | ')) mount_points
        ,ci.vendor_fk
        ,ci.account
        ,cv.name "Cloud Service Provider"
        ,ci.service_name "Cloud Service Name"
        ,ci.instance_id "Cloud Instance ID"
        ,ci.instance_name "Cloud Instance Name"
        ,ci.instance_type "Cloud Instance Type"
        ,ci.status "Cloud Instance Status"
        ,ci.location "Cloud Location"
        ,ci.notes "Cloud Notes"
        ,pch.po_date "PO Date"
        ,pch.cost "PO Cost"
        ,pli.cost "Line Item Cost"
        ,pch.order_no "Order Number"
        ,pch.cc_code "Cost Center"
        ,pch.cc_description "Cost Center Description"
        ,(Select array_to_string(array(
                      Select Distinct ip.ip_address
                      From view_ipaddress_v1 ip
                      Where ip.device_fk = d.device_pk),
                      ' | ')) all_listener_device_ips
        ,(Select array_to_string(array(
                      Select Distinct ip.label
                      From view_ipaddress_v1 ip
                      Where ip.device_fk = d.device_pk),
                      ' | ')) all_labels
        ,round(((Select sum(m.capacity-m.free_capacity)/1024 From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs' and m.fstype_name <> 'nfs4' and m.filesystem not like '\\\\%')), 2)"Used Space"
        ,round(((Select sum(m.capacity/1024) From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs' and m.fstype_name <> 'nfs4' and m.filesystem not like '\\\\%')), 2)"Total Space"
        ,round(((Select sum(m.free_capacity/1024) From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs' and m.fstype_name <> 'nfs4' and m.filesystem not like '\\\\%')), 2)"Total Free Space"
    From view_device_v2 d
      Left Join view_purchaselineitems_to_devices_v1 ptd ON ptd.device_fk = d.device_pk
      Left Join view_purchaselineitem_v1 pli ON ptd.purchaselineitem_fk = pli.purchaselineitem_pk
      Left Join view_purchase_v1 pch ON pch.purchase_pk = pli.purchase_fk
      Left Join view_oseoleos_v1 ose ON ose.os_fk = d.os_fk
      Left Join view_hardware_v1 h ON d.hardware_fk = h.hardware_pk
      Left Join view_vendor_v1 v ON h.vendor_fk = v.vendor_pk
      Left Join view_room_v1 sr ON sr.room_pk = d.storage_room_fk 
      Left Join view_rack_v1 r ON d.rack_fk = r.rack_pk
      Left Join view_room_v1 m ON r.room_fk = m.room_pk
      Left Join view_building_v1 b ON b.building_pk = m.building_fk
      Left Join view_os_v1 osc ON osc.os_pk = d.os_fk
      Left Join view_vendor_v1 v2 ON osc.vendor_fk = v2.vendor_pk
      Left Join view_device_custom_fields_flat_v1 dcf ON dcf.device_fk = d.device_pk
      Left Join view_cloudinstance_v1 ci ON ci.device_fk = d.device_pk
      Left Join view_vendor_v1 cv ON cv.vendor_pk = ci.vendor_fk
    Order by d.name ASC 