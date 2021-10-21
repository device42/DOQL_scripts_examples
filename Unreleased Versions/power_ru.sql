/*
    view_rudata_v2 measure_type_id keys:
        20 : PDU_CURRENT
        22 : PDU_ENERGY_ACTIVE
        24 : PDU_LINE_UTIL
        26 : PDU_POWER_ACTIVE
        30 : PDU_RATED_POWER
        31 : PDU_REACTANCE
        33 : PDU_VOLTAGE
        35 : PDU_STATUS
        37 : PDU_POWER_APPARENT
        39 : PDU_FREQUENCY
        43 : PDU_CAPACITY
        45 : PDU_LOAD
        47 : PDU_REPLACEMENT_INDICATOR
        49 : PDU_RUNTIME_REMAINING
        53 : PDU_HUMIDITY
        55 : PDU_TEMPERATURE
    (20,22,24,26,30,31,33,35,37,39,43,45,47,49,53,55)
    view_rudata_v2 sensor_type_id keys:
        5 : PDU_INFEED
        6 : PDU_OUTLET
        7 : PDU_OUTPUT
        8 : PDU_BATTERY
        9 : PDU_BANK
        10 : PDU_ENV_SENSOR
    (5,6,7,8,9,10)
    view_rudata_v2 timeperiod_id keys:
        1 : 1 Day
        2 : 7 Days
        3 : 30 Days
        4 : 90 Days
        5 : 365 Days
    (1,2,3,4,5)
*/
SELECT
    building.name "Building"
    ,room.name "Room"
    ,rack.name "Rack"
    ,pccf."Power Panel" "Power Panel"
    ,pdu.name "PDU"
    ,ru.sensor_type "Sensor Type"
    ,ru.sensor "Sensor"
    ,ru.metric "Metric"
    ,ru.measure_type "Measure Type"
    ,ru.value / 1000 "kVA"
    ,ru.timeperiod "Time Period"
    ,ru.window "Window"
    ,ru.start_time "Start Time"
    ,ru.end_time "End Time"
    ,rc.name "Remote Collector"
/*    -- ,ru.rudata_pk
    -- ,ru.sensor_type_id
    -- ,ru.remotecollector_fk
    -- ,ru.device_fk,
    -- ,ru.measure_type_id
    -- ,ru.metric_id,
    -- ,ru.last_updated
    -- ,ru.timeperiod_id  */
FROM view_rudata_v2 ru
JOIN view_remotecollector_v1 rc ON ru.remotecollector_fk = rc.remotecollector_pk
JOIN view_device_v2 device ON ru.device_fk = device.device_pk
JOIN view_pdu_v1 pdu ON device.device_pk = pdu.device_fk
LEFT JOIN view_rack_v1 rack ON rack.rack_pk = pdu.calculated_rack_fk 
LEFT JOIN view_room_v1 room ON room.room_pk = pdu.calculated_room_fk
LEFT JOIN view_pdu_custom_fields_flat_v1 pccf ON pccf.pdu_fk = pdu.pdu_pk
LEFT JOIN view_building_v1 building ON building.building_pk = pdu.calculated_building_fk
WHERE ru.sensor_type_id IN (5,6,7,8,9,10) and ru.measure_type_id IN (37) and ru.metric_id IN (1)