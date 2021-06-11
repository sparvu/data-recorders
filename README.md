<img src="/docs/img/k-logo.png" align="left" height="35" width="270" />
<img src="/docs/img/KDR.gif" align="right" height="75" width="75" />
<br/><br/>
<br/>

[![Alt-Text](https://img.shields.io/static/v1.svg?label=ver&message=1.8.3&color=success)](docs/start.md)
[![](https://img.shields.io/static/v1.svg?label=license&message=GPL2&color=blue)](LICENSE)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1855/badge)](https://bestpractices.coreinfrastructure.org/projects/1855)

# Overview

A simple and efficient set of data recorders and transport utilities for multi-industry: ICT, weather and environment, industrial IoT and preventive healthcare, designed to record top essential performance metrics, save raw data and send it for further analysis.

* [Design](docs/design.md)
* [Main Features](docs/features.md)
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

# Supported Industries

## Information and Communications Technology

 * sysrec - Overall system performance data recorder
 * cpurec - Per CPU statistics data recorder
 * nicrec - Per NIC statistics data recorder
 * diskrec - Per disk statistics data recorder
 * hdwrec - System inventory data recorder
 * faultrec - Fault Management data recorder
 * jvmrec - Java VM statistics data recorder
 * snmprec - Ethernet and SAN Switch, SNMP data recorder
 * netrec - TCP, UDP data recorder
 * httprec - HTTP server statistics: NGINX, Apache, Tomcat, PHP-FPM
 * dbrec - database data recorder: MariaDB, MySQL, PostgreSQL
 * certrec - X.509 security certificate statistics data recorder
 * svcrec - service performance,availability: IMAP,SMTP,POP3,LDAP,DNS,TCP(Any)
 * direc - filesystem directory statistics data recorder
 * ntprec - NTP server statistics data recorder
 * smtprec - SMTP server data recorder
 * imaprec - IMAP/POP server data recorder
 * procrec - process statistics data recorder
 * webrec - web application performance,availability data recorder
 * wprec - Wordpress security, performance and availability data recorder

## Public Cloud Providers

 * awsrec - Amazon Web Services data recorder
 * azurec - Microsoft Azure data recorder
 * gcprec - Google Computing Platform data recorder

## Industrial IoT, Weather and Environment

 * axisrec - AXIS security and video surveillance data recorder
 * bacrec - Building management BACnet data recorder
 * blrec - Bluetooth Low Energy data recorder
 * rs485rec - Industrial RS-232, RS-485, MODBUS data recorder 
 * wsrec - General weather station recorder RS-232/USB

## Epidemiology and Preventive Healthcare  

 * epidmrec - Epidemiology data recorder

# Commercial products

[Kronometrix K<sub>1</sub> Industrial IoT Gateway](https://www.kronometrix.com/k1)

# Resources

[www.kronometrix.com][1] | [@KronometrixHelp][2] | [www.facebook.com/kronometrix][3]


[1]: https://www.kronometrix.com/
[2]: https://twitter.com/KronometrixHelp
[3]: https://www.facebook.com/kronometrix
