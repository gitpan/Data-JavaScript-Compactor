
package Data::JavaScript::Compactor;

=head1 NAME

Data::JavaScript::Compactor - This module provides a means to compact javascript.

=head1 SYNOPSIS

 use Data::JavaScript::Compactor;
 my $compacted = Data::JavaScript::Compactor->compact( $javascript )
    or die $Data::JavaScript::Compactor::err_msg;

# OR, to just do a few steps #

 my $c = Data::JavaScript::Compactor->new();
 $c->data( $javascript );
 $c->replace_listeral_strings();
 $c->replace_white_space();
 my $new = $c->data();

=head1 DESCRIPTION

This module provides methods to compact javascript source down to just what is needed. It can remove all comments, put everything on one line (semi-)safely, and remove extra whitespace.

=head2 EXPORT

None by default.

"compcat" may be exported via "use Data::JavaScript::Compactor qw(compact);"

=head1 METHODS

=head2 B<Data::JavaScript::Compactor-E<gt>compact($js)>

Class method. This is a wrapper around all methods in here, to allow you to do all compacting operations in one call.

     my $compacted = Data::JavaScript::Compactor->compact( $javascript );

=head2 B<Data::JavaScript::Compactor-E<gt>new()>

Constructor. Currently takes no options. Returns Data::JavaScript::Compactor object.

=head2 B<$djc-E<gt>data($js)>

If the option C<$js> is passed in, this sets the javascript that will be worked on.

If not passed in, this returns the javascript in whatever state it happens to be in (so you can step through, and pull the data out at any time).

=head2 B<$djc-E<gt>determine_line_ending()>

Method to automatically determine the line ending character in the source data.

=head2 B<$djc-E<gt>eol_char("\n")>

Method to set/override the line ending character which will be used to parse/join lines. Set to "\r\n" if you are working on a DOS / Windows formatted file.

=head2 B<$djc-E<gt>replace_listeral_strings()>

Finds all string literals (eg. things in quotes) and replaces them with tokens of the form "__N__" where N is the occurrance number in the file. The strings are stored inside the object so they may be resotred later.

This should be called before any of the destructive methods are used, in order to get these out of the way.

=head2 B<$djc-E<gt>replace_white_space()>

Per each line:

=over

=item * Removes all begining of line whitespace.

=item * Removes all end of line whitespace.

=item * Combined all series of whitespace into one space character (eg. s/\s+/ /g)

=back

=head2 B<$djc-E<gt>remove_blank_lines()>

...does what it says.

=head2 B<$djc-E<gt>combine_concats()>

Removes any string literal concatenations. Eg.

    "bob and " +   "sam " + someVar;

Becomes:

    "bob and sam " + someVar

=head2 B<$djc-E<gt>join_all()>

Puts everything on one line.

=head2 B<$djc-E<gt>replace_extra_whitespace()>

