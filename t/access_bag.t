# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }

use utf8;
use open ':std', ':encoding(utf8)';
use Test::More tests => 13;
use Test::Exception;
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
{
  my @unsorted = (
      { "Foo", "Baz"},
      { "Foo3", "Bar3"},
      { "Foo", "Bar" },
      { "Foo5", "Bar5"},
      { "Foo2", "Bar2"},
      { "Foo4", "Bar4\n  Baz4\n  Bay4"},
  );
  my @sorted = Archive::BagIt::Base::__sort_bag_info( @unsorted);
  my @expected = (
      { "Foo", "Bar" },
      { "Foo", "Baz"},
      { "Foo2", "Bar2"},
      { "Foo3", "Bar3"},
      { "Foo4", "Bar4\n  Baz4\n  Bay4"},
      { "Foo5", "Bar5"}
  );
  is_deeply( \@sorted, \@expected, "__sort_bag_info");
}



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
Foo6: Bar6: Baz6
BAGINFO
  my @expected = (
      { "Foo", "Bar" },
      { "Foo", "Baz"},
      { "Foo2", "Bar2"},
      { "Foo3", "Bar3"},
      { "Foo4", "Bar4\n  Baz4\n  Bay4"},
      { "Foo5", "Bar5"},
      { "Foo6", "Bar6: Baz6"}
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
is ($bag->bag_info_by_key("Payload-Oxum"), "4.2", "bag_info_by_key, existing");
is ($bag->bag_info_by_key("NoKEY"), undef, "bag_info_by_key, not found");
is ($bag->_replace_bag_info_by_first_match("NoKey", "test"), undef, "_replace_bag_info_by_first_match, not found");
is ($bag->_add_or_replace_bag_info("Key", "Value"), -1, "add a new key-value");
is ($bag->_replace_bag_info_by_first_match("Key", "0.0"), 3, "_replace_bag_info_by_first_match, index");
is ($bag->bag_info_by_key("Key"), "0.0", "_replace_bag_info_by_first_match, check new value");
throws_ok ( sub {$bag->_add_or_replace_bag_info("Foo:Bar", "Baz")}, qr/key should not contain a colon/, "_add_or_replace_bag_info, invalid key check");
throws_ok ( sub {$bag->_replace_bag_info_by_first_match("Foo:Bar", "Baz")}, qr/key should not contain a colon/, "_replace_bag_info_by_first_match, invalid key check");


#p( $bag );
__END__
