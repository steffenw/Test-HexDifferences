package Test::HexDifferences;

use strict;
use warnings;

our $VERSION = '0.001';

use Carp qw(cluck);
use Perl6::Export::Attrs;
use Test::Differences qw(eq_or_diff);

my $default_format = "%a : %8C : '%d'\n";

sub eq_or_hex_diff :Export(:DEFAULT) {
    my ($got, $expected, @more) = @_;

    my $attr_ref
        = ( @more && ref $more[0] eq 'HASH' )
        ? shift @more
        : ();

    my $is_not_a_string
       = ! defined $got
       || ! defined $expected
       || ref $got
       || ref $expected;

    return eq_or_diff(
        $is_not_a_string
        ? (
            $got,
            $expected,
        )
        : (
            _format(
                $got,
                $attr_ref->{address} || 0,
                $attr_ref->{format}  || "$default_format%*x",
            ),
            1 || $attr_ref->{is_formatted}
            ? $expected
            : _format(
                $expected,
                $attr_ref->{address} || 0,
                $attr_ref->{format}  || "$default_format%*x",
            ),
        ),
        @more,
    );
}

sub _format {
    my ($data, $address, $format) = @_;

    my $output = q{};
    BLOCK:
    while ( length $data ) {
        my $format_block = _format_block(\$format);
        while ( length $format_block ) {
            $output .= _format_items( \$data, \$address, \$format_block );
        }
    }

    return $output;
}

sub _format_block {
    my $format_ref = shift;

    my $format;
    my $is_match = ${$format_ref} =~ s{
        \A
          ( .*? [^%] )           # format of the block
          % ( [1-9]\d* | [*] ) x # repetition factor
    } {
        my $new_count = $2 eq q{*} ? q{*} : $2 - 1;
        $format = $1;
        $new_count
        ? "$1\%${new_count}x"
        : q{};
    }xmse;
    if ( ! $is_match ) {
        cluck
            "Unknown format at % ... x in ${$format_ref}.",
            ' Falling back to default format';
        return $default_format;
    }

    return $format;
}

sub _format_items {
    my ($data_ref, $address_ref, $format_ref) = @_;

    my $output = q{};
    my $data_length = 0;
    RUN: {
        # % written as %%
        ${$format_ref} =~ s{
            \A % ( % )
        } {
            do {
                $output .= $1;
                q{};
            }
        }xmse and redo RUN;
        # \n written as %\n will be ignored
        ${$format_ref} =~ s{
            \A % [\n]
        }{}xms and redo RUN;
        # address
        ${$format_ref} =~ s{
            \A % ( [48]? ) a
        } {
            do {
                my $length = $1 || 4;
                $output .= sprintf "%0${length}X", ${$address_ref};
                q{};
            }
        }xmse and redo RUN;
        # words
        ${$format_ref} =~ s{
            \A % ( \d+ ) C
        } {
            do {
                $output .= join q{ }, map {
                    ( length ${$data_ref} >= $data_length + 1 )
                    ? do {
                        my $hex = sprintf
                            '%02X',
                            unpack
                                'C',
                                substr ${$data_ref}, $data_length, 1;
                        $data_length += 1;
                        ${$address_ref} += 1;
                        $hex;
                    }
                    : q{ } x 2;
                } 1 .. $1;
                q{};
            }
        }xmse and redo RUN;
        # display ascii
        ${$format_ref} =~ s{
            \A %d
        } {
            do {
                my $data = substr ${$data_ref}, 0, $data_length;
                $data =~ s{
                    ( [\x20-\xFE] )
                    | .
                } {
                    defined $1 ? $1 : q{.}
                }xmsge;
                $output .= $data;
                q{};
            }
        }xmse and redo RUN;
        # display any other char
        ${$format_ref} =~ s{
          \A (.)
        } {
            do {
                $output .= $1;
                q{};
            }
        }xmse and redo RUN;
        if ($data_length) {
            # clear already displayed data
            substr ${$data_ref}, 0, $data_length, q{};
            $data_length = 0;
        }
    }

    return $output;
}

# $Id$

1;

__END__

=head1 NAME

Test::HexDifferences - Test strings as hexadecimal data

=head1 VERSION

0.001

=head1 SYNOPSIS

    use Test::HexDifferences;

    eq_or_hex_diff(
        $got,
        $expected,
    );

    eq_or_hex_diff(
        $got,
        $expected,
        $test_name,
    );

    eq_or_hex_diff(
        $got,
        $expected,
        {
            address => $start_address,
            format  => "%a : %8C : '%d'\n",
        }
        $test_name,
    );

If C<$got> or C<$expected> is C<undef> or a reference,
the hexadecimal formatter is off.
Then C<eq_or_hex_diff> is the same like C<eq_or_diff> of 
L<Test::Differences|Test::Differences>.

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 subroutine eq_or_hex_diff

    eq_or_hex_diff(
        $got_data,
        $expected_data,
        {
            address => $display_start_address,
            format  => $format_string,
        }
        $test_name,
    );

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Carp|Carp>

L<Perl6::Export::Attrs|Perl6::Export::Attrs>

L<Test::Differences|Test::Differences>

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Test::Differences|Test::Differences>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
