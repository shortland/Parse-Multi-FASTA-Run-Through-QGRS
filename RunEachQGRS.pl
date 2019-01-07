#!/usr/bin/perl

use strict;
use warnings;
use Path::Tiny;

sub run {
    my ($fastaFile, $sequenceDirectory, $qgrsDirectoryOut, $verbose) = @_;
    empty_directory($sequenceDirectory);
    empty_directory('RC_' . $sequenceDirectory);
    empty_directory($qgrsDirectoryOut);
    my $data = path($fastaFile)->slurp;
    my @lines = split(m/\n/, $data);
    foreach my $line (@lines) {
        my ($name) = ($line =~ m/>(\w+)/g);
        my ($sequence) = ($line =~ m/([ATCG]{4,})/g);
        my $sequenceLocation = $sequenceDirectory . "/" . $name . ".txt";
        my $reverseSequenceLocation = 'RC_' . $sequenceLocation;
        print "Creating sequence file: " . $sequenceLocation . "\n";
        path($sequenceLocation)->spew($sequence);
        my $reverseCompliment = reverse_compliment($sequence);
        path($reverseSequenceLocation)->spew($reverseCompliment);
        my $outputLocation = $qgrsDirectoryOut . "/" . $name . ".txt";
        print "Running sequence file through QGRS\n";
        my $verboseFlag = '';
        if ($verbose) {
            $verboseFlag = ' -v';
        }
        my $execOut = `./qgrs -i $sequenceLocation -t 2 -s 5$verboseFlag`;
        path($outputLocation)->spew("Original Sequence\n" . $sequence . "\n" . $execOut);
        print "Running reverse compliment sequence file through QGRS\n";
        my $reverseExecOut = `./qgrs -i $reverseSequenceLocation -t 2 -s 5$verboseFlag`;
        path($outputLocation)->append("\nReverse Compliment Sequence\n" . $reverseCompliment . "\n" . $reverseExecOut);
    }
}

sub reverse_compliment {
    my ($sequence) = @_;
    my %compliment = (
        "A" => "T",
        "T" => "A",
        "C" => "G",
        "G" => "C"
    );
    my @splitSequence = split(m//, $sequence);
    my @complimentSequence;
    foreach my $letter (@splitSequence) {
        my $complimentLetter = $compliment{$letter};
        push(@complimentSequence, $complimentLetter);
    }
    my $compliment = join('', @complimentSequence);
    my $reverseCompliment = reverse($compliment);
    return $reverseCompliment;
}

sub empty_directory {
    my ($dirName) = @_;
    my $errors;
    while ($_ = glob($dirName . '/*')) {
        next if -d $_;
        unlink($_) or ++$errors, warn("Can't remove $_: $!");
    }
    exit(1) if $errors;
}

sub BEGIN {
    if (!defined $ARGV[3]) {
        print "usage: ./RunEachQGRS.pl [Input FASTA File Name] [Output Sequence Directory] [Output QGRS Directory] [Run QGRS Verbose: 0|1]";
    }
    if ($ARGV[3] !~ m/^[0|1]$/) {
        die "Invalid input for verbose\n";
    }
    run($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3]);
}