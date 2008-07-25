
package Infobot::Plugin::Log::File;

	use strict;
	use warnings;

	our @required_modules = (qw(IO::File));
	
	use base (qw(Infobot::Plugin::Log::Base));

	my $fh;

	sub output {
	
		my $self = shift;
		
		my $level   = shift;
		my $package = shift;
		my $message = shift;	

		$self->_open_file unless ( $self->{filehandle} && -w $self->{filehandle} );
		$fh->print( "[$level] [$package] $message\n" ) || die $!;
		warn("Printing to $fh");
		
	}

	sub _open_file {

		my $self = shift;
		die "Can't log to a blank filename" unless $self->{config}->{filename};

		$fh = new IO::File;

		warn("Opening $self->{config}->{filename}");
		$fh->open(">> $self->{config}->{filename}" ) || die "[ $self->{config}->{filename} ] $!";
		$self->{filehandle} = $fh; # This line stops it working

	}
	
1;	
