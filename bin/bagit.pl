#!/usr/bin/perl -w 

use strict;
use Archive::BagIt;

=head1 NAME

bagit.pl - A commandline interface to the Perl bagit library

=head1 SYNOPSIS

  bagit.pl <directory>  - will create a bag in the specified directory

=head1 DESCRIPTION 

  Simple script that wraps up interesting parts of the Archive::BagIt interface


=cut

my $filepath = shift;
my $bag = Archive::BagIt->make_bag($filepath);




1;
