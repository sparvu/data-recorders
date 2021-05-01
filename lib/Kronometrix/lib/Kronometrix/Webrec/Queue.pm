package Kronometrix::Webrec::Queue;

use Kronometrix;
use Kronometrix::Webrec::Request;
use Net::Curl::Multi qw(:constants);
use List::Util qw(first);
use Scalar::Util qw(weaken refaddr);
use JSON;
use Time::HiRes qw(sleep);
use Carp;
use strict;
use warnings;
use feature ':5.20';
use feature 'postderef';
no warnings 'experimental::postderef';

use parent 'Kronometrix';

our $VERSION = 0.12;

sub new {
    my ($class, @args) = @_;
    my %args_hash = (
        max_concurrent_requests => 1,
        timeout                 => 60,
        nap_time                => 0,
        precision               => 0,
        verbose                 => 0,
        debug                   => 0,
        num_active_reqs         => 0,
        store_active_reqs       => {},
        report                  => [],
        index                   => 0,
        num_reqs                => 0,
        cert_location           => '/etc/ssl/certs/ca-certificates.crt',
        failsafe                => 1,
        failed                  => {},
        @args
    );

    $args_hash{max_concurrent} = delete $args_hash{max_concurrent_requests};

    croak "config_file is required for $class"
        unless defined $args_hash{config_file};

    croak "agent_name is required for $class"
        unless defined $args_hash{agent_name};

    my $self = bless \%args_hash, $class;

    $self->write_log("INFO: Started");
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
        # Minimal input verification
        my @required = qw(keepalive name description zone requests delay proxy);
        my @possible = qw(use_cookies follow_redir authenticated);
        foreach my $field (@required) {
            croak "Field $field is required for workloads"
                unless exists $f->{$field};
        }

        my %is_expected;
        $is_expected{$_}++ foreach (@required, @possible);
        foreach my $field (keys $f->%*) {
            croak "Field $field was found in workload but it was not expected"
                unless exists $is_expected{$field};
        }

        # Get its parameters
        my ($ka, $wname, $desc, $delay, $proxy) = map { $f->{$_} }
            qw(keepalive name description delay proxy);

        # For each request of the workload...
        my @reqs = @{ $f->{'requests'} };
        foreach my $req (@reqs) {
            my ($rname, $met, $scm, $hst, $prt, $pth) = map { $req->{$_} }
                qw(id method scheme host port path);
            $hst =~ s{/$}{};

            my $headers = exists $req->{headers}
                ? $req->{headers}
                : []
                ;

            my $post = '';
            if ( $met eq 'POST' && $req->{post}) {
                $post = $req->{'post'};
            }

            my $put = '';
            if ( $met eq 'PUT' && $req->{put}) {
                $put = $req->{'put'};
            }

            # Authenticated workloads require cookies
            # but deactivate redirections
            my $use_cookies  = 0; 
            my $follow_redir = 1;

            if (exists $f->{authenticated} && $f->{authenticated}) {
                $use_cookies  = 1;
                $follow_redir = 0;
            }

            $use_cookies = $f->{use_cookies}
                if exists $f->{use_cookies};

            $follow_redir = $f->{follow_redir}
                if exists $f->{follow_redir};

            $use_cookies = $req->{use_cookies}
                if exists $req->{use_cookies};

            $follow_redir = $req->{follow_redir}
                if exists $req->{follow_redir};

            # Compares the HTTP return code and fails if different
            my $expected = $req->{expected}
                if exists $req->{expected};

            # Parse forms in the returned HTML document
            my $parse_form = 0;
            $parse_form = $req->{parse_form}
                if exists $req->{parse_form};

            # Use parsed forms to complete POST fields
            my $process_form = 0;
            $process_form = $req->{process_form}
                if exists $req->{process_form};

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
                headers      => $headers,
                post         => $post,
                put          => $put,
                expected     => $expected,
                use_cookies  => $use_cookies,
                follow_redir => $follow_redir,
                parse_form   => $parse_form,
                process_form => $process_form,
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

        $self->write_verbose(
            "Added request for <" . $req->{initial_url} . ">");
    }
}

# Get curl easy handler and feed it to the multi object.
# Store a weak copy of the request to be retrieved afterwards
sub add_handle {
    my ($self, $req) = @_;
    my $easy = $req->init;

    # Put the easy handle in the curl multi object
    eval {
        $self->{multi}->add_handle($easy);
    };
    if ($@) {
        $self->write_log("ERROR: Could not add easy handle to curl's "
            . " multi object for URL <"
            . $req->{initial_url} . "> - $@ - Skipping");
    }
    else {
        # Put request in hashed active reqs store
        my $addr = refaddr $easy;
        $self->{store_active_reqs}{ $addr } = $req;
        weaken $self->{store_active_reqs}{ $addr };

        # Save its place in the results report
        push $self->{report}->@*, {
            url  => $req->{initial_url},
            line => undef
        };
    }
}

