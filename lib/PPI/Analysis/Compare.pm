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
use List::Util    ();
use Data::Compare ();
use PPI::Lexer    ();
use PPI::Analysis::Compare::Standard ();

use vars qw{$VERSION @TRANSFORMS};
BEGIN {
	$VERSION = '0.03';

	# A normalisation transform is a function that takes a PPI::Document
	# and transforms it in a way that will leave two document objects
	# with different content but the same meaning in the same state.
	@TRANSFORMS = ();
}

# Register transforms
sub register_transforms {
	my $class = shift;
	foreach my $transform ( @_ ) {
		# Is it registered already
		next if List::Util::first { $transform eq $_ } @TRANSFORMS;

		# Does it exist?
		unless ( defined \&{"$transform"} ) {
			die "Tried to register non-existant function $transform as a PPI::Analysis::Compare transform";
		}

		push @TRANSFORMS, $transform;
	}

	1;
}

# Call the import method for PPI::Analysis::Compare::Standard to register
# the standard transforms.
PPI::Analysis::Compare::Standard->import;





#####################################################################
# Constructor

sub compare {
	my $class = ref $_[0] ? ref shift : shift;
	my ($left, $right) = (shift, shift);
	my $options = $class->_options_param(@_) or return undef;
	$left  = $class->_document_param($left,  $options)  or return undef;
	$right = $class->_document_param($right, $options) or return undef;

	# Process both sides
	$class->normalize( $left  )  or return undef;
	$class->normalize( $right ) or return undef;

	# We should now have two equivalent structs.
	# Do a recursive compare of the two.
	Data::Compare::Compare( $left, $right,
		{ ignore_hash_keys => [qw{_line _col}] },
		);
}

sub normalize {
	my $self = shift;
	my $Document = isa( $_[0], 'PPI::Document' ) ? shift : return undef;

	# Call each of the transforms in turn
	my $modifications = 0;
	foreach my $function ( @TRANSFORMS ) {
		my $rv = &{"$function"}( $self, $Document );
		return undef unless defined $rv;
		$modifications += $rv;
	}

	$modifications;
}




#####################################################################
# Support Methods

# Clean up the options
sub _options_param {
	my $class = shift;
	my %options = @_;

	# Apply defaults
	$options{destructive} = 1 unless defined $options{destructive};
	$options{data}        = 0 unless defined $options{data};

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

Currently, the default set of transforms include removal of non-signicant
content, such as whitespace, pod, __END__ and __DATA__ sections, etc. It
also includes some transforms to change => to , and remove empty statements.

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

Document the extention mechanism, and maybe autodetect plugins?

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
