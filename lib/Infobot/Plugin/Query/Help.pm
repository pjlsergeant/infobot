
package Infobot::Plugin::Query::Help;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base));
	use Data::Dumper;

	our %help = (
	
		help => "help [topic] # Returns a list of help available on a given topic, or a list of help topics if no topic is specified",
	
	);
	
	sub process {
		
		my $self = shift;
		my $message = shift;

		if ( $message->{message} =~ m/^help\s*$/ ) {

			my %stashed_help = %{ $self->stash('help') };

			my $topics = join ', ', sort { lc($a) cmp lc($b) } ( keys %stashed_help );

			$message->say( "Available help topics: $topics" );

			return 1;

		} elsif ( $message->{message} =~ m/^help\s*(\S+)$/ ) {

			my $topic = $1;
			
			my $segment = $self->stash('help');
						
			for my $link ( split( /\//, $topic ) ) {
			
				unless ( ref($segment) ) {
				
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
					return 1;
		
				}
		
			} else {
			
				$message->say( "Help for $topic: $segment" );
				return 1;

			}

		} else {

			return undef;

		}

	}

1;
