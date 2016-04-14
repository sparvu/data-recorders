#!/opt/kronometrix/perl/bin/perl
#
#  Copyright (c) 2016 Stefan Parvu (www.kronometrix.org).
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
use Getopt::Std;
use Time::HiRes qw(time alarm setitimer ITIMER_REAL);
use Sys::Statistics::Linux;
use POSIX qw(pause);

###  Process command line args
usage() if defined $ARGV[0] and $ARGV[0] eq "--help";
getopts('xhV') or usage();
usage()    if defined $main::opt_h;
revision() if defined $main::opt_V;

# process [interval [count]],
my ( $sinterval, $interval, $loop_max );
if ( defined $ARGV[0] ) {
    $interval = $ARGV[0];
    $loop_max = defined $ARGV[1] ? $ARGV[1] : 2**32;
    usage() if $interval == 0;
}
else {
    $interval = 1;
    $loop_max = 1;
}

# set debug log
my $xmode = defined $main::opt_x ? $main::opt_x : 0;

###  Variables
my $sb   = "/sys/block"; # sysblock device path
my $loop = 0;            # current loop number
my $tp   = 0;            # time precision
$main::opt_h = 0;        # help option
$main::opt_V = 0;        # revision option
local $| = 1;



### MAIN BODY

if ($xmode) { 
    $sinterval=$interval; 
    $interval = 1; 
}

# Set a timer for S::S::L object
local $SIG{ALRM} = sub { };
setitimer( ITIMER_REAL, .1, .1 );
my $lxs = Sys::Statistics::Linux->new(
    cpustats  => 1,
    memstats  => 1,
    diskstats => 1,
    netstats  => 1,
    loadavg   => 1
);
### 0.1sec sleep using a timer
pause;

# how often do we trigger (seconds)?
my $first_interval = $interval;

# signal handler is empty
local $SIG{ALRM} = sub { };

# first value is the initial wait, second is the wait thereafter
setitimer( ITIMER_REAL, $first_interval, $interval );

if ( $interval =~ /\./ ) {
    $tp = 3;
}

my $k = 1;


my @cpu_total;
my @ncpu;
my @hcpu;
my (@user, @nice, @system, @idle, @iowait, @irq, @softirq, @steal, @rqsz, @tcount);
my (@memusedper, @memused, @memfree, @memtotal, @membuffers, @memcached, @realfree, @realfreeper, @swapusedper, @swapused, @swapfree, @swaptotal, @swapcached);
my (@reads, @rkbytes, @writes, @wkbytes, @iops, @rwkbytes);
my (@rxpkt, @rxkbytes, @rxerr, @rxdrop, @txpkt, @txkbytes, @txerr, @txdrop, @rxtxpkt, @rxtxkbytes);
my (@la1, @la5, @la15);

