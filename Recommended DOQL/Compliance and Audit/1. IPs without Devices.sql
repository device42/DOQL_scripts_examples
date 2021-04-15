select ip.ipaddress_pk
          ,split_part(ip.ip_address::text, '/', 1) as "IP Address"
          ,sn.network as "Subnet Network"
          ,range_begin as "Subnet Range Begin"
          ,range_end as "Subnet Range End"
          ,sn.mask_bits as "Mask Bits"
          ,dns.name as "DNS Name"
          ,dns.type as "DNS Type"
          ,dns.content as "DNS Content"
          ,dns.dnszone_fk
    from view_ipaddress_v1 ip
    left join view_subnet_v1 sn
      on ip.subnet_fk = sn.subnet_pk
    left join view_dnsrecords_v1 dns
      on host(ip.ip_address) =  dns.content
      and dns.type like 'A'
    where ip.device_fk is null
      and not ip.available