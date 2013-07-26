package WWW::Tumblr;
<<<<<<< HEAD
=======

use strict;
use warnings;

require 5.012_000;

our $VERSION = '5.01';

use Moose;
use Carp;
use Data::Dumper;
use HTTP::Request::Common;
use Net::OAuth::Client;
use WWW::Tumblr::API;
use WWW::Tumblr::Blog;
use WWW::Tumblr::User;
use LWP::UserAgent;

has 'consumer_key',     is => 'rw', isa => 'Str';
has 'secret_key',       is => 'rw', isa => 'Str';
has 'token',            is => 'rw', isa => 'Str';
has 'token_secret',     is => 'rw', isa => 'Str';

has 'callback',         is => 'rw';
has 'error',            is => 'rw', isa => 'WWW::Tumblr::ResponseError';
has 'ua',               is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new };

has 'oauth',            is => 'rw', isa => 'Net::OAuth::Client', default => sub {
	my $self = shift;
	Net::OAuth::Client->new(
		$self->consumer_key,
		$self->secret_key,
		request_token_path => 'http://www.tumblr.com/oauth/request_token',
		authorize_path => 'http://www.tumblr.com/oauth/authorize',
		access_token_path => 'http://www.tumblr.com/oauth/access_token',
		callback => $self->callback, 
		session => sub { if (@_ > 1) { $self->session($_[0] => $_[1]) }; return $self->session($_[0]) },
	);
};

sub user {
    my ( $self ) = shift;
    return WWW::Tumblr::User->new({
        consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        token           => $self->token,
        token_secret    => $self->token_secret,
    })
}

sub blog {
    my ( $self ) = shift;
    my $name = shift or croak "A blog host name is needed.";

    return WWW::Tumblr::Blog->new({
        consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        token           => $self->token,
        token_secret    => $self->token_secret,
        base_hostname   => $name,
    })
}

sub _tumblr_api_request {
    my $self    = shift;
    my $r       = shift; #args

    my $method_to_call = '_' . $r->{auth} . '_request';
    return $self->$method_to_call(
        $r->{http_method}, $r->{url_path}, $r->{extra_args}
    );

}

sub _apikey_request {
    my $self        = shift;
    my $method      = shift;
    my $url_path    = shift;

    my $req; # request object
    if ( $method eq 'GET' ) {
        $req = HTTP::Request->new(
            $method => 'http://api.tumblr.com/v2/' . $url_path . '?api_key='.$self->consumer_key
            # TODO: add other required/optional params
        );
    } elsif ( $method eq 'POST' ) {
        ...
    } else {
        die "$method misunderstood";
    }

    my $res = $self->ua->request( $req );

}

sub _oauth_request {
	my $self = shift;
	my $method = shift;
	my $url_path= shift;
	my %params = @_;

	my $request = $self->oauth->_make_request(
		'protected resource', 
		request_method => uc $method,
		request_url => 'http://api.tumblr.com/v2/' . $url_path,
		consumer_key => $self->consumer_key,
	    consumer_secret => $self->secret_key,
		token => $self->token,
		token_secret => $self->token_secret,
		extra_params => \%params
	);
	$request->sign;

	my $message = $method =~ /post/i 
				? POST $request->to_url, Content => $request->to_post_body
				: GET $request->to_url;

	return $self->oauth->request( $message );
}


1;
__END__
use base qw(Class::Accessor::Fast);

use Moo;
use Carp;
use HTTP::Request::Common;
use Net::OAuth::Client;

__PACKAGE__->mk_accessors(qw/ consumer_key secret_key blog callback token token_secret /);



sub new {
	my $class = shift;
	my %opts = @_;
	my $self = bless { %opts }, $class;
	$self;
}

sub _oauth_client {
	my $self = shift;
	Net::OAuth::Client->new(
		$self->consumer_key,
		$self->secret_key,
		request_token_path => 'http://www.tumblr.com/oauth/request_token',
		authorize_path => 'http://www.tumblr.com/oauth/authorize',
		access_token_path => 'http://www.tumblr.com/oauth/access_token',
		callback => $self->callback, 
		session => sub { if (@_ > 1) { $self->session($_[0] => $_[1]) }; return $self->session($_[0]) },
		debug => 1
	);
}

sub _oauth_request {
	my $self = shift;
	my $method = shift;
	my $url_path= shift;
	my %params = @_;

	my $request = $self->_oauth_client->_make_request(
		'protected resource', 
		request_method => uc $method,
		request_url => 'http://api.tumblr.com/v2/' . $url_path,
		consumer_key => $self->consumer_key,
	    consumer_secret => $self->secret_key,
		token => $self->token,
		token_secret => $self->token_secret,
		extra_params => \%params
	);
	$request->sign;

	my $message = $method =~ /post/i 
				? POST $request->to_url, Content => $request->to_post_body
				: GET $request->to_url;

	return $self->_oauth_client->request( $message );
}

sub authorization_url {
	my $self = shift;
	croak "No application's 'consumer_key' and 'secret_key' defined!"
		unless $self->consumer_key && $self->secret_key;
	return $self->_oauth_client->authorize_url();
}

sub get_token {
	my $self = shift;
	my( $oauth_token, $oauth_verifier ) = @_;

	croak "You must provide 'oauth_token' and 'oauth_verifier' for this method!"
		unless $oauth_token && $oauth_verifier;

	my $client = $self->_oauth_client();
	unless ( $self->token && $self->token_secret ) {
		my $access_token = $client->get_access_token( $oauth_token, $oauth_verifier );
		$self->token( $access_token->token );
		$self->token_secret( $access_token->token_secret );
	}

	return( $self->token, $self->token_secret );
}

