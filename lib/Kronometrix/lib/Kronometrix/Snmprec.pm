package Kronometrix::Snmprec;

use Net::SNMP qw(:snmp);
use Data::Dumper;
use Carp;
use parent 'Kronometrix';
use strict;
use warnings;
use feature ':5.32';

our $VERSION = 0.01;

sub new {
    my ($class, @args) = @_;
    my %args_hash = (
        max_concurrent_hosts    => 1,
        timeout                 => 5,
        verbose                 => 0,
        debug                   => 0,
        config_file             => 'snmprec.json',
        queue                   => [],
        @args
    );
    my $self = bless \%args_hash, $class;
    $self->write_verbose(
        "INFO: Kronometrix::Snmprec object has been created");
    # Useful for testing
    my $conf;
    if ( ref $self->{config_file} ) {
        $conf = $self->{config_file};
    }
    else {
        $conf = $self->open_config($self->{config_file});
    }
    $self->parse_config($conf);
    return $self;
}

my %callback_for = (
    get         => \&get_request_callback,
    get_next    => sub { die "Not implemented!" },
    get_bulk    => \&get_bulk_callback,
    get_table   => sub { die "Not implemented!" },
    get_entries => sub { die "Not implemented!" },
);

# OID arguments -- The config file must include a list of snmp oids and
# the commands to fetch the information. The availability of commands
# depends on the snmp version that the particular host is using.
# Method is one of get, get_next, get_bulk, get_table, get_entries
# Section is the name of the section of the config file, like host or service
sub build_request_structure {
    my ($self, $section, $common, $conf) = @_;
    
    croak "Fatal: Required argument 'method' is missing from a request for $section"
        unless exists $conf->{method} && defined $conf->{method};
    croak "Fatal: unknown method '$conf->{method}' in the requests for $section"
        unless exists $callback_for{$conf->{method}};
    my $method = exists $conf->{method} ? $conf->{method} : 'get';

    my @possible = ();

    if ($self->{max_concurrent_hosts} > 1) {
        push @possible, 'delay';
    }

    if ($common->{version} == 3) {
        push @possible, qw(contextengineid contextname);
    }

    if ($method eq 'get_bulk') {
        push @possible, qw(nonrepeaters maxrepetitions);
    }
    elsif (($method eq 'get_table' || $method eq 'get_entries')
        && $common->{version} > 1) {
        push @possible, qw(maxrepetitions);
    }

    if ($method eq 'get_entries') {
        push @possible, qw(startindex endindex);
    }

    # Build the request arguments
    my %request;
    foreach my $ofield (@possible) {
        $request{"-$ofield"} = $conf->{$ofield}
            if exists $conf->{$ofield} && defined $conf->{$ofield};
    }

    # Request args are encapsulated with other data
    my %g;
    $g{method} = $method;

    croak "Fatal: Required argument 'oids' is missing from a request for $section"
        unless exists $conf->{oids} && defined $conf->{oids};
    my @oids_with_descr = $conf->{oids}->@*;
    my @oids;
    for (my $i = 1; $i < @oids_with_descr; $i+= 2) {
        push @oids, $oids_with_descr[$i];
    }
    $g{oids} = \@oids;

    # Translate oids to the correct attribute name
    my %oid_for = (
        get         => '-varbindlist',
        get_next    => '-varbindlist',
        get_bulk    => '-varbindlist',
        get_table   => '-baseoid',
        get_entries => '-columns',
    );
    $request{$oid_for{$method}} = \@oids;

    $g{request} = \%request;

    return \%g;
}

sub get_common_session {
    my ($self, $section, $conf) = @_;
    my @required = qw(version);
    foreach my $rfield (@required) {
        croak "Fatal: Required argument $rfield is missing for $section"
            unless exists $conf->{$rfield} && defined $conf->{$rfield};
    }
    return $conf;
}

