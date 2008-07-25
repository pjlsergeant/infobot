
	use strict;
	use warnings;

	use Tk;
	use Tk::LabEntry;

	my $search_string;

	my $main = MainWindow->new();


	my $entry = $main->LabEntry(-label => 'Say:', -width => 80,
        -labelPack => [qw/-side left -anchor w/],
        -textvariable => \$search_string)->pack(qw/-padx 2 -side top/);
        
	my $frame = $main->Scrolled(qw/Frame -width 600 -height 200 -scrollbars e/)->pack( -side => 'bottom' );


	$entry->bind('<Return>' => sub { add_text(0,0,"Hi there") } );

	MainLoop();
	
	sub add_text {
	
		my ( $self, $user, $text ) = @_;
		
		my $bg = 'Bisque';
		
		unless ( $user ) {
			$bg = 'LightGreen';
		}
		
		my $tb = $frame->Label( -anchor => 'w', -background => $bg, -border => 1, -width => 80, -justify => 'left', -wraplength => 550, -text => $search_string )->pack( -side => 'bottom', -anchor => 'w', -pady => 1 );
	
		$frame->Subwidget('xscrollbar')->set(1,1);
	
		$search_string = '';
	
	}
