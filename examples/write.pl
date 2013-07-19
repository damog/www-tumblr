#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use WWW::Tumblr;

my $tumblr = WWW::Tumblr->new;

$tumblr->email('foo@bar.com');
$tumblr->password('');

$tumblr->write(type => 'regular', title => 'whaaaaaaaaaa')
	or die $tumblr->errstr;
