<!-----
NEW: Check the "Suppress top comment" option to remove this info from the output.

Conversion time: 3.305 seconds.


Using this Markdown file:

1. Paste this output into your source file.
2. See the notes and action items below regarding this conversion run.
3. Check the rendered output (headings, lists, code blocks, tables) for proper
   formatting and use a linkchecker before you publish this page.

Conversion notes:

* Docs to Markdown version 1.0β29
* Mon Apr 26 2021 09:53:15 GMT-0700 (PDT)
* Source doc: Device42 Insights with Power BI
* This document has images: check for >>>>>  gd2md-html alert:  inline image link in generated source and store images to your server. NOTE: Images in exported zip file from Google Docs may not appear in  the same order as they do in your doc. Please check the images!


WARNING:
You have 6 H1 headings. You may want to use the "H1 -> H2" option to demote all headings by one level.

----->


<p style="color: red; font-weight: bold">>>>>>  gd2md-html alert:  ERRORs: 0; WARNINGs: 1; ALERTS: 9.</p>
<ul style="color: red; font-weight: bold"><li>See top comment block for details on ERRORs and WARNINGs. <li>In the converted Markdown or HTML, search for inline alerts that start with >>>>>  gd2md-html alert:  for specific instances that need correction.</ul>

<p style="color: red; font-weight: bold">Links to alert messages:</p><a href="#gdcalert1">alert1</a>
<a href="#gdcalert2">alert2</a>
<a href="#gdcalert3">alert3</a>
<a href="#gdcalert4">alert4</a>
<a href="#gdcalert5">alert5</a>
<a href="#gdcalert6">alert6</a>
<a href="#gdcalert7">alert7</a>
<a href="#gdcalert8">alert8</a>
<a href="#gdcalert9">alert9</a>

<p style="color: red; font-weight: bold">>>>>> PLEASE check and correct alert issues and delete this message and the inline alerts.<hr></p>



# Device42 Data Insights with Power BI

**_Table of Contents_**


[TOC]



# Introduction

In order to facilitate an easy method to extract data from Device42 and provide insightful visuals and metrics Device42  makes available a pre-built Power BI Dashboard file that contains visualizations and reports for multiple use cases that include transformation, security, inventory, and others.

Example Screenshots:



<p id="gdcalert1" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image1.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert2">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image1.png "image_tooltip")




<p id="gdcalert2" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image2.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert3">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image2.png "image_tooltip")



# Prerequisites for Usage

In order to use the dashboard the following must be available.



