use strict;
use warnings;
package Archive::BagIt::Role::Manifest;

use Moose::Role;
with 'Archive::BagIt::Role::Plugin';

use namespace::autoclean;

use Data::Printer;

has 'algorithm' => (
    is => 'rw',
    isa => 'Archive::BagIt::Role::Algorithm',
);


sub verify_file {

}

sub verify {

}

sub manifest {

}


sub register_plugin {
    my ($class, $bagit) = @_;
    
    my $self = $class->new({bagit=>$bagit});
    my $plugin_name = $self->plugin_name;
    p ($self);
    $self->bagit->plugins( { $plugin_name => $self });
    $self->bagit->algo( {$self->algorithm => $self });

}

1;
