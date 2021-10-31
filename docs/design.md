<img src="/docs/img/KDR-Text.png" align="left" height="74" width="325" />
<img src="/docs/img/KDR.png" align="right" height="100" width="100" />
<br/><br/>
<br/><br/>

[![Alt-Text](https://img.shields.io/static/v1.svg?label=ver&message=1.8.3&color=success)](docs/start.md)
[![](https://img.shields.io/static/v1.svg?label=license&message=GPL2&color=blue)](LICENSE)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1855/badge)](https://bestpractices.coreinfrastructure.org/projects/1855)

# Design

To really understand how your world works, you need to have data. The right kind of data. And for that, you need to be able to capture the correct performance metrics from your systems, devices or applications in real-time. To be able to do all of these, we have developed data recorders. The data recorder has built-in capabilities to connect or wait for data from various sources and resolves the associated performance metrics in real-time. 

There can be many data recorders, executing on top of a runtime engine, for example Perl5. All data recorders will share the same runtime engine and are designed for different tasks.

<div align="center">
<img src="/docs/img/KDR_Stack2.png" height="80%" width="80%" />
</div> 


# What is a data recorder?

A data recorder, is a simple software probe, designed to connect and fetch data from one or many data sources, like: a computer systems, one or many web and enterprise applications, weather and environment sensors, or different IoT equipment, using different communication protocols, like HTTP, SNMP or MODBUS. A data recorder will not offer data transport capabilities, like for example a software agent. See below the main features of a data recorder: 

**Time series**

All recorded observations and metrics are stored as raw data. Raw data is a simple text file, produced by a recorder, which fetches data from a system, device or sensor, which has not been modified or changed in any way.

**Data ontology**

To help you, we have carefully selected and analyzed, for each industry, the most needed metrics for different business cases, by grouping and classifying these metrics, to build a very efficient data analysis process. The recorder has built-in support for grouping and data classification.

**Supports different industries**

A data recorder supports one or many communication protocols to fetch data from different sources and technologies: industrial equipment, ICT enterprise, weather or environment sensors, being able to collect different parameters and metrics.

**Raw data compatible**

Each data recorder will save all collected metrics and parameters under one or many text files on disk. These files are simple, regular CSV text files, universal compatible with any software or system. If you want to know more about raw data, [please check this](docs/rawdata.md).

**Based on a high-level programming language**

Recorders are light software probes, which can extract data from different sources, being able to run interactively or continuous mode. Developed using a dynamic programming language, are very simple to change or build.

**Conservative in system resources**

Designed as single threaded applications, the data recorders are conservative in CPU and memory consumption across many system architectures, like X86, ARM or SPARC. 


## How does it work?

<img src="/docs/img/KDR_Arch.png" align="right" />

A data recorder requires a runtime engine to operate and execute, like Perl5 or Lua, for example. There can be more than one data recorder, designed for different activities, like fetching performance data from a storage system, an online web application, or an industrial IoT sensor or device. They do not interfere with other data recorders input and output execution. The data recorders work independently one of each other, having their own execution path and state.

The recorder can operate in two modes: 

  * interactively: you can manually run the recorder, using command line interface to start or stop the recorder 
  
  * automatic mode: you can continuously record data, without any manual interaction, for long periods of time 

The interactive or automatic mode can be enabled via command line interface. The automatic mode (logging option) will allow the recorder to log continuously data without any human intervention.


## Recorders vs Others

<div align="center">
<img src="/docs/img/RecorderVsAgent.png" height="80%" width="80%" />
<img src="/docs/img/recorderplus.png" height="80%" width="80%" /> 
<img src="/docs/img/recorder.png" height="80%" width="80%" /> 
</div> 

Go back [main page](https://gitlab.com/kronometrix/recording/)
