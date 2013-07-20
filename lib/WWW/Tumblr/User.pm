package WWW::Tumblr::User;

use Moose;
use strict;
use warnings;

use WWW::Tumblr::API;

extends 'WWW::Tumblr';

tumblr_api_method $_, [ 'GET', 'oauth' ] for qw( info dashboard likes following );

sub user { ... }


1;
