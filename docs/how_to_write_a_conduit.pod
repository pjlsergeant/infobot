
=head1 NAME

How to write a conduit

=head1 INTRODUCTION

A conduit is a piece of code that provides an input/output mechanism
into Infobot. The most commonly used conduit connects to an IRC server,
but there's also one that creates a dedicated graphical interface.

More formally, a conduit creates L<Infobot::Message> objects, and
sends them to L<Infobot::Pipeline> for processing. Conduits should be
subclasses of L<Infobot::Conduit>.

This tutorial will show us how to build a simple conduit which a user
can Telnet to to communicate with Infobot. Infobot uses L<POE> to
avoid blocking between various IO requests. While this is hidden from
developers as far as possible, writing conduits is an area in which a
developer will need a good understanding of L<POE>.

=head1 SCAFFOLDING

When Infobot loads, it reads your configuration file, and attempts to
load the classes you've specified under various headings. Conduits
live under C<conduit>, and normally live in the
C<Infobot::Plugin::Conduit::> namespace.

When Infobot loads your component, it makes several assumptions about
it. Firstly, it will call the C<load()> method, which should return
true or false depending on if the module can be loaded - this is used
primarily to check for module dependencies.

We want to use L<POE::Component::Server::TCP>. L<Infobot::Base> defines
a fairly intelligent C<load()> method that allows us to just put the
modules we want in C<@required_modules>.

Hence:

 package Infobot::Plugin::Conduit::Telnet;

   use strict;
	 use warnings;

 # Import new() and a useful load()

   use base qw( Infobot::Plugin::Conduit::Base ); # Specialised subclass of Infobot::Base

 # Modules we'll be needing

   our @required_modules = qw( POE::Component::Server::TCP );

 # Load POE explicitly

   use POE;

=head1 CONFIGURATION 

Our conduit is going to need some external data to set up properly -
in this case, simply a port number. This should be configurable, so
it's best for it to sit in the main config file under this class.

The convention for adding modules in to the configuration file is
nice and simple. This is a C<conduit>, so it sits under the conduit
section. We need to define a C<class> for it, and any C<extras> we
like. An example will make this clear:

 conduit:
    'Simple Telnet Interface':
      class : Infobot::Plugin::Conduit::Telnet
      extras:
          port: 7654 

This is L<YAML>. It's a bitch with whitespace being non-perfect, so
be careful. C<Simple Telnet Interface> is our unique ID for the
component, C<class> is the class which provides it, and you can put
any information you like in C<extras> - it'll be available to the
class.

At this point, we almost have a working component. All that's left
is ...

=head1 INIT

Having been loaded, components get a chance to do any required
set-up via their C<init()> method. The C<init()> method is passed
the name of the component (so: C<Simple Telnet Interface>) and is
expected to return 1 on success.

You can use this name, to access the configuration values you set.
There's a long way and an easy way. We're interested in the easy
way: 

 $self->set_name( shift() );

This sets C<<$self->{name}>> appropriately, and makes everything
from C<extras> available in C<<$self->{config}>>.

So to make this a workable module, let's add a very simple C<init()>
method which doesn't do anything... So that we get some output, we're
going to write to the log. The log is available through any subclass
of C<Infobot::Base> as C<log>. Pass it a priority and a message -
you can find a list of priorities in L<Infobot::Log>. We're going to 
set our priority to 2 - a serious error - just so it shows up: 

 # Setup

 sub init {

   my $self = shift;

   $self->set_name( shift() );

   $self->log( 2, "We will listen on port $self->{config}->{port}" );

   return 1;

 }

Add it in, fire up C<infobot>! Amongst other lines, I get:

 We will listen on port 7654

=head1 TELNET SERVER

L<POE> allows us to create a simple TCP server very easily. There's
a very simple example here:
L<http://poe.perl.org/?POE_Cookbook/TCP_Servers> that we're going to
try and change as little as possible to make this work.

