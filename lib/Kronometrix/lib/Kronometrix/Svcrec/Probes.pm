package Kronometrix::Svcrec::Probes;

use strict;
use warnings;

# Hash of UDP probes for Svcrec. Keyed by port number, values are probes
my %hash_of_probes = ();

# Hash of UDP probe generators
my %build_probe_for = ();

# Probe for NTP protocol -- Requests time from port 123
$build_probe_for{123} = sub {
    return "\010" . "\0" x 47;
};

# Interface with this module
sub probe_for_port {
    my ($class, $port) = @_;

    return $hash_of_probes{$port}
        if exists $hash_of_probes{$port};

    my $probe;
    if (exists $build_probe_for{$port}) {
        $probe = $build_probe_for{$port}->();
        $hash_of_probes{$port} = $probe;
    }
    return $probe;
}

1;
