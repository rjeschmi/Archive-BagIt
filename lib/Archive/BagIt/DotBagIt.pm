use strict;
use warnings;


package Archive::BagIt::DotBagIt;

# VERSION

use Sub::Quote;
use Moo;

extends "Archive::BagIt::Base";

=head1 NAME

Archive::BagIt::DotBagIt - The inside-out version of BagIt

=cut

has 'metadata_path' => (
    is=> 'rw',
    default => sub { my ($self) = @_; return $self->bag_path."/.bagit"; },
);

has 'payload_path' => (
    is => 'rw',
    default => sub { my ($self) = @_; return $self->bag_path; },
);

1;
