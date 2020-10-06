/* AWS Migration factory Template - 06_17_20  */
/* Inline view of Target CTE (inline views) to streamline the process  - 
Feedback - 6/23
        1.  The server_name column
            The server name is not unique, there are a few duplicated server names, we cannot import duplicated servers to the migration factory
            Some server names doesn't seems to be a real hostname for that machine
        2.  The server_os column
            Windows or Linux should be lower case: windows, linux
        3.  The server_fqdn column
            A lot of servers do not have a server_fqdn column, so I filled these up with sample data
 New Add - 9/9/20
        1. Add CRE info included in the 16.16 release
*/
With 
    target_device  as (
        Select Distinct        
          d.device_pk
          ,d.type
          ,d.sub_type
          ,d.virtual_subtype
          ,lower(d.name) "Device Name"
          ,CASE When split_part(d.name,'.',2) is Null  
              THEN Null 
              ELSE substring(lower(d.name) from '\.(.*)$') 
          End "Domain"  
    /* Normalize - Grp the OS's */
          ,CASE When position('windows' IN lower(d.os_name)) > 0 or
                    position('microsoft' IN lower(d.os_name)) > 0 
               Then 'Windows'
               When position('linux' IN lower(d.os_name)) > 0 or
                    position('centos' IN lower(d.os_name)) > 0 or
                    position('redhat' IN lower(d.os_name)) > 0 or     /* Redhat  */  
                    position('ubuntu' IN lower(d.os_name)) > 0 or
                    position('suse' IN lower(d.os_name)) > 0 or
                    position('debian' IN lower(d.os_name)) > 0 or
                    position('sles' IN lower(d.os_name)) > 0 
               Then 'Linux'                 
               When position('freebsd' IN lower(d.os_name)) > 0 or
                    position('aix' IN lower(d.os_name)) > 0 or
                    position('hp' IN lower(d.os_name)) > 0 or
                    position('sunos' IN lower(d.os_name)) > 0 or
                    position('solaris' IN lower(d.os_name)) > 0                  
               Then 'Unix'                  
               When position('400' IN lower(d.os_name)) > 0 
               Then 'OS400'
               When position('z/os' IN lower(d.os_name)) > 0 
               Then 'z/OS'                             
               When (position('ios' IN lower(d.os_name)) > 0 and Not network_device) or
                    position('mac' IN lower(d.os_name)) > 0 
               Then 'Apple' 
               When position('esx' IN lower(d.os_name)) > 0 or
                    position('vmware' IN lower(d.os_name)) > 0 
               Then 'ESX'
               When position('xen' IN lower(d.os_name)) > 0
               Then 'XEN'              
               When position('virtbox' IN lower(d.os_name)) > 0
               Then 'VM'                   
               Else Null
          End AS "OS Group"
          ,d.os_name
          ,d.os_version
          ,d.service_level "Service_Level"  
       From 
          view_device_v1 d
        Where Not d.network_device  and       
                  (lower(d.sub_type) NOT IN ('ups','pdu','crac','tap','scrambler','encoder','access point','ats','multiplexer','network printer') or  lower(d.sub_type) IN ('','laptop','workstation','server board','branch circuit power meter') or
                    d.sub_type is NULL) and
                    position('container' IN lower(d.virtual_subtype)) = 0 
       ),
/*  Build FQDN with DNSzone via IP
*/         
    target_dnsname  as (
        Select Distinct        
          td.device_pk
          ,ip.ip_address
          ,td."Device Name" dname
          ,dz.name dzname  
          ,concat(lower(td."Device Name"),'.', lower(dz.name))fqdn_dns          
       From 
          view_ipaddress_v1 ip
          join target_device td on td.device_pk = ip.device_fk
          join view_subnet_v1 sn on sn.subnet_pk = ip.subnet_fk
          join view_dnszone_v1 dz on dz.vrfgroup_fk = sn.vrfgroup_fk
       ),
/*  Build FQDN with DNSzone via DNSrecord
*/         
    target_dnsname_dnsrecord  as (
        Select Distinct        
          td.device_pk
          ,td."Device Name" dname
          ,dz.name dzname  
          ,concat(lower(td."Device Name"),'.', lower(dz.name))fqdn_dns          
       From 
          target_device td
          join view_dnsrecords_v1 dns on dns.name = td."Device Name"
          join view_dnszone_v1 dz on dz.dnszone_pk = dns.dnszone_fk
       ),      
