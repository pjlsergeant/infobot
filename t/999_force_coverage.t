
	use Test::More tests => 1;

	use Infobot;
	use Infobot::Base;
	use Infobot::Config;
	use Infobot::Log;
	use Infobot::Message;
	use Infobot::Pipeline;
	use Infobot::Plugin::Conduit::Base;
	use Infobot::Plugin::Conduit::IRC;
	use Infobot::Plugin::Conduit::Telnet;
	use Infobot::Plugin::Log::Base;
	use Infobot::Plugin::Log::ANSIColor;
	use Infobot::Plugin::Log::STDERR;
	use Infobot::Plugin::DataSource::Base;
	use Infobot::Plugin::DataSource::HTTP;
	use Infobot::Plugin::DataSource::DBIxClass;
	use Infobot::Plugin::Query::Base;
	use Infobot::Plugin::Query::RSS;
	use Infobot::Plugin::Query::GoogleDefine;
	use Infobot::Plugin::Query::Rot13;
	use Infobot::Plugin::Query::Factoids;
	use Infobot::Plugin::Query::Help;
	use Infobot::Plugin::Query::Base::HTTP;
	use Infobot::Plugin::Query::Base::DBIxClass;
	use Infobot::Service;

	ok(1, "Placeholder");

