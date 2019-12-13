use strict;
use warnings;
package Archive::BagIt::Role::Manifest;

use Moose::Role;
with 'Archive::BagIt::Role::Plugin';

use namespace::autoclean;

has 'algorithm' => (
    is => 'rw',
    isa=>'HashRef',
);

sub BUILD {}

after BUILD => sub {
    my $self = shift;
    $self->bagit->manifests ({$self->algorithm->name, $self}) ;
};

sub verify_file {

}

sub verify {

}

sub manifest {

}

sub create_manifest {
    my ($self) = @_;

    my $algo = $self->algorithm->name;
    my $manifest_file = $self->bagit->metadata_path."/manifest-${algo}.txt";
    # Generate digests for all of the files under ./data
    open(my $fh, ">",$manifest_file) or die("Cannot create manifest-${algo}.txt: $!\n");
    foreach my $rel_payload_file (@{$self->bagit->payload_files}) {
        #print "rel_payload_file: ".$rel_payload_file;
        my $payload_file = File::Spec->catdir($self->bagit->bag_path, $rel_payload_file);
        my $digest = $self->algorithm->verify_file( $payload_file );
        print($fh "$digest  $rel_payload_file\n");
        #print "lineout: $digest $filename\n";
    }
    close($fh);

}

sub create_tagmanifest {
  my ($self) = @_;

    my $algo = $self->algorithm->name;
    my $tagmanifest_file= $self->bagit->metadata_path."/tagmanifest-${algo}.txt";

    open (my $fh, ">", $tagmanifest_file) or die ("Cannot create tagmanifest-${algo}.txt: $! \n");

    foreach my $rel_nonpayload_file (@{$self->bagit->non_payload_files}) {
        my $nonpayload_file = File::Spec->catdir($self->bagit->bag_path, $rel_nonpayload_file);
        if ($rel_nonpayload_file=~m/tagmanifest-.*\.txt$/) {
            # Ignore, we can't take digest from ourselves
        }
        elsif ( -f $nonpayload_file && $nonpayload_file=~m/.*\.txt$/) {
            my $digest = $self->algorithm->verify_file( $nonpayload_file );
            print($fh "$digest  $rel_nonpayload_file\n");
        }
        else {
            die("A file or directory that doesn't match: $rel_nonpayload_file");
        }
    }

  close($fh);
}


sub create_bagit {
    my($self) = @_;
    open(my $BAGIT, ">", $self->bagit->metadata_path."/bagit.txt") or die("Can't open $self->bagit->metadata_path/bagit.txt for writing: $!");
    print($BAGIT "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8");
    close($BAGIT);
    return 1;
}

sub create_baginfo {
    use POSIX;
    my($self, %param) = @_;
    open(my $BAGINFO, ">", $self->bagit->metadata_path."/bag-info.txt") or die("Can't open $self->bagit->metadata_path/bag-info.txt for writing: $!");
    $param{'Bagging-Date'} = POSIX::strftime("%F", gmtime(time));
    $param{'Bag-Software-Agent'} = 'Archive::BagIt <http://search.cpan.org/~rjeschmi/Archive-BagIt>';
    while(my($key, $value) = each(%param)) {
        print($BAGINFO "$key: $value\n");
    }
    close($BAGINFO);
    return 1;
}

1;
