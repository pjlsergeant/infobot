
=head1 NAME

How to write a logger

=head1 INTRODUCTION

One of my favourite convenience methods in Infobot is the ability to
emit a logging message from any object that inherits from
L<Infobot::Base> - which is pretty much every object that forms part
of Infobot:

 $self->log( 1, "Danger danger!" );

What actually happens when you call this method is that your logging
message is passed to a pool of logging objects, each of which can
handle your log message as they wish. This makes it easy to send
important error messages to STDOUT while keeping a debugging file
that receives all messages, for example.

Writing a logging class is very easy, but there are a couple of
things to consider. This tutorial will guide us through the process
of creating a pretty coloured output logger.

=head1 SCAFFOLDING

When Infobot loads, it reads your configuration file, and attempts to
load the classes you've specified under various headings. Loggers
live under C<log>, and normally live in the
C<Infobot::Plugin::Log::> namespace.

When Infobot loads your component, it makes several assumptions about
it. Firstly, it will call the C<load()> method, which should return
true or false depending on if the module can be loaded - this is used
primarily to check for module dependencies.

We're going to want to use L<Term::ANSIColor>.
L<Infobot::Base> provides an intelligent C<load()> method that allows
us to just put the modules we want in C<@required_modules>.

Hence:

 package Infobot::Plugin::Log::ANSIColor;

   use strict;
	 use warnings;

 # Import new() and a useful load()

   use base qw( Infobot::Plugin::Log::Base ); # Specialised subclass of Infobot::Base

 # Modules we'll be needing

   our @required_modules = qw( Term::ANSIColor );

=head1 CONFIGURATION 

It's possible that not everyone is going to appreciate our colour
scheme, so we should allow users to choose their own colours for
the message output.

Logging classes also expect to have a log level configured. Let's
take an example:

 log:
   'Pretty Terminal Colours':
     class : Infobot::Plugin::Log::ANSIColor
     level : 9 
     extras:
       colours:
         levels:
           1: bold red
           3: bold yellow
           5: bold white
         default: white
         package: cyan
         divider: bold white

This is L<YAML>. It's a bitch with whitespace being non-perfect, so
be careful. C<Pretty Terminal Colours> is our unique ID for the
component, C<class> is the class which provides it, and you can put
any information you like in C<extras> - it'll be available to the
class. C<level> is the lowest level of logging information that
the class should accept (1 is the most important, 9 is the least).

At this point, we almost have a functional component. All that's
left is ...

=head1 OUTPUT

Logging classes are expected to have an C<output()> method - this
is their external interface. C<output()> will receive a logging
level, the package from which the message originated, and the
message itself. The simplest usable C<output()> method might look
like:

	sub output {
	
		my $self = shift;
		
		my $level   = shift;
		my $package = shift;
		my $message = shift;	
		
		print STDERR "[$level] [$package] $message\n";

	}

And in fact, if you use that, we have a working logging system -
all you need to do is put a reference to it in the config file,
and it'll be used. But we want to do something a little prettier
than that!

=head1 INIT

Having been loaded, components get a chance to do any required
set-up via their C<init()> method. The C<init()> method is passed
the name of the component (so: C<Pretty Terminal Colours>) and is
expected to return 1 on success.

You can use this name, to access the configuration values you set.
There's a long way and an easy way. We're interested in the easy
way: 

 $self->set_name( shift() );

This sets C<<$self->{name}>> appropriately, and makes everything
from C<extras> available in C<<$self->{config}>>.

L<Infobot::Plugin::Log::Base> provides a very simple C<init()>
method that not only does this, but also adds the logger to our
logging pool:

	sub init {

		my $self  = shift;
		my $name = shift;

		$self->log(5, "Initializing log: " . ref($self ) );

		$self->set_name( $name );
		$self->register();

		return 1;
		
	}

It's as simple as calling C<<$self->register()>>.

This would seem like a perfect place to add in some legwork we
want to do involving setting up the coloured terminal, giving us:

	sub init {

		my $self  = shift;
		my $name = shift;

		$self->log(5, "Initializing log: " . ref($self ) );

		$self->set_name( $name );
	
	# Set up our pretty colours
	
		my $current_colour = $self->{config}->{colours}->{default} || 'white';
	
		for (0 .. 8 ) {
		
			my $level = 9 - $_;
		
			$self->{colour}->{levels}->[ $level ] =
			
				Term::ANSIColor::color(
			
					$self->{config}->{colours}->{levels}->{$level} ||
					$current_colour
				
				);
		
		}
	
		my $package_colour = $self->{config}->{colours}->{'package'} || 'white';
		$self->{colour}->{package} = Term::ANSIColor::color( $package_colour );
		
		my $divider_colour =  $self->{config}->{colours}->{divider} || 'white';
		$self->{colour}->{divider} = Term::ANSIColor::color( $divider_colour );

		$self->{colour}->{reset} = Term::ANSIColor::color( 'reset' );

	# Register the logger as ready to use
		
		$self->register();

		return 1;
		
	}	
		
So far so good - nothing complicated there. But we are going to want
to rewrite our output method to actually use this...

	sub output {
	
		my $self = shift;
		
		my $level   = shift;
		my $package = shift;
		my $message = shift;	

	# Nasty hack to truncate the package name

		$package =~ s/..+(......)$/<$1/g; # hee!

	# Now print out the message
	
		print
			
			$self->{colour}->{divider} . '[' .
			$self->{colour}->{reset  } .
			
			$self->{colour}->{package} . $package .
			$self->{colour}->{reset  } .			
			
			$self->{colour}->{divider} . ']' .
			$self->{colour}->{reset  } .	' ' .	

			$self->{colour}->{levels}->[ $level ] . "$level: $message" .
			$self->{colour}->{reset} . "\n";

		return 1;

	}

=head1 CONCLUSION

You can see the finished product in
L<lib/Infobot/Plugin/Log/ANSIColor.pm>. As you can see, writing
a new logger is not a major undertaking...
