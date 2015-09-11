#!/usr/bin/perl -w
# Version 1.02
# Michael E. Zwick
# 6/24/04
# Program designed to compare a single reference.chip.fasta file to one or more
# fasta files generated by a resequencing array (RA) experiment. 
# The reference.chip.fasta file is generated from a high-quality (or at least 
# quality known) genbank reference sequence.
# The .fasta files are generated from RATools.
#
# 11/24/04 Update
# Changed name to ra_accuracy_compare_ver1.02
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
use strict;

#-------------------------------------------------------------------------------
# Local variable definitions
#-------------------------------------------------------------------------------
# Define local variable for composite seq functions

my(@reference_shotgun_files, @experimental_files, @reference_chip_file, @ref_chip_seq, $ref_shotgun_file_number, $exp_file_number, $ref_chip_file_number, $reference_sequence, $reference_sequence_size, @ref_compare, $experiment_sequence, $experiment_sequence_size, @experiment_compare, $bases_identical, $bases_different, $total_bases, $bases_called_N, $check_total, $chip_reference_sequence, $chip_reference_sequence_size);

# Define local variables for localtime function
my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
#-------------------------------------------------------------------------------
# Initialize global variable values
#-------------------------------------------------------------------------------
$total_bases = 0;
$bases_identical = 0;
$bases_called_N = 0;
$bases_different = 0;
$check_total=0;

#-------------------------------------------------------------------------------
# Get the name of the .reference.chip.fasta file
# Get the name of all the experimental files'

# Read reference sequences into an array
# Throw out the fasta header sequences
# Generate a single string - put into an array for comparison

# Loop over experimental filkes
# Read experimental files into arrays one at a time
# Perform comparison with .reference.chip file
# Count number of bases that are N, identical, different

