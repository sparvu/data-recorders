#
# Copyright (c) 2016 Stefan Parvu (www.kronometrix.org).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# (http://www.gnu.org/copyleft/gpl.html)

package PerlSvc;

use strict;
use warnings;
use Getopt::Long;
use File::Copy;
use Time::HiRes qw(time gettimeofday sleep tv_interval);
use Win32::OLE ('in');
use Win32::Process;
use Sys::Hostname;
use Win32;


# Debug Only
#use Data::Dumper;

### Command line arguments
usage() if defined $ARGV[0] and $ARGV[0] eq "--help";

my ($d, $h, $V);

Getopt::Long::Configure('bundling');
my $result = GetOptions (
                "h|help"       => \$h,
                "V|version"    => \$V,
                "d|deprecated" => \$d
                );

usage() if ( $h || ! $result );
revision() if defined $V;

# process [[interval [count]]
my ( $interval, $loop_max );
if ( defined $ARGV[0] ) {
    $interval = $ARGV[0];
    $loop_max = defined $ARGV[1] ? $ARGV[1] : 2**32;
    usage() if $interval == 0;
}
else {
    $interval = 1;
    $loop_max = 1;
}

### Variables
my $loop        = 0;                      # current loop number
my $recid       = 'getnics';
my $key         = 'Name';
$|= 1;                                    # autoflush

my %nics;
my $nic_old = {};
my $deprecated = defined $d ? $d : 0;


### MAIN BODY

# set RT class for busy systems
my $curentProcess;
my $pid = Win32::Process::GetCurrentProcessID();
if (Win32::Process::Open($curentProcess, $pid, 0)) {
    $curentProcess->SetPriorityClass(HIGH_PRIORITY_CLASS);
}



# get stats
my $wmi = Win32::OLE->GetObject("winmgmts://./root/cimv2")
    or die "Cannot initialize WMI interface\n";


if ($deprecated) {

    deprecated_nic();

} else {

    sleep (0.5);

    print "\n";

    print
      "This utility uses Win32_PerfRawData_Tcpip_NetworkInterface to report\n";
    print
      "TCPIP statistics for each network adapter found on system, mapping\n";
    print
      "the names from Win32_NetworkAdapterConfiguration\n";

    my %names = get_nac();

    #print "\n\n";
    #print Dumper (%names);

    print "\n";
    get_nics();

    print "NIC(s) discovered and ready to be processed:\n";
    my $cnt = 0;

    for my $k (keys %nics) {

        if (exists $names{$k}) {

            if ( $k =~ /\_\d+$/ ) {

                my ($l, $r) = $k =~ /^(.*)(_\d+)$/;
	        $l=~s/^\s+//; $l=~s/\s+$//;	
	        $r=~s/^\s+//; $r=~s/\s+$//;	
	        if (exists $names{$l}) {
		    my $nn = $names{$l} . $r;
                    print " $nn => $k\n";
		}

            } else {
	
	        print " $names{$k} => $k \n";

            }
        } else {

            if ( $k =~ /\_\d+$/ ) {
		my ($l, $r) = $k =~ /^(.*)(_\d+)$/;
	        $l=~s/^\s+//; $l=~s/\s+$//;	
	        $r=~s/^\s+//; $r=~s/\s+$//;	
               
	        if (exists $names{$l}) {
		    my $nn = $names{$l} . $r;
                    print " $nn => $k\n";
		}
		 
	    }

	}
    }

    #while( my($key, $value) = each (%nics)) {
    #    print " $key => $value \n";
    #}

    # print "Total: " . keys(%nics) . "\n";
}


### SUBROUTINES

sub get_nics {

    my @nicstats = qw( PacketsReceivedPerSec BytesReceivedPerSec 
                       PacketsReceivedErrors PacketsReceivedDiscarded 
		       PacketsSentPerSec     BytesSentPerSec 
		       PacketsOutboundErrors PacketsOutboundDiscarded 
		       Timestamp_PerfTime    Frequency_PerfTime 
		       Frequency_Sys100NS    Timestamp_Sys100NS);

    my @filter   =   ( 'isatap',
		       'Microsoft Virtual WiFi Miniport Adapter',
		       'Teredo Tunneling Pseudo-Interface',
		       'Reusable ISATAP Interface'
                     );

    my $s1 = [gettimeofday];
    my $list = $wmi->InstancesOf('Win32_PerfRawData_Tcpip_NetworkInterface')  
         or die "Failed to get instance object\n";  

    print "\n";
    print "NICS Win32_PerfRawData_Tcpip_NetworkInterface provider:\n";

    foreach my $v (in $list) {
        if (!grep { $v->{$key} =~ /$_/i } @filter) {

            print " $v->{$key} (marked) \n";

            map{$nic_old->{$v->{$key}}->{$_} = $v->{$_} }@nicstats;

	    $nics{$v->{$key}}=$v->{$key};

	} else {

            print " $v->{$key}\n";
        }
    }
 
    my $e1 = [gettimeofday];
    my $delta1  = tv_interval ($s1, $e1);

    printf "%s %.3f sec\n",
           "Win32_PerfRawData_Tcpip_NetworkInterface calls:",
           $delta1;

    print "\n\n";

    return;
}


