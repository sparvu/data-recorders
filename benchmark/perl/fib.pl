sub fib {
  my $n = shift;
  if ( $n <= 2 ) { return 1; }
  return fib($n - 1) + fib($n - 2);
}


#sub fib {
#    return @_[0] < 2 ? @_[0] : fib(@_[0]-1) + fib(@_[0]-2)
#}

print fib(47)
