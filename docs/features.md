<img src="/docs/img/k-logo.png" align="left" height="35" width="275" />
<img src="/docs/img/KDR.gif" align="right" height="75" width="75" />
<br/><br/>
<br/>

## Main Features


### Deployment

|| Kronometrix | Nagios Xi | Datadog | Paessler | Dynatrace | Description |
|------:|:------:|:------:|:------:|:------:|:------:|:------:| 
| SaaS | **yes** |  | **yes** | | **yes** | Run it as a service, over Internet |
| On-premises | **yes** | **yes** | no | **yes** | no | Run it as a product on your private network |  
| Edge/Fog Computing | **yes** | no | no | no | no | Run it on RaspberryPI or ARMv8 <a href="https://en.wikipedia.org/wiki/Single-board_computer">SBC</a> |


### Data Recording

|| Kronometrix | Nagios Xi | Datadog | Paessler | Dynatrace | Description |
|------:|:------:|:------:|:------:|:------:|:------:|:------:| 
| Built-in recorders | **yes** | no | **yes** | | **yes** | Own or 3rd party recorders. Datadog uses StatsD. Dynatrace uses native binaries and Java Compuware agent for Linux, Windows |
| Raw data | **yes** | **yes** | no | **yes** | no | DataDog Agent7 takes 750MB disk space, no original raw data available  |  
| Low latency | **yes** | no | no | no | no | Datadog aggregates all collected data, using different summary statistics functions. This means no possibility to retrieve the original raw data, higher consumption of system CPU resources (it needs to calculate all sort of aggregate functions). Kronometrix data recorders will not aggregate raw datadata, to always offer access to the original raw data, being very efficient, with a low memory and CPU footprint |
| Observability and Troubleshooting | **yes** | | | | no | Kronometrix data recorders can be used interactively for observability, troubleshooting and debug operations or continously for performance analysis and capapcity planning |
| Performance Analysis | **yes** | | | | | Designed for performance analysis and capacity planning & management |
| Coordinated Universal Time  (UTC) | **yes** | | | | | Kronometrix Data Recording uses UTC by default making easy and simple to share data  |
| Data Ontology | **yes** | no| no | no | no | Kronometrix Data Recording has groupped and classified all recorded metrics, for a very efficient data analysis process |
| Operating System | **yes** | **yes** | **yes** | **yes** | **yes** | |
| Platform Virtualization | **yes** | **yes** | **yes** | **yes** | **yes** | |
| OS Virtualization | yes | yes | **yes** | **yes** | **yes** | Kronometrix Data Recording supports Linux containers, FreeBSD jails, Solaris zones and Docker |
| Kubernets | no | no | **yes** | | | Kronometrix roadmap 2022 |
| Network equipment (SNMP) | beta | **yes** | **yes** | **yes** | **yes** | Kronometrix improvements Q4 2021 |
| Application Monitoring | yes | **yes** | **yes** | **yes** | **yes** | Kronometrix improvements Q4 2021 J2EE, DB monitoring |
| Internet Enterprise Services | **yes** | **yes** | **yes** | **yes** | **yes** | |
| X.509 Security Certificates | **yes** | no | no | no | | |
| Serial Command Communication | **yes** | no | no | no | no | Can connect to manage and control serial devices |
| RS232/485 | **yes** | | no | no | no | Serial RS232/RS485 support |
| MODBUS | **yes** | | no | no | no | MODBUS RTU, ASCII, TCP support |
| MQTT | beta | no | no | no | no | MQTT 3/5 support. Kronometrix improvements Q4 2021 |
| Bluetooth Low Energy | comming soon | | | | | Kronometrix roadmap 2022 |
| BACnet | Beta | no | no | no | no | Kronometrix roadmap 2022 |
| Healthcare | comming soon | no | no | no | no | Kronometrix roadmap 2023 |
| Open Source | **yes** | **yes** | **yes** | | | Datadog uses StatsD. Dynatrace uses Compuware Java agent |
| ARM compatible | **yes** | | | | **yes** | |
| Based on | Perl5/Lua | C/Perl/Shell | Python3 | C | C/Java | |

Read more about Kronometrix Data Recording [features](https://www.kronometrix.com/fabric/recorders/) 
<br/>
Go back [main page](https://gitlab.com/kronometrix/recording/)
