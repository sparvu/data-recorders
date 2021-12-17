use ExtUtils::MakeMaker;
use Data::Dumper;
use strict;
use warnings;
use 5.024000;

my %config = (
    NAME              => 'Kronometrix',
    VERSION_FROM      => 'lib/Kronometrix.pm', 
    PREREQ_PM         => {
		'JSON'         => 4.03,
        'List::Util'   => 1.55,
        'Scalar::Util' => 1.55,
    },
    PM                => {},
    ABSTRACT_FROM     => 'lib/Kronometrix.pm',
    AUTHOR            => 'Kronometrix Support <support@kronometrix.com>',
);

our $include = do './config.pl';
my @pm_files = ('lib/Kronometrix.pm');

if ($include->{all} || $include->{webrec}) {
    push @pm_files, 
        'lib/Kronometrix/Webrec/Queue.pm',
        'lib/Kronometrix/Webrec/Request.pm'; 
    $config{PREREQ_PM}{'Net::Curl'} = 0.37;
    $config{PREREQ_PM}{'Time::HiRes'} = 1.9764;
    $config{PREREQ_PM}{'HTML::TokeParser'} = 3.76;
};

if ($include->{all} || $include->{svcrec}) {
    push @pm_files, 
        'lib/Kronometrix/Svcrec.pm',
        'lib/Kronometrix/Svcrec/Probe.pm', 
        'lib/Kronometrix/Svcrec/Probe/DHCP.pm',
        'lib/Kronometrix/Svcrec/Probe/NTP.pm';
    $config{PREREQ_PM}{'Net::Ping'} = 2.59;
};

if ($include->{all} || $include->{snmprec}) {
    push @pm_files, 
        'lib/Kronometrix/Snmprec.pm',
    $config{PREREQ_PM}{'Net::SNMP'} = 6.0.1;
};

foreach my $from (@pm_files) {
    my $to = $from;
    $to =~ s/^lib/\$\(INST_LIB\)/;
    $config{PM}{$from} =  $to;
}

WriteMakefile(%config);

