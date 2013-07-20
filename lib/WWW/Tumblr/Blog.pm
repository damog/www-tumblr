package WWW::Tumblr::Blog;
use Moose;
use Data::Dumper;

use WWW::Tumblr::API;
extends 'WWW::Tumblr';

has 'base_hostname', is => 'rw', isa => 'Str', required => 1;

tumblr_api_method post => [ 'POST', 'oauth' ];

sub blog { ... }

1;

