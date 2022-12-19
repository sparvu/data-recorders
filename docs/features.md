<img src="/docs/img/data-recorders-features_5.png" />


|| Data Recorders | NagiosXi | Datadog | Paessler | Dynatrace  | Description |
|------:|:------:|:------:|:------:|:------:|:------:|:------:| 
| Type | recorder | agent | agent | agent | agent | | Own or 3rd party data recorders or agents. Datadog uses StatsD. Dynatrace uses native binaries and Java Compuware agent for Linux, Windows |
| Raw data | yes | yes | no | yes | no | DataDog Agent7 takes 750MB disk space, no original raw data available  |
| Time-series Data | yes | no | no | no | no | Data organised as time series |
| Data Ontology | yes | no| no | no | no | Data Recorders has groupped and classified all recorded metrics, for a very efficient data analysis process |
| Low latency | yes | no |  no | no | no | Datadog aggregates all collected data, using different summary statistics functions. This means no possibility to retrieve the original raw data, higher consumption of system CPU resources (it needs to calculate all sort of aggregate functions). Kronometrix data recorders will not aggregate raw datadata, to always offer access to the original raw data, being very efficient, with a low memory and CPU footprint |
| Rapid Prototyping | yes | no | no | no | no | Easy to build a new data recorder to collect data from a new data source |
| Performance Analysis | yes | yes | yes | yes | yes | Designed for performance analysis and capacity planning & management |
| Coordinated Universal Time  (UTC) | yes | | | | | Data Recorders uses UTC by default |
| Operating System | yes | yes | yes | yes | yes |
| Platform Virtualization | yes | yes | yes | yes | yes |
| OS Virtualization | yes | yes | yes | yes | |
| Docker | no | yes | no | yes | yes | 2023 |
| Kubernets | no | yes | no | yes | | 2023 |
| Network equipment (SNMP) | yes | yes | yes | yes | yes | |
| Application Monitoring | partial | yes | yes | yes | yes | 2023 |
| Internet Enterprise Services | yes | yes | yes | yes | yes | |
| X.509 Security Certificates | yes | yes | no | no | no | |
| AWS EC2 API | no | yes | yes | yes* | yes | Capabilities to fetch AWS specific performance metrics. *Paessler uses CloudWatch AWS to fetch the performance metrics. |
| GCP API | no | yes | yes | yes | yes | Capabilities to fetch GCP specific performance metrics |
| Azure API | no | yes | yes | yes | yes | Capabilities to fetch Azure specific performance metrics |
| Serial Command Communication | yes | yes | no | no | no | Can connect to manage and control serial devices |
| RS232/485 | yes | | no | no | no | Serial RS232/RS485 support |
| MODBUS | yes | no | | no | no | MODBUS RTU, ASCII, TCP support |
| MQTT | 2023 | no | no | no | no | 2024 |
| Bluetooth Low Energy | 2023 | no | no | no | no | 2024 |
| BACnet | 2024 | no | no | no | no | 2024 |
| Open Source | yes | yes | yes | | yes | Datadog uses StatsD. Dynatrace uses Compuware Java agent |
| ARM compatible | yes | yes | | | yes | |
| Public API | yes | yes | no |  | yes |  |
| Based on | Perl/C | C/Python/Php | Python3 | C | C/Java |


Go back [main page](https://github.com/sparvu/data-recorders)

