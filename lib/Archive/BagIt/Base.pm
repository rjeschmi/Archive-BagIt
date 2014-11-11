use strict;
use warnings;

package Archive::BagIt::Base;
use Data::Printer;
use File::Find;
use Digest::MD5;

# VERSION 

use Sub::Quote;
use Moo;

my $DEBUG=0;

=head1 NAME

Achive::BagIt::Base - The common base for both Bagit and dotBagIt

=cut

has 'bag_path' => (
    is => 'rw',
);

has 'metadata_path' => (
    is=> 'rw',
    default => sub { my ($self) = @_; return $self->bag_path; },
);

has 'payload_path' => (
    is => 'rw',
    default => sub { my ($self) = @_; return $self->bag_path."/data"; },
);

has 'checksum_algos' => (
    is => 'lazy',
);

has 'bag_version' => (
    is => 'lazy',
);

has 'bag_checksum' => (
    is => 'lazy',
);

has 'manifest_files' => (
    is => 'lazy',
);

has 'tagmanifest_files' => (
    is => 'lazy',
);

has 'manifest_entries' => (
    is => 'lazy',
);

has 'tagmanifest_entries' => (
    is => 'lazy',
);

has 'payload_files' => (
    is => 'lazy',
);

has 'non_payload_files' => (
    is=>'lazy',
);

around 'BUILDARGS' , sub {
    my ($orig, $class, $bag_path) = @_;
    return $class->$orig(bag_path=>$bag_path);
};

sub _build_checksum_algos {
    my($self) = @_;
    my $checksums = [ 'md5', 'sha1' ];
    return $checksums;
}

sub _build_bag_checksum {
  my($self) =@_;
  my $bagit = $self->{'bag_path'};
  open(my $SRCFILE, "<",  $bagit."/manifest-md5.txt");
  binmode($SRCFILE);
  my $srchex=Digest::MD5->new->addfile($SRCFILE)->hexdigest;
  close($SRCFILE);
  return $srchex;
}

sub _build_manifest_files {
  my($self) = @_;
  my @manifest_files;
  p $self->checksum_algos;
  foreach my $algo (@{$self->checksum_algos}) {
    my $manifest_file = $self->metadata_path."/manifest-$algo.txt";
    if (-f $manifest_file) {
      push @manifest_files, $manifest_file;
    }
  }
  #print Dumper(@manifest_files);
  return \@manifest_files;
}

sub _build_tagmanifest_files {
  my ($self) = @_;
  my @tagmanifest_files;
  foreach my $algo (@{$self->checksum_algos}) {
    my $tagmanifest_file = $self->metadata_path."/tagmanifest-$algo.txt";
    if (-f $tagmanifest_file) {
      push @tagmanifest_files, $tagmanifest_file;
    }
  }
  return \@tagmanifest_files;

}

sub _build_tagmanifest_entries {
  my ($self) = @_;

  my @tagmanifests = @{$self->tagmanifest_files};
  my $tagmanifest_entries = {};
  foreach my $tagmanifest_file (@tagmanifests) {
    die("Cannot open $tagmanifest_file: $!") unless (open(my $TAGMANIFEST,"<", $tagmanifest_file));
    while (my $line = <$TAGMANIFEST>) {
      chomp($line);
      my($digest,$file) = split(/\s+/, $line, 2);
      $tagmanifest_entries->{$file} = $digest;
    }
    close($TAGMANIFEST);

  }
  return $tagmanifest_entries;
}

sub _build_manifest_entries {
  my ($self) = @_;

  my @manifests = @{$self->manifest_files};
  my $manifest_entries = {};
  foreach my $manifest_file (@manifests) {
    die("Cannot open $manifest_file: $!") unless (open (my $MANIFEST, $manifest_file));
    while (my $line = <$MANIFEST>) {
        chomp($line);
        my ($digest,$file);
        ($digest, $file) = $line =~ /^([a-f0-9]+)\s+([a-zA-Z0-9_\.\/\-]+)/;
        if(!$file) {
          die ("This is not a valid manifest file");
        } else {
          print "file: $file \n" if $DEBUG;
          $manifest_entries->{$file} = $digest;
        }
    }
    close($MANIFEST);
  }

  return $manifest_entries;

}

sub _build_payload_files{
  my($self) = @_;

  my $payload_dir = $self->payload_path;

  my @payload=();
  File::Find::find( sub{
    push(@payload,$File::Find::name);
    #print "name: ".$File::Find::name."\n";
  }, $payload_dir);

  return @payload;

}

sub _build_bag_version {
    my($self) = @_;
    my $bagit = $self->metadata_path;
    my $file = join("/", $bagit, "bagit.txt");
    open(my $BAGIT, "<", $file) or die("Cannot read $file: $!");
    my $version_string = <$BAGIT>;
    my $encoding_string = <$BAGIT>;
    close($BAGIT);
    $version_string =~ /^BagIt-Version: ([0-9.]+)$/;
    return $1 || 0;
}

sub _build_non_payload_files {
  my($self) = @_;

  my @payload = ();
  File::Find::find( sub {
    if(-f $File::Find::name) {
      my ($relpath) = ($File::Find::name=~m!$self->{"bag_path"}/(.*$)!);
      push(@payload, $relpath);
    }
    elsif(-d _ && $_ eq "data") {
      $File::Find::prune=1;
    }
    else {
      #directories in the root other than data?
    }
  }, $self->{"bag_path"});

  return @payload;

}

