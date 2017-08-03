use Test::More tests => 3;
use Capture::Tiny qw(capture);
use strict;
use warnings;
use feature ':5.10';

# Tests for multiple concurrent connections

$| = 1;

BEGIN {
    use_ok 'Kronometrix::Webrec::Queue';
}

$ENV{KRMX_PREFIX} = 't';

my ($stdout, $stderr, @result) = capture sub { 
    my $q = Kronometrix::Webrec::Queue->new(
        config_file             => 'webrec.json',
        max_concurrent_requests => 5,
        agent_name              => 'Kronometrix test',
        precision               => 2,
        verbose                 => 0,
    );
    $q->process;
};

# note $stdout;
# note $stderr;

# Make sure request was completed just after it was created
my @times;
while ($stdout =~ /^(\d+\.\d+):\w+:(\d+\.\d+)/gm) {
    push @times, [$1, $2];
}

@times = sort {$a->[0] <=> $b->[0]} @times;

# note explain \@times;
# diag $times[0]->[0];
# diag $times[-1]->[0];

ok @times > 0, 'Report is not empty';
ok $times[-1]->[0] - $times[0]->[0] < 0.01,
    'Requests were launched at the same time';
 
done_testing();

