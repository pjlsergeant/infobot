=head1 NAME

Infobot::Pipeline - Main application pipeline

=head1 SYNOPSIS

	$self->stash('pipeline')->add( 10, Plugin->new );
	
	$self->stash('pipeline')->process( $message_object );

=head1 METHODS

=cut

package Infobot::Pipeline;

	use strict;
	use warnings;

	our $name = 'pipeline';

	use base (qw(Infobot::Service));

=head2 init

Basic setup

=cut

	sub init {

		my $self = shift;
		$self->{pipeline} = [];
		return 1;

	}

=head2 add

Accepts a priority, and an object. Higher the priority, the earlier the C<process>
method of your object is called. It should return 1 to derail the pipeline (and
basically say "I'm handling this, and I alone am handling this!"), or 0 to keep
trying the other things in the pipeline.

=cut

	sub add {

		my $self = shift;
		my $priority = shift;
		my $package  = shift;

		@{ $self->{pipeline} } = sort {

			$b->[0] <=> $a->[0]
		
		} @{ $self->{pipeline} }, [ $priority, $package ];

	}

=head2 process

Accepts a message object, and feeds it to each of the query objects, until one turns
true, or until we've tried them all.

=cut

	sub process {

		my $self = shift;
		my $message = shift;

		for ( @{ $self->{pipeline} } ) {

			if ( $_->[1]->process( $message ) ) { last }

		}

		return 1;

	}

1;

