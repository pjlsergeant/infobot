#!/usr/bin/perl

# 080_conduit_base_010_basic.t - Tests around the base class for query plugins

	use strict;
	use warnings;
	
	use Test::More tests => 4;
	use Test::Exception;
	use t::lib::NullLog;

	use DBI;
	use Infobot::Log;
	use Infobot::Plugin::DataSource::DBIxClass;
	
	my $log = Infobot::Log->new();
	$log->init;
	$log->stash( log => $log );
	t::lib::NullLog->new()->register();
	
	die "YIKES: $!" unless Infobot::Plugin::DataSource::DBIxClass->load();

	{
	# Create a simple database, using DBI...
	
		unlink 't/databases/test.db';
		my $dbh = DBI->connect( 'dbi:SQLite:dbname=t/databases/test.db' );
		$dbh->prepare("create table foo ( id int not null, kk char(10), vv int, primary key( id ) )")->execute();
	
	}
	
	my $object = Infobot::Plugin::DataSource::DBIxClass->new();
	$object->stash( config => { 
		datasource => { foo => { alias => 'dbixclass', extras => { 
			dsn   => 'dbi:SQLite:dbname=t/databases/test.db',
		} } } ,
		query      => { 
			bar => { extras => { db => 'dbixclass', table => 'foo' } }, 
			baz => { extras => { db => 'dbixclass', table => 'baz' } }
		}
	} );
	$object->init( 'foo' );

	my $test = TestModule->new();
	$test->init('bar');
	
	my $value = int(rand(1) * 100);
	
	$test->dbi->create( { id => 1, kk => 'abc', vv => $value } );
	
	my $row = $test->dbi->find( 1 );
	
	is( $row->vv, $value, "Row value matches" );

	my $test2 = TestModule->new();
	ok(! $test2->init('baz'), "No such table" );

# Remove the DB from the stash, and try and do a ->dbi - this should
# upset it a little >:)

	$test->stash( 'dbixclass' => '' );
	dies_ok { $test->init('foo') } 'Removal of dbi causes a DIE';
	like $@, qr/Where di/, "Error message matches";

	END { unlink 't/databases/test.db' }



package TestModule;

	use strict;
	use warnings;
	
	use Test::More;
	use base 'Infobot::Plugin::Query::Base::DBIxClass';

1;
