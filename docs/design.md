<img src="/docs/img/KDR-Text.png" align="left" height="74" width="325" />
<img src="/docs/img/KDR.png" align="right" height="100" width="100" />
<br/><br/>
<br/><br/>

[![Alt-Text](https://img.shields.io/static/v1.svg?label=ver&message=1.8.3&color=success)](docs/start.md)
[![](https://img.shields.io/static/v1.svg?label=license&message=GPL2&color=blue)](LICENSE)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1855/badge)](https://bestpractices.coreinfrastructure.org/projects/1855)

# Design

To really understand how your world and business works, you need to have data. The right kind of data. And for that, you need to be able to capture the correct performance metrics from your systems, devices or applications in real-time, to store and transport it for further analysis, if required. And for that we have developed data recorders.

## The recorder

A data recorder, is a simple software probe, designed to connect and fetch data from one or many data sources, like: a computer systems, some web and enterprise applications, weather and environment sensors, or different IoT equipment, using different communication protocols, like HTTP or SNMP, MODBUS. A data recorder requires a runtime engine to operate and execute, like Perl5 or Lua, for example. There can be more than one data recorder, designed for different activities, like fetching performance data from a storage system, an online web application, or an industrial IoT sensor or device.


## How does it work?

<img src="/docs/img/KDR_Arch.png" align="right" />

The data recorders work independently one of each other, having their own execution path and state. They do not interfere with other data recorders input and output execution.  

The recorder can operate in two modes:

  * interactive: you can manually run the recorder, using command line interface to start or stop the recorder
  
  * automatic mode: you can continuously record data, without any manual interaction, for long periods of time

## Raw Data

All recorded observations are stored as raw data. Raw data is produced by a _recorder_, which fetches data from a system, device or sensor, data which has not been modified, altered or changed in any way. All collected metrics are variable measured sequentially in time, called _time series_. All these observations collected over fixed sampling intervals create a _historical time series_. To easy the access to all this set of data we store the observations 
on commodity disk drives, compressed, in text format, like CSV format.

_Time series let us understand what has happened in past and look in the future, using various statistical models_


## Data Message
All collected metrics over time are combined as a data message. There can be many types of 
data messages: metrics regarding computer system utilization cpu or memory utilization, or weather data 
from a meteorological station, or water cubic meters per hour from an water pump. A data message is in 
direct relation to a data source. All these data messages are part of, [the data neurons repository](https://gitlab.com/kronometrix/dataneurons).


## Data Source
A data source, is described as any system connected to a public or private network with a valid IPv4 or IPv6 address. 
Example: a server, a logger, a graphic workstation, an iPad or an IoT sensor capable to send and receive data. 
There can be many types of data sources, each having one or many of data messages:

 * Computer system: overall cpu utilization, disk and network IO, per device metrics (Linux, FreeBSD, Windows)
 
 * HTTP server: throughput and utilization along with its inventory data (Nginx, Apache, Tomcat)
 
 * Enterprise service: response time performance and availability (SMTPS, IMAP, HTTP, LDAP, NTP, AD)
 
 * Automatic weather station: air temperature and pressure, humidity, wind speed and direction 

## Recorders vs Others

<img src="/docs/img/RecorderVsAgent.png" />

<img src="/docs/img/recorderplus.png" align="right" /> 

<img src="/docs/img/recorder.png" align="right" /> 


Go back [main page](https://gitlab.com/kronometrix/recording/)
