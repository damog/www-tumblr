package WWW::Tumblr::ResponseError;

use Moose;
use Data::Dumper;
use JSON 'decode_json';

has 'response', is => 'rw', isa => 'HTTP::Response';

sub code    { $_[0]->response->code }
sub reasons  { decode_json( $_[0]->response->decoded_content)->{response}->{errors} }

1;
