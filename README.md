<img src="https://github.com/kronometrix/recording/blob/master/docs/img/k-logo.png" align="left" height="35" width="275" />
<img src="https://github.com/kronometrix/recording/blob/master/docs/img/perl_logo.png" align="right" />
<br/>

[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1855/badge)](https://bestpractices.coreinfrastructure.org/projects/1855)

## Overview

A simple and efficient set of data recorders and transport utilities for ICT, 
environmental monitoring, meteorology and IoT, designed to record top essential 
performance metrics, save raw data and send it for further analysis.

* [Design](docs/design.md)
* [Getting Started](docs/start.md)
* [Contributing](docs/contributing.md)

## Features

* Support for raw data
* IoT readiness
* Conservative in CPU and memory usage on different architectures 
* Easy to change or add new data recorders to collect new data 
* Runs without human intervention, easy to detect data transmission problems
* Fetch data from any system, device, sensor with support for multi-industry
* Full control with no complicated licenses for further developments 

## Supported Industries

### Information and Communications Technology

 * sysrec - overall system CPU, MEM, DISK, NIC utilization, throughput and errors
 * cpurec - per CPU statistics
 * nicrec - per NIC statistics
 * diskrec - per DISK statistics
 * hdwrec - hardware and software data inventory
 * jvmrec - Java VM statistics
 * httprec - the HTTP server statistics: NGINX, Apache, PFP-FPM
 * certrec - X.509 security certificate statistics
 * svcrec - service performance,availability: IMAP,SMTP,POP3,LDAP,DNS,TCP(Any)
 * direc - filesystem directory statistics
 * ntprec - NTP server statistics
 * procrec - process statistics
 * webrec - web application performance,availability

### Environmental Monitoring, IoT

 * rs485rec - Serial, MODBUS (ASCII, RTU, TCP) industrial recorder
 
### General Meteorology

 * wsrec - Weather data recorder. Currently supporting: WH1080, WH1081, WH1090, WH20xx family of devices

## Download 

You can can download our software [here](docs/start.md)

## Support

If you have any technical problems, questions or new ideas, please 
contact us by opening a [new change request](https://github.com/kronometrix/recording/issues). For any security vulnerabilities found please open a new
[change request](https://github.com/kronometrix/recording/issues) marking 
the subject as security vulnerability.

For any other questions or assistance we are offering commercial support. 
Please contact us +358 50 483 9978 or email us at: sales@kronometrix.com for
more information.
  
## Resources

| [kronometrix.io][1] | [@KronometrixHelp][2] | [www.facebook.com/kronometrix][3] |
| ----------------------- | ------------- | --------------------- |

[1]: https://kronometrix.io/
[2]: https://twitter.com/KronometrixHelp
[3]: https://www.facebook.com/kronometrix
