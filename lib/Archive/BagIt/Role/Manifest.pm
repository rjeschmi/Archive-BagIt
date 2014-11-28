use strict;
use warnings;
package Archive::BagIt::Role::Manifest;

use Moose::Role;
with 'Archive::BagIt::Role::Plugin';

use namespace::autoclean;

has 'algorithm' => (
    isa => 'Archive::BagIt::Role::Algorithm',
);


sub verify_file {

}

sub verify {

}

sub manifest {

}

sub manifest_files {

}

sub register_plugin {
    my ($class, $bagit) = @_;
    
    my $self = $class->new({bagit=>$bagit});
    push $self->bagit->plugins, $self;
    $self->bagit->algo->{$self->algorithm} = $self;

}
1;
