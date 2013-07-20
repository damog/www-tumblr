#!/usr/bin/env perl

use warnings;
use strict;

use CGI;
use WWW::Tumblr;

my $tumblr = WWW::Tumblr->new(
	consumer_key => 'xxx',
	secret_key => 'xxx',
	blog => 'blog.tumblr.com',
	callback => 'http://my-application-site.com/tumblr.cgi'
);

if ( param('oauth_token') && param('oauth_verifier') ) {
	_saveTumblrToken();
}

#	Get url for authorization
my $tumblr_url = $tumblr->authorization_url;

#	Store session somewhere, e.g. Storable, we'll need it later
my $session = $tumblr->session;

sub _saveTumblrToken {
	my $token = param('oauth_token') or return 0;
	my $verfier = param('oauth_verifier') or return 0;

	#	Restore tumblr session
	$tumblr->session();	#	use stored $session here
	
	my( $access_token, $token_secret ) = $tumblr->get_token( $token, $verfier );

	#	Save $access_token, $token_secret, we'll use it to talk with Tumblr

	return 1;
}

#	Post something, we need $access_token, $token_secret here

my $tumblr_again = WWW::Tumblr->new(
	consumer_key => 'xxx',
	secret_key => 'xxx',
	token => $access_token,
	token_secret => $token_secret,
	blog => 'blog.tumblr.com',
);


my $response = $tumblr_again->post( type => 'text', title => 'Hello world!', body => 'Hello world!' );