
=head1 NAME

Infobot::Plugin::Conduit::Base - Base class for conduits

=head1 OVERVIEW

A conduit is a pathway through which messages can be sent to and retrieved
from the Infobot. For example, the IRC conduit connects to an IRC network,
and optionally a channel, and sits receiving and responding to commands. The
Tk conduit creates a graphical window on your computer in to which you can
issue commands.

More specifically, a conduit is a class that injects L<Infobot::Message>
objects in to the L<Infobot::Pipeline>, and provides a C<say()> method to
receive the replies.

Most real world conduits will use the L<POE> event loop to poll their data
sources. There's no restriction on the number of different conduits an Infobot
instance can have - your Infobot could connect to IRC and have a Tk interface,
and make use of any other available interfaces.

This module provides a base-class for writing your own conduits. You can find
a tutorial on creating your own conduit at L<docs/how_to_write_a_conduit.pm>.

=head1 METHODS

=cut

package Infobot::Plugin::Conduit::Base;

	use strict;
	use warnings;

	use base (qw(Infobot::Base));
	use Infobot::Message;

=head2 set_name

As with C<Infobot::Base>, but explicitly sets category to C<conduit>.

=cut

	sub set_name {

		my $self = shift;
		my $name = shift;

		return $self->SUPER::set_name( 'conduit', $name );
		
	}

=head2 pipeline

Helper method around calling C<$self->stash('pipeline')->process( $message );>

=cut

	sub pipeline {

		my $self = shift;
		my $message = shift;

		return $self->stash('pipeline')->process( $message );

	}

=head2 say

Virtual method. Should accept a copy of the original Message object, and
a string containing the suggested reply.

=cut

	sub say { 1 }

=head1 SEE ALSO

The included tutorial on writing your own conduit

=cut

1;	
	
