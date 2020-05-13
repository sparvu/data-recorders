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
    return $self->getinfo('TOTAL_TIME');
}

# Configuration of the Net::Curl::Easy object
sub init {
    my $self = shift;

    eval {
        $self->{handle} = Net::Curl::Easy->new;
    };
    if ($@) {
        $self->{webrec_queue}->write_log(
            "ERROR:  Could not create Easy handle for " . $self->{initial_url}
            . " - Net::Curl::Easy threw $@"
        );
    }
    
    # Set url
    $self->setopt('URL', $self->{initial_url});

    # Just discard headers and body
    my ($head, $body);
    $self->setopt('WRITEHEADER', \$head);
    $self->setopt('WRITEDATA', \$body);

    # Disable DNS caching
    $self->setopt('DNS_CACHE_TIMEOUT', 0);

    # Switch off the progress meter. 1 by default
    $self->setopt('NOPROGRESS', 1);

    # Follow http redirects. Defaults to 0. Set maxredirs?
    $self->setopt('FOLLOWLOCATION', 1);

    # Path to the ca bundle -- Not needed since we never verify peers
    # $self->setopt('CAINFO', $self->webrec_queue->cert_location);

    # Do not install signal handlers
    $self->setopt('NOSIGNAL', 1);

    # Timeout for the entire request
    $self->setopt('TIMEOUT', $self->{timeout});

    # Keep-alive or forbid reusing connections?
    if (!$self->{keepalive}) {
        # Closes connection after use
        $self->setopt('FORBID_REUSE', 1);

        # Forces the use of a fresh connection
        $self->setopt('FRESH_CONNECT', 1);
    }

    my @myheaders;
    $myheaders[0] = "User-Agent: " . $self->{agent_name};

    $self->setopt('HTTPHEADER', \@myheaders);      # Sets headers
    $self->setopt('COOKIEJAR',  "cookies.txt");    # Sets a cookie jar

    if ($self->{scheme} eq 'https') {
        $self->setopt('SSL_VERIFYPEER', 0);        # Skip verification
        $self->setopt('SSL_VERIFYHOST', 0);        # Skip verification
    }

    if ($self->{method} eq 'POST') {                       # Add post data
        my $post = $self->{post} ? $self->{post} : '';
        $self->setopt('POST',       1);
        $self->setopt('POSTFIELDS', $post);
    }


    if ($self->{proxy}) {
        $self->{webrec_queue}->write_log("Proxy: " . $self->{proxy});
        $self->setopt('PROXY', $self->{proxy});
    }

    if ($self->{proxy_userpwd}) {
        $self->{webrec_queue}->write_log("Proxy user: " . $self->{proxy_userpwd});
        $self->setopt('PROXYUSERPWD', $self->{proxy_userpwd});
    }

    if ($self->{verbose}) {
        $self->setopt('VERBOSE', 1);
    }

    unless ($self->{method} eq 'POST' || $self->{method} eq 'GET' || $self->{method} eq 'HEAD') {
        $self->{webrec_queue}->write_log("error: not supported method "
              . $self->{method} . " for "
              . $self->{initial_url});
    }

    $self->request_time(time);

    return $self->{handle};
};

sub write_report {
    my $self = shift;

    my @report = (
        $self->request_time,
        $self->{workload},
        $self->{request_name},
        $self->getinfo(qw{TOTAL_TIME CONNECT_TIME NAMELOOKUP_TIME
            PRETRANSFER_TIME SIZE_DOWNLOAD STARTTRANSFER_TIME
            HTTP_CODE})
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

# Error-proof calling of curl's getinfo
my %code_for = (
    TOTAL_TIME          => CURLINFO_TOTAL_TIME,
    CONNECT_TIME        => CURLINFO_CONNECT_TIME,
    NAMELOOKUP_TIME     => CURLINFO_NAMELOOKUP_TIME,
    PRETRANSFER_TIME    => CURLINFO_PRETRANSFER_TIME,
    SIZE_DOWNLOAD       => CURLINFO_SIZE_DOWNLOAD,
    STARTTRANSFER_TIME  => CURLINFO_STARTTRANSFER_TIME,
    HTTP_CODE           => CURLINFO_HTTP_CODE,
);

my %opt_for;
my @options = qw(URL WRITEHEADER WRITEDATA
    DNS_CACHE_TIMEOUT NOPROGRESS FOLLOWLOCATION NOSIGNAL TIMEOUT
    FORBID_REUSE FRESH_CONNECT HTTPHEADER COOKIEJAR SSL_VERIFYPEER
    SSL_VERIFYHOST POST POST_FIELDS PROXY PROXYUSERPWD VERBOSE CAINFO); 
$opt_for{$_} = eval "CURLOPT_$_" foreach @options; 

sub getinfo {
    my ($self, @codes) = @_;
    my $code;
    my @res;
    eval {
        while (@codes) {
            $code = shift @codes;
            push @res, $self->{handle}->getinfo($code_for{$code});
        }
    };
    if ($@) {
        $self->{webrec_queue}->write_log(
            "ERROR: URL " . $self->{initial_url}
            . " - Information requested: " . $code
            . " - curl's getinfo returned $@"
        );
    }
    return wantarray ? @res : $res[0];
}

sub setopt {
    my ($self, $code, $value) = @_;
    eval {
        $self->{handle}->setopt($opt_for{$code}, $value);
    };
    if ($@) {
        $self->{webrec_queue}->write_log(
            "ERROR: URL " . $self->{initial_url}
            . " - Setting option: " . $code
            . " - curl's setopt returned $@"
        );
    }
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
    timeout      => 30,
    agent_name   => $ua,
    verbose      => 1,
    webrec_queue => $queue,
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

=item * timeout

Determines the number of seconds to wait on a request. Defaults to 60.

=item * agent_name

User agent name to use for the retrieval of the requests.

Required.

=item * webrec_queue

Reference to the L<Kronometrix::Webrec::Queue> object that will take care of the request. Required.

=over

=head1 METHODS

=item * new

Constructor. See above for the list of attributes it may take. The constructor builds the initial url and the proxy definitions. It also verifies the existance of all the required fields.

=item * init

Builds and configures a L<Net::Curl::Easy> object according to the attributes of the object. Returns the easy handle.

=item * request_time

Holds the time at which the request is put in the queue.

=item * total_time

Returns the total time taken by the request. It uses the C<getinfo> method of the cURL easy object to obtain C<CURLINFO_TOTAL_TIME>. 

=item * write_report

Once the request has completed, this method will generate the report in the format established by L<Kronometrix::Webrec::Queue>.

=over

=head1 SEE ALSO

This class should be used along with L<Kronometrix::Webrec::Queue>, which is the public-facing class.

