=head1 NAME

Infobot::Plugin::Conduit::IRC - Connect to IRC

=head1 DESCRIPTION

Simple wrapper around L<POE::Component::IRC> to allow connections to
IRC networks.

=head1 CONFIGURATION EXAMPLE

 conduit:
    'Connection to MagNET':
      class : Infobot::Plugin::Conduit::IRC
      extras:
          server   : cou.ch
          nick     : infobot2
          port     : 6667
          ircname  : sheriff's infobot replacement
          channels :
              '#perl':
                  addressing : 1
          ignore   :
              - 'purl.*'
              - 'buubot.*'
              - 'dipsy.*'
              - 'CPAN.*'

=head1 CONFIGURATION OPTIONS

=head2 server

The hostname or IP address of the target server

=head2 port

The TCP port to connect to - defaults to 6667

=head2 ircname

The name that comes up when someone performs a /whois on your Infobot

=head2 nick

The nick your Infobot should attempt to use

=head2 ignore

A YAML array of regular expressions - messages from nicknames
that match these will be ignored

=head2 channels

A YAML hash containing channel names, and whether or not addressing
is optional in them - that is, does the bot need to be spoken to
in order to reply?

=cut

package Infobot::Plugin::Conduit::IRC;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Conduit::Base));
	
	use POE;

	our @required_modules = qw( 
		Infobot::Message
		POE::Component::IRC 
		POE::Component::IRC::Plugin::Connector 
	);

# Start-up

	sub init {

		my $self = shift;
		my $name = shift;

		$self->set_name( $name );

	# Compile our ignore list early...	

		my $ignore_regex = '';

		$ignore_regex = '^(' . ( join '|', @{ $self->{config}->{ignore} } ) . ')$' if ref( $self->{config}->{ignore} );
		$ignore_regex = qr/$ignore_regex/o;
		$self->log( 8, "Ignore regex is $ignore_regex" );
		$self->{config}->{ignore_regex} = $ignore_regex;

	# Spawn the session

		my $irc = POE::Component::IRC->spawn(
			nick    => $self->{config}->{nick},
			server  => $self->{config}->{server},
			port    => $self->{config}->{port} || 6667,
			ircname => $self->{config}->{ircname},
		) or die $!;

		POE::Session->create(
			object_states => [ $self => [ qw(_start irc_ctcp_action irc_ctcp_ping irc_ctcp_version irc_msg irc_001 irc_public _default )  ] ],
			heap => { irc => $irc },
		);

	}

# List any IRC messages we get for which there's no other handler

	sub _default {

		my ($self, $event, $args) = @_[OBJECT, ARG0 .. $#_];

		my @output = ( "$event: " );

		foreach my $arg ( @$args ) {

			if ( ref($arg) eq 'ARRAY' ) {
				push( @output, "[" . join(" ,", @$arg ) . "]" );
			} else {
				push ( @output, "'$arg'" );
			}

		}	

		$self->log(9, ( join ' ', @output ) );

	}

	sub _start {
		
		my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $heap->{irc}->yield( register => 'all' );

    $heap->{connector} = POE::Component::IRC::Plugin::Connector->new();

    $heap->{irc}->plugin_add( 'Connector' => $heap->{connector} );

    $heap->{irc}->yield ( connect => { } );

    undef;

	}

	sub irc_001 {
	
		my ( $kernel, $sender, $self ) = @_[ KERNEL, SENDER, OBJECT ];

		$kernel->post( $sender => join => $_ ) for keys %{ ${self}->{config}->{channels} };

		undef;
	
	}

	sub irc_ctcp_version {

		my ( $kernel, $heap, $sender, $who, $what ) = @_[ KERNEL, HEAP, SENDER, ARG0, ARG2 ];

		$who =~ s/^(.+?)!.+/$1/;

		$kernel->post( $sender => ctcpreply => $who, "VERSION Infobot v1.0");

	}

	sub irc_ctcp_ping { 
	
		my ( $kernel, $heap, $sender, $who, $what ) = @_[ KERNEL, HEAP, SENDER, ARG0, ARG2 ];	
	
		$who =~ s/^(.+?)!.+/$1/;

		$kernel->post( $sender => ctcpreply => $who, 'PING ' . $what );
		
	}

	sub irc_public { &incoming }
	sub irc_msg    { &incoming }
	sub irc_ctcp_action { &incoming }

	sub incoming {

		my ( $kernel, $self, $sender, $who, $where, $what ) = @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1, ARG2 ];

	# Some people we ignore...

		if ( $who =~ $self->{config}->{ignore_regex} ) {

			$self->log( 8, "$who is ignored." );
			return 1;

		}

	# Strip control characters
		
		if ( $what eq 'exittest' ) { exit }

		my $original = $what;
		$what =~ s/[\cA-\c_]//ig;
	
	# Get the user's nick

		$who =~ s/^(.+?)!.+/$1/;

	# Are we on a channel?

		$where = $where->[0];
		my $public = ( $where =~ m/^([&#])/g );

		my $printable;

	# Log if needs be...

		if ( $public ) {

			$self->{log}->{$where} = [] unless $self->{log}->{$where};
			
			push( @{ $self->{log}->{$where} }, "<$who> $what" );
			while ( scalar @{ $self->{log}->{$where} } > 200 ) {

				shift( @{ $self->{log}->{$where} } );

			}
			
			$printable = "[$where/$who] $what"; 
			
		}	else {

			$printable = "[priv/$who] $what";

		}

	#	Are we being addressed?

		my $addressed = 0;

		my $self_nick = $self->{config}->{nick};

		if ( 
			( $what =~ s/^\s*$self_nick\s*([\,\:\> ]+) *//i ) || 		
			( $what =~ s/^\s*$self_nick\s*([\,\:\> ]+)\s*(?!is )//i ) ||
			( $what =~ s/, ?$self_nick(\W*)$//i )
		) {

			$addressed = 1;

		}
	
	# Force addressing if we're private

		$addressed = 1 if !$public;

	# Process the message

		my $message = Infobot::Message->new();

		my $addressing = 0;

		if ( $public ) {

			$addressing = $self->{config}->{channels}->{$where}->{addressing};

		}

		$message->init(
		
			conduit => $self,
			context => { location => $where, sender => $sender, addressing => $addressing },
			name    => $who,
			nick    => $self->{config}->{nick},
			message => $what,
			public  => $public,
			addressed => $addressed,
			printable => $printable,
		
		) or die ( $message->error );

	# Give to the pipeline
		
		$self->pipeline($message);

	}

	sub say {

	my $self    = shift;
	my $message = shift;

	my $reply = shift;

# Addressing checking...

	$self->log( 9, 'Was I addressed? [ ' . $message->addressed . ']' );
	$self->log( 9, 'Is addressing on? [' . $message->context->{addressing} . "]" );

	if ( $message->context->{addressing} && !$message->addressed ) {
	
		$self->log( 8, "Addressing is on and I wasn't addressed" );
		$self->log( 8, $reply );
		return "[Nothing. We weren't addressed]";
		
	}

	if ( $message->public ) {

		$poe_kernel->post( $message->context->{sender}, privmsg => $message->context->{location}, $reply );
		return "[" . $message->context->{location} . "/" . $message->name . "] $reply";

	} else {

		$poe_kernel->post( $message->context->{sender}, privmsg => $message->name, $reply );
		return "[priv/" . $message->name . "] $reply";		

	}

}


1;	
