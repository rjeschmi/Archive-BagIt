use strict;
use warnings;

#ABSTRACT: The default MD5 algorithm plugin

package Archive::BagIt::Plugin::Algorithm::MD5;

use Moose;
use namespace::autoclean;

with 'Archive::BagIt::Role::Algorithm';

has 'name' => ( 
    is => ro,
    isa => 'Str',
    default => 'md5',
);

has '_digest_md5' => (
    is => 'ro',
    lazy => 1,
    init_arg => undef,
);

sub _build_digest_md5 {
    my ($self) = @_;
    my $digest_md5 = new Digest::MD5;
    return $digest_md5;
}

sub get_hash_string {
    my ($self, $fh) = @_;

    return $self->_digest_md5->addfile($fh)->hexdigest;

}

sub verify_file {
    my ($self, $filename) = @_;

}
__PACKAGE__->meta->make_immutable;
1;
