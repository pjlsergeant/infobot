
package POE::Component::Client::HTTP;

	use POE;

	my $response;

	sub response {
	
		my $self = shift;
		$response = shift;
	
	}
	
	sub spawn {
	
		my $self = shift;
		my %config = @_;
	
		POE::Session->create(

			inline_states => {
			
				_start     => sub {
				
					my ($kernel) = @_[KERNEL];
					$kernel->alias_set( $config{'Alias'} );
				
				},
				
				request => \&request
			
			},

  	);  	
  	
	}
	
	sub request {

		my ( $sender, $kernel, $return_event, $request, $message ) = @_[SENDER, KERNEL, ARG0, ARG1, ARG2];
					
		$kernel->post( $sender => $return_event, [ $request, $message ], [ $response ] );
	
	}

1;