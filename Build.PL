use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name       => 'Test::HexDifferences',
    license           => 'perl',
    dist_abstract     => 'Test::HexDifferences - Test binary as hexadecimal string',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/Test/HexDifferences.pm',
    requires          => {
        perl                    => '5.006',
        version                 => 0,
        'Hash::Util'            => 0,
        'Sub::Exporter'         => 0,
        'Test::Builder::Module' => '0.99', # dist Test-Simple
        'Text::Diff'            => 0,
    },
    build_requires => {
        'Test::Differences' => '0.60',
        'Test::More'        => 0, # dist Test-Simple
        'Test::NoWarnings'  => 0,
        'Test::Tester'      => 0,
    },
    recommends => {
        # build
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 0,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL
    ) ],
)->create_build_script;
