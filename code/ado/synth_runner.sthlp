{smcl}
{* 17feb2017}{...}
{vieweralsosee "effect_graphs" "help effect_graphs"}{...}
{vieweralsosee "pval_graphs" "help pval_graphs"}{...}
{vieweralsosee "single_treatment_graphs" "help single_treatment_graphs"}{...}
{cmd:help synth_runner} 
{hline}

{title:Title}

{p2colset 5 22 22 2}{...}
{p2col :{hi:synth_runner} {hline 2}}Automation for multiple Synthetic Control estimations. {p_end}
{p2colreset}{...}


{title:Syntax}

{p 6 8 2}
{opt synth_runner} {it:depvar}  {it:predictorvars} , [ {opt tru:nit(#)} {opt trp:eriod(#)} {opt d:(varname)} {opt tre:nds} {opt pre_limit_mult:(real>=1)} {opt training_propr(real)} {opt gen:_vars} {opt ci} {opt pvals1s}
 {opt max_lead(int)} {opt noenforce_const_pre_length} {opt n_pl_avgs:(string)} {opt par:allel} {opt det:erministicout} 
 {opt pred_prog:(string)} {opt drop_units_prog:(string)} {opt xperiod_prog:(string)} {opt mspeperiod_prog:(string)} {opt noredo_tr_error:} {opt aggfile_v:(string)} {opt aggfile_w:(string)} {it:synthsettings} ]

{p 4 4 2}
The dataset must be declared as a (balanced) panel using {help tsset}.
Variables specified in {it:depvar} and {it:predictorvars} must be numeric variables; abbreviations are not allowed. The command {cmd:synth} (available in SSC) is required. 
Auxiliary commands for generating graphs post-estimation are shown in the examples below.
Finally, the version of the package can be found by running {cmd:synth_runner version} and checking {cmd:r(version)} or viewing the displayed output.
 

{title:Description}

{p 4 4 2}
{cmd:synth_runner} automates the process of running multiple synthetic control estimations by {cmd:synth}. It will run placebo estimates in-space (estimations for the same treatment period but on all the control units). 
It will then provide inference (p-values) comparing the estimated main effect to the distribution of placebo effects. It handles the case where several units receive treatment, possibly at different time periods. 
If there are multiple treatment periods, then effects are centered around the treatment period so as to be comparable. 
The maximum common number of leads and lags that can be achieved in the data given the treated units are used for analysis.
It provides facilities for automatically generating outcome predictors using a training proportion of the pre-treatment period. It also provides diagnostics to assess fit. 
{cmd:synth_runner} is designed to accompany {cmd:synth} but not to supersede it.
For more details about single estimations (variable weights, observation weights,  covariate balance, and synthetic control outcomes when there are multiple time periods) use {cmd:synth} directly.
See {help synth:{it:synth}} and Abadie and Gardeazabal (2003) and Abadie, Diamond, and Hainmueller (2010, 2014) for more details.

{title:Required Settings}

{p 4 8 2}
{marker predoptions}
{cmd: depvar} the outcome variable.

{p 4 8 2}
{cmd: predictorvars} the list of predictor variables. See {help synth:{it:synth}} for more details.

{p 2 4 2}
For specifying the unit and time-period of treatment, there are two methods. Exactly one of these is required.

{p 4 8 2}
{cmd:trunit(}{it:#}{cmd:)} and {cmd:trperiod(}{it:#}{cmd:)}. This syntax (used by {cmd:synth}) can be used when there is a single unit entering treatment. 
Since synthetic control methods split time into pre-treatment and treated periods, {cmd:trperiod} is the first of the treated periods and, slightly confusingly, also called post-treatment.

{p 4 8 2}
{cmd:d(}varname{cmd:)}. The {cmd:d} variable should be a binary variable which is 1 for treated units in treated periods, and 0 everywhere else. 
This allows for multiple units to undergo treatment, possibly at different times.

{title:Options}

{p 4 8 2}
{cmd: trends} will force {cmd:synth} to match on the trends in the outcome variable. It does this by scaling each unit's outcome variable so that it is 1 in the last pre-treatment period.

{p 4 8 2}
{cmd: pre_limit_mult(}{it:real>=1}{cmd:)} will not include placebo effects in the pool for inference if the match quality of that control, pre-treatment Root Mean Squared Predictive Error (RMSPE), 
is greater than {it:pre_limit_mult} times the match quality of the treated unit.

{p 4 8 2}
{cmd: training_propr(}0<={it:real}<=1{cmd:)} instructs {cmd:synth_runner} to automatically generate the outcome predictors. The default (0) is to not generate any (the user then includes the desired ones in predictorvars). 
If set to a number greater than 0, then that initial proportion of the pre-treatment period is used as a training period with the rest being the validation period. 
Outcome predictors for every time in the training period will be added to the {cmd:synth} commands. Diagnostics of the fit for the validation period will be outputted. 
If the value is between 0 and 1, there will be at least one training period and at least one validation period. 
If it is set to 1, then all the pre-treatment period outcome variables will be used as predictors. This will make other covariate predictors redundant.

{p 4 8 2}
{cmd: ci} outputs confidence intervals from randomization inference for raw effect estimates. These should only be used if the treatment is randomly assigned (conditional on covariates and interactive fixed-effects). 
If treatment is not randomly assigned then these confidence intervals do not have a straight-forward interpretation (in contrast to p-values which do).

{p 4 8 2}
{cmd: pvals1s} outputs one-sided p-values in addition to the two-sided p-values.

{p 4 8 2}
{cmd:gen_vars} generates variables in the dataset from estimation. 
This is only allowed if there is a single period in which unit(s) enter treatment. If {cmd:gen_vars} is specified, it will generate the following variables:

{p 8 17 15}
{cmd:lead:}{p_end}
{p 12 12 15}
A variable that contains the respective time period relative to treatment. {it:Lead=1} specifies the first period of treatment. This is to match Cavallo et al. (2013) and in effect is the offset from the last non-treatment period.{p_end}

{p 8 17 15}
{cmd:{it:depvar}_synth:}{p_end}
{p 12 12 15}
A variable that contains the unit's synthetic control outcome for that time period.{p_end}

{p 8 17 15}
{cmd:effect:}{p_end}
{p 12 12 15}
A variable that contains the difference between the unit's outcome and its synthetic control for that time period.{p_end}

{p 8 17 15}
{cmd:pre_rmspe:}{p_end}
{p 12 12 15}
A variable, constant for a unit, containing the pre-treatment match quality in terms of RMSPE.{p_end}

{p 8 17 15}
{cmd:post_rmspe:}{p_end}
{p 12 12 15}
A variable, constant for a unit, containing a measure of the post-treatment effect (jointly over all post-treatment time periods) in terms of RMSPE.{p_end}

{p 8 17 15}
{cmd:{it:depvar}_scaled:}{p_end}
{p 12 12 15}
If the match was done on trends, this is the unit's outcome variable normalized so that its last pre-treatment period outcome is 1.{p_end}

{p 8 17 15}
{cmd:{it:depvar}_scaled_synth:}{p_end}
{p 12 12 15}
If the match was done on trends, this is the unit's synthetic control's (scaled) outcome variable.{p_end}

{p 8 17 15}
{cmd:effect_scaled:}{p_end}
{p 12 12 15}
If the match was done on trends, this is the difference between the unit's (scaled) outcome and its (scaled) synthetic control for that time period.{p_end}

{p 4 8 2}
{cmd: n_pl_avgs(}{it:string}{cmd:)} controls the number of placebo averages to compute for inference. The total possible grows exponentially with the number of treated events.
If omitted, the default behavior is cap the number of averages computed at 1,000,000 and if the total is more than that to sample (with replacement) the full distribution. 
The option {cmd: n_pl_avgs(}{it:all}{cmd:)} can be used to override this behavior and compute all the possible averages. 
The option {cmd: n_pl_avgs(}{it:#}{cmd:)} can be used to specify a specific number less than the total number of averages possible.

{p 4 8 2}
{cmd: max_lead(}{it:int}{cmd:)} will limit the number of post-treatment periods analyzed. The default is the maximum number of leads that is available for all treatment periods.

{p 4 8 2}
{cmd: noenforce_const_pre_length} - When there are multiple periods, estimations at later treatment dates will have more pre-treatment history available. 
By default, these histories are trimmed on the early side so that all estimations have the same amount of history. 
If instead, maximal histories are desired at each estimation stage, use {cmd:noenforce_const_pre_length}.

{p 4 8 2}
{cmd: parallel} will enable parallel processing if the {cmd:parallel} command is installed and configured. Version 1.18.2 is needed at a minimum (available via {browse "https://github.com/gvegayon/parallel/"}).

{p 4 8 2}
{cmd: deterministicoutput} eliminates displayed output that would vary depending on the machine (e.g. timers and number of parallel clusters) so that log files can be easily compared across runs.

{p 4 8 2}
{cmd: pred_prog(}{it:string}{cmd:)} is a method to allow time-contingent predictor sets. 
The user writes a program that takes as input a time period and outputs via {cmd:r(predictors)} a {cmd:synth}-style predictor string. 
If one is not using {cmd:training_propr} then {cmd:pred_program} could be used to dynamically include outcome predictors. See Example 3 for usage details.

{p 4 8 2}
{cmd: drop_units_prog(}{it:string}{cmd:)} is the name of a program that, when passed the unit to be considered treated, will drop other units that should not be considered when forming the synthetic control. 
Commonly this is because they are neighboring or interfering units. See Example 3 for usage details.

{p 4 8 2}
{cmd: xperiod_prog(}{it:string}{cmd:)} allows for setting of {cmd:synth}'s {cmd:xperiod} option that varies with the treatment period. 
The user-written program is passed the treatment period and should return, via {cmd:r(xperiod)}, a numlist suitable for {cmd:synth}'s {cmd:xperiod} (the period over which generic predictor variables are averaged). 
See {cmd:synth} for more details on the {cmd:xperiod} option. See Example 3 for usage details.

{p 4 8 2}
{cmd: mspeperiod_prog(}{it:string}{cmd:)} allows for setting of {cmd:synth}'s {cmd:mspeperiod} option that varies with the treatment period. 
The user-written program is passed the treatment period and should return, via {cmd:r(mspeperiod)}, a numlist suitable for {cmd:synth}'s {cmd:mspeperiod} (the period over which the prediction outcome is evaluated). 
See {cmd:synth} for more details on the {cmd:mspeperiod} option. See Example 3 for usage details.

{p 4 8 2}
{cmd: noredo_tr_error} By default an error when estimating {cmd:synth} on a treated unit will be redone
so that the output and error from {cmd:synth} can be seen by the user. Use this option to not redo
the estimation on error.

{p 4 8 2}
{cmd: aggfile_v(}{it:string}{cmd:)} and {cmd: aggfile_w(}{it:string}{cmd:)} overwrites those filenames with variable weights and unit weights from all the estimations.
Both must be specified or neither. {it:aggfile_v} will have variables V1-V{it:k}, tr_{it:unit_varname}, and tr_{it:time_varname}, and for each tr_{it:unit_varname}-tr_{it:time_varname} estimation there will be 
one observation. {it:aggfile_w} has variables _Co_Number, _W_Weight, tr_{it:unit_varname}, and tr_{it:time_varname}, and for each tr_{it:unit_varname}-tr_{it:time_varname} estimation there will be a row for each 
control donor.


{p 4 8 2}
{cmd: synthsettings} pass-through options sent to {cmd:synth}. See {help synth:{it:help synth}} for more information.  The following which are disallowed: {it:counit}, {it:figure}, {it:resultsperiod}.

{synoptline}

{title:Saved Results}

{p 4 8 2}
{cmd:synth_runner} returns the following scalars and matrices.  

{p 8 8 2}
{cmd: e(treat_control) :}{p_end}
{p 10 10 2}
A matrix with the average treatment outcome (centered around treatment) and the average of the outcome of those unit's synthetic controls for the pre- and post-treatment periods. 

{p 8 8 2}
{cmd: e(b):}{p_end}
{p 10 10 2}
A vector with the per-period effects (unit's actual outcome minus the outcome of its synthetic control) for post-treatment periods.

{p 8 8 2}
{cmd: e(n_pl):}{p_end}
{p 10 10 2}
The number of placebo averages used for comparison. For single treatment setups, this can be used to calculate purely randomized p-values.

{p 8 8 2}
{cmd: e(pvals):}{p_end}
{p 10 10 2}
A vector of the proportions of placebo effects that are at least as large as the main effect for each post-treatment period.

{p 8 8 2}
{cmd: e(pvals_std):}{p_end}
{p 10 10 2}
A vector of the proportions of placebo standardized effects that are at least as large as the main standardized effect for each post-treatment period.

{p 8 8 2}
{cmd: e(pval_joint_post):}{p_end}
{p 10 10 2}
The proportion of placebos that have a post-treatment RMSPE at least as large as the average for the treated units. 

{p 8 8 2}
{cmd: e(pval_joint_post_std):}{p_end}
{p 10 10 2}
The proportion of placebos that have a ratio of post-treatment RMSPE over pre-treatment RMSPE at least as large as the average ratio for the treated units. 

{p 8 8 2}
{cmd: e(avg_pre_rmspe_p):}{p_end}
{p 10 10 2}
The proportion of placebos that have a pre-treatment RMSPE at least as large as the average of the treated units. A measure of fit. Concerning if significant.

{p 8 8 2}
{cmd: e(failed_opt_targets):}{p_end}
{p 10 10 2}
Errors when constructing the synthetic controls for non-treated units are handled gracefully. If any are detected they will be listed in this matrix. 
(Errors when constructing the synthetic control for treated units will abort the method.)

{p 8 8 2}
{cmd: e(avg_val_rmspe_p):}{p_end}
{p 10 10 2}
When specifying {cmd:training_propr}, this is the proportion of placebos that have a RMSPE for the validation period at least as large as the average of the treated units. A measure of fit. Concerning if significant.


{title:Examples}

{p 4 4 2}
The following examples use data from the {cmd:synth} package. Ensure that {cmd:synth} was installed with ancillary files (e.g., {cmd:ssc install synth, all}). This panel dataset contains information for 39 US States for the years 1970-2000
(see Abadie, Diamond, and Hainmueller (2010) for details).
{cmd:Note}, that the {cmd:synth} package's dataset might have a different name. 
It was originally uploaded as {it:smoking}, then for a while the dataset installed was incorrect (there was a name collision with another package), and now the dataset is correct and named {it:synth_smoking}.
{p_end}
{p 4 8 2}{stata sysuse synth_smoking}{p_end}
{p 4 8 2}{stata tsset state year}{p_end}

{p 4 8 2}
Example 1 - Reconstruct the initial {cmd:synth} example plus graphs:{p_end}
{phang}{stata synth_runner cigsale beer(1984(1)1988) lnincome(1972(1)1988) retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) gen_vars}{p_end}
{phang}{stata single_treatment_graphs, trlinediff(-1) effects_ylabels(-30(10)30) effects_ymax(35) effects_ymin(-35)}{p_end}
{phang}{stata effect_graphs , trlinediff(-1)}{p_end}
{phang}{stata pval_graphs}{p_end}
{p 8 8 2}
In this example, {cmd:synth_runner} conducts all the estimations and inference. Since there was only a single treatment period we can save the output into the dataset. Then we can create the various graphs. 
Note the option {it:trlinediff} allows the offset of a vertical treatment line. 
Likely options include values in the range from (first treatment period - last post-treatment period) to 0 and the default value is -1 (to match Abadie et al. 2010). {p_end}

{p 4 8 2}
Example 2 - Same treatment, but a bit more complicated setup:{p_end}
{phang}{stata cap drop pre_rmspe post_rmspe lead effect cigsale_synth}{p_end}
{phang}{stata gen byte D = (state==3 & year>=1989)}{p_end}
{phang}{stata synth_runner cigsale beer(1984(1)1988) lnincome(1972(1)1988) retprice age15to24, trunit(3) trperiod(1989) trends training_propr(`=13/18') gen_vars pre_limit_mult(10)}{p_end}
{phang}{stata single_treatment_graphs, scaled}{p_end}
{phang}{stata effect_graphs , scaled}{p_end}
{phang}{stata pval_graphs}{p_end}
{p 8 8 2}
Again there is a single treatment period, so output can be saved and merged back into the dataset. In this setting we (a) specify the treated units/periods with a binary variable, 
(b) generate the outcome predictors automatically using the initial 13 periods of the pre-treatment era (the rest is the "validation" period), and (c) we match on trends.{p_end}

{p 4 8 2}
Example 3 - Multiple treatments at different time periods:{p_end}

{phang}{stata cap drop pre_rmspe post_rmspe lead effect cigsale_synth}{p_end}
{phang}{stata cap drop cigsale_scaled effect_scaled cigsale_scaled_synth D}{p_end}
{phang}{stata cap program drop my_pred my_drop_units my_xperiod my_mspeperiod}{p_end}
{phang}{stata program my_pred, rclass}{p_end}
{phang2}{stata args tyear}{p_end}
{phang2}{stata return local predictors "beer(`=`tyear'-4'(1)`=`tyear'-1') lnincome(`=`tyear'-4'(1)`=`tyear'-1')" }{p_end}
{phang}{stata end}{p_end}
{phang}{stata program my_drop_units}{p_end}
{phang2}{stata args tunit}{p_end}
{phang2}{stata if `tunit'==39 qui drop if inlist(state,21,38)}{p_end}
{phang2}{stata if `tunit'==3 qui drop if state==21}{p_end}
{phang}{stata end}{p_end}
{phang}{stata program my_xperiod, rclass}{p_end}
{phang2}{stata args tyear}{p_end}
{phang2}{stata return local xperiod "`=`tyear'-12'(1)`=`tyear'-1'"}{p_end}
{phang}{stata end}{p_end}
{phang}{stata program my_mspeperiod, rclass}{p_end}
{phang2}{stata args tyear}{p_end}
{phang2}{stata return local mspeperiod "`=`tyear'-12'(1)`=`tyear'-1'"}{p_end}
{phang}{stata end}{p_end}
{phang}{stata gen byte D = (state==3 & year>=1989) | (state==7 & year>=1988)}{p_end}
{phang}{stata synth_runner cigsale retprice age15to24, d(D) pred_prog(my_pred) trends training_propr(`=13/18') drop_units_prog(my_drop_units)) xperiod_prog(my_xperiod) mspeperiod_prog(my_mspeperiod)}{p_end}
{phang}{stata effect_graphs}{p_end}
{phang}{stata pval_graphs}{p_end}
{p 8 8 2}
We extend Example 2 by considering a control state now to be treated (Georgia in addition to California). No treatment actually happened in Georgia in 1987. Now that we have several treatment periods we can not merge in a simple file. 
Some of the graphs (of {cmd:single_treatment_graphs}) can no longer be made. 
We also show how predictors, unit dropping, {cmd:xperiod}, and {cmd:mspeperiod} can be dynamically generated depending on the treatment year. {p_end}

{title:Development}

{p}If you encounter a bug in the program, please ensure your are running the most recent version from the {browse "https://github.com/bquistorff/synth_runner/":GitHub site}.
If the problem persists, see if the bug has been previously reported at {browse "https://github.com/bquistorff/synth_runner/issues":https://github.com/bquistorff/synth_runner/issues}. 
If not, file a new 'issue' there and list (a) the steps causing the problem (with output) and (b) the version of {cmd:synth_runner} used (found from {cmd:which synth_runner}).{p_end}

{p}Contributions may also be made via a pull request from the GitHub page.{p_end}

{p}To be notified of new releases, subscribe to notifications of {browse "https://github.com/bquistorff/synth_runner/issues/1":this issue} .{p_end}

{title:Citation of synth_runner}

{p}{cmd:synth_runner} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{phang}Brian Quistorff and Sebastian Galiani. The synth_runner package: Utilities to automate
synthetic control estimation using synth, August 2017. {browse "https://github.com/bquistorff/synth_runner":https://github.com/bquistorff/synth_runner}. Version 1.6.0.
{p_end}

{p}And in bibtex format:{p_end}

@Misc{QG17,
  Title  = {The synth\_runner Package: Utilities to Automate Synthetic Control Estimation Using synth},
  Author = {Brian Quistorff and Sebastian Galiani},
  Month  = aug,
  Note   = {Version 1.6.0},
  Year   = {2017},
  Url    = {https://github.com/bquistorff/synth_runner}
}

{title:References}

{p 4 8 2}
Abadie, A., Diamond, A., and Hainmueller, J. 2014. Comparative Politics and the Synthetic Control Method. {it: American Journal of Political Science}, 59(2):495–510, Apr 2014.

{p 4 8 2}
Abadie, A., Diamond, A., and Hainmueller, J. 2010. Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program.
{it: Journal of the American Statistical Association} 105(490): 493-505.

{p 4 8 2}
Abadie, A. and Gardeazabal, J. 2003. Economic Costs of Conflict: A Case Study of the Basque Country. {it: American Economic Review} 93(1): 113-132.

{p 4 8 2}
Cavallo, E., Galiani, S., Noy, I., and Pantano, J. 2013. Catastrophic natural disasters and economic growth. {it: Review of Economics and Statistics}, 95(5):1549–1561, Dec 2013.

{title:Authors}

      Brian Quistorff, brian-work@quistorff.com (corresponding author, see Development section for reportings bugs)
      Bureau of Economic Analysis
      Sebastian Galiani
      University of Maryland
