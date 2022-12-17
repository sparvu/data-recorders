
# Introduction

To really understand how your world works, you need to capture the correct performance metrics from your systems, devices or applications, in real-time. No matter of your operating system or your platform used. Same time you need to have access to the original raw data collected, share it with anyone if you need so, as simple as possible. To achieve all these I started since 2009 to develop a number of light command line utilities, called data recorders, which can have capabilities to connect or wait for data from various sources and resolves the associated performance metrics in real-time. Enter data-recorders

* [Version 1](docs/design_ver1.md)
* [Version 2](docs/design_ver2.md)

<img src="/docs/img/data-recorders-ver2.0_4.png" />

# Re-Design



<div align="center">
<img src="/docs/img/perl2rust.png" width="75%"/>
</div> 


There can be many data recorders, designed for different tasks, available for several computer system architectures, like x64 or ARMv8. 

<div align="center">
<img src="/docs/img/DS2_HighLevel.png" height="80%" width="80%" />
</div> 


# What is a data recorder?

A data recorder, is a simple software probe, designed to connect and fetch data from one or many data sources, like: a computer systems, one or many web and enterprise applications, weather and environment sensors, or different IoT equipment, using different communication protocols, like HTTP, SNMP or MODBUS. A data recorder does not offer support for data transport capabilities, like for example a software agent. Please check the main features of a data recorder: 

**Time series**

All recorded observations and metrics are stored as raw data. Raw data is a [simple text file](docs/rawdata.md), produced by a recorder, which fetches data from a system, device or sensor, which has not been modified or changed in any way.

**Data ontology**

To help you, we have [carefully selected and analyzed](https://github.com/sparvu/smart-objects), for each industry, the most needed metrics for different business cases, by grouping and classifying these metrics, to build a very efficient data analysis process. The recorder has built-in support for grouping and data classification.

**Supports different industries**

A data recorder supports one or many communication protocols to fetch data from different sources and technologies: industrial equipment, ICT enterprise, weather or environment sensors, being able to collect different parameters and metrics.

**Raw data compatible**

Each data recorder will save all collected metrics and parameters under one or many text files on disk. These files are simple, regular CSV text files, universal compatible with any software or system. If you want to know more about raw data, [please check this](docs/rawdata.md).

**Based on a high-level programming language**

Recorders are light software probes, which can extract data from different sources, able to run interactively or continuous using one or many data communication protocols with a direct system access to various metrics.

**Small system footprint**

Designed as [CLI](https://en.wikipedia.org/wiki/Command-line_interface) system utilities, the data recorders are conservative in CPU and memory consumption across many system architectures, like X86 or ARM. 


## How does it work?

<img src="/docs/img/Arch.png" align="right" />

A data recorder can run on different computer system architectures, like X64 or ARMv8. There can be more than one data recorder, for different activities, like fetching performance data from a storage system, an online web application, or an industrial IoT sensor or device. They do not interfere with other data recorders input and output execution. The data recorders work independently one of each other, having their own execution path and state.

The recorder can operate in two modes: 

  * interactively: you can manually run the recorder, using command line interface to start or stop the recorder 
  
  * automatic mode: you can continuously record data, without any manual interaction, for long periods of time 

The interactive or automatic mode can be enabled via command line interface. The automatic mode (logging option) will allow the recorder to log continuously data without any human intervention.


## Recorders vs Others

<div align="center">
<img src="/docs/img/RecorderVsAgent.png" height="80%" width="80%" />
</div> 

Go back [main page](https://github.com/sparvu/data-recorders)
