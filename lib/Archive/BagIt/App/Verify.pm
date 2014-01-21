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

sub abstract {
  return 'verifies a valid bag';
}


sub run {
  my ( $self, $opt, $args) = @_;

  use Archive::BagIt;

  foreach my $dir (@$args){
    my $bag = Archive::BagIt->new($dir);
    eval {
      $bag->verify_bag($dir);
    };
    if ($@) {
      print "FAIL: ".$dir." : $! $@\n";
    }
    else {
      print "PASS: ".$dir."\n";
    }
  }
}

1; 
