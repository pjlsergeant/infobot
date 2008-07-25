
=head1 NAME

Infobot::Log - Log multiplexer

=head1 SYNOPSIS

 Infobot::Log->register( YourLoggingModule->new() );
 
 Infobot::Base->Log( 5, 'whatever' );

=head1 Log levels

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

=head1 METHODS

=cut

# Log multiplexer...

package Infobot::Log;

	use strict;
	use warnings;

	use base (qw(Infobot::Service));

	our $name = 'log';

=head2 init

Makes sure we have a holder for our log objects to go in

=cut

	sub init {

		my $self = shift;
		$self->{outputs} = [];

	}

=head2 register

Add a new log object to our multiplex

=cut

	sub register {

		my $self = shift;
		my $log  = shift;

		push( @{ $self->{outputs} }, $log );

		return 1;

	}

=head2 write

Write a line to our log objects. This should almost always be called via
Infobot::Base->log.

=cut

	sub write {

		my $self      = shift;
		my $package   = shift;

		if ( ref($self->{outputs}) && @{ $self->{outputs} } ) {

			for my $log ( @{ $self->{outputs} } ) {

				$log->write( $package, @_ );
			
			}
			
			return 1;

		} else {

			unless ( $ENV{'INFOBOT_NO_DEFAULT_LOG'} ) {

				print STDERR ( $package . ':' . $_[1] ) . "\n";
				return undef;

			}

		}

	}

1;