/*  Figure out the FQDN candidates from aliases and device name
*/  
    target_device_FQDN as (     
        Select Distinct
          ctd.device_pk
          ,CASE When position('.' IN ctd."Device Name") > 0 
              THEN ctd."Device Name"
              ELSE Null
          End as "dname"  
          ,CASE When position('.' IN da.alias_name) > 0
              THEN da.alias_name 
              ELSE Null
          End as "aa_dname"         
          ,CASE When position('.' IN dna.alias_name) > 0  
              THEN dna.alias_name  
              ELSE Null
          End as "na_dname"
       From 
            target_device ctd 
            Left join view_devicealias_v1 da on da.device_fk = ctd.device_pk
            Left join view_devicenonauthoritativealias_v1 dna on dna.device_fk = ctd.device_pk
        ),
/*  Figure out the Business Apps for each device
*/  
    target_business_app as (        
        Select Distinct
          td.device_pk
          ,ba.name
       From 
          target_device td 
          Left join view_businessapplicationelement_v1 bae on bae.device_fk = td.device_pk
          Left join view_businessapplication_v1 ba on ba.businessapplication_pk = bae.businessapplication_fk
        ),
/* Get the RU CRE data  */
    target_cre_data_ru  as (
    SELECT 
        cre.device_fk
        ,cre.tenancy
        ,cre.recommendation_type
        ,cre.recommended_instance
    From view_credata_v2 cre
     Where lower(cre.vendor) IN ('aws') and lower(cre.recommendation_type) = 'ru'   
    ),
/* Get the Regular CRE data  */
    target_cre_data_reg  as (
    SELECT 
        cre.device_fk
        ,cre.tenancy
        ,cre.recommendation_type
        ,cre.recommended_instance
    From view_credata_v2 cre
     Where lower(cre.vendor) IN ('aws') and lower(cre.recommendation_type) = 'regular'  
    )       
/*  
*/  
/*  Pull all the data together   */ 
   Select Distinct
        lower((Select array_to_string(array(
               Select distinct tba.name
               From target_business_app tba
               Where tba.device_pk = td.device_pk),
               ' | '))) app_name             
        ,td.device_pk
        ,lower(td."Device Name") server_name
        ,lower(td."OS Group") server_os 
        ,CASE When td."OS Group" = 'Windows'
             Then td.os_name
             Else Concat(td.os_name, ' ', td.os_version)
        End server_os_version         
        ,coalesce(tdf."dname", tdsnr.fqdn_dns, tdsn.fqdn_dns, tdf."aa_dname", tdf."na_dname") server_fqdn  
        ,lower(td."Service_Level") server_environment
        ,td.type, td.sub_type 
        ,td.virtual_subtype
        ,ru.tenancy ru_tenancy
        ,ru.recommendation_type ru_recommendation_type
        ,ru.recommended_instance ru_recommended_instance
        ,reg.tenancy reg_tenancy
        ,reg.recommendation_type reg_recommendation_type
        ,reg.recommended_instance reg_recommended_instance
        ,Case When ru.recommended_instance is Null
              Then reg.tenancy
              Else ru.tenancy
         End tenancy_sl
        ,Case When ru.recommended_instance is Null
              Then reg.recommendation_type
              Else ru.recommendation_type
         End recommendation_type_sl
        ,Case When ru.recommended_instance is Null
              Then reg.recommended_instance
              Else ru.recommended_instance
         End recommended_instance_sl          
      From 
        target_device td
        Left join target_device_FQDN tdf on tdf.device_pk = td.device_pk  
        Left join target_dnsname tdsn on tdsn.device_pk = td.device_pk
        Left join target_dnsname_dnsrecord  tdsnr on tdsnr.device_pk = td.device_pk
        Left Join target_cre_data_ru ru on ru.device_fk = td.device_pk
        Left Join target_cre_data_reg reg on reg.device_fk = td.device_pk
      Where td."OS Group" is  NOT Null and 
            td."OS Group" IN ('Windows', 'Linux')