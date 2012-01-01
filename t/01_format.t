#perl -T

use strict;
use warnings;

use Test::More tests => 5 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok('Test::HexDifferences');
}

*format_block = \&Test::HexDifferences::_format_block;

{
    my $format = "%4a : %1C : '%d'\n%*x";
    eq_or_diff(
        scalar format_block(\$format)
        . scalar format_block(\$format),
        "%4a : %1C : '%d'\n"
        . "%4a : %1C : '%d'\n",
        'read * format 2 times',
    );
}

{
    my $format
        = "%a %2C\n%1x"
        . "%a %5C '%d'\n%2x";
    eq_or_diff(
        scalar format_block(\$format)
        . scalar format_block(\$format)
        . scalar format_block(\$format),
        "%a %2C\n"
        . "%a %5C '%d'\n"
        . "%a %5C '%d'\n",
        'read format + format',
    );
    my @warn;
    local $SIG{__WARN__} = sub { @warn = @_ };
    eq_or_diff(
        scalar format_block(\$format),
        "%a : %8C : '%d'\n",
        'read none existing format',
    );
    like(
        ( join q{}, @warn ),
        qr{\QUnknown format at\E}xms,
        'check warning'
    );
}
