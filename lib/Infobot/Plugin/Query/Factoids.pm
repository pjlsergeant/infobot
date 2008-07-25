
package Infobot::Plugin::Query::Factoids;

	use strict;
	use warnings;
	
	use base (qw( Infobot::Plugin::Query::Base::DBIxClass ));

	our %help = (
	
		'factoids' => {
		
			'_' => "This release of Infobot provides a _very_ basic factoid system as a demonstration - it's not intended as a replacement for the old Infobot factoid system, or even as something useful in its own right",
			
			'setting'    => "remember [key] is [value] # Stores the value under the key",
			'retrieving' => "what is [key]? # Retrieves the value for key",
			'deleting'   => "forget [key] # Removes the factoid under key",
		
		}
	
	);

	sub process {

		my $self    = shift;
		my $message = shift;


		if ( $message->{message} =~ m/^remember (.+?)\s+is\s+(.+)\s*$/i ) {

			$self->remember( $message, $1, $2 );
			return 1;

		} elsif ( $message->{message} =~ m/^what is\s+(.+)\s*$/i ) {
		
			my $key = $1;
			$key =~ s/\?+$//;
			
			$self->lookup( $message, $key );

		} elsif ( $message->{message} =~ m/^forget (.+)\s*$/i ) {
		
			if ( $message->addressed ) {
			
				$self->forget( $message, $1 );
			
			} else {
			
				return undef;
			
			}

		} else {

			return undef;

		}

	}
	
	
	sub remember {
	
		my $self    = shift;
		my $message = shift;
		my $key     = shift;
		my $value   = shift;
	
		my $data = $self->get( $key );
		
		if ( $data ) {
		
			$message->say( "But $key is $data, " . $message->name . "!" );
		
		} else {
		
			$self->set( $key => $value );
			$message->say( 'Gotcha, ' . $message->name . '!'  );
		
		}
		
		return 1;
	
	}
	
	sub lookup {
	
		my $self    = shift;
		my $message = shift;
		my $factoid = shift;
	
		my $data = $self->get( $factoid );
		
		if ( $data ) {
		
			$message->say( $message->name . ": $factoid is $data" );
		
		} else {
		
			$message->say( "Don't know anything about $factoid, " . $message->name );
		
		}
		
		return 1;
	
	}

	sub forget {
	
		my $self    = shift;
		my $message = shift;
		my $key     = shift;
	
		if ( $self->remove( $key ) ) {
		
			$message->say( "I've forgotten all about $key" );
		
		} else {
		
			$message->say( "But I don't know anything about $key, " . $message->name .  '!' );
		
		}
		
		return 1;
	
	}

	sub remove {

		my $self = shift;

		my ($key, $fact) = @_;

		my ($object) = $self->dbi->search( thing => $key );

		$self->log( 8, "Removing [$key]" );

		if ( $object ) {

			$object->delete();
			return 1;

		}	else {

			return 0;

		}

	}

	sub set {

		my $self = shift;

		my ($key, $fact) = @_;

		my ($object) = $self->dbi->search( thing => $key );

		$self->log( 8, "Setting [$key] is [$fact]" );

		if ( $object ) {

			$object->content( $fact );
			$object->update;

		}	else {

			$object = $self->dbi->create({ thing => $key, content => $fact });
			$object->update;

		}

		return 1;

	}

  sub get {
	
		my $self = shift;

		my $key = $_[0];

		$self->log( 8, "Looking up [$key] " );

    my ($object) = $self->dbi->search( thing => $key );

		if ( $object ) {	
		
			$self->log( 8, "Found something!" );
			
			return $object->content || '';

		} else {

			$self->log( 8, "Not found" );
			return '';

		}

	}

1;

__DATA__

# WARNING DANGER

# A lot (most) of this code has been lifted from 0.43 with only
# minor modifications. As a result, it's pretty shoddy. But what
# it /does/ do is work, for the most part.

# There are a bunch of tests for various bits of this, based on
# a large corpus of logs from #perl. Please ensure these tests
# pass before and after you hack on this code. They don't ensure
# that the code is correct - they ensure that any functionality
# changes you make are flagged - if your change breaks tests, it's
# possible the test is incorrectly testing for a bug in infobot.

package Infobot::Plugin::Query::Factoids;

	use strict;
	use warnings;

	use base (qw( Infobot::Plugin::Query::Base::DBIxClass ));

# Statements to use when I'm specifically being asked a question,
# but don't know the answer.
 
	my @dunno = (
		'i don\'t know',
		'wish i knew',
		'i haven\'t a clue',
		'no idea',
		'bugger all, i dunno'
	);

	my $coverage;

# Verbs we currently use	

	my @verb = qw(is are);

# Database lookups
	
	sub set {

		my $self = shift;

		my ($verb, $key, $fact) = @_;

		my ($object) = $self->dbi->search( thing => $key, verb => $verb );

		$self->log( 8, "Setting [$key] $verb [$fact]" );

		if ( $object ) {

			$object->content( $fact );
			$object->update;

		}	else {

			$object = $self->dbi->create({ thing => $key, verb => $verb, content => $fact });
			$object->update;

		}

		return 1;

	}

  sub get {
	
		my $self = shift;

		my ( $key, $verb ) = @_;

		unless ( $verb ) {

			( $verb, $key ) = split( /\s+/, $key );

		}

		$self->log( 8, "Looking up [$key] in [$verb]" );

    my ($object) = $self->dbi->search( thing => $key, verb => $verb );

		if ( $object ) {	
		
			$self->log( 8, "Found something!" );
			
			return $object->content || '';

		} else {

			$self->log( 8, "Not found" );
			return '';

		}

	}

