use 5.024000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Kronometrix',
    VERSION_FROM      => 'lib/Kronometrix.pm', 
    PREREQ_PM         => {
		'Net::Ping'   => 2.59,
		'Getopt::Std' => 0,
		'Net::Curl'   => 0.37,
		'JSON'        => 0,
    },
    ABSTRACT_FROM     => 'lib/Kronometrix.pm', # retrieve abstract from module
    AUTHOR            => 'Kronometrix Support <support@kronometrix.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
