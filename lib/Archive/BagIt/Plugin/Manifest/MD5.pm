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
    is => 'ro',
    default=> quote_sub(q{ return 'md5';}),
);

sub create_manifest {
    my ($self) = @_;
    use Digest::MD5;
    my $manifest_file = $self->metadata_path."/manifest-md5.txt";
    # Generate MD5 digests for all of the files under ./data
    open(my $md5_fh, ">",$manifest_file) or die("Cannot create manifest-md5.txt: $!\n");
    foreach my $rel_payload_file (@{$self->payload_files}) {
        #print "rel_payload_file: ".$rel_payload_file;
        my $payload_file = File::Spec->catdir($self->bag_path, $rel_payload_file);
        open(my $DATA, "<", "$payload_file") or die("Cannot read $payload_file: $!");
        my $digest = Digest::MD5->new->addfile($DATA)->hexdigest;
        close($DATA);
        print($md5_fh "$digest  $rel_payload_file\n");
        #print "lineout: $digest $filename\n";
    }
    close($md5_fh); 

}

sub verify_file {
    my ($self, $fh) = @_;
}

sub verify {
    my ($self) =@_;


}


1;
