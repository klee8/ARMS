#!usr/bin/perl
# sum_labelfiles.pl
# Kate Lee April 2016 for Ivan Campos
# Takes in a number of label files and summarises output (to reduce false positives) 
# i.e. only want to identify a bird when the model for that bird is positive and all other models indicate "other_sb"

# input: text file called (sum_me.txt) with a list of the files to be summarised (one on each line), categories.txt file with a list of all the categories
# usage: perl sum_labelfiles.pl 


######################################################################################################################################

# RULES (from Ivan):
# 1. When the five labels are indicating the same category, maintain that category
#       -(example1: five models indicating “background”)
#       -(example2:  five models indicating “other_sb”)
# 2. The  “background” should be maintained every time it appear in at least one of the five models, with two exceptions:
#       -Exception 1:  when “background” appears at the same time as “noise” – maintain “noise” in this case.
#       -Exception 2:  when “background” appears at the same time as two different bird species – maintain “other_sb” in this case.
# 3. The “noise” should be maintained every time it appear in one of the five models.
# 4. When among the five models there are 2 “categories” indicated and of the categories is a bird species and the other is “other_sb”,
#   maintain the bird species (ex: one model indicate GFP and all the others  indicate “other_sb” = GFP should be indicated)
# 5. When among the five models there are 3 “categories” indicated:
#        5A: In that case should be maintained the category “other_sb”. 
#            (example: two of the categories are  bird species and the other is “other_sb” or “background”).
#            In this case the “other_sb” should be indicated from the beginning of the bird species which started first and go until 
#            the end of the second species.
# 6. When among the five models there are 4 ”categories” maintain “other_sb”.

####################################################################################################################################### 


use strict; 
use warnings; 

# open log file
open (LOG, ">log.txt") || die "ERROR, couldn't open log file: $!";

# open list of files 
open (SUMME, "<sum_me.txt") || die "ERROR, couldn't open sum_me.txt: $!";

# open output file
open (OUT, ">summary.label") || die "ERROR, couldn't open output file: $!";

# read in files in sum_me.txt list and put each into an array-of-arrays (@dataset)
my @dataset;
my $filecounter = 0;
#print "got to fileloop\n";
while(<SUMME>){
    chomp;
    print LOG "reading in $_\n";
    open (TEMP,"<$_") || die "ERROR couldn't open $_: $!";
    chomp (@{ $dataset[$filecounter] } = <TEMP>);
    close TEMP;
    $filecounter++;
}
close SUMME;
print LOG "$filecounter files parsed\n";

# test printing out label file -------- WORKS ;)
#foreach my $item (@{$dataset[1]}) {
#    print $item ."\n";
#}
#print "passed fileloop \n";

#exit;


# find start and end times (assumes all models have been run on the same audiofile)
my @values = split /\s/, $dataset[1][0];
my $starttime = $values[0];
@values = split /\s/, $dataset[1][-1];
my $endtime = $values[1];
print LOG "experiment runs from $starttime to $endtime \n";



# build categories hash
my %categories;
print LOG "\ncategories used include:\n";
open (CAT, "<categories.txt") || die "ERROR cannot open categories.txt file: $!";
while(<CAT>){
    chomp;
    $categories{$_} = 0;
    print LOG "$_\n";
}

# species list hash
my %species = %categories;
delete($species{'background'});
delete($species{'noise'});
delete($species{'other_sb'});


# iterate through arrays to find blocks
my $i;
my $last_start = $starttime;
my $last_end = $starttime;
my $last_category = 'none';
my $current_start = $starttime;
my $current_end = $starttime;
my $current_category = 'none';
my $checkpoint = 0;
my $manybirds = 0;
my $birdcount = 0;


