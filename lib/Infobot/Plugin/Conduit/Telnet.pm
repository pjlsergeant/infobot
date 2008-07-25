=head1 NAME

Infobot::Plugin::Conduit::Telnet - Telnet server interface

=head1 DESCRIPTION

Starts a simple Telnet server on the specified port for
communicating with Infobot.

=head1 CONFIGURATION EXAMPLE

 conduit:
    'Simple Telnet Interface':
      class : Infobot::Plugin::Conduit::Telnet
      extras:
          port: 7654

=head1 CONFIGURATION OPTIONS

=head2 port

TCP port to listen on

=cut

# The creation of this conduit is explained in
# docs/how_to_write_a_conduit.pm

 package Infobot::Plugin::Conduit::Telnet;

   use strict;
	 use warnings;

 # Import new() and a useful load()

   use base qw( Infobot::Plugin::Conduit::Base ); # Specialised subclass of Infobot::Base

 # Modules we'll be needing

   our @required_modules = qw( POE::Component::Server::TCP );

 # Load POE explicitly

   use POE;

 # Setup
 sub init {
 
 	my $self = shift;
 	my $name = shift;
 	
 	$self->set_name( $name );
 	
 	$self->log( 5, "Starting a TCP server on port $self->{config}->{port}" );

	POE::Session->create(
 
 		inline_states => { _start => sub { $_[KERNEL]->alias_set( $name ) } },
 		object_states => [ $self  => [qw( user_input )] ],
 	
	);
 
	POE::Component::Server::TCP->new(
	
		Port => $self->{config}->{port},

		ClientInput => sub {
			my ( $heap, $kernel, $input ) = @_[ HEAP, KERNEL, ARG0 ];
			$kernel->post( $name => user_input => ( $heap->{client}, $input ) )
		},

 	);

	return 1;

 }
 
 sub user_input {

	my ( $self, $client, $input ) = @_[ OBJECT, ARG0, ARG1 ];
	my $message = Infobot::Message->new();

	$message->init(
		
		conduit   => $self,
		context   => { client => $client },
		name      => 'Telnet User',
		nick      => $self->stash('config')->{'alias'},
		message   => $input,
		public    => 0,
		addressed => 1,
		printable => $input,
		
	) or die ( $message->error );

 # Give to the pipeline
		
		$self->pipeline($message);

 }
 
 sub say {
 
	my ( $self, $message, $reply ) = @_;
 
	$message->{context}->{client}->put( $reply );
 
 	return $reply;
 
 }

1;