sub verify_bag {
    my ($self,$opts) = @_;
    #removed the ability to pass in a bag in the parameters, but might want options
    #like $return all errors rather than dying on first one
    my $bagit = $self->bag_path;
    my $manifest_file = $self->metadata_path."/manifest-md5.txt";
    my $payload_dir   = $self->payload_path;
    my $return_all_errors = $opts->{return_all_errors};
    my %invalids;
    my @payload       = ();

    die("$manifest_file is not a regular file") unless -f ($manifest_file);
    die("$payload_dir is not a directory") unless -d ($payload_dir);

    unless ($self->bag_version > .95) {
        die ("Bag Version is unsupported");
    }

    # Read the manifest file
    #print Dumper($self->{entries});
    my %manifest = %{$self->manifest_entries};

    # Compile a list of payload files
    find(sub{ push(@payload, $File::Find::name)  }, $payload_dir);

    # Evaluate each file against the manifest
    my $digestobj = new Digest::MD5;
    foreach my $file (@payload) {
        next if (-d ($file));
        my $local_name = substr($file, length($bagit) + 1);
        my ($digest);
        unless ($manifest{$local_name}) {
          die ("file found not in manifest: [$local_name]");
        }
        #my $start_time=time();
        open(my $fh, "<", "$bagit/$local_name") or die ("Cannot open $local_name");
        $digest = $digestobj->addfile($fh)->hexdigest;
        print $digest."\n";
        close($fh);
        #print "$bagit/$local_name md5 in ".(time()-$start_time)."\n";
        unless ($digest eq $manifest{$local_name}) {
          if($return_all_errors) {
            $invalids{$local_name} = $digest;
          }
          else {
            die ("file: $local_name invalid");
          }
        }
        delete($manifest{$local_name});
    }
    if($return_all_errors && keys(%invalids) ) {
      foreach my $invalid (keys(%invalids)) {
        print "invalid: $invalid hash: ".$invalids{$invalid}."\n";
      }
      die ("bag verify failed with invalid files");
    }
    # Make sure there are no missing files
    if (keys(%manifest)) { die ("Missing files in bag"); }

    return 1;
}

=head2 make_bag
  A constructor that will make and return a bag from a direcory

  If a data directory exists, assume it is already a bag (no checking for invalid files in root)

=cut

sub make_bag {
  my ($class, $bag_path) = @_;
  unless ( -d $bag_path) { die ( "source bag directory doesn't exist"); }
  my $self = $class->new(bag_path=>$bag_path);
  unless ( -d $self->payload_path) {
    rename ($bag_dir, $bag_dir.".tmp");
    mkdir  ($bag_dir);
    rename ($bag_dir.".tmp", $self->payload_path);
  }
  unless ( -d $self->metadata_path) {
    #metadata path is not the root path for some reason
    mkdir ($self->metadata_path);
  }
  $self->_write_bagit();
  $self->_write_baginfo();
  $self->_manifest_md5();
  $self->_tagmanifest_md5();
  return $self;
}

sub _write_bagit {
    my($self) = @_;
    open(my $BAGIT, ">", $self->metadata_path."/bagit.txt") or die("Can't open $self->metadata_path/bagit.txt for writing: $!");
    print($BAGIT "BagIt-Version: 0.97\nTag-File-Character-Encoding: UTF-8");
    close($BAGIT);
    return 1;
}

sub _write_baginfo {
    use POSIX;
    my($self, %param) = @_;
    open(my $BAGINFO, ">", $self->metadata_path."/bag-info.txt") or die("Can't open $self->metadata_path/bag-info.txt for writing: $!");
    $param{'Bagging-Date'} = POSIX::strftime("%F", gmtime(time));
    $param{'Bag-Software-Agent'} = 'Archive::BagIt <http://search.cpan.org/~rjeschmi/Archive-BagIt>';
    while(my($key, $value) = each(%param)) {
        print($BAGINFO "$key: $value\n");
    }
    close($BAGINFO);
    return 1;
}

sub _write_manifest_md5 {
    use Digest::MD5;
    my($self) = @_;
    my $manifest_file = $self->metadata_path."/manifest-md5.txt";
    my $data_dir = $self->payload_path;
    print "creating manifest: $data_dir\n";
    # Generate MD5 digests for all of the files under ./data
    open(my $md5_fh, ">",$manifest_file) or die("Cannot create manifest-md5.txt: $!\n");
    find(
        sub {
            my $file = $File::Find::name;
            if (-f $_) {
                open(my $DATA, "<", "$_") or die("Cannot read $_: $!");
                my $digest = Digest::MD5->new->addfile($DATA)->hexdigest;
                close($DATA);
                my $filename = substr($file, length($bagit) + 1);
                print($md5_fh "$digest  $filename\n");
                #print "lineout: $digest $filename\n";
            }
        },
        $data_dir
    );
    close($md5_fh);
}

sub _tagmanifest_md5 {
  my ($self) = @_;

  use Digest::MD5;

  my $tagmanifest_file= $self->metadata_path."/tagmanifest-md5.txt";

  open (my $md5_fh, ">", $tagmanifest_file) or die ("Cannot create tagmanifest-md5.txt: $! \n");

  find (
    sub {
      my $file = $File::Find::name;
      if ($_=~m/^data$/) {
        $File::Find::prune=1;
      }
      elsif ($_=~m/^tagmanifest-.*\.txt/) {
        # Ignore, we can't take digest from ourselves
      }
      elsif ( -f $_ ) {
        open(my $DATA, "<", "$_") or die("Cannot read $_: $!");
        my $digest = Digest::MD5->new->addfile($DATA)->hexdigest;
        close($DATA);
        my $filename = substr($file, length($self->metadata_path) + 1);
        print($md5_fh "$digest  $filename\n");
      }
  }, $bagit);

  close($md5_fh);
}

1;