This removes any excess whitespace. Eg.

    if (someVar = "foo") {

Becomes:

    if(someVar="foo"){

=head2 B<$djc-E<gt>restore_literal_strings()>

All string literals that were extracted with C<$djc-E<gt>replace_listeral_strings()> are restored. String literals retain all spacing and extra lines and such.

=head2 B<$djc-E<gt>replace_final_eol()>

Prior to this being called, the end of line is not terminated with a new line character. This adds one of whatever is set in C<$djc-E<gt>eol_char()>.

=head1 NOTES

The following should only cause an issue in rare and odd situations... If the input file is in dos format (line termination with "\r\n" (ie. CR LF / Carriage return Line feed)), we'll attempt to make the output the same. If you have a mixture of embeded "\r\n" and "\n" characters (not escaped, those are still safe) then this script may get confused and make them all conform to whatever is first seen in the file.

=head1 TODO

Add in a way to retain some comments (eg. so we can retain copyright notices in javascript files). Something like the following:

    my $compact = Data::JavaScript::Compactor->compact( $javascript, keep_comments_matching => qr/copyright/i );

=head1 BUGS

There are a few bugs, which may rear their head in some minor situations.

=over

=item Statements not terminated by semi-colon.

Javascript statement that are NOT terminated by a semi-colon (";") may break once compacted, as they will be put on the same line as the following statement. In many cases, this won't be a problem, but it could cause an issue. Ex.

    i = 5.4
    j = 42

The above would become "i=5.4 j=42", and would generate an error along the lines of "expected ':' before statement".

=item Ambiguous operator precidence

Operator precidence may get screwed up in ambiguous statements. Eg. "x = y + ++b;" will be compacted into "x=y+++b;", which means something different.

=back

Still looking for them. If you find some, let us know.

=head1 SEE ALSO

The order of steps to compact the file were initially based upon the "JavaScript Crunchinator" (http://www.brainjar.com).

=head1 AUTHOR

Joshua I. Miller <jmiller@puriifeddata.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 by CallTech Communications, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

use 5.00503;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw( compact ) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( );

$VERSION = '0.02';

sub compact
{
    my $this = shift;

    # compact() can be used as a class method or instance method
    unless (ref $this)
    {
        $this = $this->new();
    }

    {
        my $data = (ref($_[0]) eq 'SCALAR') ? ${(shift)} : shift;
        $this->data($data);
    }
    my %opts = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

    # determine line ending
    print STDERR "Determining line ending format (LF || CRLF)...\n" if $opts{DEBUG};
    $this->determine_line_ending();

    # replace literal strings
    print STDERR "Replacing literal strings...\n" if $opts{DEBUG};
    $this->replace_listeral_strings();

    # replace white space
    print STDERR "Replacing white space...\n" if $opts{DEBUG};
    $this->replace_white_space();

    # remove blank lines
    print STDERR "Removing blank lines...\n" if $opts{DEBUG};
    $this->remove_blank_lines();

    # combine literal string concatenators
    print STDERR "Combining literal string concatenators...\n" if $opts{DEBUG};
    $this->combine_concats();

    # join all lines
    print STDERR "Joining all lines...\n" if $opts{DEBUG};
    $this->join_all();

    # replace extra extra whitespace
    print STDERR "Replacing extra extra whitespace...\n" if $opts{DEBUG};
    $this->replace_extra_whitespace();

    # restore literals
    print STDERR "Restoring all literal strings...\n" if $opts{DEBUG};
    $this->restore_literal_strings();

    # replace final EOL
    print STDERR "Replace final EOL...\n" if $opts{DEBUG};
    $this->replace_final_eol();

    return $this->data;
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $this = {
        strings => [ ],
        data    => '',
        eol     => "\n",
        };
    bless $this, $class;

    return $this;
}

sub data
{
    my $this = shift;
    if ($_[0]) {
        $this->{data} = $_[0];
    } else {
        return $this->{data};
    }
}

sub eol_char
{
    my $this = shift;
    if ($_[0]) {
        $this->{eol} = $_[0];
    } else {
        return $this->{eol};
    }
}

sub determine_line_ending
{
    my $this = shift;

    # Where is the first LF character?
    my $lf_position = index($this->data, "\n");
    if ($lf_position == -1)
    {   # not found, set to default, cause it won't (shouldn't) matter
        $this->eol_char("\n");
    } else {
        if ($lf_position == 0)
        {   # found at first char, so there is no prior character to observe
            $this->eol_char("\n");
        } else {
            # Is the character immediately before it a CR?
            my $test_cr = substr($this->data, ($lf_position -1),1);
            if ($test_cr eq "\r")
            {
                $this->eol_char("\r\n");
            } else {
                $this->eol_char("\n");
            }
        }
    }
}

sub replace_listeral_strings
{
    my $this = shift;

    # where we'll store the literals
    my $strings = $this->{strings};

    my ($escaped, $quoteChar, $inQuote);

    my $literal = ""; # literal strings we're building
    my $t = ""; # replacement text

    my @lines = split(/\r?\n/, $this->data); # dos or unix... output is unix
    # step through each line
    LINE: for (my $i=0; $i<@lines; $i++)
    {
        # step through each character
        LINE_CHAR: for (my $j=0; $j<length($lines[$i]); $j++)
        {
            my $c  = substr($lines[$i],$j,1);
            my $c2 = substr($lines[$i],$j,2);
            # look for start of string (if not in one)
            if (! $inQuote)
            {
                if ($c eq '"' || $c eq "'")
                {
                    $inQuote = 1;
                    $escaped = 0;
                    $quoteChar = $c;
                    $t .= $c;
                    $literal = '';

                } elsif ($c2 eq "//") {
                    $t .= $this->eol_char();
                    next LINE;
                } elsif ($c2 eq "/*") {
                    my $found_end = 0;
                    COMM_SEARCH1: for (my $k=($j+2); $k<length($lines[$i]); $k++)
                    {
                        my $end = substr($lines[$i],$k,2);
                        if ($end eq "*/") {
                            $j = $k+2;
                            $found_end = 1;
                            next LINE_CHAR;
                        }
                    }

                    if (! $found_end)
                    {
                        for (my $l=($i+1); $l<@lines; $l++)
                        {
                            for (my $k=0; $k<length($lines[$l]); $k++)
                            {
                                my $end = substr($lines[$l],$k,2);
                                if ($end eq "*/") {
                                    $i = $l;
                                    $j = $k+2;
                                    $found_end = 1;
                                    next LINE_CHAR;
                                }
                            }
                        }
                    }
                    if (! $found_end)
                    {
                        die "Unterminated /* */ style comment found around line[$i]\n";
                    }
                } else {
                    $t .= $c;
                }

            # else we're in a quote
            } else {
                if ($c eq $quoteChar && !$escaped)
                {
                    $inQuote = 0;
                    my $key_num = scalar(@{$strings});
                    $t .= "__".$key_num."__";
                    $t .= $c;
                    push(@{$strings}, $literal);

                } elsif ($c eq "\\" && !$escaped) {
                    $escaped = 1;
                    $literal .= $c;
                } else {
                    $escaped = 0;
                    $literal .= $c;
                }
            }
        }
        if ($inQuote) {
            $literal .= $this->eol_char();
        } else {
            $t .= $this->eol_char();
        }
    }

    $this->data($t);
}

sub replace_white_space
{
    my $this = shift;

    my @lines = split(/\r?\n/, $this->data);

    # condense white space
    foreach (@lines)
    {
        s/\s+/\ /g;
        s/^\s//;
        s/\s$//;
    }

    $this->data( join($this->eol_char(), @lines) );
}

sub remove_blank_lines
{
    my $this = shift;

    my @lines = split(/\r?\n/, $this->data);
    my @new_lines = ();
    foreach (@lines)
    {
        next if /^\s*$/;
        push(@new_lines,$_);

    }

    $this->data( join($this->eol_char(), @new_lines) );
}

sub combine_concats
{
    my $this = shift;

    my $data = $this->data;
    # TODO: currently, we only concat two literals if 
    #       they both use the same quote style. Eg.
    #           this: "foo " + "bar" == "foo bar"
    #           not : "foo " + 'bar' == "foo "+'bar'
    # this just makes things easier to do w/ a regexp, but we should be
    # able to do the second form as well (can't w/out lookahead and
    # lookbehind searches).
    $data =~ s/(['"])\s?\+\s?\1//g;
    $this->data($data);
}

sub join_all
{
    my $this = shift;

    my $data = $this->data;
    $this->data( join(" ", split(/\r?\n/, $data) ) );
}

sub replace_extra_whitespace
{
    my $this = shift;

    my $data = $this->data;
    # remove unneccessary white space around operators, braces, parenthesis
    $data =~ s/\s([\x21\x25\x26\x28\x29\x2a\x2b\x2c\x2d\x2f\x3a\x3b\x3c\x3d\x3e\x3f\x5b\x5d\x5c\x7b\x7c\x7d\x7e])/$1/g;
    $data =~ s/([\x21\x25\x26\x28\x29\x2a\x2b\x2c\x2d\x2f\x3a\x3b\x3c\x3d\x3e\x3f\x5b\x5d\x5c\x7b\x7c\x7d\x7e])\s/$1/g;
    $this->data($data);
}

sub restore_literal_strings
{
    my $this = shift;

    # where we'll store the literals
    my $strings = $this->{strings};

    my $data = $this->data;
    # replace each of the strings
    for (my $i=0; $i<@{$strings}; $i++)
    {
        my $string = $strings->[$i];
        $data =~ s/__$i\__/$string/g;
    }
    $this->data($data);
}

sub replace_final_eol
{
    my $this = shift;

    my $eol  = $this->eol_char();
    my $data = $this->data;
    $data =~ s/\r?\n$/$eol/;
    $this->data($data);
}



1;
