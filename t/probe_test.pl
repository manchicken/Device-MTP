#!/usr/bin/perl
use lib qw{../lib ./lib};
use strict;
use warnings;
use Device::MTP;
use Data::Dumper;

my $foo = Device::MTP->new();
ok($foo->_probe(),"Testing probing...");
print Dumper($foo->_get_first_device());

