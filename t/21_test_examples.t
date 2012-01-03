#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 1);

my $dir = getcwd();
chdir("$dir/example");
my $result = qx{prove -I../lib -T 01_eq_or_hex_diff.t 2>&3};
chdir($dir);
like(
    $result,
    qr{\QFailed 2/3 subtests\E}xms,
    'prove example',
);
