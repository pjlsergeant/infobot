#!/usr/bin/perl

	use strict;
	use warnings;

	use DBI;

	die "You must specify a database!" unless $ARGV[0];

	my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $ARGV[0] );
	
	$dbh->do("CREATE TABLE facts ( thing char(50) primary key, verb char(5), content varchar(410) )");

