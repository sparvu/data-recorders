# TROUBLESHOOTING

This is a short guide how to check and verify if your Kronometrix Data Recording installation is properly functioning. Kronometrix Data Recording contains a simple and efficient set of data recorders and transport utilities for IoT, ICT enterprise, weather and environment, designed to record top essential performance metrics, save raw data and send it for analysis.

## Configurations
Kronometrix Data Recording uses several configuration files to operate. The main configuration file, **kronometrix.json** stores information about the active data recorders being used, and the address where data will be delivered for analysis. Additonal, certain recorders might have their own configuration files, like: **webrec.json**, **svcrec.json**, **rs485rec.json**. Not all data recorders have their own configration file. 

### kronometrix.json

This is the main configuration file. Includes the following sections:

#### Logging section

    This is the section defining the base path and the location where all raw data logs will be stored. This can be located on a local disk or a remote LUN storage. Usually, this section, should not be changed or removed.

#### Transport section

    Describes all raw data files and their naming convention. Usually, this section, should not be changed or removed.

#### Data Fabric section
 
This is the section where users should defined where they want tosend data. The platform section describes the details of one or many data analytics fabrics, each with own settings.

All raw data can be transported to one or many platforms at the same time. Under this section we need to define and configure, the following:

      o port number, the port number default 80, or 443
     
      o hostname, IP or FQD of the platform 
  
      o protocol: HTTP or HTTPS

      o subscription type: cpd or amd or wcd. cpd means, computer performance data 
        and describes data belong to IT computer performance. There are many types
        of data subscriptions, each having its own type, metrics and summary 
        statistics:

            cpd - Computer Performance
            epd - End User Performance
            dpd - Datacenter Performance
            spd - Service Provider Performance
            wpd - Web Application Performance

           iaqd - Indoor Air Quality
            aqd - Outdoor Air Quality
            wcd - General Meteorology
            amd - Aviation Meteorology

        o sid: subscription id

        o tid: token id

        o dsid: to be let empty, will be automatically be computed


## Operation

### Start procedure

#### Recorders

We can start all data recorders using /opt/kronometrix/etc/rec script utility.

    As krmx user:
      $ /opt/kronometrix/etc/rec start

    OR

    As root:
      # /etc/init.d/kdr start

##### Transport
  
We can start the transport service, using /opt/kronometrix/etc/tansport script utility.
    
    As krmx user:
      $ /opt/kronometrix/etc/transport start

    OR

    As root:
      # /etc/init.d/kdr_transport start

### Stop procedure

#### Recorders

We can stop all data recorders using /opt/kronometrix/etc/rec script utility.

    As krmx user:
      $ /opt/kronometrix/etc/rec stop

    OR

    As root:
      # /etc/init.d/kdr stop

##### Transport
  
We can stop the transport service, using /opt/kronometrix/etc/tansport script utility.
    
    As krmx user:
      $ /opt/kronometrix/etc/transport stop

    OR

    As root:
      # /etc/init.d/kdr_transport stop

## Log information

All Kronometrix log files are located under /opt/kronometrix/log directory. There you have access to all log files for each data recorder and trasnport utilities.

### Recorders

* System Data Recorder: **sysrec.log**
* Cpurec Data Recorder: **cpurec.log**
* Disk Data Recorder: **diskrec.log**
* Network Interface Data Recorder: **nicrec.log**
* Inventory Data Recorder: **hdwrec.log**
* RS485 Serial Data Recorder: **rs485rec.log**
* Web Data Recorder: **webrec.log** **webinvrec.log**
* Internet Service Data Recorder: **svcrec.log**  


### Transport

* Transport Utility: **sender.log** 


## Raw Data

### Current Day

Kronometrix Data Recording is saving all collected metrics under one or many text files located under **/opt/kronometrix/log/current** directory. The files are in CSV format, universal available for any systems or applications.

### Daily

At midnight Kronometrix Data Recording will create and save the raw data stored for the day which have passed to a directory stampped as previous day. In this directory all files will be moved and archived, located under **/opt/kronometrix/log/daily** directory. 



