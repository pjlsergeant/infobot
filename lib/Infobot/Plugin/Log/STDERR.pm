=head1 NAME

Infobot::Plugin::Log::STDERR - Relay logging messages to STDERR

=head1 DESCRIPTION

Simply outputs all logging messages, their originating package
and the log-level to STDERR

=head1 CONFIGURATION EXAMPLE

 log:
 ...
   'STDERR':
     class : Infobot::Plugin::Log::STDERR
     level : 9

=head1 CONFIGURATION OPTIONS

=head2 level

The logging level at and above which to record. 9 is the
lowest, 1 is the highest. See L<Infobot::Log::Base> for
more details.

=head1 AUTHOR

Pete Sergeant -- C<pete@clueball.com>

=head1 LICENSE

Copyright B<Pete Sergeant>.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

package Infobot::Plugin::Log::STDERR;

	use strict;
	use warnings;

	use base (qw(Infobot::Log));

	sub output {
	
		my $self = shift;
		
		my $level   = shift;
		my $package = shift;
		my $message = shift;	
		
		print STDERR "[$level] [$package] $message\n";

	}
	
1;

