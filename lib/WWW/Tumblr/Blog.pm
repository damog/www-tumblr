package WWW::Tumblr::Blog;
use Moose;
use Data::Dumper;

use WWW::Tumblr::API;
extends 'WWW::Tumblr';

has 'base_hostname', is => 'rw', isa => 'Str', required => 1;

tumblr_api_method info                  => [ 'GET',  'apikey' ];
tumblr_api_method avatar                => [ 'GET',  'none', undef, 'size' ];
tumblr_api_method likes                 => [ 'GET',  'apikey'];
tumblr_api_method followers             => [ 'GET',  'oauth' ];

tumblr_api_method post                  => [ 'POST', 'oauth' ];
tumblr_api_method post_edit             => [ 'POST', 'oauth' ];
tumblr_api_method post_reblog           => [ 'POST', 'oauth' ];
tumblr_api_method post_delete           => [ 'POST', 'oauth' ];

tumblr_api_method posts_queue           => [ 'GET',  'oauth' ];
tumblr_api_method posts_draft           => [ 'GET',  'oauth' ];
tumblr_api_method posts_submission      => [ 'GET',  'oauth' ];

tumblr_api_method followers             => [ 'GET',  'oauth' ];

sub blog { ... }

1;

