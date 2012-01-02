package Test::HexDifferences::FormatHex;

use strict;
use warnings;

our $VERSION = '0.001';

use Carp qw(cluck);
use Perl6::Export::Attrs;

my $default_format = "%a : %4C : '%d'\n";

sub format_hex :Export(:DEFAULT) {
    my ($data, $attr_ref) = @_;

    defined $data
        or return $data;
    ref $data
        and return $data;
    $attr_ref
        = ref $attr_ref eq 'HASH'
        ? $attr_ref
        : {};
    my $format  = $attr_ref->{format}  || "$default_format%*x";
    my $address = $attr_ref->{address} || 0;

    my $output = q{};
    BLOCK:
    while ( length $data ) {
        my $format_block = _next_format(\$format);
        while ( length $format_block ) {
            $output .= _format_items( \$data, \$format_block, \$address );
        }
    }

    return $output;
}

sub _next_format {
    my $format_ref = shift;

    my $format;
    my $is_match = ${$format_ref} =~ s{
        \A
          ( .*? [^%] )            # format of the block
          % ( [1-9] \d* | [*] ) x # repetition factor
    } {
        my $new_count = $2 eq q{*} ? q{*} : $2 - 1;
        $format = $1;
        $new_count
        ? "$1\%${new_count}x"
        : q{};
    }xmse;
    if ( ! $is_match ) {
        cluck
            qq{Unknown format at %[repetition factor]x in "${$format_ref}".},
            ' Falling back to default format';
        ${$format_ref} = "$default_format%*x";
        return $default_format;
    }

    return $format;
}

sub _format_items {
    my ($data_ref, $format_ref, $address_ref) = @_;

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
        _format_address(\$output, $format_ref, $address_ref)
            and redo RUN;
        # words
        _format_word(\$output, $data_ref, \$data_length, $format_ref, $address_ref)
            and redo RUN;
        # display ascii
        _format_ascii(\$output, $data_ref, \$data_length, $format_ref)
            and redo RUN;
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

sub _format_address {
    my ($output_ref, $format_ref, $address_ref) = @_;

    return ${$format_ref} =~ s{
        \A % ( [48]? ) a
    } {
        do {
            my $length = $1 || 4;
            ${$output_ref} .= sprintf "%0${length}X", ${$address_ref};
            q{};
        }
    }xmse;
}

my %byte_length_of = (
    'C'  => 1, # unsigned char
    'S'  => 2, # unsigned 16-bit
    'L'  => 4, # unsigned 32-bit
    'L<' => 4, # unsigned 32-bit, little-endian
    'L>' => 4, # unsigned 32-bit, big-endian
    'V'  => 4, # unsigned 32-bit, little-endian
    'N'  => 4, # unsigned 32-bit, big-endian
    'S<' => 2, # unsigned 16-bit, little-endian
    'S>' => 2, # unsigned 16-bit, big-endian
    'v'  => 2, # unsigned 16-bit, little-endian
    'n'  => 2, # unsigned 16-bit, big-endian
    'Q'  => 8, # unsigned 64-bit
    'Q<' => 8, # unsigned 64-bit, little-endian
    'Q>' => 8, # unsigned 64-bit, big-endian
);

sub _format_word {
    my ($output_ref, $data_ref, $data_length_ref, $format_ref, $address_ref)
        = @_;

    return ${$format_ref} =~ s{
        \A
        % ( [1-9] \d* )?
        ( [LSQ] [<>] | [CVNvnLSQ]  )
    } {
        do {
            my $byte_length = $byte_length_of{$2};
            ${$output_ref} .= join q{ }, map {
                ( length ${$data_ref} >= ${$data_length_ref} + $byte_length )
                ? do {
                    my $hex = sprintf
                        q{%0} . 2 * $byte_length . q{X},
                        unpack
                            $2,
                            substr ${$data_ref}, ${$data_length_ref}, $byte_length;
                    ${$data_length_ref} += $byte_length;
                    ${$address_ref}     += $byte_length;
                    $hex;
                }
                : q{ } x 2 x $byte_length;
            } 1 .. ( $1 || 1 );
            q{};
        }
    }xmse;
}

sub _format_ascii {
    my ($output_ref, $data_ref, $data_length_ref, $format_ref) = @_;

    return ${$format_ref} =~ s{
        \A %d
    } {
        do {
            my $data = substr ${$data_ref}, 0, ${$data_length_ref};
            $data =~ s{
                ( [\x20-\xFE] )
                | .
            } {
                defined $1 ? $1 : q{.}
            }xmsge;
            ${$output_ref} .= $data;
            q{};
        }
    }xmse;
}

# $Id$

1;

__END__

=head1 NAME

Test::HexDifferences::FormatHex - Formats binary to hexadecimal strings

=head1 VERSION

0.001

=head1 SYNOPSIS

    use Test::HexDifferences::FormatHex;

    $string = format_hex(
        $binary,
    );

    $string = format_hex(
        $binary,
        {
            address => $start_address,
            format  => "%a : %4C : '%d'\n",
        }
    );

=head2 Format elements

Every format element in the format string is starting with % like sprintf.

=head3 Data format

 %C  - unsigned char
 %S  - unsigned 16-bit
 %L  - unsigned 32-bit
 %L< - unsigned 32-bit, little-endian
 %L> - unsigned 32-bit, big-endian
 %V  - unsigned 32-bit, little-endian
 %N  - unsigned 32-bit, big-endian
 %S< - unsigned 16-bit, little-endian
 %S> - unsigned 16-bit, big-endian
 %v  - unsigned 16-bit, little-endian
 %n  - unsigned 16-bit, big-endian
 %Q  - unsigned 64-bit
 %Q< - unsigned 64-bit, little-endian
 %Q> - unsigned 64-bit, big-endian

=head3 Address format

 %a  - 16 bit address
 %4a - 16 bit address
 %8a - 32 bit address

=head3 ascii format

 %d - display ascii

=head3 Repetition

 %*x - repetition endless
 %1x - repetition 1 time
 %2x - repetition 2 times
 ...

=head3 Special formats

 %\n - ignore \n

=head2 Default format

The default formatstring is:

 "%a : %4C : '%d'\n"

or fully written as

 "%a : %4C : '%d'\n%*x"

=head2 Complex formats

The %...x allows to write mixed formats e.g.

 Format:
  %a : %N %4C : '%d'\n%1x%
  %a : %n %2C : '%d'\n%*x
 Input:
    \0x01\0x23\0x45\0x67\0x89\0xAB\0xCD\0xEF
    \0x01\0x23\0x45\0x67
    \0x89\0xAB\0xCD\0xEF
 Output:
    0000 : 01234567 89 AB CD EF : '.#-Eg...'
    0008 : 0123 45 67 : '.#-E'
    000C : 89AB CD EF : 'g...'

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

This is a formatter for binary data.

=head1 SUBROUTINES/METHODS

=head2 subroutine format_hex

    $string = format_hex(
        $binary,
        {
            address => $display_start_address,
            format  => $format_string,
        }
    );

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Carp|Carp>

L<Perl6::Export::Attrs|Perl6::Export::Attrs>

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Test::HexDifferences|Test::HexDifferences>

L<Data::Hexdumper|Data::HexDumper> inspired by

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
