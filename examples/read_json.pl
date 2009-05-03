#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use WWW::Tumblr;

my $t = WWW::Tumblr->new;

$t->user('damog');
print $t->read_json(id => 27715443);
