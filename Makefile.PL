use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'WWW::Tumblr',
	VERSION_FROM    => 'lib/WWW/Tumblr.pm',
	AUTHOR          => q{David Moreno <david@axiombox.com>},
	ABSTRACT_FROM   => 'lib/WWW/Tumblr.pm',

	($ExtUtils::MakeMaker::VERSION >= 6.3002
	? ('LICENSE'=> 'perl')
	: ()),

    
	PREREQ_PM => {
		'Test::More'     => 0.88,
		'LWP'            => 0,
	},

	MIN_PERL_VERSION => '5.008',

	META_MERGE => {
		resources => {
			homepage   => 'http://github.com/damog/www-tumblr',
			repository => 'git://github.com/damog/www-tumblr.git'
		}
	},

	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'WWW::Tumblr-*' },

);
