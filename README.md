synth_runner
========

Automation for multiple Synthetic Control estimations. 

Installation
=======

As a pre-requisite, the `synth` package needs to be installed. (The 'all' option is necessary to install the 'smoking' dataset used in further examples.)

```Stata
. ssc install synth, all
```

To install the -synth_runner- package with Stata v13 or greater

```Stata
. ado uninstall synth_runner
. net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace
```

For Stata version <13, use the "Download ZIP" button above, unzip to a directory, and then replace the above `net install` with

```Stata
. net install parallel, from(full_local_path_to_files) replace
```
