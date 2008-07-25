#!/usr/bin/perl

# 040_config_010_basic.t - Tests for our config class

	use strict;
	use warnings;

	use Test::More tests => 9;
	use Test::Exception;

	use_ok( 'Infobot::Config' );

	my $object = Infobot::Config->new();

# Errors with config /have/ to be fatal, as it's so important, and the whole
# thing basically can't run without a config file. The three error cases are
# no filename, the filename provided doesn't map to something that passed -f,
# and YAML::Syck doesn't like the data...


	for (
		# Problem,          Error regex, file
		[ 'Blank filename', qr/No filename/,   ''                        ],
		[ 'Missing file',   qr/No file found/, '/asdf/asdfasdfas/fsa/df' ],
		[ 'Malformed file', qr/Syck parser/,   't/config_files/malformed.yaml' ]
	) {
	
		my ( $problem, $regex, $file ) = @$_;
		
		$object->stash( config_file => $file );
		
		dies_ok { $object->init() } $problem . " causes fatal exception";
		like $@, $regex, $problem . " error message correct";
	
	}

	$object->stash( config_file => 't/config_files/very_basic.yaml' );	
	ok( $object->init(), "init() working fine for real file" );
	is( $object->stash( 'config' )->{foo}, "bar", "Config accessible" );
	