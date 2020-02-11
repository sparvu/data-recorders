package Kronometrix::Svcrec::Probe;

use Data::Dumper;
use Time::HiRes qw(time sleep);
use IO::Poll qw(POLLIN POLLOUT POLLERR POLLHUP);
use IO::Socket::INET;
use parent Kronometrix;
use strict;
use warnings;

# This package defines an interface for sending and receiving udp probes.

sub new {
    my ($class, $service, $index, $log) = @_;

    my $obj = {
        service => $service,
        index   => $index,
        verbose => 0,
        debug   => 0,
    };

    $obj->{verbose}++ if $log == 1;
    $obj->{debug}++   if $log == 2;

    bless $obj, $class;

    $obj->{delay} = $obj->service->{delay} // 0.1;
    $obj->init;
    $obj->reset;

    $obj->write_debug("Debug: Created new probe for " . $obj->name
        . " class $class");

    return $obj;
}

sub init {
    my $obj = shift;
    $obj->write_debug("Debug: Using base init for " . $obj->name);
    return $obj;
}

sub name {
    my $self = shift;
    return $self->{service}{name};
}

sub service {
    my $self = shift;
    return $self->{service};
}

sub index {
    my $self = shift;
    return $self->{index};
}

sub time_sent {
    my ($self, $t0) = @_;
    if (defined $t0) {
        $self->{t} = $t0;
        $self->timeout(0.1);
    }
    return $self->{t};
}

sub duration {
    my ($self, $d) = @_;
    $self->{duration} = $d if defined $d;
    return $self->{duration};
}
sub set_duration {
    my $self = shift;
    $self->{duration} = time - $self->time_sent;
}

sub timeout {
    my $self = shift;
    return $self->{timeout};
}

sub set_timeout {
    my $self = shift;
    $self->{timeout} = time + $self->{delay};
    return $self->{timeout};
}

sub inc_tries {
    my $self = shift;
    $self->{tries}++;
    return $self->{tries};
}

sub tries {
    my $self = shift;
    return $self->{tries};
}

sub failed {
    my $self = shift;
    return $self->{failed};
}

sub socket {
    my ($self, $sock) = @_;
    $self->{socket} = $sock if defined $sock;
    return $self->{socket};
}

sub remove_socket {
    my $self = shift;
    $self->{socket} = undef;
}

# Default socket parameters. Override if needed
sub socket_params {
    my $self = shift;
    my $service = $self->{service};
    my ($host, $port) = @$service{qw(host port)};
    my %inet = (
        PeerAddr => $host,
        PeerPort => $port,
        Blocking => 0,
        Timeout  => $self->timeout,
        Proto    => 'udp',
        Type     => SOCK_DGRAM,
    );
    return %inet;
}

# Builds a socket for a ping object
sub build_socket {
    my $self = shift;
    my %inet = $self->socket_params;
    my $sock = IO::Socket::INET->new(%inet);

    if (!defined $sock) {
        $self->write_debug("Debug: Failed creating socket to " . $self->name);
        $self->{failed}++;
        $sock = $self->name;
    }
    $self->socket($sock);
    return $sock;
}

sub probe {
    my $self = shift;
    $self->{failed}++;
    $self->write_debug("Debug: Probe for " . $self->name . " is not defined");
}

sub send_probe {
    my ($self, $poll) = @_;
    my $probe = $self->probe;
    my $sock  = $self->build_socket;
    if (!$self->failed) {
        $poll->mask($sock => POLLIN);
        $sock->send($probe);
        $self->write_debug("Debug: Sent ping to " . $self->name);
    }
    $self->time_sent(time);
    return $sock;
}

# This method may be overriden if clean up is required, or if validation
# is required.
sub receive_response {
    return 1;
}

sub reset {
    my $self          = shift;
    $self->{t}        = undef;
    $self->{timeout}  = time - 1;
    $self->{socket}   = undef;
    $self->{tries}    = 0;
    $self->{duration} = undef;
    $self->{failed}   = 0;
}

1;
