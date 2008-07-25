package Infobot::Plugin::Query::Base::DBIxClass;

	use strict;
	use warnings;

	use base qw( Infobot::Plugin::Query::Base );

  sub init {

    my $self = shift;
    my $name = shift;

 	# Set our name, and grab in the values from the config file

		$self->set_name( $name );

	# Check the appropriate table exists...

		my $dbh = $self->stash( $self->{config}->{db} );
		unless ( $dbh ) { die "Where did my DB go? \$self->{config}->{db}" } 
			
		my $table_name = $self->tablename;
		my $resultset = eval { $dbh->resultset( $table_name ) };

		unless ( $resultset ) {

				$self->log( 2, "Table $table_name not found" );
				$self->log( 2, $@ );
				return 0;

		}

    return 1;

  }

	sub tablename { my $self = shift; return ucfirst( $self->{config}->{table} ) }

	sub dbi { 
		
		my $self = shift; 
		my $dbh = $self->stash( $self->{config}->{db} );
		
		return $dbh->resultset( $self->tablename );

	}
1;
