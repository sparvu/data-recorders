
<img src="/docs/img/recorders-design.png" />

To really understand how our world works, we need to have the **correct performance metrics** to analyze. But how could we know what metrics we really need from our systems or applications? Well, we could try to capture as much data as possible and later start mining whatever we need. As this sounds promising we will soon find out that storage and data extraction will be expensive. So what choices do we have?

In reality, we dont really need a lot of data. We will need the metrics which can help us to understand the behaviour and functionality of our systems or applications, related to:

* overall system or device utilization and saturation
* workload or system's throughput
* and the errors

This basic grouping can help us to get started and organize our metrics as Utilization, Saturation, Errors and Throughput. Of course we might need some other parameters in order to better describe and explain the functionality of our system(s). So, on top of these primary categories we might need to have aditional metrics which we can can enable or disable, if required. 


<img src="/docs/img/recorders-topgoals.png" />

Then we will need to capture, in real-time, these metrics, and save them, using a simple, uniform output format, no matter of the operating system or platform used. The output data, the original raw data collected, should be easy to access and share with anyone, if required. And last but not least, capturing these metrics should be done automatically, without human intervention, to help build large data sets for performance analysis and capacity planning or interactively, for quick troubleshooting.

To achieve all these goals, we are introducing the _data recorders_ . Designed as light command line utilities, these recorders can have capabilities to connect or wait for data from various sources and resolve the associated performance metrics in real-time. The data recorders can use one or many data communication protocols, for example like TCP or UDP, or something like MODBUS or BACNet. A data recorder can be installed on a computer system or an industrial equipment, more or less like a traditional agent based software, or can be deployed and operated over the network, without any local presence. There are fundamental differences between a data recorder and software agent, see later about these differences.

The very first data recorders were published during 2009, mainly to fetch and collect performance data from various computer systems running Solaris and Linux operating systems. After that, more recorders were developed to capture HTTP data from various web applications, and TCP/UDP service performance data from various enterprise services, like databases or middleware software. Same time, new recorders were created to connect to various industrial sensors and devices and fetch different data, using for example the MODBUS protocol.

There are two main versions describing the evolution and development of the data recorders:

* [Version 1](design_ver1.md)
* [Version 2](design_ver2.md)


# Description

### What is a data recorder?

A data recorder, is a simple software probe, designed to connect and fetch data from one or many data sources, like: a computer systems, one or many web and enterprise applications, weather and environment sensors, or different IoT equipment, using different communication protocols, like HTTP, SNMP or MODBUS. A data recorder does not offer support for data transport capabilities, like for example a _software agent_.

### What is the data transporter?

The data transporter, is the delivery layer, outside the data reocrder, responsible to deliver the output raw data from one or many data recorders to different backend systems: Redis, InfluxDB, Prometheus, your own custom database or applications. Data recorders do not incorporate within the transport functionality, like for example agent based collectors. Separating the transport functionality from the data recorder, simplifies and improves the security and performance of the data recordrs and transport utility itself (support new recorders, new data communication protocols as simle as possible, less bugs and defects, reduce complexity)


### Main features

Please check the main features of a data recorder: 

**Time series**

All recorded observations and metrics are stored as raw data. Raw data is a [simple text file](docs/rawdata.md), produced by a recorder, which fetches data from a system, device or sensor, which has not been modified or changed in any way.

**Data ontology**

To help you, we have [carefully selected and analyzed](https://github.com/sparvu/smart-objects), for each industry, the most needed metrics for different business cases, by grouping and classifying these metrics, to build a very efficient data analysis process. The recorder has built-in support for grouping and data classification.

**Microservice architecture**

Data recorders are light, independent running software applications which can be deployed on several computer system configurations. Built as self running entities the data recorders do not share data between each other, and are designed to fetch and capture only the right data from various sources of data.

**Support for different industries**

A data recorder supports one or many communication protocols to fetch data from different sources and technologies: industrial equipment, ICT enterprise, weather or environment sensors, being able to collect different metrics.

**Raw data compatible**

Each data recorder will save all collected metrics and parameters under one or many text files on disk. These files are simple, regular CSV text files, universal compatible with any software or system. If you want to know more about raw data, [please check this](docs/rawdata.md).

**Based on a high-level programming language**

Based on Perl/C or Rust the data recorders are developed as light software probes, which can extract data from different sources, able to run interactively or continuous using one or many data communication protocols with a direct system access to various metrics.

**Small system footprint**

Designed as [CLI](https://en.wikipedia.org/wiki/Command-line_interface) system utilities, the data recorders are conservative in CPU and memory consumption across many system architectures, like X86 or ARM. 

# Configuration

The data recorders, keep all their settings and defintion under a simple configuration file, based on the JSON format. For version 1 not all data recorders use a configuration file. In version 2, all data reocrders will use a JSON configuration for their metrics definition. See here for more details about data recorders confguration (Coming soon)

# Output data

A data recorder will output its data using a simple text CSV based format. the field delimiter can be anything, which should be configurable. In version 1, data recorders used ':' as the main field delimiter. In version 2, data recorders will allow users to define and set their own delimiter.

Example:

```
1692254474:0.05:0.21:399.79:0.01:0.00:0.02:0.02:99.95:0.00:0:0:0:23:23:84.69:852056.00:15.31:153976.00:1006032.00:12140.00:40316.00:800836.00:0.00:113660.00:153976.00:15.73:6.00:43.00:85.00:379.00:0:0.00:0:0.00:0.00:0.00:0.00:0:0.00:199395:49198.49:0:0:23554:1974.13:0:0:0:222949:51172.62:0.09:0.12:0.14

1692254479:0.08:0.31:399.69:0.04:0.00:0.04:0.00:99.92:0.00:0:0:0:23:23:84.69:851976.00:15.31:154056.00:1006032.00:12252.00:40400.00:800840.00:0.00:113656.00:154056.00:15.74:6.00:43.00:85.00:379.00:0:0.00:0:0.00:0.00:0.00:0.00:0:0.00:4:0.25:0:0:2:0.52:0:0:0:6:0.77:0.08:0.12:0.14

```



# How does it work?

<img src="/docs/img/Arch.png" align="right" />

A data recorder can run on different computer system architectures, like X64 or ARMv8. There can be more than one data recorder, for different activities, like fetching performance data from a storage system, an online web application, or an industrial IoT sensor or device. They do not interfere with other data recorders input and output execution. The data recorders work independently one of each other, having their own execution path and state.

The recorder can operate in two modes: 

  * interactively: you can manually run the recorder, using command line interface to start or stop the recorder 
  
  * automatic mode: you can continuously record data, without any manual interaction, for long periods of time 

The interactive or automatic mode can be enabled via command line interface. The automatic mode (logging option) will allow the recorder to log continuously data without any human intervention.

# Recorders vs Agent-based Software

<div align="center">
<img src="/docs/img/AgentsVsRecorders.jpg" height="80%" width="80%" />
<img src="/docs/img/RecorderVsAgent.png" height="80%" width="80%" />
</div> 

Go back [main page](https://github.com/sparvu/data-recorders)
