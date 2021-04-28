/*   Trend Report - Service Level
          Created 2/19/2021
           Report 2 - Over the past year show Service Level
      */
      With
       /* Get all the service levels for devices   */
      dos  as
        (select
            d.device_pk
            ,ci.device_fk
            ,d.name
            ,d.first_added
            ,d.last_edited
            ,substring(date_trunc('Month', d.first_added)::text from 0 for 8) as first_month
            ,substring(date_trunc('Month', d.last_edited + INTERVAL '1 month')::text from 0 for 8) as last_month
            ,ci.vendor_fk
            ,d.os_name
			,d.os_version
			,d.os_version_no
            ,Case When btrim(d.os_name,' ') = '' or d.os_name is NULL then 'Partial Discovery'
                 When position('windows' IN lower(d.os_name)) > 0 or
                      position('microsoft' IN lower(d.os_name)) > 0 Then 'Windows'
                 When position('linux' IN lower(d.os_name)) > 0 or
                      position('centos' IN lower(d.os_name)) > 0 or
                      position('redhat' IN lower(d.os_name)) > 0 or   /* Redhat  */
                      position('ubuntu' IN lower(d.os_name)) > 0 or
                      position('suse' IN lower(d.os_name)) > 0 or
                      position('debian' IN lower(d.os_name)) > 0 or
                      position('sles' IN lower(d.os_name)) > 0 then 'Linux'
                 When position('freebsd' IN lower(d.os_name)) > 0 or
                position('aix' IN lower(d.os_name)) > 0 or
                      position('hp' IN lower(d.os_name)) > 0 or
                      position('sunos' IN lower(d.os_name)) > 0 or
                      position('solaris' IN lower(d.os_name)) > 0 then 'Unix'
                 When position('400' IN lower(d.os_name)) > 0 then 'OS400'
                 When position('z/os' IN lower(d.os_name)) > 0 then 'z/OS'
                 When (position('ios' IN lower(d.os_name)) > 0 and Not network_device) or
                      position('mac' IN lower(d.os_name)) > 0 then 'Apple'
                 When position('esx' IN lower(d.os_name)) > 0 or
                      position('vmware' IN lower(d.os_name)) > 0 then 'ESX'
                 When position('xen' IN lower(d.os_name)) > 0 then 'XEN'
                 When position('virtbox' IN lower(d.os_name)) > 0 then 'VM'
               Else 'Other'
            end as os_group
            ,case When ci.device_fk = d.device_pk
                  Then 'Cloud'
                  Else 'On-Prem'
            end as hosted_location
            ,deviceos_fk
            ,os_fk
			,d.service_level_id
			,Case When btrim(d.service_level,' ') = '' or d.service_level is NULL then 'UNDEFINED'
			      Else d.service_level
			End service_level
          From
            view_device_v2 d
            Left Join view_building_v1 bd ON bd.building_pk = d.calculated_building_fk
            Left Join view_cloudinstance_v1 ci ON ci.device_fk = d.device_pk
            Left Join view_vendor_v1 cv ON ci.vendor_fk = cv.vendor_pk
            Where lower(d.type) != 'cluster' and Not d.network_device
		),

	/* Rank the service levels based upon volume  */	
      dos_ranks as
        (select service_level
              ,total_devices
              ,rank() over(order by total_devices desc) as rank_os_count
          from
           (select service_level
               ,count(distinct device_pk) as total_devices
           from dos
           group by 1) a),
      dos_all as
        (select dos.*
              ,dos_ranks.rank_os_count
              /* This is where we set the number of service levels that will not be lumped together */
              ,case when dos_ranks.rank_os_count <= 8 then dos.service_level
                  when dos.service_level like 'Other' then 'Other'
                  else 'Other'
                  end as sl_group_w_other
          from dos
          left join dos_ranks
            on dos.service_level = dos_ranks.service_level),
      month_date_table as
        (select distinct substring(date_trunc('Month', datum)::text from 0 for 8) as month
          from
          (select (current_timestamp - INTERVAL '12 month')::date + SEQUENCE.DAY AS datum
                from GENERATE_SERIES(0, 5000) AS SEQUENCE (DAY)
                group by SEQUENCE.DAY
          ) a),
      dos_cross_month as
		(select *
          from dos_all
          join month_date_table
            on dos_all.first_month <= month_date_table.month
            and least(dos_all.last_month, substring(date_trunc('Month', current_date)::text from 0 for 8)) >= month_date_table.month)
select *
      ,round(100.00 * device_count/(sum(device_count) over(partition by month)),2) as percent_device_count
from
    (select sl_group_w_other
          ,month
          ,count(*) as device_count
    from dos_cross_month
    group by 1,2) a
 Where device_count !=0	
	Order by sl_group_w_other  ASC, month ASC		