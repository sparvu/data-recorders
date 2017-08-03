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
        config_file             => 'webrec.json',
        max_concurrent_requests => 5,
        agent_name              => 'Hank Schroeder',
        precision               => 0,
        verbose                 => 1,
    );
    $q->process; 
};

note $stdout;
#note $stderr;

done_testing();
