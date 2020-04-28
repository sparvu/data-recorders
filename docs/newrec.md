<img src="/docs/img/k-logo.png" align="left" height="35" width="275" />
<img src="/docs/img/perl_logo.png" align="right" height="100" width="100" />
<br/><br/>
<br/>

## How to write a new data recorder

Kronometrix Data Recorder module contains many recorders, developed for different industries and sources of data. You can extend the data recording module by building a new data recorder for your own industry, or extend a current domain. The new data 
recorder will require the Kronometrix Data Recording runtime environment, and its cofiguration files. The new data recorder cannot be deployed as a 
standalone application.

In the following example, we will show how to write a new data recorder, called myrec

## Template

```
#!/opt/kronometrix/perl/bin/perl
  
#  Copyright (c) 2020 XXX (website address).
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#  (http://www.gnu.org/copyleft/gpl.html)

use strict;
use warnings;
use JSON;
use Getopt::Std;
use Time::HiRes qw(time alarm setitimer ITIMER_REAL);
use POSIX qw(pause);
use otherlib;

# Debug Only
# use Data::Dumper;

### Command line arguments
usage() if defined $ARGV[0] and $ARGV[0] eq "--help";
getopts('lhV') or usage();
usage()    if defined $main::opt_h;
revision() if defined $main::opt_V;

# logging flag
my $logging = defined $main::opt_l ? $main::opt_l : 0;

# process [[interval [count]]
my ( $interval, $loop_max );
if ( defined $ARGV[0] ) {
    $interval = $ARGV[0];
    $loop_max = defined $ARGV[1] ? $ARGV[1] : 2**64;
    usage() if $interval == 0;
}
else {
    $interval = 1;
    $loop_max = 1;
}


### Variables
my %variable;                        # my_cpu_stats data
my $loop     = 0;                    # current loop number
$main::opt_h = 0;                    # help option
$main::opt_l = 0;                    # logging option
$main::opt_V = 0;                    # revision option
my $kfile    = 'kronometrix.json';   # configuration file
my $kdata;                           # configuration data
my $rawfile;                         # krd raw data file
my $tp = 0;                          # time precision
my ($baselog, $curlog, $clog, $log); # log files
local $| = 1;                        # autoflush


### MAIN BODY

# Set a timer for my object
local $SIG{ALRM} = sub { };
setitimer( ITIMER_REAL, .1, .1 );
my $bcpu = mylib->new( 'variable' );
### 0.1sec sleep using a timer
pause;

# how often do we trigger (seconds)?
my $first_interval = $interval;

# signal handler is empty
local $SIG{ALRM} = sub { };

# first value is the initial wait, second is the wait thereafter
setitimer( ITIMER_REAL, $first_interval, $interval );

# check interval input
if ( $interval =~ /\./ ) {
    $tp = 3;
}

# logging option
if ($logging) {

    # kronometrix.json config file
    $kdata = open_config($kfile);

    ## logs
    ( $baselog, $curlog ) = get_log($kdata);
    $rawfile = $curlog . '/' . 'myrec' . '.krd';
    $clog = $baselog . "/myrec.log";
    $log = open_file($clog);

    # save STDERR to log file
    *STDERR = $log;

    write_log ("info: started");
}


while (1) {

    my @sensor_data = get_sensor_data();

    my $rawkrd;
    if ($logging) {
        $rawkrd = open_file($rawfile);
    }

    foreach my $values (@sensor_data) {

        $values =~ s/\:$//;

        my ($cid, $u, $n, $s, $r, $i ) = split /:/, $values;

        ## debug
        # print "new: $cid, $u, $n, $s, $r, $i\n";

        # old values
        my ($old_u, $old_n, $old_s, $old_r, $old_i);

        if (defined $old_cpudata{$cid}) {
            ($old_u, $old_n, $old_s, $old_r, $old_i) =
                split /:/, $old_cpudata{$cid};
            ## debug
            # print "old: $old_u, $old_n, $old_s, $old_r, $old_i\n";

        } else {
            $old_u = $old_n = $old_s = $old_r = $old_i = 0;
        }


        my $ticks = cpu_ticks($old_u, $u);
        $ticks = $ticks + cpu_ticks($old_n, $n);
        $ticks = $ticks + cpu_ticks($old_s, $s);
        $ticks = $ticks + cpu_ticks($old_r, $r);
        $ticks = $ticks + cpu_ticks($old_i, $i);

        my $percent = 100 / $ticks;

        my $percent = 100 / $ticks;

        my $user  = delta($old_u, $u) * $percent;
        my $nice  = delta($old_n, $n) * $percent;
        my $sys   = delta($old_s, $s) * $percent;
        my $intr  = delta($old_r, $r) * $percent;
        my $idle  = delta($old_i, $i) * $percent;
        my $total = $user + $nice + $sys + $intr;

        if ($logging) {
            printf $rawkrd "%.${tp}f:%s:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f\n",
                time, "cpu$cid", $user, $nice, $sys, $intr, $idle, $total;
        } else {
            printf "%.${tp}f:%s:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f\n",
                time, "cpu$cid", $user, $nice, $sys, $intr, $idle, $total;
        }

        # save old data
        $old_cpudata{$cid} = "$u:$n:$s:$r:$i";

    }

    if ($logging) {
        close ($rawkrd);
    }

    ### Check for end
    last if ++$loop == $loop_max;

    ### Interval
    pause;

}


### SUBROUTINES

# open JSON configuration file
#
sub open_config {

    my ($conf) = @_;

    my $json_data;

    {
        local $/;

        # we will parse now the file
        if ( defined $ENV{'KRMX_PREFIX'} ) {
            if ( -e "$ENV{'KRMX_PREFIX'}/etc/$conf" ) {
                open my $fh, "<", "$ENV{'KRMX_PREFIX'}/etc/$conf";
                $json_data = <$fh>;
                close $fh;
            }
            else {
                print "error: open_conf - $! $ENV{'KRMX_PREFIX'}/etc/$conf \n";
                usage();
            }
        }
        else {
            if ( -e "/opt/kronometrix/etc/$conf" ) {
                open my $fh, "<", "/opt/kronometrix/etc/$conf";
                $json_data = <$fh>;
                close $fh;
            }
            else {
                print "error: open_conf - $! /opt/kronometrix/etc/$conf \n";
                usage();
            }
        }
    }

    my $perl_data = JSON->new->utf8->decode($json_data);

    return $perl_data;
}


# get log defintion
#
sub get_log {
    my ($data) = @_;

    my $bpath = $data->{'log'}->{'base_path'};
    my $cpath = $data->{'log'}->{'current_path'};

    return ( $bpath, $cpath );
}


# write_log - write log message
#
sub write_log {

    my ($logbuf) = @_;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
    localtime(time);

    my $dt = sprintf "%4d-%02d-%02d %02d:%02d:%02d",
                $year + 1900, $mon + 1, $mday, $hour, $min, $sec;

    if (eof $log) {
        print $log "$dt $logbuf\n";
    } else {
        print $log "\n$dt $logbuf";
    }

    return;
}

# open_data - open data file
#
sub open_file {

    my ($file) = @_;
    my $fh;

    if (-f $file) {
        open $fh, "+>>", "$file" or
          die "error: open_file - cannot open $file $!";
        seek $fh, 0, 2;
        select ((select ($fh), $| = 1)[0]);

    } else {
        open $fh, "+>", "$file" or
          die "error: open_file - cannot open $file $!";
        select ((select ($fh), $| = 1)[0]);

    }

    return $fh;
}


# usage - print usage and exit.
#
sub usage {
    print STDERR <<END;
USAGE: myrec [-hlV] | [interval [count]]
 e.g. myrec 5       print continuously, every 5 seconds
      myrec 1 5     print 5 times, every 1 second
      myrec -l 60   print continuously, every 60 seconds to raw datafile

 FIELDS:
  #01 timestamp  : seconds since Epoch, time
  #02 sensorid   : sensor id, number
  #03 param1     : sensor parameter 1, number
  #04 param1     : sensor parameter 2, number
  #05 status     : sensor status ONLINE / OFFLINE, number

END
    exit 0;
}


## revision - print revision and exit
sub revision {
    print STDERR <<END;
myrec: 1.0, 2020-04-28 1414
END
    exit 0;
}



```





* use library section

```
use strict;
use warnings;
use JSON;
use Getopt::Std;
use Time::HiRes qw(time alarm setitimer ITIMER_REAL);
use POSIX qw(pause);
use otherlib;

# Debug Only
# use Data::Dumper;
```

* command arguments section 

```
### Command line arguments
usage() if defined $ARGV[0] and $ARGV[0] eq "--help";
getopts('lhV') or usage();
usage()    if defined $main::opt_h;
revision() if defined $main::opt_V;

# logging flag
my $logging = defined $main::opt_l ? $main::opt_l : 0;

# process [[interval [count]]
my ( $interval, $loop_max );
if ( defined $ARGV[0] ) {
    $interval = $ARGV[0];
    $loop_max = defined $ARGV[1] ? $ARGV[1] : 2**64;
    usage() if $interval == 0;
}
else {
    $interval = 1;
    $loop_max = 1;
}
```

* main body section




* subroutines section

## Input data

## Outout data

## Configuration file

## Documentation 

## Testing


Go back [main page](https://gitlab.com/kronometrix/recording/)