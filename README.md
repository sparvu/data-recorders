## Overview

All recorded observations we call them raw data. Raw data is produced by a monitoring agent, running on each host we plan to record data from. This set of data is not modified, altered or changed in any way and it is entirely the way we collected from the computer system. Its format is simple, as already mentioned, having its parameters collected separated by a character like , or :. Each recorder will write and store all collected parameters under such raw data file for the entire duration of its execution.

## Time Series

All collected metrics are variable measured sequentially in time, called time series. All these observations collected over fixed sampling intervals create a historical time series. To easy the access to all this set of data SDR simple records and stores the observations on commodity disk drives, compressed, in text format. All these are the sdrd data files, as described above.

Time series let us understand what has happened in past and look in the future, using various statistical models. In addition , having access to these historical time series will help us to build a simple capacity planning model for our application or site. 

## Industries
We plan to support and record data from different types of industries. For some we have already developed data recorderds, like IT, Meteorology and we need help to enhance it. Each data recorder describe a message which can be found under the [library of monitoring objects](kronometrix/lmo/blob/master/README.md), a collection of objects. 

 * Business Analytics (BA)
 * Climatology
 * Environmental Monitoring
 * Finance
 * Healthcare
 * Information Technology (IT)
 * Meteorology


### Information Technology

 * sysrec overall system CPU, MEM, DISK, NIC utilization
 * cpurec per-CPU statistics
 * nicrec per-NIC statistics
 * diskrec per-DISK statistics
 * hdwrec hardware, software inventory 


### Meteorology / Climatology

 * wsrec: WH1080, WH1081, WH1090, WH20xx
 * vwsrec: Vaisala Weather Station recorder
  
 
