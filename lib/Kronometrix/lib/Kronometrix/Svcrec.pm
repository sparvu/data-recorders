package Kronometrix::Svcrec;

use Kronometrix::Svcrec::Probes;
use Net::Ping;
use Time::HiRes qw(time sleep);
use IO::Poll qw(POLLIN POLLOUT POLLERR POLLHUP);
use IO::Socket::INET;
use Carp;
use parent 'Kronometrix';
use strict;
use warnings;
use feature ':5.24';

our $VERSION = 0.08;

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
        foreach my $service ($server->{service}->@*) {
            my %srv;
            $srv{$_} = $server->{$_}  foreach qw(name description zone);
            $srv{$_} = $service->{$_} foreach qw(id host port);

            $srv{type} = uc $service->{type};

            if ($server->{name}) {
                $srv{name}   = join('_', $server->{name}, $service->{id});
                $srv{siteid} = $server->{name};
            }
            else  {
                $srv{siteid} = $service->{id};
            }

            if (exists $service->{protocol}
                and uc $service->{protocol} eq 'UDP') {
                $srv{protocol} = 'udp';
                push $self->{queue_udp}->@*, \%srv;
                $self->{total_udp}++;
            }
            else {
                # tcp protocol by default
                $srv{protocol} = 'tcp';
                push $self->{queue}->@*, \%srv;
                $self->{total}++;
            }

            $self->write_debug(
                "Debug: Added $srv{name} - $srv{id} to the $srv{protocol} queue");
        }
    }

    $self->write_debug('Debug: Service definition file has been parsed');
}

sub process {
    my $self = shift;

    $self->process_tcp if $self->{queue}->@* > 0;
    $self->process_udp if $self->{queue_udp}->@* > 0;
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
        sleep $self->{nap_time} if $self->{nap_time};
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

    $self->{index} = 0;
    $self->{report_queue} = [];
    $self->{report_next}  = 0;

    my %pinged;
    while ($self->{index} < $self->{total_udp}) {
        $self->write_debug('Debug: Processing UDP cycle at '
            . sprintf("%.2f", 100 * $self->{index} / $self->{total_udp})
            . "% of the queue (index: $self->{index})"
        );

        # Ping the next max_concurrent servers
        my $n = $self->{max_concurrent} + $self->{index};
        $n = $self->{total_udp} if $n > $self->{total_udp};

        while ($self->{index} < $n) {
            my $service       = $self->{queue_udp}[ $self->{index} ];
            my ($host, $port) = @$service{qw(host port)};

            my %inet = (
                PeerAddr => "$host:$port",
                Blocking => 0,
                Timeout  => $self->{timeout},
                Proto    => 'udp',
                Type     => SOCK_DGRAM,
            );

            my $sock = IO::Socket::INET->new(%inet);
            my $t0 = time;

            if (defined $sock) {
                my $probe =
                    Kronometrix::Svcrec::Probes->probe_for_port($port);

                unless (defined $probe) {
                    $self->write_log(
                        "Error: probe for UDP $port does not exist");
                    $probe = "\0";
                }


                $poll->mask($sock => POLLIN);
                $sock->send($probe);
                $self->write_debug("Debug: Sent ping to $host:$port");
            }
            else {
                $self->write_debug("Debug: Failed ping to $host:$port");
                $sock = "$host:$port";
            }

            $pinged{$sock} = {
                service => $service,
                index   => $self->{index},
                t       => $t0
            };

            $self->{index}++;
        }

        # Get the resulting acknowledgements
        my $tout = $self->{timeout};
        $self->write_debug("Note: Looking for acknowledgements");

        # Poll at least once. If this is the last iteration (index > total_udp)
        # then poll until the last request is timed out
        do {
            $poll->poll($tout);
            foreach my $sock ($poll->handles(POLLIN)) {
                $poll->remove($sock);
                eval { $sock->shutdown( 2 ) };

                my $ping = delete $pinged{$sock};
                $self->write_debug("Debug: Received ack from $ping->{service}{name}");
                $ping->{duration} = time - $ping->{t};
                $self->process_report($ping);
            }

            # Remove handles with errors or hanged up
            foreach my $sock ($poll->handles(POLLERR | POLLHUP)) {
                my $ping = $pinged{$sock};
                $self->write_debug("Debug: Error event from $ping->{service}{name}");
                $poll->remove($sock);
            }

            # Remove handles whose timeout has passed
            foreach my $sock ($poll->handles()) {
                if (time > $pinged{$sock}->{t} + $tout) {
                    my $ping = $pinged{$sock};
                    $self->write_debug("Debug: Time out for $ping->{service}{name}");
                    $poll->remove($sock);
                    $self->write_debug("Debug: Remaining handles: " . scalar $poll->handles);
                }
            }
        }
        while ($poll->handles > 0 && $self->{index} >= $self->{total_udp});

        sleep $self->{nap_time} if $self->{nap_time};
    }

    # Failed pings remain in the %pinged hash
    $self->write_debug(
          'Debug: There are ' . scalar(keys(%pinged))
        . ' failed pings to process in the UDP queue'
    );

    foreach my $ping (values %pinged) {
        $ping->{duration} = 0;
        $self->process_report($ping);
    }
}

sub process_report {
    my ($self, $ping) = @_;

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
    my ($self, $saved, $duration) = @_;
    my $service = $saved->{service};
    my $t0      = $saved->{t};
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

