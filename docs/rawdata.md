<img src="/docs/img/KDR-Text.png" align="left" height="74" width="325" />
<img src="/docs/img/KDR.png" align="right" height="100" width="100" />
<br/><br/>
<br/><br/>

[![Alt-Text](https://img.shields.io/static/v1.svg?label=ver&message=1.8.3&color=success)](docs/start.md)
[![](https://img.shields.io/static/v1.svg?label=license&message=GPL2&color=blue)](LICENSE)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1855/badge)](https://bestpractices.coreinfrastructure.org/projects/1855)

# Raw Data

All recorded observations are stored as raw data. Raw data is produced by a recorder, which fetches data from a system, device or sensor, data which has not been modified, altered or changed in any way. All collected metrics are variable measured sequentially in time, called time series. All these observations collected over fixed sampling intervals create a historical time series. To easy the access to all this set of data we store the observations
on commodity disk drives, compressed, in text format, like CSV format. 

_Time series let us understand what has happened in past and look in the future, using various statistical models_

# Data Message

All collected metrics over time are combined as a data message. There can be many types of data messages: metrics regarding computer system utilization cpu or memory utilization, or weather data from a meteorological station, or water cubic meters per hour from an water pump. A data message is in direct relation to a data source. All these data messages are part of, the data neurons repository.

# Data Source

A data source, is described as any system connected to a public or private network with a valid IPv4 or IPv6 address. Example: a server, a logger, a graphic workstation, an iPad or an IoT sensor capable to send and receive data. There can be many types of data sources, each having one or many of data messages:

* Computer system: overall cpu utilization, disk and network IO, per device metrics (Linux, FreeBSD, Windows)

* HTTP server: throughput and utilization along with its inventory data (Nginx, Apache, Tomcat)

* Enterprise service: response time performance and availability (SMTPS, IMAP, HTTP, LDAP, NTP, AD)

* Automatic weather station: air temperature and pressure, humidity, wind speed and direction


Go back [main page](https://gitlab.com/kronometrix/recording/)
