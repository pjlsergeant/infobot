#!/usr/bin/perl

# old-infobot harness -- push messages through 0.43's core and turn them in to
# outgoing events, for use in a testing environment.

	require 'src/Process.pl';
	require 'src/Question.pl';
	require 'src/Norm.pl';
	require 'src/Misc.pl';
	require 'src/Reply.pl';
	require 'src/Statement.pl';
	require 'src/Update.pl';

# Parameters...
	
	@verb = qw(is are);
	@qWord = qw(what who where);
	@dunno = qw(dunno);
	
	%param = (
	
		nick         => 'purl',
		acceptUrl    => 1,
		continuity   => 0,
		allowTelling => 1,
		channel      => '#perl',
		addressing   => 0,
		VERBOSITY    => 20,
		rss          => 0,
		allowUpdate  => 1,
		unignoreWord => 'gooblebrains',
		plusplus     => 1,
		minVolunteerLength => 20,
		maxKeySize   => 40,
		maxDataSize  => 410,
	
	);

	while (<STDIN>) {	
		my $line = $_;
		
		next unless ( $line =~ s/^\d\d:\d\d\s\<\s*([^\s\>]+)\> // );
		
		my $user = $1;
		
		next if $user eq $param{'nick'};
				
		chomp($line);
		
		print "---DIVIDER---\n";
		print "||||$user||||$line||||\n";
		
		process($user, 'public', $line);
		
	}

	sub postInc {
	
		my $item = $_[1];
		print "++;;$item\n";
	
	}
	
	sub postDec {
	
		my $item = $_[1];
		print "--;;$item\n";
	
	}

# These routines fake functionality offered elsewhere in the infobot code...

	sub set {
	
		my ( $thing, $verb, $content ) = @_;
		print "set;;$thing;;$verb;;$content\n";
	
	}

	sub get {
		
		my $db  = shift;
		my $key = shift;
		
		return undef if $db eq 'ignore';
		
		print "Searching $db for $key\n";
		return undef;
		
	}
	sub getDBMKeys { 0 }     # Also apparently for ignores
	sub verifyUser { 0 }     # Used for user auth...
	sub userProcessing { 0 } # Used for user auth...
	sub math { return undef }# Maths subsystems
	sub myRoutines { return undef; }     # Basically the pipeline
	sub Extras {     return undef; }     #  "  "      "    "  "

	sub IsFlag {
	
		my $flag = shift;
		return $flag;
	
	}

	sub channel { getparam('channel') }
	
	sub status {
	
		my $self = shift;
		#warn( $self );
	
	}
	
	sub msg {
	
		my $who  = shift;
		my $what = shift;
	
		print "$who;;$what\n";
	
	}

	sub say {
	
		my $msg = shift;
		print "print;;$msg\n";
	
	}
	
	sub performSay {
	
		my $msg = shift;

		print "print;;$msg\n";
	
	}
	
	sub getparam {
	
		my $key = shift;
		my $value = $param{ $key };
		
		unless ( defined $value || $key eq 'filter' ) { warn $key }
		
		return $value;
	
	}