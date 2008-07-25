#!/usr/bin/perl

# 010_base_010_basic.t - Tests that work around the basic functionality of
# the project's base class, Infobot::Base.

	use strict;
	use warnings;

	use Test::More tests => 19;
	use t::lib::NullLog;
	
	use IO::Capture::Stderr; my $capture = IO::Capture::Stderr->new();

# Set 'main::' to be a base class of Infobot::Base

	use base qw(Infobot::Base);
	use_ok( 'Infobot::Log' );

# First of all, we're going to test the basic functionality of load(), by trying
# to load Infobot::Config explicitly. We check for the presence of loaded
# modules by looking in %INC.

	ok( main->load, "Blank load() returns true" );
	ok( !$INC{'Infobot/Config.pm'}, "Infobot::Config not loaded (control check)" );
	ok( main->require_modules('Infobot::Config'), "require_modules() returns true" );
	ok( $INC{'Infobot/Config.pm'}, "Infobot::Log loaded via explicit required_modules" );	

# Some of the calls we're about to make will try and write to the log
# multiplexer, so we intialize that right now...

	main->stash( log => Infobot::Log->new() );

# load() can also read from SELF::required_modules, so let's try and do that to
# load up a copy of Infobot::Pipeline, the incoming data controller.

	our @required_modules = (qw(Infobot::Pipeline));

	ok( !$INC{'Infobot/Pipeline.pm'}, "Infobot::Pipeline not loaded (control check)" );
	ok( main->load, "load() returns true" );
	ok( $INC{'Infobot/Pipeline.pm'}, "Infobot::Pipeline loaded via @required_modules" );

# We provide a private 'get_package_name' function which is used when we're 
# reading package variables. It should return the name of the calling package
# either when called as a package method or an object method...

	my $object = main->new();

	is( main->_get_package_name, "main", "Correct package name on unblessed package" );
	is( $object->_get_package_name, "main", "Correct package name from object" );

# The stash is an application-persistent data store, accesible through the stash
# method. We check we can get and put data in it...

	my $value = rand(100);
	$object->stash( foo => $value );
	is ( $object->stash( 'foo' ), $value, "Stash is working" );

# require_base is a bit like load() (and in fact, calls it internally), but it
# also makes the package on which you call it a subclass of another. So we turn
# main:: (the current package) in to an Infobot::Message too, and then also
# an Infobot::Config, and check that we can sensibly handle multiple inheritance
# through it!

	ok( $object->require_base('Infobot::Message'), "Loading Infobot::Message as base returns true" );
	ok( $object->require_base('Infobot::Config' ), "Loading Infobot::Config as base returns true" );
	isa_ok( $object, 'Infobot::Config'  );
	isa_ok( $object, 'Infobot::Message' );
	isa_ok( $object, 'Infobot::Base'    );

# Now check that that mechanism doesn't work (but also doesn't die) when using a
# non-existant module.

	$capture->start();
	ok(! $object->require_base('Infobot::NOTFOUND'), "Loading Infobot::NOTFOUND as base returns false" );
	$capture->stop();

# Set name should set an object's internal 'name' attribute, and also load the
# correct part of the config file in to its 'config' attribute. It works
# slightly differently in Infobot::Base than in its subclasses, in that you pass
# a category (like 'log' or 'conduit') and its alias. So we check this all works
	
	$object->stash( config => { foo => { bar => { extras => 'bang' } } } );
	$object->set_name( foo => 'bar' );

	is( $object->{config}, 'bang', "set_name gets config values correctly" );
	is( $object->{name},   'bar',  "set_name sets 'name' correctly");
	
	exit 0;
