
package t::lib::FakeDBIxClass;

	sub new {

		my $class = shift;
		return bless {}, $class;

	}

package Infobot::Plugin::Query::Client::DBIxClass;

	use base qw/Infobot::Plugin::Query::Client::Base/; 

	sub load { 1 };
	sub init { 1 };

package Infobot::Plugin::Query::Base::DBIxClass;

	use base qw( Infobot::Plugin::Query::Base );

  sub init { 1 };

	sub dbi { return t::lib::FakeDBIxClass->new(); };

1;
