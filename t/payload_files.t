#!perl -T

use Test::More 'no_plan';
use strict;


use lib '../lib';

use File::Spec;
use Data::Dumper;


my $Class = 'Archive::BagIt';
use_ok($Class);

my @ROOT = grep {length} 'src';

#warn "what is this: ".Dumper(@ROOT);


my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');


#validate tests

{
  my $bag = $Class->new($SRC_BAG);
  ok($bag,        "Object created");
  isa_ok ($bag,   $Class);

  my $result = $bag->verify_bag();

  ok($result,     "Bag verifies");
}
