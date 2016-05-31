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
. net install synth_runner, from(full_local_path_to_files) replace
```


Development
=======
If you think you've encountered a bug, try installing the latest version. If it still persists see if an existing issue notes this problem. If the problem is new, file a new issue and list your version of Stata, synth_runner (from `which synth_runner`), the steps that produce the problem and the output.

You can be notified of new releases by subscribing to notifications of [this issue](https://github.com/bquistorff/synth_runner/issues/1).
