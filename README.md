[Device42](http://www.device42.com/) is a Continuous Discovery software for your IT Infrastructure. It helps you automatically maintain an up-to-date inventory of your physical, virtual, and cloud servers and containers, network components, software/services/applications, and their inter-relationships and inter-dependencies.


This repository contains scripts that helps you create CSV or JSON files from DOQL queries. It also contains an example folder with some complex queries.


### Device42 DOQL to JSON/CSV file
-----------------------------
* Please rename `settings.json.sample` to `settings.json`.
* For the query you need to run - add `__some_name__.json` or copy / edit examples from "examples" folder.
* Add `reports` folder in the root of repository ( see additional information ).
* Set settings and run!

### settings.json references
-----------------------------
* `host: 192.168.99.102` - Device42 host address ( IP or FQDN )
* `username: admin` - Device42 username
* `password: p@ssw0rd` - Device42 password 

### query.json references
-----------------------------
* `output_filename: test` - output file prefix
* `output_format: json` - output format
* `query: "SELECT * FROM view_device_v1"` - DOQL query ( multi-line possible )
* `limit: 50` - query records limit
* `offset: 100` - pagination offset, items per file
* `date:`
	`  column: last_edited` - filter column, can be last_edited or first_added
	`  days_limit: 2` - days limit since today

### Run
-----------------------------
Call script from command line : `python starter.py query.json` ( You may specify any json file that fit our sample structure )

### Additional information
-----------------------------
* If you don't want to use `date`, `offset` or `limit` filters  - just put value : `null`
* By default all reports comes to the `reports` folder. You may change it to the path that you want.
* Possible to direct insert into different SQL databases with pyodbc, just specify driver like in `examples/service-2-db.json.sample` ( `pip install pyodbc` required )
* Script insert data to the same DB rows names as returns by SELECT query.

### Support
-----------------------------
This Device42 DOQL to JSON/CSV script is provided as-is without any support. We do provide fee-based engineering time blocks if you need help with this script.  To find out more please email sales@device42.com with subject Device42 DOQL to JSON/CSV script support.

