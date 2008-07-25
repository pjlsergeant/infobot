#!/usr/bin/perl

# 020_message_010_simple.t - Tests that deal with our message encapsulation
# layer...
	
	use strict;
	use warnings;

	use t::lib::NullLog;
	use Test::More tests => 17;

# $buffer here is a file-scoped variable, and we're going to use it to easily
# and non-invasively pass data back from our faked up conduit object (below)

	my $buffer;

# Some calls get a bit needy if they don't have a logging object

	use Infobot::Log;
	Infobot::Log->stash( log => Infobot::Log->new() );
	t::lib::NullLog->new()->register();

# Check that there are no compile-time errors with Infobot::Message...

	use_ok( 'Infobot::Message' );

# Create our message. Infobot::Message's init() method takes a whole bunch
# of attributes - we're going to start off calling it with none to check
# we get a 0 back (a convention in this app for the method failing)

	my $message = Infobot::Message->new();
	ok(! $message->init(), "init() without required attributes fails" );

# Now we set a bunch of attributes, attempt to set them in the message using
# init(), and check we get them all back again...

	my %attributes = (

		addressed => 1,
		conduit   => { name => rand(100) },
		context   => { name => rand(100) },
		message   => rand(100),
		name      => rand(100),
		nick      => rand(100),
		printable => rand(100),
		public    => 0,
	#	id        => 'TestMessage'

	);

	ok( $message->init(

		%attributes	

	), "Message creation succeeded" );

	for( keys %attributes ) {

		is( $message->$_, $attributes{$_}, "$_ set correctly" );

	}

# Now we're going to use a faked-up conduit, to check the addressing fail-safe
# features when say() is called on a message. 'addressed' is a required field
# for a message object, specifying if we consider that someone was deliberately
# trying to talk to us. The option 'addressing' field in the context attribute
# is a way of saying that the conduit requires the application to have been
# addressed for a response (so 1 if that's the case, 0 or undef otherwise)
	
	$message->{conduit} = TestConduit->new();
	$message->{conduit}->{name} = 'Test Conduit';

	for my $testcase (
		# Addressed, Addressing, Value?
		[ 0,         1,          0],
		[ 1,         1,          1],
		[ 0,         0,          1],
		[ 1,         0,          1],
	) {

		$message->{addressed} = $testcase->[0];
		$message->{context}->{addressing} = $testcase->[1];

		$buffer = '';
		my $value = rand(100);
		
		$message->say( $value );

		if ( $testcase->[2] ) {

			is( $buffer, $value, "Value correctly transmitted" );

		} else {

			ok(! $buffer, "Value correctly withheld" );

		}

	}

# Check nothing untoward happens if the conduit's 'say' message returned undef...

	$message->{conduit} = FalseConduit->new();
	ok(! $message->say( 'foo' ), "Undef propogated up through say()" );

# Check we get some sensibly values back from the message counter...

	$message->_counter for 1 .. 100;
	is( $message->_counter, "01G", "Message counter at 102 is correct" );

package TestConduit;

	use base qw(Infobot::Base);

	sub say {

		my $conduit = shift;
		my $messobj = shift;
		my $reply   = shift;

		$buffer = $reply;
		return 1;

	}

package FalseConduit;

	use base qw(Infobot::Base);
	
	sub say { return undef }
