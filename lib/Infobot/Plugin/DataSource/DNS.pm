 package Infobot::Plugin::DataSource::DNS;

   use strict;
	 use warnings;

 # Import new() and a useful load()

   use base qw( Infobot::Plugin::DataSource::Base ); # Specialised subclass of Infobot::Base

 # Modules we'll be needing

   our @required_modules = qw( POE::Component::Client::DNS );

 # Load POE explicitly

   use POE;

	sub init {

		my $self = shift;
		my $name = shift;

		$self->set_name( $name );
	
		POE::Component::Client::DNS->spawn( Alias => $self->alias );

	# Put ourselves in a sensible place in the stash...

		$self->stash( $self->alias => $self );

		return 1; 

	}
   
1;
