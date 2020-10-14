/* CRE Report for release 16.16 */
/* Inline view of Target CTE (inline views) to streamline the process  - 
 
*/
With 
    target_cre_data  as (
    SELECT Distinct
		/* count (Distinct cre.device_fk) Group by cre.device_fk AS cre_device_count,
		*/
        cre.vendor "Vendor"
		,cre.recommendation_type
        ,round(sum(cre.monthly_ondemand_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2) "Monthly On-Demand Cost"
        ,round(sum(cre.monthly_1yr_resvd_noupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly 1-Year Reserved No Upfront Cost"
        ,round(sum(cre.monthly_1yr_resvd_partupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly 1-Year Reserved Partial Upfront Cost"
        ,round(sum(cre.monthly_1yr_resvd_allupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly 1-Year Reserved All Upfront Cost"
        ,round(sum(cre.monthly_prorated_3yr_resvd_noupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly (prorated) 3-Year Reserved No Upfront Cost"
        ,round(sum(cre.monthly_prorated_3yr_resvd_partupfront_cost)Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly (prorated) 3-Year Reserved Partial Upfront Cost"
        ,round(sum(cre.monthly_prorated_3yr_resvd_allupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly (prorated) 3-Year Reserved All Upfront Cost"
        ,round(sum(cre.yearly_ondemand_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly On-Demand Cost"
        ,round(sum(cre.yearly_1yr_resvd_noupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly 1-Year Reserved No Upfront Cost"
        ,round(sum(cre.yearly_1yr_resvd_partupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly 1-Year Reserved Partial Upfront Cost"
        ,round(sum(cre.yearly_1yr_resvd_allupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly 1-Year Reserved All Upfront Cost"
        ,round(sum(cre.yearly_prorated_3yr_resvd_noupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly (prorated) 3-Year Reserved No Upfront Cost"
        ,round(sum(cre.yearly_prorated_3yr_resvd_partupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly (prorated) 3-Year Reserved Partial Upfront Cost"
        ,round(sum(cre.yearly_prorated_3yr_resvd_allupfront_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly (prorated) 3-Year Reserved All Upfront Cost"
        ,round(sum(cre.monthly_networking_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly Networking Cost"
        ,round(sum(cre.yearly_networking_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly Networking Cost"
        ,round(sum(cre.monthly_storage_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Monthly Storage Cost"
        ,round(sum(cre.yearly_storage_cost) Over(Partition by cre.vendor, cre.recommendation_type), 2)  "Yearly Storage Cost"
    From view_credata_v2 cre 
    ),
/* Get the unique device count from the CRE data  */	
    target_count_cre_data  as (
    SELECT
		count (Distinct cre.device_fk) device_count
	From view_credata_v2 cre 
    ),
/* Get the unique device_fk keys  */		
    target_unique_cre_data  as (
    SELECT Distinct
		cre.device_fk
	From view_credata_v2 cre
    ),
/* Get the mountpoint info from device records  */		
    target_mountpoint_data  as (
    Select Distinct        
        round(((select sum(m.capacity-m.free_capacity)/1024 
	From view_mountpoint_v1 m 
 	Join target_unique_cre_data tucd   
	  ON m.device_fk = tucd.device_fk 
	Where
		m.fstype_name <> 'nfs' and 
		m.fstype_name <> 'nfs4' and 
		m.filesystem not like '\\\\%')) , 0)"Used Space"
    )

/* Put the data back together  */   
    Select 
            tccd.device_count "Total Devices"
            ,tmd."Used Space"
            ,tcd."Vendor"
			,Case When tcd.recommendation_type ='regular'
				Then 'Existing'
				  When tcd.recommendation_type ='ru'
				Then 'Re-sized'
				Else ''
			End "Rcmd Type"
            ,tcd."Monthly On-Demand Cost"
            ,tcd."Monthly 1-Year Reserved No Upfront Cost"
            ,tcd."Monthly 1-Year Reserved Partial Upfront Cost"
            ,tcd."Monthly 1-Year Reserved All Upfront Cost"
            ,tcd."Monthly (prorated) 3-Year Reserved No Upfront Cost"
            ,tcd."Monthly (prorated) 3-Year Reserved Partial Upfront Cost"
            ,tcd."Monthly (prorated) 3-Year Reserved All Upfront Cost"
            ,tcd."Yearly On-Demand Cost"
            ,tcd."Yearly 1-Year Reserved No Upfront Cost"
            ,tcd."Yearly 1-Year Reserved Partial Upfront Cost"
            ,tcd."Yearly 1-Year Reserved All Upfront Cost"
            ,tcd."Yearly (prorated) 3-Year Reserved No Upfront Cost"
            ,tcd."Yearly (prorated) 3-Year Reserved Partial Upfront Cost"
            ,tcd."Yearly (prorated) 3-Year Reserved All Upfront Cost"
            ,tcd."Monthly Networking Cost"
            ,tcd."Yearly Networking Cost"
            ,tcd."Monthly Storage Cost"
            ,tcd."Yearly Storage Cost"
        From target_cre_data tcd, target_count_cre_data tccd, target_mountpoint_data tmd 
		Order by tcd."Vendor" ASC, "Rcmd Type" ASC
