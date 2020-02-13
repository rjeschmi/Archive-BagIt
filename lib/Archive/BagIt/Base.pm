use strict;
use warnings;

package Archive::BagIt::Base;

use Moose;
use namespace::autoclean;

use utf8;
use open ':std', ':encoding(utf8)';
use Encode qw(decode);
use File::Find;
use File::Spec;
use File::stat;
use Digest::MD5;
use Class::Load qw(load_class);

# VERSION

use Sub::Quote;

my $DEBUG=0;

=head1 NAME

Achive::BagIt::Base - The common base for both Bagit and dotBagIt

=cut

has 'bag_path' => (
    is => 'rw',
);

has 'bag_path_arr' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_bag_path_arr',
);

has 'metadata_path' => (
    is=> 'ro',
    lazy => 1,
    builder => '_build_metadata_path',
);

sub _build_metadata_path { 
    my ($self) = @_; 
    return $self->bag_path; 
}


has 'metadata_path_arr' => (
    is =>'ro',
    lazy => 1,
    builder => '_build_metadata_path_arr',
);

has 'rel_metadata_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_rel_metadata_path',
);

has 'payload_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_path',
);

sub _build_payload_path { 
    my ($self) = @_; 
    return $self->bag_path."/data"; 
}

has 'payload_path_arr' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_path_arr',
);

has 'rel_payload_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_rel_payload_path',
);

has 'checksum_algos' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_checksum_algos',
);

has 'bag_version' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_bag_version',
);

has 'bag_info' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_bag_info',
);

# bag_info_by_key()
sub bag_info_by_key {
    my ($self, $searchkey) = @_;
    my $info = $self->bag_info();
    if (defined $searchkey) {
        foreach my $entry (@{$info}) {
            my ($key, $value) = each %{$entry};
            if (defined $key && $key eq $searchkey) {
                return $value;
            }
        }
    }
    undef;
}

has 'forced_fixity_algorithm' => (
    is   => 'ro',
    lazy => 1,
    builder  => '_build_forced_fixity_algorithm',
);

has 'bag_checksum' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_bag_checksum',
);

has 'manifest_files' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_manifest_files',
);

has 'tagmanifest_files' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_tagmanifest_files',
);

has 'manifest_entries' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_manifest_entries',
);

has 'tagmanifest_entries' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_tagmanifest_entries',
);

has 'payload_files' => ( # relatively to bagit base
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_files',
);

has 'non_payload_files' => (
    is=>'ro',
    lazy => 1,
    builder => '_build_non_payload_files',
);

has 'plugins' => (
    is=>'rw',
    isa=>'HashRef',
);

has 'manifests' => (
    is=>'rw',
    isa=>'HashRef',
);

has 'algos' => (
    is=>'rw',
    isa=>'HashRef',

);

=head2 BUILDARGS

The constructor sub, will create a bag with a single argument
=cut

