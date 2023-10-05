#!/usr/bin/env perl

use strict;
use warnings;
use Text::CSV_XS;
use 5.010;
use Getopt::Long qw(GetOptions);

my $input_sep = ',';
my $input_esc = '"';
my $output_sep = ',';
my $output_esc = '"';

GetOptions(
  'input_sep=s' => \$input_sep,
  'input_esc=s' => \$input_esc,
  'output_sep=s' => \$output_sep,
  'output_esc=s' => \$output_esc )
or die "Usage: $0 --input_sep INPUT SEPERATOR --input_esc INPUT ESCAPE --output_sep OUTPUT SEPERATOR --output_esc OUTPUT ESCAPE FILES";

my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1, allow_loose_quotes => 1, escape_char => $input_esc, sep_char => $input_sep } )
  or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
my $outcsv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1, allow_loose_quotes => 1, escape_char => $output_esc, sep_char => $output_sep } )
  or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

binmode(STDOUT, ":encoding(UTF-8)");

foreach my $infile (@ARGV) {
  open my $fh, "<:encoding(UTF-8)", $infile or die "Can't open csv $infile";
  while (my $row = $csv->getline($fh)) {
    $outcsv->say (*STDOUT, $row);
  }
  close $fh;
}