sub get_nac {

my @nicids  =  (
                'WAN Miniport',
		'Microsoft ISATAP Adapter',
		'RAS Async Adapter',
		'Microsoft Virtual WiFi Miniport Adapter',
		'VMware Virtual Ethernet Adapter',
		'Microsoft Teredo Tunneling Adapter',
		'Microsoft Kernel Debug Network Adapter',
		'Hyper-V Virtual Switch Extension Adapter',
		'Hyper-V Virtual Ethernet Adapter'
                );

    my $s1 = [gettimeofday];

    # get no of NICs
    my $wn = $wmi->InstancesOf('Win32_NetworkAdapterConfiguration')
        or die "Failed to get instance object\n";

    # Network Adapter Configuration
    my %nac;

    print "\n";

    print "NICS Win32_NetworkAdapterConfiguration provider:\n";

    foreach my $nic (in $wn) {

        my $desc = $nic->{Description};

	my $svc  = lc $nic->{ServiceName};

        if (grep { $desc =~ /$_/i } @nicids) {

            print " $desc => $svc\n";

	} else {
            # marked, filter /\()
            $desc =~ s/\(/[/g;
	    $desc =~ s/\)/]/g;
	    $desc =~ s/\//_/g;
	    $desc =~ s/\\/_/g;
	    $desc =~ s/\#/_/g;

            print " $desc => $svc (marked)\n";

            $nac{$desc}=$svc;
	}
    }

    print "\n";
    print " NAC Table:\n";

    for my $nc (keys %nac) {

        print " $nc => $nac{$nc}\n"; 
    }


    my $e1 = [gettimeofday];
    my $delta1  = tv_interval ($s1, $e1);

    printf "%s %.3f sec\n",
           "Win32_NetworkAdapterConfiguration calls:",
           $delta1;

    #print Dumper(%nac);

    # match nics to tcpnics and save it to a new
    # hash finale
    #foreach my $k (keys %$nic_old) {
    #    if (exists $nac{$k} ) {
    #	    map {$nics{$nac{$k}} = $k} keys %nac;
    #	}
    #}

    # return NIC names
    # name => service ida
    # Microsoft Hyper-V Network Adapter _3 => netvsc
    # Microsoft Hyper-V Network Adapter _4 => netvsc
    # WAN Miniport (L2TP) => rasl2tp
    # WAN Miniport (SSTP) => rasSstp
    # WAN Miniport (IKEv2) => rasAgileVpn
    # WAN Miniport (PPTP) => pptpMiniport
    # WAN Miniport (PPPOE) => rasPppoe
    # WAN Miniport (IP) => ndisWan
    # WAN Miniport (IPv6) => ndisWan
    # WAN Miniport (Network Monitor) => ndisWan
    # Microsoft Kernel Debug Network Adapter => kdnic

    return %nac;
}


# uses Win32_NetworkAdapter deprecated class
#
sub deprecated_nic {

    # physical ids
    my $pdev  = 'PCI|USB|VMBUS';
    my $vdev  = 'ROOT|SW|\{';
    my $vid   = 'Microsoft|VMWare|VirtualBox';

    my $s1 = [gettimeofday];

    # get no of NICs
    my $nicq = 
      "SELECT * from Win32_NetworkAdapter";

    my $wn = $wmi->ExecQuery($nicq);

    my $nnic = 0;
    my $pnic = 0;
    my $vnic = 0;

    print "\nWARNING: This utility uses Win32_NetworkAdapter to fetch all\n";
    print "available network adapters found on system. The Win32_NetworkAdapter\n";
    print "class is very slow and not optimized for production usage.\n";

    foreach my $nic (in $wn) {

        my $vendor = $nic->{Manufacturer};
        my $pnp    = $nic->{PNPDeviceID};
        my $desc   = $nic->{Description};
        my $id     = $nic->{Index};

        if (defined $vendor and defined $pnp) {
            if    ( $vendor =~ /$vid/i and $pnp !~ /$pdev/i ) { $vnic++; }
            elsif ( $vendor !~ /$vid/i and $pnp =~ /$vdev/i ) { $vnic++; }
            else  { $pnic++; }
        } else { 
            print "Warning: $id, $desc missing vendor and pnp information \n";
	    $vendor = 'NA';
	    $pnp    = 'NA';
        }

        print "$id, $desc, $vendor, $pnp\n";
    }

    $nnic = $vnic + $pnic;
    print "\nNICs: $nnic, Physical: $pnic, Virtual: $vnic \n";

    my $e1 = [gettimeofday];
    my $delta1  = tv_interval ($s1, $e1);
    print "Win32_NetworkAdapter calls took: $delta1 sec\n";

    return;
}






# usage - print usage and exit.
#
sub usage {
    print STDERR <<END;
USAGE: getnics.exe -dV
 eg.
  getnics.exe -d    # deprecated mode, uses Win32_NetworkAdapter
  getnics.exe        # default CLI mode, prints all NICs
END
    exit 0;
}


# revision - print revision and exit
#
sub revision {
    print STDERR <<END;
getnics: 1.0.19, 2016-02-01 1229
END
    exit 0;
}