sub build_session_structure {
    my ($self, $section, $common, $specific) = @_;

    # Combine common attributes with host specific attrs
    my %conf = (%$common, %$specific);

    ### Session arguments
    my %host_args;
    my $host = exists $conf{hostname} ? $conf{hostname} : 'unknown';
    my @required = qw(hostname version);
    my @possible = qw(port localaddr localport domain timeout retries
        maxmsgsize translate);
    foreach my $rfield (@required) {
        croak "Fatal: Required argument $rfield is missing for host $host "
            . "in section $section"
            unless exists $conf{$rfield} && defined $conf{$rfield};
        $host_args{"-$rfield"} = delete $conf{$rfield};
    }
    foreach my $ofield (@possible) {
        $host_args{"-$ofield"} = delete $conf{$ofield}
            if exists $conf{$ofield} && defined $conf{$ofield};
    }

    # Authentication (community vs user-based security model)
    if ($host_args{"-version"} <= 2) {
        $host_args{"-community"} = delete $conf{community}
            if exists $conf{community} && defined $conf{community};
    }
    else {
        @required = qw(username);
        @possible = qw(authkey authpassword authprotocol privkey
            privpassword privprotocol);
        foreach my $rfield (@required) {
            croak "Fatal: Required argument $rfield is missing for "
                . "$host (SNMPv3) (section $section)"
                unless exists $conf{$rfield} && defined $conf{$rfield};
            $host_args{"-$rfield"} = delete $conf{$rfield};
        }
        foreach my $ofield (@possible) {
            $host_args{"-$ofield"} = delete $conf{$ofield}
                if exists $conf{$ofield} && defined $conf{$ofield};
        }
    }

    croak "Fatal: Found unknown argument(s) " . join(', ', keys %conf)
        . " for host $host in section $section" if %conf;

    return \%host_args;
}

# The debug argument is way more complex than a simple yes/no
# Config file is a list of hashes. Each hash is a section with requests
# and a list of hosts. This program will launch the same requests to n
# hosts asynchronously.
sub parse_config {
    my ($self, $conf) = @_;

    $self->write_debug('DEBUG: Parsing service definition file');
    
    if (!defined $self->{separator}) {
        if (exists $conf->{separator}) {
            $self->{separator} = $conf->{separator};
        }
        else {
            $self->{separator} = ':';
        }
    }

    my $n = 1;
    foreach my $shash ($conf->{devices}->@*) {
        # Name of the section of the config file
        croak "Fatal: Required argument 'description' is missing from section number $n"
            unless exists $shash->{description} && defined $shash->{description};
        my $section = $shash->{description};

        # Session parameters common to all hosts
        croak "Fatal: Required argument 'settings' for $section "
            . "is missing or not a hash reference"
            unless exists $shash->{settings}
                && defined $shash->{settings}
                && ref($shash->{settings}) eq 'HASH'
                ;
        my $common = $self->get_common_session($section, $shash->{settings});

        # Requests
        my @requests;
        croak "Fatal: Required argument 'requests' of pool $section is "
            . "missing or not an array reference"
            unless exists $shash->{requests}
                && defined $shash->{requests}
                && ref($shash->{requests}) eq 'ARRAY';
        foreach my $rconf ($shash->{requests}->@*) {
            push @requests, $self->build_request_structure($section, $common, $rconf);
        }

        # Session parameters specific to each host
        croak "Fatal: Required argument 'hosts' of pool $section is "
            . "missing or not an array of hashes"
            unless exists $shash->{hosts}
                && defined $shash->{hosts}
                && ref($shash->{hosts}) eq 'ARRAY'
                && ref($shash->{hosts}[0]) eq 'HASH'
                ;
        foreach my $hconf ($shash->{hosts}->@*) {
            my %host;
            $host{session} = $self->build_session_structure(
                $section, $common, $hconf);
            $host{requests} = \@requests;
            push $self->{queue}->@*, \%host; 
        }
    }

    $self->write_verbose(
        "INFO: Service definition file has been parsed");
}

