/*
For RU data and metrics.
   Update 9/16/20 
  - updated to to use view_rudata_v2
   Update 2020-10-19
  - updated the view_device_v1 to view_device_v2
*/
Select 
    r.last_updated "RU Data Last Updated"
    ,d.name "Device Name"
    ,d.monitoring_enabled "Monitoring Enabled"
    ,r.rudata_pk "Resource ID"
    ,r.value "Resource Value"
    ,r.sensor_type "Resource Type"
    ,r.sensor "Resource"
    ,r.measure_type "Measurement Type"
    ,r.metric "Measurement Metric"
    ,r.timeperiod_id "Time Period ID"
    ,r.timeperiod "Time Period"
    ,rc.name "Remote Collector Name"
    ,rc.ip "Remote Collector IP"
From 
        view_device_v2 d
    Left Join view_rudata_v2 r on r.device_fk = d.device_pk
    Left Join view_remotecollector_v1 rc on rc.remotecollector_pk = r.remotecollector_fk
    Order By d.monitoring_enabled DESC, d.name ASC, r.timeperiod_id ASC, r.measure_type ASC, r.metric ASC 