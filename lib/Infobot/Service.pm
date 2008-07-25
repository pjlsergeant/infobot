
=head1 NAME

Infobot::Service - Base class for core services

=head1 SYNOPSIS

 package Infobot::SomethingImportant;

  our $name = 'impo';

Is a L<Infobot::Base>.

=head1 METHODS

=head2 key 

Returns the value of the package variable 'name'. Used for
setting internal aliases in core services.

=cut

package Infobot::Service;

	use strict;
	no strict 'refs';
	use warnings;

	use base qw( Infobot::Base );

	our $name = 'Service';

	sub key {

		my $self = shift;
		my $package = $self->_get_package_name; 
		
		my $keyname = $package . '::name';
		
		return $$keyname;

	}
	
