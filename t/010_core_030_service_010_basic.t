#!/usr/bin/perl

# 030_service_010_basic.t - Tests that deal with our core service base class
	
	use strict;
	use warnings;

	use Test::More tests => 1;
	use base qw(Infobot::Service);


	our $name = rand(100);
	
	is( main->key, $name, "key() returns correctly" );