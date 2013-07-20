package WWW::Tumblr::Blog;
use Moose;
use Data::Dumper;

extends 'WWW::Tumblr';

has 'base_hostname', is => 'rw', isa => 'Str', required => 1;

sub blog { ... }

1;