while (1) {

    my ( $reads, $rkbytes, $writes, $wkbytes, $iops, $rwkbytes ) = 0;

    # net stats
    my ( $rxpkt, $rxkbytes, $rxerr, $rxdrop, $txpkt, $txkbytes, $txerr, $txdrop, $ntByt, $rxtxpkt, $rxtxkbytes ) = 0;

    # runq size and task count
    my ( $rqsz, $tcount ) = 0;

    ### Get Stats
    my $stat    = $lxs->get;

    # Dump $lx variable
    # use Data::Dumper;
    # print Dumper($stat);

    my $cpu     = $stat->cpustats->{cpu};
    my $mem     = $stat->memstats;
    my $disk    = $stat->diskstats;
    my $nic     = $stat->netstats;
    my $la      = $stat->loadavg;

    ### sum(cpus)
    my $scpus = $stat->cpustats;
    my @cpus = sort $stat->cpustats;
    my ($ncpu, $numcpus) = 0;

    foreach (@cpus) {
        next if ( $_ eq "cpu" );
        $ncpu += $scpus->{$_}{total};
        $numcpus++;
    }

    ### headroom cpu
    my $hcpu = ($numcpus * 100) - $ncpu;


    ### get disks
    my $rdisks = get_disks();

    ### loop over all disks
    foreach (@$rdisks) {

        # print "\nDisk: $_ \n";

        if ( defined( $disk->{$_}{rdreq} ) ) {
            $reads += $disk->{$_}{rdreq};
        }

        if ( defined( $disk->{$_}{rdbyt} ) ) {
            $rkbytes += ( $disk->{$_}{rdbyt} / 1024 );
        }

        if ( defined( $disk->{$_}{wrtreq} ) ) {
            $writes += $disk->{$_}{wrtreq};
        }

        if ( defined( $disk->{$_}{wrtbyt} ) ) {
            $wkbytes += ( $disk->{$_}{wrtbyt} / 1024 );
        }

        if ( defined( $disk->{$_}{ttreq} ) ) {
            $iops += $disk->{$_}{ttreq};
        }

        if ( defined( $disk->{$_}{ttbyt} ) ) {
            $rwkbytes += ( $disk->{$_}{ttbyt} / 1024 );
        }

        ### Debug
        #print "readReq = $readReq \n";
        #print "writeReq = $writeReq \n";
        #print "totReq = $totReq \n";
        #print "readBytes = $readByt\n";
        #print "writeReq = $writeByt \n";
        #print "totByt = $totByt \n";
    }

    ### Get NICS
    my @nics = sort $stat->netstats;

    # loop over all NICS
    foreach (@nics) {

        # skip here the non eth NICs
        next if $_ !~ /^eth|^wlan/;

        #
        # print "NIC: $_ \n";

        # rx
        if ( defined( $nic->{$_}{rxpcks} ) ) {
            $rxpkt += ( $nic->{$_}{rxpcks} );
        }

        if ( defined( $nic->{$_}{rxbyt} ) ) {
            $rxkbytes += ( $nic->{$_}{rxbyt} / 1024 );
        }

        if ( defined( $nic->{$_}{rxerrs} ) ) {
            $rxerr += ( $nic->{$_}{rxerrs} );
        }

        if ( defined( $nic->{$_}{rxdrop} ) ) {
            $rxdrop += ( $nic->{$_}{rxdrop} );
        }

        # tx
        if ( defined( $nic->{$_}{txpcks} ) ) {
            $txpkt += ( $nic->{$_}{txpcks} );
        }

        if ( defined( $nic->{$_}{txbyt} ) ) {
            $txkbytes += ( $nic->{$_}{txbyt} / 1024 );
        }

        if ( defined( $nic->{$_}{txerrs} ) ) {
            $txerr += ( $nic->{$_}{txerrs} );
        }

        if ( defined( $nic->{$_}{txdrop} ) ) {
            $txdrop += ( $nic->{$_}{txdrop} );
        }
 
        # throughput
        if ( defined( $nic->{$_}{ttbyt} ) ) {
            $rxtxkbytes += ( $nic->{$_}{ttbyt} / 1024 );
        }

    }

    $rxtxpkt = $rxpkt + $txpkt;
    # $rxtxkbytes = $rxkbytes + $txkbytes;


    # get runq_sz and process count from /proc/loadavg
    open my $plavg, '<', '/proc/loadavg'
      or die "Error: Cannot find proc partitions file: $!\n";

    ($rqsz, $tcount) = (split m@/@, (split /\s+/, <$plavg>)[3]);

    close $plavg;

    # exclude from runqa_sz current process
    $rqsz--;

    # default mode, xmode off
    if ($xmode == 0) {

    printf
         "%.${tp}f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%d:%d:%.2f:%d:%d:%d:%d:%d:%d:%.2f:%.2f:%d:%d:%d:%d:%d:%.2f:%d:%.2f:%d:%.2f:%d:%.2f:%d:%d:%d:%.2f:%d:%d:%d:%.2f:%.2f:%.2f:%.2f\n",
          time,
          $cpu->{total},  $ncpu,        $hcpu, 
          $cpu->{user},   $cpu->{nice}, $cpu->{system},  $cpu->{idle},
          $cpu->{iowait}, $cpu->{irq},  $cpu->{softirq}, $cpu->{steal},
          $rqsz,       $tcount,
          $mem->{memusedper},  $mem->{memused},
          $mem->{memfree},     $mem->{memtotal},
          $mem->{buffers},     $mem->{cached},
          $mem->{realfree},    $mem->{realfreeper},
          $mem->{swapusedper}, $mem->{swapused},
          $mem->{swapfree},    $mem->{swaptotal},
          $mem->{swapcached},

          $reads,  $rkbytes,
          $writes, $wkbytes,
          $iops,   $rwkbytes,

          $rxpkt, $rxkbytes, $rxerr, $rxdrop,
          $txpkt, $txkbytes, $txerr, $txdrop,
          $rxtxpkt, $rxtxkbytes,

          $la->{avg_1}, $la->{avg_5}, $la->{avg_15};

    # sinterval max sample interval
    } else {

        push @cpu_total, $cpu->{total};
        push @ncpu, $ncpu;
        push @hcpu, $hcpu;
        push @user, $cpu->{user};
        push @nice, $cpu->{nice};
        push @system, $cpu->{system};
        push @idle, $cpu->{idle};
        push @iowait, $cpu->{iowait};
        push @irq, $cpu->{irq};
        push @softirq, $cpu->{softirq};
        push @steal, $cpu->{steal};
        push @rqsz, $rqsz;
        push @tcount, $tcount;

        push @memusedper, $mem->{memusedper};
        push @memused, $mem->{memused};
        push @memfree, $mem->{memfree};
        push @memtotal, $mem->{memtotal};
        push @membuffers, $mem->{buffers};
        push @memcached, $mem->{cached};
        push @realfree, $mem->{realfree};
        push @realfreeper, $mem->{realfreeper};
        push @swapusedper, $mem->{swapusedper};
        push @swapused, $mem->{swapused};
        push @swapfree, $mem->{swapfree};
        push @swaptotal, $mem->{swaptotal};
        push @swapcached, $mem->{swapcached};
       
        push @reads, $reads;
        push @rkbytes, $rkbytes;
        push @writes, $writes;
        push @wkbytes, $wkbytes;
        push @iops, $iops;
        push @rwkbytes, $rwkbytes;

        push @rxpkt, $rxpkt;
        push @rxkbytes, $rxkbytes;
        push @rxerr, $rxerr;
        push @rxdrop, $rxdrop;
        push @txpkt, $txpkt;
        push @txkbytes, $txkbytes;
        push @txerr, $txerr;
        push @txdrop, $txdrop;
        push @rxtxpkt, $rxtxpkt;
        push @rxtxkbytes, $rxtxkbytes;

        push @la1, $la->{avg_1};
        push @la5, $la->{avg_5};
        push @la15, $la->{avg_15};
 
        if ($k == $sinterval) {

            # cpu
            my $avg_cpu    = getavg(@cpu_total);
            my $avg_ncpu   = getavg(@ncpu);
            my $avg_hcpu   = getavg(@hcpu);
            my $avg_user   = getavg(@user);
            my $avg_nice   = getavg(@nice);
            my $avg_sys    = getavg(@system);
            my $avg_idle   = getavg(@idle);
            my $avg_iowait = getavg(@iowait);
            my $avg_irq    = getavg(@irq);
            my $avg_sirq   = getavg(@softirq);
            my $avg_steal  = getavg(@steal);
            my $avg_rqsz   = getavg(@rqsz);
            my $avg_tcount = getavg(@tcount);

            # mem
            my $avg_memusedper = getavg(@memusedper);
            my $avg_memused    = getavg(@memused);
            my $avg_memfree    = getavg(@memfree);
            my $avg_memtotal   = getavg(@memtotal);
            my $avg_membuffers = getavg(@membuffers);
            my $avg_memcached  = getavg(@memcached);
            my $avg_realfree   = getavg(@realfree);
            my $avg_realfreeper= getavg(@realfreeper);
            my $avg_swapusedper= getavg(@swapusedper);
            my $avg_swapused   = getavg(@swapused);
            my $avg_swapfree   = getavg(@swapfree);
            my $avg_swaptotal  = getavg(@swaptotal);
            my $avg_swapcached = getavg(@swapcached);
           
            # disk io
            my $avg_reads    = getavg(@reads);
            my $avg_rkbytes  = getavg(@rkbytes);
            my $avg_writes   = getavg(@writes);
            my $avg_wkbytes  = getavg(@wkbytes);
            my $avg_iops     = getavg(@iops);
            my $avg_rwkbytes = getavg(@rwkbytes);

            my $avg_rxpkt      = getavg(@rxpkt);
            my $avg_rxkbytes   = getavg(@rxkbytes);
            my $avg_rxerr      = getavg(@rxerr);
            my $avg_rxdrop     = getavg(@rxdrop);
            my $avg_txpkt      = getavg(@txpkt);
            my $avg_txkbytes   = getavg(@txkbytes);
            my $avg_txerr      = getavg(@txerr);
            my $avg_txdrop     = getavg(@txdrop);
            my $avg_rxtxpkt    = getavg(@rxtxpkt);
            my $avg_rxtxkbytes = getavg(@rxtxkbytes);

            # LA
            my $avg_la1    = getavg(@la1);
            my $avg_la5    = getavg(@la5);
            my $avg_la15   = getavg(@la15);

            printf "%.${tp}f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%d:%d:%.2f:%d:%d:%d:%d:%d:%d:%.2f:%.2f:%d:%d:%d:%d:%.2f:%d:%.2f:%d:%.2f:%d:%.2f:%d:%d:%d:%.2f:%d:%d:%d:%.2f:%.2f:%.2f:%.2f\n", 
                    time, $avg_cpu, $avg_ncpu, $avg_hcpu, 
                    $avg_user, $avg_nice, $avg_sys, $avg_idle,
                    $avg_rqsz, $avg_tcount,
                    $avg_memusedper, $avg_memused, $avg_memfree, $avg_memtotal,
                    $avg_membuffers, $avg_memcached, $avg_realfree, $avg_realfreeper,
                    $avg_swapusedper, $avg_swapused, $avg_swapfree, $avg_swaptotal, $avg_swapcached,
                    $avg_reads, $avg_rkbytes, $avg_writes, $avg_wkbytes, $avg_iops, $avg_rwkbytes,
                    $avg_rxpkt, $avg_rxkbytes, $avg_rxerr, $avg_rxdrop, $avg_txpkt, $avg_txkbytes, $avg_txerr, $avg_txdrop, $avg_rxtxpkt, $avg_rxtxkbytes,
                    $avg_la1, $avg_la5, $avg_la15;

            undef(@cpu_total);
            undef(@ncpu);
            undef(@hcpu);
            undef(@user);
            undef(@nice);
            undef(@system);
            undef(@idle);
            undef(@iowait);
            undef(@irq);
            undef(@softirq);
            undef(@steal);
            undef(@rqsz);
            undef(@tcount);

            undef(@memusedper);
            undef(@memused);
            undef(@memfree);
            undef(@memtotal);
            undef(@membuffers);
            undef(@memcached);
            undef(@realfree);
            undef(@realfreeper);
            undef(@swapusedper);
            undef(@swapused);
            undef(@swapfree);
            undef(@swaptotal);
            undef(@swapcached);

            undef(@reads);
            undef(@rkbytes);
            undef(@writes);
            undef(@wkbytes);
            undef(@iops);
            undef(@rwkbytes);

            undef(@rxpkt);
            undef(@rxkbytes);
            undef(@rxerr);
            undef(@rxdrop);
            undef(@txpkt);
            undef(@txkbytes);
            undef(@txerr);
            undef(@txdrop);
            undef(@rxtxpkt);
            undef(@rxtxkbytes);

            undef(@la1);
            undef(@la5);
            undef(@la15);

            $k = 1;

        } else { $k++; }
    }

    ### Check for end
    last if ++$loop == $loop_max;

    ### Interval
    pause;

}