1. Ability to connect to the Device42 Main Appliance (HTTPS port 443)
2. Access to a Device42 User with “Super User” enabled (Allows access to DOQL for all data)
3. Device42 Main Appliance must be on [version 17 or greater](https://www.device42.com/update/)
4. The [Power BI Desktop Client installed](https://powerbi.microsoft.com/en-us/downloads/)
5. [Device42 ODBC Driver installed](https://docs.device42.com/external-integrations/odbc-driver-integration/) with a [User DSN configured](https://docs.device42.com/external-integrations/powerbi-integration/#section-4)

**_This file will use data and tables supporting multiple use cases of Device42 which may mean not all installations will have this data in use or the required modules available._**

**_The Power BI file will still be entirely functional though visualizations that do not have qualifying data will be blank._**

For all visualizations and functions to be available make sure to configure or enable the following in Device42.



1. **Enable Global Cloud Recommendation Engine Settings**, this can be performed by navigating to Tools > Settings > Global Settings. Then _Edit_ the Global Settings and Scroll to the bottom to find _Global Cloud Recommendation Settings_. At a minimum this must be enabled for **_AWS_**, but you can enable it for all CSP’s. **_It is also recommended to use the 95th Percentile as the RU Recommendation Metric_**. All other options and regions can be set by preference.

<p id="gdcalert3" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image3.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert4">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image3.png "image_tooltip")

2. Many of the visuals and functions will also use **Device Tags **and **Business Applications** as slicers, it is possible to modify the dashboards to use other values, but it is recommended to apply relevant business tags or [create Business Applications](https://docs.device42.com/apps/business-applications/) with your devices.

**The Device42 Modules Currently Used:**



*   **Software License Management**
*   **Application Dependency Mapping**
*   **Resource utilization**
*   **Storage Discovery**

_Though the above are not required, more functionality will be available with them._


# 


# Install the Device42 ODBC Driver

In order to connect Power BI to Device42 we will be using ODBC. The Device42 ODBC driver will be required to allow this ability.

[Download the Device42 ODBC Driver here.](https://www.device42.com/miscellaneous-tools/)

Run the ODBC Driver install after it has been downloaded, [steps to install found here](https://docs.device42.com/external-integrations/odbc-driver-integration/#section-1).


# Configure the ODBC User DSN



1. To create / pre-define a DSN (Data Source Name), open the Windows ODBC Data Source Administrator via the Windows Start Menu. \
<span style="text-decoration:underline;">Windows 10</span>: click **_Start -> Windows Administrative Tools -> ODBC Data Sources (64-bit)_**; [note there is also a 32-bit version, which you can ignore]. \
<span style="text-decoration:underline;">Windows 7</span>: Click **_Start -> All Programs -> Administrative Tools -> Data Sources (ODBC)_**: \


<p id="gdcalert4" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image4.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert5">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image4.png "image_tooltip")

2. Click the **Add** button to begin adding a new datasource. In the “Create New Data Source” window that is displayed, choose the “Device42 ODBC Driver” and click “Finish”: \


<p id="gdcalert5" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image5.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert6">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image5.png "image_tooltip")

3. On the “Device42 ODBC Driver DSN Configuration” screen that is displayed, enter values as explained below: \


<p id="gdcalert6" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image6.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert7">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image6.png "image_tooltip")

    1. **DSN Name**: The name to identify this DSN.
    2. **Server Host**: The host name of the Device42 server.
    3. **Port**: The port number that the Device42 server is servicing requests on. The default value is the standard SSL port of 443. If you leave this field blank, it will also default to 443.
    4. **Username**: The username you use to login to Device42.
    5. **Password**: The password you use to login to Device42.
4. Click the “Test” button to try connecting using the information you specified. You will receive a message if the connection could or could not be made. If the connection could not be made, verify that the information you entered is correct.
5. Click the “Save” button to save the changes you made to the DSN. Your changes will only be saved if the information entered results in a successful connection. If the connection could not be made, verify that the information you entered is correct.

Setup of the Device42 ODBC DSN is complete. You should now be able to utilize the pre-configured DSN throughout PowerBI.


# Using the Device42 Data Insights Power BI

Now that the prerequisites have been performed. The Power BI file can be downloaded and loaded for use.



1. Download the Power BI .pbix file
2. Open the file Device42_Data_Insights.pbix
    1. This file will open pre-loaded with data from a demo environment of Device42
3. In order to load your Device42 data update the Data Source Settings by performing the following
    2. In the right side pane for **_Fields_** right click any table and** **select **_Edit query_**

<p id="gdcalert7" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image7.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert8">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image7.png "image_tooltip")

    3. This will then open the** _Power BI Query Editor_**, click on **_Data Source Settings_** from the **_Home_** menu

<p id="gdcalert8" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image8.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert9">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image8.png "image_tooltip")

    4. Select the currently listed **_DSN_**, then click **_Change Source_**, and select the **_Data Source name (DSN) _**drop down to the **_DSN_** configured in the previous steps above. Once done, click **_Ok_**, then click **_Close_**

<p id="gdcalert9" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image9.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert10">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image9.png "image_tooltip")

    5. Finally, click on **_Close & Apply_** in the **_Home_** menu
4. Power BI will then start to refresh and load the data into the dashboard. **_For all prompts to follow click “Run” or “Ok”_**
    6. There will be multiple prompts about running a **_Native Database Query_** this is normal and **_Run_** can be performed
5. After some time the data and connection model will be updated with your data and all visualizations will reflect your Device42 data.