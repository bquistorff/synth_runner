CONTENTS
This package of deliverables contains the following files
== Stata Code ==
-synth_runner.ado 
-effect_graphs.ado 
-pval_graphs.ado 
-single_treatment_graphs.ado
-synth_wrapper.ado 
-calc_RMSPE.ado (ancillary utility)

== Stata Package files ==
-synth_runner.sthlp (help file) 
-synth_runner.pkg 
-stata.toc (allows using -net install- to install from this folder)

== Stata example code ==
- usage.do

== Writeup ==
- _README.txt (this file)
- synth_runner.pdf 

INSTALLATION
As a pre-requisite, the -synth- package needs to be installed. (The 'all' option is necessary to install the 'smoking' dataset used in further examples.)
. ssc install synth, all

To install the -synth_runner- package
. net install synth_runner, from(<path/to/installation/files>)
Or to get updates
. net install <package>, from(https://raw.github.com/bquistorff/synth_runner/master/) replace

To cleanup after usage
$ rm *.gph *.eps
