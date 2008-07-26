
package Infobot::Plugin::Query::Gender;

	use strict;
	use warnings;
	
	use base (qw( Infobot::Plugin::Query::Base::DBIxClass ));

	our %help = (
	
		'gender' => {
		
			'_' => "(what is the) gender [of/for/] NAME? # Returns the likely gender of a name, based on US Census data",
		
		}
	
	);
	
	my $census = 'in the abridged 1990 US Census data';

	sub process {

		my $self    = shift;
		my $message = shift;


		if ( $message->{message} =~ m/^(?:what(?: is|'s)? ?(?:the)?) ?gender (?:of|for)? ([^\s]+)\s*\??$/i ) {

			my $name = $1;

			$self->log( 8, "Searching for " . uc($name) );
			my ($nameobj) = $self->dbi->search( name => uc($1) )->all();

			unless ( $nameobj ) {
			
				$self->log( 8, "Nothing found..." );
				$message->say( "No-one called '$name' found $census" );
				return 1;
			
			}

			my $male = $nameobj->mp;
			
			if ( $male == 100 ) {
			
				$message->say("$name only appears as a male name $census" ); 
			
			} elsif ( $male == 0 ) {
			
				$message->say("$name only appears as a female name $census" ); 				
						
			} elsif ( $male > 50 ) {
			
				$message->say("$name was a male name " . $male . "\% of the time $census" ); 
			
			} else {
			
				$message->say("$name was a female name " . (100-$male) . "\% of the time $census" ); 			
			
			}

			return 1;
			
		} else {
			
			return undef;
			
		}

	}
	
	
1;