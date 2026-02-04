# Historic

## Consistent data recording
After more than 25 years of computer business we still lack of consistent performance monitoring between different operating systems, each system deploying its own type of monitoring and data collection. UNIX systems try to stay a bit close with each other since all are POSIX systems and follow similar industry standards, like The Open Group. Other systems, like Windows, use different data collection techniques.

It is very difficult to have a consistent data recording across many operating systems without purchasing separately additional software or install 3rd parties software. Even more, the recorded format data varies from system to system making difficult the collection and analysis.

If we step back and we look other industries, how are they doing it, we see a completely different picture, efforts being made towards standardization and common ways to record and offer data for analysis:

### Aerospace industry
Airplanes use some sort of data recorders, usually found as a device called flight data recorder **FDR**, built to store aircraft data parameters. Such unit is found by default on many airplanes nowadays and its usage is regulated by governments and federal administrations, example FAA in United States. This device sometimes is referred as the black box.

### Shipbuilding industry
Ships, boats or other type of vessels use some sort of recorder, called voyager data recorder **VDR**, used to store vessel data parameters. Similar to aerospace industry such devices are required when a certain vessel must comply with international standards, International Convention for the Safety of Life at Sea, SOLAS. Used mainly for accident investigation the VDR can serve as preventive maintenance, performance efficiency monitoring, heavy weather damage analysis and accident avoidance. This device sometimes is referred as the black box.

### Auto industry
Automobiles use some sort of device used to store vehicle parameters, called event data recorder **EDR**. EDRs are not enforced by any standard organizations and are not really required by law so their usage varies from vendor to vendor. National Highway Traffic Safety Administration, NHTSA, proposed a series of changes to standardize and enforce mandatory EDR installation and usage by vendors. Around 2010 over 85% of all vehicles in US would already have some sort of EDR installed.

## IT industry
Computer systems have no such data recording device, installed. Manufacturers are not interested in standardizing this effort since they prefer selling additional software packages which can perform such recording features for an extra cost. The lack of standardization and agreements between vendors makes computing business complex and difficult to handle performance data. Currently, there are thousand of such performance monitoring solutions.

Checking each operating system, we can see a smilar way to fetch and extract performance data using different interfaces, called differently from vendor to vendor and implemnetation: Sun Solaris KSTAT, Linux /proc, HP-UX KSTAT, IBM AIX RSTAT, Microsoft Windows WMI. So what if we could have several standard data recorders or agents, which could fetch metrics from each system interface and have them exporting this data same way, no matter of the implementation. And to make things even simpler we could use a very simple data format for the exported data, for example flat text file format, which can be used by any reporting system for future analysis and visualization.

Similar to a FDR device, we could develop a simple data recording module which can be used for system troubleshooting, performance analysis, system crash analysis and it can be enabled across a large number of hosts in a data center, no matter of the operating system used.
