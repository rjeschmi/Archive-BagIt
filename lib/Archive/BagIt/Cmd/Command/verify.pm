package Archive::BagIt::Cmd::Command::verify;

use Moose;
extends qw(MooseX::App::Cmd::Command);

sub abstract {
  return 'verifies a valid bag';
}


sub execute {
  my ( $self, $opt, $args) = @_;

  use Archive::BagIt;

  foreach my $dir (@$args){
    my $bag = Archive::BagIt->new($dir);
    if($bag->verify_bag($dir) ) {
      print "OK: ".$dir."\n";
    }
    else {
      print "FAIL: ".$dir."\n";
    }
  }
}


  
