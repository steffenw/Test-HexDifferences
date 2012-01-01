#perl -T

use strict;
use warnings;

use Test::More tests => 4 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Test::HexDifferences');
}

eq_or_hex_diff(
    "\x00",
    "0000 : 00" . ( q{   } x (8 - 1) ) . " : '.'\n",
    'char NUL, default format',
);

eq_or_hex_diff(
    "E",
    "ABCD : 45 : 'E'\n",
    {
        address => 0xABCD,
        format  => "%4a : %1C : '%d'\n%*x",
    },
    'char E, single byte format',
);

eq_or_hex_diff(
    "\x00\x01 .abc",
    <<'EOT',
0000 00 01
0002 20 2E 61 62 63 ' .abc'
EOT
    {
        format => <<"EOT",
%a %2C\n%1x%
%a %5C '%d'\n%2x%
EOT
    },
    '2 lines',
);
