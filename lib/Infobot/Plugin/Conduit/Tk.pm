=head1 NAME

Infobot::Plugin::Conduit::IRC - Very simple graphical interface

=head1 DESCRIPTION

Provides a very simple graphical interface

=head1 CONFIGURATION EXAMPLE

 conduit:
    'TK':
      class : Infobot::Plugin::Conduit::Tk

=head1 OVERVIEW

At this point in time, the Tk interface is provided more as a proof of concept
than as a serious attempt to write a graphical interface. It's ugly as hell,
a little bit unweildy, and not very user-friendly. As such, there are no
configuration options. Patches kindly welcomed.

=head1 USAGE INFORMATION

L<POE> requires that L<Tk> is loaded before POE itself in order to interact
properly with Tk, but this isn't easily achieved using our codebase. As a
result, if you're using the Tk conduit, you should load the module on the
command line:

 perl -MTk infobot infobot.conf

=cut

package Infobot::Plugin::Conduit::Tk;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Conduit::Base));

	BEGIN {
	
		die "You must load Tk from the command line to use the Tk conduit: 'perl -MTk infobot infobot.conf'" unless $INC{'Tk.pm'}
	
	}

	use POE;

	our @required_modules = qw( 
		Infobot::Message Tk::LabEntry
	);

	sub init {

		my $self = shift;
		my $name = shift;

		$self->set_name( $name );

		POE::Session->create(
			
			object_states => [ $self => [ qw( _start user_input ) ] ]

		);

	}
	
	
	sub _start {

		my ( $kernel, $session, $heap, $self ) = @_[ KERNEL, SESSION, HEAP, OBJECT ];

	# This string gets tied to the input box

		my $string;
		$self->{stash}->{ui}->{inputBox} = \$string;

	# Create the input box itself

		my $entry = $poe_main_window->LabEntry(
			-label => 'Say:',
			-width => 80,
			-labelPack => [qw/-side left -anchor w/],
			-textvariable => \$string,
		)->pack(qw/-padx 2 -side top/);

	# User and Infobot output goes in this part

		$self->{stash}->{ui}->{frame} =
			$poe_main_window->Scrolled(qw/Frame -width 600 -height 200 -scrollbars e/)->pack( -side => 'bottom' );

	# Make pressing return in the input box cause an event

		$entry->bind('<Return>' => $session->postback("user_input") );
	
	}
	
	sub user_input {

		my ( $kernel, $heap, $self ) = @_[ KERNEL, HEAP, OBJECT ];

	# Create and initialise the Infobot::Message object

		my $message = Infobot::Message->new();

		$message->init(
		
			conduit => $self,
			context => {},
			name    => $ENV{'USER'},
			nick    => 'infobot',
			message => ${$self->{stash}->{ui}->{inputBox}},
			public  => 0,
			addressed => 1,
			printable => ${$self->{stash}->{ui}->{inputBox}},
		
		) or die ( $message->error );

	# Update the output box, and clear the input box

		$self->add_text( 1, ${$self->{stash}->{ui}->{inputBox}} );
		${$self->{stash}->{ui}->{inputBox}} = '';

	# Give to the pipeline
		
		$self->pipeline($message);

	}

	sub add_text {
	
		my ( $self, $user, $text ) = @_;
		
		my $bg = 'Bisque';
		
		unless ( $user ) {
			$bg = 'LightGreen';
		}

	# Add a message to our output box
		
		my $tb = $self->{stash}->{ui}->{frame}->Label( -anchor => 'w', -background => $bg, -border => 1, -width => 80, -justify => 'left', -wraplength => 550, -text => $text )->pack( -side => 'bottom', -anchor => 'w', -pady => 1 );	
	
	}

	sub say {

		my $self    = shift;
		my $message = shift;

		my $reply = shift;

		$self->add_text( 0, $reply );

		return $reply;

	}

1;	
