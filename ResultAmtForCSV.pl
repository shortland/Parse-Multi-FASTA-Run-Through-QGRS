#!/usr/bin/perl

use strict;
use warnings;
use Path::Tiny;
use Data::Dumper;

my %amountsForCLL;
foreach my $fp (glob("qgrs_out/*.txt")) {
    my $data = path($fp)->slurp;
    my @lines = split(/\n/, $data);
    my @groupings;
    foreach my $line (@lines) {
        if ($line =~ /^[1-9]+/) {
            my ($lineNum) = ($line =~ m/^([1-9])+/);
            push(@groupings, $lineNum);
        }
    }
    
    # for finding if there aren't any reversecompliment qgrs outputs
    my $reverseComplimentAmt;
    my $normalAmt;
    my %seen;
    foreach my $num (@groupings) {
        $seen{$num}++;
    }
    if (!defined $seen{1}) {
        $normalAmt = '0';
        $reverseComplimentAmt = '0';
    }
    elsif ($seen{1} ne 2) {
        $normalAmt = $groupings[-1];
        $reverseComplimentAmt = '0';
    } else {
        $reverseComplimentAmt = $groupings[-1];
        my $prev = 'z';
        foreach my $num (@groupings) {
            if ($num eq 1 && $prev ne 'z') {
                $normalAmt = $prev;
                last;
            }
            $prev = $num;
        }
    }

    $fp =~ s/qgrs_out\///;
    $fp =~ s/\.txt//g;
    $amountsForCLL{$fp}{'normal'} = $normalAmt;
    $amountsForCLL{$fp}{'reversec'} = $reverseComplimentAmt;
}

print Dumper \%amountsForCLL;

my $dumpCLL = path('CLLDataBase_clean_new.withMutability.csv')->slurp;
my @cllLines = split(/\n/, $dumpCLL);
my @newCllLines;
my $i = 0;
foreach my $line (@cllLines) {
    if ($i eq 0) {
        push(@newCllLines, $line);
        $i++;
        next;
    }
    my ($cllName) = ($line =~ /(CLL\w+)/);
    my $newLine = $line;
    if (defined $cllName) {
        if (!defined $amountsForCLL{$cllName}{'normal'} || !defined $amountsForCLL{$cllName}{'reversec'}) {
            $newLine .= "\t" . "NA" . "\t" . "NA";
        } else {
            $newLine .= "\t\"" . $amountsForCLL{$cllName}{'normal'} . "\"\t\"" . $amountsForCLL{$cllName}{'reversec'} . "\"";
        }
    }
    push(@newCllLines, $newLine);
    $i++;
}

my $newData = join("\n", @newCllLines, "\n");
path("CLLDataBase_clean_new.withQGRSAmt.csv")->spew($newData);