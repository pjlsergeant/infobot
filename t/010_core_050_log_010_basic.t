#!/usr/bin/perl

# 050_config_010_basic.t - Tests for our log multiplexer

	use strict;
	use warnings;

	use Test::More tests => 10;
	use IO::Capture::Stderr; my $capture = IO::Capture::Stderr->new();

	use_ok( 'Infobot::Log' );

	my $object = Infobot::Log->new();

# write() without an init() should cause our backup STDERR logging to fire, and
# also return undef...

	$capture->start();
	ok(! $object->write("#", 1, "Ignore this message1!"), "write returns undef if uninitialised" );
	$capture->stop();
	
	is( $capture->read(), "#:Ignore this message1!\n", "Message passed to STDERR" );

# Init with no object should do the same...

	$object->init();

	$capture->start();
	ok(! $object->write("#", 1, "Ignore this message2!"), "write returns undef if defaulting to STDERR" );
	$capture->stop();

	is( $capture->read(), "#:Ignore this message2!\n", "Message passed to STDERR" );	

# Let's add a couple of fake log objects, and see if they both get hit...

	my $log1;
	my $log2;

	ok( $object->register( FakeLog1->new ), "First log registration returns true"  );
	ok( $object->register( FakeLog2->new ), "Second log registration returns true" );

	my $value = rand(100);

	ok( $object->write( "#", 1, $value ), "write() returns true if there are log objects" );
	is( $log1, $value, "Log 1 hit properly" );
	is( $log2, $value, "Log 2 hit properly" );
	

package FakeLog1;

	use base 'Infobot::Base';

	sub write { $log1 = $_[3]; return 1 }

package FakeLog2;

	use base 'Infobot::Base';

	sub write { $log2 = $_[3]; return 1 }