First of all, we need to start up the TCP server. We'll do this in
our C<init()> method:

 sub init {
 
 	my $self = shift;
 	my $name = shift;
 	
 	$self->set_name( $name );
 	
 	$self->log( 5, "Starting a TCP server on port $self->{config}->{port}" );

	POE::Session->create(
 
 		inline_states => { _start => sub { $_[KERNEL]->alias_set( $name ) } },
 		object_states => [ $self  => [qw( user_input )] ],
 	
	);
 
	POE::Component::Server::TCP->new(
	
		Port => $self->{config}->{port},

		ClientInput => sub {
			my ( $heap, $kernel, $input ) = @_[ HEAP, KERNEL, ARG0 ];
			$kernel->post( $name => user_input => ( $heap->{client}, $input ) )
		},

 	);

	return 1;

This will start a TCP server on the port specified, and send any
client input to our class's C<user_input()> method. Which doesn't
yet exist, so let's write a really simple one:

 sub user_input {
 
	my ( $self, $client, $input ) = @_[ OBJECT, ARG0, ARG1 ];
 	$client->put( $input );
 
 }

We now have an Infobot that starts an echo server ... but doesn't
do much else. The next step is taking the user's input and passing
it through Infobot, and returning Infobot's output to the user.

=head1 CREATING A MESSAGE

Information requests take a predictable path through Infobot. They
originate in conduits, and a corresponding L<Infobot::Message> is
created. This is then offered to every class in the
L<Infobot::Pipeline>, until one takes it, and crafts a response.

This response is sent to C<<Infobot::Message->say()>>. This
actually calls the C<say()> method of the conduit associated with
the message.

What this means for us is that to interface with Infobot proper,
we need to create a C<say()> method that pipes data back down our
conduit, and we need to be turning user input in to
L<Infobot::Message> objects.

First, let's rewrite C<user_input> to create, and then pipe-line
a message:

 sub user_input {

	my ( $self, $client, $input ) = @_[ OBJECT, ARG0, ARG1 ];
	my $message = Infobot::Message->new();

	$message->init(
		
		conduit   => $self,
		context   => { client => $client },
		name      => 'Telnet User',
		nick      => $self->stash('config')->{'alias'},
		message   => $input,
		public    => 0,
		addressed => 1,
		printable => $input,
		
	) or die ( $message->error );

 # Give to the pipeline
		
		$self->pipeline($message);

 }

Pretty straight forward, eh? Let's just recap what those
L<Infobot::Message> options are.

B<conduit> is a reference to the conduit object - so we give it
C<$self>.

B<context> is a useful little stash for our conduit to place
conduit-specific information in. In this case, we'll place a
reference to the requesting client there which we'll use when
we come to write out C<say()> method.

B<name> is our best approximation of the person who's talking
to us. We could have asked the connecting telnet user to identify
themselves, but to keep it simple, here we're going to hardwire
this.

B<nick> is our name, as far as the user is concerned. This is
used primarily to determine if we've been addressed, and it's
not particularly relevant in a telnet server environment!

B<message> is the input to which we want to respond.

B<public> flags whether the message is public or private.
This is used for various logging and reply preferences. In
this case, it's private.

B<addressed> flags whether we were explicitly addressed
by this message. As the telnet server is a 1 to 1 communication
method, we'll say yes.

B<printable> is a simple printable representation of the
message for logging purposes - other contextual information
can be put in here (the IRC conduit adds channel information).

Having created the message, we pipeline it, using the
C<pipeline()> convenience method. Almost done!

=head1 TELL THE WORLD

Finally, we want to be able to reply to the user, so we
need to define a C<say()> method. It'll receive the message
object and the reply as its arguments. So, it can be really
very simple:

 sub say {
 
	my ( $self, $message, $reply ) = @_;
 
 	$message->{context}->{client}->put( $reply );
 
 	return $reply;
 
 }

The return value is used for logging, so it should be
printable - in this case, we're just going to return
the reply unedited!

=head1 CONCLUSION

You can see the finished product in
L<lib/Infobot/Plugin/Conduit/Telnet.pm>. If there's already
a decent POE wrapper around your target protocol, writing a
conduit can be a ten minute job!
