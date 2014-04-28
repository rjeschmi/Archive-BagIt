#!/usr/bin/env perl 

use strict;
use warnings;

use Archive::BagIt::App;

Archive::BagIt::App->new_with_command->run;



1;

__END__

=pod

=head1 NAME

bagit.pl - a command that lets you check your bags

=cut
