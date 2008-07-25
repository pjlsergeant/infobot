#!/usr/bin/perl

	use strict;
	use warnings;

	use Test::More tests => 2;

	use IO::Capture::Stderr;

	use_ok( 'Infobot::Plugin::Log::STDERR' );

	my $object = Infobot::Plugin::Log::STDERR->new();

	my $package = int(rand(100));
	my $level   = int(rand(100));
	my $message = int(rand(100));


	my $capture = IO::Capture::Stderr->new();
	
	$capture->start();
	$object->output( $package, $level, $message );
	$capture->stop();
	
	is( $capture->read(), "[$package] [$level] $message\n", "Correct error message pushed out on STDERR" );
	