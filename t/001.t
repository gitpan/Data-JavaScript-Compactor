# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-JavaScript-Compactor.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

plan tests => 1;

use Data::JavaScript::Compactor;
ok(1); # If we made it this far, we're ok.


