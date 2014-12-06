use strict;
use warnings;

#ABSTRACT: The md5 plugin (default)
package Archive::BagIt::Plugin::Manifest::Diff;

use Moose;
use namespace::autoclean;
with 'Archive::BagIt::Role::Manifest';




__PACKAGE__->meta->make_immutable;

1;
