use strict;
use warnings;
package Archive::BagIt::Base;

use Moo;

=head1 NAME

Achive::BagIt::Base - The common base for both Bagit and dotBagIt

=cut

has 'bag_path' => (
    is => 'rw',
);

has 'checksum_algos' => (
    is => 'rw', #this could probably be rw
    default => quote_sub ' qw(md5 sha1); ';
);
has 'manifest_files' => (
    is => 'lazy',
);

has 'tag_manifests' => (
    is => 'lazy',
);

has 'entries' => (
    is => 'lazy',
);

has 'tagentries' => (

);

has 'payload_files' => (

);

has 'non_payload_files' => (

);

sub _build_manifest_files {
  my($self) = @_;
  my @manifest_files;
  foreach my $algo (@{$self->{'checksum_algos'}}) {
    my $manifest_file = $self->{"bag_path"}."/manifest-$algo.txt";
    if (-f $manifest_file) {
      push @manifest_files, $manifest_file;
    }
  }
  #print Dumper(@manifest_files);
  return @manifest_files;
}

sub _load_manifests {
  my ($self) = @_;

  my @manifests = $self->manifest_files();
  foreach my $manifest_file (@manifests) {
    die("Cannot open $manifest_file: $!") unless (open (MANIFEST, $manifest_file));
    while (my $line = <MANIFEST>) {
        chomp($line);
        my ($digest,$file);
        ($digest, $file) = $line =~ /^([a-f0-9]+)\s+([a-zA-Z0-9_\.\/\-]+)/;
        if(!$file) {
          die ("This is not a valid manifest file");
        } else {
          print "file: $file \n" if $DEBUG;
          $self->{entries}->{$file} = $digest;
        }
    }
    close(MANIFEST);
  }

  return $self;

}

sub _load_tagmanifests {
  my ($self) = @_;

  my @tagmanifests = $self->tagmanifest_files();
  foreach my $tagmanifest_file (@tagmanifests) {
    die("Cannot open $tagmanifest_file: $!") unless (open(TAGMANIFEST, $tagmanifest_file));
    while (my $line = <TAGMANIFEST>) {
      chomp($line);
      my($digest,$file) = split(/\s+/, $line, 2);
      $self->{tagentries}->{$file} = $digest;
    }
    close(TAGMANIFEST);

  }
  return $self;
}




1;
