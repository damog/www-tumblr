package WWW::TumblrV2;

use base qw(Class::Accessor::Fast);

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

	return $response->is_success ? $response->decoded_content : $response->status_line;
}

1;
