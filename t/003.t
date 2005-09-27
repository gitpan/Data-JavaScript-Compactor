# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-JavaScript-Compactor.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

plan tests => 17;

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

my %t_out = (
    ### replace_listeral_strings
    de_string   => qq|


    

    var test = "__0__"; 

var x = "__1__" + '__2__' + tset + '__3__'+

'__4__';

    var foo = '__5__'; var test = "__6__";

function blah (asdf) {
    while (x = el[ e++ ]) {
        y++;
    }
};
var x;   


|,
    ### replace_white_space
    de_space    => qq|




var test = "__0__";

var x = "__1__" + '__2__' + tset + '__3__'+

'__4__';

var foo = '__5__'; var test = "__6__";

function blah (asdf) {
while (x = el[ e++ ]) {
y++;
}
};
var x;|,
    ### remove_blank_lines
    de_line => qq|var test = "__0__";
var x = "__1__" + '__2__' + tset + '__3__'+
'__4__';
var foo = '__5__'; var test = "__6__";
function blah (asdf) {
while (x = el[ e++ ]) {
y++;
}
};
var x;|,
    ### combine_concats
    de_concat   => qq|var test = "__0__";
var x = "__1__" + '__2__' + tset + '__3____4__';
var foo = '__5__'; var test = "__6__";
function blah (asdf) {
while (x = el[ e++ ]) {
y++;
}
};
var x;|,
    ### join_all
    joinall => qq|var test = "__0__"; var x = "__1__" + '__2__' + tset + '__3____4__'; var foo = '__5__'; var test = "__6__"; function blah (asdf) { while (x = el[ e++ ]) { y++; } }; var x;|,
    ### replace_extra_whitespace
    de_space2   => qq|var test="__0__";var x="__1__"+'__2__'+tset+'__3____4__';var foo='__5__';var test="__6__";function blah(asdf){while(x=el[e++]){y++;}};var x;|,
    ### restore_literal_strings
    re_string   => qq|var test="asfd asfd";var x="blah"+'asdf'+tset+'xxasdf';var foo='bar';var test="xxx";function blah(asdf){while(x=el[e++]){y++;}};var x;|,
    ### replace_final_eol
    re_eol  => qq|var test="asfd asfd";var x="blah"+'asdf'+tset+'xxasdf';var foo='bar';var test="xxx";function blah(asdf){while(x=el[e++]){y++;}};var x;|,
    );


my $djc = Data::JavaScript::Compactor->new();
ok( defined $djc, 1, 'new() did not return anything' );
ok( $djc->isa('Data::JavaScript::Compactor') );

$djc->data($test_data);
my $t = $djc->data();
ok( $t, $test_data, "set data to be processed" );

my $eol = $djc->determine_line_ending();
ok( $eol, "\n", "figured out EOL character" );
$eol = $djc->eol_char();
ok( $eol, "\n", "fetching EOL character" );
$eol = $djc->eol_char("xxx");
ok( $eol, "xxx", "setting EOL character" );
$eol = $djc->eol_char("\n");
ok( $eol, "\n", "re-setting EOL character" );

$t = $djc->data();
ok( $t, $test_data, "test data has not changed" );

$djc->replace_listeral_strings();
$t = $djc->data();
ok( $t, $t_out{de_string}, "replace_listeral_strings" );

$djc->replace_white_space();
$t = $djc->data();
ok( $t, $t_out{de_space}, "replace_white_space" );

$djc->remove_blank_lines();
$t = $djc->data();
ok( $t, $t_out{de_line}, "remove_blank_lines" );

$djc->combine_concats();
$t = $djc->data();
ok( $t, $t_out{de_concat}, "combine_concats" );

$djc->join_all();
$t = $djc->data();
ok( $t, $t_out{joinall}, "join_all" );

$djc->replace_extra_whitespace();
$t = $djc->data();
ok( $t, $t_out{de_space2}, "replace_extra_whitespace" );

$djc->restore_literal_strings();
$t = $djc->data();
ok( $t, $t_out{re_string}, "restore_literal_strings" );

$djc->replace_final_eol();
$t = $djc->data();
ok( $t, $t_out{re_eol}, "replace_final_eol" );



