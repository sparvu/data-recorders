package Kronometrix::Svcrec;

use Data::Dumper;
use Net::Ping;
use Time::HiRes qw(time sleep);
use IO::Poll qw(POLLIN POLLOUT POLLERR POLLHUP);
use IO::Socket::INET;
use Carp;
use parent 'Kronometrix';
use strict;
use warnings;
use feature ':5.24';

our $VERSION = 0.09;

sub new {
    my ($class, @args) = @_;
    my %args_hash = (
        max_concurrent_requests => 1,
        timeout                 => 5,
        precision               => 0,
        nap_time                => 0,
        verbose                 => 0,
        debug                   => 0,
        config_file             => 'svcrec.json',

        # tcp protocol
        queue                   => [],
        total                   => 0,
        # udp protocol
        queue_udp               => [],
        total_udp               => 0,

        # hash of retries per server
        retries_for             => {},

        index                   => 0,
        @args
    );

    $args_hash{max_concurrent} =
        delete $args_hash{max_concurrent_requests};

    $args_hash{template} =
        "%." . $args_hash{precision} . "f:%s:%s:%s:%s:%s:%d\n";

    my $self = bless \%args_hash, $class;

    $self->write_verbose(
        "Info: Kronometrix::Svcrec object has been created");

    $self->build_requests;

    return $self;
}

# Read and flatten the configuration file
sub build_requests {
    my $self = shift;

    $self->write_debug('Debug: Parsing service definition file');
    my $conf = $self->open_config($self->{config_file});

    foreach my $server ($conf->{server}->@*) {

        # Retries and delays for UDP processing
        $self->{retries_for}{$server->{name}} =
            $server->{retry_count} // 3;

        foreach my $service ($server->{service}->@*) {

            $service->{server} = $server->{name};
            $service->{zone}   = $server->{zone};
            $service->{type}   = uc $service->{type};
            $service->{delay}  = defined $server->{delay}
                ? $server->{delay} : 0.1;


            if ($server->{name}) {
                $service->{name}   = join('_', $server->{name}, $service->{id});
                $service->{siteid} = $server->{name};
            }
            else  {
                $service->{siteid} = $service->{id};
            }

            if (exists $service->{protocol}
                and uc $service->{protocol} eq 'UDP') {
                $service->{protocol} = 'udp';
                my $class = "Kronometrix::Svcrec::Probe::$service->{type}";
                eval "require $class";
                $self->write_debug("Debug: Loaded $class");
                my $log = 0;
                $log = 1 if $self->{verbose};
                $log = 2 if $self->{debug};
                my $ping  = $class->new($service, $self->{total_udp}, $log);
                push $self->{queue_udp}->@*, $ping;
                $self->{total_udp}++;
            }
            else {
                # tcp protocol by default
                $service->{protocol} = 'tcp';
                push $self->{queue}->@*, $service;
                $self->{total}++;
            }

            $self->write_debug(
                  "Debug: Added $service->{name} - $service->{id} to the "
                . $service->{protocol}
                . " queue");
        }
    }

    $self->write_debug('Debug: Service definition file has been parsed');
}

sub process {
    my $self = shift;

    $self->process_tcp if $self->{queue}->@* > 0;
    $self->process_udp if $self->{queue_udp}->@* > 0;

    if ($self->{nap_time}) {
        $self->write_debug("Debug: Sleeping for $self->{nap_time} seconds");
        sleep $self->{nap_time};
    }
}

sub process_tcp {
    my $self = shift;

    $self->write_verbose(
        'Note: Starting asynchronous processing cycle, tcp');

    $self->{index} = 0;
    $self->{report_queue} = [];
    $self->{report_next}  = 0;

    my %pinged;
    while ($self->{index} < $self->{total}) {
        $self->write_debug('Debug: Processing TCP cycle at '
            . sprintf("%.2f", 100 * $self->{index} / $self->{total})
            . '% of the queue'
        );

        # Ping the next max_concurrent servers
        my $n = $self->{max_concurrent} + $self->{index};
        $n = $self->{total} if $n > $self->{total};

        my $t0 = time;
        my $p = Net::Ping->new('syn');
        while ($self->{index} < $n) {
            my $service       = $self->{queue}[ $self->{index} ];
            my ($host, $port) = @$service{qw(host port)};

            $p->hires;
            $p->port_number($port);

            eval {
                $p->ping($host, $self->{timeout});
            };
            if ($@) {
                $self->write_log("Error: Failed sending ping to host "
                    . " $host port $port: $@"
                );
                next;
            }

            $pinged{"$host:$port"} = {
                service => $service,
                index   => $self->{index},
                t       => $t0
            };

            $self->{index}++;
            $self->write_debug("Debug: Sent ping to $host:$port");
        }

        # Get the resulting acknowledgements
        $self->write_debug('Note: Looking for acknowledgements');
        while (my ($host,$duration, $ip, $port) = $p->ack) {
            my $acked = delete $pinged{"$host:$port"};
            $acked->{duration} = $duration;
            $self->write_debug("Debug: Received ack from $host:$port (duration: $duration)");

            # Print the report ensuring the correct order
            $self->process_report($acked);
        }
    }

    # Failed pings remain in the %pinged hash
    $self->write_debug(
          'Debug: There are ' . scalar(keys(%pinged))
        . ' failed pings to process'
    );
    foreach my $ping (values %pinged) {
        $ping->{duration} = 0;
        $self->process_report($ping);
    }
}