sub session {
	my $self = shift;
	$self->{session} ||= {};

	if ( ref $_[0] eq 'HASH' ) {
		$self->{session} = $_[0];
	}
	elsif ( @_ > 1 ) {
		$self->{session}->{$_[0]} = $_[1]
	}

	return $_[0] ? $self->{session}->{$_[0]} : $self->{session};
}

sub post {
	my $self = shift;
	my $action = $_[0] =~ /^edit|reblog|delete$/i ? shift : '';
	my %post_values = @_;

	#	Post new entry
	my $response = $self->_oauth_request(
		'POST',	'blog/' . $self->blog . '/post' . $action, %post_values 
	);

	return $response->is_success ? $response->decoded_content : $response->status_line;
}

1;

__END__
=head1 NAME

WWW::Tumblr - Perl interface for the Tumblr API

=head1 SYNOPSIS

 use WWW::Tumblr;
 
 # read method
 my $t = WWW::Tumblr->new;
 
 # Will read http://juanito.tumblr.com/api/read
 $t->user('juanito');

 # Will read http://log.damog.net/api/read
 $t->url('http://log.damog.net');

 # Pass Tumblr API read arguments to the read() method
 $t->read(
 	start => 2,
 	num	=> 10,
 	...
 );

 # Will get you JSON back
 # Same arguments as read, as defined by the API
 $t->read_json(
 	...
 );
 
 # write
 # Object initialization
 my $t = WWW::Tumblr->new;

 # The email you use to log in to Tumblr	
 $t->email('pepito@chistes.com');
 $t->password('foobar');
 
 # You will always have to pass a type to write() and the additional
 # args depend on that type and the requests by the Tumblr API
 $t->write(
 	type => 'regular',
 	body => 'My body text',
 	...

 	type => 'quote',
 	quote => 'I once had a girlfriend...',
 	...

 	type => 'conversation',
 	title => 'On the subway...',
 	conversation => 'Meh, meh, meh.',
 	...

 	# File uploads:
 	type => 'audio',
 	data => '/tmp/my.mp3',
 	...
 );
 
 # other actions
 $t->authenticate or die $t->errstr;
 $t->check_audio or die $t->errstr;

 my $vimeo = $t->check_vimeo or die $t->errstr;

All options passed to C<read>, C<read_json> and C<write> are all of the parameters
specified on L<http://www.tumblr.com/api> and you simple have to pass them as key =>
values argument pairs.

The Tumblr API is not really long or difficult and this implementation covers it fully.

=head1 METHODS

=cut

>>>>>>> damog/v2

use base qw(Class::Accessor::Fast);

use Carp;
use HTTP::Request::Common;
use Net::OAuth::Client;
use JSON::XS qw( decode_json );

__PACKAGE__->mk_accessors(qw/ consumer_key secret_key blog callback token token_secret error /);

sub new {
	my $class = shift;
	my %opts = @_;
	my $self = bless { %opts }, $class;
	$self;
}

sub _oauth_client {
	my $self = shift;
	Net::OAuth::Client->new(
		$self->consumer_key,
		$self->secret_key,
		request_token_path => 'http://www.tumblr.com/oauth/request_token',
		authorize_path => 'http://www.tumblr.com/oauth/authorize',
		access_token_path => 'http://www.tumblr.com/oauth/access_token',
		callback => $self->callback, 
		session => sub { if (@_ > 1) { $self->session($_[0] => $_[1]) }; return $self->session($_[0]) },
		debug => 1
	);
}

sub _oauth_request {
	my $self = shift;
	my $method = shift;
	my $url_path= shift;
	my %params = @_;

	my $request = $self->_oauth_client->_make_request(
		'protected resource', 
		request_method => uc $method,
		request_url => 'http://api.tumblr.com/v2/' . $url_path,
		consumer_key => $self->consumer_key,
	   	consumer_secret => $self->secret_key,
		token => $self->token,
		token_secret => $self->token_secret,
		extra_params => \%params
	);
	$request->sign;

	my $message = $method =~ /post/i 
				? POST $request->to_url, Content => $request->to_post_body
				: GET $request->to_url;

	return $self->_oauth_client->request( $message );
}

sub authorization_url {
	my $self = shift;
	croak "No application's 'consumer_key' and 'secret_key' defined!"
		unless $self->consumer_key && $self->secret_key;
	return $self->_oauth_client->authorize_url();
}

sub get_token {
	my $self = shift;
	my( $oauth_token, $oauth_verifier ) = @_;

	croak "You must provide 'oauth_token' and 'oauth_verifier' for this method!"
		unless $oauth_token && $oauth_verifier;

	my $client = $self->_oauth_client();
	unless ( $self->token && $self->token_secret ) {
		my $access_token = $client->get_access_token( $oauth_token, $oauth_verifier );
		$self->token( $access_token->token );
		$self->token_secret( $access_token->token_secret );
	}

	return( $self->token, $self->token_secret );
}

sub session {
	my $self = shift;
	$self->{session} ||= {};

	if ( ref $_[0] eq 'HASH' ) {
		return $self->{session} = $_[0];
	}
	elsif ( @_ > 1 ) {
		$self->{session}->{$_[0]} = $_[1]
	}

	return $_[0] ? $self->{session}->{$_[0]} : $self->{session};
}

sub post {
	my $self = shift;
	my $action = $_[0] =~ /^edit|reblog|delete$/i ? shift : '';
	my %post_values = @_;

	#	Post new entry
	my $response = $self->_oauth_request(
		'POST',	'blog/' . $self->blog . '/post' . $action, %post_values 
	);

	if ( $response->is_success ) {
		return decode_json $response->decoded_content;
	} else {
		$self->error( $response->status_line );
		return 0;
	}
}

1;
