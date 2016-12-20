package Kronometrix::Webrec::Request;

use Time::HiRes qw(time);
use Net::Curl::Easy qw(:constants);
use Scalar::Util qw(weaken);
use Carp;
use strict;
use warnings;
use feature ':5.20';
use feature 'postderef';
no warnings 'experimental::postderef';

sub new {
    my ($class, @args) = @_;
    my %args_hash = @args;
    
    $args_hash{timeout} //= 60;

    # Build initial url -- host name is required
    my $initial;
    $initial = $args_hash{scheme} . '://' if $args_hash{scheme};
    $initial .= $args_hash{host} || die 'A host name is required';
    $initial .= ':' . $args_hash{port} if $args_hash{port};
    $initial .= $args_hash{path} if defined $args_hash{path};
    $args_hash{initial_url} = $initial;

    # Test for required fields
    foreach my $field (qw(keepalive workload description 
        request_name method host webrec_queue)) {
        croak "Field $field is required for objects of class $class"
            unless exists $args_hash{$field};
    }

    # Build proxy
    my $proxy;
    if (ref $args_hash{proxy} eq 'HASH' && $args_hash{proxy}->{hostname}) {
        $proxy .= $args_hash{proxy}->{hostname};
    }
    if ($proxy && defined $args_hash{proxy}->{port}) {
        $proxy .= ':' . $args_hash{proxy}->{port};
    }

    # Proxy user and password
    if ($proxy && $args_hash{proxy}->{username}) {
        $args_hash{proxy_userpwd} = join ':', 
            $args_hash{proxy}->{username}, 
            $args_hash{proxy}->{password};
    }
    $args_hash{proxy} = $proxy;

    weaken $args_hash{webrec_queue};
    
    my $self =  bless \%args_hash, $class;
    
    return $self;
}

# Holds the time at which the request is launched
sub request_time {
    my ($self, $time) = @_;
    $self->{request_time} = $time if defined $time;
    return $self->{request_time};
}

# Returns the total time the request took
sub total_time {
    my $self = shift;
    return $self->{handle}->getinfo(CURLINFO_TOTAL_TIME);
}

# Configuration of the Net::Curl::Easy object
sub init {
    my $self = shift;
    my $easy = Net::Curl::Easy->new;

    # Set url
    $easy->setopt(CURLOPT_URL, $self->{initial_url});

    # Just discard headers and body
    my ($head, $body);
    $easy->setopt(CURLOPT_WRITEHEADER, \$head);
    $easy->setopt(CURLOPT_WRITEDATA, \$body);

    # Disable DNS caching
    $easy->setopt(CURLOPT_DNS_CACHE_TIMEOUT, 0);

    # Switch off the progress meter. 1 by default
    $easy->setopt(CURLOPT_NOPROGRESS, 1);

    # Follow http redirects. Defaults to 0. Set maxredirs?
    $easy->setopt(CURLOPT_FOLLOWLOCATION, 1);

    # Path to the ca bundle -- Not needed since we never verify peers
    # $easy->setopt(CURLOPT_CAINFO, $self->webrec_queue->cert_location);

    # Do not install signal handlers
    $easy->setopt(CURLOPT_NOSIGNAL, 1);

    # Timeout for the entire request
    $easy->setopt(CURLOPT_TIMEOUT, $self->{timeout});

    # Keep-alive or forbid reusing connections?
    if (!$self->{keepalive}) {
        # Closes connection after use
        $easy->setopt(CURLOPT_FORBID_REUSE, 1);

        # Forces the use of a fresh connection
        $easy->setopt(CURLOPT_FRESH_CONNECT, 1);
    }

    my @myheaders;
    $myheaders[0] = "User-Agent: " . $self->{agent_name};

    $easy->setopt(CURLOPT_HTTPHEADER, \@myheaders);      # Sets headers
    $easy->setopt(CURLOPT_COOKIEJAR,  "cookies.txt");    # Sets a cookie jar

    if ($self->{scheme} eq 'https') {
        $easy->setopt(CURLOPT_SSL_VERIFYPEER, 0);        # Skip verification
        $easy->setopt(CURLOPT_SSL_VERIFYHOST, 0);        # Skip verification
    }

    if ($self->{method} eq 'POST') {                       # Add post data
        my $post = $self->{post} ? $self->{post} : '';
        $easy->setopt(CURLOPT_POST,       1);
        $easy->setopt(CURLOPT_POSTFIELDS, $post);
    }


    if ($self->{proxy}) {
        $self->{webrec_queue}->write_log("Proxy: " . $self->{proxy});
        $easy->setopt(CURLOPT_PROXY, $self->{proxy});
    }

    if ($self->{proxy_userpwd}) {
        $self->{webrec_queue}->write_log("Proxy user: " . $self->{proxy_userpwd});
        $easy->setopt(CURLOPT_PROXYUSERPWD, $self->{proxy_userpwd});
    }

    if ($self->{verbose}) {
        $easy->setopt(CURLOPT_VERBOSE, 1);
    }

    unless ($self->{method} eq 'POST' || $self->{method} eq 'GET') {
        $self->{webrec_queue}->write_log("error: not supported method "
              . $self->{method} . " for "
              . $self->{initial_url});
    }

    $self->request_time(time);
    $self->{handle} = $easy;

    return $easy;
};

