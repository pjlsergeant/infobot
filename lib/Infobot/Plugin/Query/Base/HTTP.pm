package Infobot::Plugin::Query::Base::HTTP;

	use strict;
	use warnings;

	use POE;

	use base qw( Infobot::Plugin::Query::Base );

	sub init {

		my $self = shift;
		my $name = shift;

		$self->set_name( $name );

		$self->{session} = POE::Session->create(
			object_states => [ $self => [qw( _stop _start _base_request _base_response )] ],
		)->ID;

	}

	sub _stop { }

	sub request {

		my $self    = shift;
		my $message = shift;
		my $request = shift;

		die "[$self->{config}->{'http_client'}] not found in the stash" unless $self->stash( $self->{config}->{'http_client'} );
		$self->log(9, "Posting a _base_request item to session " . $self->{session} );
		$self->log(9, "[$self->{session}] resolves to [" . $poe_kernel->_resolve_session( $self->{session} ) . ']' );

		$poe_kernel->post( 
			
			$self->{session} => '_base_request',
			[
				$self->stash( $self->{config}->{'http_client'} )->alias, 
				'request',
				'_base_response',
				$request, 
				$message
			]
		
		);

	}

	sub _start {

		my ( $self, $session ) = @_[ OBJECT, SESSION ];

		$poe_kernel->alias_set( $self->{name} . \$self );

		return 1;

	}

	sub _base_request {

		my ($self, $kernel) = @_[ OBJECT, KERNEL ];

		$self->log( 9, "_base_request called - calling $_[ARG0]->[1] on $_[ARG0]->[0]" );
		$self->log( 9, '[' . $_[ARG0]->[0] . '] resolves to [' . $poe_kernel->_resolve_session( $_[ARG0]->[0] ) . ']' );
		#$self->log( 9, "ARG$_ = " . $_[ARG0]->[$_]) for ( 0 .. 5);
		
		$kernel->post( @{ $_[ARG0] } );

	}

	sub _base_response {

		my ( $self, $request_object, $response_object ) = @_[ OBJECT, ARG0, ARG1 ];

		my $message  = $request_object->[1];
		my $response = $response_object->[0];	

		$self->response( $message , $response );

	}

1;
