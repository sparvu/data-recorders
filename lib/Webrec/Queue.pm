package Kronometrix::Webrec::Queue;

use Kronometrix::Webrec::Request;
use Net::Curl::Multi qw(:constants);
use List::Util qw(first);
use Scalar::Util qw(weaken refaddr);
use JSON;
use Time::HiRes qw(time);
use Carp;
use strict;
use warnings;
use feature ':5.10';

our $VERSION = 'v1.1.4.0';

sub new {
    my ($class, @args) = @_;
    my %args_hash = (
        max_concurrent_requests => 1,
        timeout                 => 60,
        precision               => 0,
        verbose                 => 0,
        debug                   => 0,
        num_active_reqs         => 0,
        store_active_reqs       => {},
        report                  => [],
        index                   => 0,
        num_reqs                => 0,
        cert_location           => '/etc/ssl/certs/ca-certificates.crt',
        @args
    );

    $args_hash{max_concurrent} = delete $args_hash{max_concurrent_requests};

    croak "config_file is required for $class"
        unless defined $args_hash{config_file};

    croak "agent_name is required for $class"
        unless defined $args_hash{agent_name};

    my $self = bless \%args_hash, $class;

    $self->write_log("Info: Started");
    $self->write_verbose("cURL version: " . Net::Curl::version());
    $self->build_requests;

    return $self;
}

sub is_async {
    my $self = shift;
    return $self->{max_concurrent} > 1;
}

# Get workloads defintion. It is a hash keyed by host name; values
# are an array ref of code references that will build Webrec::Requests.
# Works on the data structure stored in the configuration file.
sub build_requests {
    my $self = shift;
    
    $self->write_verbose("Building request queue");

    my %workloads;
    my $data = $self->open_config($self->{config_file});    
    my @temp = @{ $data->{'workloads'} };

    # For each workload...
    foreach my $f (@temp) {
        # Get its parameters
        my ($ka, $wname, $desc, $delay, $proxy) = map { $f->{$_} }
            qw(keepalive name description delay proxy);

        # For each request of the workload...
        my @reqs = @{ $f->{'requests'} };
        foreach my $req (@reqs) {
            my ($rname, $met, $scm, $hst, $prt, $pth) = map { $req->{$_} }
                qw(id method scheme host port path);

            my $post = '';
            if ( $met eq 'POST' && $req->{post}) {
                $post = $req->{'post'};
            }

            # Build a request object and save it in the queue
            my $r = Kronometrix::Webrec::Request->new(
                keepalive    => $ka,
                workload     => $wname,
                description  => $desc,
                delay        => $delay,
                proxy        => $proxy,
                request_name => $rname,
                method       => $met,
                scheme       => $scm,
                host         => $hst,
                port         => $prt,
                path         => $pth,
                post         => $post,
                precision    => $self->{precision},
                timeout      => $self->{timeout},
                agent_name   => $self->{agent_name},
                verbose      => $self->{debug},
                webrec_queue => $self,
            );
            
            # Push the request into the queue
            push @{ $self->{queue} }, $r;
            $self->{num_reqs}++;
            $self->write_verbose(
                "Built request object for " . $r->{initial_url});
        }
    }

    $self->{host_requests} = \%workloads;

    $self->write_verbose("Built " . $self->{num_reqs} . " request objects");
}

# Adds requests to the curl multi object
sub add_requests {
    my $self = shift;

    while (
           $self->{num_active_reqs} < $self->{max_concurrent} 
        && $self->{index} < $self->{num_reqs}
    ) {
        # Get the next request in the queue
        my $req = $self->{queue}[$self->{index}];
        $self->{index}++;

        # Add easy handle to multi object
        $self->add_handle($req);
        $self->{num_active_reqs}++;

        $self->write_verbose("Added request for " . $req->{initial_url});
    }
}

# Get curl easy handler and feed it to the multi object.
# Store a weak copy of the request to be retrieved afterwards
sub add_handle {
    my ($self, $req) = @_;
    my $easy = $req->init;
    
    # Put request in hashed active reqs store
    my $addr = refaddr $easy;
    $self->{store_active_reqs}{ $addr } = $req;
    weaken $self->{store_active_reqs}{ $addr };
    
    # Save its place in the results report
    push $self->{report}->@*, { 
        url  => $req->{initial_url}, 
        line => undef
    };
    
    # Put the easy handle in the curl multi object
    $self->{multi}->add_handle($easy) if $self->is_async;
}

