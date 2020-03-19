use strict;
use warnings;

#ABSTRACT: A role that defines the interface to a hashing algorithm
#

package Archive::BagIt::Role::Algorithm;

use Moose::Role;
with 'Archive::BagIt::Role::Plugin';

has 'name' => (
    is => 'ro',
);


sub get_hash_string {
    my ($self, $fh) = @_;
    return;
}

sub verify_file {
    my ($self, $fh) = @_;
    return;
}

sub register_plugin {
    my ($class, $bagit) =@_;
    my $self = $class->new({bagit=>$bagit});
    my $plugin_name = $self->plugin_name;
    $self->bagit->plugins( { $plugin_name => $self });
    $self->bagit->algos( {$self->name => $self });
    return 1;
}
no Moose;
1;
