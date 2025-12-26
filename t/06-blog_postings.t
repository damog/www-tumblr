use strict;
use warnings;
use utf8;

use Test::More;
use LWP::Simple 'get';
use JSON;
use Data::Dumper;
use Encode 'decode_utf8';

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my %post_types = (
    text    => { body => scalar localtime() },
    photo   => { source => 'https://picsum.photos/400/200' },
    quote   => { quote => 'The only way to do great work is to love what you do. - Steve Jobs' },
    link    => do {
        eval {
            my $data = decode_json( get("https://fastapi.metacpan.org/v1/favorite/_search?size=50&fields=author,release&sort=date:desc") );
            my $hit = $data->{hits}->{hits}->[ int rand @{$data->{hits}->{hits}} ];
            my ( $author, $release ) = @{ $hit->{fields} }{'author', 'release'};
            { url => "https://metacpan.org/release/$author/$release" }
        } or do {
            { url => "https://damog.net/blog" }
        };
    },
);

# TODO: chat, audio, video

my $blog = WWW::Tumblr::Test::blog();

for my $type ( sort keys %post_types ) {
    ok $blog->post( type => $type, %{ $post_types{ $type } } ),       "trying $type";
}

# Test UTF-8 posting (PR #15)
my $utf8_body = scalar(localtime()) . " - UTF-8 test: \x{65e5}\x{672c}\x{8a9e}";  # Japanese chars
ok $blog->post(
    type => 'text',
    body => $utf8_body,
), "trying text with UTF-8 characters";

done_testing();
