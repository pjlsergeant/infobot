
package t::lib::Conduit;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Conduit::Base));
	use POE;

	sub init {

		my $self = shift;

		my $session = POE::Session->create(

			args => [ $self ],
			object_states => [
				$self => [qw( _start input )],
			],
			heap => { self => $self }
		
		);	
			
		$self->stash( 'test_conduit', $session );

	}

sub _start {

	my ($heap, $session) = @_[ HEAP, SESSION ];

	my $self = $heap->{self};

	while ( my $message = $self->get_message ) {

		$poe_kernel->post( $session => input => $message );

	}

}

sub say {

	my $self = shift;
	my $message = shift;
	my $reply = shift;

	my $callback = $message->context->{callback};
	
	$callback->( $message, $reply );

	return 1;

}

sub input {

	my ( $self, $input ) = @_[ OBJECT, ARG0 ];
	$self->pipeline($input);
	return 1;

}

1;	