#for (my $counter=1; $counter <= 200; $counter++) {
until ($current_end == $endtime){    
    # move current values to $last values
    $last_start = $current_start;
    $last_end = $current_end;
    $last_category = $current_category;

    # empty categories hash for next block
    for my $key (sort keys %categories) {
	$categories{$key} = 0;
	#print "$key\t";
    }
    print "\n";

    # move to next block, skip values = 0
    for ($i=0; $i <= $filecounter -1; $i++){
	my @values = split /\t/, $dataset[$i][0];
	if ($values[1] == $checkpoint) { shift(@{$dataset[$i]}); }
	@values = split /\t/, $dataset[$i][0];
	if ($values[2] eq "0") { print "0 was here\n";shift(@{$dataset[$i]}); }
    }

    print "______________________________________________________________________________________________\n"; 
    # get values for all models in next time block and mark the smallest end time as the next checkpoint
    my %section;
    $checkpoint = $checkpoint + 100;
    for ($i=0; $i <= $filecounter -1; $i++){
	print "$i $dataset[$i][0] \n";
	my @values = split ("\t", $dataset[$i][0]);
	$section{category}{$i} = $values[2];
	$section{start}{$i} = $values[0];
	$section{end}{$i} = $values[1];
#	print "values[1] = $values[1] and checkpoint = $checkpoint\n";    # numbers correct
#	if ($values[1] <= $checkpoint) { print "it is smaller\n";}        # if statement works
	if ($values[1] <= $checkpoint) { 
	    $checkpoint = $values[1];
	}
    }
    #print "next checkpoint = $checkpoint\n";

    # sum catagories
    for ($i=0; $i <= $filecounter -1; $i++){
	$categories{$section{category}{$i}}++;
    }
    
    # test category hash
    for $i (sort keys %categories) {
    #print "$i $categories{$i}\t";
    }

    # determine summary category for this block
    $birdcount = 0;
    if ($categories{'noise'} > 0) { $current_category = 'noise';}                  # if any category is noise                            -> 'noise'
    elsif ( ($categories{'other_sb'} > 0) || ($categories{'background'} > 0) ) {   
	my $tempcategory = 'unknown';
	for my $i (sort keys %species){                                            # check for birds identified
	    if ($categories{$i} > 0) { $birdcount++; $tempcategory = $i; }
	}
	if ( ($manybirds == 0) && ($birdcount > 1) ) { $manybirds = 1; $current_category = 'other_sb'; }    # no 'noise', manybirds = 0, 2+ birds  ->  'other_sb', change manybirds = 1
	elsif ( ($manybirds == 1) && ($birdcount > 1) ) { $current_category = 'other_sb'; }                 # no 'noise', manybirds = 1, 2+ birds  ->  'other_sb'  
	elsif ( ( $manybirds == 1) && ($birdcount == 1) ) { 
	    if ($categories{'background'} > 0) {$current_category = 'background'; $manybirds = 0; }  # no 'noise', manybirds flag = 1, one bird, 'background' > 0 -> 'background', change manybirds = 0, 
 	    else { $current_category = 'other_sb';}                                # no 'noise', manybirds flag = 1, one bird, no 'background'   ->  'other_sb', 
	}
	elsif ( ( $manybirds == 0) && ($birdcount == 1) ) { 
	    if ($categories{'background'} > 0) {$current_category = 'background';} # no 'noise', manybirds = 0, one bird, 'background' > 0  -> 'background'
 	    else { $current_category = $tempcategory; }                            # no 'noise', manybirds = 0, one bird, no 'background'   ->  'bird'
	}
	elsif ($birdcount == 0){
	    if ($categories{'background'} > 0) { $current_category = 'background'; $manybirds = 0;}    # no 'noise', no birds, 'background' > 0   -> 'background', change manybirds = 0
	    elsif ($categories{'other_sb'} > 0) { $current_category = 'other_sb'; $manybirds = 0;}     # no 'noise', no birds, no 'background', 'other_sb' > 0  -> 'other_sb', change manybirds = 0
      	}
	else { $current_category = 'unknown'; }
    }
    #elsif ($categories{'background'} > 0) { $current_category = 'background'; $manybirds = 0; }   
    #elsif ($categories{'other_sb'} > 0) { $current_category = 'other_sb' ; }
    else {$current_category = 'unknown';}

    #print "\ncurrent category = $current_category\n";

    # find curent end (where next block will start)
    $current_end = 1000000;
    for ($i=0; $i <= $filecounter -1; $i++){
        my @values = split ("\t", $dataset[$i][0]);
	if ($values[1] < $current_end){
	    $current_end = $values[1];
	}
    }


    # add block to last or print to file
    if ($current_category eq $last_category) {
	$current_start = $last_start;
    }
    else {
	if ($manybirds == 1) { $current_start = $last_start;} 
	else { $current_start = $last_end; } 
	unless ( ($last_end == $starttime) ||  ( ($manybirds == 1) && ($last_category ne 'background') && ($last_category ne 'noise') ) ){
	    print "\n******SUM LINE: $last_start\t$last_end\t$last_category*********\n";
	    print OUT "$last_start\t$last_end\t$last_category\n";
	}
    }
    
    print "current category = $current_category\ncurrent start = $current_start\ncurrent end = $current_end\ncurrent manybirds = $manybirds\nbirdcount = $birdcount\n";	

}

# if last block, print to file and exit
if ($current_end == $endtime){
    print OUT "$current_start\t$current_end\t$current_category\n";
}
