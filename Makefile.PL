use inc::Module::Install;

name 'Archive-BagIt';
all_from 'lib/Archive/BagIt.pm';


requires 'Moose';
requires 'MooseX::App::Cmd';
requires 'File::Find';
requires 'Digest::MD5';


tests 't/*.t';

WriteAll;

