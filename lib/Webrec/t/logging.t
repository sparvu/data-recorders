use Test::More tests => 5;
use Capture::Tiny qw(capture);
use strict;
use warnings;
use autodie;
use feature ':5.10';

# Tests for webrec.pl -- logging option

$| = 1;

BEGIN {
    use_ok 'Kronometrix::Webrec::Queue';
}


$ENV{KRMX_PREFIX} = 't';

foreach my $file ('t/log/current/webrec.krd', 't/log/webrec.log') {
    next unless -e $file;
    unlink $file or die $!;
    note "File $file still exists!" if -e $file;
}

system('bin/webrec', '-l');

ok -e "t/log/current/webrec.krd",
    'Results file webrec.krd was created';
ok -e "t/log/webrec.log",
    'Log file webrec.log was created';

ok -s "t/log/current/webrec.krd",
    'webrec.krd is not empty';
ok -s "t/log/webrec.log",
    'webrec.log is not empty';

done_testing();
