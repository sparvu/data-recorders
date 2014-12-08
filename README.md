## Overview

All recorded observations we call them raw data. Raw data is produced by a monitoring agent, running on each host we plan to record data from. This set of data is not modified, altered or changed in any way and it is entirely the way we collected from a host, no matter is a computer system, weather station, a business analytic platform as long as it is a TCP/IP host on a network.

## Time Series

All collected metrics are variable measured sequentially in time, called time series. All these observations collected over fixed sampling intervals create a historical time series. To easy the access to all this set of data we simple store the observations on commodity disk drives, compressed, in text format.

Time series let us understand what has happened in past and look in the future, using various statistical models. In addition , having access to these historical time series will help us to build a simple capacity planning model.


## Data Message
All collected metrics over time from a host make a data message. There can be many types of data messages: metrics regarding computer system utilization cpu or memory utilization, or weather data from a meteorological station, or water cubic meters per hour from an water pump. 

All these metrics, observations are ultimately the data message. To describe such messages we built a library of monitoring objects documented here: [library of monitoring objects](https://github.com/kronometrix/lmo)


## Host
A host can have attached different types of sensors, or a host can be the sensor itself. It depends. Some examples:

 * A computer system: can have one or many data messages regarding computer performance: cpu utilization, disk IO, network IO, etc. In this case we can have one or many data messages from the computer system itself.
 
 * A computer system + other utilities: we can connect to a computer system a weather station, or any other type of monitoring system. In this case we can have one or many types of data messages from all sensors connected to that host.
 
 * A dedicated weather station: a standalone weather station, capable of being on a TCP/IP network which can send or or many data messages without a need for a computer system.
 
It is important to understand that we process data based on a host, linked to a TCP/IP newtork. A host can have one or many types of data messages, all messages being described and defined under LMO.


## Industries
We plan to support and record data from different types of industries. For some we have already developed data recorderds, like IT, Meteorology and we need help to enhance it. Each data recorder describe a message which can be found under the [LMO](https://github.com/kronometrix/lmo). 

 * Business Analytics (BA)
 * Climatology
 * Environmental Monitoring
 * Finance
 * Healthcare
 * Information Technology (IT)
 * Meteorology


### Information Technology

 * sysrec overall system CPU, MEM, DISK, NIC utilization
 * cpurec per-CPU statistics
 * nicrec per-NIC statistics
 * diskrec per-DISK statistics
 * hdwrec hardware, software inventory 


### Meteorology / Climatology

 * wsrec: WH1080, WH1081, WH1090, WH20xx
 * vwsrec: Vaisala Weather Station recorder
  
