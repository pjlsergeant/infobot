=head1 NAME

Infobot::Plugin::DataSource::HTTP - Spawn a POE::Component::Client::HTTP session

=head1 DESCRIPTION

Spawns a POE::Component::Client::HTTP session for easy use by other components

=head1 CONFIGURATION EXAMPLE

 datasource:
 ...
    'HTTP':
        class : Infobot::Plugin::DataSource::HTTP
        alias : poe_http
        extras:
          Agent   : Infobot v1.0
          Timeout : 15
          FollowRedirects: 3

=head1 CONFIGURATION OPTIONS

=head2 alias

Where to stash this, and also the POE alias given to the session
we create.

=head2 extras

Passed directly through to L<POE::Component::Client::HTTP> - see
those docs for more information on what's allowed

=head1 AUTHOR

Pete Sergeant -- C<pete@clueball.com>

=head1 LICENSE

Copyright B<Pete Sergeant>.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

package Infobot::Plugin::DataSource::HTTP;

	use base qw/Infobot::Plugin::DataSource::Base/; 

	use POE::Component::Client::HTTP;
		
	our @required_modules = ( qw( HTTP::Request POE::Component::Client::HTTP ) ); 

# Spawn our client... 

	sub init {

		my $self = shift;
		my $name = shift;

		$self->set_name( $name );
	
		POE::Component::Client::HTTP->spawn( %{$self->{config}}, Alias => $self->alias );

	# Put ourselves in a sensible place in the stash...

		$self->stash( $self->alias => $self );

		return 1; 

	}


1;