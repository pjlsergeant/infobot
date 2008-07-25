
=head1 NAME

Infobot::Config - Read in a YAML config file

=head1 SYNOPSIS

  use Infobot::Config;
  
  my $object = Infobot::Config->new();
  $object->stash( config_file => '/tmp/whatever' );
  $object->init;
  
  print $object->stash( config )->{config values};

=cut

package Infobot::Config;

	use strict;
	use warnings;

	our $name = 'config';

	use base (qw(Infobot::Service));
	use YAML::Syck;

=head1 METHODS

=head2 init

Searches the stash for a value called C<config_file>, and tries to load
a YAML file found there, placing if in C<stash( 'config' )>. Will cause
a fatal error if it fails at any point.

=cut

	sub init {

		my $self = shift;

		my $file = $self->stash('config_file');

		die "No filename placed in 'config_file' in the stash" unless $file;
		die "No file found for [$file]" unless -f $file;

		my $data = LoadFile( $file ); # Dies anyway if it's malformed

	# This is a little nasty, replace our entry in the stash with
	# our data (where it was $self)

		$self->stash( $name => $data );

		return 1;

	}
	
