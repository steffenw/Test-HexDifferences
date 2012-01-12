package Test::HexDifferences::FormatHex;  ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.001';

use Hash::Util qw(lock_keys);
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
    my $data_pool = {
        # global
        data               => $data,
        format             => $attr_ref->{format}  || "$default_format%*x",
        address            => $attr_ref->{address} || 0,
        output             => q{},
        # to format a block
        format_block       => undef,
        data_length        => undef,
        is_multibyte_error => undef,
    };
    lock_keys %{$data_pool};
    BLOCK:
    while ( length $data_pool->{data} ) {
        _next_format($data_pool);
        _format_items($data_pool);
    }

    return $data_pool->{output};
}

sub _next_format {
    my $data_pool = shift;

    my $is_match = $data_pool->{format} =~ s{
        \A
          ( .*? [^%] )               # format of the block
          % ( 0* [1-9] \d* | [*] ) x # repetition factor
    } {
        my $new_count = $2 eq q{*} ? q{*} : $2 - 1;
        $data_pool->{format_block} = $1;
        $new_count
        ? "$1\%${new_count}x"
        : q{};
    }xmse;
    if ( $data_pool->{is_multibyte_error} || ! $is_match ) {
        $data_pool->{format}             = "$default_format%*x";
        $data_pool->{format_block}       = $default_format;
        $data_pool->{is_multibyte_error} = 0;
        return;
    }

    return;
}

sub _format_items {
    my $data_pool = shift;

    $data_pool->{data_length} = 0;
    RUN: {
        # % written as %%
        $data_pool->{format_block} =~ s{
            \A % ( % )
        } {
            do {
                $data_pool->{output} .= $1;
                q{};
            }
        }xmse and redo RUN;
        # \n written as %\n will be ignored
        $data_pool->{format_block} =~ s{
            \A % [\n]
        }{}xms and redo RUN;
        # address
        _format_address($data_pool)
            and redo RUN;
        # words
        _format_word($data_pool)
            and redo RUN;
        # display ascii
        _format_ascii($data_pool)
            and redo RUN;
        # display any other char
        $data_pool->{format_block} =~ s{
          \A (.)
        } {
            do {
                $data_pool->{output} .= $1;
                q{};
            }
        }xmse and redo RUN;
        if ( $data_pool->{data_length} ) {
            # clear already displayed data
            substr $data_pool->{data}, 0, $data_pool->{data_length}, q{};
            $data_pool->{data_length} = 0;
        }
    }

    return;
}

sub _format_address {
    my $data_pool = shift;

    return $data_pool->{format_block} =~ s{
        \A % ( 0* [48]? ) a
    } {
        do {
            my $length = $1 || 4;
            $data_pool->{output}
                .= sprintf "%0${length}X", $data_pool->{address};
            q{};
        }
    }xmse;
}

my %byte_length_of = (
    'C'  => 1, # unsigned char
    'S'  => 2, # unsigned 16-bit
    'S<' => 2, # unsigned 16-bit, little-endian
    'S>' => 2, # unsigned 16-bit, big-endian
    'v'  => 2, # unsigned 16-bit, little-endian
    'n'  => 2, # unsigned 16-bit, big-endian
    'L'  => 4, # unsigned 32-bit
    'L<' => 4, # unsigned 32-bit, little-endian
    'L>' => 4, # unsigned 32-bit, big-endian
    'V'  => 4, # unsigned 32-bit, little-endian
    'N'  => 4, # unsigned 32-bit, big-endian
    'Q'  => 8, # unsigned 64-bit
    'Q<' => 8, # unsigned 64-bit, little-endian
    'Q>' => 8, # unsigned 64-bit, big-endian
);

sub _format_word {
    my $data_pool = shift;

    return $data_pool->{format_block} =~ s{
        \A
        % ( 0* [1-9] \d* )?
        ( [LSQ] [<>] | [CVNvnLSQ] )
    } {
        do {
            my $byte_length = $byte_length_of{$2};
            $data_pool->{output} .= join q{ }, map {
                (
                    length $data_pool->{data}
                    >= $data_pool->{data_length} + $byte_length
                )
                ? do {
                    my $hex = sprintf
                        q{%0} . 2 * $byte_length . q{X},
                        unpack
                            $2,
                            substr
                                $data_pool->{data},
                                $data_pool->{data_length},
                                $byte_length;
                    $data_pool->{data_length} += $byte_length;
                    $data_pool->{address}     += $byte_length;
                    $hex;
                }
                : do {
                    if ( $byte_length > 1 ) {
                        $data_pool->{is_multibyte_error}++;
                    }
                    q{ } x 2 x $byte_length;
                };
            } 1 .. ( $1 || 1 );
            q{};
        }
    }xmse;
}

sub _format_ascii {
    my $data_pool = shift;

    return $data_pool->{format_block} =~ s{
        \A %d
    } {
        do {
            my $data = substr $data_pool->{data}, 0, $data_pool->{data_length};
            $data =~ s{
                ( [\x20-\xFE] )
                | .
            } {
                defined $1 ? $1 : q{.}
            }xmsge;
            $data_pool->{output} .= $data;
            q{};
        }
    }xmse;
}

# $Id$

1;

__END__

=head1 NAME

Test::HexDifferences::FormatHex - Format binary to hexadecimal strings

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

The default format is:

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

L<Hash::Util|Hash::Util>

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
