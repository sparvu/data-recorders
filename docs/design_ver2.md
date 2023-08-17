<img src="/docs/img/recorders-rust.png" />

# Why 2.0?

Since 2009, the main architecture of the data recorders was based on C and Perl5. Perl was a good fit for string processing combined with the speed of C language. The data recorders have been used by [Kronometrix Data Analytics Platform](https://gitlab.com/kronometrix/) to offer data capturing capabilities for the platform, as [ready packages](https://kronometrix.gitlab.io/packages/) for different industries. These packages have been deployed on several systems and configurations since 2015. Over time we been able to identify several problems with our current C/Perl implementation:

* high memory usage fetching performance data from +500 web pages 
* network runtime errors handling data from multiple sensors over UDP
* not simple to implement new data recorders or support new protocols like BACnet 
* lack of Perl5 modules and C libraries to support new sensors and devices via MQTT
* cant deploy with a very small CPU and memory footprint for different installations like ARM
* lack of possibilities to run only certain data recorders without the entire C/Perl5 runtime engine

<div align="center">
<img src="/docs/img/cperl2rust.png" width="75%"/>
</div> 


There can be many data recorders, designed for different tasks, available for several computer system architectures, like x64 or ARMv8. 

<div align="center">
<img src="/docs/img/DS2_HighLevel.png" height="80%" width="80%" />
</div> 


TBC

Go back [design page](design.md)
