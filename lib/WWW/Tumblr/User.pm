package WWW::Tumblr::User;

use Moose;
use strict;
use warnings;

use WWW::Tumblr::API;

extends 'WWW::Tumblr';

tumblr_api_method $_, [ 'GET',  'oauth' ] for qw( info dashboard likes following );
tumblr_api_method $_, [ 'POST', 'oauth' ] for qw( follow unfollow like unlike );

sub user { ... }


1;
