=head1 NAME

Infobot::Plugin::DataSource::Base

=cut

package Infobot::Plugin::DataSource::Base;

	use strict;
	use warnings;

	use base (qw( Infobot::Plugin::Query::Base ));

	#sub load { 0 } # You definitely need to over-ride this with deps 

=head1 METHODS

=head2 set_name

Grabs the alias from the config, and puts it somewhere safe. Then calls
L<Infobot::Base>'s C<set_name> with C<datasource> as the category.

=cut

	sub set_name {

		my $self = shift;
		my $name = shift;

		$self->{_alias} = $self->stash('config')->{datasource}->{$name}->{alias};

		return $self->Infobot::Base::set_name( 'datasource', $name );

	}

=head2 alias

Read-only accessor for the client's alias.

=cut

	sub alias {

		my $self = shift;

		return $self->{_alias};
		
	}

1;