# The magic happens here...

	sub process {

		my $self    = shift;
		my $message = shift;

	# First things first, let's create a factoid package
	# so we don't need to stash anything, and so we can
	# easily pass around data we've already had to work
	# to retrieve.

		my $factoid = {

		# These bits we start with

			message   => $message,
			who       => $message->name,
			nick      => $message->nick,
			text      => $message->message,
			addressed => $message->addressed,
	
		# These bits we get as we go along
	
			filter               => '',
			correction_plausible => 0,
			continuity           => 0,
			question_mark        => 0,
			question_word        => '',
	
		};

		my $nick = $factoid->{nick}; # Used in regex's a lot, so alias
	
	# Remove control characters	
		
		$factoid->{'text'} =~ s/[\cA-\c_]//ig;

	# Look for, then remove, message filters. The filter below is
	# able to match things like '=~ /(?:(toot!))/' for historical
	# reasons.

		$factoid->{'filter'} = ($1 || $2) 
    
			if $factoid->{'text'} =~ s,
				
				\s+ (?:=~)? \s?			# Allow an =~ part
        
				/										# Literal /

					(?: 								# Non-assigned OR group 
					
						\(									# Literal (
						(?: \?: )?					# Optional literal ?:
						([^)]*)							# Any stuff that isn't a closing bracket
						\)									# Literal }

					|										# OR

						([^()]*)						# Any stuff that isn't brackets
					
					)										# End of OR group

				/										# Literal /
				i?									# Allow people to specify an 'i' if they like
				
				\s* $								# Any whitespace they fancy then string end
				
			,,x;								# Strip it!

		if ( $factoid->{'filter'} ) {

			$self->log( 7, "Message filter found: [$factoid->{'filter'}]" );

		}

	# We try and work out elsewhere if we're addressed, but we're
	# keeping in the further context here so that we can do less
	# refactoring right now :-) The original code set $addressed
	# to be zero here, but we set it a little further up the file...

	# Flag, and substitute out possible corrections

		if (
			($factoid->{'text'} =~ s/^(no,?\s+$nick,?\s*)//i) ||
			($factoid->{'addressed'} and $factoid->{'text'} =~ s/^(no,?\s+)//i)
		) { 
		
			$factoid->{'correction_plausible'} = 1;
    
		} else {
				
			$factoid->{'correction_plausible'} = 0;
    
		}

	# Handle 'feedback addressing' - that is, someone saying 'infobot?'

		if (
			$factoid->{'text'} =~ /^\s*$nick\s*\?*$/i ||
			($factoid->{'text'} =~ /^\s*\s*\?*$/ && $factoid->{addressed} )
		) {
		
				if (rand() > 0.5) {

					$factoid->{message}->say( "yes, " . $factoid->{who} . '?' );
					return 1;
					
				} else {
					
					$factoid->{message}->say( $factoid->{who} . '?' );
					return 1;
        
				}

			# FIX - last addressing
			
    }

	# Redo addressing stuff, for now. This needs to be reworked,
	# obviously, as we're duplicating it here... FIX

		if (
			
			($factoid->{'text'} =~ /^\s*$nick\s*(?:[\,\:\> ]+) *(.+)$/i) ||
			($factoid->{'text'} =~ /^\s*$nick\s*-+ *\??(.+)$/i) 
			
		) {
		
		# Perform a check here that it isn't, in fact, a statement
			
			my $trail = $1;
			
			if ($trail !~ /^\s*is/i) {
				
				#$message = $trail;
				$factoid->{'addressed'} = 1;
			
			}
		
		}

		if ($factoid->{'text'} =~ m/^(.+)(, ?$nick(\W+)?)$/i) { # i have been addressed!

			my $query_part = $1;
			my $addressed_part = $2;

			if ($query_part !~ /^\s*i?s\s*$/i) {
	
				$query_part = quotemeta($query_part);
				$factoid->{'text'} =~ s/$query_part//;
				$factoid->{'addressed'} = 1;
    	
			}
		
		}

	# FIX - removed 'showmode' functionality
	# FIX - removed 'continuity' functionality...

	# FIX - removed taking a ref to message length in to $message_input_length

	# One of /many/ points at which we take off some type of whitespace!	
		
		$factoid->{'text'} =~ s/^\s+//;
	

		$factoid->{'text'} =~ s/^\s*hey,*\s+where/where/i && $coverage++;
		$factoid->{'text'} =~ s/whois/who is/ig  && $coverage++;
		$factoid->{'text'} =~ s/where can i find/where is/i && $coverage++;
		$factoid->{'text'} =~ s/how about/where is/i && $coverage++;
		$factoid->{'text'} =~ s/^(gee|boy|golly|gosh),? //i && $coverage++;
		$factoid->{'text'} =~ s/^(well|and|but|or|yes),? //i && $coverage++;
		$factoid->{'text'} =~ s/^(does )?(any|ne)(1|one|body) know // && $coverage++;
		$factoid->{'text'} =~ s/ da / the /ig && $coverage++;
		$factoid->{'text'} =~ s/^heya*,*( folks)?,*\.* *//i && $coverage++; # clear initial filled pauses & stuff
		$factoid->{'text'} =~ s/^[uh]+m*[,\.]* +//i && $coverage++;
		$factoid->{'text'} =~ s/^o+[hk]+(a+y+)?,*\.* +//i && $coverage++; 
		$factoid->{'text'} =~ s/^g(eez|osh|olly)+,*\.* +(.+)/$2/i && $coverage++;
		$factoid->{'text'} =~ s/^w(ow|hee|o+ho+)+,*\.* +(.+)/$2/i && $coverage++;
		$factoid->{'text'} =~ s/^still,* +//i && $coverage++; 
		$factoid->{'text'} =~ s/^well,* +//i && $coverage++;
		$factoid->{'text'} =~ s/^\s*(stupid )?q(uestion)?:\s+// && $coverage++;

	# FIX - removed all ability to tell someone anything...
		
	# FIX - removed all 'target' stuff	

		my $check_minimum_volunteer_length;

		if ( 
			$factoid->{'continuity'} or # These count as explicit 
			$factoid->{'addressed'}  or #  " " 
			( # Flag it if we're entering this loop only because
			  # addressing is off...
				!$factoid->{message}->context->{addressing} &&
				++$check_minimum_volunteer_length
			)	
		) {

		# FIX - this is the point, originally, where we checked against plugins

		# Check if it's a question, as long as it meets our 'volunteering'
		# criteria 

			$self->log( 9, "We've been addressed, or continuity, or addressing isn't on"); 
			$self->{config}->{minimum_volunteer_length} = 0 unless $self->{config}->{minimum_volunteer_length};
			
			unless ( 
				$check_minimum_volunteer_length &&
				( length( $factoid->{text} ) < $self->{config}->{minimum_volunteer_length}  ) 
			) {
			
				$self->log(9, "Now we're going to check to see if [$factoid->{text}] is found");
			
				if ( $self->is_question( $factoid ) ) {

					return 1;

				} 	

			}

		# FIX - karma stuff used to be here, but we've moved that forward
		# in the processing queue...
			
		# FIX - Removed min volunteer length stuff - didn't seem to do anything?
		
		# FIX - removed question count stuff - add back in elsewhere...

		# FIX - removed replies to statements - add that back in the is_statement
			
			if ( $self->is_statement( $factoid ) ) {
			
				return 1;
			
			}
			
				# If we're sure it's a question...	
    
    	if ( $factoid->{addressed} ) {

			my $reply = $dunno[int(rand(@dunno))];
				
	    if (rand() > 0.5) {
				$factoid->{message}->say( $factoid->{who} . ": $reply" );
				return 1;
	    } else {
				$factoid->{message}->say( "$reply, " . $factoid->{who} );
				return 1;
	    }

		}
	
		}
	
	# If we're here, and we were addressed, we're confused...

	# FIX - Confused message should be final part on the message chain 

		return undef;

	}


# Work out if we're a query, and perform other munging...

	sub is_question {

		my $self      = shift;
		my $factoid   = shift;
	
	# Remove the trailing question mark, but record it...
		
		$factoid->{question_mark} = $factoid->{text} =~ s/\?+\s*$//;

	# Convert to canonical reference form
		
		$self->normquery(    $factoid ); 
		$self->switchPerson( $factoid );

	# Where is x at?
		
    $factoid->{text} =~ s/\s+at\s*(\?*)$/$1/;

	# Find the question word

    $factoid->{text} = " $factoid->{text} ";
    my $qregex = join '|', qw( who what where );

    $factoid->{text} =~ s/ ($qregex)\'?s / $1 is / && $coverage++;

    if ($factoid->{text} =~ s/\s+($qregex)\s+//i) { # check for question word

			$factoid->{question_word} = lc($1);
    
		}

    $factoid->{text} =~ s/^\s+//;
    $factoid->{text} =~ s/\s+$//;

	# Presence of a question_word used for making decision elsewhere,
	# so force one if we're sure it's a question

    if (
			( $factoid->{question_word} eq "" ) &&
			( $factoid->{question_mark}       ) &&
			( $factoid->{addressed} || $factoid->{continuity} )
		) {		

			$factoid->{question_word} = "where";

		}

 	# ok, here's where we try to actually get it

		my $answer = $self->lookup( $factoid );

	# If we got a reply, it's already been sent, to represent that 
	
		return 1 if $answer;
		


		return undef;

	}

# Yet More language parsing stuff...

	sub normquery {

		my $self    = shift;
		my $factoid = shift;

		$factoid->{text} = ' ' . $factoid->{text} . ' ';

		# where blah is -> where is blah
		$factoid->{text} =~ s/ (where|what|who)\s+(\S+)\s+(is|are) / $1 $3 $2 /i && $coverage++;

		# where blah is -> where is blah
		$factoid->{text} =~ s/ (where|what|who)\s+(.*)\s+(is|are) / $1 $3 $2 /i && $coverage++;

		$factoid->{text} =~ s/^\s*(.*?)\s*/$1/ && $coverage++;

		$factoid->{text} =~ s/be tellin\'?g?/tell/i && $coverage++;
		$factoid->{text} =~ s/ \'?bout/ about/i && $coverage++;

		$factoid->{text} =~ s/,? any(hoo?w?|ways?)/ /ig && $coverage++;
		$factoid->{text} =~ s/,?\s*(pretty )*please\??\s*$/\?/i && $coverage++;


		# what country is ...
		if (
			$factoid->{text} =~ 
			s/wh(at|ich)\s+(add?res?s|country|place|net (suffix|domain))/wh$1 /ig
		) {

			if ((length($factoid->{text}) == 2) && ($factoid->{text} !~ /^\./)) {
				
				$factoid->{text} = '.'.$factoid->{text};
			}

			$factoid->{text} .= '?';

		}

		# profanity filters.  just delete it
		$factoid->{text} =~ s/th(e|at|is) (((m(o|u)th(a|er) ?)?fuck(in\'?g?)?|hell|heck|(god-?)?damn?(ed)?) ?)+//ig && $coverage++;
		$factoid->{text} =~ s/wtf/where/gi && $coverage++; 
		$factoid->{text} =~ s/this (.*) thingy?/ $1/gi && $coverage++;
		$factoid->{text} =~ s/this thingy? (called )?//gi && $coverage++;
		$factoid->{text} =~ s/ha(s|ve) (an?y?|some|ne) (idea|clue|guess|seen) /know /ig && $coverage++;
		$factoid->{text} =~ s/does (any|ne|some) ?(1|one|body) know //ig && $coverage++;
		$factoid->{text} =~ s/do you know //ig && $coverage++;
		$factoid->{text} =~ s/can (you|u|((any|ne|some) ?(1|one|body)))( please)? tell (me|us|him|her)//ig && $coverage++;
		$factoid->{text} =~ s/where (\S+) can \S+ (a|an|the)?//ig && $coverage++;
		$factoid->{text} =~ s/(can|do) (i|you|one|we|he|she) (find|get)( this)?/is/i && $coverage++; # where can i find
		$factoid->{text} =~ s/(i|one|we|he|she) can (find|get)/is/gi && $coverage++; # where i can find
		$factoid->{text} =~ s/(the )?(address|url) (for|to) //i && $coverage++; # this should be more specific
		$factoid->{text} =~ s/(where is )+/where is /ig && $coverage++;
		$factoid->{text} =~ s/\s+/ /g && $coverage++;
		$factoid->{text} =~ s/^\s+// && $coverage++;

		if ($factoid->{text} =~ s/\s*[\/?!]*\?+\s*$//) {
			$factoid->{question_mark} = 1;
		}

		#	$factoid->{text} =~ s/\b(the|an?)\s+/ /i; # handle first article in query
		$factoid->{text} =~ s/\s+/ /g && $coverage++;

		$factoid->{text} =~ s/^\s*(.*?)\s*$/$1/ && $coverage++;
	
	}

	# for be-verbs
	sub switchPerson {

		my $self = shift;

		my $factoid = shift;
	
		my $in   = $factoid->{text};
		my $who  = $factoid->{who};
		my $nick = $factoid->{nick};
		my $addressed = $factoid->{addressed};

		my $safeWho = purifyNick($who);

		# $safeWho will cause trouble in nicks with deleted \W's
		$in =~ s/(^|\W)${safeWho}s\s+/$1${who}\'s /ig && $coverage++; # fix genitives
		$in =~ s/(^|\W)${safeWho}s$/$1${who}\'s/ig && $coverage++; # fix genitives
		$in =~ s/(^|\W)${safeWho}\'(\s|$)/$1${who}\'s$2/ig && $coverage++; # fix genitives
		$in =~ s/(^|\s)i\'m(\W|$)/$1$who is$2/ig && $coverage++;
		$in =~ s/(^|\s)i\'ve(\W|$)/$1$who has$2/ig && $coverage++;
		$in =~ s/(^|\s)i have(\W|$)/$1$who has$2/ig && $coverage++;
		$in =~ s/(^|\s)i haven\'?t(\W|$)/$1$who has not$2/ig && $coverage++;
		$in =~ s/(^|\s)i(\W|$)/$1$who$2/ig && $coverage++;
		$in =~ s/ am\b/ is/i && $coverage++;
		$in =~ s/\bam /is/i && $coverage++;
		$in =~ s/yourself/$nick/i if ($addressed) && $coverage++;
		$in =~ s/(^|\s)(me|myself)(\W|$)/$1$who$3/ig && $coverage++;
		$in =~ s/(^|\s)my(\W|$)/$1${who}\'s$2/ig && $coverage++; # turn 'my' into name's
		$in =~ s/(^|\W)you\'?re(\W|$)/$1you are$2/ig && $coverage++;

		if ($addressed > 0) {
			$in =~ s/(^|\W)are you(\W|$)/$1is $nick$2/ig && $coverage++;
			$in =~ s/(^|\W)you are(\W|$)/$1$nick is$2/ig && $coverage++;
			$in =~ s/(^|\W)you(\W|$)/$1$nick$2/ig && $coverage++; 
			$in =~ s/(^|\W)your(\W|$)/$1$nick\'s$2/ig && $coverage++;
		}

		$factoid->{text} = $in;

	}   

# Function, not a method...

	sub purifyNick {
		
		my $safeWho = $_[0];
		$safeWho =~ s/\*//g && $coverage++;
		$safeWho =~ s/\\/\\\\/g && $coverage++;
		$safeWho =~ s/\[/\\\[/g && $coverage++;
		$safeWho =~ s/\]/\\\]/g && $coverage++;
		$safeWho =~ s/\|/\\\|/g && $coverage++;
		$safeWho =~ tr/A-Z/a-z/ && $coverage++;
		$safeWho = substr($safeWho, 0, 9);
		$safeWho =~ s/\s+.*// && $coverage++;
		return $safeWho;
	
	}
	sub lookup {

		my $self = shift;
		my $factoid = shift;

		$self->log(8, "Query parsed to: " . $factoid->{text} );

		my $msgType    = $factoid->{public} ? 'public' : 'private';
		my $message    = $factoid->{text};
		my $msgFilter  = $factoid->{filter};
		my $addressed  = $factoid->{addressed};
		my $finalQMark = $factoid->{question_mark};
		my $who        = $factoid->{who};
		my $crop       = 0;
		my $nick       = $factoid->{nick};

		my $questionWord = $factoid->{question_word};

    my($theMsg) = "";
    my($locMsg) = $message;

		my $shortReply = 0;

    # x is y

    # x    is the lhs (left hand side)
    # 'is' is the mhs ("middle hand side".. the "head", or verb)
    # y    is the Y (right hand side)

    my($X, $V, $Y, $result);
    my ($theVerb, $orig_Y);

    $locMsg =~ tr/A-Z/a-z/;

    my $literal = ($locMsg =~ s/^literal //);

		if ($result = $self->get($locMsg, 'is')) {
		#	&status("exact: $message =is=> $result");
			$theVerb = "is";
			$X = $message;
			$V = $theVerb;
			$Y = $result;
			$orig_Y = $X;

		} elsif ($result = $self->get($locMsg, 'are')) {
			#	&status("exact: $message =is=> $result");
			$theVerb = "are";
			$X = $message;
			$V = $theVerb;
			$Y = $result;
			$orig_Y = $X;

		} else { # no verb
			my $y_determiner = '';
			my $verbs = join '|', @verb;

			$message = " $message ";

			if ($message =~ / ($verbs) /i) {
				$X = $`;
				$V = $1; 
				$Y = $';

				$X =~ s/^\s*(.*?)\s*$/$1/ && $coverage++;
				$Y =~ s/^\s*(.*?)\s*$/$1/ && $coverage++;
				$orig_Y = $Y;
				$Y =~ tr/A-Z/a-z/ && $coverage++;

				$V =~ s/^\s*(.*?)\s*$/$1/;

				if ($Y =~ s/^(an?|the)\s+//) {
					$y_determiner = $1;
				} else {
					$y_determiner = '';
				}

				if ($questionWord !~ /^\s*$/) {
					if ($V eq "is") {
						$result = $self->get($Y, 'is');
					} else {
						if ($V eq "are") {
							$result = $self->get($Y, 'are');
						}
					}
				}

				$theVerb = $V;

			}

#			my $debugstring = "\tmsgType:\t$msgType\n";
#			$debugstring .= "\tquestionWord:\t$questionWord\n";
#			$debugstring .= "\taddressed:\t$addressed\n";
#			$debugstring .= "\tfinalQMark:\t$finalQMark\n";
#			$debugstring .= "\tX[$X] verb[$theVerb] det[$y_determiner] Y[$Y]\n";
#			$debugstring .= "\tresult:\t$result\n"; 
#			$self->log( 9, $debugstring ); 

			if ($y_determiner) {
			# put the det back on 
				$Y = "$y_determiner $Y";
			}

			# check "is" tables anyway for lhs alone

			if (!defined($V)) {	# no explicit head had been found
				my $det;
				if ($locMsg =~ s/^\s*(an?|the)\s+//) {
					$det = $1;
				}
				$locMsg =~ s/[.!?]+\s*$// && $coverage++;

				my($check) = "";

				$check = $self->get($locMsg, 'is') || '';

				if ($check ne "") {
					$result = $check;
					$orig_Y = $locMsg;
					$theVerb = "is";
					$V = "is";	# artificially set the head to is
				} else {
					$check = $self->get($locMsg, 'are') || '';
					if ($check ne "") {
						$result = $check;
						$V = "are"; # artificially set the head to are
						$orig_Y = $locMsg;
						$theVerb = "are";
					}
				}
				if ($det) {
					$orig_Y = "$det $orig_Y";
				}
			}
		}
			$result = '' unless $result;
			$V = '' unless $V;
			
		PickMsg: {
			last if $V eq '';			# can't do without a head

			if ($literal) {
				$theMsg = $result;
				last;
			}

			my(@poss) = split(/(?<!\\)\|/, $result);

			if ($msgFilter) {
				@poss = grep /\Q$msgFilter\E/, @poss;
				if (!@poss) {
					$theMsg = q!<reply>Hmm.  No matches for that, $who.!;
					last;
				}
			}

		# Reponses which start with <\d+> indicated weighted probability.
		# Such a response is N times more likely to be chosen.
			my $tot_weight = 0;
			for (@poss) {
				my $weight = s/^\s*<(\d+)>// && $1 > 0 ? $1 : 1;
				$tot_weight += $weight;
				$theMsg = $_ if int(rand $tot_weight) < $weight;
			}

			$theMsg =~ s/^\s+// && $coverage++;
			$theMsg =~ s/\s+$// && $coverage++;
			$theMsg =~ s/\\\|/\|/g && $coverage++;
		}

		my $skipReply = 0;

		if ($theMsg ne "") {
#	if ($msgType =~ /public/) {
# FIX - removing this functionality for now
#    my $interval = time() - $prevTime;
#	    if ( 1 
#		&& getparam('repeatIgnoreInterval')
#		&& ($theMsg eq $prevMsg) 
#		&& ((time()-$prevTime) < getparam('repeatIgnoreInterval'))) {
#		&status("repeat ignored ($interval secs < ".getparam('repeatIgnoreInterval').")");
#		$skipReply = 1;
#		$theMsg = "NOREPLY";
#		$prevTime = time();
#	    } else {
#		$skipReply = 0;
#		$prevTime = time() unless ($theMsg eq $prevMsg);
#		$prevMsg = $theMsg;
#	    }
#	}


		# by now $theMsg should contain the result, or null

		# this global is nto a great idea
			my $shortReply = 0;
			my $noReply = 0;

### This be b0rked, I guess, since it was sorta commented out. 
#	Now it has a real comment.  This is it.  'if (0 and'--
#	if ($theMsg =~ s/^\s*<noreply>\s*//i) { 
#	    # specially defined type. No reply. Experimental.
#	    $noReply = 1;
#	    return 'NOREPLY';
#	}

			if (!$msgType) {
				$msgType = 'private';
				&status("NO MSG TYPE / set to private\n");
			}

# Made case-sensitive go bye-bye.
			if ($literal) {
				$orig_Y =~ s/^literal //i;
				$theMsg = "$who: $orig_Y =$theVerb= $theMsg";
				return $theMsg;
			}

# We really should tokenize outbound factoids - this would allow us to 
# see in a single pass that a factoid was <priv><req><reply> without 
# requiring them to be in any specific order.  
# <priv> forthcoming.
			if ($theMsg =~ s/^\s*<req>\s*//i and not $addressed) {
				$skipReply = 1;
			} elsif ($msgType !~ /private/ and $theMsg =~ s/^\s*<reply>\s*//i) {
# specially defined type.  only remove '<reply>'
				$shortReply = 1;
			} elsif (1 and $theMsg =~ m/(<(?:rss|rdf)\s*=\s*(\S+)>)/i) {

			my $result = '[RSS not yet implemented]';

# specially defined type.  get and process an RSS (RDF Site Summary)
				my ($replace, $rdf_loc) = ($1,$2);
#				$shortReply = 1;
#				$rdf_loc =~ s/^\"+// && $coverage++;
#				$rdf_loc =~ s/\"+$// && $coverage++;
#
#				if ($rdf_loc !~ /^(ht|f)tp:/) {
#					&msg($who, "$orig_Y: bad RSS [$rdf_loc] (not an HTTP or FTP location)");
#				} else {
#					my $result = ''; #&get_headlines($rdf_loc);
#					if ($result =~ s/^error: //) {
#						$theMsg = "couldn't get the headlines: $result";
#					} else {
						$theMsg =~ s/\Q$replace\E/$result/;
						$theMsg = "$who: $theMsg";
#					}
#				}
			} elsif ($msgType !~ /private/ and 
				$theMsg =~ s/^\s*<action>\s*(.*)/\cAACTION $1\cA/i) {
			# specially defined type.  only remove '<action>' and make it an action
				$shortReply = 1;
			} else {		# not a short reply
				if ($theVerb =~ /is/) {
					my($x) = int(rand(16));
				# oh this could be done much better
					if ($x <= 5) {
						$theMsg= "$orig_Y is $theMsg";
					}
					if ($x == 6) { 
						$theMsg= "i think $orig_Y is $theMsg";
					}
					if ($x == 7) { 
						$theMsg= "hmmm... $orig_Y is $theMsg";
					}
					if ($x == 8) { 
						$theMsg= "it has been said that $orig_Y is $theMsg";
					}
					if ($x == 9) { 	
						$theMsg= "$orig_Y is probably $theMsg";
					}
					if ($x == 10) { 
$theMsg =~ s/[.!?]+$//;
$theMsg= "rumour has it $orig_Y is $theMsg";
# $theMsg .= " dumbass";
}
if ($x == 11) { 
$theMsg= "i heard $orig_Y was $theMsg";
}
if ($x == 12) { 
$theMsg= "somebody said $orig_Y was $theMsg";
}
if ($x == 13) { 
$theMsg= "i guess $orig_Y is $theMsg";
}
if ($x == 14) { 
$theMsg= "well, $orig_Y is $theMsg";
}
if ($x == 15) { 
$theMsg =~ s/[.!?]+$//;
$theMsg= "$orig_Y is, like, $theMsg";
}
} else {
$theMsg = "$orig_Y $theVerb $theMsg" if ($theMsg !~ /^\s*$/);
}
}
}

my $safeWho = &purifyNick($who);

if (!$shortReply) {
# shouldn't this be in switchPerson?
# this is fixing the person for going back out

# /^onz!lenzo@lenzo.pc.cs.cmu.edu privmsg rurl :*** noctcp: omega42 is/: nested *?+ in regexp at /usr/users/infobot/infobot-current/src/Reply.pl line 266, <FH> chunk 176.

if ($theMsg =~ s/^$safeWho is/you are/i) { # fix the person 
} else {
$theMsg =~ s/^$nick is /i am /ig;
$theMsg =~ s/ $nick is / i am /ig;
$theMsg =~ s/^$nick was /i was /ig;
$theMsg =~ s/ $nick was / i was /ig;

if ($addressed) {
$theMsg =~ s/^you are (\.*)/i am $1/ig;
$theMsg =~ s/ you are (\.*)/ i am $1/ig;
} else {
if ($theMsg =~ /^you are / or $theMsg =~ / you are /) {
$theMsg = 'NOREPLY';
}
}
}

$theMsg =~ s/ $nick\'?s / my /ig;
$theMsg =~ s/^$safeWho\'?s /$safeWho, your /i;
$theMsg =~ s/ $safeWho\'?s / your /ig;
}


if (1) {			# $date, $time 
my $curDate = scalar(localtime());
chomp $curDate;
$curDate =~ s/\:\d+(\s+\w+)\s+\d+$/$1/;
$theMsg =~ s/\$date/$curDate/gi;
$curDate =~ s/\w+\s+\w+\s+\d+\s+//;
$theMsg =~ s/\$time/$curDate/gi;
}

$theMsg =~ s/\$who/$who/gi;

if (1) {			# variables. like $me or \me
$theMsg =~ s/(\\){1,}([^\s\\]+)/$1/g;
}

$theMsg =~ s/^\s*//;
$theMsg =~ s/\s+$//;

#if (getparam('filter')) {
#require "src/filter.pl";
#$theMsg = &filter($theMsg);
#}

# If we have non-space content in our reply, we return it... 
if ($theMsg =~ /\S/) {
# But first we check to see if we should be crop it
if ($crop) {

# If we're here, guess there's a chance we should be,
# so we check that we weren't addressed and that the
# reply will be longer than our 'crop' value
unless (($addressed)||(length($theMsg)<$crop)) {

# Grab the first 'crop' chars of the return message
my $temp_msg = substr($theMsg, 0, $crop);

# Find a nice white-space delimiter
1 while(chop($temp_msg) =~ /\S/);

# Work out how much we chopped for our status message
my $discarded = length($theMsg) - length($temp_msg);

# Overwrite the return var ($theMsg) with out new one
$theMsg = $temp_msg . "... [$discarded chars more]";

}
}

$factoid->{message}->say($theMsg);
return 1;

} else {
return undef;
}
}


sub is_statement {

	my $self = shift;
	my $factoid = shift;

	my $msgType    = $factoid->{public} ? 'public' : 'private';
	my $in         = $factoid->{text};
	my $msgFilter  = $factoid->{filter};
	my $addressed  = $factoid->{addressed};
	my $finalQMark = $factoid->{question_mark};
	my $who        = $factoid->{who};
	my $crop       = 0;
	my $nick       = $factoid->{nick};
	my $public     = $factoid->{public};

$self->log(9, "Entering the is_statment loop");

$in =~ s/\\(\S+)/\#$1\#/g;

# switch person

$in =~ s/(^|\s)i am /$1$who is /i; 
$in =~ s/(^|\s)my /$1$who\'s /ig;
$in =~ s/(^|\s)your /$1$nick\'s /ig;

if ($addressed) {
$in =~ s/(^|\s)you are /$1$nick is /i;
}


# don't want to complain if it's new but negative
$factoid->{'correction_plausible'} = 1	if($in =~ s/^no,\s+//i);



my($theType);
my($lhs, $mhs, $rhs);	# left hand side, uh.. middlehand side...


# check if we need to be addressed and if we are
if ($factoid->{message}->context->{addressing} && !$addressed) {
return;
}

# prefix www with http:// and ftp with ftp://
$in =~ s/ www\./ http:\/\/www\./ig;	
$in =~ s/ ftp\./ ftp:\/\/ftp\./ig;

# look for a "type nugget". this should be externalized.
$theType = "";
$theType = "mailto" if ($in =~ /\bmailto:.+\@.+\..{2,}/i);
$theType = "mailto" if ($in =~ s/\b(\S+\@\S+\.\S{2,})/mailto:$1/gi);
$in =~ s/(mailto:)+/mailto:/g;

$theType = "about" if ($in =~ /\babout:/i);
$theType = 'afp' if ($in =~ /\bafp:/);
$theType = 'file' if ($in =~ /\bfile:/);
$theType = 'palace' if ($in =~ /\bpalace:/);
$theType = 'phoneto' if ($in =~ /\bphone(to)?:/);
if ($in =~ /\b(news|http|ftp|gopher|telnet):\s*\/\/[\-\w]+(\.[\-\w]+)+/) {
$theType = $1;
}

# FIX - removed a bunch of URL accepting stuff

foreach my $item (qw(is are)) {	# check for verb
if ($in =~ /(^|\s)$item(\s|$)/i) {
my ($lhs, $mhs, $rhs) = ($`, $&, $');
$lhs =~ tr/A-Z/a-z/;
$lhs =~ s/^\s*(the|da|an?)\s+//i; # discard article
$lhs =~ s/^\s*(.*?)\s*$/$1/;
$mhs =~ s/^\s*(.*?)\s*$/$1/;
$rhs =~ s/^\s*(.*?)\s*$/$1/;

# note : prevent access to globals in the eval
return '' unless ($lhs and $rhs);

my $maxkey = 50;
return "The key is too long (> $maxkey chars)." 
if (length($lhs) > $maxkey);

if (length($rhs) > 410) {
if ($public) {  
if ($addressed) {
if (rand() > 0.5) {
$factoid->{message}->say("that entry is too long, ".$who);
} else {
$factoid->{message}->say("i'm sorry, but that entry is too long, $who");
} 
}	 
} else {
$factoid->{message}->say($who, "The text is too long");
}
return '';
}

return undef if ($lhs eq 'NOREPLY');

my $failed = 0;
$lhs =~ /^(who|what|when|where|why|how)$/ and $failed++;

if (!$failed and !$addressed) {
# the arsenal of things to ignore if we aren't addressed directly

$lhs =~ /^(who|what|when|where|why|how|it) /i and $failed++;
$lhs =~ /^(this|that|these|those|they|you) /i and $failed++;
$lhs =~ /^(every(one|body)|we) /i and $failed++;

$lhs =~ /^\s*\*/ and $failed++; # server message
$lhs =~ /^\s*<+[-=]+/ and $failed++; # <--- arrows
$lhs =~ /^[\[<\(]\w+[\]>\)]/ and $failed++; # [nick] from bots
$lhs =~ /^heya?,? / and $failed++; # greetings
$lhs =~ /^\s*th(is|at|ere|ese|ose|ey)/i and $failed++; # contextless
$lhs =~ /^\s*it\'?s?\W/i and $failed++; # contextless clitic
$lhs =~ /^\s*if /i and $failed++; # hypothetical
$lhs =~ /^\s*how\W/i and $failed++; # too much trouble for now
$lhs =~ /^\s*why\W/i and $failed++; # too much trouble for now
$lhs =~ /^\s*h(is|er) /i and $failed++; # her name is
$lhs =~ /^\s*\D[\d\w]*\.{2,}/ and $failed++; # x...
$lhs =~ /^\s*so is/i and $failed++; # so is (no referent)
$lhs =~ /^\s*s+o+r+[ye]+\b/i and $failed++; # sorry
$lhs =~ /^\s*supposedly/i and $failed++;
$lhs =~ /^all / and $failed++; # all you have to do, all you guys...
} elsif (!$failed and $addressed) {
# things to skip if we ARE addressed
}

if ($failed) {
$self->log(9, "Ignoring $in as ambiguous when unaddressed");
return 0;
}

#&status("statement: <$who> $message");

$lhs =~ s/\#(\S+)\#/$1/g;
# Avi++
$rhs =~ s/\#\|\#/\\\|/g;
$rhs =~ s/\#(\S+)\#/$1/g;

$lhs =~ s/\?+\s*$//; # strip the ? off the key
return $self->update($factoid, $lhs, $mhs, $rhs);

#return 0 if ($lhs eq 'NOREPLY');

last;
}
}

$lhs;
}

sub update {
    my($self, $factoid, $lhs, $verb, $rhs) = @_;
    my($reply) = $lhs;

	my $msgType    = $factoid->{public} ? 'public' : 'private';
	my $in         = $factoid->{text};
	my $msgFilter  = $factoid->{filter};
	my $addressed  = $factoid->{addressed};
	my $finalQMark = $factoid->{question_mark};
	my $who        = $factoid->{who};
	my $crop       = 0;
	my $nick       = $factoid->{nick};
	my $public     = $factoid->{public};
	my $correction_plausible = $factoid->{'correction_plausible'};

	my $exists = 0;
	my $also = 0;

    $lhs =~ s/^\s*=?//;		# handle dcc =oznoid and stuff
    $lhs =~ s/^i (heard|think) //i;
    $lhs =~ s/^some(one|1|body) said //i;
    $lhs =~ s/ +/ /g;

    # this really needs cleaning up
    if ($verb eq "is") {
	$also = ($rhs =~ s/^also //i);

	my $also_or = ($also and $rhs =~ s/\s*\|\s*//);


	if ($exists = $self->get( $lhs, "is" )) { 
	    chomp $exists;

	    if ($exists eq $rhs and not $main::googling) {

				$factoid->{message}->say("I already had it that way, $who");
				return 1;
		
	    }

	   my $skipReply = 0;	 
	    if ($also) {
		if ($also_or) {
		    $rhs = $exists . '|'.$rhs;
		} else {
		    if ($exists ne $rhs) {
			$rhs = $exists .' or '.$rhs;
		    }
		}
		    if (length($rhs) > 410) {
			if ($msgType =~ /public/) {
			    if ($addressed) {
				if (rand() > 0.5) {
				    &performSay("that is too long, ".$who);
				} else {
				    &performSay("i'm sorry, but that's too long, $who");
				} 
			    }
			} else {
			    &msg($who, "The text is too long");
			}
			return 'NOREPLY';
		}
		if ($msgType =~ /public/) {
		    $factoid->{message}->say("okay, $who.");
		} else {
		    $factoid->{message}->say("okay.");
		}

		&status("update: <$who> \'$lhs =is=> $rhs\'; was \'$exists\'");
		$self->set("is", $lhs, $rhs);
	    } else {		# not "also"
		if (($correction_plausible == 0) && ($exists ne $rhs)) {
		    if ($addressed) {
			if (not $main::googling) {
			    if ($msgType =~ /public/) {
				&performSay("...but $lhs is $exists...");
			    } else { 
				&msg($who, "...but $lhs is $exists..");
			    }
			    &status("FAILED update: <$who> \'$lhs =$verb=> $rhs\'");
			}
		    } else {
			&status("FAILED update: <$who> \'$lhs =$verb=> $rhs\' (not addressed, no reply)");
			# we were not addressed, so just
			# ignore it.  
			return 'NOREPLY';
		    }
		} else {
#		    if (IsFlag("m") ne "m") {
#			performReply("You have no access to change factoids");
#			return 'NOREPLY';
#		    }
		    if ($msgType =~ /public/) {
			$factoid->{message}->say("okay, $who.");
		    } else {
			$factoid->{message}->say("okay.");
		    }
		    &status("update: <$who> '$lhs =is=> $rhs\'; was \'$exists\'");
		    $self->set("is", $lhs, $rhs);
		}
	    }
	    $reply = 'NOREPLY';

	} else {
	    &status("enter: <$who> $lhs =$verb=> $rhs");
	 
	    $self->set("is", $lhs, $rhs);
	}

    } else {			# 'is' failed
	if ($verb eq "are") {
	    $also = ($rhs =~ s/^also //i);
	    if ($exists = $self->get($lhs, 'are')) {
		if ($also) {	
		    if ($exists ne $rhs) {
			$rhs = $exists .' or '.$rhs;
		    }
		    if ($msgType =~ /public/) {
			&performSay("okay, $who.") unless $rhs eq $exists;
		    } else {
			&msg($who, "okay.");
		    }
		    &status("update: <$who> \'$lhs =are=> $rhs\'; was \'$exists\'");
		    $self->set("are", $lhs, $rhs);
		} else {	# not 'also'
		    if (($correction_plausible == 0) && ($exists ne $rhs)) {
			if ($addressed) {
			    &status("FAILED update: \'$lhs =$verb=> $rhs\'");
			    if ($msgType =~ /public/) {
				&performSay("...but $lhs is $exists...");
			    } else { 
				&msg($who, "...but $lhs is $exists..");
			    }
			} else {
			    &status("FAILED update: $lhs $verb $rhs (not addressed, no reply)");
			    # we were not addressed, so just
			    # ignore it.  
			    return 'NOREPLY';
			}
			if ($msgType =~ /public/) {
			    &performSay("...but $lhs are $exists...");
			} else {
			    &msg($who, "...but $lhs are $exists...");
			}
		    } else {
			if ($msgType =~ /public/) {
			    &performSay("okay, $who.") unless $rhs eq $exists;
			} else {
			    &msg($who, "okay.") 
				#unless grep $_ eq $who, split /\s+/, $param{friendlyBots};
			}
			&status("update: <$who> \'$lhs =are=> $rhs\'; was \'$exists\'");
			$self->set("are", $lhs, $rhs);
		    }
		    $reply = 'NOREPLY';
		} 
	    } else {
		&status("enter: <$who> $lhs =are=> $rhs");
		$self->set("are", $lhs, $rhs);
	    }
	}
    }

    $lhs .= " $verb $rhs";
    if ($reply ne 'NOREPLY') {	
	$reply = $lhs;
    }

    return $reply;
}

sub status {}

1;


