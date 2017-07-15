
![alt tag](https://github.com/kronometrix/recording/blob/master/k-logo.jpg)

## Overview

A simple and efficient set of data recorders and transport utilities fo ICT, Environmental Monitoring, Meteorology and IoT industries, responsible to record top essential performance metrics, save raw data and transport it for further analysis. 

## Time Series
All recorded observations we call them raw data. Raw data is produced by a monitoring agent, part of a data source.  This set of data is not modified, altered or changed in any way. All collected metrics are variable measured sequentially in time, called time series. All these observations collected over fixed sampling intervals create a historical time series. To easy the access to all this set of data we simple store the observations on commodity disk drives, compressed, in text format.

Time series let us understand what has happened in past and look in the future, using various statistical models. In addition , having access to these historical time series will help us to build a simple capacity planning model.


## Data Message
All collected metrics over time make a data message. There can be many types of data messages: metrics regarding computer system utilization cpu or memory utilization, or weather data from a meteorological station, or water cubic meters per hour from an water pump. All these coming from one or many data sources. Each data source, must be unique and tagged as such. A data source, ds will have an unique UUID.

All these metrics, observations are ultimately the data message. To describe such messages we built a library of monitoring objects documented here: [library of monitoring objects](https://github.com/kronometrix/lmo)


## Data Source
A data source can have attached different types of sensors attached to, or the data source can be the sensor itself. It depends. Some examples:

 * A computer system: can have one or many data messages regarding computer performance: cpu utilization, disk IO, network IO, etc. In this case we can have one data source, the performance metrics of the system itself.
 
 * A computer system + other utilities: we can connect to a computer system a weather station, or any other type of monitoring system. In this case we have more than one data source, one data source for computer performance metrics and another data source for weather data.
 
 * A dedicated weather station: a standalone weather station, capable of being on a TCP/IP network which can send or or many data messages without an additional computer system. In this case we have a single data source.
 
It is important to understand that we process data based on a unique data source. A data source can have one or many types of data messages, all messages being described and defined under LMO.


### Industries
We plan to support and record data from different types of industries. For some we have already developed data recorderds, like IT, Meteorology and we need help to enhance it. For some, we plan using data loggers to enahnce and speed-up the recording process. For each case, raw data will be presented as messages, based on [LMO](https://github.com/sparvu/lmo). 

 * Environmental Monitoring
 * Information and Communications Technology (ICT)
 * Meteorology
 * Internet of Things 


#### Information and Communications Technology

 * sysrec - overall system CPU, MEM, DISK, NIC utilization, throughput and errors
 * cpurec - per-CPU statistics
 * nicrec - per NIC statistics
 * diskrec - per DISK statistics
 * hdwrec - the hardware, software data inventory
 * jvmrec - Java VM statistics
 * httprec - the HTTP server statistics: NGINX, Apache, PFP-FPM
 * certrec - X.509 security certificate statistics
 * svcrec - entreprise service statistics: IMAP, SMTP, POP3, LDAP, DNS, TCP(Any)
 * direc - per directory statistics 
 * ntprec - NTP server statistics
 * procrec - per process statistics
 * webrec - Web response time analyzer


#### Environmental Monitoring

 * rs485rec - RS485 MODBUS RTU recorder. Currently supporting Vaisala GMW90, Tongdy G01, Tongdy MSD IAQ  


#### General Meteorology

 * wsrec - Weather data recorder. Curretnly supporting WH1080, WH1081, WH1090, WH20xx
  
