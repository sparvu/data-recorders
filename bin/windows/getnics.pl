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
use Sys::Hostname;
use Win32;


# Debug Only
use Data::Dumper;

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

# get stats
my $wmi = Win32::OLE->GetObject("winmgmts://./root/cimv2")
    or die "Cannot initialize WMI interface\n";


if ($deprecated) {

    deprecated_nic();

} else {

    default_nic();

    print "NIC(s) discovered and ready to be processed:\n";
    while( my($key, $value) = each (%nics)) {
        print " $key => $value \n";
    }
    print "Total: " . keys(%nics) . "\n";
}


### SUBROUTINES

sub default_nic {

    print "\n";
    print "WARNING: This utility uses Win32_PerfRawData_Tcpip_NetworkInterface and\n";
    print "Win32_NetworkAdapterConfiguration to fetch all available network adapters\n";
    print "found on system.\n";

    my @nicstats = qw(PacketsReceivedPerSec BytesReceivedPerSec PacketsReceivedErrors PacketsReceivedDiscarded PacketsSentPerSec BytesSentPerSec PacketsOutboundErrors PacketsOutboundDiscarded Timestamp_PerfTime Frequency_PerfTime Frequency_Sys100NS Timestamp_Sys100NS);
      
    my $s1 = [gettimeofday];
    my $list = $wmi->InstancesOf('Win32_PerfRawData_Tcpip_NetworkInterface')  
         or die "Failed to get instance object\n";  

    print "\n";
    print "NICS Win32_PerfRawData_Tcpip_NetworkInterface provider:\n";
    foreach my $v (in $list) {
        print " $v->{$key}\n";
        map{$nic_old->{$v->{$key}}->{$_} = $v->{$_} }@nicstats;  
    }

    my $e1 = [gettimeofday];
    my $delta1  = tv_interval ($s1, $e1);
    print "Win32_PerfRawData_Tcpip_NetworkInterface calls took: $delta1 sec\n";
    print "\n";

    my $s2 = [gettimeofday];
    my %mn = getnics();
    my $e2 = [gettimeofday];
    my $delta2  = tv_interval ($s2, $e2);
    print "\n";
    print "Win32_NetworkAdapterConfiguration calls took: $delta2 sec\n";
    print "\n";

    return;
}


sub getnics {

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

    # get no of NICs
    my $wn = $wmi->InstancesOf('Win32_NetworkAdapterConfiguration')
        or die "Failed to get instance object\n";

    print "NICS Win32_NetworkAdapterConfiguration provider:\n";

    my $nnic = 0;

    # Network Adapter Configuration
    my %nac;


    foreach my $nic (in $wn) {

        my $desc = $nic->{Description};

	my $id   = $nic->{Index};

	my $ser  = $nic->{ServiceName};

        if (grep { $desc =~ /$_/i } @nicids) {

            print " $id $desc $ser\n";

	} else {

            # marked, filter /\()
            $desc =~ s/\(/[/g;
	    $desc =~ s/\)/]/g;
	    $desc =~ s/\//_/g;
	    $desc =~ s/\\/_/g;
	    $desc =~ s/\#/_/g;

            print " $id $desc $ser (marked)\n";

	    my $nic_name = lc $nic->{ServiceName} . '_' . $id;

            $nac{$desc}=$nic_name;
	}
    }

    # print Dumper(%nac);


    # match nics to tcpnics and save it to a new
    # hash finale
    foreach my $k (keys %$nic_old) {

        if (exists $nac{$k} ) {
	
	    map {$nics{$nac{$k}} = $k} keys %nac;
	}
	    
    }

    return %nics;
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

    print "WARNING: This utility uses Win32_NetworkAdapter to fetch all\n";
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
getnics: 1.0.19, 2016-01-27 0648
END
    exit 0;
}
