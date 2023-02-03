<img src="/docs/img/data-recorders-title8.png" />

[![Alt-Text](https://img.shields.io/static/v1.svg?label=ver&message=2.0&color=success)](docs/start.md)
[![](https://img.shields.io/static/v1.svg?label=license&message=GPL2&color=blue)](LICENSE)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1855/badge)](https://bestpractices.coreinfrastructure.org/projects/1855)

# Overview

A set of [CLI](https://en.wikipedia.org/wiki/Command-line_interface) utilities designed to record top essential performance metrics, save original raw data  for visualization and analysis. Supports different industries: ICT enterprise, weather and environment.

<!--- <div align="center">
<img src="/docs/img/DR2.png" height="80%" width="80%" />
</div> --->

* [Design](docs/design.md)
* [Features](docs/features.md)
* [Why use data recorders?](docs/why.md)
* [Download](docs/download.md)

# Requirements

* Processor: Intel/AMD x64, ARMv8
* Memory: 32 MB RAM
* Disk space: 64MB, Raw data: 500-750KB per day / data source
* Protocols: SERIAL COMMUNICATION, SNMP, MODBUS(RTU,TCP,ASCII), MQTT, HTTP, BLE, BACnet
* SBC: Raspberry PI 3B+, 4B

# Features

* Resource utilization
* Throughput performance metrics
* Response time performance metrics
* Operational availability
* Power consumption
* Support for raw data
* Data classification and grouping
* Industrial IoT readiness
* Conservative in CPU and memory usage on different architectures 
* Easy to configure and add new metrics to capture new data 
* Runs without human intervention, easy to detect data transmission problems
* Full control with no complicated licenses for further development
* [See more](docs/features.md)

# Supported Systems

* FreeBSD 12,13
* CentOS 7.9 x86_64
* RHEL 8 x86_64
* Debian 9,10,11 amd64
* CloudLinux 7 x86_64
* Ubuntu Server Edition 18 amd64
* SLES 15 x86_64
* OpenSuse Leap 15 x86_64
* Raspbian GNU/Linux 8+ armv8
* MacOS (2023)
* Windows 7
* Windows 8
* Windows 10
* Windows 11 (TBD)
* Windows 2008 R2 Server x64
* Windows 2012 R2 Server x64
* Windows 2016 R2 Server x64

# Industries

## Information and Communications Technology

 * sysrec - Overall system performance data recorder
 * cpurec - Per CPU statistics data recorder
 * nicrec - Per NIC statistics data recorder
 * diskrec - Per disk statistics data recorder
 * hdwrec - System inventory data recorder
 * faultrec - Fault Management data recorder **(2023)**
 * dockrec - Docker Performance data recorder **(2023)**
 * jvmrec - Java VM statistics data recorder
 * snmprec - SNMP equipment data recorder
 * netrec - TCP, UDP data recorder
 * httprec - HTTP server statistics: NGINX, Apache, Tomcat, PHP-FPM
 * dbrec - Database data recorder: MariaDB, MySQL, PostgreSQL **(2023)**
 * certrec - X.509 security certificate statistics data recorder
 * direc - Filesystem directory statistics data recorder
 * ntprec - NTP server statistics data recorder
 * smtprec - SMTP server data recorder **(2024)**
 * imaprec - IMAP/POP server data recorder **(2024)**
 * svcrec - Service performance,availability: IMAP,SMTP,POP3,LDAP,DNS,TCP,Any
 * procrec - Process statistics data recorder
 * webrec - Web application performance,availability data recorder
 * wprec - Wordpress security, performance and availability data recorder **(2023)**

## Industrial IoT, Weather and Environment

 * axisrec - AXIS security and video surveillance data recorder
 * bacrec - Building management BACnet data recorder **(2024)**
 * blrec - Bluetooth Low Energy data recorder **(2024)**
 * rs485rec - Industrial RS-232, RS-485, MODBUS data recorder 
 * sockrec - Network IO Socket data recorder
 * wsrec - General weather station recorder RS-232/USB
