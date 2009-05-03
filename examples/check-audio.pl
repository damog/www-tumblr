#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use WWW::Tumblr;

my $t = WWW::Tumblr->new;

$t->email('damogar@gmail.com');
$t->password('zemIjAeRZYLkE8TxRv2duRWlqtpDlAMkqRJkEdrQlhUv6o1y');
$t->check_audio or die $t->errstr;
