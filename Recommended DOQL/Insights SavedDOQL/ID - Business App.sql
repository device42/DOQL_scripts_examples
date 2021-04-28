/*   Trend Report - Business Application
          Created 3/1/2021
           Report 4 - Over the past year show Business Application
      */
      With
       /* Get all the Business Application for devices   */
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
			,Case When bae.device_fk = 0 or bae.device_fk is NULL Then 'Uncategorized'
				  Else ba.name
			End ba_name
          From
            view_device_v2 d
            Left Join view_businessapplicationelement_v1 bae on d.device_pk = bae.device_fk
			Left Join view_businessapplication_v1 ba on bae.businessapplication_fk = ba.businessapplication_pk			
            Left Join view_building_v1 bd ON bd.building_pk = d.calculated_building_fk
            Left Join view_cloudinstance_v1 ci ON ci.device_fk = d.device_pk
            Left Join view_vendor_v1 cv ON ci.vendor_fk = cv.vendor_pk
            Where lower(d.type) != 'cluster' and Not d.network_device
		),

	/* Rank the service levels based upon volume  */	
      dos_ranks as
        (select ba_name
              ,total_devices
              ,rank() over(order by total_devices desc) as rank_ba_count
          from
           (select ba_name
               ,count(distinct device_pk) as total_devices
           from dos
           group by 1) a),
      dos_all as
        (select dos.*
              ,dos_ranks.rank_ba_count
              /* This is where we set the number of service levels that will not be lumped together */
              ,case when dos_ranks.rank_ba_count <= 15 then dos.ba_name
                  else 'Other'
                  end as ba_group_w_other
          from dos
          left join dos_ranks
            on dos.ba_name = dos_ranks.ba_name),
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
    (select ba_group_w_other
          ,month
          ,count(*) as device_count
    from dos_cross_month	
    group by 1,2) a
 Where device_count !=0	
	Order by ba_group_w_other  ASC, month ASC		