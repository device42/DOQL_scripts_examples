/* CRE Report for release 16.18 */
/* Inline view of Target CTE (inline views) to streamline the process  - 
   Updated - 9/24
   - added in the recommendation type so now producing 2 rows per vendor; costs based upon config and one based upon usage.
   - 10/7/20 Updated
     -  Produce a "Matrix report to be used in a Delivery report.
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
    ),
/* Put the data back together  */   
/* Pull the CRE records together for each Cloud provider  */        
    target_cre_summary_data  as (
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
            ,'1' cost_type_id
            ,'On-Demand' cost_type
            ,tcd."Monthly On-Demand Cost"
            ,tcd."Yearly On-Demand Cost"          
        From target_cre_data tcd, target_count_cre_data tccd, target_mountpoint_data tmd 
  Union 
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
            ,'2' cost_type_id           
            ,'1_YR_Reserved_Instance' cost_type
            ,tcd."Monthly 1-Year Reserved All Upfront Cost"           
            ,tcd."Yearly 1-Year Reserved All Upfront Cost"
        From target_cre_data tcd, target_count_cre_data tccd, target_mountpoint_data tmd            
  Union 
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
            ,'3' cost_type_id               
            ,'3_YR_Reserved_Instance' cost_type
            ,tcd."Monthly (prorated) 3-Year Reserved All Upfront Cost"            
            ,tcd."Yearly (prorated) 3-Year Reserved All Upfront Cost"
        From target_cre_data tcd, target_count_cre_data tccd, target_mountpoint_data tmd        
  Union 
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
            ,'4' cost_type_id               
            ,'Network Costs' cost_type
            ,tcd."Monthly Networking Cost"
            ,tcd."Yearly Networking Cost"
        From target_cre_data tcd, target_count_cre_data tccd, target_mountpoint_data tmd 
  Union 
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
            ,'5' cost_type_id               
            ,'Storage Costs' cost_type          
            ,tcd."Monthly Storage Cost"
            ,tcd."Yearly Storage Cost"
        From target_cre_data tcd, target_count_cre_data tccd, target_mountpoint_data tmd 
    )
    Select 
            csde."Vendor"
            ,csde.cost_type "Cost Category"
            ,csde."Monthly On-Demand Cost" "Existing - Monthly Costs"
            ,csde."Yearly On-Demand Cost"  "Existing - Yearly Costs"
            ,csdr."Monthly On-Demand Cost" "Right Sized - Monthly Costs"
            ,csdr."Yearly On-Demand Cost"  "Right Sized - Yearly Costs"
        From target_cre_summary_data csde
        Join target_cre_summary_data csdr On (csde."Vendor" = csdr."Vendor")
                                          and (csde.cost_type = csdr.cost_type)
                                          and csdr."Rcmd Type" = 'Re-sized'
        Where csde."Rcmd Type" = 'Existing'
        Order by csde."Vendor" ASC , csde.cost_type_id ASC