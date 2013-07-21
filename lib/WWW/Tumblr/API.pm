package WWW::Tumblr::API;

use strict;
use warnings;

use Moose;
use JSON 'decode_json';
use Moose::Exporter;
Moose::Exporter->setup_import_methods(with_caller => ['tumblr_api_method']);
use WWW::Tumblr::ResponseError;

sub tumblr_api_method ($$) {
    my $class = Moose::Meta::Class->initialize( shift );
    my $method_name = $_[0];

    my $meta = {
        name => $method_name,
        spec => $_[1],
    };

    my $sub = sub {
        my $self = shift;
        my $r = { _meta => $meta, args => shift };

        my ( $http_method, $auth_method ) = @{ $r->{_meta}->{spec} };
       
        my $response;
        my $kind = lc( pop( @{ [ split '::', ref $self ] }));
        if ( $auth_method eq 'oauth' ) {
            $response = $self->_oauth_request(
                $http_method,
                $kind . '/' .
                ( $kind eq 'blog' ? $self->base_hostname . '/' : '' ) .
                join('/', split /_/, $method_name),
                %{ $r->{args} || {} }
            );
        } elsif ( $auth_method eq 'none' ) {
        
        } elsif ( $auth_method eq 'apikey' ) {
        
        } else {
            die "auth method: $auth_method is unsupported, you jerk.";
        }

        if ( $response->is_success ) {
            return decode_json($response->decoded_content)->{response};
        } else {
            $self->error( WWW::Tumblr::ResponseError->new(
                response => $response
            ) );
            return;
        }
    };

    $class->add_method($method_name, $sub );

}

1;
