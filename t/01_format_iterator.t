#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 1;
use Test::NoWarnings;
use Test::Differences;
use Test::Warn;

BEGIN {
    use_ok('Test::HexDifferences::FormatHex');
}

*next_format = \&Test::HexDifferences::FormatHex::_next_format;

{
    my $format = "%4a : %1C : '%d'\n%*x";
    eq_or_diff(
        scalar next_format(\$format)
        . scalar next_format(\$format),
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
        scalar next_format(\$format)
        . scalar next_format(\$format)
        . scalar next_format(\$format),
        "%a %2C\n"
        . "%a %5C '%d'\n"
        . "%a %5C '%d'\n",
        'read format + format',
    );
    warning_like(
        sub {
            eq_or_diff(
                scalar next_format(\$format),
                "%a : %4C : '%d'\n",
                'read none existing format',
            );
        },
        qr{\QUnknown format at\E}xms,
        'check warning',
    );
}
