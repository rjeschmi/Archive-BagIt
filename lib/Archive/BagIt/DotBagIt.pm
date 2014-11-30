use strict;
use warnings;


package Archive::BagIt::DotBagIt;

# VERSION

use Sub::Quote;
use Moose;

extends "Archive::BagIt::Base";

=head1 NAME

Archive::BagIt::DotBagIt - The inside-out version of BagIt

=cut

has 'metadata_path' => (
    is=> 'ro',
    lazy => 1,
    builder => '_build_metadata_path',
);

sub _build_metadata_path {
    my ($self) = @_;
    return $self->bag_path."/.bagit";
}

has 'payload_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_path',
);
    
sub _build_payload_path {
    my ($self) = @_; 
    return $self->bag_path; 

}

1;
