use strict;
use warnings;
package Archive::BagIt::Role::Plugin;

use Moose::Role;

use namespace::autoclean;

has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has bagit => (
  is  => 'ro',
  isa => class_type('Archive::BagIt'),
  required => 1,
  weak_ref => 1,
);

sub register_plugin {
    my ($self, $bagit);

    $self->bagit = $bagit;
    push $self->bagit->plugins, $self;
}

1;
