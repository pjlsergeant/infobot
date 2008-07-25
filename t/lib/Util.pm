package t::lib::Util;

  use strict;
  use warnings;

	use Infobot::Base;
  use File::Basename;

# This is a naive way of finding all packages in blib...
# Naive because it assumes each file contains one package only, and that that
# package is determinable from the filename alone...

  sub find_packages {

  # Find any loaded modules in this path...

    my %seen;
    my $class = 'blib/lib/';

    my @found_paths =

    # Read the following in reverse, obviously :-)

      grep { !$seen{$_}++, }            # We only want each path once ...
      map  { s!/!::!g; $_ }             # Make it look like a package name...
      map  { s!\.pm$!!g; $_ }           # Remove trailing .pm
      map  { s/.*$class//g; $_ }        # Remove any nasty path stuff
      map  { s/\s+$//g; $_ }            # That adds newlines to the end, so kill 'em
      `find blib -name '*\.pm'`;          # Look for files...

    return @found_paths;

  }

1;
