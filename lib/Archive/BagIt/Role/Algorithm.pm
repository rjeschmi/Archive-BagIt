use strict;
use warnings;

#ABSTRACT: A role that defines the interface to a hashing algorithm
#

package Archive::BagIt::Role::Algorithm;

use Moose;
use Moose::Role;

has 'name' => ( );

sub get_hash_string {
    my ($self, $fh) = @_;
}

sub verify_file {
    my ($self, $fh) = @_;
}

1;
