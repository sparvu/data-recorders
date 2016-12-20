use Test::More;
use Capture::Tiny qw(capture);
use strict;
use warnings;
use autodie;
use feature ':5.10';

# Tests for single connections

BEGIN {
    use_ok 'Kronometrix::Webrec::Queue';
}


$ENV{KRMX_PREFIX} = 't';
$|++;

my ($stdout, $stderr, @result) = capture sub { 
    my $q = Kronometrix::Webrec::Queue->new(
        config_file             => 'webrec-error.json',
        max_concurrent_requests => 5,
        agent_name              => 'Kronometrix webrec testing',
        precision               => 0,
        verbose                 => 1,
        debug                   => 0,
    );
    $q->process; 
};

# note $stdout;
# note $stderr;

like $stdout, qr/NA:NA:NA:NA:NA:NA:0$/,
    'Report is full of NA';
like $stderr, qr/Error code: 6/,
    'Error code is reported';
like $stderr, qr/Error message:/,
    'Error message is reported';

done_testing();
