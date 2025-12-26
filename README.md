# WWW::Tumblr

[![CPAN Version](https://img.shields.io/cpan/v/WWW-Tumblr.svg)](https://metacpan.org/pod/WWW::Tumblr)
[![CPAN Testers](https://img.shields.io/badge/cpan--testers-results-blue.svg)](http://cpantesters.org/distro/W/WWW-Tumblr.html)
[![License](https://img.shields.io/cpan/l/WWW-Tumblr.svg)](https://metacpan.org/pod/WWW::Tumblr)
[![GitHub issues](https://img.shields.io/github/issues/damog/www-tumblr.svg)](https://github.com/damog/www-tumblr/issues)
[![GitHub stars](https://img.shields.io/github/stars/damog/www-tumblr.svg?style=social)](https://github.com/damog/www-tumblr)

Perl bindings for the Tumblr API v2.

## Installation

```bash
cpanm WWW::Tumblr
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

## Synopsis

```perl
use WWW::Tumblr;

my $t = WWW::Tumblr->new(
    consumer_key    => $consumer_key,
    secret_key      => $secret_key,
    token           => $token,
    token_secret    => $token_secret,
);

# Get blog info
my $blog = $t->blog('staff.tumblr.com');
my $info = $blog->info;

# Post to your blog
my $post = $blog->post(
    type => 'text',
    body => 'Hello from Perl!',
);

# Reblog a post
my $reblog = $blog->post_reblog(
    id         => $post_id,
    reblog_key => $reblog_key,
);

# Get tagged posts
my $tagged = $t->tagged(tag => 'perl');
```

## Documentation

Full documentation available at [MetaCPAN](https://metacpan.org/pod/WWW::Tumblr).

- [WWW::Tumblr](https://metacpan.org/pod/WWW::Tumblr) - Main module
- [WWW::Tumblr::Blog](https://metacpan.org/pod/WWW::Tumblr::Blog) - Blog methods
- [WWW::Tumblr::User](https://metacpan.org/pod/WWW::Tumblr::User) - User methods

## Getting API Credentials

1. Go to https://www.tumblr.com/oauth/apps
2. Register a new application
3. Get your OAuth credentials

## Testing

```bash
# Run tests (requires valid API credentials in WWW::Tumblr::Test)
prove -Ilib t/

# Skip posting tests (useful for CI)
TUMBLR_SKIP_POSTING_TESTS=1 prove -Ilib t/

# Skip all live API tests
TUMBLR_SKIP_LIVE_TESTS=1 prove -Ilib t/
```

## Known Limitations

- **Image formats**: Legacy API only supports JPEG, PNG, GIF (not WebP)
- **Video uploads**: Limited to embed URLs (YouTube, Vimeo, etc.)
- **NPF**: Neue Post Format not yet supported

See [CAVEATS](https://metacpan.org/pod/WWW::Tumblr::Blog#CAVEATS) for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## Author

[David Moreno](https://damog.net/) and [contributors](https://github.com/damog/www-tumblr/graphs/contributors).

## License

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Links

- [MetaCPAN](https://metacpan.org/pod/WWW::Tumblr)
- [GitHub](https://github.com/damog/www-tumblr)
- [CPAN Testers](http://cpantesters.org/distro/W/WWW-Tumblr.html)
- [Tumblr API Docs](https://www.tumblr.com/docs/en/api/v2)