sub remove_request {
    my ($self, $easy) = @_;
    
    # Remove the easy handle from the curl multi object
    $self->{multi}->remove_handle($easy) if $self->is_async;
    $self->{num_active_reqs}--;

    # Remove the request from the hashed active reqs store
    my $addr = refaddr $easy;
    my $req  = delete $self->{store_active_reqs}{$addr};
    
    # Put request's line in the report
    my $url  = $req->{initial_url};
    my $line = $req->write_report;
    my $rep  = first { $_->{url} eq $url } $self->{report}->@*;
    $rep->{line} = $line;
    
    # Go through the report and print the lines which are ready
    # until we find one which istn't
    while ($self->{report}->@* && defined $self->{report}[0]{line}) {
        my $r = shift $self->{report}->@*;
        say $r->{line};
    }
        
    return $req;
}

sub init {
    my $self = shift;
    $self->{multi} = $self->is_async ? Net::Curl::Multi->new : undef;
    $self->{index} = 0;
}

sub process {
    my $self = shift;
    if ($self->is_async) {
        $self->process_async;
    }
    else {
        $self->process_sync;
    }
}

sub process_sync {
    my $self = shift;
    $self->write_verbose("Starting new synchronous request cycle");

    $self->init;
    
    foreach my $req ($self->{queue}->@*) {
        eval {
            my $easy = $req->init;
            $easy->perform;
        };
        if ($@) {
            if (ref $@ eq 'Net::Curl::Easy::Code') {
                $self->write_log("Error while processing request for "
                    . $req->{initial_url}
                    . " - Error code: " . (0+$@)
                    . " - Error message: $@");
            }
            else {
                die "Unexpected error: <$@>";
            }
        }
        else {
            $self->write_verbose("Request " 
                . $req->{initial_url}
                . " has been executed, elapsed "
                . $req->total_time
                . " ms"
            );
        }
        say $req->write_report;
        $req->clear_easy;
    }    
    $self->write_verbose("Finished request cycle");
}

            
sub process_async {
    my $self = shift;

    $self->write_verbose("Starting new asynchronous request cycle");

    $self->init;
    
    do {
        $self->add_requests;

        eval {
            my ($fdr,$fdw,$fde) = $self->{multi}->fdset;
            
            my $timeout = $self->{multi}->timeout / 1000; 
            select($fdr,$fdw,$fde, $timeout) if $timeout > 0;

            my $active;
            $active = $self->{multi}->perform;
        };
        if ($@) {
            if (ref $@ eq 'Net::Curl::Multi::Code') {
                $self->write_log("Error while processing requests"
                    . " - Error code: " . (0+$@)
                    . " - Error message: $@");
            }
            else {
                die "Unexpected error: <$@>";
            }
        }

        while (my ($msg, $easy, $r) = $self->{multi}->info_read) {
            my $req = $self->remove_request($easy);
            if ($r == 0) {
                $self->write_verbose("Request " 
                    . $req->{initial_url}
                    . " has been executed, elapsed "
                    . $req->total_time
                    . " ms"
                );
            }
            else {
                $self->write_log("Error with response: "
                    . $req->{initial_url}
                    . " - Error code: " . (0+$r)
                    . " - Error message: $r"
                );
            }
            $req->clear_easy;
            $self->write_verbose(
                "Report lines waiting: " . scalar $self->{report}->@*);
        }

    } while $self->{index} < $self->{num_reqs} || $self->{num_active_reqs} > 0;
    
    # Clean after Net::Curl::Multi to avoid memory leaks
    $self->{multi} = undef;
    $self->write_verbose("Finished request cycle");
}

# Open JSON configuration file
sub open_config {
    my ($class, $conf) = @_;

    my $json_data;

    {
        local $/;

        # We will parse now the file
        if ( defined $ENV{'KRMX_PREFIX'} ) {
            if ( -e "$ENV{'KRMX_PREFIX'}/etc/$conf" ) {
                open my $fh, "<", "$ENV{'KRMX_PREFIX'}/etc/$conf";
                $json_data = <$fh>;
                close $fh;
            }
            else {
                die "error: $ENV{'KRMX_PREFIX'}/etc/$conf - file not found\n";
            }
        }
        else {
            if ( -e "/opt/kronometrix/etc/$conf" ) {
                open my $fh, "<", "/opt/kronometrix/etc/$conf";
                $json_data = <$fh>;
                close $fh;
            }
            else {
                die "error: /opt/kronometrix/etc/$conf - file not found\n";
            }
        }
    }

    my $perl_data = JSON->new->utf8->decode($json_data);

    return $perl_data;
}

