use strict;
use warnings;

use Test::More;

use_ok 'WWW::Tumblr';
use_ok 'WWW::Tumblr::Test';

my $blog = WWW::Tumblr::Test::blog();

my $photo = $blog->post(
    source => 'http://www.baconwrappedmedia.com/wp-content/uploads/2013/01/funny-kids-bacon-wrapped-media-21.jpg',
    type => 'photo',
);

ok $photo,      'posting a small image';
is ref $photo, 'HASH',      'checking the response is a hash';
ok defined $photo->{id},    'there\'s an id for the post';

done_testing();
