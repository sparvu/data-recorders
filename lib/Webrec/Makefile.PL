use 5.020000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Kronometrix::Webrec::Queue',
    VERSION_FROM      => 'lib/Kronometrix/Webrec/Queue.pm', 
    PREREQ_PM         => {
        'Net::Curl'      => 0,
        'List::Util'     => 0,
        'Scalar::Util'   => 0,
        'JSON'           => 0,
        'Time::HiRes'    => 0,
        'Carp'           => 0,
    }, 
    TEST_REQUIRES    => {
        'Capture::Tiny'  => 0,
    },
    EXE_FILES         => ['bin/webrec'],
    INSTALLSITESCRIPT => '/opt/kronometrix/bin',
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/Kronometrix/Webrec/Queue.pm', 
       AUTHOR         => 'Julio Fraire <julio@>') : ()),
);
