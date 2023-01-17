
# Fibonacci(47)
my $n = 46;

my @cache = ( 1, 1 );
foreach ( 2 .. $n ) {
    $cache[$_] = $cache[$_-1] + $cache[$_-2];
}
 
print "$cache[-1]\n";
