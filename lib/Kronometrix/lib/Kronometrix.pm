package Kronometrix;

use JSON;
use strict;
use warnings;

our $VERSION = 0.17;

# Open JSON configuration file
sub open_config {
    my ($proto, $conf) = @_;

    my $json_data;

    {
        local $/;

        # We will parse now the file
        if ( defined $ENV{'KRMX_PREFIX'} ) {
            if ( -e "$ENV{'KRMX_PREFIX'}/etc/$conf" ) {
                open my $fh, "<", "$ENV{'KRMX_PREFIX'}/etc/$conf";
                $json_data = <$fh>;
                close $fh;
            }
            else {
                die "error: $ENV{'KRMX_PREFIX'}/etc/$conf - file not found\n";
            }
        }
        else {
            if ( -e "/opt/kronometrix/etc/$conf" ) {
                open my $fh, "<", "/opt/kronometrix/etc/$conf";
                $json_data = <$fh>;
                close $fh;
            }
            else {
                die "error: /opt/kronometrix/etc/$conf - file not found\n";
            }
        }
    }

    my $perl_data = decode_json $json_data;

    return $perl_data;
}


sub log_to_file {
    my ($proto, $kfile, $program) = @_;

    # kronometrix.json config file
    my $kdata = $proto->open_config($kfile);

    # get log destinations
    my ($baselog, $curlog) = $proto->get_log($kdata);

    # Redirect STDOUT, STDERR to their log files
    my $rlog = "$baselog/$program.log";
    open STDERR, '>>', $rlog
        or die "error: open_file - cannot open $rlog $!";

    my $klog = "$curlog/$program.krd";
    open STDOUT, '>>', $klog
        or die "error: open_file - cannot open $klog $!";
}

# get log defintion
sub get_log {
    my ($proto, $data) = @_;

    my $bpath = $data->{'log'}->{'base_path'};
    my $cpath = $data->{'log'}->{'current_path'};

    return ( $bpath, $cpath );
}

# Log warnings in verbose level
sub warnings_to_log {
    my $self = shift;
    my $code = sub {
        my $w = shift;
        chomp $w;
        $self->write_log("WARNING: $w");
    };
    $SIG{__WARN__} = $code;
}

# Write log message
sub write_log {
    my ($self, $logbuf) = @_;
    $self->_write_log($logbuf);
}

sub write_verbose {
    my ($self, $logbuf) = @_;
    return unless $self->{verbose};
    $self->_write_log($logbuf);
}

sub write_debug {
    my ($self, $logbuf) = @_;
    return unless $self->{debug};
    $self->_write_log($logbuf);
}

sub _write_log {
    my ($self, $logbuf) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
      localtime(time);

    my $dt = sprintf "%4d-%02d-%02d %02d:%02d:%02d",
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec;

    say STDERR "$dt $logbuf";
}


1;

=pod

=head1 NAME

Kronometrix - Data recorders of performance metrics

=head1 DESCRIPTION

Kronometrix includes a simple and efficient set of data recorders and transport utilities for ICT, Environmental Monitoring, Meteorology and IoT industries, responsible to record top essential performance metrics, save raw data and transport it for further analysis. This module implements some basic utilities used by some of these recorders.

=cut
