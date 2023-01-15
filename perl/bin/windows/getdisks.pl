#
# Copyright (c) 2009-2022 Stefan Parvu (gitlab.com/sparvu)
# Initial Author: Stefan Parvu
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
my $recid       = 'getdisks';
my $key         = 'Name';
$|= 1;                                    # autoflush

my %nics;
my $nic_old = {};
my $deprecated = defined $d ? $d : 0;


### MAIN BODY

# set HIGH class for busy systems
my $curentProcess;
my $pid = Win32::Process::GetCurrentProcessID();
if (Win32::Process::Open($curentProcess, $pid, 0)) {
    $curentProcess->SetPriorityClass(HIGH_PRIORITY_CLASS);
}


# get stats
my $wmi = Win32::OLE->GetObject("winmgmts://./root/cimv2")
    or die "Cannot initialize WMI interface\n";

get_disks();



### SUBROUTINES

sub get_disks {

    my ($di, $dd);

    my $s1 = [gettimeofday];

    # get no of physical disks
    my $wd = $wmi->InstancesOf("Win32_DiskDrive");

    foreach my $disk (in $wd) {
        $di = $disk->{Index};
        $dd = $disk->{DeviceID};
        $dd =~ s/\\/\\\\/sg;

        my $qpart = 'ASSOCIATORS OF ' . '{Win32_DiskDrive.DeviceID="' . 
	            $dd . 
		    '"} WHERE AssocClass = Win32_DiskDriveToDiskPartition';

        # print "qpart=$qpart\n";

        my $wpart = $wmi->ExecQuery($qpart);

        foreach my $obj (in $wpart) {

            my $d1 = $obj->{DeviceID};

            my $wdrive = $wmi->ExecQuery("ASSOCIATORS OF {Win32_DiskPartition.DeviceID=\"$d1\"} WHERE AssocClass = Win32_LogicalDiskToPartition");

	    foreach my $lobj (in $wdrive) {
                my $lid = $lobj->{DeviceID};
	        print "$dd $d1, Logical: $lid\n";
	    }
        }
    }

    my $e1 = [gettimeofday];
    my $delta1  = tv_interval ($s1, $e1);
    print "Win32_DiskDrive calls took: $delta1 sec\n";
}


# usage - print usage and exit.
#
sub usage {
    print STDERR <<END;
USAGE: getdisks [-hV]
 eg. 
  getdisks.exe
END
    exit 0;
}


# revision - print revision and exit
#
sub revision {
    print STDERR <<END;
disks: 1.0.19, 2016-01-31 2034
END
    exit 0;
}



