
package t::lib::CatchAllQuery;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base));
	
	sub process {
		
		my $self = shift;
		my $message = shift;
		$message->say('not caught');
		return 1;
		
	}

1;
