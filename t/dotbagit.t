
BEGIN { chdir 't' if -d 't' }

use Test::More 'no_plan';
use strict;


use lib '../lib';

use File::Spec;
use Data::Printer;
use File::Path;
use File::Copy;

my $Class = 'Archive::BagIt::DotBagIt';
use_ok($Class);

my @ROOT = grep {length} 'src','dotbagit';

warn "what is this: ".p(@ROOT);


my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');


#validate tests

{
  my $bag = $Class->new({bag_path=>$SRC_BAG});
  ok($bag,        "Object created");
  isa_ok ($bag,   $Class);

  print "checksum algos:".p $bag->checksum_algos;
  print "manifest files:".p $bag->manifest_files;
  print "bag path:".p $bag->bag_path;
  print "metadata path: ".p $bag->metadata_path;
  p $bag->tagmanifest_files;
  p $bag->manifest_entries;
  p $bag->tagmanifest_entries;
  print "payload files".p $bag->payload_files;

  my $result = $bag->verify_bag;
  ok($result,     "Bag verifies");
}

{
  mkdir($DST_BAG);
  copy($SRC_FILES."/1", $DST_BAG);
  copy($SRC_FILES."/2", $DST_BAG);

  my $bag = $Class->make_bag($DST_BAG);

  ok ($bag,       "Object created");
  isa_ok ($bag,   $Class);
  my $result = $bag->verify_bag();
  ok($result,     "Bag verifies");

  #rmtree($DST_BAG);
}

{

  my $bag = $Class->new($SRC_BAG);
  my @manifests = $bag->manifest_files();
  my $cnt = scalar @manifests;
  my $expect = 1;

  is($cnt, $expect, "All manifests counted");

  my @tagmanifests = $bag->tagmanifest_files();
  my $tagcnt = scalar @tagmanifests;
  my $tagexpect =1;

  is($tagcnt, $tagexpect, "All tagmanifests counted");

}

__END__