package Kronometrix::Svcrec::Probe::NTP;

use parent Kronometrix::Svcrec::Probe;
use strict;
use warnings;
use feature ':5.24';

# The probe was taken from Net::NTPTime
sub probe {
    return "\010" . "\0" x 47;
};

1;
