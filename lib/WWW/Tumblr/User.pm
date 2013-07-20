package WWW::Tumblr::User;

use Moose;
use strict;
use warnings;

use WWW::Tumblr::API;

extends 'WWW::Tumblr';

tumblr_api_method info        => [ 'GET', 'oauth' ];
tumblr_api_method dashboard   => [ 'GET', 'oauth' ];
tumblr_api_method likes       => [ 'GET', 'oauth' ];
tumblr_api_method following   => [ 'GET', 'oauth' ];

sub user { ... }


1;
