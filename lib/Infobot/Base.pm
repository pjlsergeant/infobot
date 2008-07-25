
=head1 NAME

Infobot::Base - Useful methods for Infobot modules

=head1 SYNOPSIS

 package Infobot::YourModule;

 	use base qw( Infobot::Base );

	our @required_modules = qw( Your::Deps::Here );

 package main;
 
	die unless Infobot::YourModule->load();
 
  my $object = Infobot::YourModule->new();	

=head1 DESCRIPTION

This module provides some useful tools that are required by most
of the other Infobot components.

=cut

package Infobot::Base;

	use strict;
	use warnings;
	
	use UNIVERSAL::require;

	no strict 'refs';

=head1 METHODS

=head2 mk_accessor et al

Inherits from L<Class::Accessor>.

=cut

	use base qw(Class::Accessor);
	
	our $stash = {};	

=head2 new

This application has been designed with the idea that a new
method should be as lightweight as possible, with all
initialisation done explicitly with an C<init()> method.

This implementation of C<new()> is about as simple as it gets -
will return a hashref blessed in to your class.

=cut

	sub new {

		my $package = shift;

		return bless {}, $package;

	}

=head2 load

C<infobot> calls the C<load()> method on all packages it
would like to use. This allows a module to check for module
dependencies, and anything else it would like. It should
return 1 if the plugin can be used, and 0 if not.

The default C<load> module here simply returns the result
of an empty call to C<require_modules> (so allows you to
set module dependencies in C<@modules_dependencies>.

=cut

	sub load { my $self = shift; return $self->require_modules }

=head2 require_modules

Accepts a list of modules, and attempts to load them using 
L<UNIVERSAL::Require>. Returns 1 if all load, 0 if any fail.
This method will short-circuit on the first error, and will
write to the application L<log|Infobot::Log> multiplexer
(priority 2).

If you don't provide a list of modules, the existance of
C<@required_modules> is checked for in your package, and
used.

=head2 require_base

Accepts a single module, and attempts to require it using
C<require_modules>). Adds it to the calling package's C<ISA>.

=cut

	sub require_base {

		my $self = shift;
		my $base = shift;

		return 0 unless $self->require_modules( $base );

		my $package = $self->_get_package_name . '::ISA';
		
		push( @$package, $base );

		return 1;

	}

	sub require_modules {

		my $self = shift;

		my @modules = @_;

		unless ( @modules ) {

			my $package = $self->_get_package_name(); 
			my $array_name = $package . '::required_modules';
			if ( @$array_name ) {

				@modules = @$array_name;

			}

		}
		
		for my $module ( @modules ) {

			unless ( $module->require ) {
					
				$self->log( 2, "$module can't be loaded: $@" );
				return undef;
									
			}
			
		}
	
		return 1;
	
	}

=head2 log

Shortcut to C<Infobot::Stash->new->log()>, the log multiplexer
object from C<Infobot::Log>.

=cut

	sub _get_package_name {

		my $self = shift;

		my $name = ref( $self );
		$name = $self unless $name;

		return $name;

	}

	sub log {

		my $self = shift;
		my $name = $self->_get_package_name; 

		$stash->{log}->write( $name, @_ );

	}

=head2 set_name

Accepts an object type (such as 'log', 'conduit', or 'query'), and
a name, sets C<$self->{name}> to that name, and sets C<<$self->{config}>>
to C<<$stash->{config}->{$type}->{$name}->{extras}>>. 

=cut

	sub set_name {

		my $self = shift;
		my $type = shift;
		my $name = shift;
	   
		$self->{name} = $name;
		$self->{config} = $stash->{config}->{$type}->{$name}->{extras};

		return 1;
  
	}

=head2 stash

Application-wide stash. Accepts either a key (for lookups) or
a key + value (for storage).

=cut

	sub stash {

		my $self = shift;

		my ( $key, $value ) = @_;

		if ( defined( $value ) ) {
			
			$stash->{$key} = $value;
			return 1;
		
		} else {

			if ( $key ) {

				return $stash->{$key};

			} else {
			
				return undef;
			
			}

		}

	}

1;
