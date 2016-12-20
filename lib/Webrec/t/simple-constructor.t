#! /usr/bin/env perl

use Test::More tests => 11;
use strict;
use warnings;

BEGIN {
    use_ok 'Kronometrix::Webrec::Queue';
}

$ENV{KRMX_PREFIX} = 't';

# Check simplified queue building

# This test will read a config file and it will build a queue of
# request objects
{    
    my $queue = Kronometrix::Webrec::Queue->new(
        config_file             => 'webrec.json',
        max_concurrent_requests => 5,
        agent_name              => 'Hank Schroeder',
        verbose                 => 0,
        precision               => 3,
    );  

    is ref $queue, 'Kronometrix::Webrec::Queue',
        'The constructor returned a blessed ref';

    # Attributes set by constructor
    is $queue->{config_file}, 'webrec.json',
        'config_file is correct';
    is $queue->{max_concurrent}, 5,
        'max_concurrent_requests turned into max_concurrent and set ok';
    is $queue->{verbose}, 0,
        'verbose attribute set correctly';
    is $queue->{precision}, 3,
        'precision attribute set correctly';
    
    # Internal attributes
    is $queue->{index}, 0,
        'request index set at zero';
    is $queue->{num_reqs}, 4,
        'The number of requests is correct';
    is scalar($queue->{queue}->@*), $queue->{num_reqs},
        'The number of request objects in the queue is correct';
    is $queue->{num_active_reqs}, 0,
        'The number of active requests is set to zero';
    is_deeply $queue->{store_active_reqs}, +{},
        'The store for active requests is an empty hash ref';
}

done_testing();
