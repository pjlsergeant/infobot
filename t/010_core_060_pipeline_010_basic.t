#!/usr/bin/perl

# 060_pipeline_010_basic.t - Tests for our pipeline

	use strict;
	use warnings;
	
	my $response = '';

	use Test::More tests => 4;

	use_ok( 'Infobot::Pipeline' );

	my $object = Infobot::Pipeline->new();
	$object->init();

# First let's check that they get priority right...

	$object->add( 40, PipCFoo->new() );
	$object->add( 20, PipAFoo->new() );

# Now check that we do conditional pass-through

	ok(! $response,   "\$response is empty (control)" );

	$object->process( "foo" );
	is( $response, 'foo', "Conditional handler worked" );
	
	$object->process( "bar" );
	is( $response, 'afoo', "Pass-through handler worked" );


package PipCFoo; use base 'Infobot::Base';

	sub process { my $self = shift; my $message = shift; if ( $message =~ m/foo/ ) { $response = 'foo';  return 1 } else { return undef } }

package PipAFoo; use base 'Infobot::Base'; sub process { $response = 'afoo'; return 1 }
