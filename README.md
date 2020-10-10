[Device42](http://www.device42.com/) is a Continuous Discovery software for your IT Infrastructure. It helps you automatically maintain an up-to-date inventory of your physical, virtual, and cloud servers and containers, network components, software/services/applications, and their inter-relationships and inter-dependencies.

### Device42 Recommended DOQL and Reports
-----------------------------
This repository includes our SQL files for DOQL, scripts, and Report/Dashboard files that are recommended by the team to access common and useful data discovered by Device42.

These files come in three forms and are intended to be used in different ways:
* `.sql` files found in "Recommended DOQL" and "Affinity Group DOQL". These .sql files can be downloaded or copied then added as [Saved DOQL](https://docs.device42.com/device42-doql/#section-9) or [DOQL](https://docs.device42.com/device42-doql/) to use.
* `.wr` and `.wrc` files found in "Pre-Defined Reports", "Pre-Defined Dashboards", and "Insights". These are intended to be uploaded to [Advanced Reports](https://docs.device42.com/reports/advanced-reporting/), create a new folder if one doesn't exist and use the "Upload" option to navigate to the import file.
* `.json` files found in "Script JSON Examples". These can be used along with the `starter.py` script and usage instructions below.

### Device42 Report Files
-----------------------------
The `.wr` and `.wrc` files in order to use reference names and locations. If the report file is uploaded to a different location or a Chained report that references a report that was renamed you may need to Edit the report in Advanced Reporting to point to the directory and report names modified in your instance.

If the directories and report names are kept the same as this github you will be able to use them consistently without additional modifications.

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

