package PPI::Analysis::Compare::Standard;

# The package provides a standard set of PPI::Analysis::Compare
# normalization transforms.

use strict;
use UNIVERSAL 'isa';
use PPI::Analysis::Compare ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}

# Register the transforms
sub import {
	my @transforms = map { __PACKAGE__ . "::$_" } qw{
		remove_end
		remove_data
		remove_pod
		remove_whitespace
		remove_insignificant_tokens
		remove_null_statements
		commify_list_digraph
		};
	PPI::Analysis::Compare->register_transforms( @transforms );
}





#####################################################################
# Transforms

sub remove_end {
	my ($self, $Document) = @_;
	$Document->prune( 'PPI::Token::End' );
}

sub remove_data {
	my ($self, $Document) = @_;
	$Document->prune( 'PPI::Token::Data' );
}

sub remove_pod {
	my ($self, $Document) = @_;
	$Document->prune( 'PPI::Token::Pod' );
}

sub remove_whitespace {
	my ($self, $Document) = @_;
	$Document->prune( 'PPI::Token::Whitespace' );
}

sub remove_insignficant_tokens {
	my ($self, $Document) = @_;
	$Document->prune( sub { ! $_[1]->significant } );
}

sub remove_null_statements {
	my ($self, $Document) = @_;
	$Document->prune( 'PPI::Statement::Null' );
}

sub commify_list_digraph {
	my ($self, $Document) = @_;

	# Find all "=>" digraph list operators
	my $commas = $Document->find( 
		sub {
			UNIVERSAL::isa($_[1], 'PPI::Token::Operator')
			and $_[1]->content eq '=>'
		} );
	return $commas unless $commas; # 0 or undef

	# Convert them to commas
	foreach ( @$commas ) {
		$_->{content} = ';';
	}

	scalar @$commas;		
}

1;