# Queue of hosts; one host per SNMP session. SNMP sessions are async and
# concurrent. So, we process n hosts at a time
sub process {
    my $self = shift;

    $self->write_verbose("INFO: Processing");

    my $i = 0;
    my $creq = $self->{max_concurrent_hosts};
    my @full_output;
    while ($i < $self->{queue}->@*) {
        # Build SNMP session and schedule requests
        my %host_args = $self->{queue}[$i]->%*;
        $self->write_debug("DEBUG: Host args " . Dumper \%host_args);
        my $requests = $host_args{requests};
        my $session = $self->build_session($host_args{session});
        next unless $session;

        push @full_output, $self->issue_requests($session, $requests);

        # Execute requests every max_concurrent_hosts
        $i++;
        if ($i % $creq == 0) {
            $self->write_debug("DEBUG: Executing requests");
            $self->execute_requests();
            $self->write_report(\@full_output);
            @full_output = ();
        }
    }
}

sub build_session {
    my ($self, $host_args) = @_;

    # Build session object
    my %session_args = %$host_args;
    my $host = $host_args->{'-hostname'};
    $session_args{'-nonblocking'} = 1;
    
    my ($session, $error) = Net::SNMP->session(%session_args);
    if (!defined $session) {
        $self->write_log(
            "Error: Failed creating SNMP session for $host: $error");
    }
    return $session;
}

sub issue_requests {
    my ($self, $session, $requests) = @_;

    # Translate method name
    my %method_for = (
        get         => sub { $session->get_request(@_) },
        get_next    => sub { $session->get_next_request(@_) },
        get_bulk    => sub { $session->get_bulk_request(@_) },
        get_table   => sub { $session->get_table(@_) },
        get_entries => sub { $session->get_entries(@_) },
    );

    # Add requests to the session object
    my @host_output;
    foreach my $g ($requests->@*) {
        my $m    = $g->{method};
        my $oids = $g->{oids};
        my $req  = $g->{request};
        $req->{'-callback'} = [ $callback_for{$m}, $self, $oids, \@host_output ];

        # Issue the request
        my $r = $method_for{$m}->(%$req);

        if (!defined $r) {
            my $host = $session->hostname();
            my $e    = $session->error();
            $self->write_log("Error: $m request for $host failed: $e");
        }
    }
    return \@host_output;
}

sub execute_requests {
    snmp_dispatcher();
}

sub write_report {
    my ($self, $output) = @_;
    foreach my $host_output (@$output) {
        next unless @$host_output;
        say join $self->{separator}, time(), @$host_output;
    }
}

sub get_request_callback {
    my ($session, $snmprec, $oids, $output) = @_;
    my $host   = $session->hostname();
    my $result = $session->var_bind_list();
    if (defined $result) {
        # Puts the results for every OID in the output, respecting their order
        foreach my $oid (@$oids) {
            if (exists $result->{$oid}) {
                push @$output, $result->{$oid};
            }
            else {
                $snmprec->write_log("ERROR: No response for $oid from $host");
                $output = [];
                last;
            }
        }
    }
    else {
        $snmprec->write_log("ERROR: No response from $host for any OID");
        $output = [];
    }
    unshift $output->@*, $host
        if $output->@*;
}

sub get_bulk_callback {
    my ($session, $snmprec, $oids, $output) = @_;
    my $host      = $session->hostname();
    my $value_for = $session->var_bind_list();
    push @$output, $host;
    if (!defined $value_for) {
        push @$output, [$host, 'get_bulk', 'ERROR', $session->error()];
        return;
    }

    # The $oids are partials; get_bulk will bring data that start with oid.
    # Returned data may be incomplete. If so, we will issue a new request
    # but these new data must be integrated into the right table.
    # See example3.pl in Net::SNMP

    # Output is an array ref. Create a hash ref inside
    $output->[0] = {} unless defined $output->[0];

    # Iterate results and add them to the right table
    my @names = $session->var_bind_names();
    my $name;
    my $matched;
    foreach $name (@names) {
        $matched = 0;
        foreach my $oid ($oids->@*) {
            $output->[0]{$oid} = {} unless exists $output->[0]{$oid}; 
            if (oid_base_match($oid, $name)) {
                $output->[0]{$oid}{$name} = $value_for->{$name};
                $matched++;
                last;
            }
        }
    } 

    if ($matched) { 
        # Table is not finished. Send a new request starting with new OID
        my $r = $session->get_bulk_request( 
            -varbindlist    => [ $value_for ], -maxrepetitions => 10,
            -callback       => [\&get_bulk_callback, $oids, $output],
        );

        if (!defined $r) {
            push @$output, [$host, 'get_bulk', 'ERROR', $session->error()]; 
        }
    }
}

