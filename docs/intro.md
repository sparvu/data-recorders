<img src="https://github.com/kronometrix/recording/blob/master/docs/img/k-logo.png" align="left" height="35" width="275" />
<br/>

## Raw Data
All recorded observations are stored as raw data. Raw data is produced by a _recorder_, which fetches data from a 
system, device or sensor, data which has not been modified, altered or changed in any way. All collected metrics 
are variable measured sequentially in time, called _time series_. All these observations collected over fixed sampling 
intervals create a _historical time series_. To easy the access to all this set of data we simple store the observations 
on commodity disk drives, compressed, in text format, like CSV format.

_Time series let us understand what has happened in past and look in the future, using various statistical models_


## Data Message
All collected metrics over time are combined as a data message. There can be many types of data messages: metrics regarding computer system utilization cpu or memory utilization, or weather data from a meteorological station, or water cubic meters per hour from an water pump. A data message is in direct relation to a data source. To describe one or many data messages, we have built a library of monitoring objects, (LMO) documented here: [library of monitoring objects](https://github.com/sparvu/lmo)


## Data Source
A data source, is described as any system connected to a public or private network with a valid IPv4 or IPv6 address like, a server, a data logger, a graphic workstation, an iPad or an IoT sensor capable to send and receive data. There can be many types of data sources, each having one or many of data messages:

 * Computer system: overall cpu utilization, disk and network IO, per device metrics (Linux, FreeBSD, Windows)
 
 * HTTP server: throughput and utilization along with its inventory data (Nginx, Apache, Tomcat)
 
 * Enterprise service: response time performance and availability (SMTPS, IMAP, HTTP, LDAP, NTP, AD)
 
 * Automatic weather station: air temperature and pressure, humidity, wind speed and direction 


## The recorder
A light probe developed in _Perl5_ language which can extract data from different libraries or sources, like 
an operating system interfaces, a sensor or device, an industrial equipment using _MODBUS_ protocol, or an
web based application or database.

The recorder can operate in two modes:

  * interactive: you can manually run the recorders using different samping rate values to analyse raw data
  
  * automatic: you can continuously record data, using a default sampling rate of _60 seconds_ 

<img src="https://github.com/kronometrix/recording/blob/master/docs/img/recorderplus.png" align="right" /> 
<img src="https://github.com/kronometrix/recording/blob/master/docs/img/recorder.png" align="right" /> 

