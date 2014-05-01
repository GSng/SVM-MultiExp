#!/usr/bin/perl
use strict;
use warnings;

@ARGV >= 3 or die "Usage: print-specific-line.pl line-number input-file\n";

my $infile = $ARGV[0];
my $outfile = $ARGV[1];
my @desired_lines = @ARGV[2..$#ARGV];

open(my $in ,"<",$infile)  || die "Could not open $infile, program halting.";
open(my $out,">>",$outfile) || die "Could not open $outfile, program halting.";

my $count = 1;
my $line_count = 0;

while (<$in>) {
  if ($count == $desired_lines[$line_count]) {
	print $out $_;
    if ($line_count == $#desired_lines) {
		close $in; close $out;
		exit;
	}
	$line_count++;
  }
  $count++;
}
