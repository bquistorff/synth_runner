synth_runner
========

Automation for multiple Synthetic Control estimations in Stata.

Installation
=======

As a pre-requisite, the `synth` package needs to be installed. (The `all` option is necessary to install the `smoking` dataset used in further examples.)

```Stata
. ssc install synth, all
```

To install the `synth_runner` package with Stata v13 or greater

```Stata
. cap ado uninstall synth_runner //in-case already installed
. net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace
```

For Stata version <13, use the "Download ZIP" button above, unzip to a directory, and then replace the above `net install` with

```Stata
. net install synth_runner, from(full_local_path_to_files) replace
```

You can be notified of new releases by subscribing to notifications of [this issue](https://github.com/bquistorff/synth_runner/issues/1).

Usage
=======
```
sysuse smoking, clear
tsset state year
synth_runner cigsale beer(1984(1)1988) lnincome(1972(1)1988) retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), ///
	trunit(3) trperiod(1989) gen_vars
single_treatment_graphs, trlinediff(-1) raw_gname(cigsale1_raw) ///
	effects_gname(cigsale1_effects) effects_ylabels(-30(10)30) effects_ymax(35) effects_ymin(-35)

effect_graphs , trlinediff(-1) effect_gname(cigsale1_effect) tc_gname(cigsale1_tc)
	
pval_graphs , pvals_gname(cigsale1_pval) pvals_std_gname(cigsale1_pval_t)
```

Help
=======
See the [HTML version of the package help](https://rawgit.com/bquistorff/synth_runner/master/code/ado/synth_runner.html) for more info.

Contributing
=======
If you think you've encountered a bug, try installing the latest version. If it still persists see if an existing issue notes this problem. If the problem is new, file a [new issue](https://github.com/bquistorff/synth_runner/issues/new) and filling out the checklist so that there is enough information to diagnose the issue.
