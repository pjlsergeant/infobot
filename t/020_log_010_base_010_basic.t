#!/usr/bin/perl

# 100_log_base_010_basic.t -- Log base class

	use strict;
	use warnings;
	
	use Test::More tests => 7;

	use_ok( 'Infobot::Plugin::Log::Base' );

	my $multiplex = 0;

# Set name should set an object's internal 'name' attribute, and also load the
# correct part of the config file in to its 'config' attribute. It should be
# explicitly tryin to retrieve the 'conduit' category here... set_name is called
# via init()
	
	my $object = FakeLogger->new();
	
	$object->stash( log => FakeMultiplex->new() );
	
	$object->stash( config => { log => { bar => { extras => 'bang', level => 4 } } } );
	$object->init( 'bar' );

	ok( $multiplex, "Logger registered" );

	is( $object->{config}, 'bang', "set_name gets config values correctly" );
	is( $object->{name},   'bar',  "set_name sets 'name' correctly");

# Check the priority was set approriately...

	is( $object->level, 4, "Level correctly set" );

	ok(! $object->write( 'Package', 9, "Bad" ), "Lower level message returns 0" );
	ok( $object->write(  'Package', 1, "Good" ), "Higher level message returns 1" );
	

package FakeLogger;

	use base 'Infobot::Plugin::Log::Base';

	sub output { return 1 }	

package FakeMultiplex;

	use base 'Infobot::Plugin::Log::Base';

	sub register {
	
		my $self = shift;
		my $obj  = shift;
	
		if ( ref( $obj ) eq 'FakeLogger' ) {
		
			$multiplex = 1;
				
		} else {
		
			$multiplex = 0;
		
		}
	
	}