sub remove_request {
    my ($self, $easy) = @_;

    # Remove the request from the hashed active reqs store
    my $addr = refaddr $easy;
    my $req  = delete $self->{store_active_reqs}{$addr};

    # Remove the easy handle from the curl multi object
    eval {
        $self->{multi}->remove_handle($easy);
    };
    if ($@) {
        $self->write_log("ERROR: Curl returned an error while removing"
            . " the easy handle for <" . $req->{initial_url} . ">");
    }
    $self->{num_active_reqs}--;

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
    if ($self->is_async) {
        eval {
            $self->{multi} = Net::Curl::Multi->new;
            $self->{multi}->setopt(CURLMOPT_SOCKETFUNCTION, sub { return 0 });
        };
        if ($@) {
            $self->write_log("ERROR: The constructor of Net::Curl::Multi threw $@");
        }
    }
    else {
        $self->{multi} = undef;
    }

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
    my $res = $self->process_failsafe();
    $self->write_verbose("Finished request cycle");
    return $res;
}

# Failsafe can run for a number of cycles. If any sites fail, this will
# return 0.
sub process_failsafe {
    my $self = shift;
    my $s = 1;
    if ($self->{failsafe} == 1) {
        if ($self->{failed}->%*) {
            $s = 0;
            foreach my $r (keys $self->{failed}->%*) {
                $self->write_log("FAILSAFE: Failsafe $r failed");
            }
        }
    }
    $self->{failsafe}-- if $self->{failsafe} > 0;
    return $s;
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
                $req->mark_failsafe();
                $self->write_log("ERROR: Error while processing request for <"
                    . $req->{initial_url}
                    . "> - Error code: " . (0+$@)
                    . " - Error message: $@");
            }
            else {
                die "Unexpected error: <$@>";
            }
        }
        else {
            $self->write_verbose("Request <"
                . $req->{initial_url}
                . "> has been executed, elapsed "
                . $req->total_time
                . " ms"
            );
        }
        say $req->write_report;
        $req->clear_easy;

        sleep $self->{nap_time} if $self->{nap_time};

    }
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
                $self->write_log("ERROR: Error while processing requests"
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
                $self->write_verbose("Request <"
                    . $req->{initial_url}
                    . "> has been executed, elapsed "
                    . $req->total_time
                    . " ms"
                );
            }
            else {
                $req->mark_failsafe();
                $self->write_log("ERROR: Error with response: <"
                    . $req->{initial_url}
                    . "> - Error code: " . (0+$r)
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
 );

 $queue->process;

=head1 DESCRIPTION

This distribution implements a queue of URL requests. The goal is to measure the time it takes to complete each request. For each request, the following information is reported:

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

The system may send requests either sequentially or concurrently.

=head1 USAGE

User programs should build a single object of this class, and then simply call the C<process> method. The configuration file will be read and the specified requests will be performed.

=head1 ATTRIBUTES

The following attributes may be given to the constructor:

=over

=item * config_file

Name of the configuration file. If the environment variable KRMX_PREFIX exists, the Kronometrix::Webrec::Queue object will look for this file in the directory $KRMX_PREFIX/etc. Otherwise, the configuration file must be in /opt/kronometrix/etc.

Required.

=item * agent_name

User agent name to use for the retrieval of the requests.

Required.

=item * max_concurrent_requests

Determines the maximum number of requests that may be active at any time. Defaults to one.

=item * timeout

Determines the number of seconds to wait on a request. Defaults to 60.

=item * precision

Number of decimals to include in time reports. Defaults to 0.

=item * verbose

Extra information will be written to STDERR if true. Defaults to false.

=item * debug

If true, the subjacent L<Net::Curl::Easy> object will print useful information to STDERR. Defaults to false.

=back

=head1 METHODS

The following public methods are available in this class.

=over

=item * new

Constructor. Only C<config_file> is required. See above for the optional arguments.

=item * process

If the maximum number of concurrent requests is one, this method will use curl's easy interface to make all the requests in the queue, one by one.

If the maximum number of concurrent requests is greater than one, this method will feed the underlying L<Net::Curl::Multi> object with requests until the maximum concurrent limit has been attained or until there are no requests left. Requests will be sent asynchronously until the queue has been completed.

=back

=head1 SEE ALSO

This distribution is comprised of two modules. There is a module for requests, C<Kronometrix::Webrec::Request>.

Actual requests are processed through L<Net::Curl>.  It is recommended to read the documentation for libcurl options found at L<https://curl.haxx.se/libcurl/c/curl_easy_setopt.html>.

=cut


