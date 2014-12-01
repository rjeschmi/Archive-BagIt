use strict;
use warnings;

#ABSTRACT: A role that defines the interface to a hashing algorithm
#

package Archive::BagIt::Role::Algorithm;

use Moose::Role;
with 'Archive::BagIt::Role::Plugin';

use Data::Printer;

has 'name' => (
    is => 'ro',
);


sub get_hash_string {
    my ($self, $fh) = @_;
}

sub verify_file {
    my ($self, $fh) = @_;
}

sub register_plugin {
    my ($class, $bagit) =@_;
    
    my $self = $class->new({bagit=>$bagit});

    my $plugin_name = $self->plugin_name;
    p ($self);
    $self->bagit->plugins( { $plugin_name => $self });
    $self->bagit->algos( {$self->name => $self });
}

1;
