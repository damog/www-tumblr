use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $user = WWW::Tumblr::Test::user();

my $follow = $user->follow( url => 'staff.tumblr.com' );

ok $follow,                       'user follow is fine';

done_testing();


