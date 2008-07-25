
package t::lib::NullLog; 

	use strict;
	use warnings;

	use Test::More;
	use base (qw(Infobot::Plugin::Log::Base));

sub write {  1 }
#	sub write { my $message = $_[3]; diag( $message ) }
	
1;	
