<img src="https://github.com/kronometrix/recording/blob/master/k-logo.png" align="left" height="35" width="275" />
<br/><br/>

## Description

A simple and efficient set of data recorders and transport utilities for ICT, Environmental Monitoring, Meteorology and IoT industries, responsible to record top essential performance metrics, save raw data and transport it for further analysis. 

### Time Series
All recorded observations we call them raw data. Raw data is produced by a monitoring agent, part of a data source.  This set of data is not modified, altered or changed in any way. All collected metrics are variable measured sequentially in time, called time series. All these observations collected over fixed sampling intervals create a historical time series. To easy the access to all this set of data we simple store the observations on commodity disk drives, compressed, in text format.

Time series let us understand what has happened in past and look in the future, using various statistical models. In addition , having access to these historical time series will help us to build a simple capacity planning model.


### Data Message
All collected metrics over time make a data message. There can be many types of data messages: metrics regarding computer system utilization cpu or memory utilization, or weather data from a meteorological station, or water cubic meters per hour from an water pump. A data message belongs to a data source. All these metrics, observations are ultimately the data message. To describe such messages we built a library of monitoring objects documented here: [library of monitoring objects](https://github.com/sparvu/lmo)


### Data Source
A data source, is described as any system connected to a public or private network with a valid IPv4 or IPv6 address like, a server, a data logger, a graphic workstation, an iPad or an IoT sensor capable to send data. there can be many types of data sources, each with a number of data messages:

 * a computer system, with one or many data messages: overall cpu utilization, disk IO, network IO, or per device metrics 
 
 * a HTTP server, describing performance metrics, like throughput and utilization along with its inventory data
 
 * an website, keeping track of the performance response time and availability
 
 * an automatic weather station, capable to send data over a TCP/IP network without an additional computer system attached
 
 * an intelligent IoT sensor
 

### Supported Industries

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


#### Environmental Monitoring, IoT

 * rs485rec - RS485 MODBUS RTU recorder. Currently supporting Vaisala GMW90, Tongdy G01, Tongdy MSD IAQ  


#### General Meteorology

 * wsrec - Weather data recorder. Currently supporting> WH1080, WH1081, WH1090, WH20xx family of devices
  

## Get started

You can install Kronometrix data recording on several operating systems, 32 and 64bit manually or to easy the installation and deployment we recommend you to open your free account under http://kronometrix.io/register and create your data subscriptions which offers automatic data provisoning guidance. 

### Linux/UNIX

#### RPM based systems

  * Download package http://www.kronometrix.org/pkgs/linux/kdr-stable-rhel-x64.rpm
  * Install package ```# rpm -ihv kdr-stable-rhel-x64.rpm``` 
  
#### DEB based systems

  * Download package http://www.kronometrix.org/pkgs/linux/kdr-stable-debian-x64.deb
  * Install package ```# dpkg -i kdr-stable-debian-x64.deb``` 

#### FreeBSD systems

  * Download package http://www.kronometrix.org/pkgs/freebsd/kdr-stable-freebsd-x64.txz
  * Install package ```# pkg install kdr-stable-freebsd-x64.txz``` 

 
### Windows

#### Windows 2008, 2012, 2016 systems

  * Download package http://www.kronometrix.org/pkgs/win/kdr-stable-windows-x64.exe
  * Execute kdr-stable-windows-x64.exe


## Support

If you need help regarding Kronometrix data recording, we are offering commercial support. Please contact us +358 50 483 9978 or email us at: sales@kronometrix.com
  
