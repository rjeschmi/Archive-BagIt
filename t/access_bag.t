# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }

use utf8;
use open ':std', ':encoding(utf8)';
use Test::More tests => 4;
use strict;


use lib '../lib';

use File::Spec;
use Data::Printer;
use File::Path;
use File::Copy;

my $Class = 'Archive::BagIt::Base';
use_ok($Class);

my @ROOT = grep {length} 'src';

#warn "what is this: ".Dumper(@ROOT);


my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');

## tests
my $bag = $Class->new({bag_path=>$SRC_BAG});
is($bag->bag_version(), "0.96", "has expected bag version");
{
  my $input =<<BAGINFO;
Foo: Bar
Foo: Baz
Foo2 : Bar2
Foo3:   Bar3
Foo4: Bar4
  Baz4
  Bay4
Foo5: Bar5
BAGINFO
  my @expected = (
      { "Foo", "Bar" },
      { "Foo", "Baz"},
      { "Foo2", "Bar2"},
      { "Foo3", "Bar3"},
      { "Foo4", "Bar4\n  Baz4\n  Bay4"},
      { "Foo5", "Bar5"}
  );
  my $got = $bag->_parse_bag_info( $input );
  is_deeply( $got, \@expected, "bag-info parsing");
}
{
  my $got = $bag->bag_info();
  my @expected = (
      { "Bag-Software-Agent", "bagit.py <http://github.com/edsu/bagit>" },
      { "Bagging-Date", "2013-04-09"},
      { "Payload-Oxum", "4.2"}
    );
  is_deeply( $got, \@expected, "has all bag-info entries");
}

__END__
