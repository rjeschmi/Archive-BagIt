use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Archive::BagIt',
    AUTHOR              => q{Robert Schmidt <rjeschmi@gmail.com>},
    VERSION_FROM        => 'lib/Archive/BagIt.pm',
    ABSTRACT_FROM       => 'lib/Archive/BagIt.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'cc0')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Archive-BagIt-*' },
);
