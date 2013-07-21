package WWW::Tumblr::ResponseError;

use Moose;
use Data::Dumper;
use JSON 'decode_json';

has 'response', is => 'rw', isa => 'HTTP::Response';

sub code    { $_[0]->response->code }
sub reasons  {
    my $self = $_[0];
    my $j = decode_json( $_[0]->response->decoded_content);
    if ( ref $j && ref $j eq 'HASH' ) {
        if ( ref $j->{response} && ref $j->{response} eq 'ARRAY' ) {
            unless ( scalar @{ $j->{response} }) {
                return [ $self->response->message ]
            }
            return $j->{response};
        } elsif ( ref $j->{response} && ref $j->{response} eq 'HASH' &&
            defined $j->{response}->{errors}  
        ) {
            if ( defined $j->{response}->{errors}->{state} ) {
                return [ 
                    $j->{response}->{errors}->{0},
                    $j->{response}->{errors}->{state}
                ];
            } else {
                return $j->{response}->{errors};
            }
        } else {
            ...
        }
    } else {
        ...
    }
}

1;
