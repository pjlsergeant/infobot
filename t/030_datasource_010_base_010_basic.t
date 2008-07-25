#!/usr/bin/perl

# 080_conduit_base_010_basic.t - Tests around the base class for query plugins

	use strict;
	use warnings;
	
	use Test::More tests => 4;

	use_ok( 'Infobot::Plugin::DataSource::Base' );

# Set name should set an object's internal 'name' attribute, and also load the
# correct part of the config file in to its 'config' attribute. It should be
# explicitly tryin to retrieve the 'conduit' category here... set_name is called
# via init()
	
	my $object = Infobot::Plugin::DataSource::Base->new();
	
	$object->stash( config => { datasource => { bar => { extras => 'bang', alias => 11 } } } );
	$object->init( 'bar' );

	is( $object->{config}, 'bang', "set_name gets config values correctly" );
	is( $object->{name},   'bar',  "set_name sets 'name' correctly");

# Check the priority was set approriately...

	is( $object->alias, 11, "Alias correctly set" );

