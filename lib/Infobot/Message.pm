
=head1 NAME

Infobot::Message - Encapsulate incoming queries

=head1 SYNOPSIS

 use Infobot::Message;

 my $message = Infobot::Message->new();

 # These all become available as accessors

 $message->init(
		addressed => 1,
		conduit   => $irc_conduit,
		context   => { channel => '#perl' },
		name      => 'sheriff',
		message   => 'Hey purl!',
		public    => 1,
		nick      => 'purl',
		printable => '[#perl/sheriff] purl: Hey purl!',
 );

 my $id = $message->id;

 $message->say( "Right back at ya, ", $message->name );

 $self->stash('pipeline')->process( $message );

=cut 

package Infobot::Message;

	use strict;
	use warnings;

	use base ( qw( Infobot::Base ) );

# We want a unified interface, and don't want people messing around
# in our object itself, so produce accessors to all the bits people
# might need.

	my @required_attributes = (
	
		'id',        # Our unique-ish base35(!) message id
		'addressed', # If we were specifically being spoken to
		'conduit',   # A copy of the conduit object we were created frmo
		'context',   # Conduit-specific data store
		'message',   # The text of the message sent to us
		'name',      # The username of the person addressing us
		'nick',      # Our name
		'printable', # A loggable, text-representation of the message and info
		'public',    # If the message was said publically

	);

=head1 ATTRIBUTES

These are the attributes a conduit must pass to init, and which 
other plugins that use L<Infobot::Message> can rely on being set.

=head2 addressed

If we were specifically spoken to by the user. In situations where
the bot is the only possible recipient (say a console conduit), then
this should be set to one regardless.

=head2 conduit

The conduit object which created the message.

=head2 context

Any conduit-specific information (hashref). This should not be relied upon
in any place other than the conduit itself - the default for any
value you put in should be 0/undef. So, the IRC conduit uses an
'addressing' value in here, which specifies if the current channel
requires addressing (set up in the config). It defaults to 0, so
any plugin that doesn't deal with IRC doesn't need to care about
it.

C<channel> and C<addressing> are the only keys that are currently
suggested for use outside of the conduit itself, but PLEASE programme
defensively here, and don't rely on ANY value being here...

=head2 message 

The text of the message itself

=head2 name 

The name (human-readable) of the user talking to us

=head2 nick

Our name - please default to the value of C<$self->stash('config')->{alias}>
if your conduit doesn't have this concept.

=head2 printable

A nice, loggable text representation of the message text plus some
context - for IRC, we use channel name and nick and the message,
nicely formatted in one string.

=head2 public

If the comment was made in a 'public' place (IRC channel, for example).

=cut	

	Infobot::Message->mk_ro_accessors( @required_attributes );

=head1 METHODS

=head2 id

Returns a unique(ish) ID for the message

=head2 ATTRIBUTES...

All the above attributes are also read-only accessors...

=head2 init

Accepts a list of the attributes as described above. Returns 1
on success.

=cut

	sub init {

		my $self = shift;
		my %options = @_;

		$options{id} = $self->_counter();

	# Copy the options over to our object's data store, checking for
	# defined-ness en-route.

		for my $attribute ( @required_attributes ) {

			unless ( defined( $options{$attribute} ) ) {

				$self->log( 2, "Message creation without [$attribute] defined fails" );
				return undef;
	
			}
			
			$self->{$attribute} = $options{$attribute};

		}

		$self->log( 5, "'" . $self->id . "' " . $self->name . ' -> ' . $self->printable );

		return 1;

	}

=head2 say

Prints the message in the appropriate conduit, having checked addressing
and done some logging

=cut

	sub say {

		my $self = shift;

		my $message = shift;

	# Deal with addressing

		unless ( $self->addressed || !$self->context->{addressing} ) { return 1 }

		my $output = $self->conduit->say( $self, $message ); 

		if ( $output ) {
			$self->log( 5, "'" . $self->id . "' " . $self->name . ' <- ' . $output ); 
		} else {
			return undef;
		}

		return 1;

	}

# This is /not/ Base64. It's Base 35!  This is so that you have easily
# readable/grokkable identifiers for messages, where each digit counts
# up from 0. Also, this pads. We never use a capital O as these are
# meant to be for HUMAN EYES, and it could get confused with a 0.		

	my @counter_digits = (0 .. 9, 'a' .. 'z', 'A' .. 'N', 'P' .. 'Z'); 
	my $counter_base   = scalar( @counter_digits );
	
	sub _counter { 

		my $self = shift;

		my $number = ( $self->stash('message_counter') || 0 ) + 1;
		$self->stash( message_counter => $number );
		
		my $digits = '';
		
		while( $number > 0 ) {

			my $whole = int( $number / $counter_base );
			my $remainder = ($number % $counter_base) || 0;
		
			$digits = $counter_digits[ $remainder ] . $digits;

			$number = $whole;

		}

		return ( '0' x ( 3 - length( $digits ) ) . $digits );
		
	};
	
1;	
