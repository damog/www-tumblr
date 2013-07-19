package WWW::Tumblr;

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


use strict;
use warnings;

use Carp;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;

our $VERSION = '4.1';

=head2 new

 new(
 	user => $user,
 	email => $email,
 	password => $password,
 	url => $url,
 );

Initilizes a class instance.

All arguments are optional, you can specify most of them here on each of the method
calls anyway.

=cut

sub new {
	my($class, %opts) = @_;

	my $ua = LWP::UserAgent->new;
	
	return bless {
		user		=> $opts{user},
		email		=> $opts{email},
		password	=> $opts{password},
		url			=> $opts{url},
		ua 			=>	$ua,
	}, $class;
}

=head2 email

 email(
 	$email
 );

If C<$email> is specified, it sets the email class variable, otherwise, the
previous value is returned. This is the email that users use to log in to
Tumblr.

=cut

sub email {
	my($self, $email) = @_;
	$self->{email} = $email if $email;
	$self->{email};
}

=head2 password

 password(
 	$password
 );

If C<$password> is specified, it sets the password class variable, otherwise
the previous value is returned. This is the password used by users to log in
to Tumblr.

=cut

sub password {
	my($self, $password) = @_;
	$self->{password} = $password if $password;
	$self->{password};
}

=head2 user

 user(
 	$user
 );

If C<$user> is specified, it sets the user class variable, otherwise
the previous value is returned. This is the user portion of the tumblr.com
URL (ie. maria.tumblr.com).

=cut

sub user {
	my($self, $user) = @_;
	$self->{user} = $user if $user;
	$self->{user};
}

=head2 url

 url(
 	$url
 );

