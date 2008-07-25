=head2 000_integrity_010_pod

Uses L<Test::Pod> to check for POD errors in all modules in the build
directory.

=cut

  use strict;
  use warnings;

  use Test::More;

# First we check if we have everything we need...

  eval "use Test::Pod 1.00";
  plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

# We do, so let's go!

  all_pod_files_ok();
