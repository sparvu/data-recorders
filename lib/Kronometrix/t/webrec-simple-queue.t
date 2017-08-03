#! /usr/bin/env perl

use Test::More;
use strict;
use warnings;

BEGIN {
    use_ok 'Kronometrix::Webrec::Queue';
}

$ENV{KRMX_PREFIX} = 't';

{
    # Change add_handle method so that we can test the queue
    no warnings 'redefine';
    *Kronometrix::Webrec::Queue::add_handle = sub {
        my ($self, $req) = @_;
        # diag "Added a handle";
    };
}

# Iterate through the request queue
{    
    my $queue = Kronometrix::Webrec::Queue->new(
        config_file             => 'webrec.json',
        agent_name              => 'Hank Schroeder',
        max_concurrent_requests => 1,
        verbose                 => 0,
        precision               => 3,
    );  

    is $queue->{max_concurrent}, 1,
        'max_concurrent set as expected';

    # Initial state
    is $queue->{index}, 0,
        'request index set at zero';
    is $queue->{num_active_reqs}, 0,
        'The number of active requests is set to zero';
    
    
    # Advance once
    $queue->add_requests;
    is $queue->{index}, 1,
        'Request index advanced as a request was processed';
    is $queue->{num_active_reqs}, 1,
        'Active requests increased as a request was processed';
    
    # Change the max_concurrent limit to 3 so that all of the reqs
    # are processed
    $queue->{max_concurrent} = 4;
    $queue->add_requests;
    is $queue->{index}, $queue->{num_reqs},
        'Request index equals the number of reqs in the queue';
    is $queue->{num_active_reqs}, $queue->{max_concurrent},
        'Active requests equals max_concurrent';
    
}

# Iterate through the request queue with max_concurrent < num_reqs
{    
    my $queue = Kronometrix::Webrec::Queue->new(
        config_file             => 'webrec.json',
        max_concurrent_requests => 3,
        agent_name              => 'Hank Schroeder',
        verbose                 => 0,
        precision               => 3,
    );  

    $queue->add_requests;
    is $queue->{index}, $queue->{max_concurrent},
        'Request index equals max_concurrent';
    is $queue->{num_active_reqs}, $queue->{max_concurrent},
        'Active requests equals max_concurrent';
    
}

# Iterate through the request queue with max_concurrent > num_reqs
{    
    my $queue = Kronometrix::Webrec::Queue->new(
        config_file             => 'webrec.json',
        agent_name              => 'Hank Schroeder',
        max_concurrent_requests => 5,
        verbose                 => 0,
        precision               => 3,
    );  

    $queue->add_requests;
    is $queue->{index}, $queue->{num_reqs},
        'Request index equals number of requests';
    is $queue->{num_active_reqs}, $queue->{num_reqs},
        'Active requests equals number of requests';
    
}

done_testing();
