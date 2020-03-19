use strict;
use warnings;

#ABSTRACT: The md5 plugin (default)
package Archive::BagIt::Plugin::Manifest::MD5;

use Moose;
with 'Archive::BagIt::Role::Manifest';


use Digest::MD5;
use Sub::Quote;

has 'plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Manifest::MD5',
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
    $self->bagit->load_plugins(("Archive::BagIt::Plugin::Algorithm::MD5"));
    $self->algorithm($self->bagit->plugins->{"Archive::BagIt::Plugin::Algorithm::MD5"});
    return 1;
}

sub verify_file {
    my ($self, $fh) = @_;
    return;
}

sub verify {
    my ($self) =@_;
    return;
}


1;
