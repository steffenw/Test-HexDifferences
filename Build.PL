use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name       => 'Test::HexDifferences',
    license           => 'perl',
    dist_abstract     => 'Test::HexDifferences - differences of hexadecimal text',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Test/HexDifferences.pm',
    requires          => {
        perl    => 5.006,
        version => 0,
    },
    build_requires => {
        'Test::NoWarnings' => '1.03',
        'Test::More'       => 0, # dist Test-Simple
    },
    recommends => {
        # build
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL
    ) ],
)->create_build_script();