If C<$url> is specified, it sets the url class variable. Otherwise,
the previous value is returned. This is the URL that some people might
use for their Tumblelogs instead of user.tumblr.com (in my case, L<http://log.damog.net>).

=cut

sub url {
	my($self, $url) = @_;
	
	if($url) {
		$self->{url} = $url;
		$self->{url} =~ s/\/\z//;
	} else {
		$self->{url} = 'http://' . $self->user . '.tumblr.com'
			if $self->user;
	}
	
	return $self->{url};
}

=head2 read_json

 read_json(
 	# read params
 	...
 );

Returns the JSON version of c<read>, it accepts the same Tumblr API
arguments. It returns the JSON version of C<read>.

=cut

sub read_json {
	my($self, %opts) = @_;
	$opts{json} = 1;
	return $self->read(%opts);
}

=head2 read

 read(
 	# read args
 	...
 );

You should have specified the user or url to use this method. Parameters
to be passed are the ones specified on the Tumblr API, such as id, num,
type, etc. It returns an XML string containing the output.

If the option C<auth =&gt; 1> is passed, an authenticated read request
is being made in order to retrieve the private posts as well. See
Tumblr's API for details.

=cut

sub read {
	my($self, %opts) = @_;
	
  my $auth;
  if($opts{auth}) {
    croak "No email or password defined"
      if not $self->email or not $self->password;
    $auth = 1;
    delete $opts{auth};
  }

	croak "No user or url defined" unless $self->user or $self->url;

	my $url = $self->url . '/api/read';
	
	$url .= '/json' if defined $opts{json};
	$url .= '?'.join'&',map{qq{$_=$opts{$_}}} sort keys %opts;

  if($auth) {
    $opts{email} = $self->email;
    $opts{password} = $self->password;
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content(join '&', map{ qq{$_=$opts{$_}} } sort keys %opts);
    my $res = $self->{ua}->request($req);
    if($res->is_success) {
      return $res->decoded_content;
    } else {
      $self->errstr($res->as_string);
      return;
    }
  } else {
    return $self->{ua}->get($url)->content;
  }
}

=head2 write

 write(
 	type => $type,
 	...
 	# other write args
 );

Posts a C<type> item with the needed arguments from the Tumblr API.
The C<type> argument is mandatory. C<email> and C<password> should have
been specified before too. In success, it returns true, otherwise, it
returns undef. For file uploads, just specify the filename on the C<data>
argument.

=cut 

sub write {
	my($self, %opts) = @_;

	croak "No email was defined" unless $self->email;
	croak "No password was defined" unless $self->password;
	croak "No type defined for writing" unless $opts{type};
	
	$opts{'email'} = $self->email;
	$opts{'password'} = $self->password;
	
	my $req;
	my $res;
	
	# If there's a file to upload or not
	if($opts{data}) {
		$opts{data} = [$opts{data}]; # whack!
		
		$res = $self->{ua}->request(POST 'http://www.tumblr.com/api/write', Content_Type => 'form-data', Content => \%opts);
		
	} else {
		$req = HTTP::Request->new(POST => 'http://www.tumblr.com/api/write');
		$req->content_type('application/x-www-form-urlencoded');
		$req->content(join '&', map{ qq{$_=$opts{$_}} } sort keys %opts);
		$res = $self->{ua}->request($req);
	}
	
	if($res->is_success) {
		return $res->decoded_content;
	} else {
		$self->errstr($res->as_string);
		return;
	}
	
}

=head2 edit

 edit(
   'post-id' => 123,
   type => 'regular',
   title => 'This has changed!',
   ...
 );

Edits the post idenfied with C<post-id>. The same parameters as those used
with C<write> can be used, but C<post-id> has to be specified.

=cut

=head2 delete

 delete(
   'post-id' => 123,
 );

Deletes the post idenfied with the C<post-id> id.

=cut

sub delete {
  my($self, %opts) = @_;

  $opts{email} = $self->email;
  $opts{password} = $self->password;

  croak "No email was defined" unless $self->email;
  croak "No password was defined" unless $self->password;

  my $req = HTTP::Request->new(POST => 'http://www.tumblr.com/api/delete');
  $req->content_type('application/x-www-form-urlencoded');
  $req->content(join '&', map { qq{$_=$opts{$_}} } sort keys %opts);
  my $res = $self->{ua}->request($req);
  
  if($res->is_success) {
    return $res->decoded_content;
  } else {
    $self->errstr($res->as_string);
    return;
  }
}

=head2 check_audio

 check_audio();

This method has been deprecated on this implementation since it was
also on the Tumblr API.

Checks if the user can upload an audio file. Returns true or undef.

=cut

sub check_audio {
	my($self) = shift;
	
	croak "No email was defined" unless $self->email;
	croak "No password was defined" unless $self->password;
	
	$self->_POST_request(
		qq{action=check-audio&email=${\$self->email}&password=${\$self->password}}
	) or return;
}

=head2 check_vimeo

 check_vimeo();

Deprecated as the Tumblr API discontinued it.

Checks if the user is logged in on Vimeo, as specified by the Tumblr API.
Returns the maximum number of bytes available for the user to upload in case
the user is logged in, otherwise it returns undef.

=cut

sub check_vimeo {
	my($self) = shift;
	
	croak "No email was defined" unless $self->email;
	croak "No password was defined" unless $self->password;
	
	$self->_POST_request(
		qq{action=check-vimeo&email=${\$self->email}&password=${\$self->password}}
	) or return;
	
	return $self->{_response};
}

=head2 authenticate

 authenticate();

Checks if the C<email> and C<password> specified are correct. If they are,
it returns true, otherwise, undef.

=cut

sub authenticate {
	my($self) = shift;
	
	croak "No email was defined" unless $self->email;
	croak "No password was defined" unless $self->password;

	$self->_POST_request(
		qq{action=authenticate&email=${\$self->email}&password=${\$self->password}}
	) or return;
}

=head2 errstr

 errstr();

It returns the error string for the last operation, so you can see why
other methods failed.

=cut

sub errstr {
	my($self, $err) = @_;
	$self->{errstr} = $err if $err;
	$self->{errstr};
}

=head2 _POST_request

 _POST_request($string);

Internal method to post C<$string> to Tumblr. You shouldn't be using it anyway.

=cut


sub _POST_request {
	my($self, $args) = @_;
	
	croak "No arguments present" unless $args;
	
	my $req = HTTP::Request->new(POST => 'http://www.tumblr.com/api/write');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($args);
	
	my $res = $self->{ua}->request($req);
	
	if($res->is_success) {
		return $self->{_response} = $res->decoded_content;
	} else {
		$self->{_response} = $res->decoded_content;
		$self->errstr($self->{_response});
		return;
	}
	
}

=head1 SEE ALSO

L<http://tumblr.com>, L<http://tumblr.com/api>. See also the sample scripts on the examples/ dir.

This and other interesting modules and hacks are posted by the author on
his blog Infinite Pig Theorem, L<http://damog.net>.

=head 1 CODE

The code is actively maintained at L<http://github.com/damog/www-tumblr>.

=head1 AUTHOR

David Moreno Garza, E<lt>david@axiombox.comE<gt>

=head1 THANKS

You know who (L<http://maggit.net>).

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by David Moreno Garza - Axiombox

L<http://axiombox.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER

I'm not a worker nor affiliated to Tumblr in any way, and this is a
separated implementation of their own public API.

=cut

1;
