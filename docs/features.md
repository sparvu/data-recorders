<img src="/docs/img/k-logo.png" align="left" height="35" width="275" />
<img src="/docs/img/perl_logo.png" align="right" height="100" width="100" />
<br/><br/>
<br/>

## Main Features


### Deployment

|| Kronometrix | Nagios Xi | Datadog | Paessler | Dynatrace | Description |
|------:|:------:|:------:|:------:|:------:|:------:|:------:| 
| SaaS | **yes** |  | **yes** | | **yes** | Run it as a service, over Internet |
| On-premises | **yes** | **yes** | no | **yes** | no | Run it as a product on your private network |  
| Edge/Fog Computing | **yes** | | | |  | Run it on RaspberryPI or ARMv8 <a href="https://en.wikipedia.org/wiki/Single-board_computer">SBC</a> |


### Data Recording

|| Kronometrix | Nagios Xi | Datadog | Paessler | Dynatrace | Description |
|------:|:------:|:------:|:------:|:------:|:------:|:------:| 
| Built-in recorders | **yes** |  | **yes** | | **yes** | Own or 3rd party recorders. Datadog uses StatsD. Dynatrace uses native binaries and Java Compuware agent for Linux, Windows, AIX |
| Raw data | **yes** | **yes** | no | **yes** | no | Agent 7 750MB disk space  needed. No raw data. Datadog aggregates raw data every 10 seconds |  
| Low latency | **yes** | | | | | Kronometrix recorders have a low memory and CPU footprint, designed  to monitor individual system resources, offered as a open-source software based on Perl 5 for easy customisatio |
| Observability and Troubleshooting | **yes** | | | | | Designed to be used interactive and continuous mode |
| Serial Command Communication | **yes** | | | | | Manage & control serial attached sensors and devices |
| Performance Analysis | **yes** | | | | | Designed for performance analysis and capacity management |
| Coordinated Universal Time  (UTC) | **yes** | | | | | Kronometrix Data Recording uses UTC by default making easy and simple to share data  |
| Operating System | **yes** | **yes** | **yes** | **yes** | **yes** | |
| Network equipment (SNMP) | yes | **yes** | **yes** | **yes** | **yes** | Kronometrix improvements Q2 2021 |
| Application Monitoring | yes | **yes** | **yes** | **yes** | **yes** | Kronometrix improvements Q2 2021 J2EE, DB monitoring |
| Internet Enterprise Services | **yes** | **yes** | **yes** | **yes** | **yes** | |
| X.509 Security Certificates | **yes** | | | | | |
| RS232/485 | **yes** | | | | | Serial RS232/RS485 support |
| MODBUS | **yes** | | | | | MODBUS RTU, ASCII, TCP support |
| Bluetooth Low Energy | coming soon | | | | | Kronometrix roadmap 2021 |
| BACnet | coming soon | | | | | Kronometrix roadmap 2021 |
| Epidemiology | coming soon | | | | | Kronometrix roadmap 2021 |
| Open Source | **yes** | **yes** | **yes** | | | Datadog uses StatsD. Dynatrace uses Compuware Java agent |
| ARM compatible | **yes** | | | | **yes** | |
| Based on | Perl5 | C/Perl/Shell | Python | C | C/Java | |

Go back [main page](https://gitlab.com/kronometrix/recording/)
