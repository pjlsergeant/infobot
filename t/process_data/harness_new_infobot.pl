#!/usr/bin/perl

# new-infobot harness -- push messages through Factoid.pm, and collect some
# output data

	use strict;
	use warnings;
	
	no warnings 'redefine';
	no warnings 'once';
	
	use Test::More tests => 6680;
	use Term::ANSIColor;
	
	use Infobot::Base; 
		my $base = Infobot::Base->new();
		$base->stash( config => { log => { Console => { level => -1 } } } );

	use Infobot::Log;  
		my $log = Infobot::Log->new();
		$log->init;
		$log->stash( log => $log );
		
	use Infobot::Plugin::Log::PrettyConsole;
		my $nulllog = Infobot::Plugin::Log::PrettyConsole->new();
		$nulllog->init('Console');
		$nulllog->register();

	use Infobot::Message;

	my $buffer;

	require UNIVERSAL::require;

	Infobot::Plugin::Query::Client::DBIxClass->require || die $@;
	Infobot::Plugin::Query::Factoids->require || die $@;
	Infobot::Plugin::Query::Karma->require || die $@;

	my $factoid = Infobot::Plugin::Query::Factoids->new();
	my $karma   = Infobot::Plugin::Query::Karma->new();

	*Infobot::Plugin::Query::Karma::DB::topten = sub {};
	*Infobot::Plugin::Query::Karma::DB::get_score = sub {};
	*Infobot::Plugin::Query::Karma::DB::Explain::get_explanation = sub {};
	*Infobot::Plugin::Query::Karma::DB::Explain::add_explanation = sub {};

	*Infobot::Plugin::Query::Karma::DB::increment = sub {
	
		my $item = $_[0];
		$buffer .= "++;;$item\n";		
	
	};

	*Infobot::Plugin::Query::Karma::DB::decrement = sub {
	
		my $item = $_[0];
		$buffer .= "--;;$item\n";		
	
	};

	*Infobot::Plugin::Query::Factoids::get = sub {
		
		my $self = shift;
		my $key  = shift;
		my $db   = shift;
		
		return undef if $db eq 'ignore';
		
		$buffer .= "Searching $db for $key\n";
		return undef;
		
	};
	
	*Infobot::Plugin::Query::Factoids::set = sub {
	
		my ( $thing, $verb, $content ) = @_;
		$buffer .= "set;;$thing;;$verb;;$content\n";
	
	};

package FakeConduit;

	use base 'Infobot::Base';

	sub say { $buffer .= $_[2] }

package main;
	
# Parameters...

	my $nick = 'purl';

	while (<STDIN>) {	
		
		my $divider = $_;
		chomp( $divider );
		next if $divider eq "---DIVIDER---";
		
		my @lines = ($divider);
		
		while(<STDIN>) {
		
			my $in = $_;
			chomp( $in );
			(last && next) if $in eq "---DIVIDER---";
		#	print "-> $in\n";
			push( @lines, $in );
		
		}




		#my @lines = split(/\n/, $data);
		#print "**" . ( join "\n", @lines ) . "**\n";
		#next;

		my $ref = shift(@lines);
		my ( $waste, $user, $line ) = split(/\|\|\|\|/, $ref );
								
#		print "---DIVIDER---\n";
#		print "||||$user||||$line||||\n";

		$buffer = '';

		my $addressed = 0;
		if ( 
			( $line =~ s/^\s*$nick\s*([\,\:\> ]+) *//i ) || 		
			( $line =~ s/^\s*$nick\s*([\,\:\> ]+)\s*(?!is )//i ) ||
			( $line =~ s/, ?$nick(\W*)$//i )
		) {

			$addressed = 1;

		}		

		my $target = '';

if (($line =~ s/^\S+\s*:\s+//) or ($line =~ s/^\S+\s+--+\s+//)) {
	# stripped the addressee ("^Pudge: it's there") 
	$target = $1;
    } elsif ( $addressed ) {
	$target = $nick;
    }

		my $message = Infobot::Message->new();
		$message->init(
		
			name      => $user,
			nick      => $nick,
			message   => $line,
			printable => $line,
			context   => {},
			conduit   => FakeConduit->new(),
			addressed => 0,
			public    => 1,
		
		) || die;
		
		$factoid->process( $message ) ||
		$karma->process(   $message );

		chomp( $buffer );
		is( $buffer, ( join "\n", @lines ), "<$user> $line" ) || die;
	
	}

