package t::lib::HelpTestQuery;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base));

	our %help = (
	
		foo => 'bar',
	
		helptest => {
		
			foo => 'bar',
			foo1 => { '_' => 'foo1 stuff', foo12 => 'bar12', foo13 => 'bar13' },
			foo2 => { foo21 => 'foo21', foo22 => 'foo22' },
		
		}
	
	);
	
	sub process { return 0 }

1;

		