1;

__END__

=pod

=head1 NAME

Kronometrix::Snmprec - Interrogate a remote host with SNMP

=head1 SYNOPSIS

 use Kronometrix::Snmprec;

 my $snmprec = Kronometrix::Snmprec->new(
    config_file             => 'svcrec.json',
    max_concurrent_hosts    => 25,
    timeout                 => 5,
    verbose                 => $verbose,
    debug                   => $debug,
 );

 $snmprec->process;

=head1 DESCRIPTION

This module implements a Kronometrix service that monitors a set of hosts using SNMP. It allows for asynchronous monitoring.

=head1 OBJECT CONSTRUCTOR

The constructor takes the following arguments:

=over

=item config_file

Optional. Name of the JSON configuration file or a data structure with the full configuration. Defaults to 'snmprec.json'.

=item max_concurrent_hosts

Optional. Defaults to 1. Sets the number of concurrent sessions to handle. A session is a connection to a host. Requests will be treated in a per-host basis.

=item timeout

Optional. Defaults to 5 seconds. Time to wait for hosts to respond.

=item verbose, debug

Optional. Default to a false value. Set to true to produce extra information on STDERR.

=back

=head1 CONFIGURATION FILE

The main concept for this program is a I<session>. It represents a connection to a particular host to execute a set of requests. To create a session, the configuration file must include information to establish the connection to the host and information about the requests to be made.

The configuration file is broken into I<sections>. A section groups several hosts that share the same connection parameters and same requests. A section includes common and particular connection parameters (keywords I<session> and I<hosts>). Each section includes a list of I<requests>, too.

A basic configuration file looks like this:

 [
    { 
        "section": "Section name",
        "session": {
            "timeout": 25,
            "version": 1,
            "community": "public",
            "retries": 5
        },
        "requests": [
            {
                "oids": [
                    "1.3.6.1.2.1.1.3.0"
                ],
                "method": "get"
            }
        ],
        "hosts": [
            {
                "hostname": "localhost"
            }
        ]
    }
 ]

It is a list of I<sections>, and each section is a hash. The keys of each section are:

=over

=item section

The name of the section. Sections group the configuration for similar devices.

=item session

Common parameters to connect to each host. These parameters may be overriden in the I<hosts> particular parameters section. It must be a hash.

=item hosts

List of particular parameters to connect to each host. Sessions will be established with each host in the order given in this list. Each entry of the list must be a hash.

=item requests

List of hashes. Each hash contains the parameters for one or more requests to be executed with a given I<method>.

=back

All of the above keys are required.

=head2 SESSION CONFIGURATION

Session configuration options are meant to establish connections to each host. These options may be given in any of I<session> or I<hosts>. Those given in I<session> will be used for all hosts, and I<hosts> parameters are particular to each host.

The only exception is B<version>, the SNMP protocol version to use for the set of sessions. B<version> must be present in the I<session> hash and it will be valid for all requests and all hosts.

=over

=item version

Mandatory, must be present in the I<session> hash. It must be 1, 2 or 3.

=item hostname

Required. Should be included in a hash inside of I<hosts>. It defines each host to send the requests to. It can be given in the standard dotted form, as a valid hostname, and it can include the port number if given in any of these forms: hostname:port or address:port.

