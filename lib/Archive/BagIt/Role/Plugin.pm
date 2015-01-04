use strict;
use warnings;
package Archive::BagIt::Role::Plugin;

use Moose::Role;

use namespace::autoclean;

has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  default => __PACKAGE__,
);

has bagit => (
  is  => 'ro',
  isa => 'Archive::BagIt::Base',
  required => 1,
  weak_ref => 1,
);

sub BUILD {
    my ($self) = @_;
    my $plugin_name = $self->plugin_name;
    $self->bagit->plugins( { $plugin_name => $self });
}

1;
