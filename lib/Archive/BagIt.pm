package Archive::BagIt;

use 5.006;
use strict;
use warnings;

=head1 WARNING

This is experimental software for the moment and under active development. I
hope to have a beta version available soon.

=head1 NAME

Archive::BagIt - An interface to make and verify bags according to the BagIt standard

=head1 VERSION

Version 0.02_2

=cut

our $VERSION = '0.02_2';


=head1 SYNOPSIS

This modules will hopefully help with the basic commands needed to create
and verify a bag. My intention is not to be strict and enforce all of the
specification. The reference implementation is the java version
and I will endeavour to maintain compatibility with it.

    use Archive::BagIt;

    #read in an existing bag:
    my $bag = Archive::BagIt->new($bag_dir);


    #construct bag in an existing directory
    my $bag = Archive::BagIt->make_bag($bag_dir);

    # Validate a BagIt archive against its manifest
    my $bag = Archive::BagIt->new($bag_dir);
    $is_valid = $bag->verify_bag($root);




=head1 SUBROUTINES

=head2 new
   An Object Oriented Interface to a bag. Opens an existing bag.
=cut

sub new {
  my ($class,$bag_path) = @_;
  my $self = {};
  $bag_path=~s!/$!!;
  $self->{'bag_path'} = $bag_path || "";
  bless $self, $class;
  return $self;
}

=head2 make_bag
   A constructor that will make and return a bag from a directory
=cut

sub make_bag {
  my ($class, $bag_dir, $inplace) = @_;
  unless ( -d $bag_dir) { die ( "source bag directory doesn't exist"); }
  unless ( -d $bag_dir."/data") {
    rename ($bag_dir, $bag_dir.".tmp");
    mkdir  ($bag_dir);
    rename ($bag_dir.".tmp", $bag_dir."/data");
  }
  my $self=$class->new($bag_dir);
  $self->_write_bagit($bag_dir);
  $self->_write_baginfo($bag_dir);
  $self->_manifest_md5($bag_dir);
  return $self;
}

sub _write_bagit {
    my($self, $bagit) = @_;
    open(BAGIT, ">$bagit/bagit.txt") or die("Can't open $bagit/bagit.txt for writing: $!");
    print(BAGIT "BagIt-Version: 0.97\nTag-File-Character-Encoding: UTF-8");
    close(BAGIT);
    return 1;
}



sub _write_baginfo {
    use POSIX;
    my($self, $bagit, %param) = @_;
    open(BAGINFO, ">$bagit/bag-info.txt") or die("Can't open $bagit/bag-info.txt for writing: $!");
    $param{'Bagging-Date'} = POSIX::strftime("%F", gmtime(time));
    $param{'Bag-Software-Agent'} = 'Archive::BagIt <http://search.cpan.org/~rjeschmi/Archive-BagIt>';
    while(my($key, $value) = each(%param)) {
        print(BAGINFO "$key: $value\n");
    }
    close(BAGINFO);
    return 1;
}

sub _manifest_crc32 {
    require String::CRC32;
    my($self,$bagit) = @_;
    my $manifest_file = "$bagit/manifest-crc32.txt";
    my $data_dir = "$bagit/data";

    # Generate MD5 digests for all of the files under ./data
    open(FH, ">$manifest_file") or die("Cannot create manifest-crc32.txt: $!\n");
    my $fh = *FH;
    find(
        sub {
            my $file = $File::Find::name;
            if (-f $_) {
                open(DATA, "<$_") or die("Cannot read $_: $!");
                my $digest = sprintf("%010d",crc32(*DATA));
                close(DATA);
                my $filename = substr($file, length($bagit) + 1);
                print($fh "$digest  $filename\n");
            }
        },
        $data_dir
    );
    close(FH);
}


