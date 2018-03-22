<img src="https://github.com/kronometrix/recording/blob/master/img/k-logo.png" align="left" height="35" width="275" />
<br/>

# Description

A simple and efficient set of data recorders and transport utilities for ICT, Environmental Monitoring, Meteorology and IoT , designed to record top essential performance metrics, save raw data and send it for further analysis. 

## Raw Data
All recorded observations are stored as raw data. Raw data is produced by a recorder, which fetches data from a system or a sensor, data which is original and has not been modified, altered or changed in any way. All collected metrics are variable measured sequentially in time, called time series. All these observations collected over fixed sampling intervals create a historical time series. To easy the access to all this set of data we simple store the observations on commodity disk drives, compressed, in text format, like CSV format.

Time series let us understand what has happened in past and look in the future, using various statistical models.


## Data Message
All collected metrics over time are combined as a data message. There can be many types of data messages: metrics regarding computer system utilization cpu or memory utilization, or weather data from a meteorological station, or water cubic meters per hour from an water pump. A data message is in direct relation to a data source. To describe one or many data messages, we have built a library of monitoring objects, (LMO) documented here: [library of monitoring objects](https://github.com/sparvu/lmo)


## Data Source
A data source, is described as any system connected to a public or private network with a valid IPv4 or IPv6 address like, a server, a data logger, a graphic workstation, an iPad or an IoT sensor capable to send and receive data. There can be many types of data sources, each having one or many of data messages:

 * Computer system: overall cpu utilization, disk IO, network IO, or per device metrics (Linux, FreeBSD)
 
 * HTTP server: throughput and utilization along with its inventory data (Nginx, Apache)
 
 * Enterprise service: response time performance and its availability (SMTPS, IMAP, HTTP, LDAP)
 
 * Automatic weather station: air temperature and pressure, humidity, wind speed and direction 
 

## Supported Industries

### Information and Communications Technology

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


### Environmental Monitoring, IoT

 * rs485rec - RS485 MODBUS ASCII, MODBUS RTU, MODBUS TCP recorder
 

### General Meteorology

 * wsrec - Weather data recorder. Currently supporting: WH1080, WH1081, WH1090, WH20xx family of devices
  

# Get started

You can manually install Kronometrix data recording on several operating systems, or you can open your free account,  http://kronometrix.io/register to automatically provision and visualize your data. 

## Linux

### RPM based systems

  * Download packages 
    * Intel/AMD 64bit: http://www.kronometrix.org/pkgs/linux/kdr-stable-rhel-x64.rpm
    * Intel/AMD 32bit: http://www.kronometrix.org/pkgs/linux/kdr-stable-rhel-x86.rpm
        
  * Install package ```# rpm -ihv kdr-stable-rhel-x64.rpm``` 
  
### DEB based systems

  * Download packages
    * Intel/AMD 64bit: http://www.kronometrix.org/pkgs/linux/kdr-stable-debian-x64.deb
    * Intel/AMD 32bit: http://www.kronometrix.org/pkgs/linux/kdr-stable-debian-x86.deb
    * ARM 32bit: http://www.kronometrix.org/pkgs/linux/kdr-stable-raspbian-arm.deb
    
* Install package ```# dpkg -i kdr-stable-debian-x64.deb``` 

## UNIX

### FreeBSD systems

  * Download packages
    * Intel/AMD 64bit: http://www.kronometrix.org/pkgs/freebsd/kdr-stable-freebsd-x64.txz
    * Intel/AMD 32bit: http://www.kronometrix.org/pkgs/freebsd/kdr-stable-freebsd-x86.txz
    * ARM 32bit: http://www.kronometrix.org/pkgs/freebsd/kdr-stable-freebsd-arm.txz
    
  * Install package ```# pkg install kdr-stable-freebsd-x64.txz``` 

## Windows

### Windows 2008, 2012, 2016 systems

  * Download package
    * Intel/AMD 64bit: http://www.kronometrix.org/pkgs/win/kdr-stable-windows-x64.exe

* Execute kdr-stable-windows-x64.exe


# Support

If you need help regarding Kronometrix data recording, we are offering commercial support. Please contact us +358 50 483 9978 or email us at: sales@kronometrix.com
  
