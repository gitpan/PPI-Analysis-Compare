package PPI::Analysis::Compare;

# This package takes two "documents" of perl source code, in either filename,
# raw source or PPI::Document form. It uses a number or methods to try to
# determine if the two documents are functionally equivalent.

# In general, the way it does this is by applying a number of transformations
# to the perl documents. Initially, this simply consists of removing all
# "non-signficant" tokens and comparing what is left.

# Thus, changes in whitespace, newlines, comments, pod and __END__ material
# are all ignored.

use strict;
use UNIVERSAL 'isa';

use PPI::Lexer    ();
use Data::Compare ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor

sub compare {
	my $class = ref $_[0] ? ref shift : shift;
	my ($left, $right) = (shift, shift);
	my $options = $class->_options_param(@_) or return undef;
	$left  = $class->_document_param($left,  $options)  or return undef;
	$right = $class->_document_param($right, $options) or return undef;

	# Process both sides
	foreach my $Document ( $left, $right ) {
		my $rv = $Document->prune( sub { ! $_[1]->significant } );
		return undef unless defined $rv;
	}

	# We should now have two equivalent structs.
	# Do a recursive compare of the two.
	Data::Compare::Compare( $left, $right,
		{ ignore_hash_keys => [qw{_line _col}] },
		);
}





#####################################################################
# Support Methods

# Clean up the options
sub _options_param {
	my $class = shift;
	my %options = @_;

	# Apply defaults
	$options{destructive} = 1 unless defined $options{destructive};
	foreach ( qw{whitespace comments pod end data} ) {
		$options{$_} = 0 unless defined $options{$_};
	}

	# Clean up values
	foreach ( keys %options ) {
		$options{$_} = !! $options{$_};
	}

	\%options;
}

# We work with PPI::Document object, but are able to take arguments in a
# variety of different forms.
sub _document_param {
	my $class = shift;
	my $it = defined $_[0] ? shift : return undef;
	my $options = shift || {};

	# Ideally, we have just been given a PPI object we can work with easily.
	if ( isa( ref $it, 'PPI::Document' ) ) {
		# Because we test destructively, clone the document first
		# if they have set the "nondestructive" option.
		return $options->{destructive} ? $it : $it->clone;

	} elsif ( isa( ref $it, 'PPI::Tokenizer' ) ) {
		# Lex and return
		return PPI::Lexer->lex_tokenizer( $it );

	} elsif ( ref $it eq 'SCALAR' ) {
		# If we have been given a reference to a scalar, it is source code.
		return PPI::Lexer->lex_source( $$it );

	} elsif ( ! ref $it and length $it ) {
		# A simple string is a filename
		return PPI::Lexer->lex_file( $$it );

	} else {
		# We don't support this
		return undef;
	}
}

1;

=pod

=head1 NAME

PPI::Analysis::Compare - Compare two perl documents for equivalence

=head1 SYNOPSIS

  use PPI::Analysis::Compare;
  
  # Compare my file to yours, to see if they are functionally equivalent
  PPI::Analysis::Compare->compare( 'my/file.pl', 'your/file.pl' );

=head1 DESCRIPTION

The module is part of PPI, but is provided seperately, as is the practice for
any non-essential module with additional dependencies.

The PPI::Analysis::Compare module takes to perl documents, as a file name, raw
source or an existing PPI::Tokenizer or PPI::Document object, and compares the
two to see if they are functionally identical.

The two documents (however they are provided) are loaded into fully lexed
PPI::Document structures. These are then destructively modified to factor out
anything that may have different content but be functionally equivalent.

Initially, this means that all non-significant items, such as whitespace,
comments, POD, __END__ and __DATA__ sections etc are stripped out of the
structs. Finally a deep Data::Compare is used to check that the two sets of
lexed code are identical.

Currently, the removal of various non-signicicant content are the only options
available, but over time there may be additional transforms added to this
package (or perhaps plugins), so various other language idioms can be tested
for equivalency.

Please note that due to some parts of PPI being incomplete, mainly the
PPI::Document scanning/filter engine, this 0.01 does NOT actually strip
anything out. So really, currently this module is a placeholder and
effectively useless :(

=head1 METHODS

=head2 compare $left, $right, option => value, ...

For the time being, PPI::Analysis::Compare provides only the C<compare>
method. The first two arguments are the left and right comparitors.

Each comparitor can be either a PPI::Document or PPI::Tokenzier object,
a file name, or a reference to a scalar containing raw perl source code.
Each comparitor will be loaded, tokenized and lexed as needed to get two
PPI::Document objects for comparison.

The list of options will be documented once this module is actually useful.

=head1 TO DO

This code is largely completed and should correctly lex and compare two
identical files, but without the core scanning/filter PPI::Analysis routines
in place, the actual stripping code is incomplete.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

  http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI%3A%3AAnalysis%3A%3Compare

For other issues, contact the author

=head1 AUTHORS

        Adam Kennedy ( maintainer )
        cpan@ali.as
        http://ali.as/

=head1 COPYRIGHT

Copyright (c) 2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
