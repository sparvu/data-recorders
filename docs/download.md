
<img src="/docs/img/data-recorders-design5.jpg" />

# Installation

Select your package and install Kronometrix data recording to measure different systems, applications or industrial installations. Open your free 30 days trial account, to Kronometrix SaaS to automatically provision and visualize your data or
fetch manually the raw data and send it to any type of system for analysis.

<div align="center">
<img src="/docs/img/KPackages.png" height="80%" width="80%" />
</div> 

## Free Download 

See our ready [made packages](https://kronometrix.gitlab.io/packages/) 

Kronometrix Data Recording is a free open-source project which can be used to capture and transport data to any 3rd party systems or applications. By default, to visualize and analyse your data, you can subscribe to [Kronometrix SaaS](www.kronometrix.com/get-started). 



# Introduction

To really understand how our world works, we need to have the **correct performance metrics** to analyze. But how could we know what metrics we really need from our systems or applications? Well, we could try to capture as much data as possible and later start mining whatever we need. As this sounds promising we will soon find out that storage and data extraction will be expensive. So what choices do we have?

In reality we dont really need a lot of data. We will need the metrics which can help us to understand the behaviour and functionality of our systems or applications, related to:

* the overall system utilization and saturation
* device or sub component utilization and saturation
* the throughput
* system or device errors

We have already grouped and clasified the most important metrics we need. Of course we might need some other additional parameters in order to better describe and explain the functionality of our system(s). So on top of these primary categories we might need to have some aditional parameters which we can can enable or disable, if required. 

Then we will need to capture, in real-time, these performance metrics, and save them, using a simple output format, no matter of the operating system or platform used. The output data, the original raw data collected, should be easy to access and share with anyone, if required. And last but not least, capturing these metrics should be done automatically, without human intervention, to help build large data sets for performance analysis and capacity planning or interactively, for something like quick troubleshooting.

To achieve all these goals, we are introducing the _data recorders_ . Designed as light command line utilities, these recorders can have capabilities to connect or wait for data from various sources and resolve the associated performance metrics in real-time. The data recorders can use one or many data communication protocols, for example like TCP or UDP, or something like MODBUS or BACNet. A data recorder can be installed on a computer system or an industrial equipment, more or less like a traditional agent based software, or can be deployed and operated over the network, without any local presence. There are fundamental differences between a data recorder and software agent, see later about these differences.

The very first data recorders were published during 2009, mainly to fetch and collect performance data from various computer systems running Solaris and Linux operating systems. After that, more recorders were developed to capture HTTP data from various web applications, and TCP/UDP service performance data from various enterprise services, like databases or middleware software. Same time, new recorders were created to connect to various industrial sensors and devices and fetch different data, using for example the MODBUS protocol.

There are two main versions describing the evolution and development of the data recorders:

* [Version 1](design_ver1.md)
* [Version 2](design_ver2.md)


# Description

### What is a data recorder?

A data recorder, is a simple software probe, designed to connect and fetch data from one or many data sources, like: a computer systems, one or many web and enterprise applications, weather and environment sensors, or different IoT equipment, using different communication protocols, like HTTP, SNMP or MODBUS. A data recorder does not offer support for data transport capabilities, like for example a _software agent_. Please check the main features of a data recorder: 

**Time series**

All recorded observations and metrics are stored as raw data. Raw data is a [simple text file](docs/rawdata.md), produced by a recorder, which fetches data from a system, device or sensor, which has not been modified or changed in any way.

**Data ontology**

To help you, we have [carefully selected and analyzed](https://github.com/sparvu/smart-objects), for each industry, the most needed metrics for different business cases, by grouping and classifying these metrics, to build a very efficient data analysis process. The recorder has built-in support for grouping and data classification.

**Microservice architecture**

Data recorders are light, independent running software applications which can be deployed on several computer system configurations. Built as self running entities the data recorders do not share data between each other, and are designed to fetch and capture only the right data from various sources of data.

**Supports different industries**

A data recorder supports one or many communication protocols to fetch data from different sources and technologies: industrial equipment, ICT enterprise, weather or environment sensors, being able to collect different metrics.

**Raw data compatible**

Each data recorder will save all collected metrics and parameters under one or many text files on disk. These files are simple, regular CSV text files, universal compatible with any software or system. If you want to know more about raw data, [please check this](docs/rawdata.md).

**Based on a high-level programming language**

Recorders are light software probes, which can extract data from different sources, able to run interactively or continuous using one or many data communication protocols with a direct system access to various metrics.

**Small system footprint**

Designed as [CLI](https://en.wikipedia.org/wiki/Command-line_interface) system utilities, the data recorders are conservative in CPU and memory consumption across many system architectures, like X86 or ARM. 

# Configuration

# Output data


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
