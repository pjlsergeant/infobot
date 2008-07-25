
=head1 NAME

Infobot::Plugin::DataSource::DBIxClass - Simple reusable interface to DBIx::Class

=head1 DESCRIPTION

Stashes a L<DBIx::Class::Schema::Loader> object somewhere sensible for
easy connections to databases

=head1 CONFIGURATION EXAMPLE

 datasource:
 ...
    'DBIxClass':
        class : Infobot::Plugin::DataSource::DBIxClass
        alias : dbix
        extras:
           dsn  : dbi:SQLite:brains/factoids.db
           user : abc
           pass : cba

=head1 CONFIGURATION OPTIONS

=head2 alias

Where to stash this. As you can have connections to more than one
database, this is useful for differentiating.

=head2 extras

C<dsn>, C<user>, C<pass> as per database connections.

=head1 AUTHOR

Pete Sergeant -- C<pete@clueball.com>

=head1 LICENSE

Copyright B<Pete Sergeant>.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

package Infobot::Plugin::DataSource::DBIxClass;

	use base qw/Infobot::Plugin::DataSource::Base/; 

	sub load {
	
		my $self = shift;
		
		return $self->require_base( qw/DBIx::Class::Schema::Loader/ );	
		
	}
		
# Connect to the database...

	sub init {

		my $self   = shift;
		my $name   = shift;

		$self->set_name( $name );

	# Options for DBIx..Loader

		$self->loader_options(
			relationships => 1,
			constraint    => $self->{config}->{constraint},
			debug         => 0,
		);
	
		$self->log( 6, "Attempting connection to $self->{config}->{dsn}" );
		
		$self->connection(
			$self->{config}->{dsn},
			$self->{config}->{user},
			$self->{config}->{pass},
		);

	# Try to actually connect...

		$self->storage->ensure_connected();# Dies on failure 

	# Put ourselves in a sensible place in the stash...

		$self->stash( $self->alias => $self );

		return 1; 

	}


1;