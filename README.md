<img src="/docs/img/KDR-Text.png" align="left" height="74" width="325" />
<img src="/docs/img/KDR.gif" align="right" height="75" width="75" />
<br/><br/>
<br/><br/>

[![Alt-Text](https://img.shields.io/static/v1.svg?label=ver&message=1.8.3&color=success)](docs/start.md)
[![](https://img.shields.io/static/v1.svg?label=license&message=GPL2&color=blue)](LICENSE)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1855/badge)](https://bestpractices.coreinfrastructure.org/projects/1855)

# Overview

A simple and efficient set of data recorders and transport utilities for multi-industry: ICT, weather and environment, industrial IoT and preventive healthcare, designed to record top essential performance metrics, save raw data and send it for further analysis.

* [Design](docs/design.md)
* [Features](docs/features.md)
* [Getting started](docs/start.md)
* [Contributing and support](docs/contributing.md)

# Requirements

* Processor: Intel/AMD x64, Apple M1, ARMv8
* Memory: 32 MB RAM
* Disk space: 140MB, Raw data: 500-750KB per day / data source
* Protocols: HTTP(S), SERIAL COMMUNICATION, MODBUS(RTU,TCP,ASCII), MQTT, BLE, BACnet
* SBC: Raspberry PI 3B, 3B+

# Features

* Support for raw data
* Industrial IoT readiness
* Conservative in CPU and memory usage on different architectures 
* Easy to change or add new data recorders to collect new data 
* Runs without human intervention, easy to detect data transmission problems
* Fetch data from any system, device, sensor with support for different industries
* Full control with no complicated licenses for further development
* [See more](docs/features.md)

# Supported Systems

* CentOS 7.9 x86_64
* RHEL 8 x86_64
* Debian 9.13 amd64
* CloudLinux 7 x86_64
* Ubuntu Server Edition 18 amd64
* SLES 15 x86_64
* OpenSuse Leap 15 x86_64
* Raspbian GNU/Linux 8+ armv8
* Solaris 11 (Ask support)
* FreeBSD
* MacOS (Q4 2021)
* Windows 7
* Windows 8
* Windows 10
* Windows 11 (TBD)
* Windows 2008 R2 Server x64
* Windows 2012 R2 Server x64
* Windows 2016 R2 Server x64

# Supported Industries

## Information and Communications Technology

 * sysrec - Overall system performance data recorder
 * cpurec - Per CPU statistics data recorder
 * nicrec - Per NIC statistics data recorder
 * diskrec - Per disk statistics data recorder
 * hdwrec - System inventory data recorder
 * faultrec - Fault Management data recorder **(Q1 2022)**
 * jvmrec - Java VM statistics data recorder
 * snmprec - Ethernet and SAN Switch, SNMP data recorder **(Q4 2021)**
 * netrec - TCP, UDP data recorder
 * httprec - HTTP server statistics: NGINX, Apache, Tomcat, PHP-FPM
 * dbrec - Database data recorder: MariaDB, MySQL, PostgreSQL **(Q1 2022)**
 * certrec - X.509 security certificate statistics data recorder
 * direc - Filesystem directory statistics data recorder
 * ntprec - NTP server statistics data recorder
 * smtprec - SMTP server data recorder **(Q1 2022)**
 * imaprec - IMAP/POP server data recorder **(Q1 2022)**
 * sockrec - Network IO Socket data recorder **(Q4 2021)**
 * svcrec - Service performance,availability: IMAP,SMTP,POP3,LDAP,DNS,TCP,Any
 * procrec - Process statistics data recorder
 * webrec - Web application performance,availability data recorder
 * wprec - Wordpress security, performance and availability data recorder **(Q1 2022)**

## Public Cloud Providers

 * awsrec - Amazon Web Services data recorder **(2022)**
 * azurec - Microsoft Azure data recorder **(2022)**
 * gcprec - Google Computing Platform data recorder **(2022)**

## Industrial IoT, Weather and Environment

 * axisrec - AXIS security and video surveillance data recorder
 * bacrec - Building management BACnet data recorder **(Q2 2022)**
 * blrec - Bluetooth Low Energy data recorder **(Q1 2021)**
 * rs485rec - Industrial RS-232, RS-485, MODBUS data recorder 
 * wsrec - General weather station recorder RS-232/USB

## Epidemiology and Preventive Healthcare  

 * epidmrec - Epidemiology data recorder **(2022)**

# Commercial products

[Kronometrix Industrial IoT Gateway](https://www.kronometrix.com/products/iotgateway/)

# Resources

[www.kronometrix.com][1] | [@KronometrixHelp][2] | [www.facebook.com/kronometrix][3]


[1]: https://www.kronometrix.com/
[2]: https://twitter.com/KronometrixDDF
[3]: https://www.facebook.com/kronometrix
