#!perl -T

use strict;
use warnings;

use Test::Tester tests => 1 + 4 * 7 + 1;
use Test::More;
use Test::NoWarnings;

BEGIN {
    use_ok( 'Test::HexDifferences' );
}

check_test(
    sub {
        eq_or_hex_diff(undef, 1, 'got undef');
    },
    {
        ok    => 0,
        depth => 2,
        name  => 'got undef',
        diag  => <<'EOT',
+---+-------+----------+
| Ln|Got    |Expected  |
+---+-------+----------+
*  1|undef  |1         *
+---+-------+----------+
EOT
    },
);

check_test(
    sub {
        eq_or_hex_diff(1, undef, 'expected undef');
    },
    {
        ok    => 0,
        depth => 2,
        name  => 'expected undef',
        diag  => <<'EOT',
+---+-----+----------+
| Ln|Got  |Expected  |
+---+-----+----------+
*  1|1    |undef     *
+---+-----+----------+
EOT
    },
);

check_test(
    sub {
        eq_or_hex_diff(1, 1, 'equal');
    },
    {
        ok    => 1,
        depth => 2,
        name  => 'equal',
        diag  => q{},
    },
);

check_test(
    sub {
        eq_or_hex_diff('12345678', '1234567', '12345678 ne 1234567');
    },
    {
        ok    => 0,
        depth => 2,
        name  => '12345678 ne 1234567',
        diag => <<'EOT',
+---+----------------------------+----------------------------+
| Ln|Got                         |Expected                    |
+---+----------------------------+----------------------------+
|  1|'0000 : 31 32 33 34 : 1234  |'0000 : 31 32 33 34 : 1234  |
*  2|0004 : 35 36 37 38 : 5678   |0004 : 35 36 37    : 567    *
|  3|'                           |'                           |
+---+----------------------------+----------------------------+
EOT
    },
);