sub _manifest_md5 {
    use File::Find;
    use Digest::MD5 qw/md5_hex/;
    my($self, $bagit) = @_;
    my $manifest_file = "$bagit/manifest-md5.txt";
    my $data_dir = "$bagit/data";

    # Generate MD5 digests for all of the files under ./data
    open(MD5, ">$manifest_file") or die("Cannot create manifest-md5.txt: $!\n");
    my $md5_fh = *MD5;
    find(
        sub {
            my $file = $File::Find::name;
            if (-f $_) {
                open(DATA, "<$_") or die("Cannot read $_: $!");
                my $digest = md5_hex(join("", <DATA>));
                close(DATA);
                my $filename = substr($file, length($bagit) + 1);
                print($md5_fh "$digest  $filename\n");
            }
        },
        $data_dir
    );
    close(MD5);
}

=head2 verify_bag

An interface to verify a bag

=cut

sub verify_bag {
    my ($self,$bagit) = @_;
    $self->{'bag_path'} = $bagit;
    my $manifest_file = "$bagit/manifest-md5.txt";
    my $payload_dir   = "$bagit/data";
    my %manifest      = ();
    my @payload       = ();

    die("$manifest_file is not a regular file") unless -f ($manifest_file);
    die("$payload_dir is not a directory") unless -d ($payload_dir);

    # Read the manifest file
    die("Cannot open $manifest_file: $!") unless (open (MANIFEST, $manifest_file));
    while (my $line = <MANIFEST>) {
        chomp($line);
        my($digest, $file) = split(/\s+/, $line, 2);
        $manifest{$file} = $digest;
    }
    close(MANIFEST);

    # Compile a list of payload files
    find(sub{ push(@payload, $File::Find::name)  }, $payload_dir);

    # Evaluate each file against the manifest
    foreach my $file (@payload) {
        next if (-d ($file));
        my $local_name = substr($file, length($bagit) + 1);
        return 0 unless ($manifest{$local_name});
        open(DATA, "<$bagit/$local_name") or return 0;
        my $digest = Digest::MD5->new->addfile(*DATA)->hexdigest;
        close(DATA);
        return 0 unless ($digest eq $manifest{$local_name});
        delete($manifest{$local_name});
    }

    # Make sure there are no missing files
    return 0 if (keys(%manifest));

    return 1;
}

=head2 get_checksum 

=cut

sub get_checksum {
  my($self) =@_;
  my $bagit = $self->{'bag_path'};
  open(my $SRCFILE, $bagit."/manifest-md5.txt");
  binmode($SRCFILE);
  my $srchex=Digest::MD5->new->addfile($SRCFILE)->hexdigest;
  close($SRCFILE);
  return $srchex;
}

=head2 version

   Returns the bagit version according to the bagit.txt file.
=cut

sub version {
    my($self) = @_;
    my $bagit = $self->{'bag_path'};
    my $file = join("/", $bagit, "bagit.txt");
    open(BAGIT, "<$file") or die("Cannot read $file: $!");
    my $version_string = <BAGIT>;
    my $encoding_string = <BAGIT>;
    close(BAGIT);
    $version_string =~ /^BagIt-Version: ([0-9.]+)$/;
    return $1 || 0;
}

sub _payload_files{
  my($self) = @_;

  my $payload_dir = $self->{"bag_path"};
  
  use File::Find;
  my @payload=();
  File::Find::find({push(@payload,$File::Find::name); print "name: ".$File::Find::name."\n"; }, $payload_dir);
  
  return @payload;

}
=head1 AUTHOR

=over 4

=item *

Robert Schmidt, C<< <rjeschmi at gmail.com> >> 

=item *

William Wueppelmann, C<< <william at c7a.ca> >>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-archive-bagit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-BagIt>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::BagIt


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Archive-BagIt>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Archive-BagIt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Archive-BagIt>

=item * Search CPAN

L<http://search.cpan.org/dist/Archive-BagIt/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Robert Schmidt and William Wueppelmann

This program is released under the following license: cc0


=cut

1; # End of Archive::BagIt