=item port

Optional. Port number to establish the connection to. Defaults to 161, the standard SNMP port.

=item localaddr, localport

Optional. Source transport address and port for the connection. By default, these will be chosen dynamically by Net::SNMP.

=item domain

Optional. Transport domain used. Options: 'udp6', 'udp/ipv6'; 'tcp', 'tcp4', 'tcp/ipv4'; 'tcp6', or 'tcp/ipv6'. Defaults to 'udp', 'udp4', 'udp/ipv4' which are equivalent. 

=item timeout

Optional. Defaults to 5.0 seconds. If given, it must be between 1.0 and 60.0 seconds.

=item retries

Optional. Defaults to 1. Must be between 0 and 20.

=item maxmsgsize

Optional. Defaults to 1472 octets for UDP/IPv4, 1452 octets for UDP/IPv6, 1460 octets for TCP/IPv4, and 1440 octets for TCP/IPv6. It must be between 464 and 65535 octets.

=item translate

Advanced behavior. Please refer to the documentation of Net::SNMP.

=back

The same I<session> or I<hosts> hashes may include parameters to handle authentication. SNMP versions 1 and 2 use a "community" model, while version 3 uses a more sophisticated model:

=head3 Authentication for SNMP versions 1 and 2

=over

=item community

Optional. A string that defines the community to use for authentication. Defaults to "public".

=back

=head3 Authentication for SNMP version 3

=over

=item username

Required for SNMP version 3. String of length between 1 and 32 octets.

=item authpassword or authkey

These two fields set a security level of noAuthNoPriv. You can use either of them. I<authpassword> is a password string at least 1 octet long. I<authkey> is a hexadecimal string  produced by localizing the password with the authoritativeEngineID for the specific destination device. See Net::SNMP for details.

=item authprotocol

Optional. Defines the hashing algorithm to use for authentication. Possible values are 'md5' (default) or 'sha'.

=item privkey or privpassword

Optional. Any of these fields will set a security level of authPriv. If any of them is present, either I<authpassword> or I<authkey> become mandatory. I<privkey> and I<privpassword> expect the same input as I<authkey> or I<authpassword>, respectively.

=item privprotocol

Optional. Defines the encryption protocol. Defaults to 'des'. Possible values are 'aes' or 'aes128'; '3des' or '3desede'. See Net::SNMP for details.

=back

=head2 REQUESTS CONFIGURATION

Each section of the configuration file must contain a list of request definitions. Each request is detailed as a hash. This hash accepts the following options:

=over

=item method

Required. It must be one of 'get', 'get_next', 'get_bulk', 'get_table', or 'get_entries'. It defines the SNMP method for the request.

=item oids

Required. List of OIDs for the request. It may include one or more OIDs.

=item delay

Optional. Used for asynchronous requests. Defaults to 0. Sets the number of seconds to wait before executing the SNMP protocol exchange.

=back

SNMP3 requests may have a B<context>. This context is specified by using the options I<contextengineid> and I<contextname>.

=over

=item contextengineid

Expects a hexadecimal string representing the desired contextEngineID. The string must be 10 to 64 characters (5 to 32 octets) long and can be prefixed with an optional "0x". Once the I<contextengineid> is specified it stays with the object until it is changed again or reset to default by passing in the undefined value. By default, the contextEngineID is set to match the authoritativeEngineID of the authoritative SNMP engine.

=item contextname

The contextName is passed as a string which must be 0 to 32 octets in length. The contextName stays with the object until it is changed. The contextName defaults to an empty string which represents the "default" context.

=back

=head3 OPTIONS FOR SPECIFIC METHODS

Each method can have its own parameters. The following parameters are supported:

=over

=item get_bulk: nonrepeaters, maxrepetitions

=item get_table, get_entries if version is 2 or 3: maxrepetitions

=item get_entries: startindex, endindex

=back


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

Julio FRAIRE, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Julio FRAIRE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
