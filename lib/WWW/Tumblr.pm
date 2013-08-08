package WWW::Tumblr;

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
use WWW::Tumblr::Authentication::OAuth;
use LWP::UserAgent;

has 'consumer_key',     is => 'rw', isa => 'Str';
has 'secret_key',       is => 'rw', isa => 'Str';
has 'token',            is => 'rw', isa => 'Str';
has 'token_secret',     is => 'rw', isa => 'Str';

has 'callback',         is => 'rw', isa => 'Str';
has 'error',            is => 'rw', isa => 'WWW::Tumblr::ResponseError';
has 'ua',               is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new };

has 'session_store',	is => 'rw', isa => 'HashRef', default => sub { {} };

has 'oauth',            is => 'rw', isa => 'Net::OAuth::Client', default => sub {
	my $self = shift;
	Net::OAuth::Client->new(
		$self->consumer_key,
		$self->secret_key,
		request_token_path => 'http://www.tumblr.com/oauth/request_token',
		authorize_path => 'http://www.tumblr.com/oauth/authorize',
		access_token_path => 'http://www.tumblr.com/oauth/access_token',
		callback => $self->callback, 
		session => sub { if (@_ > 1) { $self->_session($_[0] => $_[1]) }; return $self->_session($_[0]) },
	);
};

sub user {
    my ( $self ) = shift;
    return WWW::Tumblr::User->new({
        consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        token           => $self->token,
        token_secret    => $self->token_secret,
    });
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
    });
}

sub oauth_tools {
	my ( $self ) = shift;
	return WWW::Tumblr::Authentication::OAuth->new(
		consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        callback		=> $self->callback,
	);
}

sub _tumblr_api_request {
    my $self    = shift;
    my $r       = shift; #args

    my $method_to_call = '_' . $r->{auth} . '_request';
    return $self->$method_to_call(
        $r->{http_method}, $r->{url_path}, $r->{extra_args}
    );
}

sub _none_request {
    my $self        = shift;
    my $method      = shift;
    my $url_path    = shift;
    my $params      = shift;

    my $req;
    if ( $method eq 'GET' ) {
        print "Requesting... " .'http://api.tumblr.com/v2/' . $url_path, "\n";
        $req = HTTP::Request->new(
            $method => 'http://api.tumblr.com/v2/' . $url_path,
        );
    } elsif ( $method eq 'POST' ) {
        ...
    } else {
        die "dude, wtf.";
    }

    my $res = $self->ua->request( $req );

    if ( my $prev = $res->previous ) {
        return $prev;
    } else { return $res };
}

sub _apikey_request {
    my $self        = shift;
    my $method      = shift;
    my $url_path    = shift;
    my $params      = shift;

    my $req; # request object
    if ( $method eq 'GET' ) {
        $req = HTTP::Request->new(
            $method => 'http://api.tumblr.com/v2/' . $url_path . '?api_key='.$self->consumer_key.
            ( join '&', map { $_ .'='. $params->{ $_} } keys %$params )
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
	my $params = shift;

	my $request = $self->oauth->_make_request(
		'protected resource', 
		request_method => uc $method,
		request_url => 'http://api.tumblr.com/v2/' . $url_path,
		consumer_key => $self->consumer_key,
	    consumer_secret => $self->secret_key,
		token => $self->token,
		token_secret => $self->token_secret,
		extra_params => $params,
	);
	$request->sign;

	my $message = $method =~ /post/i 
				? POST $request->to_url, Content => $request->to_post_body
				: GET $request->to_url;

	return $self->oauth->request( $message );
}

sub _session {
	my $self = shift;

	if ( ref $_[0] eq 'HASH' ) {
		$self->session_store($_[0]);
	} elsif ( @_ > 1 ) {
		$self->session_store->{$_[0]} = $_[1]
	}
	return $_[0] ? $self->session_store->{$_[0]} : $self->session_store;
}

1;

