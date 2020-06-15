use strict;
use warnings;

#ABSTRACT: The default SHA algorithms plugin

package Archive::BagIt::Plugin::Algorithm::SHA512;

use Moose;
use namespace::autoclean;

with 'Archive::BagIt::Role::Algorithm';

has 'plugin_name' => (
    is => 'ro',
    default => 'Archive::BagIt::Plugin::Algorithm::SHA512',
);

has 'name' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'sha512',
);

has '_digest_sha' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_digest_sha',
    init_arg => undef,
);

sub _build_digest_sha {
    my ($self) = @_;
    my $digest = Digest::SHA->new("512");
    return $digest;
}

sub get_hash_string {
    my ($self, $fh) = @_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat $fh;
    my $buffer;
    while (read($fh, $buffer, $blksize)) {
        $self->_digest_sha->add($buffer);
    }
    return $self->_digest_sha->hexdigest;
}

sub verify_file {
    my ($self, $filename) = @_;
    open(my $fh, '<', $filename) || die ("Can't open '$filename', $!");
    binmode($fh);
    my $digest = $self->get_hash_string($fh);
    close $fh || die("could not close file '$filename', $!");
    return $digest;
}
__PACKAGE__->meta->make_immutable;
1;
