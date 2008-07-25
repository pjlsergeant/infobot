=head1 NAME

Infobot::Plugin::Log::ANSIColor - Relay and colour logging messages to STDOUT

=head1 DESCRIPTION

Output logging messages, coloured by logging level, to STDOUT

=head1 CONFIGURATION EXAMPLE

 log:
 ...
   'Pretty Terminal Colours':
     class : Infobot::Plugin::Log::ANSIColor
     level : 9 
     extras:
       colours:
         levels:
           1: bold red
           3: bold yellow
           5: bold white
         default: white
         package: cyan
         divider: bold white

=head1 CONFIGURATION OPTIONS

=head2 level

The logging level at and above which to record. 9 is the
lowest, 1 is the highest. See L<Infobot::Log::Base> for
more details.

=head2 extras/colours/levels

The colour (according to those available from L<Term::ANSIColor>)
to use for each logging level. Note that these expand upward -
in the above example, 5 and 4 are bold white, 3 and 2 are bold
yellow, and 1 is bold red, while 9-5 are the default colour, white.

=head2 extras/colours/default

=head2 extras/colours/package

=head2 extras/colours/divider

The default logging colour, the package name colour, and the
divider colour, respectively.

=head1 AUTHOR

Pete Sergeant -- C<pete@clueball.com>

=head1 LICENSE

Copyright B<Pete Sergeant>.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

 package Infobot::Plugin::Log::ANSIColor;

   use strict;
	 use warnings;

 # Import new() and a useful load()

   use base qw( Infobot::Plugin::Log::Base ); # Specialised subclass of Infobot::Base

 # Modules we'll be needing

   our @required_modules = qw( Term::ANSIColor );

	sub init {

		my $self  = shift;
		my $name = shift;

		$self->log(5, "Initializing log: " . ref($self ) );

		$self->set_name( $name );
	
	# Set up our pretty colours
	
		my $current_colour = $self->{config}->{colours}->{default} || 'white';
	
		for (0 .. 8 ) {
		
			my $level = 9 - $_;
		
			if ( $self->{config}->{colours}->{levels}->{$level} ) {
			
				$current_colour = $self->{config}->{colours}->{levels}->{$level};
			
			}
		
			$self->{colour}->{levels}->[ $level ] = Term::ANSIColor::color( $current_colour );
		
		}

	# Set up the helper colours
	
		my $package_colour = $self->{config}->{colours}->{'package'} || 'white';
		$self->{colour}->{package} = Term::ANSIColor::color( $package_colour );
		
		my $divider_colour =  $self->{config}->{colours}->{divider} || 'white';
		$self->{colour}->{divider} = Term::ANSIColor::color( $divider_colour );

		$self->{colour}->{reset} = Term::ANSIColor::color( 'reset' );

	# Register the logger as ready to use
		
		$self->register();

		return 1;
		
	}	

	sub output {
	
		my $self = shift;
		
		my $level   = shift;
		my $package = shift;
		my $message = shift;	

	# Nasty hack to truncate the package name

		$package =~ s/..+(......)$/<$1/g; # hee!

	# Now print out the message
	
		print
			
			$self->{colour}->{divider} . '[' .
			$self->{colour}->{reset  } .
			
			$self->{colour}->{package} . $package .
			$self->{colour}->{reset  } .			
			
			$self->{colour}->{divider} . ']' .
			$self->{colour}->{reset  } .	' ' .	

			$self->{colour}->{levels}->[ $level ] . "$level: $message" .
			$self->{colour}->{reset} . "\n";

		return 1;

	}

1;
