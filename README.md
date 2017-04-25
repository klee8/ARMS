
# ARMS_summarizing.pl
### Kate D Lee April 2016

MIT Licenced

The script takes in files generated by running a bioacoustic sound file through [matlabHTK](https://github.com/LouisRanjard/matlabHTK) under different species models. In order to reduce false positives, some rules were made to compare the output of the species models. The script defines the smallest blocks of time over which there is a change in any of the matlabHTK outputs, and evalutates the labels for that block. The summary of labels is calculated using the rules laid out below by [Ivan Braga Campos](https://unidirectory.auckland.ac.nz/people/profile/icam765). A summary file with the new time blocks, their start and end times and new summarised label are printed to an output file.

The script takes in two files. An input file which contains a list of all the model files to sum, one on each line (default input file name is sum_me.txt) and categories.txt which contains a list of all the categories, one on each line (e.g. the bird models from the example and the three compulsory labels 'noise', 'background' and 'other_sp')


usage :
perl ARMS_summarizing.pl

or

perl ARMS_summarizing.pl \<inputfile\> \<outfile\>


## rules for summary:

 1. When all labels are indicating the same category, use that category (example1: all models indicating “background”; example2: all models indicating “other_sp”).
 2. The “background” label should be used every time it appears in at least one of models, with two exceptions (exception 1:  when “background” appears at the same time as “noise” use the “noise” label; exception 2:  when “background” appears at the same time as two or more different species use the “unidentified” label).
 3. The “noise” label should be used every time it appears in any model.
 4. When there are 2 categories identified and one of the categories is a specific species and the other is “other_sp”, 
    use the specific species label (example: if one model indicates GFP and all the others indicate “other_sp”, the GFP label should be used)
 5. When there are 3 categories identified among all the models, use the category "unidentified”.(example: if two of the categories are bird species and the other is “other_sp” or “background”, use "unidentified"). Note that in this case the “unidentified” label should be used from the beginning of the bird species which started first and go until the end of the last species.
 6. When there are 4 or more categories among all models use “unidentified”.
 7. Replace "other_sp" label with "unidentified"


## running the example

enter the example folder and run sum_label.pl
<pre><code>cd example
perl ../ARMS_summarizing.pl
</code></pre>

### output files:

#### outfile (default: summary.labels.txt)
shows a list of each time block and the summarised label for that block

#### label.log
Indicates the timeframe looked at and categories used.
Shows how the program is making decisions in each block (between underscored lines).
Each block shows the current timeslot and label for each of the files, what has been printed for the last block (in the starred line), and the decision for the current block.

