package Archive::BagIt::Cmd::Command::create;

use Moose;
extends qw(MooseX::App::Cmd::Command);

sub abstract {
  return 'creates a valid bag out of the files contained within a directory';
}


sub execute {
  my ( $self, $opt, $args) = @_;

  use Archive::BagIt;

  foreach my $dir (@$args){
    my $bag = Archive::BagIt->make_bag($dir);
  }
}


  
