
package t::conduit001;

	use strict;
	use warnings;

	use Infobot::Message;
	use base qw( t::lib::Conduit );	

	my @data = ('hi');

	sub process {
		my $self = shift;
		my $message = shift;

		die( $message );
	}

	sub get_message {

		my $self = shift;
			
		my $data = pop( @data );

		my $message = Infobot::Message->new();

		if ( $data ) {	

			$message->init(
		
				name      => 'testuser',
				nick      => 'testbot',
				message   => $data,
				printable => $data,
				conduit   => $self,
				addressed => 0,
				context   => { callback => sub { $self->process(shift()) } },
				public    => 0,	

			);

			return $message;

		} else {

			return undef;

		}

	}