### SUBROUTINES

# getavg - return MEAN of array values
sub getavg {

    my @values = @_;

    my $avg = 0;
    for my $i (0 .. $#values) {
        $avg += $values[$i];
    }

    $avg = $avg / $sinterval;

    return $avg;
}





# get_disks - return the attached disks on the system.
#
sub get_disks {

    my @d;

    # get disks
    opendir(my $dh, $sb) 
        or die "Error: Cannot find block directory: $!\n";

    while(readdir $dh) {
        # discard parent dir
        next if ($_ =~ m/^\./);

        # exceptions
        next if ($_ =~ m/^loop|^ram|^zram/);
        next if ($_ =~ m/^fd0|^hdc/);
        next if ($_ =~ m/^md(?:[0-9])/);
        next if ($_ =~ m/^sr(?:[0-9])$/);
        
        # print disks
        # print "Disk: $_\n";
        push @d, "$_";
    }
    closedir $dh;

    # return array ref
    return \@d;
}


sub get_part {
    my ($entry) = @_;
    my ( $s, $maj, $min, $bks, $name );

    chomp $entry;
    return if $entry =~ /^major/;
    return if $entry =~ /^$/;
   
    # we return any valid partition number, we skip entire disk
    if ($entry =~ /(?:[0-9])$/) {
        ( $s, $maj, $min, $bks, $name ) = split /\s+/, $entry;
        return $name;
    }

    return;
}


