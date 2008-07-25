#!/usr/bin/perl

# 070_conduit_base_010_basic.t - Tests around the base class for conduits

	use strict;
	use warnings;
	
	use Test::More tests => 5;

	use_ok( 'Infobot::Plugin::Conduit::Base' );

# Set name should set an object's internal 'name' attribute, and also load the
# correct part of the config file in to its 'config' attribute. It should be
# explicitly tryin to retrieve the 'conduit' category here...
	
	my $object = Infobot::Plugin::Conduit::Base->new();
	
	$object->stash( config => { conduit => { bar => { extras => 'bang' } } } );
	$object->set_name( 'bar' );

	is( $object->{config}, 'bang', "set_name gets config values correctly" );
	is( $object->{name},   'bar',  "set_name sets 'name' correctly");

# Check that our process method is the shortcut we think it is...

	$object->stash( pipeline => FakeClass->new() );
	is( $object->pipeline, 3, "pipeline method works as an alias to the pipeline" );

# Finally, the default say method should return true

	ok( $object->say('asdf'), "Default say() returns true" );

package FakeClass;

	use base 'Infobot::Base';

	sub process { return 3 }