around 'BUILDARGS' , sub {
    my $orig = shift;
    my $class = shift;
    if (@_ == 1 && !ref $_[0]) {
        return $class->$orig(bag_path=>$_[0]);
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my ($self, $args) = @_;
    $self->load_plugins(("Archive::BagIt::Plugin::Manifest::MD5", "Archive::BagIt::Plugin::Manifest::SHA512"));
}
sub _build_bag_path_arr {
    my ($self) = @_;
    my @split_path = File::Spec->splitdir($self->bag_path);
    return @split_path;
}

sub _build_payload_path_arr {
    my ($self) = @_;
    my @split_path = File::Spec->splitdir($self->payload_path);
    return @split_path;
}

sub _build_rel_payload_path {
    my ($self) = @_;
    my $rel_path = File::Spec->abs2rel( $self->payload_path, $self->bag_path ) ;
    return $rel_path;
}

sub _build_metadata_path_arr {
    my ($self) = @_;
    my @split_path = File::Spec->splitdir($self->metadata_path);
    return @split_path;
}

sub _build_rel_metadata_path {
    my ($self) = @_;
    my $rel_path = File::Spec->abs2rel( $self->metadata_path, $self->bag_path ) ;
    return $rel_path;
}

sub _build_checksum_algos {
    my($self) = @_;
    my $checksums = [ 'md5', 'sha1', 'sha256', 'sha512' ];
    return $checksums;
}

sub _build_bag_checksum {
  my($self) =@_;
  my $bagit = $self->{'bag_path'};
  open(my $SRCFILE, "<:raw",  $bagit."/manifest-md5.txt");
  my $srchex=Digest::MD5->new->addfile($SRCFILE)->hexdigest;
  close($SRCFILE);
  return $srchex;
}

sub _build_manifest_files {
  my($self) = @_;
  my @manifest_files;
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
    die("Cannot open $tagmanifest_file: $!") unless (open(my $TAGMANIFEST,"<:encoding(utf8)", $tagmanifest_file));
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
    die("Cannot open $manifest_file: $!") unless (open (my $MANIFEST, "<:encoding(utf8)", $manifest_file));
    while (my $line = <$MANIFEST>) {
        chomp($line);
        my ($digest,$file);
        ($digest, $file) = $line =~ /^([a-f0-9]+)\s+(.+)/;
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
  my $payload_reldir = $self->rel_payload_path;

  my @payload=();
  File::Find::find( sub{
    $File::Find::name = decode ('utf8', $File::Find::name);
    $_ = decode ('utf8', $_);
    if (-f $_) {
        my $rel_path=File::Spec->catdir($self->rel_payload_path,File::Spec->abs2rel($File::Find::name, $payload_dir));
        push(@payload,$rel_path);
    }
    elsif($self->metadata_path_arr > $self->payload_path_arr && -d _ && $_ eq $self->rel_metadata_path) {
        #print "pruning ".$File::Find::name."\n";
        $File::Find::prune=1;
    }
    else {
        #payload directories
    }
    #print "name: ".$File::Find::name."\n";
  }, $payload_dir);

  #print p(@payload);

  return wantarray ? @payload : \@payload;

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

sub _parse_bag_info { # parses a bag-info textblob
    my ($self, $textblob) = @_;
    #    metadata elements are OPTIONAL and MAY be repeated.  Because "bag-
    #    info.txt" is intended for human reading and editing, ordering MAY be
    #    significant and the ordering of metadata elements MUST be preserved.
    #
    #    A metadata element MUST consist of a label, a colon ":", a single
    #    linear whitespace character (space or tab), and a value that is
    #    terminated with an LF, a CR, or a CRLF.
    #
    #    The label MUST NOT contain a colon (:), LF, or CR.  The label MAY
    #    contain linear whitespace characters but MUST NOT start or end with
    #    whitespace.
    #
    #    It is RECOMMENDED that lines not exceed 79 characters in length.
    #    Long values MAY be continued onto the next line by inserting a LF,
    #    CR, or CRLF, and then indenting the next line with one or more linear
    #    white space characters (spaces or tabs).  Except for linebreaks, such
    #    padding does not form part of the value.
    #
    #    Implementations wishing to support previous BagIt versions MUST
    #    accept multiple linear whitespace characters before and after the
    #    colon when the bag version is earlier than 1.0; such whitespace does
    #    not form part of the label or value.
    # find all labels
    my @labels;
    my $label_rx = qr/^([^:\s]+)\s*:\s*/;
    my $eol_rx = qr/[\r\n]/;
    while ($textblob =~ s/$label_rx//m) { # label if starts with chars not colon or whitespace followed by zero or more spaces, a colon, zero or more spaces
        # label found
        my $label = $1; my $value;

        if ($textblob =~ s/(.+?)(?=^\S)//ms) {
            # value if rest string starts with chars not \r and/or \n until a non-whitespace after \r\n
            $value =$1;
            chomp $value;
        } elsif ($textblob =~ s/(.*)//s) {
            $value = $1;
            chomp $value;
        }
        push @labels, { $label, $value };
    }
    return \@labels;
}

sub _build_bag_info {
    my ($self) = @_;
    my $bagit = $self->metadata_path;
    my $file = join("/", $bagit, "bag-info.txt");
    open(my $BAGINFO, "<", $file) or die("Cannot read $file: $!");

    my @lines;
    foreach my $line (<$BAGINFO>) {
        push @lines, $line;
    }
    close($BAGINFO);
    my $lines = join("", @lines);
    return $self->_parse_bag_info ($lines);

}

sub _build_non_payload_files {
  my($self) = @_;

  my @non_payload = ();

  File::Find::find( sub{
    $File::Find::name = decode('utf8', $File::Find::name);
    $_=decode ('utf8', $_);
    if (-f $_) {
        my $rel_path=File::Spec->catdir($self->rel_metadata_path,File::Spec->abs2rel($File::Find::name, $self->metadata_path));
        #print "pushing ".$rel_path." payload_dir: $payload_dir \n";
        push(@non_payload,$rel_path);
    }
    elsif($self->metadata_path_arr < $self->payload_path_arr && -d _ && $_ eq $self->rel_payload_path) {
        #print "pruning ".$File::Find::name."\n";
        $File::Find::prune=1;
    }
    else {
        #payload directories
    }
    #print "name: ".$File::Find::name."\n";
  }, $self->metadata_path);

  return wantarray ? @non_payload : \@non_payload;

}

sub _build_forced_fixity_algorithm {
    my ($self) = @_;
    if ($self->bag_version() >= 1.0) {
        return Archive::BagIt::Plugin::Algorithm::SHA512->new(bagit => $self);
    }
    else {
        return Archive::BagIt::Plugin::Algorithm::MD5->new(bagit => $self);
    }
}

=head2 load_plugins

As default SHA512 and MD5 will be loaded and therefore used. If you want to create a bag only with one or a specific
checksum-algorithm, you could use this method to (re-)register it. It expects list of strings with namespace of type:
Archive::BagIt::Plugin::Algorithm::XXX where XXX is your chosen fixity algorithm.

=cut

sub load_plugins {
    my ($self, @plugins) = @_;
 
    #p(@plugins); 
    my $loaded_plugins = $self->plugins;  
    @plugins = grep { not exists $loaded_plugins->{$_} } @plugins; 

    return if @plugins == 0;
    foreach my $plugin (@plugins) {
        load_class ($plugin) or die ("Can't load $plugin");
        $plugin->new({bagit => $self});
    }

    return 1;
}

=head2 verify_bag

An interface to verify a bag.

You might also want to check Archive::BagIt::Fast to see a more direct way of accessing files (and thus faster).


=cut

sub verify_bag {
    my ($self,$opts) = @_;
    #removed the ability to pass in a bag in the parameters, but might want options
    #like $return all errors rather than dying on first one
    my $bagit = $self->bag_path;
    my $version = $self->bag_version(); # to call trigger
    my $manifest_file = $self->metadata_path."/manifest-".$self->forced_fixity_algorithm()->name().".txt"; # FIXME: use plugin instead
    my $payload_dir   = $self->payload_path;
    my $return_all_errors = $opts->{return_all_errors};
    my %invalids;
    my @payload       = @{$self->payload_files};

    die("$manifest_file is not a regular file for bagit $version") unless -f ($manifest_file);
    die("$payload_dir is not a directory") unless -d ($payload_dir);

    unless ($version > .95) {
        die ("Bag Version $version is unsupported");
    }

    # Read the manifest file
    #print Dumper($self->{entries});
    my %manifest = %{$self->manifest_entries};

    # Evaluate each file against the manifest
    my $digestobj = $self->forced_fixity_algorithm();
    foreach my $local_name (@payload) { # local_name is relative to bagit base
        my ($digest);
        unless ($manifest{"$local_name"}) {
          die ("file found not in manifest: [$local_name] (bag-path:$bagit)");
        }
        if (! -r "$bagit/$local_name" ) {die ("Cannot open $bagit/$local_name");}
        $digest = $digestobj->verify_file( "$bagit/$local_name");
        print "digest of $bagit/$local_name: $digest\n" if $DEBUG;
        unless ($digest eq $manifest{$local_name}) {
          if($return_all_errors) {
            $invalids{$local_name} = $digest;
          }
          else {
            die ("file: $bagit/$local_name invalid");
          }
        }
        delete($manifest{$local_name});
    }
    if($return_all_errors && keys(%invalids) ) {
      foreach my $invalid (keys(%invalids)) {
        print "invalid: $invalid hash: ".$invalids{$invalid}."\n";
      }
      die ("bag verify for bagit $version failed with invalid files");
    }
    # Make sure there are no missing files
    if (keys(%manifest)) { die ("Missing files in bag".p(%manifest)); }

    return 1;
}

=head2 calc_payload_oxum()

returns an array with octets and streamcount of payload-dir

=cut



sub calc_payload_oxum {
    my($self) = @_;
    my @payload = @{$self->payload_files};
    my $octets=0;
    my $streamcount = scalar @payload;
    foreach my $local_name (@payload) {# local_name is relative to bagit base
        my $file = $self->bag_path()."/$local_name";
        my $sb = stat($file);
        $octets += $sb->size;
    }
    return ($octets, $streamcount);
}

=head2 calc_bagsize()

returns a string with human readable size of paylod

=cut

sub calc_bagsize {
    my($self) = @_;
    my ($octets,$streamcount) = $self->calc_payload_oxum();
    if ($octets < 1024) { return "$octets B"; }
    elsif ($octets < 1024*1024) {return sprintf("%0.1f kB", $octets/1024); }
    elsif ($octets < 1024*1024*1024) {return sprintf "%0.1f MB", $octets/(1024*1024); }
    elsif ($octets < 1024*1024*1024*1024) {return sprintf "%0.1f GB", $octets/(1024*1024*1024); }
    else { return sprintf "%0.2f TB", $octets/(1024*1024*1024*1024); }
}

sub create_bagit {
    my($self) = @_;
    open(my $BAGIT, ">", $self->metadata_path."/bagit.txt") or die("Can't open $self->metadata_path/bagit.txt for writing: $!");
    print($BAGIT "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8");
    close($BAGIT);
    return 1;
}

sub create_baginfo {
    use POSIX;
    my($self) = @_; # because bag-info.txt allows multiple key-value-entries, hash is replaced
    my @baginfo;
    push @baginfo, {'Bagging-Date', POSIX::strftime("%F", gmtime(time))};
    push @baginfo, {'Bag-Software-Agent', 'Archive::BagIt <https://metacpan.org/pod/Archive::BagIt>'};
    my ($octets, $streams) = $self->calc_payload_oxum();
    push @baginfo, {'Payload-Oxum', "$octets.$streams"};
    push @baginfo, {'Bag-Size', $self->calc_bagsize()};
    $self->bag_info( \@baginfo);
    open(my $BAGINFO, ">", $self->metadata_path."/bag-info.txt") or die("Can't open $self->metadata_path/bag-info.txt for writing: $!");
    foreach my $entry (sort @baginfo) {
        my ($key, $value) = each %{$entry};
        print($BAGINFO "$key: $value\n");
    }
    close($BAGINFO);
    return 1;
}


=head2 init_metadata

A constructor that will just create the metadata directory

This won't make a bag, but it will create the conditions to do that eventually

=cut

sub init_metadata {
    my ($class, $bag_path) = @_;
    unless ( -d $bag_path) { die ( "source bag directory doesn't exist"); }
    my $self = $class->new(bag_path=>$bag_path);
    warn "no payload path\n" if ! -d $self->payload_path;
    unless ( -d $self->payload_path) {
        rename ($bag_path, $bag_path.".tmp");
        mkdir  ($bag_path);
        rename ($bag_path.".tmp", $self->payload_path);
    }
    unless ( -d $self->metadata_path) {
        #metadata path is not the root path for some reason
        mkdir ($self->metadata_path);
    }

    $self->create_bagit();
    $self->create_baginfo();

    # FIXME: deprecated?
    #foreach my $algorithm (keys %{$self->manifests}) {
        #$self->manifests->{$algorithm}->create_bagit();
        #$self->manifests->{$algorithm}->create_baginfo();
    #}

    return $self;
}


=head2 make_bag

A constructor that will make and return a bag from a directory,

It expects a preliminary bagit-dir exists.
If there a data directory exists, assume it is already a bag (no checking for invalid files in root)


=cut

sub make_bag {
  my ($class, $bag_path) = @_;

  my $self = $class->init_metadata($bag_path);
  # it is important to create all manifest files first, because tagmanifest should include all manifest-xxx.txt
  foreach my $algorithm ( keys %{ $self->manifests }) {
        $self->manifests->{$algorithm}->create_manifest();
  }
  foreach my $algorithm ( keys %{ $self->manifests }) {

        $self->manifests->{$algorithm}->create_tagmanifest();
  }
  return $self;
}


__PACKAGE__->meta->make_immutable;

1;