# usage - print usage and exit.
#
sub usage {
    print STDERR <<END;
USAGE: sysrec [-xhV] | [interval [count]]
 e.g. sysrec 5        print continuously, every 5 seconds
      sysrec 1 5      print 5 times, every 1 second
      sysrec -x 1 5   print 5 times, every 1 second
      sysrec .5       print continuously, every 0.5 seconds

 FIELDS:
  CPU
   #01 timestamp  : seconds since Epoch, time
   #02 cpupct     : cpu utilization, across all cpus, number
   #03 sumpct     : sum of all cpus utilization, number
   #04 headpct    : headroom cpu available, all cpus, number
   #05 userpct    : cpu utilization, user space in percent, number
   #06 nicepct    : cpu utilization, user space with nice priority, number
   #07 sysct      : cpu utilization, system space, number
   #08 idlepct    : cpu utilization, idle state, number
   #09 iowaitcpt  : cpu percentage in idle state because an I/O operation 
                     is waiting to complete, number
   #10 irqpct     : cpu percentage servicing interrupts, number
   #11 softirqpct : cpu percentage servicing softirqs, number
   #12 stealpct   : cpu percentage of time spent in other operating systems
                    when running in a virtualized environment, number
   #13 runqsz     : run queue length, tasks waiting for run time, number
   #14 plistsz    : tasks in the task list, number

  MEM
   #15 memusedpct : size of used memory in percent, number
   #16 memused    : size of used memory in kilobytes, number
   #17 memfree    : size of free memory in kilobytes, number
   #18 memtotal   : size of memory in kilobytes, number
   #19 buffers    : size of buffers used from memory in kilobytes, number
   #20 cached     : size of cached memory in kilobytes, number
   #21 realfree   : size of memory is real free, number
                     (memfree+buffers+cached)
   #22 realfreepct: size of memory real free in percent of total memory, number
   #23 swapusedpct: size of used swap space in percent, number
   #24 swapused   : size of swap space is used is kilobytes, number
   #25 swapfree   : size of swap space is free in kilobytes, number
   #26 swaptotal  : size of swap space in kilobytes, number
   #27 swapcached : memory that once was swapped out, is swapped back in 
                     but still also is in the swapfile, number

  DISK
   #28 reads      : disk read requests per second, rate
   #29 rkbytes    : read KB per second, rate
   #30 writes     : disk write requests per second, rate
   #31 wkbytes    : write KB per second, rate
   #32 iops       : disk read+write requests per second, rate
   #33 rwkbytes   : read+write KB per second, rate

  NIC
   # rx received, inbound
   #34 rxpkt      : rx packets per sec, rate
   #35 rxkbytes   : rx KB per sec, rate
   #36 rxerr      : rx packets containing errors, rate
   #37 rxdrop     : number of rx packets that were dropped per second, rate
   
   # tx transmitted, outbound
   #38 txpkt      : tx packets per sec, rate
   #39 txkbytes   : tx KB per sec, rate
   #40 txerr      : tx packets containing errors, rate
   #41 txdrop     : number of tx packets that were dropped per second, rate

   # throughput
   #42 rxtxpkt    : rx+tx packets per sec, rate
   #43 rxtxkbytes : rx+tx KB per sec, rate
 
   #44 avg1       : LA of the last minute, number
   #45 avg5       : LA of the last 5 minutes, number
   #46 avg15      : LA of the last 15 minutes, number

END
    exit 0;
}


# revision - print revision and exit
#
sub revision {
    print STDERR <<END;
sysrec: 1.1.0, 2016-04-08 1213
END
    exit 0;
}