#-------------------------------------------------------------------------------
# Obtain the name of the ames.reference.chip file
#-------------------------------------------------------------------------------
@reference_chip_file = glob("*.ames.reference.chip");
$ref_chip_file_number = ($#reference_chip_file + 1);

print "Processing a total of $ref_chip_file_number chip reference files\n";
if ($ref_chip_file_number == 0) {
	die "$ref_chip_file_number .chip files detected.\n
		Check directory. Exiting program";
}

#-------------------------------------------------------------------------------
# Obtain the name of the .reference.shotgun.fasta file
#-------------------------------------------------------------------------------
@reference_shotgun_files = glob("*.reference.shotgun");
$ref_shotgun_file_number = ($#reference_shotgun_files + 1);

print "Processing a total of $ref_shotgun_file_number shotgun files\n";
if ($ref_shotgun_file_number == 0) {
	die "$ref_shotgun_file_number .shotgun files detected.\n
		Check directory. Exiting program";
}

#-------------------------------------------------------------------------------
# Obtain the names of the experimental files
#-------------------------------------------------------------------------------
@experimental_files = glob("*.fasta");
$exp_file_number = ($#experimental_files + 1);

print "Processing a total of $exp_file_number experimental files\n\n";
if ($exp_file_number == 0) {
	die "$exp_file_number .fasta files detected.\n
		Check directory. Exiting program";
}

#---------------------------------------------------------------------------
# Open output file: discrepancy Count
#---------------------------------------------------------------------------
open(OUT_DISCREPANCIES, ">", "discrepancy.count") 
	or die "Cannot open OUT_FASTA for data output";


#-------------------------------------------------------------------------------
# Process chip reference file to generate single DNA sequence file
# Read file in line by line, discard fasta header
# Remove spaces, put string into array called @ref_chip_seq
#-------------------------------------------------------------------------------
foreach my $chip_file (@reference_chip_file) {

	open(FILEHANDLE_FIRST, $chip_file)
		or die "Cannot open FILEHANDLE_FIRST";

	while (<FILEHANDLE_FIRST>) {
		if ($_ =~ /^>/) {
			next;
		}
		else {
			$chip_reference_sequence .= $_;
		}
	}	
	close FILEHANDLE_FIRST;
	$chip_reference_sequence =~ s/\s//g;
	@ref_chip_seq = split( '', $chip_reference_sequence);
	$chip_reference_sequence_size = ($#ref_chip_seq + 1);
	print OUT_DISCREPANCIES "Size of chip reference sequence: $chip_reference_sequence_size\n";
}

#-------------------------------------------------------------------------------
# Process reference file to generate single DNA sequence file
# Read file in line by line, discard fasta header
# Remove spaces, put string into array called @ref_compare
# Determine size of array @ref_compare
#-------------------------------------------------------------------------------
foreach my $shotgun_file (@reference_shotgun_files) {

	open(FILEHANDLE_FIRST, $shotgun_file)
		or die "Cannot open FILEHANDLE_FIRST";

	while (<FILEHANDLE_FIRST>) {
		if ($_ =~ /^>/) {
			next;
		}
		else {
			$reference_sequence .= $_;
		}
	}	
	close FILEHANDLE_FIRST;
	$reference_sequence =~ s/\s//g;
	@ref_compare = split( '', $reference_sequence);
	$reference_sequence_size = ($#ref_compare + 1);
	print OUT_DISCREPANCIES "Size of shotgun reference sequence: $reference_sequence_size\n";
}

#-------------------------------------------------------------------------------
# Process each experimental file, generate an array, compare to reference 
# sequence, count differences
#-------------------------------------------------------------------------------
foreach my $exp_files (@experimental_files) {

	open(FILEHANDLE_SECOND, $exp_files)
		or die "Cannot open FILEHANDLE_SECOND";

	while (<FILEHANDLE_SECOND>) {
		if ($_ =~ /^>/) {
			next;
		}	
		else {
			$experiment_sequence .= $_;
		}
	}
	close FILEHANDLE_SECOND;
	$experiment_sequence =~ s/\s//g;
	@experiment_compare = split( '', $experiment_sequence);
	$experiment_sequence_size = ($#experiment_compare + 1);
	print OUT_DISCREPANCIES "Size of experimental sequence is $experiment_sequence_size\n";

	if ($reference_sequence_size != $experiment_sequence_size) {
		print "File size error between $exp_files and reference file\n";
	}

	#---------------------------------------------------------------------------
	# Perform file comparison at all chars in arrays @ref_compare and 
	# @experiment_compare.
	#---------------------------------------------------------------------------
	for (my $j = 0; $j < $reference_sequence_size; $j++) {
		$total_bases++;

		if (($experiment_compare[$j] eq "N") || ($ref_compare[$j] eq "N")) {
			$bases_called_N++;
			$j++;
		}
		elsif ($experiment_compare[$j] eq $ref_compare[$j]) {
			$bases_identical++;
			$j++;
		}
		else {
			print OUT_DISCREPANCIES "\n";
			print OUT_DISCREPANCIES "$exp_files\n";
			print OUT_DISCREPANCIES "Position is $j\n";
			print OUT_DISCREPANCIES "Shotgun sequence base is $ref_compare[$j]\n";
			print OUT_DISCREPANCIES "20bp Upstream Shotgun: ";
			for (my $i = 20; $i > 0; $i--) {
				print OUT_DISCREPANCIES "$ref_compare[$j-$i]";
			}
			print OUT_DISCREPANCIES "\n";
			print OUT_DISCREPANCIES "20bp Downstream Shotgun: ";
			for (my $k = 1; $k < 21; $k++) {
				print OUT_DISCREPANCIES "$ref_compare[$j+$k]";
			}
			
			print OUT_DISCREPANCIES "\n";
			print OUT_DISCREPANCIES "Chip Base call is $experiment_compare[$j]\n";
			print OUT_DISCREPANCIES "20bp Upstream Chip - Ames: ";
			for (my $l = 20; $l > 0; $l--) {
				print OUT_DISCREPANCIES "$ref_chip_seq[$j-$l]";
			}
			print OUT_DISCREPANCIES "\n";
			print OUT_DISCREPANCIES "20bp Downstream Chip - Ames: ";
			for (my $m = 1; $m < 21; $m++) {
				print OUT_DISCREPANCIES "$ref_chip_seq[$j+$m]";
			}
			print OUT_DISCREPANCIES "\n";
			#------------------------------------------------------------------
			#Put sequence in format to send to Jacques Ravel
			print OUT_DISCREPANCIES "Chip Base call is $experiment_compare[$j]\n";
			#print OUT_DISCREPANCIES "20bp Upstream Chip - Ames: ";
			for (my $l = 20; $l > 0; $l--) {
				print OUT_DISCREPANCIES "$ref_chip_seq[$j-$l]";
			}
			print OUT_DISCREPANCIES "$experiment_compare[$j]";
			#print OUT_DISCREPANCIES "\n";
			#print OUT_DISCREPANCIES "20bp Downstream Chip - Ames: ";
			for (my $m = 1; $m < 21; $m++) {
				print OUT_DISCREPANCIES "$ref_chip_seq[$j+$m]";
			}
			print OUT_DISCREPANCIES "\n";
			#-----------------------------------------------------------------
			$bases_different++;
			$j++;
			}
	}

	#---------------------------------------------------------------------------
	# Reset values of variables - array containing experimental sequence,
	# variable containing experimental sequence string, experimental sequence
	# size
	#---------------------------------------------------------------------------
	@experiment_compare = ();
	$experiment_sequence = '';
	$experiment_sequence_size = 0;
}
$check_total = ($bases_identical + $bases_different + $bases_called_N);

if ($total_bases != $check_total) {
	print OUT_DISCREPANCIES "Warning. Total bases, $total_bases, does not match $check_total";
}



print OUT_DISCREPANCIES "\n";
print OUT_DISCREPANCIES "The final number of bases called N is $bases_called_N\n";
print OUT_DISCREPANCIES "The final number of identical bases is $bases_identical\n";
print OUT_DISCREPANCIES "The final number of discrepant bases is $bases_different\n";
print OUT_DISCREPANCIES "The total number of bases is $total_bases\n";
print OUT_DISCREPANCIES "The total number of bases (check value) is $check_total\n";
print "Completed chip_accuracy_compare.pl program.\n";

close OUT_DISCREPANCIES;