sub process_udp {
    my $self = shift;

    $self->write_verbose(
        'Note: Starting asynchronous processing cycle, udp');

    my $poll = IO::Poll->new;

    $self->{index}        = 0;
    $self->{report_next}  = 0;
    $self->{report_queue} = [];

    my $queue      = $self->{queue_udp};
    my $n          = $self->{max_concurrent} // 1;
    my $index      = 0;                # Index of latest service in the queue
    my %ping_for;                      # Keyed by service index
    my %service_for;                   # Keyed by socket object

    do {
        # Always have $n pending pings in process
        while (keys %ping_for < $n && $index < @$queue) {
            my $ping = $queue->[$index];
            $ping->reset;
            $ping_for{$index} = $ping;
            $index++;
        }

        # Test each service
        my $t = time;
        foreach my $ping (values %ping_for) {
            next if $ping->timeout > $t;

            # Test the service
            my $try = $ping->inc_tries;
            $self->write_debug("Debug: Sending message to "
                . $ping->name . " (tries: $try)");
            my $sock = $ping->send_probe($poll);
            $service_for{$sock} = $ping->index;
        }

        # Poll at least once
        my $tout = $self->{timeout};
        $poll->poll($tout);

        # Process acknowledgements
        foreach my $sock ($poll->handles(POLLIN)) {
            $poll->remove($sock);
            eval { $sock->shutdown( 2 ) };
            my $sid  = delete $service_for{$sock};
            my $ping = delete $ping_for{$sid};
            $self->write_debug("Debug: Received ack from "
                . $ping->name);
            $ping->set_duration;
            $self->process_report($ping);
        }

        # Remove handles with errors or hanged up
        foreach my $sock ($poll->handles(POLLERR | POLLHUP)) {
            my $sid  = delete $service_for{$sock};
            my $ping = delete $ping_for{$sid};
            $self->write_debug(
                "Debug: Error event from " . $ping->name);
            $poll->remove($sock);
        }

        # Remove timed out handles after tries are exhausted
        foreach my $sock ($poll->handles()) {
            my $sid  = $service_for{$sock};
            my $ping = $ping_for{$sid};
            if (not defined $ping) {
                delete $service_for{$sock};
                $poll->remove($sock);
                next;
            }
            my $max_tries = $self->{retries_for}{$ping->service->{server}};
            if ($ping->tries >= $max_tries && time > $ping->timeout) {
                $self->write_debug("Debug: Removing timed out " . $ping->name);
                $poll->remove($sock);
                delete $service_for{$sock};
                delete $ping_for{$sid};
                $ping->duration(0);
                $self->process_report($ping);
            }
        }

        # Remove failed sockets
        foreach my $ping (values %ping_for) {
            my $max_tries = $self->{retries_for}{$ping->service->{server}} // 3;
            next unless $ping->failed && $ping->tries >= $max_tries;

            $self->write_debug("Debug: Removing failed " . $ping->name);
            my $sock = $ping->socket;
            my $sid  = delete $service_for{$sock};
            delete $ping_for{$sid};
            $ping->duration(0);
            $self->process_report($ping);
        }

        $self->write_debug("Debug: Remaining handles: "
            . scalar $poll->handles);
    }
    while (keys %ping_for || $index < @$queue);
}

sub process_report {
    my ($self, $ping) = @_;

    $self->write_debug("Debug: About to issue report for "
        . $ping->{service}{name}
        . " (index: $ping->{index})");

    my $queue = $self->{report_queue};
    push @$queue, $ping;
    @$queue = sort { $a->{index} <=> $b->{index} } @$queue;

    while (@$queue && $self->{report_next} == $queue->[0]{index}) {
        my $next = shift @$queue;
        $self->write_report($next, $next->{duration});
        $self->write_debug("Debug: Just reported service index "
            . $next->{index});
        $self->{report_next}++;
    }
}

sub write_report {
    my ($self, $ping, $duration) = @_;
    my $service = $ping->{service};
    my $t0      = $ping->{t};
    my $idn     = $service->{name} || $service->{id};
    my $status  = $duration ? 1 : 0;
    my $pktime  = $status ?
        sprintf ("%.2f", 1000 * $duration) : 'NA';
    my ($type, $port, $siteid, $zone) =
        map { $service->{$_} } qw(type port siteid zone);
    my $proto   = "$type($port)";
    printf $self->{template},
        $t0, $idn, $pktime, $siteid, $zone, $proto, $status;
}

1;

__END__

=pod

=head1 NAME

Kronometrix::Svcrec - Test the reachability of a remote host

=head1 SYNOPSIS

 use Kronometrix::Svrec;

 my $svcrec = Kronometrix::Svcrec->new(
    config_file             => 'svcrec.json',
    max_concurrent_requests => $num_concurrent_reqs,
    timeout                 => 5,
    precision               => $precision,
    verbose                 => $verbose,
    debug                   => $debug,
 );

 $svcrec->process;

=head1 DESCRIPTION

This module implements a Kronometrix service that monitors the reachability of remote hosts using Net::Ping. It allows for asynchronous tests.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

FRAIRE, E<lt>julio@(none)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by FRAIRE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
