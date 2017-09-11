package Kronometrix::Svcrec;

use Net::Ping;
use Time::HiRes qw(sleep);
use Carp;
use parent 'Kronometrix';
use strict;
use warnings;
use feature ':5.24';

our $VERSION = 0.06;

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
        queue                   => [],
        index                   => 0,
        total                   => 0,
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

            push $self->{queue}->@*, \%srv;
            $self->{total}++;

            $self->write_debug(
                "Debug: Added $srv{name} - $srv{id} to the queue");
        }
    }

    $self->write_debug('Debug: Service definition file has been parsed');
}

sub process {
    my $self = shift;

    $self->{index} = 0;

    if ($self->{max_concurrent} > 1) {
        $self->{report_queue} = [];
        $self->{report_next}  = 0;
        $self->process_async;
    }
    else {
        $self->process_sync;
    }
}

sub process_sync {
    my $self = shift;

    $self->write_verbose('Note: Starting serial processing cycle');

    while ($self->{index} < $self->{total}) {
        $self->write_debug('Debug: Processing cycle at '
            . sprintf("%.2f", 100 * $self->{index} / $self->{total})
            . '% of the queue'
        );

        my $t0 = time;
        my $service = $self->{queue}[ $self->{index} ];

        my $p = Net::Ping->new('tcp');
        $p->hires;
        $p->port_number($service->{port});
        my ($status, $duration, $ip);
        eval {
            ($status, $duration, $ip) =
                $p->ping($service->{host}, $self->{timeout});
            $p->close;
        };

        if ($@) {
            $self->write_log("Error: Failed sending ping to host "
                . $service->{host}
                . " port " . $service->{post}
                . " : $@"
            );
            next;
        }

        my %saved = (
            service => $service,
            t       => time()
        );
        $self->write_report(\%saved, $duration);
        $self->{index}++;
        $self->write_debug(
            "Debug: Sent ping to " . $service->{host}
            . ":" . $service->{port}
            . " (duration: $duration)"
        );
        sleep $self->{nap_time} if $self->{nap_time};
    }
}

sub process_async {
    my $self = shift;

    $self->write_verbose('Note: Starting asynchronous processing cycle');

    my %pinged;
    while ($self->{index} < $self->{total}) {
        $self->write_debug('Debug: Processing cycle at '
            . sprintf("%.2f", 100 * $self->{index} / $self->{total})
            . '% of the queue'
        );

        # Ping the next max_concurrent servers
        my $n = $self->{max_concurrent} + $self->{index};
        $n = $self->{total} - 1 if $n > $self->{total} - 1;
        my $t0 = time;
        my $p = Net::Ping->new('syn');
        while ($self->{index} <= $n) {
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

sub process_report {
    my ($self, $ping) = @_;

    my $queue = $self->{report_queue};
    push @$queue, $ping;
    @$queue = sort { $a->{index} <=> $b->{index} } @$queue;

    while (@$queue && $self->{report_next} == $queue->[0]{index}) {
        my $next = shift @$queue;
        $self->write_report($next, $next->{duration});
        $self->write_debug("Debug: Just reported " . $next->{index});
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

