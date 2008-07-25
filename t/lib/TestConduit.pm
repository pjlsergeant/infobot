
package t::lib::TestConduit;

	use strict;
	use warnings;

	use base qw( Infobot::Plugin::Conduit::Base );

	use Test::More;
	use POE;

	my @tests;
	my $results;
	
	
	sub tests {
	
		my $self = shift;
		
		@tests = @_;
	
		plan tests => scalar @tests;
	
	}

	sub init {
 
 		my $self = shift;
	 	my $name = shift;
 	
 		$self->set_name( $name );
 
	# Schedule a call to 'run_tests'
	
		POE::Session->create(

			inline_states => {
			
				_start     => sub {
					my ($kernel, $session) = @_[KERNEL, SESSION];
					$kernel->delay_set( run_tests => 1 );
				},
			
			},
						
			object_states => [ $self => [ 'run_tests' ] ],
    
  	);  
	
		diag( "Tests scheduled. Waiting 1 second" );
	
		return 1;

	}

	sub run_tests {
	
		my $self = $_[ OBJECT ];
		
		diag( "Running tests" );
		
		for my $test ( @tests ) {
		
			my ( $name, $query, $response ) = @$test;

			my $message = Infobot::Message->new();

			$message->init(
		
				conduit   => $self,
				context   => { response => $response, name => $name },
				name      => 'Test',
				nick      => $self->stash('config')->{'alias'},
				message   => $query,
				public    => 0,
				addressed => 1,
				printable => $query,
		
			) or die ( $message->error );

	 # Give to the pipeline
			
			$self->pipeline($message);			
			
		
		}
	
	}
 
	sub say {
 
		my ( $self, $message, $reply ) = @_;
 		 		
 		is( $reply => $message->{context}->{response}, $message->{context}->{name} );
 
 		$results++;
 		
 		if ( $results == scalar(@tests) ) {
 		
 			$poe_kernel->stop;
 		
 		}
 
	}

1;