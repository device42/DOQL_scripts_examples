/*   Trend Report
	Created 2/4/2021
	 Report 1 -  (over the past year - month by month).  shows the devices associated to  AWS, GCP, Azure (and other cloud) and On-Prem. 
	(based upon the last day of the month) 
	- show only those that been added in each group - the rest are in the base.
	2/9/2021 Changes
	- Handle remove records for previous months if location has 0 new and 0 accumulated
	- Switch over to area.
	- Put just month on the X axis
*/
With 
 /* Get all the locations for devices cloud and on prem  */
      dos  as (
        Select Distinct		   
          d.device_pk
		  ,ci.device_fk
		  ,d.name
          ,ci.vendor_fk
		  ,Case When ci.device_fk = d.device_pk and btrim(ci.service_name, ' ') != ''
				Then split_part(ci.service_name,' ', 1) 
				When ci.device_fk = d.device_pk
				Then 'Drop'
				Else coalesce(bd.name,'Undefined Loc')
		   End dev_loc		  
          ,ci.service_name "Cloud Service Name"
		  ,Case When ci.device_fk = d.device_pk
				Then 'Cloud'
				Else 'On-Prem' 
		  End "Hosted Location"
          ,d.first_added
		  ,d.last_edited
          ,substring(date_trunc('Month', d.first_added)::text from 0 for 8) as first_month
          ,substring(date_trunc('Month', d.last_edited + INTERVAL '1 month')::text from 0 for 8) as last_month		  
       From 
          view_device_v2 d
		  Left Join view_building_v1 bd ON bd.building_pk = d.calculated_building_fk
	      Left Join view_cloudinstance_v1 ci ON ci.device_fk = d.device_pk  		  
          Left Join view_vendor_v1 cv ON ci.vendor_fk = cv.vendor_pk
		  Where lower(d.type) != 'cluster'		  
     ),

	/* Rank the dev locations based upon volume  */	
      dos_ranks as
        (select dev_loc
              ,total_devices
              ,rank() over(order by total_devices desc) as rank_dev_count
          from
           (select dev_loc
               ,count(distinct device_pk) as total_devices
           from dos
           group by 1) a),
      dos_all as
        (select dos.*
              ,dos_ranks.rank_dev_count
              /* This is where we set the number of service levels that will not be lumped together */
              ,case when dos_ranks.rank_dev_count <= 15 then dos.dev_loc
                    else 'Other'
              end as dev_group_w_other
          from dos
          left join dos_ranks
            on dos.dev_loc = dos_ranks.dev_loc),
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
    (select dev_group_w_other
          ,month
          ,count(*) as device_count
    from dos_cross_month	
    group by 1,2) a
 Where device_count !=0	
	Order by dev_group_w_other  ASC, month ASC		