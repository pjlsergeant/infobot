
	use strict;
	use warnings;

	BEGIN { $ENV{'INFOBOT_NO_DEFAULT_LOG'} = 1 }

	use t::lib::TestConduit;

	t::lib::TestConduit->tests(
	
	# Rot 13
	
		[ "Simple ROT13 test",          'rot13 peter' => 'crgre' ],
		[ "Simple ROT13 negative test", 'rat13 peter' => 'not caught' ],
	
	# Help system
	
		[ "Enumerate help topics",
			'help' => 'Available help topics: foo, help, helptest, rot13' ],
	
		[ "Simple help response",
			'help foo' => 'Help for foo: bar' ],
	
		[ "Nested help response",
			'help helptest/foo' => 'Help for helptest/foo: bar' ],
			
		[ "Nested help enumeration",
			'help helptest/foo2' => 'Available help topics for helptest/foo2: helptest/foo2/foo21, helptest/foo2/foo22' ],
	
		[ "Nest help enumeration with default",
			'help helptest/foo1' => 'Help for helptest/foo1: foo1 stuff (see also: helptest/foo1/foo12, helptest/foo1/foo13)' ],
	
		[ "Help Missing Start Path",
			'help missing' => "Couldn't find any help for missing (lost path at missing)" ],
		
		[ "Help Missing Mid Path",
			'help helptest/foo1/missing/massing' => "Couldn't find any help for helptest/foo1/missing/massing (lost path at missing)" ],
		
		[ "Help Missing End Path",
			'help helptest/foo1/foo12/missing' => "Couldn't find any help for helptest/foo1/foo12/missing (lost path at missing)" ],
		
		
	
	);
	
	use Infobot;

	Infobot->start( 't/config_files/test_conduit.yml' );

__DATA__


		helptest => {
		
			foo => 'bar',
			foo1 => { '_' => 'foo1 stuff', foo12 => 'bar12', foo13 => 'bar13' },
			foo2 => { foo21 => 'foo21', foo22 => 'foo22' },
		
		}
		
		
					$message->say( "Available help topics: $topics" );

			return 1;

		} elsif ( $message->{message} =~ m/^help\s*(\S+)$/ ) {

			my $topic = $1;
			
			my $segment = $self->stash('help');
						
			for my $link ( split( /\//, $topic ) ) {
			
				unless ( $segment && ( ref($segment) ) ) {
				
					$message->say( "Couldn't find any help for $topic (lost path at $link)" );
					return 1;
				
				}
				
				$segment = $segment->{$link};
				
				unless ( $segment ) {
				
					$message->say( "Couldn't find any help for $topic (lost path at $link)" );
					return 1;					
				
				}
			
			}
			
			if ( ref( $segment ) ) {

				my $topics = join ', ', grep { ! /\/_$/ } ( map { $topic . '/' . $_ } (sort { lc($a) cmp lc($b) } ( keys %$segment )) );

				if ( $segment->{_} ) {
				
					$message->say( "Help for $topic: " . $segment->{_} . " (see also: $topics)");
					return 1;
				
				} else {


					$message->say( "Available help topics for $topic: $topics" );
		
				}
		
			} else {
			
				$message->say( "Help for $topic: $segment" );