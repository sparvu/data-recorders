package Kronometrix::Svcrec::Probe::DHCP;

use Data::Dumper;
use Socket;
use parent Kronometrix::Svcrec::Probe;
use strict;
use warnings;
use feature ':5.24';

sub init {
    my $self = shift;

    # Get string for client ip address or hostname
    $self->{client} = inet_aton $self->service->{local_addr};

    # Split mac address
    my @mac_addr = map { hex $_ } split ':', $self->service->{mac_addr};
    $self->{mac} = \@mac_addr;

    $self->write_debug("Debug: Instantiated DHCP probe for "
        . $self->name)
}

# DHCP uses two different ports: It sends by 67 and receives on 68
sub socket_params {
    my $self = shift;
    my $service = $self->{service};
    my ($host, $port, $lhost, $lport, $mac) =
        @$service{qw(host port local_addr local_port mac_addr)};
    my %inet = (
        PeerAddr  => $host,
        PeerPort  => $port,
        LocalAddr => $lhost,
        LocalPort => $lport,
        Blocking  => 0,
        Timeout   => $self->timeout,
        Proto     => 'udp',
        Type      => SOCK_DGRAM,
    );
    $self->write_debug("Debug: Set socket parameters for DHCP probe for "
        . $self->name);
    return %inet;
}

# The DHCP message was taken from Net::DHCP::Watch
sub probe {
    my $self = shift;

    # Transaction id
    my $xid = int(rand(2**32-1));
    $self->{xid} = $xid;

    # DHCP Message: Fixed-Format + Options
    # (see Droms & Lemon, 1999, Apendixes C and D).
    my @fields = (
        1,                # op
		1,                # htype
        6,                # hlen
        0,                # hops
        $self->{xid},     # xid
        0,                # secs
        0,                # flags
        $self->{client},  # ciaddr
        0,                # yiaddr
        0,                # siaddr
        0,                # giaddr
        $self->{mac}->@*, # chaddr
        0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0,
        "\0",             # sname
        "\0",             # file
        99,130,83,99,     # Magic cookie (RFC)
		53,               # option1 = DHCP-Message
        1,                # length1 = 1
        3,                # value1  = DHCPREQUEST
    );
    my $query = pack(
         # It's horrible, but it works
         'CCCCNnna4NNNCCCCCCCCCCCCCCCCa64a128C*',
         @fields
    );
    $self->write_debug("Debug: Set DHCP probe for " . $self->name);
    return $query;
}

1;
