
package Infobot::Plugin::Query::GoogleDefine;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base::HTTP));

	our %help = (
	
		'define' => 'define [string] # Searches Google for a definition of string'
	
	);

	our @required_modules = qw( HTTP::Request::Common URI::Escape  );
	
	sub process {
		
		my $self = shift;
		my $message = shift;

		if ( $message->{message} =~ m/^define (.+)\s*$/ ) {

			$self->get_definition( $message, $1 );
			return 1;

		} else {

			return undef;

		}

	}

	sub get_definition {

		my $self    = shift;
		my $message = shift;
		my $terms   = shift;

		my $url = 'http://www.google.co.uk/search?q=define%3A+' . URI::Escape::uri_escape( $terms );

		$self->log( 5, "Requesting $url" );
		$self->request( $message, HTTP::Request::Common::GET $url ); 

	}

	sub response {

		my $self = shift;

		my ( $message, $response ) = @_;
	
		$self->log( 5, "Response received" );
		
		unless ( $response->is_success ) {

			$message->say("Unable to reach Google");
			$self->log( 5, "Unable to reach Google" );
			return;

		}

		$self->log( 7, "Successful response received" );

		my $data = $response->content;

		if ( $data =~ m/<li>(.+?)</ ) {
		
			$message->say( $1 );
		
		} else {

			$message->say( "Can't find a Google definition for that" );

		}

	}

1;