sub write_report {
    my $self = shift;

    my @report = (
        $self->request_time,
        $self->{workload},
        $self->{request_name},
        $self->{handle}->getinfo(CURLINFO_TOTAL_TIME),
        $self->{handle}->getinfo(CURLINFO_CONNECT_TIME),
        $self->{handle}->getinfo(CURLINFO_NAMELOOKUP_TIME),
        $self->{handle}->getinfo(CURLINFO_PRETRANSFER_TIME),
        $self->{handle}->getinfo(CURLINFO_SIZE_DOWNLOAD),
        $self->{handle}->getinfo(CURLINFO_STARTTRANSFER_TIME),
        $self->{handle}->getinfo(CURLINFO_HTTP_CODE),
    );

    # First packet time: starttransfer_time - namelookup_time
    $report[-2] -= $report[5];

    $self->putraw(@report);
};

sub clear_easy {
    my $self = shift;
    $self->{handle} = undef;
}

# Build report line
sub putraw {
    my ($self,  $timereq, $workload, $reqname, $ttime, $ctime,
        $dtime, $ptime,   $psize,    $fpkt,    $rcode
    ) = @_;

    my $devid;
    my $p = $self->{precision};

    if ($workload) {
        $devid = $workload . "_" . $reqname;
    }
    else {
        $devid = $reqname;
    }
    
    my $line = sprintf "%.${p}f:%s:", $timereq, $devid;
    my @fields = ($ttime, $ctime, $dtime, $ptime, $fpkt, $psize);
    
    if ($rcode == 0) {
        $line .= join ':', ('NA') x 6;
    }
    else {
        $line .= sprintf "%.3f:%.3f:%.3f:%.3f:%.3f:%d", @fields;
    }

    $line .= ":$rcode";
    return $line;
}

1;

=pod

=head1 NAME

Kronometrix::Webrec::Request - Request objects for Kronometrix

=head1 SYNOPSIS

 # Build a request object and save it in the queue
 my $r = Kronometrix::Webrec::Request->new(
    keepalive    => $ka,
    workload     => $wname,
    description  => $desc,
    proxy        => $proxy,
    request_name => $rname,
    method       => $met,
    scheme       => $scm,
    host         => $hst,
    port         => $prt,
    path         => $pth,
    post         => $post,
    precision    => 3,
    verbose      => $self->verbose,
    webrec_queue => $self,
 );

=head1 DESCRIPTION

This class is part of the Kronometrix::Webrec distribution. Its role is to wrap L<Net::Curl::Easy> objects configured to measure HTTP or HTTPS request time statistics, such as total request time, connection time, or name resolving time.

Generally speaking, this module shoule is meant to be used with L<Kronometrix::Webrec::Queue>.

=head1 ATTRIBUTES

The constructor may include the following attributes:

=over

=item * scheme

Used to create the URL for the request. Generally, it should be either http or https. Optional.

=item * host

Name of the host to which the request will be sent. Required.

=item * port, path

Used to create the URL for the request. Optional.

=item * proxy

Hash reference with the following keys:

=over

=item - hostname

Host name of the proxy server. Required. Proxy configuration is ignored unless the hostname exists.

=item - port

Port in which the proxy server is listening. Optional.

=item - username and password

Credentials to be sent to the proxy server. Optional.

=over

=item * keepalive

Boolean. When true, connections are left open for re-using them on later requests. If false, a fresh connection is forced for every request. This parameter has a direct influence on the times measured as the connection and name resolving times become zero. Required.

=item * workload

Name of the current workload. Required.

=item * description

Description of the workload. Required.

=item * request_name

Name of the current request. The configuration file uses the key C<id> for this field. Required.

=item * method

HTTP method, either GET or POST. All other methods are illegal. Required.

=item * precision

Precision to timestamp the request; i.e, number of decimals.

=item * webrec_queue

Reference to the L<Kronometrix::Webrec::Queue> object that will take care of the request. Required.

=over

=head1 METHODS

=item * new

Constructor. See above for the list of attributes it may take. The constructor builds the initial url and the proxy definitions. It also verifies the existance of all the required fields.

=item * init

Builds and configures a L<Net::Curl::Easy> object according to the attributes of the object. Returns the easy handle, which is also accessible via C<handle>.

=item * handle

Accessor/mutator for the L<Net::Curl::Easy> handle.

=item * request_time

Holds the time at which the request is put in the queue of the L<Kronometrix::Webrec::Queue> object (not necessarily in the cURL multi object within).

=item * total_time

Returns the total time taken by the request. It uses the C<getinfo> method of the cURL easy object to obtain C<CURLINFO_TOTAL_TIME>. 

=item * write_report

Once the request has completed, this method will generate the report in the format established by L<Kronometrix::Webrec::Queue>.

=over

=head1 SEE ALSO

This class should be used along with L<Kronometrix::Webrec::Queue>, which is the public-facing class.

