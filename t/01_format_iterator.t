#!perl -T

use strict;
use warnings;

use Test::More tests => 4 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok('Test::HexDifferences::FormatHex');
}

*next_format = \&Test::HexDifferences::FormatHex::_next_format;

my $multibyte_error = 0;
{
    my $format = "%4a : %1C : '%d'\n%*x";
    eq_or_diff(
        scalar next_format(\$format, \$multibyte_error)
        . scalar next_format(\$format, \$multibyte_error),
        "%4a : %1C : '%d'\n"
        . "%4a : %1C : '%d'\n",
        'read format* 2 times',
    );
}

{
    my $format
        = "%a %2C\n%1x"
        . "%a %5C '%d'\n%2x";
    eq_or_diff(
        scalar next_format(\$format, \$multibyte_error)
        . scalar next_format(\$format, \$multibyte_error)
        . scalar next_format(\$format, \$multibyte_error),
        "%a %2C\n"
        . "%a %5C '%d'\n"
        . "%a %5C '%d'\n",
        'read format + format',
    );
    eq_or_diff(
        scalar next_format(\$format, \$multibyte_error),
        "%a : %4C : '%d'\n",
        'read none existing format',
    );
}
