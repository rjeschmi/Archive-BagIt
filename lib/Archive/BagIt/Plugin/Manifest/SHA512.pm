use strict;
use warnings;

#ABSTRACT: The md5 plugin (default)
package Archive::BagIt::Plugin::Manifest::SHA512;

use Moose;
with 'Archive::BagIt::Role::Manifest';


use Digest::SHA;
use Sub::Quote;

has 'plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Manifest::SHA512',
);

has 'manifest_path' => (
    is => 'ro',
);

has 'manifest_files' => (
    is => 'ro',
);

has 'algorithm' => (
    is => 'rw',
);

sub BUILD {
    my ($self) = @_;
    $self->bagit->load_plugins(("Archive::BagIt::Plugin::Algorithm::SHA512"));
    $self->algorithm($self->bagit->plugins->{"Archive::BagIt::Plugin::Algorithm::SHA512"});
}

sub verify_file {
    my ($self, $fh) = @_;
}

sub verify {
    my ($self) =@_;


}


1;
