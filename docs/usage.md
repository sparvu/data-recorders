# How to operate data recorders

**What you need to know before operation**

You need to have Kronometrix Data Recording module installed for your system. If you dont have Kronometrix Data Recording package installed on your system, please see refer to the article [Getting started](https://gitlab.com/kronometrix/recording/-/blob/master/docs/start.md) how to install data recorder. during installation, a dedicated, non privileged user account is created, krmx which will be the main Kronometrix user account to operate all data recorders.

## Interactive Operation

Please check and review the system requirements and prerequisites for [Linux](https://gitlab.com/kronometrix/recording/-/blob/master/README.linux) or [FreeBSD](https://gitlab.com/kronometrix/recording/-/blob/master/README.freebsd) operating systems, before operating data recorders.

You can run any data recorder via command line interface, by simple calling the recorder, using the absolute path. Example:

```
$ /opt/kronometrix/bin/sysrec
1646484612:0.00:0.00:100.00:0.00:0.00:0.00:100.00:0.00:0.00:0.00:0.00:0:84:88.12:899072:121172:1020244:61740:693284:876196:85.88:1.03:10748:1034752:1045500:996:0:0.00:0:0.00:0:0.00:11:0.72:0:0:0:0.00:0:0:11:0.72:0.00:0.00:0.00
```

You can provide the number of times the recorder will run, using the interval and count options. For example, to run sysrec data recorder two times, every 10 seconds, you can run:

```
$ /opt/kronometrix/bin/sysrec 10 2
1646484740:0.00:0.00:100.00:0.00:0.00:0.00:100.00:0.00:0.00:0.00:0.00:0:84:88.11:898976:121268:1020244:61744:693284:876296:85.89:1.03:10748:1034752:1045500:996:0:0.00:0:0.00:0:0.00:11:0.72:0:0:0:0.00:0:0:11:0.72:0.00:0.00:0.00
1646484750:0.00:0.00:100.00:0.00:0.00:0.00:100.00:0.00:0.00:0.00:0.00:0:84:88.13:899100:121144:1020244:61744:693284:876172:85.88:1.03:10748:1034752:1045500:996:0:0.00:0:0.00:0:0.00:0:0.00:0:0:0:0.00:0:0:0:0.00:0.00:0.00:0.00
```

Same way you can run any other data recorder or call the help usage interface to get more information:

```
$ /opt/kronometrix/bin/sysrec -h
USAGE: sysrec [-hlV] | [interval [count]]
 e.g. sysrec 5       print continuously, every 5 seconds
      sysrec 1 5     print 5 times, every 1 second
      sysrec .5      print continuously, every 0.5 seconds
      sysrec -l 60   print continuously, every 60 seconds to raw datafile
```


## Automatic Operation

In automatic mode, the recorders will save all metrics to a raw data file, no data will be printed on the screen and the run will be silent. This mode is recommeneded for long term data capturing, non interactive installations, where no humans are usually involved.

### Configuration files

A master script, called **rec** is responsible to start all data recorders, configured under kronometrix.json file. The kronometrix.json file is the main configuration file for data recording, where all data recorders are configured. For each active data recorder the master **rec** script will execute and launch the respective recorder.

#### kronometrix.json

Found under ```/opt/kronometrix/etc``` directory this is the main configuration file for all data recorders. This file contains 
three main sections:

##### Logging section

This is the section defining the base path and the location where all raw data logs will be stored. This can be located on a local disk or a remote LUN storage. Usually, this section, should not be changed or removed.

```
  "log" : {
    "current_path" : "/opt/kronometrix/log/current",
    "base_path" : "/opt/kronometrix/log",
    "daily_path" : "/opt/kronometrix/log/daily"
  },
```

##### Message section

Describes for each data recorder, what data message is associated with and the raw data files.


```
  "message" : [
    {
        "name" : "sys",
        "file" : "sysrec.krd",
      "status" : "active",
    "interval" : 60,
      "domain" : [ "cpd", "dpd", "spd", "wpd" ]
    },
    {
        "name" : "cpu",
        "file" : "cpurec.krd",
      "status" : "active",
    "interval" : 60,
      "domain" : [ "cpd", "dpd", "spd", "wpd" ]
    },
    {
        "name" : "disk",
        "file" : "diskrec.krd",
      "status" : "active",
    "interval" : 60,
      "domain" : [ "cpd", "dpd", "spd", "wpd" ]
    },
    {
        "name" : "nic",
        "file" : "nicrec.krd",
      "status" : "active",
    "interval" : 60,
      "domain" : [ "cpd", "dpd", "spd", "wpd" ]
    },
...
```

##### Data Fabric section
 
This is the section where users should defined where they want to send data. The platform section describes the details of one or many data analytics fabrics, each with own settings. All raw data can be transported to one or many platforms at the same time. Under this section we need to define and configure, the following:

- port number, the port number default 80, or 443
- hostname, IP or FQD of the platform 
- protocol: HTTP or HTTPS
- data subscription type:
  - cpd - Computer Performance
  - epd - End User Performance
  - dpd - Datacenter Performance
  - spd - Service Provider Performance
  - wpd - Web Application Performance
  - iaqd - Indoor Air Quality
  - aqd - Outdoor Air Quality
  - wcd - General Meteorology
  - amd - Aviation Meteorology
- sid: subscription id
- tid: token id
- dsid: to be let empty, will be automatically be computed

```
  "transport" : {
    "fabric" : [
      {
        "port" : 80,
        "keepalive" : 0,
        "name" : "Kronometrix Distributed Data Fabric",
        "host" : "change me",
        "protocol" : "http",
        "description" : "Kronometrix Distributed Data Fabric",
        "cpd" : [
          {
            "dsid" : "",
            "sid"  : "change me",
            "tid"  : "change me"
          }
        ]
      }
    ]
  }
```



For example **cpd** means, computer performance data and describes data belong to IT computer performance. There are many types of data subscriptions, each having its own type, metrics and summary statistics.

Each data recorder will have a section with its own settings.

```
    {
        "name" : "sys",
        "file" : "sysrec.krd",
        "status" : "active",
        "interval" : 60,
        "domain" : [ "cpd", "dpd", "spd", "wpd" ]
    },
```

#### recorder.json 

Same time, different data recorders, might need certain settings outside the main configuration file. These settings can be found under a different JSON file, using the recorder name. Not all data recorder might have such configuration file. For example sysrec data recorder does not have its own settings. On the other hand sockrec data recorder, has its own settings defined under sockrec.json.


As krmx user:

```
      $ /opt/kronometrix/etc/rec start
````
or as super-user, root:

```
      # /etc/rc.d/kdr start
```



Go back [main page](https://gitlab.com/kronometrix/recording/)
