use ExtUtils::MakeMaker;
use File::Copy qw(cp);
use Data::Dumper;
use strict;
use warnings;
use 5.024000;

my $conf_dir = '/opt/kronometrix/etc';
my $bin_dir  = '/opt/kronometrix/bin';

if (defined $ENV{KRMX_PREFIX} ) {
    if (-d "$ENV{KRMX_PREFIX}/etc") {
        $conf_dir = "$ENV{KRMX_PREFIX}/etc";
    }
    else {
        die "Directory $ENV{KRMX_PREFIX}/etc does not exist";
    }
    if (-d "$ENV{KRMX_PREFIX}/bin") {
        $bin_dir = "$ENV{KRMX_PREFIX}/bin"
    }
    else {
        die "Directory $ENV{KRMX_PREFIX}/bin does not exist";
    }
}

my %config = (
    NAME              => 'Kronometrix',
    VERSION_FROM      => 'lib/Kronometrix.pm', 
    PREREQ_PM         => {
		'JSON'         => 4.03,
        'List::Util'   => 1.55,
        'Scalar::Util' => 1.55,
    },
    PM                => {},
    INST_BIN          => 'scripts',
    INST_SCRIPT       => 'configs',
    INSTALLSITESCRIPT => $conf_dir,
    INSTALLSITEBIN    => $bin_dir,
    ABSTRACT_FROM     => 'lib/Kronometrix.pm',
    AUTHOR            => 'Kronometrix Support <support@kronometrix.com>',
);

our $include = do './config.pl';
my @pm_files = ('lib/Kronometrix.pm');

# Remove existing files from scripts and configs directories
unlink glob 'scripts/*';
unlink glob 'configs/*';

if ($include->{all} || $include->{webrec}) {
    push @pm_files, 
        'lib/Kronometrix/Webrec/Queue.pm',
        'lib/Kronometrix/Webrec/Request.pm'; 
    $config{PREREQ_PM}{'Net::Curl'} = 0.37;
    $config{PREREQ_PM}{'Time::HiRes'} = 1.9764;
    $config{PREREQ_PM}{'HTML::TokeParser'} = 3.76;
    cp('all_scripts/webrec','scripts/')
        or die "Script webrec was not found";
    cp('all_configs/webrec.json', 'configs/')
        or die "Configuration for webrec was not found";
};

if ($include->{all} || $include->{svcrec}) {
    push @pm_files, 
        'lib/Kronometrix/Svcrec.pm',
        'lib/Kronometrix/Svcrec/Probe.pm', 
        'lib/Kronometrix/Svcrec/Probe/DHCP.pm',
        'lib/Kronometrix/Svcrec/Probe/NTP.pm';
    $config{PREREQ_PM}{'Net::Ping'} = 2.59;
    cp('all_scripts/svcrec','scripts/')
        or die "Script svcrec was not found";
    cp('all_configs/svcrec.json', 'configs/')
        or die "Configuration for svcrec was not found";
};

if ($include->{all} || $include->{snmprec}) {
    push @pm_files, 
        'lib/Kronometrix/Snmprec.pm';
    $config{PREREQ_PM}{'Net::SNMP'} = 6.0.1;
    cp('all_scripts/snmprec','scripts/')
        or die "Script snmprec was not found";
    cp('all_configs/snmprec.json', 'configs/')
        or die "Configuration for snmprec was not found";
};

if ($include->{all} || $include->{sockrec}) {
    push @pm_files, 
        'lib/Kronometrix/Snmprec.pm';
    $config{PREREQ_PM}{'Tie::IxHash'} = 0;
    $config{PREREQ_PM}{'IO::Async::Listener'} = 0;
    $config{PREREQ_PM}{'IO::Async::Socket'} = 0;
    $config{PREREQ_PM}{'IO::Async::Loop'} = 0;
    $config{PREREQ_PM}{'Proc::Daemon'} = 0;
    $config{PREREQ_PM}{'Proc::PID::File'} = 0;
    $config{PREREQ_PM}{'Getopt::Std'} = 0;
    cp('all_scripts/sockrec','scripts/')
        or die "Script sockrec was not found";
    cp('all_configs/sockrec.json', 'configs/')
        or die "Configuration for sockrec was not found";
};

foreach my $from (@pm_files) {
    my $to = $from;
    $to =~ s/^lib/\$\(INST_LIB\)/;
    $config{PM}{$from} =  $to;
}

WriteMakefile(%config);

