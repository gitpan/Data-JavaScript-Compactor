# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-JavaScript-Compactor.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

plan tests => 2;

use Data::JavaScript::Compactor;
ok(1); # If we made it this far, we're ok.

my $test_data = <<JAVASCRIPT;

/* some single line comment */

    // another single comment

    var test = "asfd asfd"; // comment 3

var x = "blah" + 'asdf' + tset + 'xx'+

'asdf';

    var foo = 'bar'; /* embeded comment */ var test = "xxx";

function blah (asdf) {
    while (x = el[ e++ ]) {
        y++;
    }
};
var x;   
// preceding line has ends in extra spaces up to
// here ^

JAVASCRIPT

my $test_output = qq|var test="asfd asfd";var x="blah"+'asdf'+tset+'xxasdf';var foo='bar';var test="xxx";function blah(asdf){while(x=el[e++]){y++;}};var x;|;

my $c = Data::JavaScript::Compactor->compact($test_data);
ok( $c, $test_output, "overall final result test" );


