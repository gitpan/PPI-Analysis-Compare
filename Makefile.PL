require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'PPI::Analysis::Compare',
	'VERSION_FROM' => 'lib/PPI/Analysis/Compare.pm',
	'PREREQ_PM'    => {
		# Application dependencies
		PPI           => '0.817',
		Data::Compare => '0.10',

		# Test dependencies
		Test::More => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Compare two perl documents for equivalence (experimental)',
	) : (),
);
