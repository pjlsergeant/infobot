
=head1 NAME

Infobot::Plugin::Log::Base - Logger base class

=head1 LOG LEVELS

0. Fatal errors
1. Critical errors
2. Non-critical warnings and complaints
3. Plugin tick over - any plugins that are hit say they're hit 
4. 
5. All messages incoming - whether addressed or not - [default]
6. Plugin important - plugins describe what they're doing
7. Plugin detailed - plugins describe in detail what they're doing 
8. All incoming events - _default et al
9. All possible information

=cut

package Infobot::Plugin::Log::Base;

	use strict;
	use warnings;

	use base (qw(Infobot::Base));

=head2 init

Calls C<set_name>, and C<register>

=cut

	sub init {

		my $self  = shift;
		my $name = shift;

		$self->log(5, "Initializing log: " . ref($self ) );

		$self->set_name( $name );
		$self->register();

		return 1;
		
	}

=head2 set_name

Safetly stashes the log level and reads in values from the config file.

=cut

	sub set_name {

		my $self = shift;
		my $name = shift;

		$self->{_level} = $self->stash('config')->{log}->{$name}->{level};

		return $self->SUPER::set_name( 'log', $name );

	}

=head2 register

Adds the log to the multiplexer's store

=cut

	sub register {

		my $self = shift;

		return $self->stash('log')->register( $self );

	}

=head2 write

Checks that the log level is appropriate, and if it is, passes the message
through to the C<output> method.

=cut

	sub write {

		my $self    = shift;
		my $package = shift;
		my $level   = shift;
		
		my $loglevel = $self->level || 0;
	
		return unless $level <= $loglevel;

		my $message = shift;

		return $self->output( $level, $package, $message );

	}

=head2 level

Accessor to logging level

=cut

	sub level {

		my $self = shift;
		return $self->{_level};
	
	}

1;
