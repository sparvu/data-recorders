<img src="/docs/img/recorders-v2.png" />

# Why 2.0?

Since 2009, the main architecture of the data recorders was simple designed as a monolithic stack, based on C and Perl5. Perl was a good fit for the entire string processing part, combined with the speed of C language. 
Over time, we have received valuable feedback and we have discovered several problems with the default current C/Perl implementation:

* high memory usage fetching performance data from +1000 web sites 
* network runtime errors handling data from multiple sensors over UDP
* not simple to implement new data recorders or support new protocols, like BACnet 
* very limited support for Perl5 libraries to support new sensors and devices over MQTT
* difficult to deploy with a very small CPU and memory footprint, for different installations like ARM
* monolithic design, hard to execute without the entire C/Perl5 runtime engine

<div align="center">
<img src="/docs/img/perl2rust.png" width="75%"/>
</div> 

To address all these issues, after 2020, I have started to re-think the recorders based on a different design and architecture, which will allow us to execute different recorders, as efficient as possible without the need of an entire runtime engine. Same time, fast text processing and support for different network protocols, would remain paramount on the new design. 

Formal specifications would also be used to write precise designs for the new recorders. This would be very critical to have as accurate as possible specs for coming architecture. Then the programming language. Rust came immediately, as a strong candidate for speed, safery and concurrency. Moving from C/Perl5 to Rust will allow to simplify the development of new data recorders, same time being able to improve the performance and security of data recorders.

## New Architecture

Based on Rust, the new data recorders, can be compiled for various operating systems and platforms, without the need of a runtime environment in place, which will improve performance, same time staying safe and secure. There can be many data recorders, designed for different tasks, available for several computer system architectures, like x64 or ARMv8. 

<div align="center">
<img src="/docs/img/recorders-arch-v2.png" height="80%" width="80%" />
</div> 



Go back [design page](design.md)
