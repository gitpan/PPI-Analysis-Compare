#!/usr/bin/perl -w

# Load test the PPI::Analysis::Compare module and do some super-basic tests

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}





# Does everything load?
use Test::More 'tests' => 3;
BEGIN {
	ok( $] >= 5.005, 'Your perl is new enough' );
}

use_ok( 'PPI::Analysis::Compare' );





# Basic API testing
use constant PAC => 'PPI::Analysis::Compare';
ok( PAC->can('compare'), "compare method exists" );

1;
