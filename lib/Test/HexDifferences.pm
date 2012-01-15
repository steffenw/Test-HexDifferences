package Test::HexDifferences; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.002';

use Test::Differences qw(eq_or_diff);
use Test::HexDifferences::HexDump qw(hex_dump);
use Perl6::Export::Attrs;

sub eq_or_dump_diff :Export(:DEFAULT) {
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
            hex_dump($got, $attr_ref),
            hex_dump($expected, $attr_ref),
        ),
        @more,
    );
}

sub dumped_eq_dump_or_diff :Export(:DEFAULT) {
    my ($got, $expected, @more) = @_;

    my $attr_ref
        = ( @more && ref $more[0] eq 'HASH' )
        ? shift @more
        : ();

    return eq_or_diff(
        defined $got
            ? hex_dump($got, $attr_ref)
            : $got,
        $expected,
        @more,
    );
}

# $Id$

1;

__END__

=head1 NAME

Test::HexDifferences - Test binary as hexadecimal string

=head1 VERSION

0.002

=head1 SYNOPSIS

    use Test::HexDifferences;

    eq_or_dump_diff(
        $got,
        $expected,
    );

    eq_or_dump_diff(
        $got,
        $expected,
        $test_name,
    );

    eq_or_dump_diff(
        $got,
        $expected,
        {
            address => $start_address,
            format  => "%a : %4C : %d\n",
        }
        $test_name,
    );

If C<$got> or C<$expected> is C<undef> or a reference,
the hexadecimal formatter is off.
Then C<eq_or_dump_diff> is the same like C<eq_or_diff> of
L<Test::Differences|Test::Differences>.

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
    );

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
        $test_name,
    );

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
        {
            address => $start_address,
            format  => "%a : %4C : %d\n",
        }
        $test_name,
    );

See L<Test::HexDifferences::HexDump|Test::HexDifferences::HexDump>
for the format description.

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

The are some special cases for testing binary data.

=over

=item * The ascii format is not good for e.g. a length byte 0x41 displayed as A.

=item * Multibyte values are better shown as 1 value.

=item * Structured binary e.g. 2 byte length followed by bytes better are shown as it is.

=item * Compare 2 binary or 1 binary and a dump.

=back

=head1 SUBROUTINES/METHODS

=head2 subroutine eq_or_dump_diff

    eq_or_dump_diff(
        $got_value,
        $expected_value,
        {                                      # optional hash reference
            address => $display_start_address, # optional
            format  => $format_string,         # optional
        }
        $test_name,                            # optional
    );

=head2 subroutine dumped_eq_dump_or_diff

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
        {                                      # optional hash reference
            address => $display_start_address, # optional
            format  => $format_string,         # optional
        }
        $test_name,                            # optional
    );

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Test::Differences|Test::Differences>

L<Test::HexDifferences::HexDump|Test::HexDifferences::HexDump>

L<Perl6::Export::Attrs|Perl6::Export::Attrs>

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Test::Differences|Test::Differences>

L<Test::HexDifferences::HexDump|Test::HexDifferences::HexDump>

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