# Write log message
sub write_log {
    my ($self, $logbuf) = @_;
    $self->_write_log($logbuf);
}

sub write_verbose {
    my ($self, $logbuf) = @_;
    return unless $self->{verbose};
    $self->_write_log($logbuf);
}

sub write_debug {
    my ($self, $logbuf) = @_;
    return unless $self->{debug};
    $self->_write_log($logbuf);
}

sub _write_log {
    my ($self, $logbuf) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
      localtime(time);

    my $dt = sprintf "%4d-%02d-%02d %02d:%02d:%02d",
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec;

    say STDERR "$dt $logbuf";
}


1;

=pod

=head1 NAME

Kronometrix::Webrec::Queue -- Queue of URL requests for Kronometrix

=head1 SYNOPSIS

 use Kronometrix::Webrec::Queue;

 my $queue = Kronometrix::Webrec::Queue->new(
    config_file             => 'webrec.json',
    max_concurrent_requests => 25,
    verbose                 => 0,
    same_host_delay         => 1,
 );
 
 $queue->process;

=head1 DESCRIPTION

This distribution implements a system of queues of URL requests. The goal is to measure the time it takes to complete each request. For each request, the following information is reported:

  01 timestamp : seconds since Epoch, time
  02 request   : the HTTP request name
  03 ttime     : total time the entire operation lasted, seconds
  04 ctime     : connect time it took from the start until the TCP 
                 connect to the remote host (or proxy) was completed, 
                 seconds
  05 dnstime   : namelookup time, it took from the start until the name 
                 resolving was completed, seconds
  06 ptime     : protocol time, it took from the start until the file 
                 transfer was just about to begin, seconds
  07 pktime    : first packet time, it took from the start until the 
                 first byte was just about to be transferred, seconds
  08 size      : page size, the total amount of bytes that were 
                 downloaded
  09 status    : response status code, the numerical response code 
                 that was found in the last retrieved HTTP(S) transfer

The system may send requests either sequentially or concurrently. It can also be configured to make a delay between requests to the same host and to limit the number of concurrent requests to the same host.

The system works by building one queue per host. There is a per-host request index to keep track of the requests which have been sent, and there is a hash of hosts that keeps track of the times at which host connections shall be freed to receive a new request, thus implementing delays between requests to the same host.

This module then delivers the L<Net::Curl::Easy> objects contained within requests to a L<Net::Curl::Multi> object which is responsible of performing the requests. The L<Net::Curl::Easy> objects are configured to obtain the desired measurements. Requests belong to the class L<Kronometrix::Queue::Request>.

=head1 USAGE

User programs should build a single object of this class, and then simply call the C<process> method. The configuration file will be read and the specified requests will be performed.

=head1 ATTRIBUTES

The following attributes may be given to the constructor:

=over

=item * config_file

Name of the configuration file. If the environment variable KRMX_PREFIX exists, the Kronometrix::Webrec::Queue object will look for this file in the directory $KRMX_PREFIX/etc. Otherwise, the configuration file must be in /opt/kronometrix/etc.

This attribute is read-only and it has an accessor method of the same name.

Required.

=item * max_concurrent_requests

Determines the maximum number of requests that may be active at any time. The attribute is read-only, and its accessor method is called C<max_concurrent>.

Defaults to one.

=item * verbose

If true, the subjacent L<Net::Curl::Easy> object will print useful information to STDERR.

Defaults to false.

=back

=head1 METHODS

The following public methods are available in this class. 

=over

=item * new

Constructor. Only C<config_file> is required. See above for the optional arguments.

=item * process

This method will feed the underlying L<Net::Curl::Multi> object with requests until the maximum concurrent limit has been attained or until there are no requests left.

Requests will be sent to the first host which has not yet hit the limit of maximum active connections (see C<max_host_connections>). The list of hosts is searched in the order of decreasing number of total requests. Thus, hosts for which there are more requests come first than hosts with few requests.

The count of active connections to the chosen host is increased and the request is sent. When the response is finally received, the time at which the host will be available for a new request is saved and the timing report is issued.

Finally, the number of active connections is decreased only after the time to mark the host as available has elapsed.

=back

=head1 SEE ALSO

This distribution is comprised of two modules. In addition to this one, there is a module for requests, C<Kronometrix::Webrec::Request>.

Actual requests are processed through L<Net::Curl>.  It is recommended to read the documentation for libcurl options found at L<https://curl.haxx.se/libcurl/c/curl_easy_setopt.html>.

=cut


