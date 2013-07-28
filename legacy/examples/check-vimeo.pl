#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use WWW::Tumblr;

my $t = WWW::Tumblr->new;

$t->email('hola@adios.com');
$t->password('sdf');

my $s = $t->check_vimeo or die $t->errstr;

print $s;
