package Archive::BagIt::App::Verify;

use MooseX::App::Command;

parameter 'bag_path' => (
  is=>'rw',
  isa=>'Str',
  documentation => q[This is the path to run verify on],
  required => 1,
);

option 'return_all_errors' => (
  is => 'rw',
  isa => 'Bool',
  documentation => q[collect all errors rather than dying on first],
);

option 'fast' => (
  is => 'rw',
  isa => 'Bool',
  documentation => q[use Archive::BagIt::Fast instead...],
);

sub abstract {
  return 'verifies a valid bag';
}


sub run {
  my ( $self) = @_;

  use Archive::BagIt;
  my $bag_path = $self->bag_path;
  my ($bag);
  if($self->fast) {
    $bag = Archive::BagIt::Fast->new($bag_path);
  }
  else {
    $bag = Archive::BagIt->new($bag_path);
  }
  eval {
      $bag->verify_bag();
  };
  if ($@) {
      print "FAIL: ".$bag_path." : $! $@\n";
  }
  else {
      print "PASS: ".$bag_path."\n";
  }
}

1; 
