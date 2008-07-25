
	use strict;
	use warnings;

	use ExtUtils::MakeMaker;

	my %config = (

	NAME => 'Infobot',
	VERSION_FROM => 'lib/Infobot.pm',

	);

	my %prerequisites = map { $_ => '' } qw(

		POE
		POE::Component::Client::HTTP
		POE::Component::IRC
		File::Basename
		DBIx::Class
		DBIx::Class::Schema::Loader
		DBD::SQLite
		IO::Capture
		HTTP::Request
		HTML::TreeBuilder
		UNIVERSAL::require
		YAML::Syck	
		Term::ANSIColor

	);

	WriteMakefile(

		%config,
		PREREQ_PM => \%prerequisites

	);

